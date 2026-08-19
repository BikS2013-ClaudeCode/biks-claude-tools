---
description: Compact the current session into a handoff document and save it in the active project's handoff/ folder as [session-name]-NNN.md
argument-hint: "What will the next session be used for?"
---

Create a handoff document for the CURRENT session and store it in the
active project's handoff archive. Follow these steps exactly:

## 1. Compute the target file path

Run:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/next-handoff-name.sh"
```

It prints the full target path: `<active project>/handoff/<session-name>-<NNN>.md` —
a `handoff` folder inside the current working directory (created on demand
by the helper), so handoffs live with the project they describe.
`<session-name>` is the current session's name (auto-detected from the
session registry under the Claude config directory) and `<NNN>` the next
free sequence number in that project's handoff folder (001–999, then
A01–A99, B01–B99, … Z99). If it fails because the session cannot be
detected, tell the user to name the session first (`/rename`) and stop.

## 2. Write the handoff document

Write a handoff document summarising the current conversation so a fresh
agent can continue the work, and save it AT THE EXACT PATH from step 1 (not
the OS temp directory, not any central archive):

- Capture the state of the work: what was being done, what was completed,
  key decisions made and their rationale, open problems, and concrete next
  steps.
- Include a **"Suggested skills"** section listing the skills the next agent
  should invoke to continue effectively.
- Do NOT duplicate content already captured in other artifacts (specs,
  plans, ADRs, issues, commits, diffs, project docs). Reference them by
  path or URL instead.
- REDACT any sensitive information: API keys, tokens, passwords, personally
  identifiable information.
- If the user passed arguments below, treat them as a description of what
  the next session will focus on and tailor the document accordingly.

User arguments: $ARGUMENTS

## 3. Report

Tell the user the handoff was saved, giving the full path and the sequence
number used.
