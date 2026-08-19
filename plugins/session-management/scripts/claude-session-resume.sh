# claude-session-resume.sh — interactively resume a named Claude Code session.
#
# NOT a standalone executable. Source it via a resume-claude() shell function
# (see the plugin README for the ~/.zshrc or ~/.bashrc snippet), so that:
#   - the `cd` into the session's folder persists in your shell, and
#   - your own claude invocation functions/aliases (claude-max, deep-claude,
#     ...) are available to launch the resume.
#
# Data source: <config-dir>/claude-session-management/claude-session-history.json,
# written by this plugin's SessionEnd hook, scripts/log-session-end.sh (named
# sessions only). Override the path with CLAUDE_SESSION_HISTORY_FILE.
#
# The default invocation offered at the prompt is `claude`; set
# CLAUDE_RESUME_COMMAND to make it default to your own wrapper instead.
#
# Usage:
#   resume-claude            interactive picker (default)
#   resume-claude --prune    compact the log: keep only the latest
#                                    entry per named work item (sessionName +
#                                    folder), move superseded ones to
#                                    claude-session-history-old.json
#
# Identity note: Claude Code forks a NEW sessionId every time a session is
# resumed (the custom title is inherited by the fork). The GUID therefore
# identifies a link in the chain, not the work itself — so both the picker
# and prune group by sessionName + folder and keep the latest exit, whose
# GUID is the tip of the lineage and holds the full history.

local hist="${CLAUDE_SESSION_HISTORY_FILE:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/claude-session-management/claude-session-history.json}"

# On a machine where the log is a symlink into a notes/dotfiles repo, resolve
# it first, so writes (--prune) can never replace a symlink with a plain file.
if [ -L "$hist" ]; then
  hist=$(readlink "$hist")
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "resume-claude: jq is required but not installed" >&2
  return 1
fi
if [ ! -f "$hist" ]; then
  echo "resume-claude: no history file at $hist" >&2
  echo "(it is created the first time you exit a session named with /rename)" >&2
  return 1
fi
if ! jq -e 'type == "array" and length > 0' "$hist" >/dev/null 2>&1; then
  echo "resume-claude: $hist is empty or not a JSON array" >&2
  return 1
fi

# ── prune mode ───────────────────────────────────────────────────────────────
if [ "${1:-}" = "--prune" ] || [ "${1:-}" = "-p" ]; then
  local old="${hist%.json}-old.json"
  if [ -L "$old" ]; then
    old=$(readlink "$old")
  fi

  local keep drop dropped tmp
  drop=$(jq '[group_by([.sessionName, .folder])[] | sort_by(.exitTimestamp) | .[:-1]] | flatten | sort_by(.exitTimestamp)' "$hist")
  dropped=$(printf '%s' "$drop" | jq length)
  if [ "$dropped" -eq 0 ]; then
    echo "resume-claude: nothing to prune (every named session has a single entry)"
    return 0
  fi
  keep=$(jq '[group_by([.sessionName, .folder])[] | max_by(.exitTimestamp)] | sort_by(.exitTimestamp)' "$hist")

  # Append the superseded entries to the -old archive (never clobber a
  # damaged archive: set it aside like the hook does with the main log).
  if [ -f "$old" ] && ! jq -e 'type == "array"' "$old" >/dev/null 2>&1; then
    mv "$old" "$old.corrupt.$(date +%s)"
    echo "resume-claude: damaged archive set aside as $old.corrupt.*" >&2
  fi
  tmp="$old.tmp.$$"
  if [ -f "$old" ]; then
    jq --argjson d "$drop" '. + $d' "$old" > "$tmp" && mv "$tmp" "$old"
  else
    printf '%s\n' "$drop" > "$old"
  fi

  tmp="$hist.tmp.$$"
  printf '%s\n' "$keep" > "$tmp" && mv "$tmp" "$hist"

  echo "resume-claude: kept $(printf '%s' "$keep" | jq length) latest entries in $hist"
  echo "resume-claude: moved $dropped superseded entries to $old"
  return 0
fi

# ── interactive picker ───────────────────────────────────────────────────────

# One row per named work item (sessionName + folder; latest exit wins —
# its sessionId is the lineage tip), newest exit first.
local rows
rows=$(jq -r '
  group_by([.sessionName, .folder])
  | map(max_by(.exitTimestamp))
  | sort_by(.exitTimestamp)
  | reverse
  | .[]
  | [.exitTimestamp, .sessionName, .folder, .sessionId]
  | @tsv' "$hist")

if [ -z "$rows" ]; then
  echo "resume-claude: no sessions found in $hist" >&2
  return 1
fi

local i=0 ts name folder sid
echo "Named Claude sessions (latest exit first):"
while IFS=$'\t' read -r ts name folder sid; do
  i=$((i + 1))
  printf '%3d) %-32s %s  %s\n' "$i" "$name" "$ts" "$folder"
done <<< "$rows"

local total=$i sel
echo "(tip: 'resume-claude --prune' compacts the log — keeps the latest entry per named session, archives the rest to claude-session-history-old.json)"
printf 'Select a session [1-%d, q to quit]: ' "$total"
read -r sel
case "$sel" in
  ''|q|Q) echo "resume-claude: aborted"; return 1 ;;
  *[!0-9]*) echo "resume-claude: invalid selection '$sel'" >&2; return 1 ;;
esac
if [ "$sel" -lt 1 ] || [ "$sel" -gt "$total" ]; then
  echo "resume-claude: selection out of range" >&2
  return 1
fi

IFS=$'\t' read -r ts name folder sid <<< "$(printf '%s\n' "$rows" | sed -n "${sel}p")"

local inv default_inv
default_inv="${CLAUDE_RESUME_COMMAND:-claude}"
printf 'Claude invocation to use (command, function, or alias) [%s]: ' "$default_inv"
read -r inv
inv=${inv:-$default_inv}
if ! type -- "$inv" >/dev/null 2>&1; then
  echo "resume-claude: '$inv' is not a known command, function, or alias" >&2
  return 1
fi

if [ ! -d "$folder" ]; then
  echo "resume-claude: session folder no longer exists: $folder" >&2
  return 1
fi

cd "$folder" || return 1
echo "Resuming '$name' ($sid) in $folder with $inv ..."
eval "$inv --resume '$sid'"
