#!/usr/bin/env bash
# next-handoff-name.sh — print the full path for the CURRENT session's next
# handoff document under <active project>/handoff/ (a "handoff" folder in
# the directory the session runs in, created on demand). Handoffs live WITH
# the project they describe, not in a central archive.
#
# Naming: <session-name>-NNN.md with NNN an incremental sequence:
#   001 .. 999, then A01 .. A99, B01 .. B99, ... Z99.
# Numbering is per project folder (it scans only $PWD/handoff).
#
# The current session is detected from the live registry <config-dir>/sessions/
# (the busy session in this cwd with the freshest status update). Pass an
# explicit session name as $1 to override detection.
# Override the target folder with CLAUDE_HANDOFF_DIR (used by tests).
set -euo pipefail

HANDOFF_DIR="${CLAUDE_HANDOFF_DIR:-$PWD/handoff}"
SESSIONS_DIR="${CLAUDE_SESSIONS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/sessions}"

name="${1:-}"
if [ -z "$name" ]; then
  if ! ls "$SESSIONS_DIR"/*.json >/dev/null 2>&1; then
    echo "next-handoff-name: no session registry found in $SESSIONS_DIR" >&2
    exit 1
  fi
  name=$(jq -rs --arg cwd "$PWD" '
    [.[] | select(.cwd == $cwd and .status == "busy")]
    | sort_by(.statusUpdatedAt) | last | .name // empty' "$SESSIONS_DIR"/*.json)
  if [ -z "$name" ]; then
    echo "next-handoff-name: could not detect the current session in $SESSIONS_DIR (no busy session for cwd $PWD)" >&2
    exit 1
  fi
fi

# sanitize for use as a filename. The U+200B strip covers the one-prompt window
# after a /clear during which the title carries the badge-restore marker (see
# session-name-common.sh) — without it a handoff would be filed under a name that
# looks identical to the real one but does not match it.
name=${name//$(printf '\342\200\213')/}
name=$(printf '%s' "$name" | tr '/ ' '--')

mkdir -p "$HANDOFF_DIR"

# rank of a suffix: 001-999 -> 1-999; A01-Z99 -> 999 + letter*99 + dd
rank_of() {
  local s="$1" l idx
  case "$s" in
    [0-9][0-9][0-9]) echo $((10#$s)) ;;
    [A-Z][0-9][0-9])
      l=${s:0:1}
      idx=$(( $(printf '%d' "'$l") - 65 ))
      echo $((999 + idx * 99 + 10#${s:1:2})) ;;
    *) echo 0 ;;
  esac
}

local_max=0
for f in "$HANDOFF_DIR/$name"-???.md; do
  [ -e "$f" ] || continue
  suffix=$(basename "$f" .md)
  suffix=${suffix##*-}
  r=$(rank_of "$suffix")
  [ "$r" -gt "$local_max" ] && local_max=$r
done

next=$((local_max + 1))
if [ "$next" -le 999 ]; then
  suffix=$(printf '%03d' "$next")
else
  rr=$((next - 999))
  idx=$(( (rr - 1) / 99 ))
  dd=$(( (rr - 1) % 99 + 1 ))
  if [ "$idx" -gt 25 ]; then
    echo "next-handoff-name: sequence exhausted (beyond Z99) for '$name'" >&2
    exit 1
  fi
  letter=$(printf "\\$(printf '%03o' $((65 + idx)))")
  suffix=$(printf '%s%02d' "$letter" "$dd")
fi

printf '%s/%s-%s.md\n' "$HANDOFF_DIR" "$name" "$suffix"
