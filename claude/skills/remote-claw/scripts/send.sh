#!/bin/bash
# send.sh — Send a prompt to remote OpenClaw (non-streaming, returns content only)
# Usage: ./scripts/send.sh "do something"

PROMPT="$1"
if [ -z "$PROMPT" ]; then
  echo "Usage: send.sh <prompt>"
  exit 1
fi

# Escape prompt for JSON
ESCAPED=$(echo "$PROMPT" | jq -Rs .)

curl -s http://localhost:18789/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"openclaw:main\",
    \"stream\": false,
    \"messages\": [{\"role\": \"user\", \"content\": $ESCAPED}]
  }" | jq -r '.choices[0].message.content // .error.message // .'
