# The 18 layouts

Every method is called on the object returned by `createDeck()`. All of them
accept two common options:

| Option | Type | Meaning |
|---|---|---|
| `notes` | string | Greek speaker note — build it with `NOTE(purpose, tips)` |
| `section` | string | Footer label on the left (auto-uppercased) |

Slide numbers, the footer rule, and the section label are handled by the
library. Never add them yourself.

Canvas is 10 × 5.625 in. The content band is x 0.5–9.5, y 1.7–5.1. The eyebrow
sits at y 0.35 and the footer rule at y 5.25 — those two are the only elements
outside the band.

---

## Selection

The template serves two families of deck — engineering and business. They share
the same layouts because they share the same spine: a situation, the options,
the evidence, and the decision being asked for. Only the vocabulary differs.

| If the content is… | Engineering example | Business example | Method | Layout |
|---|---|---|---|---|
| Opening | — | — | `cover` | 01 |
| Meta-explanation of the template | — | — | `howToUse` | 02 |
| Section map / agenda | — | — | `agenda` | 03 |
| Transition between major parts | — | — | `sectionDivider` | 04 |
| Up to 3 points + one key takeaway | What breaks today | The situation and its driver | `contentCallout` | 05 |
| Two options of equal weight | Two designs | Build vs buy; two strategies | `twoColumn` | 06 |
| A visual is the primary carrier | Architecture diagram | Org chart, market map, journey | `imageText` | 07 |
| 3 MECE items | Design principles, guarantees | Strategic pillars, workstreams | `threePillars` | 08 |
| A single headline number | Latency, error rate | Saving, revenue at risk, ROI | `bigStat` | 09 |
| Current vs target state | Before/after a migration | Current vs target operating model | `beforeAfter` | 10 |
| One authoritative line | Design tenet, postmortem finding | Customer quote, board mandate, regulatory requirement | `pullQuote` | 11 |
| A trend or distribution | Benchmark, load profile | Cost trend, volumes, adoption | `chart` | 12 |
| A sequence of 3–5 stages | Request path, rollout | Roadmap phases, milestone plan | `timeline` | 13 |
| A comparison matrix | Benchmark table | Vendor or option scoring | `table` | 14 |
| What to remember / what happens next | — | The ask | `takeaways` | 15 |
| Sources | Papers, RFCs, ADRs, repos | Market reports, contracts, internal analyses | `references` | 16 |
| Closing | — | — | `qa` | 17 |
| Appendix / design reference | — | — | `designTokens` | 18 |

### Canonical spine — engineering, 20–25 minutes

Cover → Agenda → Divider "Problem" → Content + callout (what breaks today) →
Big stat (the number that motivates the work) → Divider "Design" → Image + text
(architecture diagram) → Three-pillar (design principles or guarantees) →
Timeline (request path or rollout stages) → Divider "Results" → Chart
(benchmark) → Table (comparison matrix) → Divider "Adoption" → Before/After
(migration path) → Takeaways → References → Q&A.

**Variants.** A *design review* usually swaps the benchmark chart for a second
`twoColumn` weighing the rejected option. A *postmortem* runs Timeline
(incident sequence) → Big stat (impact) → Content + callout (root cause) →
Takeaways (action items with owners). An *onboarding* deck leans on
`threePillars` and `timeline` and drops the stat and chart entirely.

### Canonical spine — business, 20–25 minutes

Cover → Agenda → Divider "Situation" → Content + callout (what is happening and
why now) → Big stat (the number that motivates the decision) → Divider
"Options" → Two-column (the two live options) → Table (options scored against
the criteria) → Divider "Recommendation" → Before/After (current vs target) or
Three-pillar (the workstreams) → Timeline (phases with dates) → Chart (cost,
benefit, or volume profile) → Takeaways (the ask) → References → Q&A.

**Variants.** A *steering or program update* drops the options section
entirely and runs Timeline (plan vs actual) → Table (RAG status per workstream)
→ Content + callout (the one blocker) → Takeaways (the decisions needed). A
*quarterly business review* leads with Chart and Table and keeps a single
`twoColumn` for what changed against plan. A *vendor evaluation* is Table-led:
the criteria are the argument, so the comparison table comes early and
everything after it explains a column.

