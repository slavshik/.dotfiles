#!/bin/bash
# tunnel-down.sh — Tear down the SSH tunnel
# Usage: ./tunnel-down.sh [host]

HOST="${1:-wkwkwk.ngrok.app}"
SOCKET="/tmp/remote-claw-ctrl"

ssh -S "$SOCKET" -O exit "$HOST" 2>/dev/null && echo "tunnel down" || {
  pkill -f "ssh.*-L 18789.*wkwkwk.ngrok.app" 2>/dev/null
  echo "tunnel killed (force)"
}
