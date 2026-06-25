---
description: Orchestrate a multi-agent team to research, plan, design, implement, review, and test a development request
argument-hint: [request description]
allowed-tools:
  - Task
  - Read
  - Write
  - Edit
  - Bash(git:*)
  - Bash(date:*)
  - Bash(mkdir:*)
  - Bash(ls:*)
  - Bash(find:*)
  - Bash(rm:*)
  - Bash(npx:*)
  - Bash(npm:*)
  - Bash(pnpm:*)
  - Bash(yarn:*)
  - Bash(uv:*)
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - mcp__serena__get_symbols_overview
  - mcp__serena__find_symbol
  - mcp__serena__find_referencing_symbols
  - mcp__serena__search_for_pattern
  - mcp__serena__list_dir
  - mcp__serena__find_file
  - mcp__serena__replace_symbol_body
  - mcp__serena__insert_after_symbol
  - mcp__serena__insert_before_symbol
  - mcp__serena__rename_symbol
  - mcp__serena__onboarding
  - mcp__serena__get_current_config
  - mcp__serena__read_memory
  - mcp__serena__write_memory
  - mcp__serena__list_memories
  - mcp__cclsp__get_diagnostics
  - mcp__cclsp__find_references
  - mcp__cclsp__find_definition
  - mcp__cclsp__find_workspace_symbols
  - mcp__cclsp__find_implementation
  - mcp__cclsp__get_hover
  - mcp__cclsp__get_incoming_calls
  - mcp__cclsp__get_outgoing_calls
  - mcp__cclsp__prepare_call_hierarchy
  - mcp__plugin_context7_context7__resolve-library-id
  - mcp__plugin_context7_context7__query-docs
disable-model-invocation: true
---

# Team Workflow Orchestrator

## Objective

Orchestrate a structured, multi-agent development workflow to fulfill the following request:

<request>
$ARGUMENTS
</request>

This command coordinates a team of specialized agents that execute sequentially and in parallel to take a request from investigation through implementation and testing.

## Context

- Project root: $PWD
- Timestamp: !`date "+%Y-%m-%d %H:%M:%S"`

## Pre-Flight Checks

Before starting the workflow:

1. **Validate request**: If `$ARGUMENTS` is empty or unclear, use AskUserQuestion to ask the user to describe their request in detail.
2. **Read project CLAUDE.md**: Read the project's CLAUDE.md and the global ~/.claude/CLAUDE.md to understand registration and documentation requirements.
3. **Check existing docs**: Look for `docs/design/project-design.md` and `docs/reference/` to understand current project state.
4. **Ensure directories exist**: Create `docs/design/`, `docs/reference/`, and `test_scripts/` directories if they don't exist.
5. **Serena onboarding**: Call `mcp__serena__list_memories`. If it returns no memories (onboarding never ran), call `mcp__serena__onboarding` to prime Serena for the project. If the Serena MCP is unavailable or either call errors, note it and continue — downstream agents have Glob/Grep/Read fallbacks; Serena is an accelerator, not a prerequisite.
6. **Clean working tree check**: Run `git status --porcelain`. If there are uncommitted changes, use AskUserQuestion to warn: "There are uncommitted changes in the working tree. It's recommended to commit or stash them before running this workflow so its changes can be cleanly identified and reverted if needed. Proceed anyway?" If the user declines, abort the workflow.

**All pre-flight checks must complete before launching Phase 1.** Do not launch any phase agent until steps 1-6 above are finished.

## Artifact Path Tracking

As each phase completes, the orchestrator must capture the exact file paths of artifacts produced and pass them explicitly to downstream phases. Never rely on agents finding "the most recent" file — always provide the exact path.

Track these artifacts as they are produced:
- `WORKFLOW_SLUG` — set after Phase 1: a short, lowercase, hyphenated slug derived from the refined request objective (e.g. `oauth2-auth`, `user-mgmt-api`). Every artifact filename in this workflow that contains a slug MUST use this exact value, so all artifacts of one request are linkable.
- `REFINED_REQUEST_FILE` — set after Phase 1
- `CODEBASE_SCAN_FILE` — set after Phase 2 (or empty if skipped)
- `INVESTIGATION_FILE` — set after Phase 3a (or empty if skipped by triage)
- `TECHNICAL_RESEARCH_FILES` — list of paths, set after Phase 3b (or empty if no research needed)
- `PLAN_FILE` — set after Phase 4
- `DESIGN_SPEC_FILE` — set after Phase 5: the per-request design file (`docs/design/design-NNN-[WORKFLOW SLUG].md`)
- `DESIGN_FILE` — always the absolute path `<project root>/docs/design/project-design.md` (the living project design document the design-builder updates)
- `FILES_TOUCHED_UNION` — set after the Phase 6 post-coding conflict check: the verified union of all coder agents' "Files touched" lists (plus any files the Merge Resolver touched)
- `REVIEW_REPORT_FILE` — set after Phase 7: the code-review report (`docs/reference/code-review-[WORKFLOW SLUG].md`)
- `DEPENDENCY_VALIDATION_FILE` — set after Phase 8 (the validator always writes a report — when no package manager is detected its status is `skipped_no_manifest`)
- `TEST_BUILD_REPORT_FILES` — list of per-agent report paths, set after Phase 9
- `INTEGRATION_REPORT_FILE` — set after Phase 10

When constructing agent instructions for subsequent phases, replace placeholders with the actual paths:
- `[WORKFLOW SLUG]` → value of `WORKFLOW_SLUG`
- `[REFINED REQUEST FILE]` → value of `REFINED_REQUEST_FILE`
- `[CODEBASE SCAN FILE]` → value of `CODEBASE_SCAN_FILE`
- `[INVESTIGATION FILE]` → value of `INVESTIGATION_FILE`
- `[TECHNICAL RESEARCH FILES]` → list of `TECHNICAL_RESEARCH_FILES` paths (or "none")
- `[PLAN FILE]` → value of `PLAN_FILE`
- `[DESIGN SPEC FILE]` → value of `DESIGN_SPEC_FILE`
- `[DESIGN FILE]` → value of `DESIGN_FILE`
- `[FILES TOUCHED UNION]` → the `FILES_TOUCHED_UNION` list
- `[REVIEW REPORT FILE]` → value of `REVIEW_REPORT_FILE`
- `[DEPENDENCY VALIDATION FILE]` → value of `DEPENDENCY_VALIDATION_FILE` (or "none")
- `[TEST BUILD REPORT FILES]` → list of `TEST_BUILD_REPORT_FILES` paths (or "none")

