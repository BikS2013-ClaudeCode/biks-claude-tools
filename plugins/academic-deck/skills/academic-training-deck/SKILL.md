---
name: academic-training-deck
description: Build academic and training presentations (lectures, workshops, research talks, professional training) as editable .pptx files using the Academic & Training design system — 18 predefined layouts, two palettes (Warm Academic burgundy / Lean Corporate teal), Inter + Calibri typography, Greek speaker notes on every slide. Use whenever the user asks for a lecture deck, workshop slides, a research talk, a training presentation, a defence/seminar deck, or asks to rebuild an existing deck in the academic template. Also use when asked to regenerate the reference template or QA a deck built with it.
---

# Academic & Training Presentation Template

A design system for talks that have to teach something: lectures, workshops,
research presentations, professional training. Output is a real `.pptx` with
editable native objects — no screenshots, no image-only slides.

The system is deliberately narrow. There are 18 layouts, two palettes, two
fonts, and a fixed grid. Everything a deck needs is a composition of those
pieces. When content does not fit a layout, the answer is to split the content,
not to invent a layout.

## What this is not

Not the LeanPresentationStyle (13.33″ python-pptx, Google Slides scaling
math) and not the Quiet Authority family. Those are separate systems. This one
uses a 10 × 5.625 in canvas so the same file renders identically in PowerPoint
and Google Slides with no scaling step.

## Build workflow

1. **Pick the palette.** `burgundy` for academic / research / humanities;
   `teal` for corporate / tech / strategy, or when the deck sits alongside
   other LeanPresentationStyle material. Never mix palettes in one deck.
2. **Map the brief to layouts.** Use the decision table in
   `references/layouts.md` §Selection. For a 20-minute talk start from the
   canonical 17-slide structure there and cut, don't pad.
3. **Write the build script.** Require `assets/deck-lib.js` and call one
   method per slide. Do not hand-roll pptxgenjs calls — the library already
   encodes the grid, the colour rules, and the footer.
4. **Write Greek speaker notes for every slide** with the `NOTE(purpose, tips)`
   helper. This is not optional; the notes are how the next person learns the
   deck.
5. **Run the QA.** `node assets/qa-check.js <deck>.pptx`. Exit code 0 or fix
   what it reports. Then do the visual pass in `references/qa-checklist.md`.

## Minimal example

```bash
cd <workdir> && npm install pptxgenjs
```

```javascript
const { createDeck, NOTE } = require("./deck-lib");

const deck = createDeck({ palette: "teal", title: "My talk", author: "Name" });

deck.cover({
  title: "Retrieval quality in production RAG",
  subtitle: "What we measured across 40 deployments",
  author: "Name", affiliation: "Department", date: "July 2026",
  notes: NOTE("Εξώφυλλο.", ["Τίτλος έως 8 λέξεις."]),
});

deck.bigStat({
  eyebrow: "KEY FINDING", title: "Headline result", section: "Findings",
  stat: "62%", label: "of failures were retrieval, not generation",
  body: "Across 40 deployments over 6 months.",
  notes: NOTE("Ένα ποσοτικό εύρημα.", ["Στρογγυλοί αριθμοί μόνο."]),
});

deck.qa({ contact: ["Name", "name@org.gr"], notes: NOTE("Κλείσιμο.", []) });

deck.save("talk.pptx").then((f) => console.log("Saved", f));
```

Every layout method takes `notes` (Greek speaker note) and `section` (footer
label). The footer rule, the section label, and the auto-updating slide number
are added for you.

## Regenerating the reference template

```bash
node assets/build-template.js --palette teal     -o template-teal.pptx
node assets/build-template.js --palette burgundy -o template-burgundy.pptx
```

Produces an 18-slide deck — one slide per layout, English placeholder content,
Greek speaker notes. Prebuilt copies are in `templates/`. Use them as a visual
index, or open one and overwrite slide by slide when you would rather edit than
script.

## The rules that matter most

These are the ones that separate a deck in this system from a generic one:

1. **One idea per slide.** Two ideas means two slides.
2. **Never put an accent rule under a subsection title.** It is the clearest
   tell of an AI-generated deck. Use whitespace or a background panel.
3. **Accent colour is for emphasis only** — eyebrows, big numbers, significant
   values. Never a block of body text in accent.
4. **Page numbers are automatic**, never a literal `"3 / 18"` string.
5. **Every slide has Greek speaker notes** explaining purpose and usage.
6. **Every figure has a caption with a source. Every chart has an
   interpretation panel.** A chart alone is not an argument.

The full set, with the reasoning and the pptxgenjs traps behind each one, is in
`references/design-system.md`.

## Reference files

| File | Read it when |
|---|---|
| `references/layouts.md` | Choosing layouts, or you need a layout's exact API and constraints |
| `references/design-system.md` | Palettes, typography, the 11 design principles, pptxgenjs pitfalls |
| `references/qa-checklist.md` | Before shipping — automated + visual + cross-platform checks |
| `assets/deck-lib.js` | The implementation; read it when you need an option the docs don't name |

## Files

```
assets/
  deck-lib.js         the library — createDeck() + 18 layout methods
  build-template.js   regenerates the 18-slide reference template
  qa-check.js         automated QA over a built .pptx
  package.json        pptxgenjs dependency
templates/
  template-teal.pptx      prebuilt reference deck, Lean Corporate palette
  template-burgundy.pptx  prebuilt reference deck, Warm Academic palette
```
