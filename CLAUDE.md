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

- **zsh/zshrc** — Main shell config. Sources oh-my-zsh (powerlevel10k theme), then loads in order: `zsh/scripts/*` helpers → `aliases.zsh` → `keybindings.zsh` → company submodules (`evolution/`, `ela/`) → `_jira_restore_profile`
- **zsh/scripts/jira.zsh** — Multi-profile Jira CLI (shared across company configs). Company submodules call `jira-register` to add profiles; `_jira_restore_profile` auto-activates on shell start
- **zsh/aliases.zsh** — Shell aliases and utility functions (`proj_run`, `proj_install`, `glone`, etc.)
- **nvim/** — Neovim config using Lazy.nvim. Entry point: `init.lua` → `lua/{set,remap,russian}.lua` + `lua/config/{lazy,lsp}.lua`. Plugins live in `lua/plugins/` as individual files
- **tmux/** — tmux config with TPM plugins, sesh session manager (prefix+K), vim-tmux-navigator. Sub-configs sourced from `tmux.conf` in order: `navigation.conf` (EN bindings) → `navigation-ru.conf` (RU mirror) → `plugins.conf` → `statusline.conf`
- **alacritty/** — Terminal emulator config (TOML format)
- **lazygit/** — Lazygit config
- **lf/** — lf file manager config with `lfcd.sh` for directory-changing integration
- **karabiner/** — Karabiner-Elements keyboard remapping
- **sesh/** — tmux session manager config

## Git Submodules

Company-specific dotfiles are kept as submodules (`evolution/`, `ela/`). These are private repos that extend the base config (each has an `index.zsh` sourced from `zshrc`).

## Key Conventions

- **Commit messages** follow conventional commits: `type(scope): description` (feat, fix, docs, style, refactor, perf, test, chore, build, ci)
- **AI commit helper**: `aicommit-suggest.sh` emits N (default 3) Conventional Commits messages to stdout, one per line, by firing parallel OpenAI-compatible requests (Cerebras `gpt-oss-120b` via `CEREBRAS_API_KEY`, local Ollama fallback via `OLLAMA_HOST`/`AICOMMIT_OLLAMA_BASE`). Lazygit's `Ctrl-J` feeds them into a native `menuFromCommand` popup (snappy now that generation is sub-second), then an edit prompt and commit. `aicommit-pick.sh` is an optional standalone `fzf` streaming picker (`output: terminal`) for a one-by-one reveal. Routes to `evolution/aicommit-suggest.sh` if present and repo is on evolution
- **Neovim plugins**: Each plugin gets its own file in `nvim/lua/plugins/`. Use Lazy.nvim spec format
- **Shell keybindings**: Defined in `zsh/keybindings.zsh` using `bindkey -s`. Vim mode is enabled (`bindkey -v`)
- **fnm** is used for Node.js version management (not nvm)
- **delta** is the git pager (side-by-side diffs)
- **Russian layout pairing**: `tmux/navigation.conf` (EN) and `tmux/navigation-ru.conf` (RU) are a matched pair — every letter/Alt binding in navigation.conf has a Cyrillic equivalent in navigation-ru.conf using the same command. **When editing either file, update the other.** Key map: `,`→`б` `.`→`ю` `h`→`р` `j`→`о` `k`→`л` `l`→`д` (uppercase = Shift equivalent)