Always pass artifact paths as **absolute paths** when constructing agent instructions — agents may resolve relative paths against a different working directory.

Additionally, pass the original raw request to every downstream agent as a fallback against interpretation drift introduced by refinement: include the line `The original user request was: "[INSERT RAW REQUEST HERE]"` (replacing the placeholder with `$ARGUMENTS`) in each phase prompt that reads the refined request.

## Workflow Phases

Execute the following phases in order. Each phase uses the Task tool to launch specialized agents.

---

### Phase 1: Request Refiner

Launch a **foreground** agent using the `request-refiner` agent to analyze, clarify, and refine the raw request into a structured, unambiguous specification that all downstream phases will consume.

**Agent type**: `request-refiner`
**Instructions for the agent**:

```
Refine the following raw request into a structured specification:

<raw-request>
[INSERT RAW REQUEST HERE]
</raw-request>

This specification will drive a full development workflow (investigation, planning, design, implementation, review, and testing), so ensure the refinement is thorough and development-oriented.

Save the refined specification under `<absolute path to project root>/docs/reference/` (create the directory if missing), following your `refined-request-<slug>.md` naming convention — do not resolve the directory relative to your own working directory. Report the file's absolute path and the slug.

You run in an isolated subagent context: AskUserQuestion cannot reach the user from here. Do not block on clarifications — make reasonable, documented assumptions (Assumptions section) and record every ambiguity that genuinely needs the user's decision in the "Open Questions" section with a recommended default. The orchestrator resolves them with the user immediately after you finish.
```

**Wait for completion before proceeding.**

