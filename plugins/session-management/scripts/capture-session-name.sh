#!/usr/bin/env bash
# UserPromptSubmit hook — keep a session's user-given name intact and in sync.
#
# Three jobs, in order of how often they matter:
#
#   sync     Reconcile the live registry entry with the session's title on every
#            prompt. /rename updates the title but not the registry, so without
#            this the registry keeps the folder-derived name assigned at process
#            start and next-handoff-name.sh (and every other registry reader)
#            reports the wrong name. Idempotent: a no-op once they agree.
#   capture  Remember the name in a cache keyed by the Claude Code process id.
#            /clear replaces the session id and the transcript but not the
#            process, so the pid is the one handle that survives it.
#   badge    Put the session's agent name back after a /clear. /rename sets a
#            title AND an agent name; /clear carries over only the title, and the
#            label above the composer is the agent name — so the session looks
#            unnamed. Claude Code's UserPromptSubmit handler is the one place a
#            hook can set the agent name, but it returns early when the title we
#            hand back already equals the current one, which post-/clear it
#            always does. Handing back the name with a U+200B suffix clears that
#            guard; the next prompt hands back the clean name (which now differs
#            again) and the session settles. See session-name-common.sh.
#   restore  If the session has no title at all but this process had one before
#            a /clear, hand it back as `sessionTitle`. Claude Code carries the
#            title across /clear by itself, so this is the belt-and-braces path
#            — it only fires if that ever stops happening. This path needs no
#            nudge: with no current title the guard passes on its own and the
#            agent name is set along with the title.
#
# Output discipline: stdout that parses as hook JSON is consumed as structured
# output; stdout that does not is injected into the conversation as context. So
# this script prints the JSON object and nothing else, ever, and always exits 0.
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=session-name-common.sh
. "$DIR/session-name-common.sh"

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)

pid=""
current=""

# Everything up to the final decision is silenced: a stray byte here would land
# in the conversation.
{
  pid=$(claude_pid) || pid=""

  # `session_title` is the title the user set (/rename, --name, or the one
  # /clear carried over). Claude Code leaves it unset for names it derived from
  # the folder — exactly the distinction we want, so an unnamed session stays
  # unnamed.
  current=$(printf '%s' "$INPUT" | jq -r '.session_title // empty' 2>/dev/null)

  if [ -z "$current" ]; then
    transcript=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
    current=$(transcript_custom_title "$transcript")
  fi

  if [ -z "$current" ] && [ -n "$pid" ]; then
    current=$(registry_user_name "$pid")
  fi
} >/dev/null 2>&1

[ -n "${pid:-}" ] || exit 0

# Named session: push the name into the registry and keep the cache warm. Both
# helpers strip the nudge marker, so nothing downstream ever sees it.
if [ -n "${current:-}" ]; then
  clean=$(strip_zwsp "$current")
  {
    registry_sync "$pid" "$clean"
    cache_write "$pid" "$clean"
  } >/dev/null 2>&1

  # Second half of the nudge: the title is still carrying the marker, so the
  # clean name differs from it and gets through the equality guard. This is the
  # call that leaves the session on its real name with the badge populated.
  if has_zwsp "$current"; then
    { nudge_drop "$pid"; } >/dev/null 2>&1
    jq -cn --arg t "$clean" \
      '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", sessionTitle:$t}}'
    exit 0
  fi

  # First half: only ever on the first prompt after a /clear, because that is the
  # only place the marker is armed. The suffix is invisible in the badge and is
  # gone again one prompt later.
  if nudge_take "$pid" 2>/dev/null; then
    jq -cn --arg t "$clean$ZWSP" \
      '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", sessionTitle:$t}}'
  fi
  exit 0
fi

# Untitled session that this process had named before: give the title back.
# Claude Code applies it and, on this path, writes the registry and the agent
# name itself — so any armed nudge is redundant and would only cost a pointless
# round trip through the marker.
restored=$(cache_read "$pid" 2>/dev/null) || exit 0
[ -n "${restored:-}" ] || exit 0
{ nudge_drop "$pid"; } >/dev/null 2>&1

jq -cn --arg t "$restored" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", sessionTitle:$t}}'
exit 0
