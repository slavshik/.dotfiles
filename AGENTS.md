# AGENTS.md

**Universal guidance for AI agents and developers working with this repository.**

This file provides the shared conventions, architecture, and workflow guidelines. For **agent-specific guidance**, see:
- **Claude Code** → [`CLAUDE.md`](CLAUDE.md)
- **Google Gemini** → [`GEMINI.md`](GEMINI.md)

## Overview

Personal dotfiles repository for macOS and generic Linux systems. All configs are symlinked from `~/.dotfiles/` to their expected locations via `install.sh`.

**OS Support:**
- **macOS**: Full feature set (Karabiner, macOS defaults, `/Library/…` paths)
- **Linux**: XDG-compliant fallbacks (`~/.config/`, `~/.local/share/`)

All platform-specific logic is guarded by `IS_MACOS` checks to prevent shell startup breakage on unsupported systems.

## Installation & Setup

### Quick Start
```bash
./install.sh        # Symlink all configs, clone deps, install plugins
./defaults_write.sh # macOS-only: set key repeat preferences
```

The install script:
- Symlinks dotfiles to `~` and `~/.config/`
- Clones Oh My Zsh, Lazy.nvim, and plugin dependencies
- Registers AI agent skills (Claude, Gemini, etc.)
- Applies macOS defaults (Karabiner, system preferences)

**Homebrew Reference**: See `Brewfile` for the canonical package list (not automated, just a reference).

## Repository Structure

### Core Shells & Startup
- **`zsh/zshrc`** — Main shell entry point. Loads in order: Oh My Zsh (Powerlevel10k theme) → helper scripts → aliases → keybindings → company submodules → Jira profile restoration
- **`zsh/scripts/`** — Modular shell helpers (e.g., `jira.zsh`)
- **`zsh/aliases.zsh`** — Shell aliases and utility functions (`proj_run`, `proj_install`, `glone`, etc.)
- **`zsh/keybindings.zsh`** — Vim-mode keybindings (zsh `bindkey -s`)

### Editors & Tools
- **`nvim/`** — Neovim config (Lazy.nvim). Entry: `init.lua` → `lua/{set,remap,russian}.lua` + `lua/config/{lazy,lsp}.lua`. Plugins in `lua/plugins/` (one file per plugin)
- **`alacritty/`** — Terminal emulator config (TOML)
- **`herdr/`** — Terminal workspace manager (replaces tmux). Only `config.toml` is symlinked; `~/.config/herdr/` also holds runtime state (sockets, logs, sessions)
- **`tmux/`** — Legacy tmux config (fallback). Subconfigs: `plugins.conf` → `statusline.conf`
- **`lf/`** — File manager config with `lfcd.sh` for shell directory syncing

### Integrations & Helpers
- **`zsh/scripts/jira.zsh`** — Multi-profile Jira CLI (shared across company configs). Company modules call `jira-register`; `_jira_restore_profile` auto-activates profiles on shell start
- **`aicommit-suggest.sh`** — AI-powered commit message generator (Cerebras/Ollama). Invoked by Lazygit `Ctrl-J`; routes to `evolution/aicommit-suggest.sh` if present
- **`daily-summary.sh`** — Daily standup summary script

### Keyboard & UI
- **`karabiner/`** — Karabiner-Elements keyboard remapping (macOS only)
- **`lazygit/`** — Lazygit config
- **`sesh/`** — Tmux session manager config

### AI Agent Guidance
- **`claude/`** — Claude Code skills and configurations
- **`cli/`** — CLI tool helpers

### Documentation
- **`docs/`** — Additional references (setup guides, architecture notes)

## Key Conventions

