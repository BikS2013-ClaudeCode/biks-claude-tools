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

| If the content is… | Method | Layout |
|---|---|---|
| Opening | `cover` | 01 |
| Meta-explanation of the template | `howToUse` | 02 |
| Section map / agenda | `agenda` | 03 |
| Transition between major parts | `sectionDivider` | 04 |
| Up to 3 points with sub-details + one key takeaway | `contentCallout` | 05 |
| Two parallel ideas of equal weight | `twoColumn` | 06 |
| A figure or image is the primary carrier | `imageText` | 07 |
| 3 MECE concepts | `threePillars` | 08 |
| A single headline statistic | `bigStat` | 09 |
| Change over time, or option comparison | `beforeAfter` | 10 |
| An authoritative quotation | `pullQuote` | 11 |
| A quantitative trend | `chart` | 12 |
| A process in 3–5 discrete steps | `timeline` | 13 |
| Numeric results across conditions | `table` | 14 |
| End-of-section summary | `takeaways` | 15 |
| Bibliography | `references` | 16 |
| Closing | `qa` | 17 |
| Appendix / design reference | `designTokens` | 18 |

### Canonical structure — 20-minute academic talk

Cover → Agenda → Divider "Background" → Two-column (prior work) → Pull quote
(frame the problem) → Divider "Methodology" → Image+text (design) → Timeline
(procedure) → Divider "Findings" → Big stat → Chart → Table → Divider
"Implications" → Before/After or Three-pillar → Takeaways → References → Q&A.

That is 17 slides. Cut to fit; never exceed 18 for a 20-minute slot. `howToUse`
and `designTokens` are template scaffolding — drop them from real decks.

---

## 01 — `cover(o)`

Opening slide: topic, speaker, date.

