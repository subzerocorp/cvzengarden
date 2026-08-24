/**
 * ZG-12 probes: long names fit Nightgarden's rail, below-fold sections are
 * painted before they scroll into view (with or without scroll-driven
 * animation support), and `\n` inside a highlight renders as a line break in
 * every theme.
 *
 * Every browser probe opens `/sandbox.html` as the top-level page via
 * `openResumePage` — the Garden iframe is an internal scroller, so a page
 * screenshot never contains its scrolled-out content. "Nothing animates"
 * oracles are scoped to `.rz-section` (the name sheen and the foxfire entry
 * animate forever on Nightgarden and are outside every assertion).
 *
 * Parametrised by a `sheetSource` (live or `git show <base>`) like ZG-11.
 */
import { openResumePage, useSheetText } from "./lib/page.mjs";
import { parseRgb } from "./lib/contrast.mjs";
import { describeRiseStructure, riseStructureReasons, withoutViewSupports } from "./lib/css-structure.mjs";
import { CHANNEL_THRESHOLD, countDifferingPixels } from "./lib/pixels.mjs";
import { sheetSuffix } from "./lib/sheet-source.mjs";

export const ZG12_THEMES = ["nightgarden", "quarto", "switchyard"];
const RISE_THEME = "nightgarden";
const LONG_NAME = "Marcus Okafor-Lindqvist Jr.";
const NAME_VIEWPORTS = [
  { width: 1280, height: 800 },
  { width: 390, height: 844 },
];
const RISE_VIEWPORT = { width: 1280, height: 800 };
const BELOW_FOLD_SECTIONS = ["rz-volunteer", "rz-projects"];
const PAINT_SECTION = "rz-projects";
const MIN_PAINTED_PIXELS = 200;
const MULTI_LINE_BULLET = "Store:\n- Postgres\n- moved tables";
const SINGLE_LINE_BULLET = "One line";
const MIN_MULTI_TO_SINGLE_HEIGHT = 2.5;

// ---------------------------------------------------------------- calculations

function fmt(n) {
  return Number.isInteger(n) ? String(n) : n.toFixed(1);
}

function fitsReasons(boxes) {
  return Object.entries(boxes)
    .filter(([, box]) => box.scrollWidth > box.clientWidth)
    .map(([selector, box]) => `${selector} scrollWidth ${fmt(box.scrollWidth)} > clientWidth ${fmt(box.clientWidth)}`);
}

function describeBoxes(boxes) {
  return Object.entries(boxes)
    .map(([selector, box]) => `${selector} ${fmt(box.scrollWidth)}/${fmt(box.clientWidth)}px`)
    .join(" ");
}

function opacityReasons(opacities) {
  return Object.entries(opacities)
    .filter(([, opacity]) => opacity !== "1")
    .map(([id, opacity]) => `#${id} opacity ${opacity}`);
}

function animationReasons(names) {
  return names.length ? [`.rz-section animations running: ${names.join(", ")}`] : [];
}

function foldReasons(tops, foldPx) {
  return Object.entries(tops)
    .filter(([, top]) => !(top > foldPx))
    .map(([id, top]) => `#${id} top ${fmt(top)}px is not below the ${foldPx}px fold (probe mis-set-up)`);
}

function preLineReasons(heights) {
  return heights.multi >= MIN_MULTI_TO_SINGLE_HEIGHT * heights.single
    ? []
    : [`multi-line bullet ${fmt(heights.multi)}px < ${MIN_MULTI_TO_SINGLE_HEIGHT} × single-line ${fmt(heights.single)}px`];
}

function report(ctx, line, reasons, detail) {
  reasons.length ? ctx.fail(`${line}: ${reasons.join("; ")}`) : ctx.pass(`${line} ${detail}`);
}

// --------------------------------------------------------------------- actions

async function applySheet(page, theme, sheetSource) {
  if (sheetSource.label !== null) {
    await useSheetText(page, sheetSource.cssFor(theme));
  }
}

