# global-rules

Deploys the shared global `CLAUDE.md` and the `~/.claude/rules/` working rules
onto the installing machine as **real files**, so it is always visible on disk
exactly which instructions are in place for every project.

## What it does

- On every session start (`SessionStart` hook, `startup` matcher),
  `scripts/sync-rules.sh` compares the plugin's bundled content against the
  machine's `~/.claude/CLAUDE.md` and `~/.claude/rules/*.md`:
  - missing files are **installed**;
  - files the user never edited are **updated** when the plugin ships a newer
    version;
  - files with local edits are **never overwritten** — they are reported as
    conflicts and left untouched (resolve via `--force` after reviewing).
- Conflict detection uses last-deployed snapshots kept under
  `~/.claude/.global-rules-state/` (three-way comparison).
- On a dev machine where `~/.claude/CLAUDE.md` or `~/.claude/rules` is a
  symlink into the canonical repo, the sync **skips** that part entirely.
- A second SessionStart hook (`scripts/sync-project-claude-md.sh`) maintains
  the `<structure-and-conventions>` documentation-map block in the **current
  project's** `CLAUDE.md`: it creates the file at the git toplevel when
  missing, inserts or replaces the tagged block when absent/outdated, and
  preserves all other project content. A machine-local master at
  `~/.claude/structure-and-conventions.md` overrides the bundled copy when
  present, and on a machine that also has the canonical hook script
  (`~/.claude/scripts/sync-claude-md.sh`) the plugin defers to it entirely.
- `/global-rules:rules-status` shows a per-file report of what is installed,
  in sync, outdated, or locally modified.

## Content

| Bundled file | Deployed to |
|---|---|
| `content/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `content/rules/*.md` | `~/.claude/rules/*.md` |
| `content/structure-and-conventions.md` | `<structure-and-conventions>` block inside each project's `CLAUDE.md` |

## Repackaging (maintainers)

The canonical sources live in the `claude-workdocs` repo: `.claude/claude.md`,
`.claude/rules/*.md`, and `.claude/structure-and-conventions.md` (keep the
bundled copy byte-identical to the master so dev-synced and plugin-synced
projects never flip-flop). To release an update, copy them
into `content/`, bump the version in `.claude-plugin/plugin.json` and in the
marketplace's `marketplace.json`, then commit and push the marketplace repo.

## Uninstalling

Removing the plugin stops the syncing but leaves the deployed files in place
(they are plain files under `~/.claude`). Delete `~/.claude/rules/*.md`,
`~/.claude/CLAUDE.md`, and `~/.claude/.global-rules-state/` manually if you
want them gone.