After Phase 1 completes:
1. Read the refined request file path and store it as `REFINED_REQUEST_FILE`.
2. Set `WORKFLOW_SLUG` to the slug the request-refiner reported (its `Slug:` line — the same slug embedded in the refined-request filename). Only if the agent failed to report one, derive it yourself from the refined request objective — short, lowercase, hyphenated (e.g. `oauth2-auth`, `user-mgmt-api`). Use this exact slug in every slug-bearing artifact filename for the rest of the workflow.
3. **Open-questions gate (mandatory):** read the refiner's reported open-questions count (and the refined request's "Open Questions" section). If greater than zero, resolve each question with the user via AskUserQuestion (offering the refiner's recommended default as the first option), append the resolutions to the refined-request file's "Open Questions" section, and only then proceed to triage. The refiner runs in an isolated subagent context and cannot reach the user itself — this gate is where its unresolved ambiguities get answered.

**Phase triage** — before launching Phase 2, decide which conditional phases this request actually needs, using the skip criteria from the project CLAUDE.md pipeline rules:

1. **Phase 2 (Codebase Scanner)** — skip if the project is greenfield (no source files outside `node_modules/`, `.git/`, `docs/`). **Reuse instead of re-scanning** if `docs/reference/codebase-scan-[WORKFLOW SLUG].md` already exists, its frontmatter `last_scanned_commit` matches the current `git rev-parse HEAD`, AND its `scanned_for_request` matches `WORKFLOW_SLUG` (the scanner writes the request slug in that field, not the filename) — in that case set `CODEBASE_SCAN_FILE` to the existing file and skip the scanner.
2. **Phase 3a (Investigator)** — skip when ANY of these hold: a single, obvious approach already used in the project satisfies the request; the project's CLAUDE.md, `docs/design/project-design.md`, or an existing tool documentation already prescribes the approach; the work is a localized change with a self-evident strategy; a still-valid investigation artifact from a previous run covers this request (reuse it as `INVESTIGATION_FILE`).
3. **Phase 3b (Technical Research)** — normally driven by Phase 3a's "Research needed" flag. Exception: if the request directly names a specific library/API/SDK and asks for usage or integration guidance, skip Phase 3a and dispatch Phase 3b directly for that topic.

**Explicit-skip rule**: every time triage skips (or reuses an artifact for) a phase, announce it to the user in one sentence with the reason (e.g., "Skipping investigation — project-design.md already prescribes the approach.") so the user can override. When a phase is skipped, set its artifact variable to empty, replace its placeholder in downstream prompts with `none (skipped: <reason>)`, and drop the corresponding "Read the ..." step from those prompts.

---

### Phase 2: Codebase Scanner (Conditional)

This phase runs **only if triage marked it required** (see "Phase triage" after Phase 1): the project must have source code files (i.e., not purely greenfield), and no reusable scan may exist for the current `WORKFLOW_SLUG` and `HEAD`. If triage decided to reuse an existing scan, `CODEBASE_SCAN_FILE` is already set — skip this phase. If the project is greenfield, skip this phase and proceed with `CODEBASE_SCAN_FILE` empty.

Launch a **foreground** agent using the `codebase-scanner` agent. The scanner produces a structured markdown overview with YAML frontmatter (language, package_manager, build_command, test_command, lint_command, entry_points, last_scanned_commit) that downstream phases — Planner, Designer, Integration Verifier — can read directly without re-detecting these fields themselves.

**Agent type**: `codebase-scanner`
**Instructions for the agent**:

```
Scan this codebase and produce a structured overview narrowed to the areas relevant to the request.

Inputs:
- request_file: [REFINED REQUEST FILE]
- output_path: <absolute path to project root>/docs/reference/codebase-scan-[WORKFLOW SLUG].md

Apply request-driven narrowing (Step 4 of your workflow) so the Integration Points section is populated.
```

**Wait for completion before proceeding.**

After Phase 2 completes, set `CODEBASE_SCAN_FILE` to the output path the scanner reported.

**Duplication check (mandatory after every scan)** — before launching Phase 3a, read the scan's "Module Map" and "Integration Points" sections and classify the requested feature:

1. **Already implemented** → STOP. Use AskUserQuestion to ask the user whether to (a) extend the existing implementation, (b) replace it, or (c) abandon the request as already done. If (c), end the workflow; if (a) or (b), record the decision and pass it explicitly to the Investigator, Planner, and Designer prompts.
2. **Partially implemented** → record a directive for the Planner: the work MUST be scoped as an extension of the existing module, citing the file/symbol locations from the scan — NOT as a parallel implementation. Include this directive verbatim in the Phase 4 instructions.
3. **New Integration Point flagged** → record a directive for the Designer: the design must explain where the new module lands, how it interacts with the existing surface, and which conventions it adopts from the scan's "Conventions" section. Include this directive verbatim in the Phase 5 instructions.

---

### Phase 3a: Investigator (Conditional)

This phase runs **only if triage marked it required** (see "Phase triage" after Phase 1). If triage skipped it, proceed to Phase 3b (if triage dispatched direct research) or Phase 4.

Launch a **foreground** agent using the `investigator` agent to research available approaches, recommend the best fit, and identify any topics requiring deeper technical research.

**Agent type**: `investigator`
**Instructions for the agent**:

```
Investigate available approaches and solutions for the following request.

Save the investigation document to `<absolute path to project root>/docs/reference/investigation-[WORKFLOW SLUG].md` (use this path verbatim).

Read the refined request specification at `[REFINED REQUEST FILE]` to understand the full scope, requirements, and constraints.

If a codebase scan exists at `[CODEBASE SCAN FILE]`, read it to understand the current architecture, technology stack, and conventions. Focus your research on approaches compatible with the existing codebase.

This investigation will feed into planning, design, and implementation phases, so ensure the recommendation is specific and actionable.

IMPORTANT: In the "Technical Research Guidance" section of your output, assess whether any specific technologies, libraries, or patterns from your recommendation need deeper technical research before the team can proceed to planning. Be selective — only flag topics where the investigation found insufficient detail for confident implementation.
```

**Wait for completion before proceeding.**

After Phase 3a completes:
1. Read the investigation file and store its path as `INVESTIGATION_FILE`
2. Locate the "Technical Research Guidance" section in the investigation document
3. Check whether "Research needed" is "Yes" or "No"

---

### Phase 3b: Technical Deep Research (Conditional)

This phase runs **only if the investigator flagged topics in the "Technical Research Guidance" section** (i.e., "Research needed: Yes"), OR if triage dispatched direct research because the request names a specific library/API/SDK and asks for usage guidance (in that case derive the topic, focus areas, and depth from the refined request instead of an investigation document). If "Research needed: No" and triage dispatched nothing, skip this phase and proceed directly to Phase 4.

For each topic listed in the guidance section, launch a `technical-researcher` agent. If multiple topics are listed and they are independent, launch them in **parallel** using `run_in_background: true`.

**Agent type**: `technical-researcher` (one per topic)
**Instructions for each agent** (adapt per topic):

```
You are conducting a deep technical research dive on a specific topic identified during an investigation phase.

**Context**: Read the investigation document at `[INVESTIGATION FILE]` to understand the broader context and recommendation. Your research supports the implementation of this recommendation.
(Omit the Context line above when triage dispatched direct research — no investigation document exists in that case; the topic derives from the refined request instead.)

Inputs:
- topic: [TOPIC NAME from the guidance section's Name field, or derived from the refined request on direct dispatch]
- why_needed: [WHY from the guidance section, or from the refined request on direct dispatch]
- focus_areas: [FOCUS from the guidance section, or from the refined request on direct dispatch]
- depth_level: [DEPTH from the guidance section, or your judgment on direct dispatch]
- investigation_file: [INVESTIGATION FILE]   (omit this line on direct dispatch)
- output_path: <absolute path to project root>/docs/research/[topic-slug].md
  (derive [topic-slug] from the topic by lowercasing and replacing spaces/underscores with hyphens)

Produce comprehensive technical documentation following your standard output format and save it to the output_path above.

Ensure your documentation includes:
- Practical code examples relevant to the focus areas
- Best practices and common pitfalls
- Any findings that might affect the approach recommended in the investigation
```

**Wait for all technical research agents to complete.**

After Phase 3b completes, collect all research file paths into `TECHNICAL_RESEARCH_FILES`.

---

### Phase 4: Planner

Launch a **foreground** agent using the `plan-builder` agent to create the implementation plan. The plan is a Claude-executable prompt — dependency-ordered atomic steps with per-step verification — and carries YAML frontmatter (`status`, `open_questions`, `files_to_create`, `files_to_modify`, `implementation_units`) that this orchestrator and the coder fan-out parse directly.

**Agent type**: `plan-builder`
**Instructions for the agent**:

```
Create the implementation plan for this workflow.

Inputs:
- request_file: [REFINED REQUEST FILE]
- investigation_file: [INVESTIGATION FILE]   (omit this line if Phase 3a was skipped)
- research_files: [TECHNICAL RESEARCH FILES]   (omit this line if Phase 3b produced nothing)
- codebase_scan_file: [CODEBASE SCAN FILE]   (omit this line if Phase 2 was skipped)
- design_file: <absolute path to project root>/docs/design/project-design.md   (omit if it does not exist)
- output_path: <absolute path to project root>/docs/design/plan-NNN-[WORKFLOW SLUG].md
  (derive NNN as the next sequential plan number)
- duplication_directive: [DIRECTIVE FROM THE PHASE 2 DUPLICATION CHECK]   (omit if none was recorded)
- original_request: "[INSERT RAW REQUEST HERE]"

Also review the plan against the global and project CLAUDE.md instructions and the project's existing architecture before writing it, and update docs/design/project-functions.md with any new functional requirements.
```

**Wait for completion before proceeding.**

After Phase 4 completes:
1. Read the plan file path the agent reported and store it as `PLAN_FILE`.
2. If the agent reported status `blocked_on_inputs`, stop and resolve the missing input (re-run the producing phase) before retrying — never proceed with a partial plan.
3. **Open-questions gate (mandatory):** read the plan's YAML frontmatter `open_questions` count. If greater than zero, read the "Open Questions" section and use AskUserQuestion to resolve each entry with the user (the plan includes a recommended default per question) BEFORE launching Phase 5. Record the answers, append them to the plan's "Open Questions" section as resolutions, and include them explicitly in the Designer's instructions. Do not proceed to design with unresolved open questions.
4. If the agent flagged a scan-commit mismatch or an investigation conflict, surface it to the user before continuing.

---

### Phase 5: Designer

Launch a **foreground** agent using the `design-builder` agent to create the technical design. The design file carries YAML frontmatter (`status`, `implementation_units` with per-unit files and interface contracts, `files_to_create`, `files_to_modify`, `units_changed_from_plan`) that Phase 6 parses directly for the coder fan-out. The agent also updates the living `docs/design/project-design.md` with a dated, provenance-linked section.

**Agent type**: `design-builder`
**Instructions for the agent**:

```
Create the technical design for this workflow.

Inputs:
- request_file: [REFINED REQUEST FILE]
- plan_file: [PLAN FILE]
- investigation_file: [INVESTIGATION FILE]   (omit this line if Phase 3a was skipped)
- research_files: [TECHNICAL RESEARCH FILES]   (omit this line if Phase 3b produced nothing)
- codebase_scan_file: [CODEBASE SCAN FILE]   (omit this line if Phase 2 was skipped)
- project_design_file: [DESIGN FILE]
- output_path: <absolute path to project root>/docs/design/design-NNN-[WORKFLOW SLUG].md
  (use the same NNN as the plan file, so plan and design pair up)
- integration_directive: [DIRECTIVE FROM THE PHASE 2 DUPLICATION CHECK]   (omit if none was recorded)
- resolved_open_questions: [ANSWERS RECORDED AT THE PHASE 4 OPEN-QUESTIONS GATE]   (omit if there were none)
- original_request: "[INSERT RAW REQUEST HERE]"
```

**Wait for completion before proceeding.**

After Phase 5 completes:
1. Store the design file path the agent reported as `DESIGN_SPEC_FILE`.
2. If the agent reported status `blocked_on_inputs`, stop and resolve the missing input (re-run the producing phase) before retrying.
3. If the agent flagged conflicts with the plan or investigation, surface them to the user before continuing.

Then ask the user to review the design before proceeding to implementation. Use AskUserQuestion to present a summary of the design — including every entry the agent listed under "Decisions Requiring User Review" — and ask:
- "The technical design is ready. Should I proceed with implementation, or do you want to review and adjust the design first?"

---

### Phase 6: Coders (Parallel Implementation)

Identify the independent implementation units and launch **parallel** agents. Read the `implementation_units` frontmatter of the design at `[DESIGN SPEC FILE]` — the design-builder started from the plan's units and adjusted them where the architecture demanded (its `units_changed_from_plan` flag tells you whether they differ from the plan's partition), so the design's units are authoritative. Re-verify that they still have pairwise-disjoint file sets before launching.

