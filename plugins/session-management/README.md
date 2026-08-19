# session-management

Makes a session's **user-given name** behave the way you would expect it to:
it survives `/clear`, it stays correct everywhere it is read from, it is
remembered after the session exits, and it becomes the filename of the
session's handoff documents.

## The problem it solves

Claude Code stores a session's name in three places that are written by three
different code paths, and nothing reconciles them:

| | set by `/rename` | carried across `/clear` | updated in the registry |
|---|---|---|---|
| session **title** | yes | yes | no |
| session **agent name** (the badge above the composer) | yes | **no** | — |
| `<config-dir>/sessions/<pid>.json` (the live registry) | **no** | **no** | only at process start, derived from the folder |

The visible consequences without this plugin:

- after a `/clear` the name badge above the composer goes blank, so the session
  reads as unnamed even though the title survived;
- the registry keeps the folder-derived name (`my-project-9a`) for the whole
  life of the process, so **everything keyed on the registry reports the wrong
  name** — session pickers, status lines, and the handoff helper below.

## What it does

- **`UserPromptSubmit` → `scripts/capture-session-name.sh`** — on every prompt,
  reconciles the registry entry with the session's real title, caches the name
  keyed by the Claude Code **process id** (the one handle that survives
  `/clear`, since the session id does not), and restores the name badge after a
  clear. Sessions Claude Code named for you (`nameSource: derived`/`auto`) are
  deliberately left alone: an unnamed session stays unnamed.
- **`SessionStart` (matcher `clear`) → `scripts/restore-session-name.sh`** —
  writes the carried-over name into the registry and arms the badge repair that
  the next prompt performs.
- **`SessionEnd` → `scripts/log-session-end.sh`** — appends
  `{sessionName, folder, exitTimestamp, sessionId}` to the history log, **only**
  for sessions you named with `/rename`.
- **`/session-management:session-handoff`** — compacts the current conversation
  into `<project>/handoff/<session-name>-NNN.md`, with the sequence number
  allocated per project folder (`001`…`999`, then `A01`…`Z99`).
- **`scripts/claude-session-resume.sh`** — an interactive picker over the
  history log that `cd`s into a past session's folder and resumes it (see
  *Resume picker* below).

Every hook **fails soft**: missing `jq`, an unreadable registry, or an
unexpected input shape all end in a silent `exit 0`. The hooks never write to
stdout except the one JSON object Claude Code expects, so nothing they do can
leak into the conversation.

### About the invisible character

Restoring the name badge after a `/clear` requires handing back a title that
*differs* from the current one — Claude Code short-circuits its
`sessionTitle` handler when they match, and that handler is the only path from
a hook to the agent name. The plugin appends a single U+200B ZERO WIDTH SPACE
for exactly one prompt, then hands back the clean name. The marker is invisible
in the badge and is stripped by every path that persists a name (registry,
cache, history log, handoff filename), so it can never reach a file.
`scripts/session-name-common.sh` documents the mechanism in full.

## Installation

This plugin is part of the `biks-claude-tools` marketplace.

```
/plugin marketplace add BikS2013-ClaudeCode/biks-claude-tools
/plugin install session-management@biks-claude-tools
```

Then restart Claude Code (hooks are registered at startup).

**Requires `jq`** on `PATH` (`brew install jq`, `apt install jq`). Without it
the hooks no-op silently. The scripts are bash 3.2 compatible, so macOS's
system `/bin/bash` works.

## Configuration

All optional — the defaults are what you want on a standard install.

| Variable | Default | Purpose |
|---|---|---|
| `CLAUDE_CONFIG_DIR` | `~/.claude` | Claude config directory; every path below is derived from it. |
| `CLAUDE_SESSION_HISTORY_FILE` | `<config-dir>/claude-session-management/claude-session-history.json` | The history log. Lives **outside** the plugin, so plugin updates never touch accumulated history. |
| `CLAUDE_SESSIONS_DIR` | `<config-dir>/sessions` | The live session registry. |
| `CLAUDE_SESSION_NAME_CACHE` | `$TMPDIR/claude-session-names` | Per-process name cache that carries a name across `/clear`. Safe to delete. |
| `CLAUDE_HANDOFF_DIR` | `$PWD/handoff` | Where `/session-handoff` files documents. |
| `CLAUDE_RESUME_COMMAND` | `claude` | Default invocation offered by the resume picker. |

## Resume picker

`scripts/claude-session-resume.sh` must be **sourced**, not executed — it `cd`s
into the session's folder and runs your own `claude` wrapper, both of which
have to happen in your shell. Add to `~/.zshrc` (or `~/.bashrc`):

```sh
resume-claude() {
  local s
  for s in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/marketplaces/*/plugins/session-management/scripts/claude-session-resume.sh; do
    [ -f "$s" ] && { . "$s" "$@"; return; }
  done
  echo "resume-claude: claude-session-resume.sh not found" >&2
  return 1
}
```

The glob keeps working across plugin updates and marketplace renames.

```
resume-claude            # interactive picker, newest exit first
resume-claude --prune    # keep only the latest entry per (name, folder);
                         # archive the rest to claude-session-history-old.json
```

Resuming forks a **new** session id (the title is inherited), so the picker
groups by *name + folder* and offers the latest exit — the tip of the lineage,
which holds the full history.

## Already wired these scripts by hand?

If you previously copied these scripts into your config directory and
referenced them from `settings.json`, **remove those hook entries** when you
install the plugin — otherwise `capture-session-name.sh`,
`restore-session-name.sh`, and `log-session-end.sh` each run twice per event.
The name hooks are idempotent so a double run is harmless, but
`log-session-end.sh` would append **two identical history entries** per session
exit.

The history log keeps its default location (`<config-dir>/claude-session-management/`),
so an existing log is picked up as-is.

## Uninstall

```
/plugin uninstall session-management@biks-claude-tools
```

Nothing is left behind inside Claude Code itself. Your history log and any
`handoff/` folders are yours — delete them by hand if you want them gone.
