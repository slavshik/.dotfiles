# Multi-instance Jira CLI
# Requires: curl, jq, fzf (for jira-status)
#
# Usage:
#   Company index.zsh calls: jira-register <label> <host> <pat_env_var> [auth_type]
#   User switches with:      jira-use <label>

# --- Profile registry ---
typeset -gA _JIRA_PROFILES  # label -> "host|pat_var|auth_type"

jira-register() {
    local label="$1" host="$2" pat_var="$3" auth="${4:-bearer}"
    [[ -z "$label" || -z "$host" || -z "$pat_var" ]] && {
        echo "Usage: jira-register <label> <host> <pat_env_var> [auth_type=bearer]"
        return 1
    }
    _JIRA_PROFILES[$label]="$host|$pat_var|$auth"
}

# --- Context switcher ---

_jira_state_file="${XDG_STATE_HOME:-$HOME/.local/state}/jira-profile"

# jira-use [label] — switch Jira profile or list all
jira-use() {
    local label="$1"
    local profiles=("${(@k)_JIRA_PROFILES}")

    if [[ -z "$label" ]]; then
        # Show current + available
        echo "Jira profiles:"
        for p in "${profiles[@]}"; do
            if [[ "$p" == "$_JIRA_ACTIVE_PROFILE" ]]; then
                echo "  * $p (active)"
            else
                echo "    $p"
            fi
        done
        [[ -z "$_JIRA_ACTIVE_PROFILE" ]] && echo "\nNo active profile. Run: jira-use <label>"
        return 0
    fi

    [[ -z "${_JIRA_PROFILES[$label]}" ]] && {
        echo "Unknown profile: $label"
        echo "Available: ${(j:, :)profiles}"
        return 1
    }

    _jira_activate "$label"
    echo "Jira profile: $label ($JIRA_HOST)"
}

_jira_activate() {
    local label="$1"
    local entry="${_JIRA_PROFILES[$label]}"
    local host="${entry%%|*}"
    local rest="${entry#*|}"
    local pat_var="${rest%%|*}"
    local auth="${rest#*|}"

    export JIRA_HOST="$host"
    export JIRA_API="$host/rest/api/2"
    export _JIRA_PAT_VAR="$pat_var"
    export _JIRA_AUTH_TYPE="$auth"
    export _JIRA_ACTIVE_PROFILE="$label"
    export _JIRA_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/jira-issues-${label}"

    # persist
    mkdir -p "${_jira_state_file:h}"
    echo "$label" > "$_jira_state_file"
}

_jira_restore_profile() {
    local profiles=("${(@k)_JIRA_PROFILES}")
    local count=${#profiles}

    # auto-select if only one registered
    if (( count == 1 )); then
        _jira_activate "${profiles[1]}"
        return
    fi

    # restore from state file
    if [[ -f "$_jira_state_file" ]]; then
        local saved=$(<"$_jira_state_file")
        if [[ -n "${_JIRA_PROFILES[$saved]}" ]]; then
            _jira_activate "$saved"
        fi
    fi
}

# --- Auth helper ---

_jira_require_profile() {
    [[ -n "$_JIRA_ACTIVE_PROFILE" ]] && return 0
    echo "No Jira profile active. Run: jira-use <label>"
    echo "Available: ${(j:, :)${(@k)_JIRA_PROFILES}}"
    return 1
}

# --- Commands (delegated to Go binary) ---

_JIRA_CLI="${0:h:h}/cli/cmd/jira/jira-cli"
[[ -x "$HOME/.local/bin/jira-cli" ]] && _JIRA_CLI="$HOME/.local/bin/jira-cli"

# jira <KEY> — view issue summary
jira() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" view "$@"
}

# jira-detail <KEY> — full issue view
jira-detail() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" detail "$@"
}

# jira-open <KEY> — open issue in browser
jira-open() {
    _jira_require_profile || return 1
    local key="${1:u}"
    [[ -z "$key" ]] && { echo "Usage: jira-open <ISSUE-KEY>"; return 1; }
    open "$JIRA_HOST/browse/$key"
}

# jira-my [N] — list my unresolved issues
jira-my() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" my "$@"
}

alias jir='jira-my | fzf --ansi --bind "ctrl-o:become(open $JIRA_HOST/browse/{1})"'

# jira-search <text> — free-text search
jira-search() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" search "$@"
}

# jira-comment <KEY> <msg> — add a comment
jira-comment() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" comment "$@"
}

# jira-assign <KEY> [user] — assign issue (defaults to self)
jira-assign() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" assign "$@"
}

# jira-unassign <KEY> — remove assignee from issue
jira-unassign() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" unassign "$@"
}

# jira-status <KEY> — transition status via fzf
jira-status() {
    _jira_require_profile || return 1
    local key="${1:u}"
    [[ -z "$key" ]] && { echo "Usage: jira-status <ISSUE-KEY>"; return 1; }
    local choice=$("$_JIRA_CLI" transitions "$key" | fzf --prompt="Transition $key > " --with-nth=2..)
    [[ -z "$choice" ]] && return 0
    local tid=$(echo "$choice" | awk '{print $1}')
    "$_JIRA_CLI" transition "$key" "$tid"
}

# jira-by-status <status> [N] — list my issues by status name
jira-by-status() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" by-status "$@"
}

# jira-transition <KEY> <status> — transition issue to status by name (fuzzy match)
jira-transition() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" transition "$@"
}

# jira-mr <KEY> [--web] — find GitLab MR by ticket key
jira-mr() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" mr "$@"
}

# jira-batch-transition <from-status> <to-status> — move all my issues between statuses
jira-batch-transition() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" batch-transition "$@"
}

# jira-jql <JQL> [maxResults] — run a raw JQL query
jira-jql() {
    _jira_require_profile || return 1
    "$_JIRA_CLI" jql "$@"
}

# --- Completions ---

_jira_branch_key() {
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    [[ "$branch" =~ '([A-Z]+-[0-9]+)' ]] && echo "${match[1]}"
}

_jira_complete_keys() {
    local -a keys
    local bk=$(_jira_branch_key)
    [[ -n "$bk" ]] && keys+=("$bk:current branch")
    if [[ -n "$_JIRA_CACHE" && -f "$_JIRA_CACHE" ]]; then
        while IFS=$'\t' read -r key summary; do
            keys+=("$key:$summary")
        done < "$_JIRA_CACHE"
    fi
    _describe 'issue key' keys
}

_jira_complete_profiles() {
    local -a profiles
    for p in "${(@k)_JIRA_PROFILES}"; do
        profiles+=("$p")
    done
    _describe 'jira profile' profiles
}

compdef _jira_complete_keys jira jira-detail jira-open jira-comment jira-assign jira-jql jira-unassign jira-status jira-transition jira-mr
compdef _jira_complete_profiles jira-use
