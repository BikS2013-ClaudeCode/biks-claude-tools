---
name: engineering-deck
description: Build engineering and technical presentations as editable .pptx files — design reviews, architecture walkthroughs, tech talks, conference talks, RFC and ADR presentations, incident and postmortem reviews, benchmark and migration reports, engineering onboarding and technical training. Uses a fixed design system of 18 layouts in two palettes with a pptxgenjs layout library, a template generator, and an automated QA checker. Use whenever the user asks for a technical deck, an architecture or design-review presentation, a tech talk, a postmortem deck, an engineering training deck, or asks to rebuild an existing deck in this template.
---

# Engineering presentation template

A design system for talks that have to explain how something works: design
reviews, architecture walkthroughs, tech talks, postmortems, benchmark
write-ups, migration proposals, engineering onboarding. Output is a real
`.pptx` with editable native objects — no screenshots, no image-only slides.

The system is deliberately narrow. There are 18 layouts, two palettes, two
fonts, and a fixed grid. Every deck is a composition of those pieces. When
content does not fit a layout, the answer is to split the content, not to
invent a layout.

## What this is not

Not the LeanPresentationStyle (13.33″ python-pptx with Google Slides scaling
math) and not the Quiet Authority family. Those are separate systems. This one
uses a 10 × 5.625 in canvas so the same file renders identically in PowerPoint
and Google Slides with no scaling step.

## Build workflow

1. **Pick the palette.** `teal` for engineering, platform, and product decks —
   the default, and it matches other LeanPresentationStyle material.
   `burgundy` for research-flavoured or editorial material: papers, formal
   evaluations, academic-conference audiences. Never mix palettes in one deck.
2. **Map the brief to layouts.** Use the decision table in
   `references/layouts.md` §Selection. For a 20–25 minute talk start from the
   canonical structure there and cut, don't pad.
3. **Write the build script.** Require `assets/deck-lib.js` and call one
   method per slide. Do not hand-roll pptxgenjs calls — the library already
   encodes the grid, the colour rules, and the footer.
4. **Write Greek speaker notes for every slide** with the `NOTE(purpose, tips)`
   helper. This is not optional; the notes are how the next engineer picks the
   deck up and re-presents it.
5. **Run the QA.** `node assets/qa-check.js <deck>.pptx`. Exit code 0 or fix
   what it reports. Then do the visual pass in `references/qa-checklist.md`.

## Minimal example

```bash
cd <workdir> && npm install pptxgenjs
```

```javascript
const { createDeck, NOTE } = require("./deck-lib");

const deck = createDeck({ palette: "teal", title: "Retrieval design review", author: "Name" });

deck.cover({
  eyebrow: "DESIGN REVIEW",
  title: "Reworking the retrieval path",
  subtitle: "Why ranking, not generation, is the bottleneck",
  author: "Name", affiliation: "Platform Engineering", date: "July 2026",
  notes: NOTE("Εξώφυλλο.", ["Τίτλος έως 8 λέξεις."]),
});

deck.bigStat({
  eyebrow: "BASELINE", title: "Where the time goes", section: "Problem",
  stat: "62%", label: "of p95 latency is spent in re-ranking",
  body: "Measured across 40 production deployments over six weeks.",
  notes: NOTE("Ένα ποσοτικό εύρημα.", ["Στρογγυλοί αριθμοί μόνο."]),
});

deck.qa({ contact: ["Name", "name@org.gr"], notes: NOTE("Κλείσιμο.", []) });

deck.save("design-review.pptx").then((f) => console.log("Saved", f));
```

Every layout method takes `notes` (Greek speaker note) and `section` (footer
label). The footer rule, the section label, and the auto-updating slide number
are added for you.

## Regenerating the reference template

```bash
node assets/build-template.js --palette teal     -o template-teal.pptx
node assets/build-template.js --palette burgundy -o template-burgundy.pptx
```

Produces an 18-slide deck — one slide per layout, filled with engineering
placeholder content, Greek speaker notes throughout. Prebuilt copies are in
`templates/`. Use them as a visual index, or open one and overwrite slide by
slide when you would rather edit than script.

## The rules that matter most

These are the ones that separate a deck in this system from a generic one:

1. **One idea per slide.** Two ideas means two slides.
2. **Never put an accent rule under a subsection title.** It is the clearest
   tell of an AI-generated deck. Use whitespace or a background panel.
3. **Accent colour is for emphasis only** — eyebrows, big numbers, the one
   value in a table that carries the decision. Never a block of body text.
4. **Page numbers are automatic**, never a literal `"3 / 18"` string.
5. **Every slide has Greek speaker notes** explaining purpose and usage.
6. **Every diagram has a caption. Every chart has an interpretation panel.**
   A benchmark chart without the sentence saying what it means is not an
   argument — it is a picture.
7. **Numbers carry their conditions.** A latency figure without the
   percentile, the load, and the hardware is decoration.

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
  template-burgundy.pptx  prebuilt reference deck, Warm Editorial palette
```
