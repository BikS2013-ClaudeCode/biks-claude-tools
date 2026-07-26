/**
 * deck-lib.js — Academic & Training presentation template
 *
 * A pptxgenjs wrapper implementing the 18 canonical layouts of the
 * Academic & Training template in two palettes (Warm Academic / Lean Corporate).
 *
 * Usage:
 *   const { createDeck } = require("./deck-lib");
 *   const deck = createDeck({ palette: "teal", title: "My talk", author: "Me" });
 *   deck.cover({ title: "...", subtitle: "...", author: "...", date: "..." });
 *   deck.qa({ contact: ["Name", "me@example.com"] });
 *   await deck.save("out.pptx");
 *
 * Design rules enforced by this library (see references/design-system.md):
 *   - Canvas is LAYOUT_16x9 (10 x 5.625 in); 0.5 in safe margin.
 *   - Bare hex colors, never "#"-prefixed.
 *   - Fresh option objects per shape — pptxgenjs mutates them in place.
 *   - margin: 0 + valign: "top" on every multi-line text box.
 *   - Automatic slide numbers via slide.slideNumber — never hard-coded.
 *   - Every slide gets a footer rule at y=5.25.
 *   - bullet: true, never literal "•" characters.
 */

"use strict";

const pptxgen = require("pptxgenjs");

/* ------------------------------------------------------------------ *
 * Palettes
 * ------------------------------------------------------------------ */

const PALETTES = {
  // Palette A — Warm Academic. Scholarly / editorial / humanities.
  burgundy: {
    ink: "1A1A1A",
    paper: "FFFFFF",
    cream: "F5EFE5",
    accent: "8B2635",
    accentDark: "6B1D2A",
    callout: "F5EFE5",
    muted: "8B8680",
    line: "D8D3CB",
    chartA: "8B2635",
    chartB: "C97B5A",
    chartC: "E0C097",
  },
  // Palette B — Lean Corporate. Tech / strategy / LeanPresentationStyle-adjacent.
  teal: {
    ink: "1A1A2E",
    paper: "FFFFFF",
    cream: "F0F8F9",
    accent: "007B85",
    accentDark: "005F67",
    callout: "E8F5F6",
    muted: "555555",
    line: "CCE4E6",
    chartA: "007B85",
    chartB: "005F67",
    chartC: "00454B",
  },
};

/* ------------------------------------------------------------------ *
 * Geometry — every coordinate in inches, canvas 10 x 5.625
 * ------------------------------------------------------------------ */

const G = {
  margin: 0.5,
  contentW: 9.0,
  contentTop: 1.7,
  contentBottom: 5.1,
  footerY: 5.25,
  footerTextY: 5.3,
};

/* ------------------------------------------------------------------ *
 * Speaker-note helper — Greek, per the template convention
 * ------------------------------------------------------------------ */

/**
 * Build a Greek speaker note in the canonical format.
 * @param {string} purpose - one sentence: what this layout is for
 * @param {string[]} tips  - 1-3 presenter tips
 */
function NOTE(purpose, tips = []) {
  let out = `ΠΡΟΟΡΙΣΜΟΣ: ${purpose}`;
  if (tips.length) {
    out += `\n\nΠΟΤΕ ΝΑ ΤΟ ΧΡΗΣΙΜΟΠΟΙΗΣΕΙΣ:\n` + tips.map((t) => `• ${t}`).join("\n");
  }
  return out;
}

/* ------------------------------------------------------------------ *
 * Deck factory
 * ------------------------------------------------------------------ */

/**
 * @param {object} opts
 * @param {"burgundy"|"teal"|object} [opts.palette="teal"] palette name or custom token object
 * @param {string} [opts.title]
 * @param {string} [opts.author]
 * @param {string} [opts.subject]
 * @param {string} [opts.headFont="Inter"]  heading/body font
 * @param {string} [opts.labelFont="Calibri"] letter-spaced label font (eyebrow + footer only)
 */
