# .dotfiles

A high-performance macOS development environment centered around Zsh, Neovim, and Tmux, with deep integrations for Jira, GitLab, and AI-assisted workflows.

## System Overview

- **OS:** macOS
- **Shell:** Zsh (Oh My Zsh + Powerlevel10k)
- **Editor:** Neovim (`nvim`)
- **Terminal:** Alacritty
- **Multiplexer:** Tmux (`tpm`, `tmuxifier`, `sesh`)
- **Key Tools:** `lazygit` (fork: `slavshik/lazygit`), `lf` (fork: `slavshik/lf`), `fzf`, `lsd`, `zoxide`, `gh`, `glab`, `jq`, `yq`, `bun`

## Installation


Run the main installation script to symlink configurations and clone dependencies:

```bash
./install.sh
```

This script manages:
- Symlinking dotfiles to `~/.config` and `$HOME`.
- Symlinking Claude skills and agents.
- Installing Oh My Zsh plugins and themes.
- Configuring macOS defaults (via `defaults_write.sh`).

## Development Workflow

### Shell Environments
The configuration detects when it's running inside an AI agent (like Claude Code or Gemini CLI) and switches to a lightweight shell config to improve performance and stability.

- **Standard Shell:** Full P10k prompt, autosuggestions, etc.
- **Agent Shell:** `zsh/zshrc.agent.zsh` (minimalist, fast).

### Project Management
Use these helpers for quick navigation and project setup:
- `proj_run`: Fuzzy-pick and run an NPM/Bun script from `package.json`.
- `proj_install`: Detect and run the correct package manager install command (`go install`, `bun install`, `yarn`, `npm i`).
- `runscript`: Fuzzy-pick and run scripts from `.claude/scripts`, `package.json`, or local `commands.txt`.
- `jj`: fuzzy-pick a `sesh` session to connect to.
- `glone`: Clone a GitHub repository from a specific organization using fuzzy search.

### Jira Integration
The `jira` CLI (Go-based) is integrated directly into the shell and Claude skills.

**Key Commands:**
- `jira <KEY>`: Quick issue summary.
- `jira-detail <KEY>`: Full issue view.
- `jira-my`: List your unresolved issues.
- `jira-status <KEY>`: Transition issue status via fuzzy search.
- `jira-open <KEY>`: Open the issue in your default browser.
- `jira-use <label>`: Switch between different Jira profiles/instances.

**Key Inference:**
Jira keys are automatically inferred from the current Git branch or recent commit logs if not provided.

### GitLab Integration
Helpers built on top of `glab` and `fzf`:
- `gl-mrs`: List and open your MRs.
- `gl-pipes`: View and open recent CI pipelines.

### AI-Assisted Commits
- `aicommit.sh`: Uses AI to generate meaningful commit messages based on staged changes.
- `route_ai_commit.sh`: Routing logic for AI commit generation.

## Navigation & UI
- **Git Interface:** `lazygit` (`lg` alias) is the primary driver for Git operations.
- **File Manager:** `lf` with `lfcd` for synced directory changing.
- **Directory Jumping:** `j` (alias for `zoxide`).
- **Listing:** `l` / `ll` (alias for `lsd` with git status).
- **SSH:** `ss` fuzzy-picks a device from the local network (via `lan` tool).

## Work-Specific Helpers

The configuration includes specialized helpers for the `evolution` and `ela` environments:
- **Jira:** Automatically registers and activates the `evo` Jira profile.
- **Testing:**
  - `jt` / `jtw`: Run Jest tests in the current directory (finds the nearest `jest.config.cjs`).
  - `waa`: Run Jest tests in watch mode for the current directory.
  - `check`: Run tests in a new Tmux pane and execute TS validation.
- **Git:** `minevo` and `evoweek` for quick commit history filtering.
- **VPN:** `evoru` for fixing VPN issues.
- **Game Dev:** `rungame` for fuzzy-starting games in specific monorepos.

## Coding Standards & Preferences
- **Editor:** Neovim is the primary editor (`v` alias).
- **Keybindings:** Vim-style keybindings are enabled in the shell (`bindkey -v`).
- **Architecture:** Keep logic modular (e.g., `zsh/jira.zsh`, `zsh/gitlab.zsh`, `nvim/lua/plugins/`).
- **Tools:** Prefer `zsh -i -c 'command'` when invoking shell functions from external scripts or AI agents to ensure environment variables and aliases are loaded.

## Important Paths
- `~/.dotfiles`: Root of the configuration.
- `~/.config/nvim`: Neovim configuration.
- `~/.claude`: Claude-specific skills and configurations.
- `~/Library/Application Support/lazygit`: Lazygit configuration.
nfiguration.
