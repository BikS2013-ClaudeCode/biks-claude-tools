# Design system

Tokens, typography, principles, and the pptxgenjs traps behind them.

## Canvas

| Property | Value |
|---|---|
| Layout | `LAYOUT_16x9` |
| Size | 10.0 × 5.625 in |
| Safe margin | 0.5 in on all sides |
| Content band | x 0.5–9.5, y 1.7–5.1 |
| Eyebrow line | y 0.35 |
| Footer rule | y 5.25 |

Nothing crosses the margin except full-bleed backgrounds on dividers, the pull
quote, and the Q&A slide.

**Why 10 × 5.625 and not 13.33 × 7.5?** The Google Slides API silently ignores
custom page sizes and always creates 10 in pages, which forces a scaling pass on
every coordinate in a 13.33 in design (that is what LeanPresentationStyle has to
do). Authoring at 10 in removes that entire class of bug: the same file renders
identically in PowerPoint and Google Slides.

---

## Palettes

Both palettes use the same token names. Selecting one is a single argument to
`createDeck({ palette })`; nothing else in a build script changes.

### A — Warm Editorial (`burgundy`)

| Token | Hex | |
|---|---|---|
| `ink` | `1A1A1A` | near-black — primary text |
| `paper` | `FFFFFF` | background |
| `cream` | `F5EFE5` | warm off-white — dividers, panels |
| `accent` | `8B2635` | burgundy — emphasis, rules, big numbers |
| `accentDark` | `6B1D2A` | secondary emphasis |
| `callout` | `F5EFE5` | callout panel fill |
| `muted` | `8B8680` | warm grey — captions, sub-bullets |
| `line` | `D8D3CB` | dividers, borders |
| `chartA/B/C` | `8B2635` / `C97B5A` / `E0C097` | burgundy, terracotta, sand |

Use for research-flavoured and editorial material: papers, formal evaluations,
academic-conference talks, long-form technical writing turned into slides.

### B — Lean Corporate (`teal`)

| Token | Hex | |
|---|---|---|
| `ink` | `1A1A2E` | dark navy — primary text |
| `paper` | `FFFFFF` | background |
| `cream` | `F0F8F9` | light teal — dividers, panels |
| `accent` | `007B85` | teal — emphasis, rules, big numbers |
| `accentDark` | `005F67` | secondary emphasis |
| `callout` | `E8F5F6` | callout panel fill |
| `muted` | `555555` | grey — captions, sub-bullets |
| `line` | `CCE4E6` | dividers, borders |
| `chartA/B/C` | `007B85` / `005F67` / `00454B` | teal ramp |

The default. Use for engineering, platform, product, and strategy decks —
design reviews, architecture walkthroughs, tech talks, postmortems — and
whenever the deck sits next to other LeanPresentationStyle work (same `007B85`
accent).

### Usage rules

| Token | Allowed uses |
|---|---|
| `ink` | Slide titles, card titles, body text |
| `accent` | Eyebrows, big numbers, short rules, significant values in tables |
| `accentDark` | A second accent when two shades must coexist |
| `muted` | Subtitles, captions, sources, sub-bullets, footer |
| `cream` | Full-slide background on dividers/quote/Q&A; the "before" card |
| `callout` | Callout panel fill |
| `line` | Dividers, table borders, placeholder outlines |
| `paper` | Slide background on content slides |

Never set body copy in `accent` — a paragraph of burgundy or teal reads as
amateur. Never mix the two palettes in one deck.

A custom palette is accepted: pass a token object instead of a name. Supply
every key listed above.

---

## Typography

| Role | Font | Size | Weight | Colour |
|---|---|---|---|---|
| Cover title | Inter | 44 | Regular | ink |
| Slide title | Inter | 28 | Regular | ink |
| Section number | Inter | 160 | Regular | accent |
| Big stat number | Inter | 144 | Regular | accent |
| Q&A headline | Inter | 120 | Regular | accent |
| Subsection header | Inter | 18 | Bold | accent |
| Pillar / card title | Inter | 16 | Bold | ink |
| Callout body | Inter | 15 | Italic | ink |
| Eyebrow / footer label | Calibri | 9–10 | Bold | accent / muted, `charSpacing` 2–4, ALL CAPS |
| Body | Inter | 12–14 | Regular | ink |
| Muted body | Inter | 11–13 | Regular/Italic | muted |
| Caption / source | Inter | 9 | Italic | muted |

**Two fonts, one job each.** Inter carries everything. Calibri appears *only*
in letter-spaced ALL-CAPS labels — the eyebrow and the footer label — because
its wider letterforms hold up under tracking. Never a third font. Never Calibri
outside those two roles. Never `charSpacing` above 1 on Inter; its geometry
does not tolerate tracking.

