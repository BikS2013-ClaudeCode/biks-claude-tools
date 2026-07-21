#!/bin/bash
# global-rules plugin — materializes the bundled global CLAUDE.md and rules
# into ~/.claude so it is always visible on disk what is in place.
#
# Modes:
#   (no arg)   sync: install missing files, update files the user never edited,
#              leave locally-modified files untouched (reported as CONFLICT).
#   --status   report the state of every managed file; change nothing.
#   --force    like sync, but overwrite locally-modified files too.
#
# Conflict detection uses a last-synced snapshot kept under
# ~/.claude/.global-rules-state/: a target that differs from BOTH the plugin
# version and the snapshot was edited by the user and is never overwritten
# without --force.
#
# On a machine where ~/.claude/CLAUDE.md or ~/.claude/rules is a symlink
# (a dev machine managing the canonical copies in a repo), that part of the
# sync is skipped entirely.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CONTENT="$PLUGIN_ROOT/content"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATE_DIR="$CLAUDE_DIR/.global-rules-state"

MODE="sync"
case "${1:-}" in
  --status) MODE="status" ;;
  --force)  MODE="force" ;;
esac

mkdir -p "$STATE_DIR"

report=""
add() { report="${report}${1}"$'\n'; }

# handle <src> <target> <state-snapshot> <label>
handle() {
  local src="$1" target="$2" state="$3" label="$4"

  if [ -L "$target" ]; then
    if [ "$MODE" = "status" ]; then
      add "$label: managed elsewhere (symlink -> $(readlink "$target")) — skipped"
    fi
    return 0
  fi

  if [ ! -e "$target" ]; then
    if [ "$MODE" = "status" ]; then
      add "$label: NOT INSTALLED"
    else
      mkdir -p "$(dirname "$target")"
      cp "$src" "$target"
      cp "$src" "$state"
      add "$label: installed"
    fi
    return 0
  fi

  if cmp -s "$src" "$target"; then
    if [ "$MODE" = "status" ]; then
      add "$label: in sync"
    fi
    cp "$src" "$state"
    return 0
  fi

  if [ -f "$state" ] && cmp -s "$state" "$target"; then
    # target is exactly what we last deployed -> safe to update
    if [ "$MODE" = "status" ]; then
      add "$label: UPDATE AVAILABLE (plugin ships a newer version)"
    else
      cp "$src" "$target"
      cp "$src" "$state"
      add "$label: updated"
    fi
    return 0
  fi

  # target differs from plugin version AND from last-deployed snapshot
  if [ "$MODE" = "force" ]; then
    cp "$src" "$target"
    cp "$src" "$state"
    add "$label: OVERWRITTEN (was locally modified)"
  else
    add "$label: CONFLICT — locally modified, left untouched (rerun with --force to overwrite)"
  fi
  return 0
}

handle "$CONTENT/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "$STATE_DIR/CLAUDE.md" "~/.claude/CLAUDE.md"

if [ -L "$CLAUDE_DIR/rules" ]; then
  if [ "$MODE" = "status" ]; then
    add "~/.claude/rules: managed elsewhere (symlink -> $(readlink "$CLAUDE_DIR/rules")) — skipped"
  fi
else
  for src in "$CONTENT/rules/"*.md; do
    b="$(basename "$src")"
    handle "$src" "$CLAUDE_DIR/rules/$b" "$STATE_DIR/rule-$b" "~/.claude/rules/$b"
  done
fi

if [ "$MODE" = "status" ]; then
  printf 'global-rules status (plugin content -> this machine):\n%s' "$report"
else
  # SessionStart hook: stay silent when nothing changed, so no context noise
  if [ -n "$report" ]; then
    printf 'global-rules sync:\n%s' "$report"
  fi
fi
exit 0
