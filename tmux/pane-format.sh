#!/bin/bash
PANE_INDEX="$1"
PANE_ACTIVE="$2"
# $3 = pane_current_path (unused)
PANE_CMD="$4"

PLUGIN_BIN="$HOME/.tmux/plugins/tmux-nerd-font-window-name/bin/tmux-nerd-font-window-name"

# Strip path prefix; map bare semver strings to "claude" (Claude Code binary is named like "2.1.116")
normalize_cmd() {
  local cmd="${1##*/}"
  echo "$cmd" | sed -E 's/^[0-9]+\.[0-9]+\.[0-9]+$/claude/'
}

CMD_NORMALIZED=$(normalize_cmd "$PANE_CMD")
ICON=$("$PLUGIN_BIN" "$CMD_NORMALIZED" 1 2>/dev/null)

# Catppuccin Mocha — pill colors intentionally differ from border colors so caps are visible:
#   active border = teal (#94e2d5)  → active pill = mauve (matches active window tab)
#   inactive border = surface0 (#313244) → inactive pill = surface1 (#45475a)
MAUVE="#cba6f7"
SURFACE1="#45475a"
SUBTEXT0="#a6adc8"
MANTLE="#181825"
BASE="#1e1e2e"   # explicit terminal background — avoids "bg=default" ambiguity in border context

CAP_LEFT=""   # U+E0B6 — left rounded cap
CAP_RIGHT=""  # U+E0B4 — right rounded cap

if [ "$PANE_ACTIVE" = "1" ]; then
  printf "#[fg=${MAUVE},bg=${BASE}]${CAP_LEFT}#[fg=${MANTLE},bg=${MAUVE},bold] ${ICON} %s #[fg=${MAUVE},bg=${BASE}]${CAP_RIGHT}" "${PANE_INDEX}"
else
  printf "#[fg=${SURFACE1},bg=${BASE}]${CAP_LEFT}#[fg=${SUBTEXT0},bg=${SURFACE1}] ${ICON} %s #[fg=${SURFACE1},bg=${BASE}]${CAP_RIGHT}" "${PANE_INDEX}"
fi
