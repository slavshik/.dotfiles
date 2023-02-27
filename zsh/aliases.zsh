function https() {
    SSL_PATH=~/.config/ssl
    http-server -S -C $SSL_PATH/key.pem -K $SSL_PATH/key.key -p 8080
}
# clone the repo using `gh list` and `fzf` filter
function glone() {
    if [ -n "$1" ]; then
        ORG=$1
    else
        ORG=$(whoami)
    fi
    REPO=$(gh repo list $ORG --json=name --jq=".[] .name" | fzf)
    [ -n "$REPO" ] && gh repo clone $ORG/$REPO
}
alias zshconfig="vim ~/.zshrc"
alias python=python3
alias j=z
alias t=tmux
alias ta=tmux attach
alias hard="git reset --hard @"
alias love="/Applications/love.app/Contents/MacOS/love"
alias v=nvim
alias lg=lazygit
alias l="exa -la --git --group-directories-first"
alias ll="exa -l --git --group-directories-first"
