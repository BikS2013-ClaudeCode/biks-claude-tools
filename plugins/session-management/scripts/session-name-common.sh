# session-name-common.sh — shared helpers for the name-through-/clear hooks.
# Sourced by capture-session-name.sh and restore-session-name.sh.
#
# Both hooks must NEVER disturb the session: every helper fails soft and the
# callers always exit 0.

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CACHE_DIR="${CLAUDE_SESSION_NAME_CACHE:-${TMPDIR:-/tmp}/claude-session-names}"
SESSIONS_DIR="${CLAUDE_SESSIONS_DIR:-$CLAUDE_DIR/sessions}"

# U+200B ZERO WIDTH SPACE, built from its UTF-8 bytes so this works on bash 3.2
# (macOS /bin/bash), where $'​' is not supported.
#
# This character is the whole trick behind restoring the name badge that sits
# above the composer. That badge does not render the session *title*; it renders
# the session *agent name*, which /rename sets alongside the title and which
# /clear drops. The only path from a hook to the agent name is Claude Code's
# UserPromptSubmit sessionTitle handler, and it short-circuits before it gets
# there whenever the title we hand back already equals the current one:
#
#   let t = <hook sessionTitle>, n = <current title>;
#   if (t === n) return;             // <- always true right after a /clear
#   await setSessionName(t, "hook")  // <- the call that sets the agent name
#
# So the name has to differ, once, to get through — and U+200B is the only kind
# of difference that is invisible in the badge AND survives Claude Code's own
# sanitiser (which strips \x00-\x1f and \x7f-\x9f, then compares). The suffix
# lives for exactly one prompt: the next UserPromptSubmit sees it, hands back the
# clean name (which now differs again), and the session settles on the real name
# with the badge populated.
ZWSP=$(printf '\342\200\213')

# strip_zwsp <string> — the name as it should be persisted anywhere.
# Everything that writes the name to disk goes through this, so the marker never
# reaches the registry, the cache, the history log or a handoff filename.
strip_zwsp() {
  printf '%s' "${1//$ZWSP/}"
}

# has_zwsp <string> — true while a name is mid-nudge.
has_zwsp() {
  case "$1" in
    *"$ZWSP"*) return 0 ;;
  esac
  return 1
}

# claude_pid — print the PID of the Claude Code process running this hook.
#
# A hook runs as a descendant of the `claude` process, and that process owns a
# live registry entry at $SESSIONS_DIR/<pid>.json. Walking up the parent chain
# until a registry file appears identifies our session's process. The PID is
# what makes this work across /clear: the session id changes, the process does
# not.
claude_pid() {
  local pid="$$" i
  for i in 1 2 3 4 5 6 7 8; do
    if [ -z "$pid" ] || [ "$pid" = "0" ] || [ "$pid" = "1" ]; then
      return 1
    fi
    if [ -f "$SESSIONS_DIR/$pid.json" ]; then
      printf '%s' "$pid"
      return 0
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
  return 1
}

# registry_user_name <pid> — print the session name IF the user set it.
#
# The registry records how a name was produced in `nameSource`: "derived" and
# "auto" are names Claude Code invented from the folder (e.g. claude-workdocs-9a)
# and must never be propagated — an unnamed session stays unnamed. Anything else
# (null, "user") is a name the user chose via /rename or --name.
registry_user_name() {
  local f="$SESSIONS_DIR/$1.json" src
  [ -f "$f" ] || return 1
  src=$(jq -r '.nameSource // "null"' "$f" 2>/dev/null)
  case "$src" in
    derived|auto) return 1 ;;
  esac
  jq -r '.name // empty' "$f" 2>/dev/null
}

# transcript_custom_title <transcript.jsonl> — print the last /rename title.
# Same signal the SessionEnd logger uses: /rename writes a "custom-title"
# record; auto-generated "ai-title" records do not count.
#
# Deliberately NOT passed through strip_zwsp: this is one of the readers the
# nudge is detected from, and a stripped result would look like a settled name
# and leave the marker in place for good. Callers strip before persisting.
transcript_custom_title() {
  [ -f "$1" ] || return 1
  grep '"type":"custom-title"' "$1" 2>/dev/null | tail -1 |
    jq -r '.customTitle // empty' 2>/dev/null
}

# proc_token <pid> — an identity for the process behind a registry entry.
#
# The cache is keyed by PID, and the OS recycles PIDs. Without this, a new
# unnamed session could land on the PID of a dead named one and inherit its
# name. `procStart` is the process's own start time and is constant for its
# whole life, so pairing it with the name makes a stale entry detectable.
proc_token() {
  local f="$SESSIONS_DIR/$1.json"
  [ -f "$f" ] || return 1
  jq -r '.procStart // .startedAt // empty' "$f" 2>/dev/null
}

