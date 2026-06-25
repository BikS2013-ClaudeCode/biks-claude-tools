---
description: Scaffold a new tool's docs and config — or audit an existing tool — against the project's tool-conventions (docs/tools/<name>.md format, ~/.tool-agents/<name>/ folder, four-tier env-var resolution chain, vendor-canonical LLM provider names, no-fallback rule)
argument-hint: <scaffold|audit> <tool-name>
allowed-tools:
  - Task
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
user-invocable: true
---

<objective>
Invoke the `tool-doc-config-architect` subagent to either scaffold the documentation and configuration artifacts for a new tool, or audit an existing tool against the project's tool-conventions. This command handles all user-interaction (gathering missing inputs, presenting the agent's report, optionally appending the recommended entry to CLAUDE.md) so the subagent can stay focused on file work and conformance checks.

Argument: $ARGUMENTS — expected as `<scaffold|audit> <tool-name>` (e.g. `scaffold my-tool`, `audit my-tool`). If arguments are missing or malformed, the command will ask for them.
</objective>

<context>
- Project root: $PWD
- Project CLAUDE.md present: !`test -f CLAUDE.md && echo yes || echo no`
- User-global CLAUDE.md present: !`test -f ~/.claude/CLAUDE.md && echo yes || echo no`
- Existing docs/tools entries: !`ls docs/tools/ 2>/dev/null || echo "(no docs/tools folder)"`
- Existing ~/.tool-agents folders: !`ls ~/.tool-agents/ 2>/dev/null || echo "(no ~/.tool-agents folder)"`
- Timestamp: !`date "+%Y-%m-%d %H:%M:%S"`
</context>

<process>

1. **Parse arguments** from `$ARGUMENTS`:
   - First token → mode (must be `scaffold` or `audit`).
   - Second token → tool name (lowercase-with-hyphens).
   - If `$ARGUMENTS` is empty, the mode is missing/invalid, or the tool name is missing, use `AskUserQuestion` to collect what's missing. Do NOT proceed with defaults.

2. **Pre-flight checks**:
   - Verify a CLAUDE.md exists for the agent to read (project root preferred, else `~/.claude/CLAUDE.md`). If neither exists, abort and tell the user the agent has no source of truth for the conventions.
   - For `audit` mode: verify the named tool actually exists in some form — at least one of `docs/tools/<tool-name>.md`, source code referring to the tool, or `~/.tool-agents/<tool-name>/`. Use `Glob`/`Grep` to check. If none of those is present, use `AskUserQuestion` to ask whether the user meant `scaffold` instead.

3. **Gather scaffold inputs** (scaffold mode only):
   Use `AskUserQuestion` to collect each missing input the subagent needs. Ask all four in a single AskUserQuestion call so the user fills them out in one pass:
   - `tool_description` — one-or-two-sentence summary of what the tool does.
   - `tool_command` — the exact CLI command users will run.
   - `llm_required` — does this tool talk to LLM providers? (`yes`/`no`). If yes, the agent will include the canonical names for all eight standard providers in the `.env` template.
   - `extra_config_vars` — any non-LLM configuration variables the tool needs (name + purpose for each); the user may answer "none".

4. **Dispatch the subagent**:
   Launch the `tool-doc-config-architect` subagent in the foreground via the `Task` tool. Pass a single instruction block with all required inputs:

   ```
   mode: <scaffold|audit>
   tool_name: <name>
   project_root: <absolute path to $PWD>
   tool_description: <from step 3, scaffold only>
   tool_command: <from step 3, scaffold only>
   llm_required: <yes|no, scaffold only>
   extra_config_vars:
     - name: <var name>
       purpose: <one-line purpose>
     - ...
   ```

   Wait for completion and capture the report.

5. **Present the report to the user**:
   - Summarize: status, files written (scaffold) or findings count (audit), and whether `needs_user_decision: yes`.
   - Show the full convention-compliance table from the report.
   - List the "Decisions Needed From User" items.

6. **Handle the CLAUDE.md update offer**:
   - If the report includes a "Recommended CLAUDE.md Tools Section Entry", use `AskUserQuestion` to ask whether to append it now to the project's CLAUDE.md.
   - If the user agrees:
     - Read the project's CLAUDE.md.
     - Locate the `## Tools` section. If it exists, append the recommended entry to it.
     - If it does not exist, create a new `## Tools` section at the end of the file (or at a position consistent with the file's existing structure) and add the entry.
   - If the user declines, leave CLAUDE.md untouched and remind them they can apply the entry manually later.

7. **Handle the "Decisions Needed From User" items**:
   For each item in that section of the report, use `AskUserQuestion` to capture the user's choice. Apply trivial choices directly (e.g. renaming an env var in the just-written `.env` template via `Edit`). For choices that materially change scaffold inputs (e.g. "actually this tool DOES talk to LLMs"), re-invoke the subagent with the corrected inputs.

8. **Final confirmation**:
   - For `scaffold`: run `ls -la ~/.tool-agents/<tool-name>/` and `ls -la docs/tools/<tool-name>.md` via `Bash` to confirm artifacts exist with correct modes. Show the output to the user.
   - For `audit`: confirm no files were modified by checking `git status --porcelain` (the working tree should be unchanged from before the command ran).

</process>

<success_criteria>
- The mode and tool name were unambiguous before the subagent was dispatched.
- For `scaffold`: all four scaffold inputs were collected; the subagent ran to `status: completed`; `docs/tools/<tool-name>.md` exists; `~/.tool-agents/<tool-name>/` exists with mode `0700` and contains `.env` with mode `0600`; the user has been offered (and either accepted or declined) the CLAUDE.md update.
- For `audit`: the subagent ran to `status: completed`; all findings were presented to the user with severity classifications; the working tree is unchanged.
- All "Decisions Needed From User" items have been resolved or explicitly deferred by the user.
- No tool's artifacts other than the named one were touched.
</success_criteria>

<verification>
After the workflow completes, confirm by reading:
- For `scaffold`: `ls -la ~/.tool-agents/<tool-name>/` shows the folder with mode `drwx------` (0700) and `.env` with mode `-rw-------` (0600). `docs/tools/<tool-name>.md` exists and contains the `<toolName>` block. The recommended CLAUDE.md entry was either applied (visible in `git diff CLAUDE.md`) or explicitly skipped per user choice.
- For `audit`: a structured report was displayed, and `git status --porcelain` shows the working tree is in the same state as before the command was invoked.
</verification>

<output>
Files possibly created/modified by this command:

**scaffold mode**:
- `<project_root>/docs/tools/<tool-name>.md` (created or updated by the subagent)
- `~/.tool-agents/<tool-name>/.env` (created or updated by the subagent)
- `~/.tool-agents/<tool-name>/` directory (created by the subagent if missing)
- `<project_root>/CLAUDE.md` (modified by THIS command in step 6, only with explicit user consent)

**audit mode**:
- No files modified. A report is presented in the conversation.
</output>
