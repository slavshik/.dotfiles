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
function proj_run() {
    if cat package.json > /dev/null 2>&1; then
        scripts=$(cat package.json | jq -r ".scripts | keys []" | fzf --height="40%")

        if [[ -n $scripts ]]; then
            script_name=$(echo $scripts | awk -F ': ' '{gsub(/"/, "", $1); print $1}' | xargs)

            if cat yarn.lock > /dev/null 2>&1; then
                print -s "yarn run "$script_name;
                yarn run $script_name
            else
                print -s "npm run "$script_name;
                npm run $script_name
            fi
        fi
    else
        echo "Error: There's no package.json"
    fi
}

function proj_install() {
    if [[ -f "yarn.lock" ]]; then
        if cat yarn.lock > /dev/null 2>&1; then
            yarn
            return
        fi
    fi

    if [[ -f "package.json" ]]; then
        if cat package.json > /dev/null 2>&1; then
            npm i
            return
        fi
    fi

    if [[ -f "go.mod" ]]; then
        if cat go.mod > /dev/null 2>&1; then
            go install
        fi
    fi
}

function runscript_save() {
    if [[ -f "$1" ]]; then 
        ./$1
    else
        if [[ -f "package.json" ]]; then
            yarnrun
        fi
    fi
}
function _run_s() {
    if [ -f "$1" ]; then
        nvim $1
    else
        mkdir -p .$(whoami)
        touch .$(whoami)/run.sh
        chmod u+x .$(whoami)/run.sh
        nvim .$(whoami)/run.sh
    fi
}
function jj() {
    sesh connect $(sesh list | fzf)
}
alias _run="runscript_save .$(whoami)/run.sh"
alias zshconfig="vim ~/.zshrc"
alias python=python3
alias j=z
alias t=tmux
alias ta="tmux attach"
alias hard="git reset --hard @"
alias love="/Applications/love.app/Contents/MacOS/love"
alias v=nvim
alias lg=lazygit
alias l="lsd -la --git --group-directories-first"
alias ll="lsd -l --git --group-directories-first"
alias mine="git log --decorate --all --author=\"`git config user.email`\""
alias webstorm="open -a 'WebStorm' --args '$1' >/dev/null 2>&1"

# TODO: add alias for `git push origin -u HEAD`
