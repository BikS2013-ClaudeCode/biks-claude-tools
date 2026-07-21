#!/usr/bin/env bash
# global-rules plugin — SessionStart hook: sync the <structure-and-conventions>
# documentation-map block into the current project's CLAUDE.md.
#
# Adapted from the canonical claude-workdocs hook (~/.claude/scripts/sync-claude-md.sh).
# Source resolution:
#   1. On a machine that has the canonical setup (master copy at
#      ~/.claude/structure-and-conventions.md AND the canonical hook script at
#      ~/.claude/scripts/sync-claude-md.sh), this script exits silently — the
#      canonical mechanism owns project syncing there.
#   2. Otherwise, a master copy at ~/.claude/structure-and-conventions.md wins
#      when present; the plugin's bundled copy under content/ is the fallback.
#
# The block is delimited by <structure-and-conventions> ... </structure-and-conventions>
# tags. If the project file is missing or the block is absent/outdated it will be
# created or replaced while preserving all other project-specific content.
#
# Also removes the legacy `@~/.claude/pre-implementation-pipeline.md` import line
# wherever it still exists (that document is a user-level rule nowadays).

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

MASTER_MD="$CLAUDE_DIR/structure-and-conventions.md"
CANONICAL_HOOK="$CLAUDE_DIR/scripts/sync-claude-md.sh"
BUNDLED_MD="$PLUGIN_ROOT/content/structure-and-conventions.md"

# Dev machine with the canonical mechanism in place — it owns project syncing.
if [ -f "$MASTER_MD" ] && [ -f "$CANONICAL_HOOK" ]; then
  exit 0
fi

if [ -f "$MASTER_MD" ]; then
  GLOBAL_MD="$MASTER_MD"
else
  GLOBAL_MD="$BUNDLED_MD"
fi

# Import wired by an earlier hook version; removed wherever still found.
LEGACY_IMPORT='@~/.claude/pre-implementation-pipeline.md'

# Never write a CLAUDE.md into the home directory itself — the user-level
# config lives in ~/.claude/CLAUDE.md and a copy here would double-load.
if [ "$PWD" = "$HOME" ]; then
  exit 0
fi

# Resolve the project CLAUDE.md. An existing ./CLAUDE.md at the session cwd is
# always the sync target (nested project layouts keep their own CLAUDE.md files).
# Only when no CLAUDE.md exists here does the git toplevel decide where — and
# whether — a new one is created, so a session started in a plain subdirectory
# of a repo does not scatter spurious CLAUDE.md files.
if [ -f "./CLAUDE.md" ]; then
  PROJECT_MD="./CLAUDE.md"
elif GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  PROJECT_MD="$GIT_ROOT/CLAUDE.md"
  if [ "$PROJECT_MD" = "$HOME/CLAUDE.md" ]; then
    exit 0
  fi
else
  # Not a project directory — nothing to sync.
  exit 0
fi

# ── helpers ──────────────────────────────────────────────────────────────────

# Extract everything between the open/close tags (inclusive).
extract_block() {
  awk '
    /^<structure-and-conventions>$/ { found=1 }
    found { print }
    /^<\/structure-and-conventions>$/ { if (found) exit }
  ' "$1"
}

# Print lines BEFORE the block.
print_before() {
  awk '
    /^<structure-and-conventions>$/ { exit }
    { print }
  ' "$1"
}

# Print lines AFTER the block.
print_after() {
  awk '
    found { print; next }
    /^<\/structure-and-conventions>$/ { found=1 }
  ' "$1"
}

# Remove the legacy pipeline import line from the project CLAUDE.md, if present.
remove_legacy_import() {
  [ -f "$PROJECT_MD" ] || return 0
  if grep -qF "$LEGACY_IMPORT" "$PROJECT_MD"; then
    grep -vF "$LEGACY_IMPORT" "$PROJECT_MD" > "$PROJECT_MD.tmp"
    mv "$PROJECT_MD.tmp" "$PROJECT_MD"
    echo "global-rules CLAUDE.md sync: removed legacy import $LEGACY_IMPORT from $PROJECT_MD"
  fi
}

# ── guard ────────────────────────────────────────────────────────────────────

if [ ! -f "$GLOBAL_MD" ]; then
  echo "global-rules CLAUDE.md sync: source not found at $GLOBAL_MD — skipped"
  exit 0
fi

GLOBAL_BLOCK=$(extract_block "$GLOBAL_MD")

if [ -z "$GLOBAL_BLOCK" ]; then
  echo "global-rules CLAUDE.md sync: no <structure-and-conventions> block in $GLOBAL_MD — skipped"
  exit 0
fi

# ── project file does not exist ──────────────────────────────────────────────

if [ ! -f "$PROJECT_MD" ]; then
  # Reaching here means PROJECT_MD is the git toplevel of an actual project
  # (the resolution above already skipped non-repo directories without a
  # CLAUDE.md), so creating the file is always intended.
  printf '%s\n' "$GLOBAL_BLOCK" > "$PROJECT_MD"
  echo "global-rules CLAUDE.md sync: created $PROJECT_MD with Structure & Conventions block"
  exit 0
fi

# ── project file exists — compare ────────────────────────────────────────────

PROJECT_BLOCK=$(extract_block "$PROJECT_MD")

if [ "$GLOBAL_BLOCK" = "$PROJECT_BLOCK" ]; then
  # Up to date — stay silent (SessionStart hook, avoid context noise).
  remove_legacy_import
  exit 0
fi

# ── replace or insert ────────────────────────────────────────────────────────

if [ -z "$PROJECT_BLOCK" ]; then
  # No block found — prepend the global block before existing content
  REMAINING=$(cat "$PROJECT_MD")
  {
    printf '%s\n\n' "$GLOBAL_BLOCK"
    printf '%s\n' "$REMAINING"
  } > "$PROJECT_MD.tmp"
else
  # Block exists but is outdated — replace it
  BEFORE=$(print_before "$PROJECT_MD")
  AFTER=$(print_after "$PROJECT_MD")

  {
    if [ -n "$BEFORE" ]; then
      printf '%s\n' "$BEFORE"
    fi
    printf '%s\n' "$GLOBAL_BLOCK"
    if [ -n "$AFTER" ]; then
      printf '%s\n' "$AFTER"
    fi
  } > "$PROJECT_MD.tmp"
fi

mv "$PROJECT_MD.tmp" "$PROJECT_MD"
echo "global-rules CLAUDE.md sync: updated Structure & Conventions block in $PROJECT_MD"
remove_legacy_import
