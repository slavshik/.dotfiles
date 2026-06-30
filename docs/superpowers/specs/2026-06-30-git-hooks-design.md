 Git Hooks for Dotfiles — Design

**Date:** 2026-06-30
**Status:** Approved (pending spec review)

## Context & Decision

Goal: add git hooks to this dotfiles repo for **(a)** pre-commit quality checks and
**(b)** auto-running `install.sh` after a pull.

**Husky was rejected.** Husky is built for the JS/npm ecosystem and needs a
`package.json` + Node *solely* to manage hooks — contaminating a pure shell/lua/tmux
repo with npm infrastructure. Per multiple 2026 tooling comparisons, repos with no
`package.json` should use native git hooks, lefthook, or pre-commit — not husky.

**Chosen: native git hooks via `core.hooksPath`.** Zero runtime dependencies, hooks are
plain shell scripts (the repo's native language), and it fits the existing `install.sh`
symlink/config pattern — a single config line wires it up.

Rejected alternatives:
- **lefthook** — adds a binary dependency + a YAML abstraction layer for what is, here,
  a couple of small shell scripts.
- **husky** — see above.

## Constraints discovered

- **`pull.rebase = true`** (local config on this repo). A normal `git pull` is a
  fast-forward rebase, where **neither `post-merge` nor `post-rewrite` fires**, so a
  hook-based "after pull" trigger would almost never run. Resolved with a **shell
  wrapper** (`dotup`) instead of a hook.
- **shellcheck, shfmt, gitleaks, stylua, luacheck are not installed** on this machine;
  only `zsh` is present. Therefore hooks must **skip-with-warning** on a missing tool and
  never block a commit. The tools are added to `Brewfile` (still reference-only per repo
  convention — not auto-installed).

## Components

### 1. `git-hooks/_lib.sh` — shared helpers (sourced, not executable-required)
- `staged <glob...>` → `git diff --cached --name-only --diff-filter=ACM`, filtered to globs
- `has <tool>` → `command -v` guard
- `skip <tool> <brew-hint>` → prints yellow `⚠ <tool> not installed — skipping (brew install <hint>)`, returns success
- color helpers + a `HOOK_FAILED` accumulator so all checks run before the hook exits

### 2. `git-hooks/pre-commit` — sources `_lib.sh`, checks staged files only

| Staged pattern    | Tool       | Action                                              | If tool missing |
|-------------------|------------|-----------------------------------------------------|-----------------|
| `*.sh`            | shellcheck | lint; fail on error                                 | skip-warn       |
| `*.sh`            | shfmt      | `shfmt -d`; fail on diff (hint: `shfmt -w`)         | skip-warn       |
| `*.zsh`, `zshrc*` | `zsh -n`   | syntax check (zsh installed → **always runs**)      | n/a             |
| `*.lua`           | stylua     | `stylua --check`                                    | skip-warn       |
| `*.lua`           | luacheck   | lint                                                | skip-warn       |
| staged diff       | gitleaks   | `gitleaks protect --staged --redact` *(verify subcommand against the installed gitleaks version during implementation)* | skip-warn |

- Generated file `.fzf.zsh` is excluded from the `zsh -n` check.
- Hook exits nonzero **iff** a real finding occurs (lint error / format diff / secret).
  Missing tools never cause failure.

### 3. `dotup` function → `zsh/scripts/dotfiles.zsh` (new file, auto-sourced via `zsh/scripts/*`)

```zsh
dotup() {
  local dir="${1:-$HOME/.dotfiles}" before after changed
  before=$(git -C "$dir" rev-parse HEAD)
  git -C "$dir" pull --rebase || return
  after=$(git -C "$dir" rev-parse HEAD)
  [[ "$before" == "$after" ]] && return                  # nothing pulled
  changed=$(git -C "$dir" diff --name-only "$before" "$after")
  if grep -qx 'install.sh' <<< "$changed"; then
    echo "↻ install.sh changed — re-running"
    (cd "$dir" && ./install.sh)
  fi
  grep -qx 'Brewfile' <<< "$changed" && echo "⚠ Brewfile changed — review new packages"
}
```

Reliable across merge / rebase / fast-forward; runs `install.sh` only when it actually
changed, using explicit before/after SHAs (not reflog). Also flags a changed `Brewfile`.

### 4. `install.sh` — new "Git hooks" section

```bash
echo "Git hooks:"
git -C "$DOTFILES" config core.hooksPath git-hooks && ok "core.hooksPath → git-hooks" || fail "core.hooksPath"
chmod +x "$DOTFILES"/git-hooks/pre-commit
```

The relative path `git-hooks` is portable (no hardcoded `$HOME`) and the config is local,
so it applies only to this repo.

### 5. `Brewfile`

Add `shellcheck`, `shfmt`, `gitleaks`, `stylua`, `luacheck` (remains a flat reference
list per repo convention).

## Error handling

- Hooks: missing tool → skip + warn (does not fail); real finding → accumulate, exit 1.
- `_lib.sh` resolved via `${BASH_SOURCE[0]}` dirname so it works under `core.hooksPath`.
- `dotup`: a failed `pull` returns early; the `cd` is confined to a subshell.

## Testing (manual verification)

1. **Tools absent** → `git commit` prints skip-warnings and succeeds.
2. After `brew install`: stage a `*.sh` with a shellcheck error → commit **blocked**.
3. Stage a file containing a fake AWS key → gitleaks **blocks**.
4. Stage a `*.zsh` with a syntax error → `zsh -n` **blocks** (works with zero brew installs).
5. `dotup` against an upstream that changed `install.sh` → re-runs it; no changes → silent.

## Out of scope (YAGNI)

commit-msg conventional-commit lint (deferred by choice), husky, lefthook, pre-push hooks,
CI, and auto-fix/re-stage behavior.

## Possible future improvements (not in this spec)

- `install.sh --check` dry-run mode
- optional `brew bundle` integration (Brewfile is currently reference-only)
- a `dotcheck` command to run all hooks across the whole repo on demand
