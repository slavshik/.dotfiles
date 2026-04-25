#!/bin/bash
# tunnel-up.sh — Establish SSH tunnel to remote OpenClaw
# Usage: ./tunnel-up.sh [host]

HOST="${1:-wkwkwk.ngrok.app}"
SOCKET="/tmp/remote-claw-ctrl"

# Already up?
if ssh -S "$SOCKET" -O check "$HOST" 2>/dev/null; then
  echo "tunnel already up"
  exit 0
fi

# Fresh tunnel
ssh -f -N -M -S "$SOCKET" -L 18789:127.0.0.1:18789 "$HOST" && echo "tunnel up"