Both spines are 17 slides. Cut to fit; never exceed 18 for a 25-minute slot.
`howToUse` and `designTokens` are template scaffolding — drop them from real
decks.

**Where business decks go wrong in this template.** The pull to fill slides
with dense text is strongest in business decks, and this system will not absorb
it: three bullets is the ceiling on `contentCallout`, three items on
`threePillars`, three takeaways. If the material does not fit, it belongs in a
pre-read document and the deck carries the argument. A steering committee that
needs the detail will ask for the appendix; one that needs the decision will
thank you for the whitespace.

---

## 01 — `cover(o)`

Opening slide: topic, speaker, date.

```javascript
deck.cover({
  eyebrow: "DESIGN REVIEW",   // ALL CAPS, tracked
  title: "Reworking the retrieval path",   // <= 8 words
  subtitle: "Why ranking, not generation, is the bottleneck",
  author: "Author Name",
  affiliation: "Platform Engineering",
  date: "Month YYYY",
});
```

**Rule:** title ≤ 8 words. Everything else goes in the subtitle. Nothing above
the accent rule at y=2.0 except the eyebrow.

---

## 02 — `howToUse(o)`

Bilingual meta-slide explaining the template to whoever opens the file. Cream
background. Delete it before shipping a real deck.

```javascript
deck.howToUse({
  rules: ["Ένα μήνυμα ανά slide.", "..."],      // left column, bulleted
  tokens: [["Accent", "007B85"], ["Ink", "1A1A2E"]],  // right column
});
```

Defaults produce a sensible Greek rules list and the current palette's tokens.

---

## 03 — `agenda(o)`

4–6 sections, numbered, each with a one-line description.

```javascript
deck.agenda({
  eyebrow: "OVERVIEW", title: "Agenda",
  items: [
    ["01", "The problem", "What breaks at current scale"],
    ["02", "Proposed design", "How the new path works"],
    ["03", "Benchmarks", "What we measured"],
    ["04", "Migration", "How we get there without downtime"],
  ],
});
```

**Rule:** more than 6 rows will not fit — group instead. Descriptions are
phrases, not sentences.

---

## 04 — `sectionDivider(o)`

Full-bleed cream, a 160 pt section number, a vertical accent rule, then the
section title.

```javascript
deck.sectionDivider({
  number: "01", label: "SECTION",
  title: "The problem",
  subtitle: "A one-sentence framing of what this section covers.",
});
```

**Rule:** increment `number` on every divider, and keep the structure identical
across all of them. Varying dividers destroys the sense of a spine.

---

## 05 — `contentCallout(o)`

Bulleted body on the left, one highlighted insight on the right.

```javascript
deck.contentCallout({
  eyebrow: "PROBLEM", title: "Where the current path breaks",
  bullets: [
    { text: "Re-ranking runs synchronously on every request",
      sub: ["Adds 340 ms at p95", "Scales linearly with candidate count"] },
    { text: "The cache keys on the raw query", sub: ["Hit rate is 11%"] },
    "Fallbacks are untested under partial failure",
  ],
  callout: { label: "Root cause",
             text: "We optimised recall and never bounded the candidate set." },
});
```

Main bullets render bold in ink; `sub` entries render indented in muted grey.

**Rule:** max 3 main bullets. The callout holds one message — the root cause,
the decision, the constraint — not a summary of the slide.

---

## 06 — `twoColumn(o)`

Two options or approaches of equal weight. The standard design-review slide.

```javascript
deck.twoColumn({
  eyebrow: "OPTIONS", title: "Two ways to bound the candidate set",
  left:  { heading: "Static top-k",    body: "…",
           bullets: ["Simple", "Predictable latency"] },
  right: { heading: "Adaptive cutoff", body: "…",
           bullets: ["Better recall", "Harder to reason about"] },
});
```

**Rule:** match the two columns in length and rhythm — an imbalance reads as a
thumb on the scale. If you have already chosen, say so on the next slide rather
than by starving one column. Never put a rule line under the headings.

**Business variant.** Build vs buy, two vendors, two strategies, in-house vs
outsourced. The discipline is the same and matters more: a steering committee
reads a starved column as a decision already taken, and will spend the meeting
on that instead of on your recommendation. Give the option you are rejecting
its strongest form.

