#!/bin/bash
# global-rules plugin — materializes the bundled global CLAUDE.md and rules
# into the Claude config directory so it is always visible on disk what is
# in place.
#
# Modes:
#   (no arg)           sync: install missing files, update files the user never
#                      edited, leave locally-modified files untouched (reported
#                      as CONFLICT).
#   --status           report the state of every managed file; change nothing.
#   --force [name...]  like sync, but overwrite locally-modified files too.
#                      With no names EVERY conflicted file is overwritten; with
#                      names only the listed ones — a name is a managed file's
#                      basename, with or without the .md suffix
#                      (e.g. `--force tool-creation CLAUDE.md`).
#
# Config directory: $CLAUDE_CONFIG_DIR when set, otherwise ~/.claude. The
# plugin therefore follows alternate environments — e.g. an alias
#   claude-nbg = CLAUDE_CONFIG_DIR="$HOME/.claude-nbg" claude
# keeps a separate set of rules for one class of projects. All report labels
# show the config directory actually in use.
#
# Conflict detection uses a last-synced snapshot kept under
# <config-dir>/.global-rules-state/: a target that differs from BOTH the plugin
# version and the snapshot was edited by the user and is never overwritten
# without --force.
#
# On a machine where <config-dir>/CLAUDE.md or <config-dir>/rules is a symlink
# (a dev machine managing the canonical copies in a repo), that part of the
# sync is skipped entirely.
#
# Deployment is atomic: content is written to a temporary file in the target
# directory and renamed into place, so an interrupted run can never leave a
# half-written rule file behind. The snapshot is only updated after the target
# is successfully in place.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CONTENT="$PLUGIN_ROOT/content"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATE_DIR="$CLAUDE_DIR/.global-rules-state"

# Label prefix for the report: the config dir in use, with $HOME shown as ~.
case "$CLAUDE_DIR" in
  "$HOME"/*) DISPLAY_DIR="~${CLAUDE_DIR#$HOME}" ;;
  "$HOME")   DISPLAY_DIR="~" ;;
  *)         DISPLAY_DIR="$CLAUDE_DIR" ;;
esac

MODE="sync"
case "${1:-}" in
  --status) MODE="status"; shift ;;
  --force)  MODE="force";  shift ;;
esac

# Remaining arguments scope --force to specific files (empty = all conflicts).
FORCE_COUNT=$#
FORCE_NAMES=""
if [ "$FORCE_COUNT" -gt 0 ]; then
  FORCE_NAMES="$*"
fi

# force_selected <managed-basename> — is this file in scope for --force?
force_selected() {
  if [ "$MODE" != "force" ]; then
    return 1
  fi
  if [ "$FORCE_COUNT" -eq 0 ]; then
    return 0
  fi
  local want="$1" n
  for n in $FORCE_NAMES; do
    if [ "$n" = "$want" ] || [ "$n.md" = "$want" ]; then
      return 0
    fi
  done
  return 1
}

report=""
add() { report="${report}${1}"$'\n'; }

# write_atomic <src> <dst> — copy via a temp file in the destination directory.
write_atomic() {
  local src="$1" dst="$2" tmp
  mkdir -p "$(dirname "$dst")"
  tmp="$dst.global-rules.$$"
  cp "$src" "$tmp"
  mv -f "$tmp" "$dst"
}

# deploy <src> <target> <state> — target first, snapshot only once it landed.
deploy() {
  write_atomic "$1" "$2"
  write_atomic "$1" "$3"
}

# handle <src> <target> <state-snapshot> <label> <managed-name>
handle() {
  local src="$1" target="$2" state="$3" label="$4" name="$5"

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
      deploy "$src" "$target" "$state"
      add "$label: installed"
    fi
    return 0
  fi

  if cmp -s "$src" "$target"; then
    if [ "$MODE" = "status" ]; then
      add "$label: in sync"
    else
      # Keep the snapshot aligned with what is deployed. --status writes nothing.
      if [ ! -f "$state" ] || ! cmp -s "$src" "$state"; then
        write_atomic "$src" "$state"
      fi
    fi
    return 0
  fi

  if [ -f "$state" ] && cmp -s "$state" "$target"; then
    # target is exactly what we last deployed -> safe to update
    if [ "$MODE" = "status" ]; then
      add "$label: UPDATE AVAILABLE (plugin ships a newer version)"
    else
      deploy "$src" "$target" "$state"
      add "$label: updated"
    fi
    return 0
  fi

  # target differs from plugin version AND from last-deployed snapshot
  if force_selected "$name"; then
    deploy "$src" "$target" "$state"
    add "$label: OVERWRITTEN (was locally modified)"
  else
    add "$label: CONFLICT — locally modified, left untouched (rerun with --force ${name%.md} to overwrite)"
  fi
  return 0
}

handle "$CONTENT/CLAUDE.md" \
       "$CLAUDE_DIR/CLAUDE.md" \
       "$STATE_DIR/CLAUDE.md" \
       "$DISPLAY_DIR/CLAUDE.md" \
       "CLAUDE.md"

if [ -L "$CLAUDE_DIR/rules" ]; then
  if [ "$MODE" = "status" ]; then
    add "$DISPLAY_DIR/rules: managed elsewhere (symlink -> $(readlink "$CLAUDE_DIR/rules")) — skipped"
  fi
else
  for src in "$CONTENT/rules/"*.md; do
    b="$(basename "$src")"
    handle "$src" \
           "$CLAUDE_DIR/rules/$b" \
           "$STATE_DIR/rule-$b" \
           "$DISPLAY_DIR/rules/$b" \
           "$b"
  done
fi

if [ "$MODE" = "status" ]; then
  printf 'global-rules status (plugin content -> %s):\n%s' "$DISPLAY_DIR" "$report"
else
  # SessionStart hook: stay silent when nothing changed, so no context noise
  if [ -n "$report" ]; then
    printf 'global-rules sync:\n%s' "$report"
  fi
fi
exit 0
