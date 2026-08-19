# global-rules

Deploys the shared global `CLAUDE.md` and the `rules/` working rules onto the
installing machine as **real files**, so it is always visible on disk exactly
which instructions are in place for every project.

## What it does

- On every session start (`SessionStart` hook, `startup` matcher),
  `scripts/sync-rules.sh` compares the plugin's bundled content against the
  machine's `CLAUDE.md` and `rules/*.md` in the Claude config directory:
  - missing files are **installed**;
  - files the user never edited are **updated** when the plugin ships a newer
    version;
  - files with local edits are **never overwritten** — they are reported as
    conflicts and left untouched (resolve via `--force`, see below).
- Conflict detection uses last-deployed snapshots kept under
  `.global-rules-state/` in the config directory (three-way comparison).
- Deployment is **atomic**: content is written to a temporary file and renamed
  into place, and the snapshot is updated only after the target file has landed.
  An interrupted run can never leave a half-written rule file behind.
- `--status` is strictly read-only: it reports state and writes nothing.
- On a dev machine where `CLAUDE.md` or `rules` is a symlink into the canonical
  repo, the sync **skips** that part entirely.
- A second SessionStart hook (`scripts/sync-project-claude-md.sh`) maintains
  the `<structure-and-conventions>` documentation-map block in the **current
  project's** `CLAUDE.md`: it creates the file at the git toplevel when
  missing, inserts or replaces the tagged block when absent/outdated, and
  preserves all other project content. A machine-local master at
  `<config-dir>/structure-and-conventions.md` overrides the bundled copy when
  present, and on a machine that also has the canonical hook script
  (`<config-dir>/scripts/sync-claude-md.sh`) the plugin defers to it entirely.
- `/global-rules:rules-status` shows a per-file report of what is installed,
  in sync, outdated, or locally modified.
- `/global-rules:uninstall-cleanup` removes the deployed files when you want
  them gone (dry run by default).

## Installation

This plugin is part of the `biks-claude-tools` marketplace.

```
/plugin marketplace add BikS2013-ClaudeCode/biks-claude-tools
/plugin install global-rules@biks-claude-tools
```

Then restart Claude Code — the sync runs from a `SessionStart` hook, so the
files land on the first session started after installation. The target
directory is whatever `CLAUDE_CONFIG_DIR` points at (`~/.claude` by default);
see [The config directory](#the-config-directory) before installing on a
machine that runs more than one Claude environment.

## Content

| Bundled file | Deployed to |
|---|---|
| `content/CLAUDE.md` | `<config-dir>/CLAUDE.md` |
| `content/rules/*.md` | `<config-dir>/rules/*.md` |
| `content/structure-and-conventions.md` | `<structure-and-conventions>` block inside each project's `CLAUDE.md` |

## The config directory

Both hooks honour **`CLAUDE_CONFIG_DIR`**, falling back to `~/.claude` when it
is unset, and every report label shows the directory actually in use.

This makes the plugin safe on a mixed-use machine: keep one set of rules for
one class of projects and leave the default environment untouched, by giving
that class its own config directory.

```bash
# ~/.zshrc — a second, fully isolated Claude environment
alias claude-work='CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude'
```

Install the plugin from inside a `claude-work` session and it deploys to
`~/.claude-work/` exclusively; the default `~/.claude/` is never read or
written. (Claude Code has no `--config-dir` CLI flag as of v2.1.x, so an
alias or exported variable is the way to select the environment.)

## Resolving conflicts — `--force`

A file reported as `CONFLICT` was edited after deployment, so the sync leaves
it alone. To take the plugin's version instead:

```bash
# overwrite ONE file (name = basename, with or without .md)
scripts/sync-rules.sh --force tool-creation

# several at once
scripts/sync-rules.sh --force tool-creation dependency-vetting CLAUDE.md

# NO names = overwrite EVERY conflicted file — local edits in all of them are lost
scripts/sync-rules.sh --force
```

Always review the diff against `content/` before forcing; `--force` discards
local edits with no backup.

## Uninstalling

Removing the plugin (`/plugin uninstall global-rules@biks-claude-tools`) stops
the syncing but leaves the deployed files in place — they are plain files in
the config directory and are often worth keeping.

To remove them, run `/global-rules:uninstall-cleanup` (or
`scripts/uninstall-cleanup.sh`) **before** uninstalling the plugin, while the
plugin files are still available. It lists what it would delete and changes
nothing until re-run with `--yes`. Files you edited after deployment are
reported and kept, never deleted; symlinked targets are never touched.

## Repackaging (maintainers)

The canonical sources live in the `claude-workdocs` repo: `.claude/CLAUDE.md`,
`.claude/rules/*.md`, and `.claude/structure-and-conventions.md`. The bundled
copies under `content/` must stay byte-identical to them — a lagging copy makes
the `<structure-and-conventions>` block flip-flop between machines that have the
master and machines that only have the plugin.

Use the repo tool rather than copying by hand:

```bash
tools/package-global-rules-content.sh --check   # report drift, exit 1 if any
tools/package-global-rules-content.sh           # refresh content/ from canonical
```

Set `CANONICAL_ROOT` if the working repo is not at `~/claude-workdocs/.claude`.
Run `--check` before every release, then bump the version in
`.claude-plugin/plugin.json` and in the marketplace's `marketplace.json`,
commit, and push.