function createDeck(opts = {}) {
  const paletteName = opts.palette || "teal";
  const C =
    typeof paletteName === "object"
      ? paletteName
      : PALETTES[paletteName] ||
        (() => {
          throw new Error(
            `Unknown palette "${paletteName}". Use "burgundy", "teal", or a token object.`
          );
        })();

  const HEAD = opts.headFont || "Inter";
  const LABEL = opts.labelFont || "Calibri";

  const pres = new pptxgen();
  pres.layout = "LAYOUT_16x9";
  if (opts.title) pres.title = opts.title;
  if (opts.author) pres.author = opts.author;
  if (opts.subject) pres.subject = opts.subject;

  /* --------------------------- primitives --------------------------- */

  function newSlide(bg) {
    const s = pres.addSlide();
    s.background = { color: bg || C.paper };
    return s;
  }

  /** Footer rule + optional section label + auto-updating slide number. */
  function addFooter(slide, sectionLabel = "") {
    slide.addShape(pres.shapes.LINE, {
      x: 0.5,
      y: G.footerY,
      w: 9.0,
      h: 0,
      line: { color: C.line, width: 0.5 },
    });
    if (sectionLabel) {
      slide.addText(String(sectionLabel).toUpperCase(), {
        x: 0.5,
        y: G.footerTextY,
        w: 6,
        h: 0.25,
        fontFace: LABEL,
        fontSize: 9,
        color: C.muted,
        charSpacing: 2,
        margin: 0,
        valign: "top",
      });
    }
    // Auto slide number — survives insert / remove / reorder.
    slide.slideNumber = {
      x: 8.5,
      y: G.footerTextY,
      w: 1.0,
      h: 0.25,
      fontFace: HEAD,
      fontSize: 9,
      color: C.muted,
      align: "right",
    };
  }

  /** Eyebrow (ALL CAPS, tracked) + slide title. */
  function addSlideTitle(slide, title, eyebrow = "") {
    if (eyebrow) {
      slide.addText(String(eyebrow).toUpperCase(), {
        x: 0.5,
        y: 0.35,
        w: 9,
        h: 0.25,
        fontFace: LABEL,
        fontSize: 9,
        color: C.accent,
        bold: true,
        charSpacing: 3,
        margin: 0,
        valign: "top",
      });
    }
    if (title) {
      slide.addText(title, {
        x: 0.5,
        y: eyebrow ? 0.65 : 0.5,
        w: 9,
        h: 0.7,
        fontFace: HEAD,
        fontSize: 28,
        color: C.ink,
        margin: 0,
        valign: "top",
      });
    }
  }

  /** Short accent rule — the only decorative element the template allows. */
  function accentRule(slide, x, y, w = 0.5, h = 0.04) {
    slide.addShape(pres.shapes.RECTANGLE, {
      x,
      y,
      w,
      h,
      fill: { color: C.accent },
      line: { color: C.accent, width: 0 },
    });
  }

  /** Finish a slide: notes + footer. Every layout ends here. */
  function finish(slide, o) {
    if (o && o.notes) slide.addNotes(o.notes);
    addFooter(slide, (o && o.section) || "");
    return slide;
  }

  /* ----------------------------- layouts ---------------------------- */

  const deck = {
    pres,
    palette: C,
    fonts: { head: HEAD, label: LABEL },
    NOTE,

    /** Escape hatch: raw slide with the standard footer applied. */
    custom(o = {}) {
      const s = newSlide(o.background);
      if (o.title || o.eyebrow) addSlideTitle(s, o.title, o.eyebrow);
      if (typeof o.build === "function") o.build(s, { pres, C, HEAD, LABEL, accentRule });
      return finish(s, o);
    },

    /** Layout 01 — Cover / Title. Title <= 8 words. */
    cover(o = {}) {
      const s = newSlide();
      s.addText(String(o.eyebrow || "PRESENTATION").toUpperCase(), {
        x: 0.5,
        y: 0.5,
        w: 6,
        h: 0.3,
        fontFace: LABEL,
        fontSize: 10,
        color: C.accent,
        bold: true,
        charSpacing: 4,
        margin: 0,
        valign: "top",
      });
      accentRule(s, 0.5, 2.0);
      s.addText(o.title || "The Title of Your Presentation", {
        x: 0.5,
        y: 2.15,
        w: 9,
        h: 1.2,
        fontFace: HEAD,
        fontSize: 44,
        color: C.ink,
        margin: 0,
        valign: "top",
      });
      if (o.subtitle) {
        s.addText(o.subtitle, {
          x: 0.5,
          y: 3.35,
          w: 9,
          h: 0.5,
          fontFace: HEAD,
          fontSize: 16,
          color: C.muted,
          italic: true,
          margin: 0,
          valign: "top",
        });
      }
      if (o.author || o.affiliation) {
        const runs = [];
        if (o.author)
          runs.push({
            text: o.author,
            options: { bold: true, color: C.ink, breakLine: true },
          });
        if (o.affiliation) runs.push({ text: o.affiliation, options: { color: C.muted } });
        s.addText(runs, {
          x: 0.5,
          y: 4.65,
          w: 5,
          h: 0.55, // 0.55 not 0.7 — 0.7 would push the box past the footer rule at 5.25
          fontFace: HEAD,
          fontSize: 12,
          margin: 0,
          valign: "top",
        });
      }
      if (o.date) {
        s.addText(o.date, {
          x: 6,
          y: 4.65,
          w: 3.5,
          h: 0.3,
          fontFace: HEAD,
          fontSize: 11,
          color: C.muted,
          align: "right",
          margin: 0,
          valign: "top",
        });
      }
      return finish(s, o);
    },

    /**
     * Layout 02 — How-to-Use instructions (cream background, bilingual).
     * Meta-slide. Delete before shipping a real deck.
     */
    howToUse(o = {}) {
      const s = newSlide(C.cream);
      addSlideTitle(s, o.title || "Πώς να χρησιμοποιήσεις αυτό το template", o.eyebrow || "ΟΔΗΓΙΕΣ ΧΡΗΣΗΣ");
      const rules = o.rules || [
        "Ένα μήνυμα ανά slide.",
        "Κράτα τα 0.5\" περιθώρια — τίποτα δεν τα περνάει.",
        "Το accent χρώμα μόνο για έμφαση, ποτέ για σώμα κειμένου.",
        "Κάθε slide έχει ένα οπτικό στοιχείο.",
      ];
      const tokens = o.tokens || [
        ["Accent", C.accent],
        ["Ink", C.ink],
        ["Cream", C.cream],
        ["Muted", C.muted],
      ];
      s.addText(o.leftHeading || "Βασικοί κανόνες", {
        x: 0.5,
        y: 1.7,
        w: 4.3,
        h: 0.35,
        fontFace: HEAD,
        fontSize: 18,
        color: C.accent,
        bold: true,
        margin: 0,
        valign: "top",
      });
      s.addText(
        rules.map((t) => ({ text: t, options: { bullet: true, breakLine: true } })),
        {
          x: 0.5,
          y: 2.15,
          w: 4.3,
          h: 2.6,
          fontFace: HEAD,
          fontSize: 13,
          color: C.ink,
          lineSpacingMultiple: 1.3,
          margin: 0,
          valign: "top",
        }
      );
      s.addText(o.rightHeading || "Design tokens", {
        x: 5.2,
        y: 1.7,
        w: 4.3,
        h: 0.35,
        fontFace: HEAD,
        fontSize: 18,
        color: C.accent,
        bold: true,
        margin: 0,
        valign: "top",
      });
      const runs = [];
      tokens.forEach(([label, value], i) => {
        runs.push({ text: `${label}  `, options: { bold: true, color: C.ink } });
        runs.push({
          text: value,
          options: { color: C.muted, breakLine: i < tokens.length - 1 },
        });
      });
      s.addText(runs, {
        x: 5.2,
        y: 2.15,
        w: 4.3,
        h: 2.6,
        fontFace: HEAD,
        fontSize: 13,
        lineSpacingMultiple: 1.4,
        margin: 0,
        valign: "top",
      });
      return finish(s, o);
    },

    /**
     * Layout 03 — Agenda / Table of contents.
     * @param {Array<[string,string,string]>} o.items - [number, title, subtitle]
     */
    agenda(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title || "Agenda", o.eyebrow || "OVERVIEW");
      const items = o.items || [];
      items.forEach(([num, title, sub], i) => {
        const y = 1.7 + i * 0.62;
        s.addText(num, {
          x: 0.5,
          y,
          w: 0.8,
          h: 0.45,
          fontFace: HEAD,
          fontSize: 22,
          color: C.accent,
          bold: true,
          margin: 0,
          valign: "top",
        });
        s.addText(title, {
          x: 1.5,
          y,
          w: 7.5,
          h: 0.3,
          fontFace: HEAD,
          fontSize: 14,
          color: C.ink,
          bold: true,
          margin: 0,
          valign: "top",
        });
        if (sub) {
          s.addText(sub, {
            x: 1.5,
            y: y + 0.28,
            w: 7.5,
            h: 0.25,
            fontFace: HEAD,
            fontSize: 11,
            color: C.muted,
            italic: true,
            margin: 0,
            valign: "top",
          });
        }
        if (i < items.length - 1) {
          s.addShape(pres.shapes.LINE, {
            x: 1.5,
            y: y + 0.58,
            w: 7.5,
            h: 0,
            line: { color: C.line, width: 0.5 },
          });
        }
      });
      return finish(s, o);
    },

    /** Layout 04 — Section divider. Increment `number` on every divider. */
    sectionDivider(o = {}) {
      const s = newSlide(C.cream);
      s.addText(o.number || "01", {
        x: 0.5,
        y: 1.3,
        w: 3.5,
        h: 3.0,
        fontFace: HEAD,
        fontSize: 160,
        color: C.accent,
        margin: 0,
        valign: "middle",
      });
      s.addShape(pres.shapes.LINE, {
        x: 3.8,
        y: 1.8,
        w: 0,
        h: 2.0,
        line: { color: C.accent, width: 1 },
      });
      s.addText(String(o.label || "SECTION").toUpperCase(), {
        x: 4.1,
        y: 2.0,
        w: 5.4,
        h: 0.25,
        fontFace: LABEL,
        fontSize: 10,
        color: C.accent,
        bold: true,
        charSpacing: 4,
        margin: 0,
        valign: "top",
      });
      s.addText(o.title || "Section title", {
        x: 4.1,
        y: 2.3,
        w: 5.4,
        h: 1.0,
        fontFace: HEAD,
        fontSize: 32,
        color: C.ink,
        margin: 0,
        valign: "top",
      });
      if (o.subtitle) {
        s.addText(o.subtitle, {
          x: 4.1,
          y: 3.2,
          w: 5.4,
          h: 0.6,
          fontFace: HEAD,
          fontSize: 14,
          color: C.muted,
          italic: true,
          margin: 0,
          valign: "top",
        });
      }
      return finish(s, o);
    },

    /**
     * Layout 05 — Content with hierarchy + side callout.
     * @param {Array<string|{text:string,sub?:string[]}>} o.bullets - max 3 main bullets
     * @param {{label?:string, text:string}} o.callout - the single key insight
     */
    contentCallout(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      const runs = [];
      (o.bullets || []).forEach((b) => {
        const main = typeof b === "string" ? b : b.text;
        runs.push({
          text: main,
          options: { bullet: true, bold: true, color: C.ink, breakLine: true },
        });
        const subs = (typeof b === "object" && b.sub) || [];
        subs.forEach((sub) => {
          runs.push({
            text: sub,
            options: { bullet: true, indentLevel: 1, color: C.muted, bold: false, breakLine: true },
          });
        });
      });
      s.addText(runs, {
        x: 0.5,
        y: 1.7,
        w: 5.8,
        h: 3.2,
        fontFace: HEAD,
        fontSize: 13,
        lineSpacingMultiple: 1.35,
        margin: 0,
        valign: "top",
      });
      if (o.callout) {
        s.addShape(pres.shapes.RECTANGLE, {
          x: 6.7,
          y: 1.7,
          w: 2.8,
          h: 3.0,
          fill: { color: C.callout },
          line: { color: C.callout, width: 0 },
        });
        s.addShape(pres.shapes.RECTANGLE, {
          x: 6.7,
          y: 1.7,
          w: 0.04,
          h: 3.0,
          fill: { color: C.accent },
          line: { color: C.accent, width: 0 },
        });
        s.addText(String(o.callout.label || "KEY INSIGHT").toUpperCase(), {
          x: 6.95,
          y: 1.95,
          w: 2.4,
          h: 0.25,
          fontFace: LABEL,
          fontSize: 9,
          color: C.accent,
          bold: true,
          charSpacing: 3,
          margin: 0,
          valign: "top",
        });
        s.addText(o.callout.text || "", {
          x: 6.95,
          y: 2.3,
          w: 2.4,
          h: 2.2,
          fontFace: HEAD,
          fontSize: 15,
          color: C.ink,
          italic: true,
          lineSpacingMultiple: 1.25,
          margin: 0,
          valign: "top",
        });
      }
      return finish(s, o);
    },

    /**
     * Layout 06 — Two-column text. Match column lengths.
     * @param {{heading:string, body:string}} o.left
     * @param {{heading:string, body:string}} o.right
     */
    twoColumn(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      [
        [o.left || {}, 0.5],
        [o.right || {}, 5.2],
      ].forEach(([col, x]) => {
        if (col.heading) {
          s.addText(col.heading, {
            x,
            y: 1.7,
            w: 4.3,
            h: 0.4,
            fontFace: HEAD,
            fontSize: 18,
            color: C.accent,
            bold: true,
            margin: 0,
            valign: "top",
          });
        }
        if (col.body) {
          s.addText(col.body, {
            x,
            y: 2.2,
            w: 4.3,
            h: 2.6,
            fontFace: HEAD,
            fontSize: 13,
            color: C.ink,
            lineSpacingMultiple: 1.35,
            margin: 0,
            valign: "top",
          });
        }
        if (col.bullets && col.bullets.length) {
          s.addText(
            col.bullets.map((t) => ({ text: t, options: { bullet: true, breakLine: true } })),
            {
              x,
              y: col.body ? 3.4 : 2.2,
              w: 4.3,
              h: 1.5,
              fontFace: HEAD,
              fontSize: 12,
              color: C.ink,
              lineSpacingMultiple: 1.3,
              margin: 0,
              valign: "top",
            }
          );
        }
      });
      return finish(s, o);
    },

    /**
     * Layout 07 — Image + text (50/50). Every figure needs a caption with a source.
     * @param {string} [o.image] - path to an image; omitted => placeholder box
     */
    imageText(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      if (o.heading) {
        s.addText(o.heading, {
          x: 0.5,
          y: 1.7,
          w: 4.5,
          h: 0.4,
          fontFace: HEAD,
          fontSize: 18,
          color: C.accent,
          bold: true,
          margin: 0,
          valign: "top",
        });
      }
      if (o.body) {
        s.addText(o.body, {
          x: 0.5,
          y: o.heading ? 2.2 : 1.7,
          w: 4.5,
          h: 1.1,
          fontFace: HEAD,
          fontSize: 13,
          color: C.ink,
          lineSpacingMultiple: 1.3,
          margin: 0,
          valign: "top",
        });
      }
      if (o.bullets && o.bullets.length) {
        s.addText(
          o.bullets.map((t) => ({ text: t, options: { bullet: true, breakLine: true } })),
          {
            x: 0.5,
            y: 3.3,
            w: 4.5,
            h: 1.6,
            fontFace: HEAD,
            fontSize: 12,
            color: C.ink,
            lineSpacingMultiple: 1.3,
            margin: 0,
            valign: "top",
          }
        );
      }
      if (o.image) {
        s.addImage({ path: o.image, x: 5.3, y: 1.7, w: 4.2, h: 3.0, sizing: { type: "contain", w: 4.2, h: 3.0 } });
      } else {
        s.addShape(pres.shapes.RECTANGLE, {
          x: 5.3,
          y: 1.7,
          w: 4.2,
          h: 3.0,
          fill: { color: C.cream },
          line: { color: C.line, width: 0.75 },
        });
        s.addText(o.placeholder || "Figure / diagram", {
          x: 5.3,
          y: 3.0,
          w: 4.2,
          h: 0.4,
          fontFace: HEAD,
          fontSize: 12,
          color: C.muted,
          align: "center",
          italic: true,
          margin: 0,
          valign: "top",
        });
      }
      s.addText(o.caption || "Figure 1. Short caption. Source: Author, Year.", {
        x: 5.3,
        y: 4.78,
        w: 4.2,
        h: 0.3,
        fontFace: HEAD,
        fontSize: 9,
        color: C.muted,
        italic: true,
        margin: 0,
        valign: "top",
      });
      return finish(s, o);
    },

    /**
     * Layout 08 — Three-pillar framework grid. Exactly 3 MECE concepts.
     * @param {Array<{num?:string,title:string,body:string}>} o.pillars
     */
    threePillars(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      const pillars = (o.pillars || []).slice(0, 3);
      // 2.86 not 2.9 — three 2.9" columns with two 0.2" gaps end at 9.6",
      // overflowing the right margin. (9.0 - 2*0.2) / 3 = 2.866.
      const colW = 2.86;
      const gap = 0.2;
      const startX = 0.5;
      const topY = 1.8;
      pillars.forEach((c, i) => {
        const x = startX + i * (colW + gap);
        s.addShape(pres.shapes.OVAL, {
          x,
          y: topY,
          w: 0.7,
          h: 0.7,
          fill: { color: C.cream },
          line: { color: C.accent, width: 1 },
        });
        s.addText(c.num || String(i + 1).padStart(2, "0"), {
          x,
          y: topY,
          w: 0.7,
          h: 0.7,
          fontFace: HEAD,
          fontSize: 14,
          color: C.accent,
          bold: true,
          align: "center",
          valign: "middle",
          margin: 0,
        });
        s.addText(c.title, {
          x,
          y: topY + 0.9,
          w: colW,
          h: 0.45,
          fontFace: HEAD,
          fontSize: 16,
          color: C.ink,
          bold: true,
          margin: 0,
          valign: "top",
        });
        s.addText(c.body, {
          x,
          y: topY + 1.4,
          w: colW,
          h: 1.9,
          fontFace: HEAD,
          fontSize: 12,
          color: C.ink,
          lineSpacingMultiple: 1.3,
          margin: 0,
          valign: "top",
        });
      });
      return finish(s, o);
    },

    /** Layout 09 — Big stat callout. Round numbers only; always cite N and time frame. */
    bigStat(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      s.addText(o.stat || "87%", {
        x: 0.5,
        y: 1.9,
        w: 5,
        h: 2.2,
        fontFace: HEAD,
        fontSize: 144,
        color: C.accent,
        margin: 0,
        valign: "middle",
      });
      s.addShape(pres.shapes.LINE, {
        x: 5.5,
        y: 2.2,
        w: 0,
        h: 1.6,
        line: { color: C.line, width: 0.75 },
      });
      if (o.label) {
        s.addText(o.label, {
          x: 5.8,
          y: 2.2,
          w: 3.7,
          h: 0.6,
          fontFace: HEAD,
          fontSize: 18,
          color: C.ink,
          bold: true,
          lineSpacingMultiple: 1.2,
          margin: 0,
          valign: "top",
        });
      }
      if (o.body) {
        s.addText(o.body, {
          x: 5.8,
          y: 2.9,
          w: 3.7,
          h: 1.0,
          fontFace: HEAD,
          fontSize: 12,
          color: C.muted,
          lineSpacingMultiple: 1.3,
          margin: 0,
          valign: "top",
        });
      }
      if (o.source) {
        s.addText(o.source, {
          x: 5.8,
          y: 4.0,
          w: 3.7,
          h: 0.3,
          fontFace: HEAD,
          fontSize: 9,
          color: C.muted,
          italic: true,
          margin: 0,
          valign: "top",
        });
      }
      return finish(s, o);
    },

    /**
     * Layout 10 — Before / After comparison. Same bullet count on both sides.
     * @param {{label?:string,title:string,bullets:string[]}} o.before
     * @param {{label?:string,title:string,bullets:string[]}} o.after
     */
    beforeAfter(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      const cards = [
        { data: o.before || {}, x: 0.5, fill: C.cream, border: C.line, bw: 0.5, defLabel: "BEFORE" },
        { data: o.after || {}, x: 5.2, fill: C.paper, border: C.accent, bw: 1, defLabel: "AFTER" },
      ];
      cards.forEach((card) => {
        s.addShape(pres.shapes.RECTANGLE, {
          x: card.x,
          y: 1.7,
          w: 4.3,
          h: 3.2,
          fill: { color: card.fill },
          line: { color: card.border, width: card.bw },
        });
        s.addText(String(card.data.label || card.defLabel).toUpperCase(), {
          x: card.x + 0.3,
          y: 1.95,
          w: 3.7,
          h: 0.25,
          fontFace: LABEL,
          fontSize: 9,
          color: C.accent,
          bold: true,
          charSpacing: 3,
          margin: 0,
          valign: "top",
        });
        s.addText(card.data.title || "", {
          x: card.x + 0.3,
          y: 2.25,
          w: 3.7,
          h: 0.5,
          fontFace: HEAD,
          fontSize: 18,
          color: C.ink,
          bold: true,
          margin: 0,
          valign: "top",
        });
        s.addText(
          (card.data.bullets || []).map((t) => ({
            text: t,
            options: { bullet: true, breakLine: true },
          })),
          {
            x: card.x + 0.3,
            y: 2.85,
            w: 3.7,
            h: 1.85,
            fontFace: HEAD,
            fontSize: 12,
            color: C.ink,
            lineSpacingMultiple: 1.3,
            margin: 0,
            valign: "top",
          }
        );
      });
      return finish(s, o);
    },

    /** Layout 11 — Pull quote. <= 30 words, one per deck. */
    pullQuote(o = {}) {
      const s = newSlide(C.cream);
      s.addText('"', {
        x: 0.5,
        y: 0.8,
        w: 1.2,
        h: 1.5,
        fontFace: HEAD,
        fontSize: 180,
        color: C.accent,
        bold: true,
        margin: 0,
        valign: "middle",
      });
      s.addText(o.quote || "", {
        x: 1.2,
        y: 1.7,
        w: 8,
        h: 2.1,
        fontFace: HEAD,
        fontSize: 24,
        color: C.ink,
        italic: true,
        lineSpacingMultiple: 1.3,
        margin: 0,
        valign: "top",
      });
      s.addShape(pres.shapes.RECTANGLE, {
        x: 1.2,
        y: 4.0,
        w: 0.4,
        h: 0.02,
        fill: { color: C.accent },
        line: { color: C.accent, width: 0 },
      });
      const runs = [];
      if (o.author)
        runs.push({ text: o.author, options: { bold: true, color: C.ink, breakLine: true } });
      if (o.source) runs.push({ text: o.source, options: { italic: true, color: C.muted } });
      if (runs.length) {
        s.addText(runs, {
          x: 1.2,
          y: 4.25,
          w: 8,
          h: 0.7,
          fontFace: HEAD,
          fontSize: 12,
          margin: 0,
          valign: "top",
        });
      }
      return finish(s, o);
    },

    /**
     * Layout 12 — Chart + interpretation. Never ship a chart without the right panel.
     * @param {string[]} o.labels
     * @param {number[]} o.values
     * @param {string} [o.seriesName]
     * @param {"bar"|"line"|"pie"} [o.type="bar"]
     */
    chart(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      const type =
        o.type === "line" ? pres.charts.LINE : o.type === "pie" ? pres.charts.PIE : pres.charts.BAR;
      const data = [
        {
          name: o.seriesName || "Series 1",
          labels: o.labels || [],
          values: o.values || [],
        },
      ];
      s.addChart(type, data, {
        x: 0.5,
        y: 1.7,
        w: 5.8,
        h: 3.2,
        barDir: "col",
        chartColors: o.type === "pie" ? [C.chartA, C.chartB, C.chartC] : [C.chartA],
        chartArea: { fill: { color: C.paper }, roundedCorners: false },
        catAxisLabelColor: C.muted,
        catAxisLabelFontFace: LABEL,
        catAxisLabelFontSize: 10,
        valAxisLabelColor: C.muted,
        valAxisLabelFontFace: LABEL,
        valAxisLabelFontSize: 10,
        valGridLine: { color: C.line, size: 0.5 },
        catGridLine: { style: "none" },
        showValue: true,
        dataLabelPosition: o.type === "pie" ? "bestFit" : "outEnd",
        dataLabelColor: C.ink,
        dataLabelFontFace: LABEL,
        dataLabelFontSize: 10,
        showLegend: false,
      });
      s.addText(String(o.panelLabel || "WHAT THIS SHOWS").toUpperCase(), {
        x: 6.7,
        y: 1.75,
        w: 2.8,
        h: 0.25,
        fontFace: LABEL,
        fontSize: 9,
        color: C.accent,
        bold: true,
        charSpacing: 3,
        margin: 0,
        valign: "top",
      });
      s.addText(o.interpretation || "", {
        x: 6.7,
        y: 2.1,
        w: 2.8,
        h: 2.2,
        fontFace: HEAD,
        fontSize: 12,
        color: C.ink,
        lineSpacingMultiple: 1.3,
        margin: 0,
        valign: "top",
      });
      if (o.source) {
        s.addText(o.source, {
          x: 6.7,
          y: 4.5,
          w: 2.8,
          h: 0.4,
          fontFace: HEAD,
          fontSize: 9,
          color: C.muted,
          italic: true,
          margin: 0,
          valign: "top",
        });
      }
      return finish(s, o);
    },

    /**
     * Layout 13 — Process / timeline, 3-5 steps. Step titles are 1-word verbs.
     * @param {Array<{title:string, body?:string}>} o.steps
     */
    timeline(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      const steps = (o.steps || []).slice(0, 5);
      const n = steps.length || 1;
      const circleD = 0.8;
      const y = 2.3;
      const usableW = 9.0;
      const slotW = usableW / n;
      const centers = steps.map((_, i) => 0.5 + slotW * i + slotW / 2);
      if (n > 1) {
        s.addShape(pres.shapes.LINE, {
          x: centers[0],
          y: y + circleD / 2,
          w: centers[n - 1] - centers[0],
          h: 0,
          line: { color: C.line, width: 1 },
        });
      }
      steps.forEach((step, i) => {
        const cx = centers[i];
        s.addShape(pres.shapes.OVAL, {
          x: cx - circleD / 2,
          y,
          w: circleD,
          h: circleD,
          fill: { color: C.accent },
          line: { color: C.accent, width: 0 },
        });
        s.addText(String(i + 1), {
          x: cx - circleD / 2,
          y,
          w: circleD,
          h: circleD,
          fontFace: HEAD,
          fontSize: 22,
          color: C.paper,
          bold: true,
          align: "center",
          valign: "middle",
          margin: 0,
        });
        s.addText(step.title, {
          x: cx - slotW / 2,
          y: y + circleD + 0.2,
          w: slotW,
          h: 0.35,
          fontFace: HEAD,
          fontSize: 16,
          color: C.ink,
          bold: true,
          align: "center",
          margin: 0,
          valign: "top",
        });
        if (step.body) {
          s.addText(step.body, {
            x: cx - slotW / 2 + 0.1,
            y: y + circleD + 0.6,
            w: slotW - 0.2,
            h: 0.8,
            fontFace: HEAD,
            fontSize: 11,
            color: C.muted,
            align: "center",
            lineSpacingMultiple: 1.2,
            margin: 0,
            valign: "top",
          });
        }
      });
      return finish(s, o);
    },

    /**
     * Layout 14 — Results table. Accent in a table means statistical significance.
     * @param {string[]} o.headers
     * @param {Array<Array<string|{text:string,significant?:boolean,muted?:boolean}>>} o.rows
     */
    table(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title, o.eyebrow);
      const headers = o.headers || [];
      const rows = o.rows || [];
      const body = [];
      body.push(
        headers.map((h) => ({
          text: h,
          options: {
            fill: { color: C.ink },
            color: C.paper,
            bold: true,
            fontFace: LABEL,
            fontSize: 12,
            valign: "middle",
            margin: 0.06,
          },
        }))
      );
      rows.forEach((row) => {
        body.push(
          row.map((cell) => {
            const isObj = typeof cell === "object" && cell !== null;
            const text = isObj ? cell.text : String(cell);
            return {
              text,
              options: {
                color: isObj && cell.significant ? C.accent : isObj && cell.muted ? C.muted : C.ink,
                bold: !!(isObj && cell.significant),
                fontFace: HEAD,
                fontSize: 11,
                valign: "middle",
                margin: 0.06,
              },
            };
          })
        );
      });
      s.addTable(body, {
        x: 0.5,
        y: 1.8,
        w: 9.0,
        rowH: 0.42,
        border: { type: "solid", color: C.line, pt: 0.5 },
        autoPage: false,
      });
      if (o.source) {
        s.addText(o.source, {
          x: 0.5,
          y: 4.75,
          w: 9,
          h: 0.3,
          fontFace: HEAD,
          fontSize: 9,
          color: C.muted,
          italic: true,
          margin: 0,
          valign: "top",
        });
      }
      return finish(s, o);
    },

    /**
     * Layout 15 — Key takeaways. Exactly 3; the third must be actionable.
     * @param {Array<{title:string, body?:string}>} o.items
     */
    takeaways(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title || "Key takeaways", o.eyebrow || "SUMMARY");
      const items = (o.items || []).slice(0, 3);
      items.forEach((it, i) => {
        const y = 1.85 + i * 1.05;
        s.addText(String(i + 1).padStart(2, "0"), {
          x: 0.5,
          y,
          w: 1.0,
          h: 0.6,
          fontFace: HEAD,
          fontSize: 32,
          color: C.accent,
          margin: 0,
          valign: "top",
        });
        s.addText(it.title, {
          x: 1.6,
          y: y + 0.02,
          w: 7.9,
          h: 0.35,
          fontFace: HEAD,
          fontSize: 16,
          color: C.ink,
          bold: true,
          margin: 0,
          valign: "top",
        });
        if (it.body) {
          s.addText(it.body, {
            x: 1.6,
            y: y + 0.4,
            w: 7.9,
            h: 0.45,
            fontFace: HEAD,
            fontSize: 12,
            color: C.muted,
            lineSpacingMultiple: 1.2,
            margin: 0,
            valign: "top",
          });
        }
        if (i < items.length - 1) {
          s.addShape(pres.shapes.LINE, {
            x: 1.6,
            y: y + 0.92,
            w: 7.9,
            h: 0,
            line: { color: C.line, width: 0.5 },
          });
        }
      });
      return finish(s, o);
    },

    /**
     * Layout 16 — References (APA 7). Max 4 entries per slide.
     * @param {Array<string|Array<{text:string,italic?:boolean}>>} o.entries
     */
    references(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title || "References", o.eyebrow || "BIBLIOGRAPHY");
      const runs = [];
      (o.entries || []).slice(0, 4).forEach((entry, i, arr) => {
        if (typeof entry === "string") {
          runs.push({ text: entry, options: { breakLine: i < arr.length - 1 } });
        } else {
          entry.forEach((part, j) => {
            runs.push({
              text: part.text,
              options: {
                italic: !!part.italic,
                breakLine: j === entry.length - 1 && i < arr.length - 1,
              },
            });
          });
        }
      });
      s.addText(runs, {
        x: 0.5,
        y: 1.7,
        w: 9,
        h: 3.3,
        fontFace: HEAD,
        fontSize: 12,
        color: C.ink,
        lineSpacingMultiple: 1.6,
        margin: 0,
        valign: "top",
      });
      return finish(s, o);
    },

    /** Layout 17 — Q&A / Thank you. Always include contact info. */
    qa(o = {}) {
      const s = newSlide(C.cream);
      s.addText(o.headline || "Q&A", {
        x: 0.5,
        y: 1.3,
        w: 9,
        h: 1.5,
        fontFace: HEAD,
        fontSize: 120,
        color: C.accent,
        align: "center",
        margin: 0,
        valign: "middle",
      });
      s.addText(o.thanks || "Thank you.", {
        x: 0.5,
        y: 3.0,
        w: 9,
        h: 0.5,
        fontFace: HEAD,
        fontSize: 18,
        color: C.ink,
        italic: true,
        align: "center",
        margin: 0,
        valign: "top",
      });
      s.addShape(pres.shapes.RECTANGLE, {
        x: 4.75,
        y: 3.65,
        w: 0.5,
        h: 0.04,
        fill: { color: C.accent },
        line: { color: C.accent, width: 0 },
      });
      const contact = o.contact || [];
      if (contact.length) {
        const runs = contact.map((line, i) => ({
          text: line,
          options: {
            bold: i === 0,
            color: i === 0 ? C.ink : C.muted,
            breakLine: i < contact.length - 1,
          },
        }));
        s.addText(runs, {
          x: 0.5,
          y: 3.85,
          w: 9,
          h: 1.0,
          fontFace: HEAD,
          fontSize: 12,
          align: "center",
          lineSpacingMultiple: 1.3,
          margin: 0,
          valign: "top",
        });
      }
      return finish(s, o);
    },

    /** Layout 18 — Appendix: design tokens. Internal reference sheet. */
    designTokens(o = {}) {
      const s = newSlide();
      addSlideTitle(s, o.title || "Design tokens", o.eyebrow || "APPENDIX");
      const swatches = o.swatches || [
        ["Ink", C.ink],
        ["Paper", C.paper],
        ["Cream", C.cream],
        ["Accent", C.accent],
        ["Accent dark", C.accentDark],
        ["Muted", C.muted],
        ["Line", C.line],
      ];
      s.addText(o.leftHeading || "Χρώματα", {
        x: 0.5,
        y: 1.7,
        w: 4.3,
        h: 0.35,
        fontFace: HEAD,
        fontSize: 16,
        color: C.accent,
        bold: true,
        margin: 0,
        valign: "top",
      });
      swatches.forEach(([label, hex], i) => {
        const y = 2.15 + i * 0.38;
        s.addShape(pres.shapes.RECTANGLE, {
          x: 0.5,
          y,
          w: 0.35,
          h: 0.3,
          fill: { color: hex },
          line: { color: C.line, width: 0.75 },
        });
        s.addText(label, {
          x: 1.0,
          y,
          w: 2.0,
          h: 0.3,
          fontFace: HEAD,
          fontSize: 11,
          color: C.ink,
          bold: true,
          margin: 0,
          valign: "middle",
        });
        s.addText(hex, {
          x: 3.0,
          y,
          w: 1.8,
          h: 0.3,
          fontFace: HEAD,
          fontSize: 11,
          color: C.muted,
          margin: 0,
          valign: "middle",
        });
      });
      s.addText(o.rightHeading || "Τυπογραφία", {
        x: 5.2,
        y: 1.7,
        w: 4.3,
        h: 0.35,
        fontFace: HEAD,
        fontSize: 16,
        color: C.accent,
        bold: true,
        margin: 0,
        valign: "top",
      });
      const typo = o.typography || [
        ["Cover title", `${HEAD} 44 pt`],
        ["Slide title", `${HEAD} 28 pt`],
        ["Section number", `${HEAD} 160 pt`],
        ["Body", `${HEAD} 12–14 pt`],
        ["Eyebrow / footer", `${LABEL} 9–10 pt, +3 tracking`],
      ];
      const typoRuns = [];
      typo.forEach(([label, desc], i) => {
        typoRuns.push({ text: `${label}  `, options: { bold: true, color: C.ink } });
        typoRuns.push({
          text: desc,
          options: { color: C.muted, breakLine: i < typo.length - 1 },
        });
      });
      s.addText(typoRuns, {
        x: 5.2,
        y: 2.15,
        w: 4.3,
        h: 2.4,
        fontFace: HEAD,
        fontSize: 11,
        lineSpacingMultiple: 1.5,
        margin: 0,
        valign: "top",
      });
      s.addText(o.spacingNote || '0.5" margins · 0.3–0.5" gaps between blocks · Ratio 16:9', {
        x: 0.5,
        y: 4.8,
        w: 9,
        h: 0.3,
        fontFace: LABEL,
        fontSize: 10,
        color: C.muted,
        italic: true,
        align: "center",
        margin: 0,
        valign: "top",
      });
      return finish(s, o);
    },

    /**
     * Write the file. Returns the resolved filename.
     *
     * By default the .pptx is post-processed so category axis labels survive
     * the trip through Google Slides — see flattenChartCategories(). Pass
     * { googleSlidesFix: false } to write pptxgenjs's raw output instead.
     */
    async save(fileName, saveOpts = {}) {
      const applyFix = saveOpts.googleSlidesFix !== false;
      if (!applyFix) {
        await pres.writeFile({ fileName });
        return fileName;
      }
      const buf = await pres.write({ outputType: "nodebuffer" });
      const fixed = await flattenChartCategories(buf);
      require("fs").writeFileSync(fileName, fixed);
      return fileName;
    },
  };

  return deck;
}

