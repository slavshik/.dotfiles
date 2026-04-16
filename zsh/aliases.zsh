# source scripts
for f in ~/.dotfiles/zsh/scripts/*.(sh|zsh)(N); do source "$f"; done

# ssh into a LAN device picked via fzf
function ss() {
  local target=$(lan | fzf --ansi | sed $'s/\033\\[[0-9;]*m//g' | cut -d' ' -f1)
  [[ -n "$target" ]] && ssh "$target"
}

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

            if cat bun.lock > /dev/null 2>&1; then
                print -s "bun run "$script_name;
                bun run $script_name
                return
            elif cat yarn.lock > /dev/null 2>&1; then
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
            echo yarn
            yarn
            return
        fi
    fi

    if [[ -f "bun.lock" ]]; then
        if cat bun.lock > /dev/null 2>&1; then
            echo bun install
            bun install
            return
        fi
    fi

    if [[ -f "package.json" ]]; then
        if cat package.json > /dev/null 2>&1; then
            echo npm i
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

function _find_claude_scripts() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        local scripts_dir="$dir/.claude/scripts"
        if [[ -d "$scripts_dir" ]] && [[ -n "$(ls -A "$scripts_dir" 2>/dev/null)" ]]; then
            echo "$scripts_dir"
            return 0
        fi
        dir="${dir:h}"
    done
    return 1
}

function runscript() {
    local predefined="$1"
    local entries=()
    local scripts_dir
    scripts_dir=$(_find_claude_scripts 2>/dev/null)

    if [[ -f "$predefined" ]]; then
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "${line//[[:space:]]/}" ]] && continue
            [[ "${line#"${line%%[![:space:]]*}"}" == \#* ]] && continue
            entries+=( $'\e[1;33m'"$line"$'\e[0m \e[90m(predefined)\e[0m\tPREDEFINED\t'"$line" )
        done < "$predefined"
    fi

    if [[ -n "$scripts_dir" ]]; then
        local f
        for f in "$scripts_dir"/*(N-.); do
            [[ -x "$f" ]] && entries+=( $'\e[36m'"${f:t}"$'\e[0m \e[90m(claude)\e[0m\tCLAUDE\t'"$f" )
        done
    fi

    if [[ -f package.json ]]; then
        local n
        for n in ${(f)"$(jq -r '.scripts // {} | keys[]' package.json 2>/dev/null)"}; do
            [[ -n "$n" ]] && entries+=( $'\e[35m'"$n"$'\e[0m \e[90m(npm)\e[0m\tNPM\t'"$n" )
        done
    fi

    if (( ${#entries[@]} == 0 )); then
        echo "no run targets found"
        return 1
    fi

    local pick
    pick=$(printf '%s\n' "${entries[@]}" \
        | fzf --ansi --height="40%" --with-nth=1 --delimiter=$'\t' --prompt="run> ")
    [[ -z "$pick" ]] && return 0

    local kind="${${pick#*$'\t'}%%$'\t'*}"
    local payload="${pick##*$'\t'}"

    case "$kind" in
        PREDEFINED)
            print -s "$payload"
            eval "$payload"
            ;;
        CLAUDE) "$payload" ;;
        NPM)
            if [[ -f bun.lock ]]; then
                print -s "bun run $payload"
                bun run "$payload"
            elif [[ -f yarn.lock ]]; then
                print -s "yarn run $payload"
                yarn run "$payload"
            else
                print -s "npm run $payload"
                npm run "$payload"
            fi
            ;;
    esac
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

function dta() {
    git tag --delete $1
    git push --delete origin $1
}

function jj() {
    sesh connect $(sesh list | fzf)
}
alias _run="runscript .$(whoami)/commands.txt"
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
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# TODO: add alias for `git push origin -u HEAD`

# helpme [filter] — list custom commands from dotfiles
helpme() {
    local filter="${1:-}"
    local files=(~/.dotfiles/zsh/jira.zsh ~/.dotfiles/zsh/gitlab.zsh ~/.dotfiles/zsh/aliases.zsh)
    for f in $files; do
        [[ -f "$f" ]] || continue
        local label="${${f:t}%.zsh}"
        local matches=()
        while IFS= read -r line; do
            local cmd="${line#\# }"
            local name="${cmd%% —*}"
            local desc="${cmd#*— }"
            [[ -n "$filter" && "$name" != *"$filter"* && "$label" != *"$filter"* ]] && continue
            matches+=("$(printf "\033[36m%-20s\033[0m %s" "$name" "$desc")")
        done < <(grep -E '^# \w+.* — ' "$f")
        if (( ${#matches[@]} > 0 )); then
            printf "\n\033[1;33m%s\033[0m\n" "$label"
            printf '%s\n' "${matches[@]}"
        fi
    done
}
