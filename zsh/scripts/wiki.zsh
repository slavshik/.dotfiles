# Confluence wiki helpers
# Auth via WIKI_PAT from company .secure.zsh

export WIKI_HOST="https://wiki.evolution.com"

typeset -gr _WIKI_SCRIPT_PATH="${${(%):-%N}:A}"
typeset -gr _WIKI_REPO_ROOT="${_WIKI_SCRIPT_PATH:h:h:h}"
typeset -gr _WIKI_REPO_CLI="${_WIKI_REPO_ROOT}/cli/cmd/wiki/wiki-cli"

if [[ -n "$WIKI_CLI" && -x "$WIKI_CLI" ]]; then
    _WIKI_CLI="$WIKI_CLI"
elif [[ -x "$HOME/.local/bin/wiki-cli" ]]; then
    _WIKI_CLI="$HOME/.local/bin/wiki-cli"
elif (( $+commands[wiki-cli] )); then
    _WIKI_CLI="${commands[wiki-cli]}"
else
    _WIKI_CLI="$_WIKI_REPO_CLI"
fi

_wiki_require_cli() {
    [[ -x "$_WIKI_CLI" ]] && return 0
    if (( $+commands[wiki-cli] )); then
        _WIKI_CLI="${commands[wiki-cli]}"
        return 0
    fi
    echo "wiki-cli not found. Tried:"
    echo "  $_WIKI_CLI"
    [[ "$_WIKI_CLI" != "$HOME/.local/bin/wiki-cli" ]] && echo "  $HOME/.local/bin/wiki-cli"
    [[ "$_WIKI_CLI" != "$_WIKI_REPO_CLI" ]] && echo "  $_WIKI_REPO_CLI"
    echo "Install it with: make -C ~/.dotfiles/cli install"
    return 1
}

# wiki <URL-or-pageId> — fetch and display a Confluence page
wiki() {
    local input="$1"
    [[ -z "$input" ]] && { echo "Usage: wiki <URL-or-pageId>"; return 1; }
    _wiki_require_cli || return 1
    "$_WIKI_CLI" view "$input"
}

# wiki-search <query> — search Confluence
wiki-search() {
    local query="$1"
    [[ -z "$query" ]] && { echo "Usage: wiki-search <query>"; return 1; }
    _wiki_require_cli || return 1
    "$_WIKI_CLI" search "$query"
}
