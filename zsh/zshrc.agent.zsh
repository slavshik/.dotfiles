# Lightweight zshrc for agent/tool use (Claude Code, etc.)
# Sourced instead of full .zshrc when CLAUDECODE is set

# Minimal completion support (needed by jira.zsh compdef)
autoload -Uz compinit && compinit -C

# Load shared shell helper scripts
for f in ~/.dotfiles/zsh/scripts/*.(sh|zsh)(N); do source "$f"; done

# Git helpers
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,master}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo master
}

# Git aliases (oh-my-zsh git plugin subset)
alias g='git'
alias gst='git status'
alias gss='git status -s'
alias ga='git add'
alias gaa='git add --all'
alias gap='git add --patch'
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcm='git checkout $(git_main_branch)'
alias gcd='git checkout develop'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git pull'
alias glr='git pull --rebase'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gr='git remote'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbm='git rebase $(git_main_branch)'
alias gsta='git stash push'
alias gstp='git stash pop'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'

# PATH
export PATH="$HOME/.local/bin:$PATH"
export GOPATH=$HOME/.local/share/go/
export PATH="$PATH:$GOPATH/bin"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Company profiles (registers jira profiles, test helpers)
EVO=~/.dotfiles/evolution/index.zsh
[ -f "$EVO" ] && source "$EVO"
ELA=~/.dotfiles/ela/index.zsh
[ -f "$ELA" ] && source "$ELA"

_jira_restore_profile