/* ------------------------------------------------------------------ *
 * Google Slides compatibility
 * ------------------------------------------------------------------ */

/**
 * Rewrite <c:multiLvlStrRef> category references as plain <c:strRef>.
 *
 * pptxgenjs always emits chart categories as a multi-level string reference.
 * PowerPoint reads that correctly, but Google Slides ignores it and falls back
 * to numbering the categories 1, 2, 3... — silently destroying the axis labels.
 * Since this template targets both, we flatten single-level category caches on
 * write. Multi-level caches (more than one <c:lvl>) are left untouched.
 *
 * @param {Buffer} pptxBuffer raw .pptx bytes
 * @returns {Promise<Buffer>} patched .pptx bytes
 */
async function flattenChartCategories(pptxBuffer) {
  const JSZip = require("jszip");
  const zip = await JSZip.loadAsync(pptxBuffer);
  const chartNames = Object.keys(zip.files).filter((n) =>
    /^ppt\/charts\/chart\d+\.xml$/.test(n)
  );
  if (!chartNames.length) return pptxBuffer;

  for (const name of chartNames) {
    let xml = await zip.file(name).async("string");
    xml = xml.replace(
      /<c:multiLvlStrRef>([\s\S]*?)<\/c:multiLvlStrRef>/g,
      (whole, inner) => {
        const levels = inner.match(/<c:lvl>/g) || [];
        if (levels.length !== 1) return whole; // genuinely multi-level — leave it
        const f = /<c:f>([\s\S]*?)<\/c:f>/.exec(inner);
        const ptCount = /<c:ptCount val="(\d+)"\s*\/>/.exec(inner);
        const lvl = /<c:lvl>([\s\S]*?)<\/c:lvl>/.exec(inner);
        if (!f || !ptCount || !lvl) return whole;
        return (
          `<c:strRef><c:f>${f[1]}</c:f><c:strCache>` +
          `<c:ptCount val="${ptCount[1]}"/>${lvl[1]}` +
          `</c:strCache></c:strRef>`
        );
      }
    );
    zip.file(name, xml);
  }

  return zip.generateAsync({
    type: "nodebuffer",
    compression: "DEFLATE",
    compressionOptions: { level: 6 },
  });
}

module.exports = { createDeck, PALETTES, NOTE, G, flattenChartCategories };
