/**
 * ZG-11 probes: a long résumé prints without blank pages, lost bullets, or
 * pale ink. Every probe runs on `/sandbox.html` opened as the top-level page
 * at the theme's printable width, in print emulation.
 *
 * The group is parametrised by a `sheetSource` so the same probes can run
 * against a historical sheet (`git show <base>:themes/<theme>.css`) for the
 * anti-vacuity evidence the PBI asks for. The runner owns reporting; this
 * module only calls the injected `pass` / `fail`.
 */
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { openResumePage, useSheetText } from "./lib/page.mjs";
import { countPdfPages, printToPdf } from "./lib/pdf.mjs";
import {
  paginate,
  printableHeightPx,
  printableWidthPx,
  readEntryHeaderMarks,
  splitEntries,
  tallBlocks,
} from "./lib/print-geometry.mjs";
import {
  INK_SELECTORS,
  bulletMarkerReasons,
  describeInk,
  describeMarker,
  inkReasons,
  readBulletMarker,
  readInkColors,
} from "./lib/print-ink.mjs";

export const ZG11_THEMES = ["quarto", "switchyard", "nightgarden"];
const BREAKING_THEMES = ["quarto", "switchyard"];
const WIDTH_TOLERANCE_PX = 2;
const MIN_PAGE1_FILL = 0.85;
const MAX_LONG_PAGES = 3;
// Screen-width viewport for the printToPDF page counts (paper size comes from @page).
const SCREEN_WIDTH_PX = 1280;
// Themes whose sheet is scanned statically for a forced break, and the section
// whose computed break-before is checked live. The PBI singles Switchyard out.
const FORCED_BREAK_SCAN = { switchyard: { sheet: "switchyard.css", sectionId: "rz-projects" } };
const FORCED_BREAK = /(?:break-before\s*:\s*page|page-break-before\s*:\s*always)\b/;

// Sheet sources: the working-tree file (loaded by href) or a git revision
// (injected in place of #theme-stylesheet).
export function liveSheets(repoDir) {
  return {
    label: null,
    cssFor: (theme) => fs.readFileSync(path.join(repoDir, "themes", `${theme}.css`), "utf8"),
  };
}

export function gitSheets(repoDir, revision) {
  return {
    label: revision,
    cssFor: (theme) => execFileSync("git", ["show", `${revision}:themes/${theme}.css`], { cwd: repoDir, encoding: "utf8" }),
  };
}