**Agent type**: `general-purpose` (multiple instances)
**Instructions for each agent**:

```
You are a developer implementing a specific part of the design. Use Serena semantic tools for code modifications when working with existing files.

The original user request was: "[INSERT RAW REQUEST HERE]"

Your assigned implementation unit (from the design's `implementation_units` frontmatter):
- name: [UNIT NAME]
- plan_steps: [PLAN STEP NUMBERS FOR THIS UNIT]
- files you own: [UNIT FILE LIST]
- exposes / consumes: [UNIT CONTRACT NAMES]

**File ownership (hard rule):** you may create or modify ONLY the files in your unit's file list above. Other files are owned by parallel agents or are out of scope. If completing a step seems to require touching any other file, STOP that step and record it in your final report under a section titled "Blocked — out of ownership" instead of writing the change. Exception: do NOT edit `Issues - Pending Items.md` directly either (parallel agents would conflict) — list any deviation-log entries the plan's rules would send there in your final report under "Deviations & deferred items"; the orchestrator records them after the phase.

Steps:
1. Read the refined request specification at `[REFINED REQUEST FILE]` to understand the full scope and acceptance criteria
2. Read the technical design at `[DESIGN SPEC FILE]` — your unit's section defines the files you own and the interface contracts you expose and consume; the "API & Interface Contracts" section is the single source of truth for shared signatures
3. Read the plan at `[PLAN FILE]` and execute exactly the steps listed in your unit's plan_steps, in dependency order. Each step defines its files, action, a verify command, and a done condition — run the step's verify command after completing it and do not move on until it passes. Follow the plan's "Deviation Rules for Executors" section for anything you discover mid-step (subject to the file-ownership rule above)
4. If a codebase scan exists at `[CODEBASE SCAN FILE]`, read it to understand existing code patterns and conventions before implementing
5. For modifications to existing files:
   a. Use `mcp__serena__find_symbol` with `include_body: true` to read the current implementation of symbols you need to modify
   b. Use `mcp__serena__replace_symbol_body` to modify existing symbols
   c. Use `mcp__serena__insert_after_symbol` or `mcp__serena__insert_before_symbol` to add new code
   d. Use `mcp__serena__find_referencing_symbols` to find and update all references when changing interfaces
   e. For new files, use the Write tool but ensure the code follows patterns from the codebase scan
6. Follow strictly:
   - The interface contracts defined in the design
   - The project's code style and patterns
   - TypeScript for all tools (per project CLAUDE.md)
   - No fallback values for configuration settings - raise exceptions
   - FastAPI for Python REST APIs (if applicable)
   - Database naming conventions: singular table names
7. Before adding ANY new runtime dependency to a manifest (package.json, pyproject.toml, etc.), apply the dependency-vetting procedure from the project CLAUDE.md <dependency-vetting> section: identify the latest stable major, check it for security advisories, and pin a caret range against a verified-clean version. Do NOT write the vetting-log entry into `Issues - Pending Items.md` yourself (file-ownership rule above) — instead, list each vetted dependency (package, pinned version, vetted-on date) in your final report under a section titled "Dependency vetting log"; the orchestrator appends them to the file after this phase. Never copy a dependency version from a reference implementation without re-verifying it.
8. After implementation, verify:
   - Use `mcp__cclsp__get_diagnostics` on modified files to check for type errors
   - Ensure no broken references by checking symbols you changed with `mcp__serena__find_referencing_symbols`
9. If you created a new tool, do NOT scaffold its documentation file (docs/tools/<tool-name>.md) or its ~/.tool-agents/<tool-name>/ config folder by hand — the tool-doc-config-architect agent owns that specification. Instead, list each new tool in your final report under an explicit section titled "New tools created", giving for each: `tool_name` (lowercase-with-hyphens), a one-or-two-sentence capability description, `tool_command` (the exact CLI command users run), `llm_required` (yes/no — whether the tool talks to LLM providers), and any extra non-LLM config vars (name + purpose). The orchestrator passes these fields verbatim to the scaffolding agent after this phase — omitting `tool_command` or `llm_required` makes that dispatch fail
10. End your final report with an explicit section titled "Files touched" listing the path of EVERY file you created or modified (including documentation files). The orchestrator uses this list for conflict detection — omitting a file is a defect.
```