async function openThemePage(ctx, theme, viewport) {
  const page = await openResumePage(ctx.browser, { origin: ctx.origin, theme, ...viewport });
  await applySheet(page, theme, ctx.sheetSource);
  return page;
}

function readNameBoxes(page) {
  return page.evaluate((text) => {
    const name = document.querySelector(".rz-name");
    name.textContent = text;
    const box = (el) => ({ scrollWidth: el.scrollWidth, clientWidth: el.clientWidth });
    return { ".rz-name": box(name), ".rz-identity": box(document.querySelector(".rz-identity")) };
  }, LONG_NAME);
}

function readSectionOpacities(page, ids) {
  return page.evaluate(
    (sectionIds) => Object.fromEntries(sectionIds.map((id) => [id, getComputedStyle(document.getElementById(id)).opacity])),
    ids,
  );
}

function readAllSectionOpacities(page) {
  return page.evaluate(() =>
    Object.fromEntries([...document.querySelectorAll(".rz-section")].map((section) => [section.id, getComputedStyle(section).opacity])),
  );
}

// The sections-scoped oracle the PBI names: never `document.getAnimations()`.
function readSectionAnimations(page) {
  return page.evaluate(() =>
    [...document.querySelectorAll(".rz-section")].flatMap((section) => section.getAnimations()).map((animation) => animation.animationName),
  );
}

function readSectionTops(page, ids) {
  return page.evaluate(
    (sectionIds) => Object.fromEntries(sectionIds.map((id) => [id, document.getElementById(id).getBoundingClientRect().top])),
    ids,
  );
}

function readSectionDocumentBox(page, id) {
  return page.evaluate((sectionId) => {
    const rect = document.getElementById(sectionId).getBoundingClientRect();
    return {
      x: Math.round(rect.left + window.scrollX),
      y: Math.round(rect.top + window.scrollY),
      width: Math.round(rect.width),
      height: Math.round(rect.height),
      bodyBackground: getComputedStyle(document.body).backgroundColor,
    };
  }, id);
}

// Decodes a PNG in the page (createImageBitmap + canvas) and returns the RGBA
// bytes of `box` as base64; the counting is a Node-side calculation.
async function readBoxPixels(page, pngBuffer, box) {
  const base64 = await page.evaluate(
    async ({ png, x, y, width, height }) => {
      const blob = await (await fetch(`data:image/png;base64,${png}`)).blob();
      const bitmap = await createImageBitmap(blob);
      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      const context = canvas.getContext("2d");
      context.drawImage(bitmap, -x, -y);
      const bytes = context.getImageData(0, 0, width, height).data;
      let binary = "";
      for (let i = 0; i < bytes.length; i += 8192) {
        binary += String.fromCharCode(...bytes.subarray(i, i + 8192));
      }
      return btoa(binary);
    },
    { png: pngBuffer.toString("base64"), ...box },
  );
  return Buffer.from(base64, "base64");
}

function readBulletHeights(page) {
  return page.evaluate(
    ({ multi, single }) => {
      const first = document.querySelector(".rz-bullet");
      const second = first.nextElementSibling;
      first.textContent = multi;
      second.textContent = single;
      return { multi: first.clientHeight, single: second.clientHeight };
    },
    { multi: MULTI_LINE_BULLET, single: SINGLE_LINE_BULLET },
  );
}

// ---------------------------------------------------------------------- probes

async function nameFitsProbe(ctx) {
  for (const viewport of NAME_VIEWPORTS) {
    const page = await openThemePage(ctx, RISE_THEME, viewport);
    const boxes = await readNameBoxes(page);
    await page.close();
    report(ctx, `ZG-12/name-fits ${viewport.width}×${viewport.height}${ctx.suffix}`, fitsReasons(boxes), describeBoxes(boxes));
  }
}

function riseCssStructureProbe(ctx) {
  const css = ctx.sheetSource.cssFor(RISE_THEME);
  report(ctx, `ZG-12/rise-css-structure ${RISE_THEME}.css${ctx.suffix}`, riseStructureReasons(css), describeRiseStructure(css));
}

