# Lightweight zshrc for agent/tool use (Claude Code, etc.)
# Sourced instead of full .zshrc when CLAUDECODE is set

# Minimal completion support (needed by jira.zsh compdef)
autoload -Uz compinit && compinit -C

# Load shared shell helper scripts (lan, etc.)
for f in ~/.dotfiles/zsh/scripts/*.sh; do
  source "$f"
done

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/Library/Python/3.9/bin"
export GOPATH=$HOME/.local/share/go/
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# fnm (node version manager) — uncomment if needed
# FNM_PATH="$HOME/Library/Application Support/fnm"
# if [ -d "$FNM_PATH" ]; then
#   export PATH="$FNM_PATH:$PATH"
#   eval "$(fnm env --shell zsh)"
# fi

# Jira & GitLab helpers
source ~/.dotfiles/zsh/jira.zsh
source ~/.dotfiles/zsh/gitlab.zsh

# Company profiles (registers jira profiles, test helpers)
EVO=~/.dotfiles/evolution/index.zsh
[ -f "$EVO" ] && source "$EVO"
ELA=~/.dotfiles/ela/index.zsh
[ -f "$ELA" ] && source "$ELA"

_jira_restore_profile