**Font availability.** Calibri ships with PowerPoint and Google Slides. Inter is
native in Google Slides (Google Fonts) but is *not* installed by default in
desktop PowerPoint — install it from [rsms.me/inter](https://rsms.me/inter), or
override at build time:

```javascript
createDeck({ palette: "teal", headFont: "Segoe UI" })   // or "Source Sans 3"
```

---

## The 12 principles

1. **One visual element per slide.** Every content slide carries at least one
   non-text element: chart, image, icon, panel, table, stat, rule.
2. **Never put an accent rule under a subsection title.** The single clearest
   tell of an AI-generated deck. Use whitespace or a background panel.
3. **Left-align body text.** Centring is reserved for cover titles, big stat
   numbers, the Q&A slide, timeline step labels, and badge text.
4. **Eyebrows are ALL CAPS with `charSpacing: 3`.** Never mixed case.
5. **`margin: 0` and `valign: "top"` on every text box** that is taller than
   its text. Without them pptxgenjs centres the text vertically and you get
   unexplained gaps.
6. **Never reuse an options object across two `addShape`/`addText` calls.**
   pptxgenjs mutates them in place. Build a fresh object, or a factory
   function, per call.
7. **Bare hex colours, never `"#"`-prefixed.** `"8B2635"`, not `"#8B2635"` —
   the prefix corrupts the file.
8. **`bullet: true`, never a literal `"•"`.** Literal bullets produce doubles.
9. **Every slide has a footer:** hairline at y 5.25, optional section label
   left, slide number right. No exceptions.
10. **Page numbers are automatic.** `slide.slideNumber` (or an
    `<a:fld type="slidenum">` field) evaluates at render time. A hard-coded
    `"3 / 18"` goes stale the moment a slide moves.
11. **Every slide has Greek speaker notes** covering purpose, when to use the
    layout, and 1–3 presenter tips.
12. **Every number carries its conditions, every claim its source.** A latency
    figure without the percentile and the load, a benchmark without the commit,
    a diagram without the ADR it came from — all decoration. In a technical
    room the conditions are the argument.

`deck-lib.js` enforces 4–10 structurally. 1, 2, 3, 11, and 12 are editorial —
they are yours to hold.

---

## Speaker notes

```
ΠΡΟΟΡΙΣΜΟΣ: [one sentence — what this layout is for]

ΠΟΤΕ ΝΑ ΤΟ ΧΡΗΣΙΜΟΠΟΙΗΣΕΙΣ:
• [tip 1]
• [tip 2]
```

Built by `NOTE(purpose, tips)`. The notes are pedagogical: whoever opens the
file next — a teammate re-presenting it, a future you six months on — learns the
system from the deck itself, without external docs. For an internal talk this is
also where the detail that did not fit on the slide belongs: the caveat, the
config, the link to the dashboard.

---

## Google Slides compatibility

`save()` post-processes the .pptx before writing. pptxgenjs always emits chart
categories as `<c:multiLvlStrRef>`. PowerPoint reads it; **Google Slides ignores
it and numbers the axis 1, 2, 3…**, silently destroying the category labels. The
library rewrites single-level category caches as plain `<c:strRef>`, which both
applications read.

Opt out with `deck.save("out.pptx", { googleSlidesFix: false })` if you are
targeting PowerPoint only and want pptxgenjs's raw output.

Verified round-trip: build → upload to Drive as a Google Slides file → export
PDF → all 18 layouts render correctly, Inter loads, slide numbers update.

---

## Deviations from the source guide

The layout system is derived from the Academic & Training presentation guide.
This implementation corrects four coordinate bugs in that spec, all of which
broke the 0.5 in safe margin the spec itself mandates:

| Layout | Source | Here | Why |
|---|---|---|---|
| Cover author block | `h: 0.7` at y 4.65 | `h: 0.55` | 4.65 + 0.7 = 5.35, past the footer rule at 5.25 |
| Section divider text | `w: 5.5` at x 4.1 | `w: 5.4` | 4.1 + 5.5 = 9.6, past the 9.5 margin |
| Three-pillar columns | `w: 2.9`, gap 0.2 | `w: 2.86` | 3 × 2.9 + 2 × 0.2 ends at 9.6 |
| Chart side panel | `w: 2.9` at x 6.7 | `w: 2.8` | 6.7 + 2.9 = 9.6 |

`qa-check.js` catches this class of error automatically — it is what surfaced
all four.