If only one implementation unit is identified, launch it as a **foreground** agent instead of a background task. Otherwise, launch as many parallel agents as there are independent units. Use `run_in_background: true` for all parallel agents but track their completion.

**Important**: Before launching parallel agents, verify that the implementation units are truly independent — no two agents should modify the same file. If the design has overlapping units, either serialize those units or merge them into a single agent.

**Wait for all coding agents to complete before proceeding.**

**Post-coding conflict check**: After all agents complete, check for file conflicts:
1. Collect each agent's "Files touched" list from its final report. If an agent failed to report one, treat that as a defect: derive its list by asking the agent (if still reachable) or flag it for the Merge Resolver.
2. Intersect the per-agent lists pairwise — any file appearing in two or more lists was modified by multiple agents and needs reconciliation (git cannot tell you this; only the per-agent lists can).
3. Run `git status --porcelain` and take every changed AND untracked path (do NOT use `git diff --name-only` — it omits newly created files, which are untracked, so created-file work would look missing and unattributed new files would escape detection). Compare this list against the union of the per-agent lists, then cross-reference with the design document. Before comparing, exclude the **workflow-owned artifacts** — files this workflow's orchestrator and phase agents legitimately modify outside any coder's list: everything under `docs/reference/` (phase artifacts, reports, `workflow-checkpoint.json`), everything under `docs/design/` (plan, design, `project-design.md`, `project-functions.md`), `Issues - Pending Items.md`, everything under `prompts/`, and the project `CLAUDE.md` (Tools-section entries). These are expected and need no investigation. Then:
   - Files in git's list (changed or untracked) but in no agent's list (after the exclusion) → unattributed changes; investigate before proceeding.
   - Design units with no corresponding modified files → work was missed; re-dispatch that unit.
4. If any file was modified by more than one agent, launch a **foreground** "Merge Resolver" agent to reconcile the changes:
   - Read both versions of the conflicting file
   - Merge the changes preserving both agents' contributions
   - Verify the merged result compiles using `mcp__cclsp__get_diagnostics`
   - Use `mcp__serena__find_referencing_symbols` to verify no broken references
5. Store the verified union of all per-agent "Files touched" lists (plus any files the Merge Resolver touched) as `FILES_TOUCHED_UNION` — Phase 7 receives it as the authoritative review list.
6. **Tool scaffolding**: collect every entry from the coders' "New tools created" sections. For each new tool, launch a **foreground** `tool-doc-config-architect` agent with its full scaffold input contract: `mode: scaffold`, `tool_name`, `project_root` (absolute project root), `tool_description`, `tool_command`, `llm_required`, and `extra_config_vars` — taking the last four from the coder's report entry. If a coder's entry is missing `tool_command` or `llm_required`, determine them yourself by reading the tool's entry point before dispatching (the architect hard-fails on missing required fields). Then add the concise entry it recommends to the "Tools" section of the project's CLAUDE.md. Add only the **in-repo** files it touched (e.g. `docs/tools/<tool-name>.md`) to `FILES_TOUCHED_UNION` — its `~/.tool-agents/<tool-name>/` artifacts live outside the repository, never appear in `git diff`, and must not enter the union (they would trip Phase 7's cross-check as phantom discrepancies). Skip this step if no new tools were reported.
7. **Deviation log, vetting log & ownership blocks**: append every entry from the coders' "Deviations & deferred items" sections to `Issues - Pending Items.md`, and every entry from their "Dependency vetting log" sections to that file's "Dependency vetting log" section (create the section if missing) — the coders are forbidden from editing the file directly to avoid parallel write conflicts. For every "Blocked — out of ownership" entry, decide how to route it: if the file belongs to another unit, hand the change to that unit's agent (or a follow-up foreground agent); otherwise dispatch a small foreground agent to apply it, and add the touched files to `FILES_TOUCHED_UNION`.
8. If no conflicts are found, proceed directly to the next phase

---

### Phase 7: Code Reviewer

Launch a **foreground** agent to review all implemented code.

**Agent type**: `general-purpose`
**Instructions for the agent**:

