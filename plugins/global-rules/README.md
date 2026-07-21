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
- `/global-rules:rules-status` shows a per-file report of what is installed,
  in sync, outdated, or locally modified.

## Content

| Bundled file | Deployed to |
|---|---|
| `content/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `content/rules/*.md` | `~/.claude/rules/*.md` |

## Repackaging (maintainers)

The canonical sources live in the `claude-workdocs` repo:
`.claude/claude.md` and `.claude/rules/*.md`. To release an update, copy them
into `content/`, bump the version in `.claude-plugin/plugin.json` and in the
marketplace's `marketplace.json`, then commit and push the marketplace repo.

## Uninstalling

Removing the plugin stops the syncing but leaves the deployed files in place
(they are plain files under `~/.claude`). Delete `~/.claude/rules/*.md`,
`~/.claude/CLAUDE.md`, and `~/.claude/.global-rules-state/` manually if you
want them gone.