async function paintedWithoutSupportProbe(ctx) {
  const page = await openResumePage(ctx.browser, { origin: ctx.origin, theme: RISE_THEME, ...RISE_VIEWPORT });
  await useSheetText(page, withoutViewSupports(ctx.sheetSource.cssFor(RISE_THEME)));
  const opacities = await readSectionOpacities(page, BELOW_FOLD_SECTIONS);
  const animations = await readSectionAnimations(page);
  await page.close();
  const detail = `${BELOW_FOLD_SECTIONS.map((id) => `#${id} opacity ${opacities[id]}`).join(", ")}, 0 .rz-section animations`;
  report(ctx, `ZG-12/painted-without-support${ctx.suffix}`, [...opacityReasons(opacities), ...animationReasons(animations)], detail);
}

async function paintedWithSupportProbe(ctx) {
  const page = await openThemePage(ctx, RISE_THEME, RISE_VIEWPORT);
  const tops = await readSectionTops(page, BELOW_FOLD_SECTIONS);
  const opacities = await readSectionOpacities(page, BELOW_FOLD_SECTIONS);
  const box = await readSectionDocumentBox(page, PAINT_SECTION);
  const png = await page.screenshot({ fullPage: true });
  const painted = countDifferingPixels(await readBoxPixels(page, png, box), parseRgb(box.bodyBackground), CHANNEL_THRESHOLD);
  await page.close();
  const reasons = [
    ...foldReasons(tops, RISE_VIEWPORT.height),
    ...opacityReasons(opacities),
    ...(painted < MIN_PAINTED_PIXELS ? [`#${PAINT_SECTION} has ${painted} painted pixels, want >= ${MIN_PAINTED_PIXELS}`] : []),
  ];
  const detail = `${BELOW_FOLD_SECTIONS.map((id) => `#${id} top ${fmt(tops[id])}px opacity ${opacities[id]}`).join(", ")}; #${PAINT_SECTION} ${painted} pixels differ from ${box.bodyBackground} by > ${CHANNEL_THRESHOLD}`;
  report(ctx, `ZG-12/painted-with-support${ctx.suffix}`, reasons, detail);
}

async function reducedMotionProbe(ctx) {
  const page = await openThemePage(ctx, RISE_THEME, RISE_VIEWPORT);
  await page.emulateMedia({ reducedMotion: "reduce" });
  const animations = await readSectionAnimations(page);
  const opacities = await readAllSectionOpacities(page);
  await page.close();
  const detail = `${Object.keys(opacities).length} sections, 0 .rz-section animations, all opacity 1`;
  report(ctx, `ZG-12/reduced-motion${ctx.suffix}`, [...animationReasons(animations), ...opacityReasons(opacities)], detail);
}

async function preLineProbe(ctx) {
  for (const theme of ZG12_THEMES) {
    const page = await openThemePage(ctx, theme, RISE_VIEWPORT);
    const heights = await readBulletHeights(page);
    await page.close();
    const ratio = (heights.multi / heights.single).toFixed(1);
    report(ctx, `ZG-12/pre-line ${theme}${ctx.suffix}`, preLineReasons(heights), `multi ${fmt(heights.multi)}px vs single ${fmt(heights.single)}px (${ratio}×)`);
  }
}

/**
 * Runs the ZG-12 group. `report` is `{ pass, fail }`; `sheetSource` is
 * `liveSheets(...)` or `gitSheets(...)`.
 */
export async function zg12Probes({ browser, origin, report: reporter, sheetSource }) {
  const ctx = { browser, origin, sheetSource, pass: reporter.pass, fail: reporter.fail, suffix: sheetSuffix(sheetSource) };
  await nameFitsProbe(ctx);
  riseCssStructureProbe(ctx);
  await paintedWithoutSupportProbe(ctx);
  await paintedWithSupportProbe(ctx);
  await reducedMotionProbe(ctx);
  await preLineProbe(ctx);
}
