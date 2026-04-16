# Confluence wiki helpers
# Auth via EVO_WIKI_PAT from company .secure.zsh

export WIKI_HOST="https://wiki.evolution.com"

_WIKI_CLI="${0:h:h}/cli/cmd/wiki/wiki-cli"
[[ -x "$HOME/.local/bin/wiki-cli" ]] && _WIKI_CLI="$HOME/.local/bin/wiki-cli"

# wiki <URL-or-pageId> — fetch and display a Confluence page
wiki() {
    local input="$1"
    [[ -z "$input" ]] && { echo "Usage: wiki <URL-or-pageId>"; return 1; }
    "$_WIKI_CLI" view "$input"
}

# wiki-search <query> — search Confluence
wiki-search() {
    local query="$1"
    [[ -z "$query" ]] && { echo "Usage: wiki-search <query>"; return 1; }
    "$_WIKI_CLI" search "$query"
}
