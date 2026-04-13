#!/usr/bin/env bash
# Claude Code Notification hook → macOS desktop notification.
# Reads hook JSON on stdin, dispatches on notification_type.

set -euo pipefail

input=$(cat)
ntype=$(jq -r '.notification_type // empty' <<<"$input")
message=$(jq -r '.message // empty' <<<"$input")

case "$ntype" in
    permission_prompt)
        title="Claude Code - Permission Required"
        body="${message:-Claude needs your permission to continue}"
        ;;
    idle_prompt)
        title="Claude Code - Waiting"
        body="${message:-Claude is waiting for your input}"
        ;;
    *)
        exit 0
        ;;
esac

terminal-notifier \
    -title "$title" \
    -message "$body" \
    -sound Ping \
    -group "claude-code-$ntype" \
    >/dev/null 2>&1 || true