---

## 07 — `imageText(o)`

Interpretive text left, diagram right. The architecture slide.

```javascript
deck.imageText({
  eyebrow: "DESIGN", title: "Proposed request path",
  heading: "What changes",
  body: "Two sentences telling the audience what to look at in the diagram and why it matters.",
  bullets: ["Ranking moves off the hot path", "Cache keys on the embedding",
            "Fallback is explicit"],
  image: "./architecture.png",        // omit for a placeholder box
  caption: "Figure 1. Proposed retrieval path. Source: ADR-118.",
});
```

**Rule:** every diagram gets a caption, and the caption cites where the diagram
comes from — an ADR, an RFC, a repo path. The body text says what to look at;
it does not narrate the boxes.

Export diagrams at 2× the placement size so they stay sharp when projected.

---

## 08 — `threePillars(o)`

Exactly three MECE items: design principles, guarantees, components, tenets.

```javascript
deck.threePillars({
  eyebrow: "PRINCIPLES", title: "Three guarantees the new path keeps",
  pillars: [
    { num: "01", title: "Bounded latency",   body: "Two sentences." },
    { num: "02", title: "Explicit fallback", body: "Two sentences." },
    { num: "03", title: "Observable stages", body: "Two sentences." },
  ],
});
```

Extra pillars are dropped. `num` defaults to the index.

**Rule:** exactly 3, equal description lengths, same level of abstraction, no
rule lines under the titles. Four components means either grouping two of them
or using `timeline` instead.

---

## 09 — `bigStat(o)`

One number, at 144 pt.

```javascript
deck.bigStat({
  eyebrow: "BASELINE", title: "Where the time goes",
  stat: "62%",
  label: "of p95 latency is spent in re-ranking",
  body: "Measured across 40 production deployments over six weeks, at steady-state load.",
  source: "Source: latency dashboard, 2026-06.",
});
```

**Rule:** round numbers only — `62%`, never `61.7%`. **State the conditions**:
percentile, load, sample size, time window, and hardware where it matters. A
number without its conditions is not evidence. One of these per deck.

**Figure length is handled for you.** 144 pt holds about four characters in the
5 in column; anything longer would wrap onto a second line and collide with the
title. `bigStat` measures the string and scales the size down — `62%` stays at
144 pt, `€1.4m` renders at 116, `18 months` at 61. Override with
`statFontSize` if you want a specific size, but check the result: nothing in
the QA script can see text overflow, only your eyes can.

**Business variant.** A saving, a revenue at risk, a payback period, an ROI, a
headcount. The conditions rule is the same and is where business decks fail
hardest: a €1.4m saving needs the base year, the assumptions, whether it is
gross or net of migration cost, and run-rate versus first-year. Put the figure
in `stat`, the claim in `label`, the assumptions in `body`, and the origin in
`source`. If the number is a forecast rather than an actual, say so on the
slide — not in the notes.

```javascript
deck.bigStat({
  eyebrow: "THE CASE", title: "What consolidation returns",
  stat: "€1.4m",
  label: "annual run-rate saving from year two",
  body: "Net of migration cost, at current contracted volumes. Forecast, not yet contracted.",
  source: "Source: vendor contracts + FY26 volume plan.",
});
```

---

## 10 — `beforeAfter(o)`

Current state vs proposed state, or before/after a migration. The "after" card
carries the accent border, so the eye lands there.

```javascript
deck.beforeAfter({
  eyebrow: "MIGRATION", title: "Current and proposed",
  before: { label: "TODAY",    title: "Synchronous rerank", bullets: ["…","…","…"] },
  after:  { label: "PROPOSED", title: "Bounded candidates", bullets: ["…","…","…"] },
});
```

**Rule:** identical bullet counts and comparable sentence lengths on both sides,
and the bullets must be parallel — bullet *n* on the right answers bullet *n* on
the left.

**Business variant.** Current versus target operating model, as-is versus
to-be process, this year versus next. Keep the left card honest: an unfairly
bleak "today" is the most common tell of a deck selling something, and the one
person in the room who lives in that process will say so.

---

## 11 — `pullQuote(o)`

Full-bleed cream, giant quote mark, one quotation: a design tenet, a postmortem
finding, a line from an incident review or an RFC.

