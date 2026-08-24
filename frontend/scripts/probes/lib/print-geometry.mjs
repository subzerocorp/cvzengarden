/**
 * ZG-11 geometry oracle: paper size per theme and a greedy paginator over
 * the atomic blocks of a print-emulated top-level résumé page.
 *
 * Why geometry instead of pixels: Playwright cannot rasterise a PDF and the
 * toolchain has no PNG decoder, so page fill is simulated from block
 * rectangles. The simulation is a stated approximation of Chromium's break
 * positions; the real page count is checked separately with printToPDF.
 *
 * Actions: `readAtomicBlocks`, `readEntryHeaderMarks`, `paginate`.
 * Everything else is a calculation over plain data.
 */

const PX_PER_INCH = 96;
const PX_PER_MM = 96 / 25.4;

// `@page` size and margins per theme, in the units each sheet declares.
// `firstTop` is the `@page :first` top margin where a sheet has one.
const PAGE_RULES = {
  quarto: { unit: "in", width: 8.5, height: 11, top: 0.55, right: 0.7, bottom: 0.6, left: 0.7, firstTop: 0.48 },
  switchyard: { unit: "mm", width: 210, height: 297, top: 14, right: 16, bottom: 16, left: 16 },
  nightgarden: { unit: "in", width: 8.5, height: 11, top: 0.36, right: 0.5, bottom: 0.28, left: 0.5 },
};

const LEAF_BLOCK_SELECTOR = ".rz-header, .rz-entry, .rz-prose p, .rz-skill-group, .rz-section-title";
const ATOMIC_BREAK_INSIDE = ["avoid", "avoid-page"];

function toPx(value, unit) {
  return Math.round(value * (unit === "mm" ? PX_PER_MM : PX_PER_INCH));
}

function pageRule(themeId) {
  const rule = PAGE_RULES[themeId];
  if (!rule) {
    throw new Error(`no @page geometry recorded for theme ${themeId}`);
  }
  return rule;
}

export function printableWidthPx(themeId) {
  const rule = pageRule(themeId);
  return toPx(rule.width - rule.left - rule.right, rule.unit);
}

// Page-1 printable height (uses the `:first` top margin when declared).
export function printableHeightPx(themeId) {
  const rule = pageRule(themeId);
  const top = rule.firstTop ?? rule.top;
  return toPx(rule.height - top - rule.bottom, rule.unit);
}

export function blockHeight(block) {
  return block.bottom - block.top;
}

function isTall(block, printableHeight) {
  return blockHeight(block) > printableHeight;
}

function fitsOnPage(page, block, printableHeight) {
  return page.length === 0 || block.bottom - page[0].top <= printableHeight;
}

// Greedy pagination: blocks fill a page in document order; a block that does
// not fit (or declares break-before: page) starts a new page; a block taller
// than the page sits alone on its own page.
export function paginateBlocks(blocks, printableHeight) {
  const pages = [];
  let current = [];
  const close = () => {
    if (current.length) {
      pages.push(current);
      current = [];
    }
  };
  for (const block of blocks) {
    if (block.forcedBefore || isTall(block, printableHeight) || !fitsOnPage(current, block, printableHeight)) {
      close();
    }
    current.push(block);
    if (isTall(block, printableHeight)) {
      close();
    }
  }
  close();
  return pages;
}

// (bottom of the last block on page 1 − top of the first) ÷ printable height,
// so a theme's top padding never leaks into the ratio.
export function page1Fill(pages, printableHeight) {
  const first = pages[0];
  if (!first || first.length === 0) {
    return 0;
  }
  return (first.at(-1).bottom - first[0].top) / printableHeight;
}

export function tallBlocks(pages, printableHeight) {
  return pages.flat().filter((block) => isTall(block, printableHeight));
}

// Index of the simulated page whose block span contains document y, or -1.
export function pageIndexOfY(pages, y) {
  return pages.findIndex((page) => page.some((block) => block.top <= y && y <= block.bottom));
}

// Action: the outermost break-inside:avoid elements, else the leaf block
// boxes, in document order, with document-relative edges.
export function readAtomicBlocks(page) {
  return page.evaluate(
    ({ leafSelector, atomicBreakInside }) => {
      const blocks = [];
      const edges = (el) => {
        const rect = el.getBoundingClientRect();
        return { top: rect.top + window.scrollY, bottom: rect.bottom + window.scrollY };
      };
      const label = (el) => (el.id ? `#${el.id}` : `.${[...el.classList].join(".")}`);
      const visit = (el, forcedBefore) => {
        const style = getComputedStyle(el);
        const forced = forcedBefore || style.breakBefore === "page";
        const atomic = atomicBreakInside.includes(style.breakInside);
        if (atomic || el.matches(leafSelector)) {
          blocks.push({ label: label(el), atomic, forcedBefore: forced, ...edges(el) });
          return;
        }
        [...el.children].forEach((child, index) => visit(child, index === 0 && forced));
      };
      [...document.querySelector("article.rz-resume").children].forEach((child) => visit(child, false));
      return blocks;
    },
    { leafSelector: LEAF_BLOCK_SELECTOR, atomicBreakInside: ATOMIC_BREAK_INSIDE },
  );
}

// Action: document-relative tops of every .rz-entry-header and its .rz-dates.
export function readEntryHeaderMarks(page) {
  return page.evaluate(() =>
    [...document.querySelectorAll(".rz-entry-header")].map((header) => {
      const dates = header.querySelector(".rz-dates");
      const y = (el) => el.getBoundingClientRect().top + window.scrollY;
      return {
        entry: header.closest(".rz-entry")?.getAttribute("data-rz-entry") || "",
        headerY: y(header),
        datesY: dates ? y(dates) : null,
      };
    }),
  );
}

// Action + calculation: simulated pages and the page-1 fill for a page that
// is already in print emulation.
export async function paginate(page, printableHeight) {
  const blocks = await readAtomicBlocks(page);
  const pages = paginateBlocks(blocks, printableHeight);
  return { pages, fill: page1Fill(pages, printableHeight) };
}

// Calculation: entries whose header and dates land on different pages.
export function splitEntries(pages, marks) {
  return marks
    .filter((mark) => mark.datesY !== null)
    .filter((mark) => pageIndexOfY(pages, mark.headerY) !== pageIndexOfY(pages, mark.datesY))
    .map((mark) => mark.entry);
}