function stripComments(css) {
  return css.replace(/\/\*[\s\S]*?\*\//g, " ");
}

// Calculation: forced page breaks anywhere in a sheet, top level included.
export function forcedBreakReasons(css, sheetName) {
  return FORCED_BREAK.test(stripComments(css)) ? [`${sheetName} declares break-before: page / page-break-before: always`] : [];
}

function sectionBreakReasons(sections, theme) {
  const avoiding = sections.filter((section) => section.breakInside !== "auto");
  const scan = FORCED_BREAK_SCAN[theme];
  const watched = scan ? sections.find((section) => section.id === scan.sectionId) : undefined;
  return [
    ...avoiding.map((section) => `#${section.id} break-inside ${section.breakInside}`),
    ...(watched?.breakBefore === "page" ? [`#${scan.sectionId} break-before page`] : []),
  ];
}

function readSectionBreaks(page) {
  return page.evaluate(() =>
    [...document.querySelectorAll(".rz-section")].map((section) => {
      const style = getComputedStyle(section);
      return { id: section.id, breakInside: style.breakInside, breakBefore: style.breakBefore };
    }),
  );
}

function readArticleWidth(page) {
  return page.evaluate(() => document.querySelector("article.rz-resume").getBoundingClientRect().width);
}

function readExperienceHeight(page) {
  return page.evaluate(() => document.getElementById("rz-experience").getBoundingClientRect().height);
}

function fmt(n) {
  return Number.isInteger(n) ? String(n) : n.toFixed(1);
}

async function applySheet(page, theme, sheetSource) {
  if (sheetSource.label !== null) {
    await useSheetText(page, sheetSource.cssFor(theme));
  }
}

async function openPrintPage(ctx, theme, fixtureHtml) {
  const page = await openResumePage(ctx.browser, {
    origin: ctx.origin,
    theme,
    width: printableWidthPx(theme),
    fixtureHtml,
  });
  await applySheet(page, theme, ctx.sheetSource);
  await page.emulateMedia({ media: "print" });
  return page;
}

async function openThemePages(ctx) {
  const pages = {};
  for (const theme of ZG11_THEMES) {
    const page = await openPrintPage(ctx, theme, ctx.fixtureHtml);
    const width = await readArticleWidth(page);
    const want = printableWidthPx(theme);
    pages[theme] = { page, width, want, widthOk: Math.abs(width - want) <= WIDTH_TOLERANCE_PX };
  }
  return pages;
}

function widthGuard(ctx, slug, opened) {
  const bad = Object.values(opened).filter((entry) => !entry.widthOk);
  bad.forEach((entry) => ctx.fail(`ZG-11/${slug} article width ${fmt(entry.width)}px, want ${entry.want}px${ctx.suffix}`));
  return bad.length === 0;
}

function pick(opened, themes) {
  return Object.fromEntries(themes.map((theme) => [theme, opened[theme]]));
}

function articleWidthProbe(ctx, opened) {
  for (const theme of ZG11_THEMES) {
    const { width, want, widthOk } = opened[theme];
    const line = `ZG-11/article-width ${theme} ${fmt(width)}px (want ${want} ±${WIDTH_TOLERANCE_PX})${ctx.suffix}`;
    (widthOk ? ctx.pass : ctx.fail)(line);
  }
}

async function fixtureTripsE1Probe(ctx, opened) {
  if (!widthGuard(ctx, "fixture-trips-e1", pick(opened, BREAKING_THEMES))) {
    return;
  }
  const heights = await Promise.all(BREAKING_THEMES.map((theme) => readExperienceHeight(opened[theme].page)));
  const parts = BREAKING_THEMES.map((theme, i) => `${theme} #rz-experience ${fmt(heights[i])}px > ${printableHeightPx(theme)}`);
  const trips = BREAKING_THEMES.every((theme, i) => heights[i] > printableHeightPx(theme));
  (trips ? ctx.pass : ctx.fail)(`ZG-11/fixture-trips-e1 ${parts.join(", ")}${ctx.suffix}`);
}

async function page1FillProbe(ctx, opened) {
  if (!widthGuard(ctx, "page1-fill", pick(opened, BREAKING_THEMES))) {
    return;
  }
  for (const theme of BREAKING_THEMES) {
    const { fill } = await paginate(opened[theme].page, printableHeightPx(theme));
    const line = `ZG-11/page1-fill ${theme} ${fill.toFixed(2)}${ctx.suffix}`;
    (fill >= MIN_PAGE1_FILL ? ctx.pass : ctx.fail)(fill >= MIN_PAGE1_FILL ? line : `${line} (want >= ${MIN_PAGE1_FILL})`);
  }
}

async function entryIntactProbe(ctx, opened) {
  if (!widthGuard(ctx, "entry-intact", pick(opened, BREAKING_THEMES))) {
    return;
  }
  for (const theme of BREAKING_THEMES) {
    const height = printableHeightPx(theme);
    const { pages } = await paginate(opened[theme].page, height);
    const split = splitEntries(pages, await readEntryHeaderMarks(opened[theme].page));
    const tall = tallBlocks(pages, height).map((block) => `${block.label} ${fmt(block.bottom - block.top)}px`);
    const reasons = [
      ...split.map((entry) => `entry ${entry} header and dates on different pages`),
      ...tall.map((label) => `atomic block ${label} taller than ${height}px`),
    ];
    const line = `ZG-11/entry-intact ${theme} ${pages.length} simulated page(s)${ctx.suffix}`;
    reasons.length ? ctx.fail(`${line}: ${reasons.join("; ")}`) : ctx.pass(line);
  }
}

async function noForcedBreakProbe(ctx, opened) {
  for (const theme of ZG11_THEMES) {
    const sections = await readSectionBreaks(opened[theme].page);
    const scan = FORCED_BREAK_SCAN[theme];
    const staticReasons = scan ? forcedBreakReasons(ctx.sheetSource.cssFor(theme), scan.sheet) : [];
    const reasons = [...sectionBreakReasons(sections, theme), ...staticReasons];
    const line = `ZG-11/no-forced-break ${theme} ${sections.length} sections break-inside auto${ctx.suffix}`;
    reasons.length ? ctx.fail(`ZG-11/no-forced-break ${theme}${ctx.suffix}: ${reasons.join("; ")}`) : ctx.pass(line);
  }
}

async function bulletsPrintProbe(ctx, opened) {
  for (const theme of ZG11_THEMES) {
    const marker = await readBulletMarker(opened[theme].page);
    const reasons = bulletMarkerReasons(marker);
    const line = `ZG-11/bullets-print ${theme}${ctx.suffix}`;
    reasons.length ? ctx.fail(`${line}: ${reasons.join("; ")}`) : ctx.pass(`${line} ${describeMarker(marker)}`);
  }
}

async function printInkProbe(ctx, opened) {
  const colors = await readInkColors(opened.nightgarden.page, INK_SELECTORS);
  const reasons = inkReasons(colors);
  const line = `ZG-11/print-ink nightgarden${ctx.suffix}`;
  reasons.length ? ctx.fail(`${line}: ${reasons.join("; ")}`) : ctx.pass(`${line} ${describeInk(colors)}`);
}

async function countPages(ctx, theme, fixtureHtml) {
  const page = await openResumePage(ctx.browser, { origin: ctx.origin, theme, width: SCREEN_WIDTH_PX, fixtureHtml });
  await applySheet(page, theme, ctx.sheetSource);
  const count = countPdfPages(await printToPdf(page));
  await page.close();
  return count;
}

function pageCountReasons(theme, jordan, long, expected) {
  const wantJordan = expected.jordan[theme];
  const wantLong = expected.long[theme];
  return [
    ...(jordan !== wantJordan ? [`example.html is ${jordan} page(s), U3_PRINT_PAGES is ${wantJordan}`] : []),
    ...(wantLong === undefined ? [`LONG_PRINT_PAGES.${theme} is unset`] : []),
    ...(wantLong !== undefined && long !== wantLong ? [`long-resume.html is ${long} page(s), LONG_PRINT_PAGES is ${wantLong}`] : []),
    ...(long > MAX_LONG_PAGES ? [`long-resume.html is ${long} page(s), want <= ${MAX_LONG_PAGES}`] : []),
  ];
}

async function pageCountProbe(ctx) {
  for (const theme of ZG11_THEMES) {
    const jordan = await countPages(ctx, theme, undefined);
    const long = await countPages(ctx, theme, ctx.fixtureHtml);
    const reasons = pageCountReasons(theme, jordan, long, ctx.expectedPages);
    const line = `ZG-11/page-count ${theme} example.html ${jordan} page(s), long-resume.html ${long} page(s)${ctx.suffix}`;
    reasons.length ? ctx.fail(`${line}: ${reasons.join("; ")}`) : ctx.pass(line);
  }
}

/**
 * Runs the ZG-11 group.
 * `report` is `{ pass, fail }`; `expectedPages` is `{ jordan, long }` maps of
 * theme → page count; `sheetSource` is `liveSheets(...)` or `gitSheets(...)`.
 */
export async function zg11Probes({ browser, origin, report, fixtureHtml, expectedPages, sheetSource }) {
  const ctx = {
    browser,
    origin,
    fixtureHtml,
    expectedPages,
    sheetSource,
    pass: report.pass,
    fail: report.fail,
    suffix: sheetSource.label === null ? "" : ` [sheet ${sheetSource.label}]`,
  };
  const opened = await openThemePages(ctx);
  articleWidthProbe(ctx, opened);
  await fixtureTripsE1Probe(ctx, opened);
  await page1FillProbe(ctx, opened);
  await entryIntactProbe(ctx, opened);
  await noForcedBreakProbe(ctx, opened);
  await bulletsPrintProbe(ctx, opened);
  await printInkProbe(ctx, opened);
  await Promise.all(Object.values(opened).map((entry) => entry.page.close()));
  await pageCountProbe(ctx);
}
