# academic-deck

Build academic and training presentations — lectures, workshops, research
talks, professional training — as real, editable PowerPoint files.

The deck is composed from 18 predefined layouts on a fixed grid, in one of two
palettes, with Greek speaker notes on every slide explaining what the layout is
for. Output opens identically in PowerPoint and Google Slides.

## Installation

```
/plugin marketplace add BikS2013/biks-claude-tools
/plugin install academic-deck@biks-claude-tools
```

## What you get

**Command — `/academic-deck <brief>`**
Turns a talk brief into a finished `.pptx`: picks the palette, maps the brief
onto layouts, checkpoints the outline with you, writes the build script, runs
the automated QA, and reports what it assumed.

```
/academic-deck a 20-minute research talk on retrieval quality in production RAG,
  for a university seminar, speaker Giorgos Marinos, NBG
```

**Skill — `academic-training-deck`**
Loads automatically whenever a lecture / workshop / training deck comes up.
Progressive disclosure: `SKILL.md` for the workflow, `references/` for layout
APIs, design tokens, and the QA checklist.

**Library — `assets/deck-lib.js`**
A pptxgenjs wrapper with one method per layout. The grid, the colour rules, the
footer, and automatic slide numbering are already encoded.

```javascript
const { createDeck, NOTE } = require("./deck-lib");
const deck = createDeck({ palette: "teal", title: "My talk" });

deck.cover({ title: "…", subtitle: "…", author: "…", date: "July 2026",
             notes: NOTE("Εξώφυλλο.", ["Τίτλος έως 8 λέξεις."]) });
deck.bigStat({ stat: "62%", label: "…", section: "Findings", notes: NOTE("…", []) });
deck.qa({ contact: ["Name", "name@org.gr"], notes: NOTE("Κλείσιμο.", []) });

await deck.save("talk.pptx");
```

**Template generator — `assets/build-template.js`**
Regenerates the full 18-slide reference deck in either palette.

```bash
node build-template.js --palette burgundy -o template-burgundy.pptx
```

**QA checker — `assets/qa-check.js`**
Unzips a built deck and verifies the rules that can be checked without
rendering: speaker notes on every slide, footer rule present, automatic slide
numbers, no hard-coded page numbers, no leftover placeholders, no margin
violations, exactly two typefaces.

```bash
node qa-check.js talk.pptx        # exit 0 = clean
```

**Prebuilt templates — `skills/academic-training-deck/templates/`**
`template-teal.pptx` and `template-burgundy.pptx`, 18 slides each. Use as a
visual index, or open one and overwrite slide by slide.

## The 18 layouts

Cover · How-to-use · Agenda · Section divider · Content + callout · Two-column ·
Image + text · Three-pillar grid · Big stat · Before/After · Pull quote ·
Chart + interpretation · Timeline · Results table · Takeaways · References
(APA 7) · Q&A · Design tokens

## Palettes

| | Accent | Ink | Use for |
|---|---|---|---|
| **Warm Academic** | burgundy `8B2635` | `1A1A1A` | research, humanities, university audiences |
| **Lean Corporate** | teal `007B85` | `1A1A2E` | corporate, tech, strategy; matches LeanPresentationStyle |

Switching is one argument. Custom token objects are accepted.

## Requirements

Node ≥ 18 and `pptxgenjs` (`npm install pptxgenjs`) in the build directory.
Nothing else — no API keys, no services.

Inter is native in Google Slides but not installed by default in desktop
PowerPoint. Install it from [rsms.me/inter](https://rsms.me/inter), or pass
`headFont: "Segoe UI"` to `createDeck()`.

## Layout

```
academic-deck/
  .claude-plugin/plugin.json
  commands/academic-deck.md
  skills/academic-training-deck/
    SKILL.md
    references/{layouts,design-system,qa-checklist}.md
    assets/{deck-lib,build-template,qa-check}.js, package.json
    templates/template-{teal,burgundy}.pptx
  README.md
```
