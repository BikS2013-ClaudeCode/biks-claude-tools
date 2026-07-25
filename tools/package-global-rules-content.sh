#!/usr/bin/env bash
# Maintainer tool — repackage plugins/global-rules/content/ from the canonical
# sources, or check whether the packaged copies have drifted from them.
#
# The canonical sources live in a separate working repo (default:
# ~/claude-workdocs/.claude). Override with CANONICAL_ROOT.
#
# Usage:
#   tools/package-global-rules-content.sh --check    report drift, change nothing (exit 1 if drifted)
#   tools/package-global-rules-content.sh            copy the canonical sources into content/
#
# Run --check before every release: a packaged copy that lags the canonical
# master makes the <structure-and-conventions> block flip-flop between machines
# that have the master and machines that only have the plugin.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTENT="$REPO_ROOT/plugins/global-rules/content"
CANONICAL_ROOT="${CANONICAL_ROOT:-$HOME/claude-workdocs/.claude}"

MODE="package"
if [ "${1:-}" = "--check" ]; then
  MODE="check"
fi

if [ ! -d "$CANONICAL_ROOT" ]; then
  echo "package-global-rules-content: canonical sources not found at $CANONICAL_ROOT" >&2
  echo "(set CANONICAL_ROOT to the .claude folder of the working repo)" >&2
  exit 2
fi

drift=0

# compare_or_copy <canonical-file> <packaged-file>
compare_or_copy() {
  local src="$1" dst="$2" rel="${2#$REPO_ROOT/}"
  if [ ! -f "$src" ]; then
    echo "MISSING SOURCE  $src" >&2
    drift=1
    return 0
  fi
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    return 0
  fi
  if [ "$MODE" = "check" ]; then
    if [ -f "$dst" ]; then
      echo "DRIFTED  $rel"
    else
      echo "MISSING  $rel"
    fi
    drift=1
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "packaged $rel"
  fi
}

compare_or_copy "$CANONICAL_ROOT/CLAUDE.md" "$CONTENT/CLAUDE.md"
compare_or_copy "$CANONICAL_ROOT/structure-and-conventions.md" "$CONTENT/structure-and-conventions.md"

for src in "$CANONICAL_ROOT/rules/"*.md; do
  [ -e "$src" ] || continue
  compare_or_copy "$src" "$CONTENT/rules/$(basename "$src")"
done

# Packaged rules with no canonical counterpart are stale (e.g. a retired rule).
for dst in "$CONTENT/rules/"*.md; do
  [ -e "$dst" ] || continue
  b="$(basename "$dst")"
  if [ ! -f "$CANONICAL_ROOT/rules/$b" ]; then
    if [ "$MODE" = "check" ]; then
      echo "STALE    plugins/global-rules/content/rules/$b (no canonical source — retired?)"
      drift=1
    else
      rm "$dst"
      echo "removed  plugins/global-rules/content/rules/$b (no canonical source)"
    fi
  fi
done

if [ "$MODE" = "check" ]; then
  if [ "$drift" -eq 0 ]; then
    echo "content/ is in sync with $CANONICAL_ROOT"
    exit 0
  fi
  echo "content/ has drifted — run tools/package-global-rules-content.sh to refresh" >&2
  exit 1
fi

echo "content/ refreshed from $CANONICAL_ROOT"
