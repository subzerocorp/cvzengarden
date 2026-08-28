/**
 * Pure print-page estimate. No DOM. ports.js collects CSSPageRules and
 * measures height; this module turns those facts into paper geometry and
 * an "About N pages" label.
 *
 * Data: paper sizes at 96 dpi, Chromium's 1 cm default margin.
 * Calculations: pageGeometry, estimatePages, estimateLabel.
 * Actions: none.
 */

const LETTER = { width: 816, height: 1056 };
const A4 = { width: 793.7, height: 1122.5 };
const DEFAULT_MARGIN_PX = 96 / 2.54;

function isBaseSelector(selector) {
  const text = String(selector ?? "").trim();
  return text === "" || text === "@page";
}

function parseLengthPx(value) {
  const text = String(value ?? "").trim();
  const match = /^(-?[\d.]+)\s*(in|cm|mm|pt|px)$/i.exec(text);
  if (!match) {
    return null;
  }
  const amount = Number(match[1]);
  if (!Number.isFinite(amount)) {
    return null;
  }
  switch (match[2].toLowerCase()) {
    case "in":
      return amount * 96;
    case "cm":
      return amount * (96 / 2.54);
    case "mm":
      return amount * (96 / 25.4);
    case "pt":
      return amount * (96 / 72);
    case "px":
      return amount;
    default:
      return null;
  }
}

function marginPx(value) {
  return parseLengthPx(value) ?? DEFAULT_MARGIN_PX;
}

function resolveMargins(rule) {
  const top = String(rule?.marginTop ?? "").trim();
  const right = String(rule?.marginRight ?? "").trim();
  const bottom = String(rule?.marginBottom ?? "").trim();
  const left = String(rule?.marginLeft ?? "").trim();
  if (!top && !right && !bottom && !left) {
    return {
      top: DEFAULT_MARGIN_PX,
      right: DEFAULT_MARGIN_PX,
      bottom: DEFAULT_MARGIN_PX,
      left: DEFAULT_MARGIN_PX,
    };
  }
  return {
    top: marginPx(top),
    right: marginPx(right),
    bottom: marginPx(bottom),
    left: marginPx(left),
  };
}

function paperFromSize(size) {
  const token = String(size ?? "").trim().toLowerCase();
  if (token === "") {
    return { paper: "Letter", source: "default", dims: LETTER };
  }
  if (token === "letter") {
    return { paper: "Letter", source: "declared", dims: LETTER };
  }
  if (token === "a4") {
    return { paper: "A4", source: "declared", dims: A4 };
  }
  return { paper: "Letter", source: "fallback", dims: LETTER };
}

function letterDefault() {
  const margins = resolveMargins({});
  return {
    paper: "Letter",
    source: "default",
    contentWidthPx: LETTER.width - margins.left - margins.right,
    contentHeightPx: LETTER.height - margins.top - margins.bottom,
  };
}

export function pageGeometry(pageRules) {
  const rules = Array.isArray(pageRules) ? pageRules : [];
  const bases = rules.filter((rule) => isBaseSelector(rule?.selector));
  if (bases.length === 0) {
    return letterDefault();
  }
  const last = bases[bases.length - 1];
  const chosen = paperFromSize(last.size);
  if (chosen.source === "default") {
    return letterDefault();
  }
  const margins = resolveMargins(last);
  return {
    paper: chosen.paper,
    source: chosen.source,
    contentWidthPx: chosen.dims.width - margins.left - margins.right,
    contentHeightPx: chosen.dims.height - margins.top - margins.bottom,
  };
}

export function estimatePages(heightPx, contentHeightPx) {
  if (!(contentHeightPx > 0)) {
    return 1;
  }
  return Math.max(1, Math.ceil(Number(heightPx) / contentHeightPx));
}

export function estimateLabel(n, paper) {
  const noun = n === 1 ? "page" : "pages";
  return `About ${n} ${noun} (${paper})`;
}
