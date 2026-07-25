#!/bin/bash
# global-rules plugin — remove the files the plugin deployed onto this machine.
#
# Uninstalling the plugin stops the syncing but deliberately leaves the deployed
# files in place: they are plain files under the Claude config directory and may
# well be what the user wants to keep. This script is the explicit cleanup path.
#
# Usage:
#   uninstall-cleanup.sh          list what would be removed; change nothing
#   uninstall-cleanup.sh --yes    actually remove them
#
# Only files that still match a last-deployed snapshot are removed. A file the
# user edited after deployment is kept and reported, so local work is never
# thrown away by a cleanup. Symlinked targets are never touched.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CONTENT="$PLUGIN_ROOT/content"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATE_DIR="$CLAUDE_DIR/.global-rules-state"

case "$CLAUDE_DIR" in
  "$HOME"/*) DISPLAY_DIR="~${CLAUDE_DIR#$HOME}" ;;
  "$HOME")   DISPLAY_DIR="~" ;;
  *)         DISPLAY_DIR="$CLAUDE_DIR" ;;
esac

APPLY="no"
if [ "${1:-}" = "--yes" ]; then
  APPLY="yes"
fi

removed=0
kept=0
report=""
add() { report="${report}${1}"$'\n'; }

# consider <target> <state-snapshot> <label>
consider() {
  local target="$1" state="$2" label="$3"

  if [ -L "$target" ]; then
    add "  keep    $label — symlink, managed elsewhere"
    kept=$((kept + 1))
    return 0
  fi
  if [ ! -e "$target" ]; then
    return 0
  fi
  if [ -f "$state" ] && cmp -s "$state" "$target"; then
    if [ "$APPLY" = "yes" ]; then
      rm -f "$target"
      add "  removed $label"
    else
      add "  remove  $label"
    fi
    removed=$((removed + 1))
  else
    add "  keep    $label — locally modified since deployment"
    kept=$((kept + 1))
  fi
  return 0
}

consider "$CLAUDE_DIR/CLAUDE.md" "$STATE_DIR/CLAUDE.md" "$DISPLAY_DIR/CLAUDE.md"

if [ ! -L "$CLAUDE_DIR/rules" ]; then
  for src in "$CONTENT/rules/"*.md; do
    [ -e "$src" ] || continue
    b="$(basename "$src")"
    consider "$CLAUDE_DIR/rules/$b" "$STATE_DIR/rule-$b" "$DISPLAY_DIR/rules/$b"
  done
else
  add "  keep    $DISPLAY_DIR/rules — symlink, managed elsewhere"
  kept=$((kept + 1))
fi

if [ "$removed" -eq 0 ] && [ "$kept" -eq 0 ]; then
  echo "global-rules cleanup: nothing deployed by the plugin was found in $DISPLAY_DIR"
  exit 0
fi

if [ "$APPLY" = "yes" ]; then
  echo "global-rules cleanup — removed $removed file(s), kept $kept:"
  printf '%s' "$report"
  # Drop the snapshot directory and any now-empty rules directory.
  rm -rf "$STATE_DIR"
  echo "  removed $DISPLAY_DIR/.global-rules-state/"
  if [ -d "$CLAUDE_DIR/rules" ] && [ ! -L "$CLAUDE_DIR/rules" ]; then
    rmdir "$CLAUDE_DIR/rules" 2>/dev/null && echo "  removed $DISPLAY_DIR/rules/ (empty)" || true
  fi
else
  echo "global-rules cleanup — DRY RUN ($removed to remove, $kept kept):"
  printf '%s' "$report"
  echo "Re-run with --yes to apply. The snapshot directory $DISPLAY_DIR/.global-rules-state/ is removed too."
fi
exit 0
