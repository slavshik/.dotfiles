# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS. Configs are symlinked from `~/.dotfiles/` to their expected locations via `install.sh`.

## Installation

```bash
./install.sh        # Symlinks all configs to ~/ and ~/.config/
./defaults_write.sh # Sets macOS key repeat preferences
```

Homebrew packages are tracked in `Brewfile` (flat list, no `brew bundle` integration — just a reference).

## Repository Structure

- **zsh/zshrc** — Main shell config. Sources oh-my-zsh (powerlevel10k theme), then loads modules in order: `jira.zsh` → company submodules (`evolution/`, `ela/`) → `aliases.zsh` → `keybindings.zsh`
- **zsh/jira.zsh** — Multi-profile Jira CLI (shared across company configs). Company submodules call `jira-register` to add profiles; `_jira_restore_profile` auto-activates on shell start
- **zsh/aliases.zsh** — Shell aliases and utility functions (`proj_run`, `proj_install`, `glone`, etc.)
- **nvim/** — Neovim config using Lazy.nvim. Entry point: `init.lua` → `lua/{set,remap,russian}.lua` + `lua/config/{lazy,lsp}.lua`. Plugins live in `lua/plugins/` as individual files
- **tmux/** — tmux config with TPM plugins, sesh session manager (prefix+K), vim-tmux-navigator
- **alacritty/** — Terminal emulator config (TOML format)
- **lazygit/** — Lazygit config
- **lf/** — lf file manager config with `lfcd.sh` for directory-changing integration
- **karabiner/** — Karabiner-Elements keyboard remapping
- **sesh/** — tmux session manager config

## Git Submodules

Company-specific dotfiles are kept as submodules (`evolution/`, `ela/`). These are private repos that extend the base config (each has an `index.zsh` sourced from `zshrc`).

## Key Conventions

- **Commit messages** follow conventional commits: `type(scope): description` (feat, fix, docs, style, refactor, perf, test, chore, build, ci)
- **AI commit helper**: `aicommit.sh` uses `aichat` to suggest commit messages from staged diff; `route_ai_commit.sh` routes to company-specific version
- **Neovim plugins**: Each plugin gets its own file in `nvim/lua/plugins/`. Use Lazy.nvim spec format
- **Shell keybindings**: Defined in `zsh/keybindings.zsh` using `bindkey -s`. Vim mode is enabled (`bindkey -v`)
- **fnm** is used for Node.js version management (not nvm)
- **delta** is the git pager (side-by-side diffs)
