# GitLab helpers (glab + fzf)
# Requires: glab, fzf
# Auth via GITLAB_TOKEN + GITLAB_HOST from company .secure.zsh

_gl_pick_mr() {
    local mrs
    mrs=$(glab mr list --per-page=30 "$@")
    [[ $? -ne 0 ]] && return 1
    local pick=$(echo "$mrs" | fzf --ansi --header-lines=1 \
        --prompt="MR > " --preview-window=hidden)
    [[ -z "$pick" ]] && return 0
    local id=$(echo "$pick" | awk '{print $1}' | tr -d '!')
    glab mr view --web "$id"
}

# gl-mrs — list my open MRs, pick one to open in browser
gl-mrs() {
    _gl_pick_mr --author=@me "$@"
}

# gl-mrs-all — list all open MRs (not just mine)
gl-mrs-all() {
    _gl_pick_mr "$@"
}

# gl-mr <ID> — view MR details in terminal
gl-mr() {
    [[ -z "$1" ]] && { echo "Usage: gl-mr <MR-ID>"; return 1; }
    glab mr view "$1" "${@:2}"
}

# gl-mr-open <ID> — open MR in browser
gl-mr-open() {
    [[ -z "$1" ]] && { echo "Usage: gl-mr-open <MR-ID>"; return 1; }
    glab mr view --web "$1" "${@:2}"
}

# gl-pipes — list recent pipelines, pick one to open
gl-pipes() {
    local pipes
    pipes=$(glab ci list --per-page=20 "$@")
    [[ $? -ne 0 ]] && return 1
    local pick=$(echo "$pipes" | fzf --ansi --header-lines=1 \
        --prompt="Pipeline > " --preview-window=hidden)
    [[ -z "$pick" ]] && return 0
    local id=$(echo "$pick" | awk '{print $1}' | tr -d '()')
    glab ci view "$id"
}
