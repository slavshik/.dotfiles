#!/usr/bin/env zsh
# daily-summary.sh — Collect yesterday's work activity across Jira, GitLab, Git
# Part of ~/.dotfiles — works on any machine with the dotfiles installed
#
# Usage:
#   ./daily-summary.sh              # yesterday's summary (JSON to stdout)
#   ./daily-summary.sh --days 3     # last 3 days
#   ./daily-summary.sh --send       # send via Telegram
#   ./daily-summary.sh --pretty     # human-readable instead of JSON
#
# Requires: curl, jq. Optional: glab (GitLab), gh (GitHub)

set -uo pipefail

DAYS=1
SEND=false
PRETTY=false
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --days) DAYS="$2"; shift 2 ;;
        --send) SEND=true; shift ;;
        --pretty) PRETTY=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--days N] [--send] [--pretty]"
            exit 0 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

SINCE_DATE=$(date -v-${DAYS}d +%Y-%m-%d 2>/dev/null || date -d "$DAYS days ago" +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)
HOST=$(hostname -s)

echo "📊 Collecting activity since $SINCE_DATE on $HOST..." >&2

# --- Load dotfiles auth (zsh needed for associative arrays) ---
typeset -gA _JIRA_PROFILES
source "$DOTFILES_DIR/zsh/jira.zsh" 2>/dev/null

# Source company .secure.zsh files for env vars
for f in "$DOTFILES_DIR"/evolution/.secure.zsh "$DOTFILES_DIR"/ela/.secure.zsh; do
    [[ -f "$f" && -s "$f" ]] && source "$f" 2>/dev/null
done
# Source company index.zsh (registers jira profiles)
for f in "$DOTFILES_DIR"/evolution/index.zsh "$DOTFILES_DIR"/ela/index.zsh; do
    [[ -f "$f" ]] && source "$f" 2>/dev/null
done

# --- Jira: iterate registered profiles ---
collect_jira() {
    local all_issues="[]"
    for label in ${(k)_JIRA_PROFILES}; do
        local entry="${_JIRA_PROFILES[$label]}"
        local host="${entry%%|*}"
        local rest="${entry#*|}"
        local pat_var="${rest%%|*}"
        local auth_type="${rest#*|}"
        local token="${(P)pat_var}"

        [[ -z "$token" ]] && { echo "  ⚠️  $label: no token (\$$pat_var empty)" >&2; continue; }

        local auth_header
        case "$auth_type" in
            bearer) auth_header="Authorization: Bearer $token" ;;
            basic)  auth_header="Authorization: Basic $token" ;;
            *)      auth_header="Authorization: Bearer $token" ;;
        esac

        local jql="assignee=currentUser() AND updated >= \"$SINCE_DATE\" ORDER BY updated DESC"
        local result
        result=$(curl -s --max-time 10 \
            -H "$auth_header" \
            -H "Content-Type: application/json" \
            "$host/rest/api/2/search" \
            -G --data-urlencode "jql=$jql" \
            --data-urlencode "maxResults=50" \
            --data-urlencode "fields=summary,status,priority,issuetype,updated,comment" 2>/dev/null)

        local issues
        issues=$(echo "$result" | jq -c --arg lbl "$label" '[.issues[]? | {
            profile: $lbl,
            key: .key,
            type: .fields.issuetype.name,
            summary: .fields.summary,
            status: .fields.status.name,
            updated: .fields.updated
        }]' 2>/dev/null || echo "[]")

        local count=$(echo "$issues" | jq length)
        echo "  $label: $count issues" >&2
        all_issues=$(echo "$all_issues $issues" | jq -sc '.[0] + .[1]')
    done
    echo "$all_issues"
}

# --- GitLab MRs (via glab) ---
collect_gitlab() {
    if ! command -v glab &>/dev/null; then
        echo "  glab not installed, skipping" >&2
        echo "[]"
        return
    fi
    local mrs
    mrs=$(glab api "merge_requests?scope=created_by_me&updated_after=${SINCE_DATE}T00:00:00Z&per_page=50" 2>/dev/null | \
        jq -c '[.[]? | {
            id: .iid,
            title: .title,
            state: .state,
            url: .web_url,
            project: .references.full,
            updated: .updated_at,
            merged: .merged_at
        }]' 2>/dev/null || echo "[]")
    echo "  MRs: $(echo "$mrs" | jq length)" >&2
    echo "$mrs"
}

# --- GitHub PRs (via gh) ---
collect_github() {
    if ! command -v gh &>/dev/null; then
        echo "  gh not installed, skipping" >&2
        echo "[]"
        return
    fi
    local prs
    prs=$(gh api "search/issues?q=author:@me+type:pr+updated:>=$SINCE_DATE&per_page=50" 2>/dev/null | \
        jq -c '[.items[]? | {
            id: .number,
            title: .title,
            state: .state,
            url: .html_url,
            repo: .repository_url | split("/") | .[-1],
            updated: .updated_at
        }]' 2>/dev/null || echo "[]")
    echo "  PRs: $(echo "$prs" | jq length)" >&2
    echo "$prs"
}

