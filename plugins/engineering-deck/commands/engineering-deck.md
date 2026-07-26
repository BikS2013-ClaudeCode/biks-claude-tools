---
description: Build an engineering or business presentation (.pptx) from a brief — design reviews, architecture walkthroughs, tech talks, postmortems, benchmark reports, business cases, steering updates, quarterly reviews, strategy and roadmap decks, vendor evaluations. 18 layouts, teal or burgundy palette, Greek speaker notes, automated QA
argument-hint: <brief> [--palette teal|burgundy] [--slides N] [--out path.pptx]
allowed-tools:
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
Turn a talk brief into a finished, editable `.pptx` in the engineering-deck
template, which covers two families: engineering decks (design reviews,
architecture walkthroughs, tech talks, postmortems, benchmarks) and business
decks (business cases, steering updates, quarterly reviews, strategy and
roadmap, vendor evaluations). The command owns the interaction (collecting what
the brief does not say, confirming the outline, reporting the result); the
`engineering-deck` skill owns the design system.

Argument: `$ARGUMENTS` — a free-text brief, optionally with `--palette`,
`--slides`, and `--out` flags. Empty arguments means ask for the brief.
</objective>

<context>
- Working directory: $PWD
- Node available: !`node --version 2>/dev/null || echo "MISSING — required"`
- pptxgenjs installed here: !`test -d node_modules/pptxgenjs && echo yes || echo no`
- Existing decks in this folder: !`ls *.pptx 2>/dev/null || echo "(none)"`
- Today: !`date "+%Y-%m-%d"`
</context>

<process>

1. **Load the design system.** Read the `engineering-deck` skill — `SKILL.md`
   first, then `references/layouts.md` for the layout selection table and the
   deck-type variants (design review, postmortem, onboarding). Do not improvise
   layouts or coordinates; everything needed is there.

2. **Parse `$ARGUMENTS`** into: the brief, `--palette`, `--slides`, `--out`.
   If the brief is empty, ask for it with `AskUserQuestion`. Never invent a
   topic.

3. **Identify the family and the deck type.** Engineering — design review,
   architecture walkthrough, tech talk, postmortem, benchmark report,
   onboarding. Business — business case or investment proposal, steering or
   program status update, quarterly business review, strategy or roadmap deck,
   vendor evaluation or build-vs-buy, operating-model change. The family picks
   the canonical spine in `references/layouts.md` §Selection; the type picks
   the variant. It determines the structure far more than the topic does. Say
   which one you picked.

4. **Fill the gaps.** Every deck needs: topic, audience, talk length, speaker
   name and team, and the date. Beyond that, by type — a design review needs
   the decision being asked for; a postmortem the incident and its impact; a
   business case the ask, the assumptions behind the numbers, and who approves;
   a steering update the reporting period and the workstream owners. Infer what
   you safely can from the brief; ask with a single `AskUserQuestion` (grouped,
   not one at a time) for what genuinely changes the deck. Do not ask about
   anything the brief already settles.

   Palette, if not given: `teal` — the default for both families. Use
   `burgundy` for research-flavoured or academic-conference material. State the
   choice; don't ask.

5. **Size the deck.** Default is the talk length: roughly one slide per minute,
   capped at 18. `--slides` overrides. Start from the canonical structure in
   `references/layouts.md` §Selection, apply the variant for the deck type, and
   cut to fit — never pad with filler slides to reach a number.

6. **Draft the outline** — for each slide: the layout method, the working
   title, and the content it carries. Show it to the user and get agreement
   before writing any code. Skip this checkpoint only if the user explicitly
   said to just build it.

7. **Set up the build directory.** Work in `$PWD` unless `--out` says
   otherwise. If `pptxgenjs` is not installed there, run
   `npm install pptxgenjs`. Copy `deck-lib.js` and `qa-check.js` from the
   skill's `assets/` next to the build script.

8. **Write the build script** (`build-deck.js`): require `./deck-lib`, call one
   layout method per outline row, and give **every** slide a Greek `notes` via
   `NOTE(purpose, tips)` and a `section` footer label. Real content only — no
   `lorem`, no `TODO`, no `[insert]`.

   Both families share a specific failure mode: confident, invented numbers.
   Never fabricate latencies, throughput figures, error rates, benchmark
   results, commit hashes, ADR numbers, costs, savings, ROI figures, headcounts,
   market sizes, contract terms, or citations. If the brief does not supply a
   number, ask for it, or write the slide without it and say so in the report. A
   plausible-looking benchmark that nobody ran, or a saving nobody modelled, is
   worse than a gap. Where a figure is a forecast rather than an actual, label
   it as one on the slide.

9. **Build and QA.**
   ```bash
   node build-deck.js
   node qa-check.js <out>.pptx
   ```
   Fix every FAIL and re-run until the exit code is 0. Read the WARNs — margin
   warnings usually mean real overflow. Then walk the visual checklist in
   `references/qa-checklist.md`; render it if a converter is available.

10. **Report.** Give the user: the output path, the slide count, the palette,
    the deck type, the layout used per slide, the QA result, every number that
    came from the brief versus every one left as a gap, and anything you had to
    assume. Mention that Inter may need installing for desktop PowerPoint, and
    that `headFont` can be switched to `"Segoe UI"` if that is a problem.

</process>

<constraints>
- Never fabricate measurements, benchmarks, incident details, financial figures,
  costs, savings, market data, contract terms, citations, commit hashes, or
  internal document identifiers. Ask, or leave the gap and say so.
- Never hard-code page numbers — `deck-lib.js` handles numbering.
- Never mix the two palettes in one deck.
- Do not upload anything to Drive or send anything anywhere unless asked.
- Do not commit the generated deck to git unless asked.
</constraints>