```javascript
deck.cover({
  eyebrow: "RESEARCH SEMINAR",   // ALL CAPS, tracked
  title: "The Title of Your Presentation",   // <= 8 words
  subtitle: "A concise, descriptive subtitle that sets the context",
  author: "Author Name",
  affiliation: "Affiliation / Department",
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

4–6 sections, numbered, each with a one-line description. Rows separated by
hairline dividers.

```javascript
deck.agenda({
  eyebrow: "OVERVIEW", title: "Agenda",
  items: [
    ["01", "Introduction & context", "Why this topic matters"],
    ["02", "Background & prior work", "What has already been established"],
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
  title: "Introduction & context",
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
  eyebrow: "CONTEXT", title: "Content with hierarchy",
  bullets: [
    { text: "First main point stated as a claim",
      sub: ["Supporting detail", "Second supporting detail"] },
    { text: "Second main point", sub: ["Evidence or example"] },
    "Third main point",                   // a bare string works too
  ],
  callout: { label: "Key insight", text: "The single most important thing…" },
});
```

Main bullets render bold in ink; `sub` entries render indented in muted grey.

**Rule:** max 3 main bullets. The callout holds one message — not a summary of
the slide.

---

## 06 — `twoColumn(o)`

Two parallel ideas of equal weight.

```javascript
deck.twoColumn({
  eyebrow: "COMPARISON", title: "Two parallel ideas",
  left:  { heading: "Theory",  body: "…", bullets: ["…"] },
  right: { heading: "Practice", body: "…", bullets: ["…"] },
});
```

**Rule:** match the two columns in length and rhythm — imbalance reads as bias.
Never put a rule line under the column headings.

---

## 07 — `imageText(o)`

Interpretive text left, figure right.

```javascript
deck.imageText({
  eyebrow: "METHOD", title: "Figure with interpretation",
  heading: "Study design",
  body: "Two sentences telling the audience what to look at and why.",
  bullets: ["Sample and setting", "Instruments", "Analysis"],
  image: "./diagram.png",        // omit for a placeholder box
  caption: "Figure 1. Study design overview. Source: Author, 2026.",
});
```

**Rule:** every figure gets a caption *and* a source. The body text says what to
look at — it does not describe the picture.

---

## 08 — `threePillars(o)`

Exactly three MECE concepts, each with a numbered ring.

```javascript
deck.threePillars({
  eyebrow: "FRAMEWORK", title: "Three parallel concepts",
  pillars: [
    { num: "01", title: "First pillar",  body: "Two sentences." },
    { num: "02", title: "Second pillar", body: "Two sentences." },
    { num: "03", title: "Third pillar",  body: "Two sentences." },
  ],
});
```

Extra pillars are dropped. `num` defaults to the index.

**Rule:** exactly 3, equal description lengths, same level of abstraction, no
rule lines under the titles.

---

## 09 — `bigStat(o)`

One number, at 144 pt.

```javascript
deck.bigStat({
  eyebrow: "KEY FINDING", title: "Headline result",
  stat: "87%",
  label: "of participants improved over the baseline",
  body: "Measured across 240 participants over a 12-week period.",
  source: "Source: Author, 2026. N = 240.",
});
```

**Rule:** round numbers only — `87%`, never `87.34%`. Always state sample size
and time frame. One of these per deck.

---

## 10 — `beforeAfter(o)`

Two cards. The "after" card carries the accent border, so the eye lands there.

```javascript
deck.beforeAfter({
  eyebrow: "CHANGE", title: "Before and after",
  before: { label: "BEFORE", title: "The prior state", bullets: ["…","…","…"] },
  after:  { label: "AFTER",  title: "The new state",   bullets: ["…","…","…"] },
});
```

**Rule:** identical bullet counts and comparable sentence lengths on both sides.

---

## 11 — `pullQuote(o)`

Full-bleed cream, giant quote mark, one quotation.

```javascript
deck.pullQuote({
  quote: "A single authoritative sentence that reframes the problem.",
  author: "Author Name",
  source: "Journal Name, 2026",
});
```

**Rule:** ≤ 30 words. One pull quote per deck — a second one halves the effect
of the first.

---

## 12 — `chart(o)`

Chart left, interpretation right.

```javascript
deck.chart({
  eyebrow: "EVIDENCE", title: "Quantitative trend",
  type: "bar",                    // "bar" (default) | "line" | "pie"
  seriesName: "Outcome",
  labels: ["Baseline", "Week 4", "Week 8", "Week 12"],
  values: [42, 58, 71, 87],
  panelLabel: "What this shows",
  interpretation: "Improvement is monotonic across all four points…",
  source: "Source: Author, 2026.",
});
```

Chart styling (colours, gridlines, data labels, no legend) is fixed by the
system. One series per chart.

**Rule:** never ship a chart without the interpretation panel. The chart and the
sentence are one argument.

**Note:** `save()` rewrites the category axis so labels survive Google Slides —
see `design-system.md` §Google Slides.

---

## 13 — `timeline(o)`

3–5 steps on a connecting rule.

```javascript
deck.timeline({
  eyebrow: "PROCESS", title: "Four-step procedure",
  steps: [
    { title: "Plan",    body: "Define the question and the design" },
    { title: "Collect", body: "Gather data from all sources" },
    { title: "Analyze", body: "Test the hypotheses" },
    { title: "Share",   body: "Publish and disseminate" },
  ],
});
```

Spacing is computed from the step count. Steps beyond 5 are dropped.

**Rule:** step titles are one-word verbs. More than 5 steps → split across two
slides, or compress to 3.

---

## 14 — `table(o)`

Multivariate results.

```javascript
deck.table({
  eyebrow: "RESULTS", title: "Results across conditions",
  headers: ["Condition", "N", "Mean", "SD", "p"],
  rows: [
    ["Control", { text: "80", muted: true }, "42.1", { text: "6.4", muted: true }, "—"],
    ["Treatment A", { text: "80", muted: true },
      { text: "58.7", significant: true }, { text: "5.9", muted: true },
      { text: "< .01", significant: true }],
  ],
  source: "Source: Author, 2026. Bold values are significant at p < .01.",
});
```

Cells are plain strings, or objects with `significant` (bold + accent) or
`muted` (grey).

**Rule:** accent in a table means statistical significance — never decoration.
Secondary values (N, SD) go muted.

---

## 15 — `takeaways(o)`

Exactly three things to remember.

```javascript
deck.takeaways({
  items: [
    { title: "The first thing to remember", body: "One line." },
    { title: "The second thing to remember", body: "One line." },
    { title: "What to do next", body: "An actionable implication." },
  ],
});
```

**Rule:** exactly 3, and the third must be actionable — an implication or a call
to action, not another summary point.

---

## 16 — `references(o)`

APA 7 bibliography. Entries are plain strings, or arrays of runs so journal and
book titles can be italicised.

```javascript
deck.references({
  entries: [
    [{ text: "Author, A. A. (2023). Title of the article. " },
     { text: "Journal Name, 12", italic: true },
     { text: "(3), 45–67. https://doi.org/…" }],
    "Author, C. C. (2024). Book title. Publisher.",
  ],
});
```

**Rule:** ≤ 4 entries per slide — a fifth goes on a second References slide.
Never shrink the font to fit.

---

## 17 — `qa(o)`

Closing slide. Stays on screen for the whole Q&A, so it must carry contact info.

```javascript
deck.qa({
  headline: "Q&A",
  thanks: "Thank you.",
  contact: ["Author Name", "author@institution.edu", "@handle"],
});
```

First contact line renders bold ink, the rest muted.

**Rule:** always include contact details — that is the slide's job.

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

When a slide genuinely has no home among the 18, `custom` gives you a raw slide
with the title block and footer already applied.

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