# cache_write <pid> <name> — remember a name for this process, atomically.
# Stored as two lines: the process token, then the name.
cache_write() {
  local pid="$1" name tmp token
  name=$(strip_zwsp "$2")
  [ -n "$name" ] || return 0
  token=$(proc_token "$pid") || return 0
  [ -n "$token" ] || return 0
  mkdir -p "$CACHE_DIR" 2>/dev/null || return 0
  tmp="$CACHE_DIR/$pid.title.$$"
  { printf '%s\n' "$token"; printf '%s' "$name"; } > "$tmp" 2>/dev/null || return 0
  mv -f "$tmp" "$CACHE_DIR/$pid.title" 2>/dev/null || rm -f "$tmp" 2>/dev/null
  return 0
}

# registry_sync <pid> <name> — make the registry entry agree with the session's
# title.
#
# This is the half Claude Code never does for itself. A session's title and its
# registry entry are written by two different code paths: setCustomTitle (used
# by /rename, by /clear when it carries the old title onto the new session, and
# by fork) only appends a "custom-title" record to the transcript and updates
# in-memory state — it never touches ~/.claude/sessions/<pid>.json. The registry
# name is set once, at process start, by deriving it from the folder
# (nameSource:"derived"), and from then on nothing reconciles the two.
#
# Everything that reads the registry — next-handoff-name.sh, the session
# pickers, anything else keyed on the live session list — therefore keeps
# showing the derived folder name after a /clear or a /rename. Writing the file
# ourselves is the only way to fix that: the hook output that would make Claude
# Code do it (sessionTitle) is discarded for SessionStart source "clear", and on
# UserPromptSubmit it short-circuits whenever the title already matches, which
# is exactly the case here.
#
# Read-modify-write so every other field (status, updatedAt, the worktree and
# protocol bookkeeping) is preserved verbatim; updatedAt is deliberately left
# alone so this does not masquerade as a status change.
registry_sync() {
  local pid="$1" name f="$SESSIONS_DIR/$1.json" tmp cur src
  name=$(strip_zwsp "$2")
  [ -n "$name" ] || return 0
  [ -f "$f" ] || return 0

  cur=$(jq -r '.name // empty' "$f" 2>/dev/null) || return 0
  src=$(jq -r '.nameSource // empty' "$f" 2>/dev/null)
  [ "$cur" = "$name" ] && [ "$src" = "user" ] && return 0

  tmp="$f.name.$$"
  jq --arg n "$name" '.name = $n | .nameSource = "user"' "$f" > "$tmp" 2>/dev/null || {
    rm -f "$tmp" 2>/dev/null
    return 0
  }
  # A truncated or empty rewrite would destroy the entry; only swap in a file
  # that still parses as the object we started from.
  jq -e '.pid and .sessionId' "$tmp" >/dev/null 2>&1 || {
    rm -f "$tmp" 2>/dev/null
    return 0
  }
  chmod 644 "$tmp" 2>/dev/null
  mv -f "$tmp" "$f" 2>/dev/null || rm -f "$tmp" 2>/dev/null
  return 0
}

# cache_read <pid> — print the cached name, but only if it belongs to the
# process currently holding this PID.
cache_read() {
  local f="$CACHE_DIR/$1.title" token cached
  [ -f "$f" ] || return 1
  token=$(proc_token "$1") || return 1
  cached=$(head -1 "$f" 2>/dev/null)
  [ -n "$token" ] && [ "$cached" = "$token" ] || return 1
  tail -n +2 "$f" 2>/dev/null
}

# nudge_mark <pid> — record that this process just came through a /clear and
# still owes itself one title nudge to get the name badge back.
#
# The marker is written by the SessionStart hook and consumed by the first
# UserPromptSubmit that follows, which is the earliest moment a hook can reach
# the agent name at all. Token-stamped like the name cache, for the same reason:
# PIDs get recycled.
nudge_mark() {
  local pid="$1" tmp token
  token=$(proc_token "$pid") || return 0
  [ -n "$token" ] || return 0
  mkdir -p "$CACHE_DIR" 2>/dev/null || return 0
  tmp="$CACHE_DIR/$pid.nudge.$$"
  printf '%s\n' "$token" > "$tmp" 2>/dev/null || return 0
  mv -f "$tmp" "$CACHE_DIR/$pid.nudge" 2>/dev/null || rm -f "$tmp" 2>/dev/null
  return 0
}

# nudge_take <pid> — succeed once, and only for the process that set the marker.
#
# The marker is removed whether or not the nudge that follows lands. A nudge that
# silently fails costs one missing badge; a marker that survived a failure would
# re-arm on every prompt for the life of the session.
nudge_take() {
  local f="$CACHE_DIR/$1.nudge" token stamped
  [ -f "$f" ] || return 1
  token=$(proc_token "$1") || { rm -f "$f" 2>/dev/null; return 1; }
  stamped=$(head -1 "$f" 2>/dev/null)
  rm -f "$f" 2>/dev/null
  [ -n "$token" ] && [ "$stamped" = "$token" ] || return 1
  return 0
}

# nudge_drop <pid> — disarm the marker without using it, for the paths that
# restore the agent name on their own.
nudge_drop() {
  rm -f "$CACHE_DIR/$1.nudge" 2>/dev/null
  return 0
}
