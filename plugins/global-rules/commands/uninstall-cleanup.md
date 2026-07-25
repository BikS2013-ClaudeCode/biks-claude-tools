---
description: Remove the global CLAUDE.md and rules files that the global-rules plugin deployed onto this machine
allowed-tools: Bash
---

Uninstalling the global-rules plugin stops the syncing but leaves the deployed
files on disk. This command removes them.

1. Always run the dry run FIRST and show the user its output verbatim:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/uninstall-cleanup.sh"
```

2. Explain what the listing means:
   - **remove** — the file still matches what the plugin deployed; it will be
     deleted, along with the `.global-rules-state/` snapshot directory.
   - **keep — locally modified since deployment** — the file was edited after it
     was deployed, so the cleanup will NOT delete it. If the user wants it gone
     they must delete it themselves; say so explicitly and give the path.
   - **keep — symlink, managed elsewhere** — a dev machine whose canonical copies
     live in a repo. Never touched.

3. Only after the user explicitly confirms, apply the cleanup:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/uninstall-cleanup.sh" --yes
```

4. Remind the user that removing the files does not uninstall the plugin itself
   — `/plugin uninstall global-rules@biks-claude-tools` does that, and running
   this cleanup while the plugin is still installed means the next session start
   will simply deploy everything again.

Never run `--yes` without explicit confirmation in this conversation.