```javascript
deck.pullQuote({
  quote: "Every unbounded queue is an outage that has not happened yet.",
  author: "Author Name",
  source: "Incident review INC-2291",
});
```

**Rule:** ≤ 30 words. One pull quote per deck — a second halves the effect of
the first. Attribute it; an unattributed quote in a technical deck reads as
filler.

---

## 12 — `chart(o)`

Chart left, interpretation right. The benchmark slide.

```javascript
deck.chart({
  eyebrow: "BENCHMARK", title: "p95 latency by candidate count",
  type: "bar",                    // "bar" (default) | "line" | "pie"
  seriesName: "p95 (ms)",
  labels: ["k=50", "k=100", "k=200", "k=500"],
  values: [180, 240, 410, 890],
  panelLabel: "What this shows",
  interpretation: "Latency is superlinear beyond k=200 — the knee is the candidate set, not the model.",
  source: "Source: bench/retrieval, commit a3f21e.",
});
```

Chart styling (colours, gridlines, data labels, no legend) is fixed by the
system. One series per chart.

**Rule:** never ship a chart without the interpretation panel. The chart and the
sentence are one argument. Cite the benchmark — a chart whose source is not
reproducible is an opinion with axes.

**Note:** `save()` rewrites the category axis so labels survive Google Slides —
see `design-system.md` §Google Slides.

---

## 13 — `timeline(o)`

3–5 stages on a connecting rule: a pipeline, a request path, rollout phases, an
incident sequence.

```javascript
deck.timeline({
  eyebrow: "REQUEST PATH", title: "Four stages, one budget",
  steps: [
    { title: "Embed",    body: "Query to vector, 12 ms" },
    { title: "Retrieve", body: "ANN search, 40 ms" },
    { title: "Rank",     body: "Cross-encoder, bounded at 80 ms" },
    { title: "Generate", body: "Streamed, 300 ms to first token" },
  ],
});
```

Spacing is computed from the step count. Steps beyond 5 are dropped.

**Rule:** stage titles are one word. More than 5 stages → split across two
slides, or collapse to 3. For a request path, put the per-stage budget in the
body — that is what makes the slide useful in a review.

**Business variant.** Roadmap phases, milestone plan, rollout waves. Put the
date and the owner in the body; a phase without either is an intention, not a
plan. This layout is not a Gantt chart and should not be made into one — if the
audience needs dependencies and overlaps, that is an appendix or a separate
document.

```javascript
deck.timeline({
  eyebrow: "ROADMAP", title: "Four phases to consolidation",
  steps: [
    { title: "Select",    body: "Vendor chosen — Q3, Procurement" },
    { title: "Contract",  body: "Signed — Q4, Legal" },
    { title: "Migrate",   body: "Two waves — Q1, Platform" },
    { title: "Decommission", body: "Legacy off — Q2, Operations" },
  ],
});
```

---

## 14 — `table(o)`

A comparison matrix or a benchmark table.

```javascript
deck.table({
  eyebrow: "COMPARISON", title: "Options against our constraints",
  headers: ["Option", "p95", "Recall@10", "Ops cost", "Risk"],
  rows: [
    ["Static top-k", "210 ms", "0.81", { text: "low", muted: true }, "low"],
    ["Adaptive cutoff", "340 ms", { text: "0.89", significant: true },
      { text: "medium", muted: true }, "medium"],
    ["Two-stage cache", { text: "195 ms", significant: true }, "0.86",
      { text: "medium", muted: true }, "low"],
  ],
  source: "Source: bench/retrieval, 2026-07-02. Accent marks the best value per column.",
});
```

Cells are plain strings, or objects with `significant` (bold + accent) or
`muted` (grey).

**Rule:** accent in a table marks the value that carries the decision — the
winning number, the significant result, the blocking constraint. Never
decoration. Say in the source line what the accent means. Secondary values go
muted. Six columns is the practical ceiling.

**Business variant.** Vendor scoring, option comparison, RAG status per
workstream. Two failure modes to avoid: scoring everything against criteria
nobody agreed (state where the criteria come from in the source line), and
colour-coding every cell until the accent means nothing. If three cells are
accented in a five-row table, the table has no message — rank the criteria and
accent only the column that decides.

