#!/usr/bin/env bash
# Interactive AI commit picker, invoked by lazygit's <c-j> (output: terminal).
# Streams suggestions from aicommit-suggest.sh into fzf so each message appears
# one-by-one with fzf's live spinner, then lets you edit the choice and commit.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for dep in fzf jq curl; do
    command -v "$dep" >/dev/null 2>&1 || {
        echo "Missing dependency: $dep (install via Brewfile)."; sleep 2; exit 1
    }
done

root=$(git rev-parse --show-toplevel 2>/dev/null) || true
if [ -z "$root" ]; then
    echo "Not in a git repository."; sleep 1.2; exit 0
fi
cd "$root" || exit 1

if git diff --cached --quiet; then
    echo "No staged changes — stage files first."; sleep 1.2; exit 0
fi

count_file=$(mktemp)
trap 'rm -f "$count_file"' EXIT

# Stream suggestions into fzf. awk drops blanks/exact dupes, fflush() keeps the
# stream live (entries pop in as each request returns), and records the count so
# we can tell "user cancelled" from "nothing was generated".
sel=$(
    bash "$SCRIPT_DIR/aicommit-suggest.sh" \
        | awk -v cf="$count_file" 'NF && !seen[$0]++ { print; fflush(); c++ } END { print c+0 > cf }' \
        | fzf --no-sort --reverse --cycle --height=100% --border --info=inline \
              --prompt 'commit> ' \
              --header 'AI suggestions  -  enter: pick  -  esc/ctrl-c: cancel'
)

if [ -z "$sel" ]; then
    if [ "$(cat "$count_file" 2>/dev/null || echo 0)" = "0" ]; then
        echo "No suggestions generated — check CEREBRAS_API_KEY or Ollama (OLLAMA_HOST)."
    else
        echo "Cancelled — no commit made."
    fi
    sleep 1.2; exit 0
fi

# Edit the chosen message before committing: prefilled + editable on bash 4+,
# otherwise fall back to $EDITOR on a temp file.
final=""
if (( ${BASH_VERSINFO[0]:-0} >= 4 )); then
    read -e -i "$sel" -r -p 'edit> ' final
else
    tmp=$(mktemp)
    printf '%s\n' "$sel" > "$tmp"
    "${EDITOR:-vi}" "$tmp"
    final=$(head -n1 "$tmp")
    rm -f "$tmp"
fi
final="${final:-$sel}"

git commit -m "$final"