```
You are a senior code reviewer. Review all code produced by the implementation phase. You MUST use Serena semantic tools and LSP tools for verification — do not rely solely on reading files.

The original user request was: "[INSERT RAW REQUEST HERE]"

Steps:
1. Read the refined request specification at `[REFINED REQUEST FILE]` to understand the acceptance criteria
2. Read the technical design at `[DESIGN SPEC FILE]`
3. Read the plan at `[PLAN FILE]`
4. If a codebase scan exists at `[CODEBASE SCAN FILE]`, read its YAML frontmatter (`build_command`, `test_command`, `lint_command`) and use those commands in the quality verification below instead of guessing them
5. The orchestrator verified the implementation's file list during the post-coding conflict check — review these files: [FILES TOUCHED UNION]. Cross-check with `git status --porcelain` (changed AND untracked paths — `git diff --name-only` would miss newly created files) and the design's `files_to_create`/`files_to_modify` frontmatter. When comparing, ignore the workflow's own artifacts — files under `docs/reference/`, `docs/design/`, `prompts/`, plus `Issues - Pending Items.md` and the project `CLAUDE.md` — they are orchestrator-owned and expected to differ. Investigate any other discrepancy before reviewing further

6. **Semantic verification** — for each modified file:
   a. Use `mcp__cclsp__get_diagnostics` to check for type errors, warnings, and other compiler issues
   b. Use `mcp__serena__get_symbols_overview` to verify the symbol structure matches the design
   c. For changed symbols, use `mcp__serena__find_referencing_symbols` to verify all references are intact and updated
   d. Use `mcp__cclsp__find_references` to trace any broken call chains

7. **Quality verification** — for each file:
   - Correctness: Does the code do what the design specifies?
   - Completeness: Are all design requirements implemented?
   - Build: Run the build command from the codebase scan frontmatter (step 4) to verify compilation; only if no scan exists, detect it (e.g. `npx tsc --noEmit` or equivalent)
   - Style: Does it follow project conventions?
   - Security: No command injection, XSS, SQL injection, or other OWASP top 10 vulnerabilities
   - Configuration: No fallback values for missing configuration settings
   - Documentation: Does every new tool have a concise entry in the project CLAUDE.md "Tools" section pointing to its `docs/tools/<tool-name>.md` documentation file, and does that file exist? Flag gaps in your summary — do NOT hand-write the documentation file yourself (the tool-doc-config-architect agent owns its format)

8. If gaps or deviations from the design are found:
   a. Fix the code issues using Serena tools (`mcp__serena__replace_symbol_body`, `mcp__serena__insert_after_symbol`, etc.)
   b. Update the technical design at `[DESIGN SPEC FILE]` to reflect any necessary design changes, and mirror each change as a dated note in this design's section of `docs/design/project-design.md`
   c. Re-verify with `mcp__cclsp__get_diagnostics` until design and implementation are aligned

9. Update `Issues - Pending Items.md` at the project root:
   - Add any unresolved issues found during review
   - Remove any issues that were fixed during this process
   - Order: critical/important pending items first, completed items after

10. Produce a review report and save it to `<absolute path to project root>/docs/reference/code-review-[WORKFLOW SLUG].md` with: files reviewed, diagnostics found, issues fixed, design changes made (step 8b), remaining concerns, and an overall verdict (`approved` | `approved_with_concerns` | `rework_needed`). End your final message with the absolute path of the report and the verdict
```

**Wait for completion before proceeding.**

After Phase 7 completes:
1. Store the report path the agent returned as `REVIEW_REPORT_FILE`.
2. If the verdict is `rework_needed`, surface the remaining concerns to the user via AskUserQuestion (re-run the affected Phase 6 unit, continue anyway, or abort) before proceeding.
3. If the verdict is `approved_with_concerns`, no gate is needed — but the concerns must not be dropped: the review report is passed to Phase 10 (which verifies each concern was addressed or lists it as unresolved), and every concern still open after Phase 10 must appear in the Post-Workflow Summary.

---

### Phase 8: Dependency Validator

Launch a **foreground** agent using the `dependency-validator` agent to verify that the implementation uses no deprecated modules and is free of known security advisories.

**Agent type**: `dependency-validator`
**Instructions for the agent**:

```
Validate this project's dependency tree.

Inputs:
- target_path: <absolute path to the project root>
- request_file: [REFINED REQUEST FILE]
- output_path: <absolute path to project root>/docs/reference/dependency-validation-[WORKFLOW SLUG].md
- mode: fix
- max_iterations: 5
- include_security_audit: true

Run the full validate → replace → re-install loop until the project is clean, the iteration cap is hit, or the loop stalls. Save the structured report to the output_path above.

If your run ends with status `error`, `regressed`, or `stalled`, state that status and its cause prominently at the start of your final message so the workflow can decide whether to abort or continue.
```

**Wait for completion before proceeding.**

After Phase 8 completes:
1. Read the validation report and store its path as `DEPENDENCY_VALIDATION_FILE`.
2. Inspect the YAML frontmatter `status` field:
   - `clean` → continue to step 3.
   - `skipped_no_manifest` → no package manager detected; announce it in one sentence and proceed directly to Phase 9 (step 3 does not apply).
   - `deprecations_found` *(expected only from `report-only`/`interactive` runs — with `mode: fix` it means the mode input was not honored)*, `partially_fixed`, `stalled`, `max_iterations_reached`, `regressed`, `error` → use `AskUserQuestion` to surface the situation to the user with the manual-review items from the report, and ask whether to continue, retry, or abort.
3. **Post-validation re-check**: if the report shows the validator replaced any modules, it modified manifests — and possibly import statements — AFTER the Phase 7 code review. Read the report's list of replaced modules and touched files, run `mcp__cclsp__get_diagnostics` on any modified source files, and run the project's build command to confirm compilation still succeeds. If diagnostics or the build fail, fix the breakage (or surface it via AskUserQuestion) before launching Phase 9. If no replacements were made, proceed directly.

---

### Phase 9: Test Builders (Parallel Test Implementation)

Based on the implementation, identify independent testable units and launch one **parallel** `test-builder` agent per unit.

**Splitting rules** (the orchestrator decides the splits before launching):
- **Default split**: one test-builder per implementation unit from the design's `implementation_units` frontmatter (at `[DESIGN SPEC FILE]`) — those units were already verified pairwise file-disjoint, which is exactly the property the test split needs. Deviate only when the rules below force it (e.g. two units' tests would land in the same test files, or a unit is doc-only).
- Each unit must have a clear `scope` description — feature name, file list, or symbol list.
- Two units must not target the same source files (otherwise the agents would race to write tests for the same symbols).
- Two units must not require modifying the same shared test infrastructure (e.g. both needing to add a fixture to `conftest.py`) — the agent will refuse to edit shared infra and surface the conflict.
- If only one independent unit exists, launch it as a **foreground** agent instead of a background task.

**Agent type**: `test-builder` (one instance per unit)
**Instructions for each agent**:

