# QA checklist

Run all three passes before declaring a deck done.

## 1. Automated

```bash
node assets/qa-check.js my-deck.pptx
```

Exit code 0 = no failures. It unzips the .pptx and inspects the OOXML directly:

| Check | Level |
|---|---|
| Every slide has speaker notes, in the `ΠΡΟΟΡΙΣΜΟΣ` format | FAIL / WARN |
| Every slide has the footer rule at y 5.25 | FAIL |
| Every slide has an automatic slide-number field | FAIL |
| No hard-coded `"3 / 18"` page numbers | FAIL |
| No leftover placeholder text (`lorem`, `TODO`, `[insert`, `xxxx`) | FAIL |
| No `"#"`-prefixed colours | FAIL |
| No element crosses the 0.5 in margin or the footer rule | WARN |
| Font inventory (should be exactly two typefaces) | reported |

`--json` emits the full finding list for scripting. `--quiet` prints nothing and
just sets the exit code.

Warnings are worth reading rather than dismissing — margin warnings are how the
four coordinate bugs in the source spec were found.

## 2. Visual

Render the deck and look at every slide. Without LibreOffice installed, the
Google Slides round-trip below doubles as the renderer.

- [ ] No text overflow or clipping at slide edges
- [ ] No element crosses the 0.5 in safe margin
- [ ] Footer present on every slide
- [ ] Eyebrows are ALL CAPS and accent-coloured
- [ ] All text is Inter, except the eyebrow and footer label (Calibri)
- [ ] Bullet text sits at the top of its box, not vertically centred
      (centred text means a missing `valign: "top"`)
- [ ] No accent rules under subsection titles
- [ ] Every chart has its interpretation panel
- [ ] Every figure has a caption with a source
- [ ] Every slide has Greek speaker notes
- [ ] Exactly one pull quote, one big stat, three takeaways

With LibreOffice available:

```bash
soffice --headless --convert-to pdf my-deck.pptx
pdftoppm -jpeg -r 120 my-deck.pdf slide
```

## 3. Cross-platform

The template targets PowerPoint *and* Google Slides. Verify both.

Google Slides round-trip via the `gws` CLI — this both converts and renders:

```bash
# upload, converting to a native Google Slides file
gws drive files create \
  --upload ./my-deck.pptx \
  --upload-content-type "application/vnd.openxmlformats-officedocument.presentationml.presentation" \
  --json '{"name":"QA my-deck","mimeType":"application/vnd.google-apps.presentation"}'

# export the converted file back to PDF, then render pages
gws drive files export --params '{"fileId":"<ID>","mimeType":"application/pdf"}' -o qa.pdf
pdftoppm -jpeg -r 100 qa.pdf slide

# clean up when done
gws drive files delete --params '{"fileId":"<ID>"}'
```

Check specifically:

- [ ] Chart category labels show text, not `1, 2, 3, 4`
      (if numbered: `save()` ran with `googleSlidesFix: false`)
- [ ] Inter renders — in desktop PowerPoint it falls back unless installed
      locally; switch `headFont` to `"Segoe UI"` or `"Source Sans 3"` if that
      is a problem for the audience
- [ ] Slide numbers increment and update
- [ ] Cream backgrounds and table header fills survive the conversion
