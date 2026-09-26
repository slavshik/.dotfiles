# GEMINI.md

**Google Gemini agent guidance for this repository.**

For universal repo guidance, conventions, and architecture, see [`AGENTS.md`](AGENTS.md).

## Quick Start

1. **Installation**: Run `./install.sh` from the repo root
2. **Repository Structure**: See [`AGENTS.md`](AGENTS.md) for directory layout and core conventions
3. **Agent-Specific Setup**: Lightweight shell mode is recommended for performance (see below)

## Gemini-Specific Integration

### Performance Optimization

Gemini CLI runs best with a lightweight shell configuration:

```bash
# Use this for faster startup in Gemini
GEMINI_AGENT=1 zsh -i -c '...'
```

**Important**: In agent mode, oh-my-zsh aliases (like `gp`) are **NOT** available to maintain speed. Use full commands instead:
- ❌ `gp` → ✅ `git push`
- ❌ `ga` → ✅ `git add`
- ❌ `gc` → ✅ `git commit`

### Shell Environment

The configuration auto-detects when running inside Gemini and switches to a minimal shell config:
- **Standard Shell** (interactive): Full P10k prompt, autosuggestions, plugins
- **Agent Shell** (Gemini mode): Lightweight, no prompt bloat, fast startup

Both modes share:
- Jira CLI integration
- GitLab helpers (`glab`)
- Project management functions (`proj_run`, `proj_install`)
- Path helpers (zoxide, fzf)

## Available Tools & Helpers

### Project Management

```bash
proj_run           # Fuzzy-pick and run NPM/Bun scripts
proj_install       # Auto-detect and run package manager install
runscript          # Run scripts from .claude/scripts, package.json, or commands.txt
glone              # Clone GitHub repo with org fuzzy search
```

### Jira Integration

```bash
jira <KEY>         # Quick issue summary
jira-detail <KEY>  # Full issue view
jira-my            # List your unresolved issues
jira-status <KEY>  # Fuzzy transition status
jira-open <KEY>    # Open in browser
jira-use <label>   # Switch Jira profiles
```

### GitLab Integration

```bash
gl-mrs             # List and open your MRs
gl-pipes           # View and open recent CI pipelines
```

### AI-Powered Commits

```bash
aicommit-suggest.sh    # Generate 3 commit message suggestions
aicommit-pick.sh       # Interactive streaming picker for suggestions
```

Commit messages follow **Conventional Commits** format:
```
type(scope): description

Example: feat(nvim): add neo-tree plugin
```

### Navigation & UI

```bash
lg                 # Lazygit (primary git interface)
lf                 # File manager
j <dir>            # Jump to directory (zoxide)
l / ll             # List files (lsd with git status)
v                  # Open Neovim
ss                 # SSH to local network device (fuzzy)
```

## Work-Specific Helpers

### Evolution Environment (Private Submodule)

If `evolution/` submodule is present:

```bash
jira-use evo       # Activate evolution Jira profile
minevo             # Filter commits to evolution-related work
evoweek            # Show evolution commits from this week
evoru              # Fix VPN issues
jt / jtw           # Run Jest tests (find nearest jest.config.cjs)
waa                # Watch mode for Jest tests
check              # Run tests + TypeScript validation
rungame            # Fuzzy-start game in monorepo
```

### ELA Environment (Private Submodule)

Similar helpers available if `ela/` submodule is present.

## File Structure Overview

Key files for Gemini work:

- **`zsh/zshrc`** — Main shell entry point (sources helpers, aliases, company configs)
- **`zsh/aliases.zsh`** — All CLI shortcuts
- **`zsh/scripts/jira.zsh`** — Jira multi-profile CLI
- **`nvim/init.lua`** — Neovim config (LSP, plugins, keybindings)
- **`lazygit/config.yml`** — Git workflow UI
- **`claude/`** — Claude Code skills and configs (can be reused)
- **`cli/`** — CLI tool helpers and scripts

See [`AGENTS.md`](AGENTS.md) for complete directory structure.

## System Overview

- **OS**: macOS (Linux support with XDG fallbacks)
- **Shell**: Zsh (Oh My Zsh + Powerlevel10k)
- **Editor**: Neovim (Lazy.nvim)
- **Terminal**: Alacritty
- **Terminal Manager**: herdr (replaces tmux)
- **Key Tools**: lazygit, lf, fzf, lsd, zoxide, gh, glab, jq, yq, bun

## Working with Git

### Common Workflow

```bash
# Check status
git status

# View diff
git diff <file>

# Stage changes
git add <file>

# Create conventional commit
git commit -m "feat(scope): description"

# Push to origin
git push

# View log
git log --oneline
```

### AI-Assisted Commits

1. Stage your changes
2. Run `aicommit-suggest.sh` or use Lazygit `Ctrl-J`
3. Pick a suggestion, edit, and commit

Generated via Cerebras (`gpt-oss-120b`) or local Ollama fallback.

## Troubleshooting

### Shell Startup Slow in Agent Mode

- Ensure you're using `GEMINI_AGENT=1` for lightweight shell
- Check `.env` for missing API keys (Jira, Cerebras, etc.)
- Verify all `command -v` guards are in place

### Git Issues

If you see index.lock errors:
```bash
rm -f .git/index.lock
```

### Missing Dependencies

All tools are optional and guarded with `command -v` checks. Missing tools won't break startup:
- zoxide, fnm, direnv, syntax highlighting — all optional
- Required: git, zsh, minimal coreutils

## Next Steps

- See [`AGENTS.md`](AGENTS.md) for universal conventions and architecture
- Run `./install.sh` to symlink all configs
- Explore private submodules (`evolution/`, `ela/`) if available
- Review [`README.md`](README.md) for project overview
- Check `.github/copilot-instructions.md` for GitHub Copilot + Codespaces guidance
