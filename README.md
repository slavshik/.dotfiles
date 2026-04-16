# .dotfiles

A high-performance macOS development environment centered around Zsh, Neovim, and Tmux, with deep integrations for Jira, GitLab, and AI-assisted workflows.

## 📖 AI & Agent Context
This repository includes specialized instructions for AI agents:
- [CLAUDE.md](./CLAUDE.md) - Instructions and context for Claude Code.
- [GEMINI.md](./GEMINI.md) - Instructions and context for Gemini CLI.

## ✨ Features
- **Shell:** Zsh powered by [Oh My Zsh](https://ohmyz.sh/) and [Powerlevel10k](https://github.com/romkatv/powerlevel10k).
- **Editor:** [Neovim](https://neovim.io/) with a modular Lua-based configuration.
- **Terminal:** [Alacritty](https://alacritty.org/) for speed and simplicity.
- **Multiplexer:** [Tmux](https://github.com/tmux/tmux) with [TPM](https://github.com/tmux-plugins/tpm) and [sesh](https://github.com/joshmedeski/sesh).
- **Integrations:** Built-in helpers for **Jira**, **GitLab**, and **AI-assisted commits**.
- **Tools:** [lazygit](https://github.com/slavshik/lazygit) (#1 tool), [lf](https://github.com/slavshik/lf), `fzf`, `lsd`, `zoxide`, `gh`, `glab`, `jq`, `yq`, `bun`, `fnm`.

## 📸 Screenshots
<img alt="vim" src="https://user-images.githubusercontent.com/621317/207847223-8c16c455-aa5f-4fa7-b347-88c0be094f61.png">
<img alt="git" src="https://user-images.githubusercontent.com/621317/207847217-80eb03cc-f3a1-4046-8de0-ac87b126e50d.png">

## 🚀 Installation

Clone the repository and run the installation script:

```bash
./install.sh
```

This script will symlink all configurations to their respective locations in `~/.config/` or `$HOME`, and initialize required plugins.

## 🛠 Development Workflow

### Project Helpers
- `proj_run`: Fuzzy-pick and run an NPM/Bun script.
- `proj_install`: Automatically detect and run the correct package manager install.
- `runscript`: Fuzzy-pick and run scripts from `.claude/scripts` or `package.json`.

### Jira & GitLab
- `jira <KEY>` / `jira-detail <KEY>`: View issues directly in the terminal.
- `jira-status <KEY>`: Change issue status via fuzzy search.
- `gl-mrs`: List and open your GitLab Merge Requests.
- `gl-pipes`: View and open recent CI pipelines.

### AI-Assisted Commits
Use `aicommit.sh` to generate commit messages based on your staged changes using AI.