```
Build tests for the assigned scope.

Inputs:
- scope: [SCOPE DESCRIPTION FROM SPLIT — feature name, file list, or symbol list]
- target_path: <absolute path to project root>
- output_path: <absolute path to project root>/docs/reference/test-build-[WORKFLOW SLUG]-[scope-slug].md
- request_file: [REFINED REQUEST FILE]
- design_file: [DESIGN SPEC FILE]
- codebase_scan_file: [CODEBASE SCAN FILE]   (omit this line if Phase 2 was skipped)
- mode: write-and-run

Detect the framework (or read it from codebase_scan_file), find existing tests for the symbols in scope, update them where the implementation changed, add new tests for new behavior, then run only the tests you touched. Do not modify any production source. Do not edit shared test infrastructure (conftest.py, setup files, jest.config.*) — surface those needs in "Manual review needed" instead.

Save the structured report to the output_path above and return the path plus pass/fail counts.
```

Launch all test-builder agents using `run_in_background: true` and track their completion.

**Wait for all test-builder agents to complete.**

**Aggregation step** — after all agents finish:
1. Collect each agent's report path and store the list as `TEST_BUILD_REPORT_FILES`.
2. Read each report's YAML frontmatter and aggregate:
   - Total `tests_added`, `tests_updated`, `tests_passed`, `tests_failed`, `implementation_gaps`.
   - Any agent with `status` other than `completed` → surface its situation.
   - All entries from each report's "Manual review needed" → present them collectively.
3. If any agent reports `implementation_gaps > 0`, use `AskUserQuestion` to ask whether to:
   - Continue to Phase 10 (the integration verifier may surface them again with more context),
   - Pause to fix the implementation gaps now (re-run Phase 6/7 for the affected unit), or
   - Abort the workflow.
4. If any agent reports `status: ownership_violation`, `invalid_input`, `scope_unresolvable`, or `error`, abort and surface the failure — these indicate a defect in how the orchestrator split the work (an unresolvable or malformed scope is the orchestrator's fault, not the agent's).

---

### Phase 10: Integration Verifier

Launch a **foreground** agent to run the complete build and test suite, verifying that everything works together end-to-end.

**Agent type**: `general-purpose`
**Instructions for the agent**:

```
You are an integration verification specialist. Your task is to verify that the entire implementation builds, passes all tests, and works as a cohesive whole.

The original user request was: "[INSERT RAW REQUEST HERE]"

Read the refined request specification at `[REFINED REQUEST FILE]` to understand the acceptance criteria.

Read the plan at `[PLAN FILE]` — its "Verification" section defines the overall checks the plan committed to.

Read the test-build reports at [TEST BUILD REPORT FILES] so known implementation gaps and "Manual review needed" items inform your acceptance-criteria check instead of being rediscovered from scratch.

Read the code-review report at `[REVIEW REPORT FILE]` — for each entry under its "remaining concerns", verify whether it has since been addressed; list every concern still open in your verification report under a "Review concerns still open" section (an empty section means all were addressed).

If a dependency validation report exists at `[DEPENDENCY VALIDATION FILE]`, read its status and manual-review items.

If a codebase scan exists at `[CODEBASE SCAN FILE]`, read it first to identify the project's build command, test runner, and lint configuration rather than guessing.

Execute the following verification steps in order:

1. **Build verification**:
   - Run the project's build command (use the one identified in the codebase scan if available, otherwise detect: e.g., `npx tsc --noEmit`, `npm run build`, or equivalent)
   - Capture and report any build errors
   - If build fails, list all errors with file paths and line numbers

2. **Test suite execution**:
   - Identify the project's test runner (e.g., jest, vitest, mocha, pytest)
   - Run the complete test suite (e.g., `npm test`, `npx jest`, `npx vitest run`, or equivalent)
   - Capture the full output including pass/fail counts
   - If any tests fail, report: test name, file, assertion that failed, and error message

3. **Lint/static analysis** (if configured):
   - Check if a linter is configured (eslint, prettier, etc.)
   - If so, run it and report any violations

4. **Acceptance criteria check**:
   - Review each acceptance criterion from the refined request
   - For each criterion, state whether it is met, partially met, or not met, with evidence

5. **Produce a verification report** and save it to `<absolute path to project root>/docs/reference/integration-verification-[WORKFLOW SLUG].md`:
   - Build status: pass/fail (with error count if failed)
   - Test results: total, passed, failed, skipped
   - Lint results: clean / violations found
   - Acceptance criteria: met / not met per criterion
   - Overall verdict: READY or NEEDS FIXES
   If you perform fixes (step 6), update the report afterwards so it reflects the final state. End your final message with the absolute path of the report file.

6. **If NEEDS FIXES**:
   - List all issues that must be resolved, ordered by severity
   - Attempt to fix build errors and failing tests
   - Re-run the build and test suite after fixes
   - If fixes cannot be resolved, document them clearly

Update `Issues - Pending Items.md` with any unresolved issues found during verification.
```

**Wait for completion before proceeding.**

After Phase 10 completes, store the report path the agent returned as `INTEGRATION_REPORT_FILE`.

---

## Checkpoint & Resume

After each phase completes successfully, write a checkpoint file at `docs/reference/workflow-checkpoint.json` with the following structure:

```json
{
  "workflow": "team-workflow",
  "timestamp": "<ISO 8601 timestamp>",
  "request_summary": "<short description of the request>",
  "workflow_slug": "<WORKFLOW_SLUG or null>",
  "git_head": "<output of `git rev-parse HEAD` at checkpoint time, or null>",
  "last_completed_phase": "<phase id as a string — \"1\", \"2\", \"3a\", \"3b\", \"4\" ... — never a bare number, since 3a/3b are not integers>",
  "last_completed_phase_name": "<phase name>",
  "artifacts": {
    "REFINED_REQUEST_FILE": "<path or null>",
    "CODEBASE_SCAN_FILE": "<path or null>",
    "INVESTIGATION_FILE": "<path or null>",
    "TECHNICAL_RESEARCH_FILES": ["<path1>", "<path2>"],
    "PLAN_FILE": "<path or null>",
    "DESIGN_SPEC_FILE": "<path or null>",
    "DESIGN_FILE": "<path or null>",
    "FILES_TOUCHED_UNION": ["<path1>", "<path2>"],
    "REVIEW_REPORT_FILE": "<path or null>",
    "DEPENDENCY_VALIDATION_FILE": "<path or null>",
    "TEST_BUILD_REPORT_FILES": ["<path1>", "<path2>"],
    "INTEGRATION_REPORT_FILE": "<path or null>"
  },
  "decisions": {
    "triage": [
      {
        "phase": "<phase id, e.g. \"2\", \"3a\", \"3b\">",
        "action": "skipped | reused",
        "reason": "<one sentence>"
      }
    ],
    "duplication_directive": "<verbatim directive text from the Phase 2 duplication check, or null>",
    "integration_directive": "<verbatim directive text for the Designer, or null>",
    "resolved_open_questions": [
      {
        "phase": "<\"1\" or \"4\" — which gate resolved it>",
        "question": "<the question>",
        "answer": "<the user's answer>"
      }
    ],
    "design_approved": "<true | false | null — null until the Phase 5 review gate runs>"
  },
  "phases": [
    {
      "phase": "1",
      "name": "Request Refiner",
      "status": "completed",
      "timestamp": "<ISO 8601>"
    },
    {
      "phase": "6",
      "name": "Coders",
      "status": "in_progress",
      "timestamp": "<ISO 8601>",
      "units": [
        {
          "unit": "<short unit description from the design>",
          "status": "completed | in_progress | failed",
          "files_touched": ["<path1>", "<path2>"],
          "report_path": "<path or null>"
        }
      ]
    }
  ]
}
```

**Overwrite** the checkpoint file after each phase — it always reflects the latest state.

**The `decisions` block is part of the checkpoint, not an afterthought**: update it the moment a decision is made (a triage skip, a duplication/integration directive, a resolved open question, the design-review approval) — these decisions bind downstream prompts, so a resume that loses them would dispatch agents without their directives. Use `[]`/`null` for decisions not (yet) made.

**Per-unit checkpointing for parallel phases (6 and 9)**: do not wait for the whole phase to finish before checkpointing. When the parallel agents are launched, write the phase entry with `status: in_progress` and one `units` entry per unit. As each agent completes, update its unit's `status`, `files_touched` (Phase 6), and `report_path` (Phase 9). On resume, a phase whose entry has incomplete units is re-entered by re-dispatching ONLY the units not marked `completed` — never re-run a completed unit, as its agent already mutated files.

**Resuming a workflow**: If the user invokes this command and a `docs/reference/workflow-checkpoint.json` file already exists:
1. Read the checkpoint file
2. Verify the `"workflow"` field matches `"team-workflow"`. If it doesn't (e.g., it's from a change-workflow run), inform the user: "A checkpoint from a different workflow ([workflow name]) was found. It cannot be resumed by team-workflow. Delete it and start fresh?" If the user confirms, delete the file and proceed normally.
3. **Staleness validation** before offering to resume:
   - Verify every non-null artifact path in the checkpoint still exists on disk. List any missing files.
   - Compare the checkpoint's `git_head` with the current `git rev-parse HEAD`. If they differ, the codebase has moved since the checkpoint — completed-phase artifacts (scan, plan, design) may no longer match reality.
   - If artifacts are missing or HEAD has moved, include this prominently in the resume question: "Warning: [N artifacts missing / HEAD has moved since the checkpoint]. Resuming may operate on stale state."
4. Present the checkpoint state to the user: which phase completed last, what artifacts exist, when it was saved, and any staleness warnings from step 3
5. Use AskUserQuestion to ask: "A previous workflow checkpoint was found (last completed: Phase [N] — [name]). Do you want to resume from Phase [N+1], or start a fresh workflow?"
6. If resuming, restore `WORKFLOW_SLUG`, the artifact paths, AND the entire `decisions` block from the checkpoint — re-apply the triage skips (do not re-triage), and re-inject `duplication_directive`, `integration_directive`, and `resolved_open_questions` into the downstream prompts exactly as a fresh run would have. Then skip directly to the next uncompleted phase. If the last phase entry is a parallel phase (6 or 9) with `status: in_progress`, re-enter it and re-dispatch only the units not marked `completed`.
7. If starting fresh, delete the checkpoint file and proceed normally

**Cleanup**: After the Post-Workflow Summary is presented to the user, delete the checkpoint file — the workflow is complete.

---

## Post-Workflow Summary

After all phases complete:

1. Read the `Issues - Pending Items.md` file and present any outstanding items
2. Provide a summary to the user:
   - What was implemented
   - Files created/modified
   - Tests created
   - Any remaining issues or manual steps needed — including every code-review concern still open after Phase 10 (from the integration report's "Review concerns still open" section)
   - Links to all generated documentation, including the integration verification report at `INTEGRATION_REPORT_FILE`
3. Delete the `docs/reference/workflow-checkpoint.json` file

## Error Handling

- If any phase fails, the checkpoint file preserves progress up to the last successful phase
- Stop the workflow and report the failure to the user with context
- Ask the user whether to retry the failed phase, skip it, or abort the workflow
- Never silently skip a phase

## Important Constraints

- Tools created in the project are written in TypeScript (per project CLAUDE.md); other code follows the project's established language (Python REST APIs use FastAPI per the global CLAUDE.md)
- No fallback values for configuration settings - raise exceptions for missing config
- New tools are scaffolded exclusively via the `tool-doc-config-architect` agent (per `/tool-conventions`); the project CLAUDE.md "Tools" section gets only a concise entry pointing to `docs/tools/<tool-name>.md` — never full tool documentation
- Plans go in `docs/design/plan-NNN-<description>.md`
- Reference material goes in `docs/reference/`
- Test scripts go in `test_scripts/`
- Prompts go in `prompts/` with sequential numbering
- Database tables use singular names
- Update `Issues - Pending Items.md` at project root
- Update `docs/design/project-functions.md` with functional requirements
- Update `docs/design/project-design.md` with design changes
