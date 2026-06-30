#!/usr/bin/env bash
# Streams N Conventional Commits suggestions to stdout, one per line, as each
# parallel request returns. Cerebras (fast, free cloud) is primary; a local
# Ollama instance (e.g. on a Mac mini) is the fallback.
# Consumed by aicommit-pick.sh (an fzf streaming picker) and runnable on its own.
set -uo pipefail

# Route to an org-specific suggester if one exists.
if git remote get-url origin 2>/dev/null | grep -q '\.evolution\.com' \
    && [ -x "$HOME/.dotfiles/evolution/aicommit-suggest.sh" ]; then
    exec "$HOME/.dotfiles/evolution/aicommit-suggest.sh"
fi

N="${AICOMMIT_N:-3}"
CEREBRAS_MODEL="${AICOMMIT_CEREBRAS_MODEL:-gpt-oss-120b}"
OLLAMA_MODEL="${AICOMMIT_OLLAMA_MODEL:-qwen2.5-coder:14b}"
CEREBRAS_BASE="https://api.cerebras.ai/v1"

# Ollama base URL. Honors a full override (AICOMMIT_OLLAMA_BASE), auto-detects
# ngrok tunnels (served over https/443, not :11434), else uses host:11434.
if [ -n "${AICOMMIT_OLLAMA_BASE:-}" ]; then
    OLLAMA_BASE="$AICOMMIT_OLLAMA_BASE"
elif [[ "${OLLAMA_HOST:-}" == *.ngrok.app || "${OLLAMA_HOST:-}" == *.ngrok-free.app || "${OLLAMA_HOST:-}" == *.ngrok.io ]]; then
    OLLAMA_BASE="https://${OLLAMA_HOST}/v1"
else
    OLLAMA_BASE="http://${OLLAMA_HOST:-localhost}:11434/v1"
fi

DIFF=$(git --no-pager diff --no-color --no-ext-diff --cached | head -c 12000)

if [ -z "$DIFF" ]; then
    echo "No staged changes — stage files first." >&2
    exit 1
fi

SYSTEM="You are a commit message generator. Output ONE Conventional Commits message and nothing else: no quotes, no markdown, no code fences, no preamble. Format: <type>(optional scope): <description>. Types: feat, fix, docs, style, refactor, perf, test, chore, build, ci. Imperative mood, no trailing period, <= 72 characters."

# Per-call hints to nudge the parallel calls toward distinct suggestions.
STYLES=(
    "Keep it concise."
    "Include a scope in parentheses."
    "Emphasize the user-facing effect of the change."
    "Be specific about what changed."
    "Prefer a broad, high-level summary."
)

# Build an OpenAI-compatible chat payload. $1=model, $2=style hint.
payload() {
    local extra='{}'
    case "$1" in *gpt-oss*) extra='{"reasoning_effort":"low"}' ;; esac
    jq -n --arg m "$1" --arg sys "$SYSTEM" \
        --arg user "$2"$'\nSuggest one commit message for the following staged diff:\n```diff\n'"$DIFF"$'\n```' \
        --argjson extra "$extra" \
        '{model: $m, temperature: 0.8, max_tokens: 256,
          messages: [{role: "system", content: $sys}, {role: "user", content: $user}]} + $extra'
}

# Extract the first valid Conventional Commits line, capped at 72 chars, with
# any wrapping quotes/backticks/trailing whitespace trimmed.
clean() {
    grep -oiE '(feat|fix|docs|style|refactor|perf|test|chore|build|ci)(\([^)]+\))?!?: .+' \
        | head -n1 | cut -c1-72 | sed -E "s/[\"\`'[:space:]]+\$//"
}

# Generate one message: try Cerebras, fall back to local Ollama. $1=style hint.
gen_one() {
    local out=""
    if [ -n "${CEREBRAS_API_KEY:-}" ]; then
        out=$(curl -s --max-time 6 "$CEREBRAS_BASE/chat/completions" \
            -H "Authorization: Bearer $CEREBRAS_API_KEY" \
            -H 'Content-Type: application/json' \
            -d "$(payload "$CEREBRAS_MODEL" "$1")" \
            | jq -r '.choices[0].message.content // empty' | clean)
    fi
    if [ -z "$out" ]; then
        out=$(curl -s --max-time 45 "$OLLAMA_BASE/chat/completions" \
            -H 'Content-Type: application/json' \
            -H 'ngrok-skip-browser-warning: true' \
            -d "$(payload "$OLLAMA_MODEL" "$1")" \
            | jq -r '.choices[0].message.content // empty' | clean)
    fi
    # Single atomic write (< PIPE_BUF) so parallel lines never interleave.
    [ -n "$out" ] && printf '%s\n' "$out"
}

for i in $(seq 0 $((N - 1))); do
    gen_one "${STYLES[$((i % ${#STYLES[@]}))]}" &
done
wait
exit 0