### Git & Commits
- **Commit Format**: Gitmoji + Conventional Commits (`emoji type(scope): description`)
  - **Gitmoji Reference**: 
    - ✨ `:sparkles:` – New features
    - 🐛 `:bug:` – Bug fixes
    - 📝 `:memo:` – Documentation
    - 🎨 `:art:` – Code style/formatting
    - ♻️ `:recycle:` – Refactoring
    - ⚡ `:zap:` – Performance improvements
    - ✅ `:white_check_mark:` – Tests/testing
    - 🔧 `:wrench:` – Configuration/tooling (chore)
    - 🏗️ `:building_construction:` – Architecture/build system
    - 🚀 `:rocket:` – Deployment/CI
  - **Conventional Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`
  - **Example**: `✨ feat(nvim): add new LSP plugin` or `🐛 fix(zsh): resolve zoxide integration issue`
- **AI Commit Helper**: `aicommit-suggest.sh` generates 3 suggestions (parallel OpenAI-compatible requests to Cerebras or Ollama). **Agents should prepend gitmoji when generating suggestions.**
- **Staging & Company Submodules**: Private repos (`evolution/`, `ela/`) extend the base config via git submodules; each has an `index.zsh` sourced from `zshrc`

### Shell & Environment
- **Keybindings**: Vim mode enabled (`bindkey -v`). Bindings defined in `zsh/keybindings.zsh`
- **Optional Tools**: Guarded with `command -v` checks (zoxide, fnm, syntax highlighting, etc.) so missing tools never break startup
- **fnm**: Node.js version manager (not nvm)
- **delta**: Git pager (side-by-side diffs)
- **Agent Mode**: When inside an AI agent, use lightweight shell config for performance (agent-specific instructions in CLAUDE.md / GEMINI.md)

### Config Architecture
- **Herdr ↔ Alacritty Contract**: `alacritty/keybindings.toml` translates CMD-key → herdr prefix chords only; never invent new chords. After editing, verify the chord exists in `herdr/config.toml` or `herdr --default-config`. Keeping herdr at defaults ensures chords work over SSH (iPad/Blink)
- **Herdr as Source of Truth**: Only override herdr defaults for unset actions. Validate with `herdr config check`; apply changes with `herdr server reload-config`
- **Neovim Plugins**: One file per plugin in `nvim/lua/plugins/`. Use Lazy.nvim spec format

### Keyboard Layout Mirroring
- **Russian + English**: `alacritty/keybindings.toml` has EN and Cyrillic blocks in the same `bindings` array
- **Sync Rule**: Every letter binding in EN must have an RU duplicate with identical `chars` payload
- **Key Map**: `,`→`б` `.`→`ю` `h`→`р` `j`→`о` `k`→`л` `l`→`д` (and uppercase variants)
- **Update Both or Neither**: Edit both blocks together; never leave them out of sync

### Platform Differences
- **macOS Paths**: `~/Library/…`, Karabiner, `defaults write` commands
- **Linux Paths**: `~/.config/`, `~/.local/share/` (XDG)
- **Guard Pattern**: Check `IS_MACOS` before running macOS-specific steps

## Development Workflow

### Navigation & Common Tasks
- **Fuzzy Project Selection**: `proj_run` (NPM/Bun scripts), `proj_install` (package manager detection)
- **Script Execution**: `runscript` (Claude scripts, package.json, commands.txt)
- **Session Management**: `jj` (sesh session picker)
- **Repository Cloning**: `glone` (GitHub org fuzzy search)
- **Git Interface**: `lazygit` (primary git driver)
- **File Navigation**: `lf` with `lfcd` (synced directory changing)
- **Directory Jumping**: `j` (zoxide alias)
- **Listing**: `l`/`ll` (lsd with git status)

### Jira Integration
```bash
jira <KEY>              # Quick summary
jira-detail <KEY>       # Full issue
jira-my                 # Your unresolved issues
jira-status <KEY>       # Fuzzy transition status
jira-open <KEY>         # Open in browser
jira-use <label>        # Switch profiles
```
**Key Inference**: Jira keys auto-detected from current Git branch or recent commits.

### AI-Powered Commits
1. Stage your changes
2. Open Lazygit (`lg`)
3. Press `Ctrl-J` → AI generates 3 commit messages
4. Pick one, edit, and commit

## Important Notes

- **State Not in Instructions**: Do not store runtime state in markdown files (AGENTS.md, CLAUDE.md, GEMINI.md, etc.). State goes in `~/.config/`, `~/.local/`, or `.git/`.
- **Agent-Specific Sections**: For Claude-specific features (e.g., skills loading), see CLAUDE.md. For Gemini-specific behavior, see GEMINI.md.
- **Handoff Format**: When handing off between agents or to a human, use git commits + README snippets, not isolated instruction files.

## Cross-References

- **For Claude Code details**: See [`CLAUDE.md`](CLAUDE.md)
- **For Gemini CLI details**: See [`GEMINI.md`](GEMINI.md)
- **For setup tips**: See [`HINTS.md`](HINTS.md)
- **For project overview**: See [`README.md`](README.md)
- **For copilot/GitHub Codespaces**: See [`.github/copilot-instructions.md`](.github/copilot-instructions.md)
