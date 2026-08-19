# engineering-deck

Build engineering **and business** presentations as real, editable PowerPoint
files.

- **Engineering** — design reviews, architecture walkthroughs, tech talks, RFC
  and ADR presentations, postmortems, benchmark reports, migration proposals,
  engineering onboarding.
- **Business** — business cases and investment proposals, steering committee
  and program status updates, quarterly business reviews, strategy and roadmap
  decks, vendor evaluations and build-vs-buy, operating-model changes.

The two families share the same layouts because they share the same spine: a
situation, the options, the evidence, and the decision being asked for. Only
the vocabulary differs.

The deck is composed from 18 predefined layouts on a fixed grid, in one of two
palettes, with Greek speaker notes on every slide explaining what the layout is
for. Output opens identically in PowerPoint and Google Slides.

## Installation

This plugin is part of the `biks-claude-tools` marketplace.

```
/plugin marketplace add BikS2013-ClaudeCode/biks-claude-tools
/plugin install engineering-deck@biks-claude-tools
```

## What you get

**Command — `/engineering-deck <brief>`**
Turns a talk brief into a finished `.pptx`: identifies the family and deck
type, picks the palette, maps the brief onto layouts, checkpoints the outline
with you, writes the build script, runs the automated QA, and reports which
numbers came from the brief and which were left as gaps.

```
/engineering-deck a 20-minute design review of the retrieval path rework,
  for the platform team, asking for a go/no-go by 15 August

/engineering-deck a 15-minute steering update on the vendor consolidation
  programme, Q3 reporting period, two workstreams at risk
```

**Skill — `engineering-deck`**
Loads automatically whenever a technical or business deck comes up. Progressive
disclosure: `SKILL.md` for the workflow, `references/` for layout APIs, design
tokens, and the QA checklist.

**Library — `assets/deck-lib.js`**
A pptxgenjs wrapper with one method per layout. The grid, the colour rules, the
footer, and automatic slide numbering are already encoded.

```javascript
const { createDeck, NOTE } = require("./deck-lib");
const deck = createDeck({ palette: "teal", title: "Design review" });

deck.cover({ title: "Reworking the retrieval path", subtitle: "…",
             author: "…", date: "July 2026",
             notes: NOTE("Εξώφυλλο.", ["Τίτλος έως 8 λέξεις."]) });
deck.bigStat({ stat: "62%", label: "of p95 latency is spent in re-ranking",
               section: "Problem", notes: NOTE("…", []) });
deck.qa({ contact: ["Name", "name@org.gr"], notes: NOTE("Κλείσιμο.", []) });

await deck.save("design-review.pptx");
```

**Template generator — `assets/build-template.js`**
Regenerates the full 18-slide reference deck in either palette.

```bash
node build-template.js --palette teal -o template-teal.pptx
```

**QA checker — `assets/qa-check.js`**
Unzips a built deck and verifies the rules that can be checked without
rendering: speaker notes on every slide, footer rule present, automatic slide
numbers, no hard-coded page numbers, no leftover placeholders, no margin
violations, exactly two typefaces.

```bash
node qa-check.js talk.pptx        # exit 0 = clean
```

**Prebuilt templates — `skills/engineering-deck/templates/`**
`template-teal.pptx` and `template-burgundy.pptx`, 18 slides each. Use as a
visual index, or open one and overwrite slide by slide.

## The 18 layouts

Cover · How-to-use · Agenda · Section divider · Content + callout · Two-column
(options / build-vs-buy) · Diagram + text (architecture / org / journey) ·
Three-pillar grid (principles / workstreams) · Big stat (latency / ROI) ·
Before/After (migration / target operating model) · Pull quote · Chart
(benchmark / cost trend) · Timeline (request path / roadmap phases) ·
Comparison table (benchmark / vendor scoring) · Takeaways (the ask) ·
References (RFCs, ADRs, repos, market reports, contracts) · Q&A · Design tokens

`references/layouts.md` §Selection carries a canonical spine per family plus
variants — design review, postmortem, onboarding on the engineering side;
business case, steering update, quarterly review, vendor evaluation on the
business side — and a per-layout business note where the two diverge
(`bigStat` conditions, `table` scoring, `timeline` phases, `takeaways` as the
ask).

## Palettes

| | Accent | Ink | Use for |
|---|---|---|---|
| **Lean Corporate** (default) | teal `007B85` | `1A1A2E` | both families — engineering, platform, product, business; matches LeanPresentationStyle |
| **Warm Editorial** | burgundy `8B2635` | `1A1A1A` | papers, formal evaluations, academic-conference talks |

Switching is one argument. Custom token objects are accepted.

## Requirements

Node ≥ 18 and `pptxgenjs` (`npm install pptxgenjs`) in the build directory.
Nothing else — no API keys, no services.

Inter is native in Google Slides but not installed by default in desktop
PowerPoint. Install it from [rsms.me/inter](https://rsms.me/inter), or pass
`headFont: "Segoe UI"` to `createDeck()`.

## Layout

```
engineering-deck/
  .claude-plugin/plugin.json
  commands/engineering-deck.md
  skills/engineering-deck/
    SKILL.md
    references/{layouts,design-system,qa-checklist}.md
    assets/{deck-lib,build-template,qa-check}.js, package.json
    templates/template-{teal,burgundy}.pptx
  README.md
```

## Credits

The layout system is derived from the Academic & Training presentation guide;
this implementation corrects four margin bugs in that spec and adds a Google
Slides chart-category fix. Both are documented in
`references/design-system.md`.
