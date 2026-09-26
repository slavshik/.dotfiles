# CLAUDE.md

**Claude Code agent guidance for this repository.**

For universal repo guidance, conventions, and architecture, see [`AGENTS.md`](AGENTS.md).

## Quick Start

1. **Installation**: Run `./install.sh` from the repo root
2. **Claude Skills**: Symlinked to `~/.claude/skills/` — these are loaded automatically by Claude Code
3. **Configuration**: Additional guidance in `claude/` directory (hooks, scripts, styles)

## Claude Code Integration

### Available Skills

Skills are organized in `claude/skills/` and automatically discovered. Key skill categories:
- **cloudflare** — Workers, Pages, KV, D1, R2, AI, Tunnel
- **agents-sdk** — Cloudflare Agents SDK (state, durable execution, RPC)
- **durable-objects** — Stateful coordination, WebSockets, SQLite
- **wrangler** — Cloudflare CLI (deploy, dev, manage resources)
- **workers-best-practices** — Code review, anti-patterns, observability
- **sandbox-stable/next** — Sandbox SDK (code execution, AI runners, terminals)
- **turnstile-spin** — Bot protection (CAPTCHA)
- **web-perf** — Performance analysis (Chrome DevTools MCP, Core Web Vitals)
- **remote-claw** — Offload tasks to remote machine via SSH + HTTP API
- **jira** — Jira ticket interaction (view, comment, assign, transition)
- **wiki** — Confluence wiki search
- **graphify** — Knowledge graph (codebase structure, architecture queries)
- **axi** — Agent eXperience Interface (CLI standards for agents)

Plus general-purpose skills: pdf, xlsx, pptx, docx, docs, morning, import-memory, deep-research, skill-creator

### Shell Access

You have full bash access to the repo. Common commands:

```bash
# See uncommitted changes
git status

# View git logs with conventional commits
git log --oneline

# Run tests (project-specific, see Makefile or package.json)
npm test
bun test

# Install dependencies (auto-detected)
./install.sh

# List available CLI helpers
ls -la cli/
```

### Key Files to Know

- **`zsh/aliases.zsh`** — Shell aliases and functions you can invoke via bash
- **`nvim/init.lua`** — Neovim entry point (LSP, plugins, keybindings)
- **`Brewfile`** — Canonical package list (reference; not automated)
- **`AGENTS.md`** — Universal conventions (commit format, git workflow, directory structure)
- **`README.md`** — Project overview

### Working with Neovim Config

When editing `nvim/lua/plugins/`, each file is a Lazy.nvim plugin spec. Common patterns:

```lua
return {
  "plugin-author/plugin-name",
  opts = {
    -- config options here
  },
  keys = { -- lazy keybindings
    { "<leader>x", function() end }
  }
}
```

Reload with `:Lazy sync` or restart nvim.

### Working with Shell Configs

Shell startup is optimized for performance. When adding new helpers:

1. **Small helpers** → `zsh/aliases.zsh`
2. **Modular logic** → `zsh/scripts/myfeature.zsh` (sourced from `zshrc`)
3. **Company-specific** → Private submodule (`evolution/`, `ela/`)

Always guard optional tools with `command -v`:

```bash
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi
```

## Agent-Specific Behavior

### Performance Optimization

Claude Code may run in a lightweight shell mode for speed. Full P10k prompt, autosuggestions, and oh-my-zsh plugins are still available but may be slower on large codebases. The repo's optional-tool guards ensure nothing breaks even if a tool is missing.

### Git Operations

Use `git` commands directly or through the helpers:

```bash
# View uncommitted changes
git diff

# Stage and commit (use conventional commits)
git add <file>
git commit -m "type(scope): description"

# Push to origin
git push
```

AI commit suggestions available: see `aicommit-suggest.sh` and Lazygit `Ctrl-J`.

### File Editing

- Use `edit` tool for precise, multi-location changes
- Use `write` for new files or full rewrites
- Use `read` to examine existing files

All paths are relative to `/Users/slavshik/.dotfiles`.

## Troubleshooting

### Shell Startup Issues

If shell startup breaks:
1. Check `.env` for missing secrets
2. Verify `IS_MACOS` logic for your OS
3. Look for unguarded `command -v` calls in `zsh/scripts/`
4. See `HINTS.md` for macOS-specific fixes

### Git Lock File

If you see `fatal: Unable to create '.git/index.lock'`:
```bash
rm -f .git/index.lock
```

### Neovim Plugin Issues

Clear Lazy cache and resync:
```bash
rm -rf ~/.local/share/nvim/lazy/
nvim -c "Lazy! sync" -c "qa"
```

## Next Steps

- See [`AGENTS.md`](AGENTS.md) for repo-wide conventions
- See [`README.md`](README.md) for project overview
- Explore `claude/skills/` for available AI capabilities
- Run `./install.sh` if you haven't already
