---
description: Show which global CLAUDE.md and rules files are installed, in sync, outdated, or locally modified on this machine
allowed-tools: Bash
---

Report the deployment state of the global-rules plugin on this machine.

1. Run:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/sync-rules.sh" --status
```

2. Present the output to the user as a short table with one row per managed file (`~/.claude/CLAUDE.md` plus each file under `~/.claude/rules/`) and its state:
   - **in sync** — the installed file matches the plugin.
   - **UPDATE AVAILABLE** — the plugin ships a newer version; offer to apply it by running the script with no arguments.
   - **CONFLICT** — the file was modified locally after deployment; show the user a diff between the installed file and the plugin's copy under `${CLAUDE_PLUGIN_ROOT}/content/`, and only run the script with `--force` if the user explicitly confirms they want their local edits overwritten.
   - **NOT INSTALLED** — offer to install by running the script with no arguments.
   - **managed elsewhere (symlink)** — this is a dev machine whose canonical copies live in a repo; the plugin deliberately does not touch them. No action needed.

3. Never run `--force` without explicit user confirmation in this conversation.
