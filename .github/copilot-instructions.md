# Copilot instructions for this repository

## Build, test, and lint commands

- This repository does not define a centralized build, test, or lint suite.
- Primary setup command: `./install.sh`
  - Symlinks repo-managed config into `~` and `~/.config/`
  - Also runs `./defaults_write.sh`
- macOS keyboard repeat preferences only: `./defaults_write.sh`
- `Brewfile` is reference-only here; do not assume `brew bundle` is part of the repo workflow unless the user explicitly asks for it.
- Single-test command in this repo: **not applicable** (no first-party test suite in dotfiles itself).
- If the optional `evolution/` submodule is present, it contributes Jest helpers for work repos:
  - `jt` (run tests for current directory scope)
  - `jtw` (same scope in watch mode)

## High-level architecture

- This is a personal macOS dotfiles repository. The repo is the source of truth; `install.sh` wires files into their runtime locations with symlinks.
- `zsh/zshrc` automatically switches to `zsh/zshrc.agent.zsh` when running inside agent environments (`CLAUDECODE`/`OPENCLAW`) to keep shells lightweight.
- Shell configuration centers on `zsh/zshrc`. Load order matters:
  1. oh-my-zsh + powerlevel10k bootstrap
  2. shared shell integrations such as `lfcd.sh`
  3. `zsh/jira.zsh`
  4. `zsh/gitlab.zsh`
  5. optional company submodules `evolution/index.zsh` and `ela/index.zsh`
  6. `_jira_restore_profile`
  7. `zsh/aliases.zsh`
  8. `zsh/keybindings.zsh`
- `zsh/jira.zsh` is a reusable multi-profile Jira layer. Company-specific submodules are expected to call `jira-register`, and the active profile is restored from state on shell startup.
- Shortcut handling is layered across tools and should be read as a chain, not as isolated mappings:
  1. `alacritty/keybindings.toml` translates macOS-style key chords into escape sequences or literal text
  2. `zsh/keybindings.zsh` maps some of those emitted sequences to shell commands with `bindkey -s`
  3. `tmux/tmux.conf` handles tmux-prefixed navigation/session/window bindings
  4. Neovim keymaps in `nvim/lua/remap.lua` and plugin specs provide the editor-layer behavior
- Neovim is structured as a small entrypoint plus modular config:
  - `nvim/init.lua` loads `lua/set.lua`, `lua/remap.lua`, `lua/russian.lua`, `lua/config/lazy.lua`, and `lua/config/lsp.lua`
  - `lua/config/lazy.lua` bootstraps Lazy.nvim and imports plugin specs from `nvim/lua/plugins/`
  - LSP enablement is split across `lua/config/lsp.lua` and plugin specs such as `mason.lua`, `mason-lspconfig.lua`, and `nvim-lspconfig.lua`
- tmux is composed from `tmux/tmux.conf` plus sourced files `tmux/statusline.conf` and `tmux/plugins.conf`. It is tightly integrated with `sesh`, with the session picker bound on `prefix + K`.
- `lf/lfcd.sh` is sourced by `zsh/zshrc` so `lf` can change the parent shell directory on exit.
- AI-assisted commit flow: Lazygit's `Ctrl-J` custom command runs `aicommit-suggest.sh` and streams its 3-line output into a native `menuFromCommand` dropdown; the selected message is piped through an edit prompt to `git commit -m`.

## Key conventions

- Edit the repo-backed files, not the symlink targets in `~` or `~/.config/`.
- Keep zsh changes consistent with the existing module split:
  - reusable shell functions and aliases in `zsh/aliases.zsh`
  - interactive bindings in `zsh/keybindings.zsh`
  - Jira behavior in `zsh/jira.zsh`
- Preserve zsh load order when changing `zsh/zshrc`, especially that `zsh/jira.zsh` loads before `evolution/` and `ela/`, because those submodules extend the shared Jira profile registry.
- `evolution/` and `ela/` are git submodules with private/company-specific overrides. Treat them as optional extensions of the base config rather than moving shared logic into them.
- Prefer running shell helper functions via interactive zsh (`zsh -i -c '<command>'`) when invoking them from scripts/agents, so aliases/functions/profile setup are loaded.
- When changing shortcuts, trace the full path before editing: many top-level shortcuts begin in `alacritty/keybindings.toml`, get expanded in zsh or tmux, and only then reach Neovim. Update the correct layer instead of duplicating the same binding in multiple places.
- Add Neovim plugins as separate files under `nvim/lua/plugins/` using Lazy.nvim spec tables; do not collapse multiple plugins into one large file.
- Neovim LSP configuration uses current server names such as `ts_ls`, `lua_ls`/`luals`, and `gopls`; keep additions aligned with the existing Lazy.nvim + Mason + `vim.lsp.enable(...)` pattern.
- Neovim and tmux share movement-oriented bindings: `vim-tmux-navigator` wires `<C-h/j/k/l>` across panes, while `nvim/lua/remap.lua` also assigns `<C-j>` and `<C-k>` to line movement. Check both tmux and Neovim mappings before changing control-key behavior.
- Shell keybindings use `bindkey -s`, and vi mode is enabled with `bindkey -v`.
- Commit messages follow conventional commits: `type(scope): description`.
- `fnm` is the Node version manager in this environment; do not introduce `nvm`-specific assumptions into repo instructions or shell changes.
