#!/usr/bin/env bash
# Shared helpers for git hooks (sourced, not executed). Targets bash 3.2.

if [ -t 2 ]; then
  _C_YEL=$'\033[33m'; _C_RED=$'\033[31m'; _C_GRN=$'\033[32m'; _C_RST=$'\033[0m'
else
  _C_YEL=''; _C_RED=''; _C_GRN=''; _C_RST=''
fi

HOOK_FAILED=0

# staged <glob>...  → staged (added/copied/modified) files matching any glob.
staged() {
  local f g
  while IFS= read -r f; do
    for g in "$@"; do
      # shellcheck disable=SC2053  # glob match is intentional
      if [[ $f == $g ]]; then printf '%s\n' "$f"; break; fi
    done
  done < <(git diff --cached --name-only --diff-filter=ACM)
}

has() { command -v "$1" >/dev/null 2>&1; }

skip() {
  printf '%s⚠ %s not installed — skipping (brew install %s)%s\n' \
    "$_C_YEL" "$1" "${2:-$1}" "$_C_RST" >&2
}

fail() {
  printf '%s✘ %s%s\n' "$_C_RED" "$1" "$_C_RST" >&2
  HOOK_FAILED=1
}

pass() { printf '%s✔ %s%s\n' "$_C_GRN" "$1" "$_C_RST"; }
