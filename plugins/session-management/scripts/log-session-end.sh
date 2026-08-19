#!/usr/bin/env bash
# SessionEnd hook: append the session's name, working folder, and exact exit
# timestamp to the session history log — but ONLY for sessions the user
# explicitly named via /rename. Named sessions are detected by a "custom-title"
# record in the transcript; sessions carrying only their GUID or an
# auto-generated "ai-title" are skipped.
#
# The log lives OUTSIDE the plugin, under the Claude config directory, so a
# plugin update can never touch accumulated history:
#   <config-dir>/claude-session-management/claude-session-history.json
# Override the whole path with CLAUDE_SESSION_HISTORY_FILE.
#
# History file format: a JSON array of
#   { "sessionName": "...", "folder": "...", "exitTimestamp": "...", "sessionId": "..." }
# If the history file exists but is not valid JSON, it is set aside as
# claude-session-history.json.corrupt.<epoch> (never silently overwritten).
set -euo pipefail

INPUT=$(cat)
HIST="${CLAUDE_SESSION_HISTORY_FILE:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/claude-session-management/claude-session-history.json}"

# On a machine where the log (or the folder holding it) is a symlink into a
# notes/dotfiles repo, resolve it first: the append below replaces the file via
# `mv tmp -> target`, which would otherwise turn the symlink into a plain file.
if [ -L "$HIST" ]; then
  HIST=$(readlink "$HIST")
fi

mkdir -p "$(dirname "$HIST")"

transcript=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
cwd=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
sid=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')

if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

# The LAST custom-title record wins — the user may have renamed more than once.
name=$(grep '"type":"custom-title"' "$transcript" 2>/dev/null | tail -1 | jq -r '.customTitle // empty' || true)
# capture-session-name.sh briefly suffixes the title with U+200B to restore the
# name badge after a /clear (see session-name-common.sh). A session that ends
# inside that one-prompt window would otherwise log an invisible character as
# part of its name.
name=${name//$(printf '\342\200\213')/}
if [ -z "$name" ]; then
  exit 0  # session was never named — nothing to log
fi

ts=$(date '+%Y-%m-%dT%H:%M:%S%z')

entry=$(jq -n --arg n "$name" --arg c "$cwd" --arg t "$ts" --arg s "$sid" \
  '{sessionName: $n, folder: $c, exitTimestamp: $t, sessionId: $s}')

if [ -f "$HIST" ] && ! jq -e 'type == "array"' "$HIST" >/dev/null 2>&1; then
  mv "$HIST" "$HIST.corrupt.$(date +%s)"
fi

tmp="$HIST.tmp.$$"
if [ -f "$HIST" ]; then
  jq --argjson e "$entry" '. + [$e]' "$HIST" > "$tmp" && mv "$tmp" "$HIST"
else
  printf '%s\n' "$entry" | jq -s '.' > "$HIST"
fi
exit 0
