function https() {
    SSL_PATH=~/.config/ssl
    http-server -S -C $SSL_PATH/key.pem -K $SSL_PATH/key.key -p 8080
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
