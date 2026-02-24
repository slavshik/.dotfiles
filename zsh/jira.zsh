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
    typeset -g _JIRA_PAT_VAR="$pat_var"
    typeset -g _JIRA_AUTH_TYPE="$auth"
    typeset -g _JIRA_ACTIVE_PROFILE="$label"
    typeset -g _JIRA_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/jira-issues-${label}"

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

_jira_curl() {
    local token="${(P)_JIRA_PAT_VAR}"
    local auth_header
    case "$_JIRA_AUTH_TYPE" in
        bearer) auth_header="Authorization: Bearer $token" ;;
        basic)  auth_header="Authorization: Basic $token" ;;
        *)      auth_header="Authorization: Bearer $token" ;;
    esac
    curl -s -H "$auth_header" \
         -H "Content-Type: application/json" \
         "$@"
}

# --- Commands ---

jira() {
    _jira_require_profile || return 1
    local key="${1:u}"
    [[ -z "$key" ]] && { echo "Usage: jira <ISSUE-KEY>"; return 1; }
    local res=$(_jira_curl "$JIRA_API/issue/$key?fields=summary,status,assignee,priority,issuetype")
    local err=$(echo "$res" | jq -r '.errorMessages[0] // empty')
    [[ -n "$err" ]] && { echo "Error: $err"; return 1; }
    echo "$res" | jq -r '
        "\(.key)  [\(.fields.issuetype.name)] \(.fields.summary)\n" +
        "Status:   \(.fields.status.name)\n" +
        "Priority: \(.fields.priority.name)\n" +
        "Assignee: \(.fields.assignee.displayName // "Unassigned")"
    '
}

jira-open() {
    _jira_require_profile || return 1
    local key="${1:u}"
    [[ -z "$key" ]] && { echo "Usage: jira-open <ISSUE-KEY>"; return 1; }
    open "$JIRA_HOST/browse/$key"
}

jira-my() {
    _jira_require_profile || return 1
    local max="${1:-15}"
    local res=$(_jira_curl "$JIRA_API/search" \
        -G --data-urlencode "jql=assignee=currentUser() AND resolution=Unresolved ORDER BY updated DESC" \
        --data-urlencode "maxResults=$max" \
        --data-urlencode "fields=summary,status,priority,issuetype")
    # update per-profile completion cache
    echo "$res" | jq -r '.issues[] | "\(.key)\t\(.fields.summary)"' > "$_JIRA_CACHE" 2>/dev/null
    echo "$res" | jq -r '
        .issues[] |
        "\u001b[36m\(.key)\u001b[0m\(" " * (14 - (.key | length)))[\(.fields.status.name)] \(.fields.summary)"
    '
}

alias jir='jira-my | fzf --ansi'

jira-search() {
    _jira_require_profile || return 1
    [[ -z "$1" ]] && { echo "Usage: jira-search <text>"; return 1; }
    local res=$(_jira_curl "$JIRA_API/search" \
        -G --data-urlencode "jql=text ~ \"$*\" ORDER BY updated DESC" \
        --data-urlencode "maxResults=15" \
        --data-urlencode "fields=summary,status,assignee,issuetype")
    echo "$res" | jq -r '
        .issues[] |
        "\(.key | . + " " * (14 - length))[\(.fields.status.name)] \(.fields.summary)"
    '
}

jira-comment() {
    _jira_require_profile || return 1
    local key="${1:u}"
    shift
    local body="$*"
    [[ -z "$key" || -z "$body" ]] && { echo "Usage: jira-comment <ISSUE-KEY> <message>"; return 1; }
    _jira_curl -X POST "$JIRA_API/issue/$key/comment" \
        -d "$(jq -n --arg b "$body" '{body: $b}')" | jq -r '"Comment added (id: \(.id))"'
}

jira-assign() {
    _jira_require_profile || return 1
    local key="${1:u}"
    local user="${2:-}"
    [[ -z "$key" ]] && { echo "Usage: jira-assign <ISSUE-KEY> [username]"; return 1; }
    local payload
    if [[ -z "$user" ]]; then
        local me=$(_jira_curl "$JIRA_API/myself" | jq -r '.name')
        payload=$(jq -n --arg n "$me" '{name: $n}')
    else
        payload=$(jq -n --arg n "$user" '{name: $n}')
    fi
    _jira_curl -X PUT "$JIRA_API/issue/$key/assignee" -d "$payload"
    echo "Assigned $key to ${user:-me}"
}

jira-status() {
    _jira_require_profile || return 1
    local key="${1:u}"
    [[ -z "$key" ]] && { echo "Usage: jira-status <ISSUE-KEY>"; return 1; }
    local res=$(_jira_curl "$JIRA_API/issue/$key/transitions")
    local choice=$(echo "$res" | jq -r '.transitions[] | "\(.id) \(.name)"' | fzf --prompt="Transition $key > ")
    [[ -z "$choice" ]] && return 0
    local tid=$(echo "$choice" | awk '{print $1}')
    _jira_curl -X POST "$JIRA_API/issue/$key/transitions" \
        -d "$(jq -n --arg id "$tid" '{transition: {id: $id}}')"
    echo "Transitioned $key -> $(echo "$choice" | cut -d' ' -f2-)"
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

compdef _jira_complete_keys jira jira-open jira-comment jira-assign jira-status
compdef _jira_complete_profiles jira-use