```javascript
deck.table({
  eyebrow: "STATUS", title: "Workstreams against plan",
  headers: ["Workstream", "Owner", "Plan", "Forecast", "Status"],
  rows: [
    ["Migration", { text: "Team A", muted: true }, "Q3", "Q3", "on track"],
    ["Contracts", { text: "Team B", muted: true }, "Q3",
      { text: "Q4", significant: true }, { text: "at risk", significant: true }],
  ],
  source: "Source: programme plan v4, 2026-07-20. Accent marks slippage.",
});
```

---

## 15 — `takeaways(o)`

Exactly three things to remember.

```javascript
deck.takeaways({
  items: [
    { title: "The bottleneck is the candidate set", body: "Not the model, not the index." },
    { title: "Bounding it costs 3 points of recall", body: "We think that trade is right." },
    { title: "Decision needed by 15 August", body: "Otherwise the migration slips a quarter." },
  ],
});
```

**Rule:** exactly 3, and the third must be actionable — a decision, an owner, a
date. In a design review the third takeaway is what you are asking the room for.

**Business variant.** In a business case or a steering update this slide *is*
the deck; everything before it is support. Name the ask precisely: what
decision, by whom, by when, and what happens if it slips. "We recommend
proceeding" is not an ask — "approve €300k and a Q4 start, or the FY27 saving
is lost" is.

---

## 16 — `references(o)`

Sources and further reading: papers, RFCs, ADRs, repos, dashboards, runbooks.
Entries are plain strings, or arrays of runs so titles can be italicised.

```javascript
deck.references({
  entries: [
    "ADR-118 — Bounding the retrieval candidate set. internal/adr/118.md",
    [{ text: "Khattab & Zaharia (2020). ColBERT: Efficient and effective passage search. " },
     { text: "SIGIR '20", italic: true },
     { text: ". https://doi.org/10.1145/3397271.3401075" }],
    "RFC 9114 — HTTP/3. https://www.rfc-editor.org/rfc/rfc9114",
    "Benchmark harness — github.com/org/repo/tree/main/bench/retrieval",
  ],
});
```

Cite whatever the claims rest on: academic sources in APA 7, internal sources by
identifier and path so the audience can actually find them.

**Rule:** ≤ 4 entries per slide — a fifth goes on a second References slide.
Never shrink the font to fit. Every number and every diagram in the deck should
be traceable to something on this slide.

**Business variant.** Market reports, analyst notes, contracts, internal
analyses, the programme plan, the model the figures came out of. Cite the
version and the date — "programme plan v4, 2026-07-20", not "programme plan".
A financial figure whose model nobody can open is the fastest way to lose a
steering committee.

---

## 17 — `qa(o)`

Closing slide. Stays on screen for the whole Q&A, so it must carry contact info.

```javascript
deck.qa({
  headline: "Q&A",
  thanks: "Thank you.",
  contact: ["Author Name", "author@org.gr", "#team-platform · internal/adr/118"],
});
```

First contact line renders bold ink, the rest muted.

**Rule:** always include contact details, and for an internal talk add where the
follow-up lives — the channel, the ADR, the doc. That is the slide's job.

---

## 18 — `designTokens(o)`

Internal reference sheet: colour swatches and the type scale. Defaults to the
active palette, so it stays correct after a palette swap.

```javascript
deck.designTokens({});
```

Keep it for collaborators, delete it for an audience.

---

## Escape hatch — `custom(o)`

When a slide genuinely has no home among the 18 — a code listing, a wide
sequence diagram — `custom` gives you a raw slide with the title block and
footer already applied.

```javascript
deck.custom({
  eyebrow: "SPECIAL", title: "One-off slide", section: "Appendix",
  notes: NOTE("…", []),
  build(slide, { pres, C, HEAD, LABEL, accentRule }) {
    slide.addText("…", { x: 0.5, y: 1.7, w: 9, h: 1, fontFace: HEAD,
                          fontSize: 14, color: C.ink, margin: 0, valign: "top" });
  },
});
```

Use it rarely. Three custom slides in one deck means the content is fighting the
system — restructure the content instead.

For code, resist `custom`: a monospaced block at a readable projected size fits
about 12 lines. If the excerpt is longer it belongs in the repo, and the slide
should carry the one line that matters plus the file path.
