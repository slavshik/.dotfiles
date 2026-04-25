#!/bin/bash
# send-stream.sh — Send a prompt with streaming output (live)
# Usage: ./scripts/send-stream.sh "build the thing"

PROMPT="$1"
if [ -z "$PROMPT" ]; then
  echo "Usage: send-stream.sh <prompt>"
  exit 1
fi

ESCAPED=$(echo "$PROMPT" | jq -Rs .)

curl -s -N --no-buffer http://localhost:18789/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"openclaw:main\",
    \"stream\": true,
    \"messages\": [{\"role\": \"user\", \"content\": $ESCAPED}]
  }"
