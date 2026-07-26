#!/usr/bin/env node
/**
 * qa-check.js — automated QA for decks built with the engineering deck template.
 *
 *   node qa-check.js my-deck.pptx
 *   node qa-check.js my-deck.pptx --json
 *
 * Unzips the .pptx and inspects the raw OOXML. Checks the rules from
 * references/qa-checklist.md that can be verified without rendering:
 *
 *   1. slide count
 *   2. Greek speaker notes on every slide
 *   3. footer rule present on every slide
 *   4. automatic slide-number field present (never a hard-coded "3 / 18")
 *   5. no leftover placeholder text (lorem / TODO / [insert / xxxx)
 *   6. safe margin — no shape crosses the 0.5 in boundary
 *   7. font inventory — only the head font + the label font should appear
 *   8. colors are bare 6-digit hex
 *
 * Exit code 0 = all checks passed, 1 = at least one FAIL.
 * Visual checks (overflow, clipping, balance) still need a rendered pass —
 * see references/qa-checklist.md section "Visual checks".
 *
 * Requires jszip, which ships as a dependency of pptxgenjs.
 */

"use strict";

const fs = require("fs");
const path = require("path");
const JSZip = require("jszip");

const EMU_PER_INCH = 914400;
const SLIDE_W = 10 * EMU_PER_INCH;
const SLIDE_H = 5.625 * EMU_PER_INCH;
const MARGIN = 0.5 * EMU_PER_INCH;
const FOOTER_Y = 5.25 * EMU_PER_INCH;
const TOLERANCE = 0.02 * EMU_PER_INCH; // ~0.5 mm of rounding slack
// The eyebrow band sits at y=0.35 by design — it is the one element the
// template allows above the 0.5 in margin, so the top check starts there.
const TOP_LIMIT = 0.35 * EMU_PER_INCH;
// Content must clear the footer rule. 5.1 in is the ideal floor; 5.25 is hard.
const CONTENT_FLOOR = FOOTER_Y;

