# .dotfiles

A high-performance macOS development environment centered around Zsh, Neovim, and Tmux, with deep integrations for Jira, GitLab, and AI-assisted workflows.

## 📖 AI & Agent Context
This repository includes specialized instructions for AI agents:
- [CLAUDE.md](./CLAUDE.md) - Instructions and context for Claude Code.
- [GEMINI.md](./GEMINI.md) - Instructions and context for Gemini CLI.
- [pi/](./pi/) - Extensions, themes, and settings for [pi](https://github.com/badlogic/pi-mono) coding agent.
- [.github/copilot-instructions.md](./.github/copilot-instructions.md) - Custom instructions for GitHub Copilot.

## ✨ Features
- **Shell:** Zsh powered by [Oh My Zsh](https://ohmyz.sh/) and [Powerlevel10k](https://github.com/romkatv/powerlevel10k).
- **Editor:** [Neovim](https://neovim.io/) with a modular Lua-based configuration.
- **Terminal:** [Alacritty](https://alacritty.org/) for speed and simplicity.
- **Multiplexer:** [Tmux](https://github.com/tmux/tmux) with [TPM](https://github.com/tmux-plugins/tpm) and [sesh](https://github.com/joshmedeski/sesh).
- **Integrations:** Built-in helpers for **Jira**, **GitLab**, and **AI-assisted commits**.
- **Tools:** [lazygit](https://github.com/slavshik/lazygit) (#1 tool), [lf](https://github.com/slavshik/lf), `fzf`, `lsd`, `zoxide`, `gh`, `glab`, `jq`, `yq`, `bun`, `fnm`.
- **Pi Coding Agent:** Custom [Catppuccin Mocha](./pi/agent/themes/catppuccin-mocha.json) theme, plan mode, Perplexity web search, custom status bar, and tool management.

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
In Lazygit, press `Ctrl-J` on the files or branches view. After a brief "Generating..." spinner (~0.5s), lazygit shows a **native popup menu** of AI-generated Conventional Commits suggestions from `aicommit-suggest.sh`; pick one, tweak it in the edit prompt, and it commits. (`aicommit-pick.sh` is an optional standalone full-screen `fzf` picker that streams the suggestions one-by-one as they arrive — run it directly or bind it to a key if you prefer that style.)

Suggestions come from parallel OpenAI-compatible requests: **Cerebras** (`gpt-oss-120b`, fast and free) when `CEREBRAS_API_KEY` is set, falling back to a **local Ollama** instance otherwise. Requires `fzf`, `jq`, and `curl`.

**Setup:**
- Cerebras (recommended): get a free key at https://cloud.cerebras.ai, then add `export CEREBRAS_API_KEY=csk-...` to your shell secrets.
- Local fallback (Ollama, e.g. on a Mac mini): `ollama pull qwen2.5-coder:14b` and serve it on the LAN. Point the helper at it with `export OLLAMA_HOST=<host>` (uses `http://<host>:11434/v1`); for a tunnel or reverse proxy set the full base instead, e.g. `export AICOMMIT_OLLAMA_BASE=https://your.ngrok.app/v1`. ngrok hosts (`*.ngrok.app`, `*.ngrok.io`) given via `OLLAMA_HOST` are auto-detected as `https://.../v1`.

Tunables (env vars): `AICOMMIT_N` (number of suggestions, default 3), `AICOMMIT_CEREBRAS_MODEL` (default `gpt-oss-120b`), `AICOMMIT_OLLAMA_MODEL` (default `qwen2.5-coder:14b`). On evolution repos it routes to `evolution/aicommit-suggest.sh` when present.
