#!/usr/bin/env bash
# SessionStart hook (matcher: clear) — make the post-/clear session carry the
# name the pre-/clear session had, everywhere it is read from.
#
# What Claude Code already does: /clear reads the outgoing session's title and
# re-applies it to the incoming one, so the title itself survives — the new
# transcript opens with a "custom-title" record and the hook input's
# `session_title` is already populated by the time this runs.
#
# What it does not do: update the live registry entry at
# ~/.claude/sessions/<pid>.json. That still holds the folder-derived name
# (nameSource:"derived") assigned when the process started, so everything keyed
# on the registry — next-handoff-name.sh above all — reports the wrong name for
# the rest of the process's life. registry_sync closes that gap.
#
# Why this hook cannot simply return the name as `sessionTitle`: Claude Code
# only consumes a SessionStart hook's sessionTitle when the start source is
# startup, resume or fork. For source "clear" the collected value is explicitly
# discarded before anything reads it. The registry has to be written directly.
#
# The other thing /clear does not do: keep the session's *agent name*. /rename
# writes two records, "custom-title" and "agent-name"; /clear carries only the
# first across. The label above the composer renders the agent name, so it goes
# blank and the session reads as unnamed no matter how correct every stored copy
# of the name is. That repair cannot happen here either — for the same discarded
# -sessionTitle reason — so this hook only arms it (nudge_mark) and
# capture-session-name.sh performs it on the next prompt.
#
# The hook prints nothing at all and always exits 0.
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=session-name-common.sh
. "$DIR/session-name-common.sh"

{
  command -v jq >/dev/null 2>&1 || exit 0

  INPUT=$(cat)
  pid=$(claude_pid) || exit 0

  # The title Claude Code just carried across the clear. Names it derived
  # itself never appear here, which is what keeps an unnamed session unnamed.
  name=$(printf '%s' "$INPUT" | jq -r '.session_title // empty' 2>/dev/null)

  if [ -z "$name" ]; then
    transcript=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
    name=$(transcript_custom_title "$transcript")
  fi

  # Last resort: the name this process was known by before the clear.
  # capture-session-name.sh restores the title proper on the next prompt.
  if [ -z "$name" ]; then
    name=$(cache_read "$pid")
  fi

  [ -n "$name" ] || exit 0

  registry_sync "$pid" "$name"
  cache_write "$pid" "$name"

  # Arm the badge nudge. /clear carries the title over but drops the session's
  # agent name, and the agent name is what the label above the composer shows —
  # so from here the session looks unnamed even though every stored copy of the
  # name is correct. Nothing reachable from SessionStart can set the agent name
  # (this hook's sessionTitle is discarded outright for source "clear"), so the
  # repair is handed to the next UserPromptSubmit, which can.
  nudge_mark "$pid"
} >/dev/null 2>&1

exit 0