const PLACEHOLDER_RE = /lorem|ipsum|\bTODO\b|xxxx|\[insert/i;
const HARDCODED_PAGENO_RE = />\s*\d{1,2}\s*\/\s*\d{1,2}\s*</;

function parseArgs(argv) {
  const args = { file: null, json: false, quiet: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--json") args.json = true;
    else if (a === "--quiet" || a === "-q") args.quiet = true;
    else if (a === "--help" || a === "-h") {
      console.log("Usage: node qa-check.js <deck.pptx> [--json] [--quiet]");
      process.exit(0);
    } else if (!args.file) args.file = a;
    else throw new Error(`Unexpected argument: ${a}`);
  }
  if (!args.file) throw new Error("Missing argument: path to a .pptx file");
  return args;
}

/** Collect every <a:off>/<a:ext> pair inside <a:xfrm> blocks. */
function extractGeometry(xml) {
  const boxes = [];
  const xfrmRe = /<a:xfrm[^>]*>([\s\S]*?)<\/a:xfrm>/g;
  let m;
  while ((m = xfrmRe.exec(xml)) !== null) {
    const inner = m[1];
    const off = /<a:off x="(-?\d+)" y="(-?\d+)"\/>/.exec(inner);
    const ext = /<a:ext cx="(\d+)" cy="(\d+)"\/>/.exec(inner);
    if (off && ext) {
      boxes.push({
        x: +off[1],
        y: +off[2],
        w: +ext[1],
        h: +ext[2],
      });
    }
  }
  return boxes;
}

/** Strip tags and return the visible text of a slide part. */
function visibleText(xml) {
  const out = [];
  const re = /<a:t>([\s\S]*?)<\/a:t>/g;
  let m;
  while ((m = re.exec(xml)) !== null) out.push(m[1]);
  return out.join(" ");
}

async function run() {
  const args = parseArgs(process.argv);
  const buf = fs.readFileSync(args.file);
  const zip = await JSZip.loadAsync(buf);

  const slideNames = Object.keys(zip.files)
    .filter((n) => /^ppt\/slides\/slide\d+\.xml$/.test(n))
    .sort((a, b) => {
      const na = +a.match(/slide(\d+)\.xml/)[1];
      const nb = +b.match(/slide(\d+)\.xml/)[1];
      return na - nb;
    });

  const findings = [];
  const fonts = new Set();
  let notesCount = 0;
  let footerCount = 0;
  let slideNumCount = 0;

  const add = (level, slide, message) => findings.push({ level, slide, message });

  for (const name of slideNames) {
    const idx = +name.match(/slide(\d+)\.xml/)[1];
    const xml = await zip.file(name).async("string");

    // --- fonts -----------------------------------------------------------
    const fontRe = /typeface="([^"]+)"/g;
    let fm;
    while ((fm = fontRe.exec(xml)) !== null) fonts.add(fm[1]);

    // --- placeholder leftovers -------------------------------------------
    const text = visibleText(xml);
    if (PLACEHOLDER_RE.test(text)) {
      add("FAIL", idx, `leftover placeholder text: ${PLACEHOLDER_RE.exec(text)[0]}`);
    }

    // --- hard-coded page numbers -----------------------------------------
    if (HARDCODED_PAGENO_RE.test(xml)) {
      add("FAIL", idx, 'hard-coded page number ("n / m") — use slide.slideNumber instead');
    }

    // --- automatic slide-number field ------------------------------------
    if (/<a:fld[^>]+type="slidenum"/.test(xml)) slideNumCount++;
    else add("FAIL", idx, "no automatic slide-number field (slide.slideNumber missing)");

    // --- footer rule ------------------------------------------------------
    const boxes = extractGeometry(xml);
    const hasFooterRule = boxes.some(
      (b) => Math.abs(b.y - FOOTER_Y) < 0.05 * EMU_PER_INCH && b.w > 5 * EMU_PER_INCH
    );
    if (hasFooterRule) footerCount++;
    else add("FAIL", idx, "footer rule missing at y = 5.25 in");

    // --- safe margin ------------------------------------------------------
    boxes.forEach((b) => {
      // The <p:spTree> carries its own 0x0 transform — not a real element.
      if (b.w === 0 && b.h === 0) return;
      const full = b.w >= SLIDE_W - TOLERANCE && b.h >= SLIDE_H - TOLERANCE;
      if (full) return; // full-bleed background is allowed
      const left = b.x;
      const top = b.y;
      const right = b.x + b.w;
      const bottom = b.y + b.h;
      const isFooterElement = top >= FOOTER_Y - 0.05 * EMU_PER_INCH;
      if (left < MARGIN - TOLERANCE) {
        add("WARN", idx, `element starts at x=${(left / EMU_PER_INCH).toFixed(2)}" (< 0.5" margin)`);
      }
      if (right > SLIDE_W - MARGIN + TOLERANCE) {
        add(
          "WARN",
          idx,
          `element ends at x=${(right / EMU_PER_INCH).toFixed(2)}" (> 9.5" margin)`
        );
      }
      if (top < TOP_LIMIT - TOLERANCE) {
        add("WARN", idx, `element starts at y=${(top / EMU_PER_INCH).toFixed(2)}" (above the 0.35" eyebrow band)`);
      }
      if (!isFooterElement && bottom > CONTENT_FLOOR + TOLERANCE) {
        add(
          "WARN",
          idx,
          `element ends at y=${(bottom / EMU_PER_INCH).toFixed(2)}" (crosses the footer rule at 5.25")`
        );
      }
    });

    // --- speaker notes ----------------------------------------------------
    const notesName = `ppt/notesSlides/notesSlide${idx}.xml`;
    const notesFile = zip.file(notesName);
    if (notesFile) {
      const notesXml = await notesFile.async("string");
      const notesText = visibleText(notesXml);
      if (/ΠΡΟΟΡΙΣΜΟΣ/.test(notesText)) notesCount++;
      else if (notesText.trim().length > 0) {
        notesCount++;
        add("WARN", idx, "speaker notes present but not in the ΠΡΟΟΡΙΣΜΟΣ/ΠΟΤΕ format");
      } else {
        add("FAIL", idx, "speaker notes are empty");
      }
    } else {
      add("FAIL", idx, "no speaker notes");
    }
  }

  // --- deck-wide colour check ---------------------------------------------
  for (const name of slideNames) {
    const xml = await zip.file(name).async("string");
    const badColor = /srgbClr val="#/.exec(xml);
    if (badColor) {
      add("FAIL", +name.match(/slide(\d+)\.xml/)[1], 'color written with a "#" prefix');
    }
  }

  const summary = {
    file: path.resolve(args.file),
    slides: slideNames.length,
    withNotes: notesCount,
    withFooter: footerCount,
    withAutoSlideNumber: slideNumCount,
    fonts: [...fonts].sort(),
    fails: findings.filter((f) => f.level === "FAIL").length,
    warnings: findings.filter((f) => f.level === "WARN").length,
    findings,
  };

  if (args.json) {
    console.log(JSON.stringify(summary, null, 2));
  } else if (!args.quiet) {
    console.log(`QA report — ${path.basename(summary.file)}`);
    console.log(`  slides:                ${summary.slides}`);
    console.log(`  with Greek notes:      ${summary.withNotes}/${summary.slides}`);
    console.log(`  with footer rule:      ${summary.withFooter}/${summary.slides}`);
    console.log(`  with auto slide no.:   ${summary.withAutoSlideNumber}/${summary.slides}`);
    console.log(`  fonts used:            ${summary.fonts.join(", ") || "(none)"}`);
    if (summary.fonts.length > 2) {
      console.log("    ! more than two typefaces — the template allows only head + label font");
    }
    console.log("");
    if (!findings.length) {
      console.log("  No issues found. Run the visual checks before shipping.");
    } else {
      for (const f of findings) {
        console.log(`  [${f.level}] slide ${f.slide}: ${f.message}`);
      }
      console.log("");
      console.log(`  ${summary.fails} failure(s), ${summary.warnings} warning(s)`);
    }
  }

  process.exit(summary.fails > 0 ? 1 : 0);
}

run().catch((err) => {
  console.error("qa-check failed:", err.message);
  process.exit(2);
});