# --- Git commits (scan repos) ---
collect_git() {
    local email=$(git config --global user.email 2>/dev/null || echo "")
    [[ -z "$email" ]] && { echo "[]"; return; }

    local all_commits="[]"
    local search_dirs=("$HOME/projects" "$HOME/dev" "$HOME/work" )

    for dir in "${search_dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        for repo in $(find "$dir" -maxdepth 2 -name ".git" -type d 2>/dev/null); do
            local repo_dir=$(dirname "$repo")
            local repo_name=$(basename "$repo_dir")
            local commits
            commits=$(cd "$repo_dir" && git log \
                --author="$email" \
                --since="$SINCE_DATE" \
                --format='{"hash":"%h","message":"%s","date":"%ci"}' \
                --all 2>/dev/null | jq -sc --arg r "$repo_name" '[.[] | . + {repo: $r}]' 2>/dev/null || echo "[]")
            all_commits=$(echo "$all_commits $commits" | jq -sc '.[0] + .[1]')
        done
    done
    echo "  Commits: $(echo "$all_commits" | jq length)" >&2
    echo "$all_commits"
}

# --- Collect all ---
echo "  → Jira..." >&2
JIRA=$(collect_jira)
echo "  → GitLab..." >&2
GITLAB=$(collect_gitlab)
echo "  → GitHub..." >&2
GITHUB=$(collect_github)
echo "  → Git..." >&2
GIT=$(collect_git)

# --- Build JSON ---
SUMMARY=$(jq -nc \
    --arg since "$SINCE_DATE" \
    --arg until "$TODAY" \
    --arg host "$HOST" \
    --argjson jira "$JIRA" \
    --argjson gitlab "$GITLAB" \
    --argjson github "$GITHUB" \
    --argjson git "$GIT" \
    '{
        period: {since: $since, until: $until},
        host: $host,
        jira: $jira,
        gitlab: $gitlab,
        github: $github,
        git: $git,
        totals: {
            jira: ($jira | length),
            gitlab: ($gitlab | length),
            github: ($github | length),
            git: ($git | length)
        }
    }')

echo "" >&2

if $PRETTY; then
    echo "═══════════════════════════════════════"
    echo "  📊 Daily Summary — $HOST"
    echo "  📅 $SINCE_DATE → $TODAY"
    echo "═══════════════════════════════════════"
    echo ""

    local jira_count=$(echo "$SUMMARY" | jq '.totals.jira')
    if (( jira_count > 0 )); then
        echo "🎫 Jira ($jira_count issues)"
        echo "$SUMMARY" | jq -r '.jira[] | "  [\(.status)] \(.key) — \(.summary)"'
        echo ""
    fi

    local gl_count=$(echo "$SUMMARY" | jq '.totals.gitlab')
    if (( gl_count > 0 )); then
        echo "🦊 GitLab MRs ($gl_count)"
        echo "$SUMMARY" | jq -r '.gitlab[] | "  [\(.state)] !\(.id) — \(.title)"'
        echo ""
    fi

    local gh_count=$(echo "$SUMMARY" | jq '.totals.github')
    if (( gh_count > 0 )); then
        echo "🐙 GitHub PRs ($gh_count)"
        echo "$SUMMARY" | jq -r '.github[] | "  [\(.state)] #\(.id) — \(.title)"'
        echo ""
    fi

    local git_count=$(echo "$SUMMARY" | jq '.totals.git')
    if (( git_count > 0 )); then
        echo "📝 Git commits ($git_count)"
        echo "$SUMMARY" | jq -r '.git[] | "  \(.repo): \(.hash) \(.message)"'
        echo ""
    fi
else
    echo "$SUMMARY" | jq .
fi

# --- Send ---
if $SEND; then
    if [[ -n "${JOBBY_TG_TOKEN:-}" && -n "${JOBBY_TG_CHAT:-}" ]]; then
        local tmp_file="/tmp/daily-summary-$(date +%Y%m%d).json"
        echo "$SUMMARY" | jq . > "$tmp_file"
        curl -s -X POST "https://api.telegram.org/bot${JOBBY_TG_TOKEN}/sendDocument" \
            -F chat_id="$JOBBY_TG_CHAT" \
            -F document="@${tmp_file}" \
            -F caption="📊 Daily summary from $HOST" > /dev/null 2>&1
        echo "📤 Sent to Telegram" >&2
    else
        echo "⚠️  Set JOBBY_TG_TOKEN + JOBBY_TG_CHAT for --send" >&2
    fi
fi
