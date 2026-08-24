/**
 * ZG-11 print-marker and print-ink oracles. Pure calculations over the
 * computed-style records that `readBulletMarker` and `readInkColors` return.
 *
 * A pseudo-element has no node to measure, so a bar's or dot's box is read
 * from `getComputedStyle(el, "::before")` width/height: they serialise as
 * used px when the pseudo generates a box and as `auto` when it does not.
 */
import { contrastRatio, formatRatio } from "./contrast.mjs";

export const MIN_PRINT_CONTRAST = 4.5;
export const PAPER = "#fff";
export const INK_SELECTORS = [".rz-entry-secondary", ".rz-location", ".rz-dates", ".rz-meta"];

const BOXLESS_CONTENT = new Set(['""', "none", "normal"]);

// Action: one read of the first .rz-bullet's ::before plus its li list style.
export function readBulletMarker(page) {
  return page.evaluate(() => {
    const li = document.querySelector(".rz-bullet");
    if (!li) {
      return null;
    }
    const before = getComputedStyle(li, "::before");
    return {
      content: before.content,
      width: before.width,
      height: before.height,
      color: before.color,
      backgroundColor: before.backgroundColor,
      printColorAdjust: before.printColorAdjust || before.webkitPrintColorAdjust || "",
      listStyleType: getComputedStyle(li).listStyleType,
    };
  });
}

// Action: computed colour of the first element per ink selector.
export function readInkColors(page, selectors) {
  return page.evaluate(
    (wanted) =>
      wanted.map((selector) => {
        const el = document.querySelector(selector);
        return { selector, color: el ? getComputedStyle(el).color : null };
      }),
    selectors,
  );
}

function px(value) {
  const n = Number.parseFloat(value);
  return Number.isFinite(n) ? n : 0;
}

// A quoted string with at least one character inside (`""` is the empty bar).
export function isGlyph(marker) {
  return /^(["']).+\1$/s.test(marker.content);
}

export function hasBox(marker) {
  return BOXLESS_CONTENT.has(marker.content) && px(marker.width) > 0 && px(marker.height) > 0;
}

export function markerExistsReasons(marker) {
  if (isGlyph(marker) || hasBox(marker) || marker.listStyleType !== "none") {
    return [];
  }
  return [
    `no marker: ::before content ${marker.content}, width ${marker.width}, height ${marker.height}, list-style-type ${marker.listStyleType}`,
  ];
}

function inkedGlyphReasons(marker) {
  const ratio = contrastRatio(marker.color, PAPER);
  return ratio !== null && ratio >= MIN_PRINT_CONTRAST
    ? []
    : [`glyph ${marker.content} color ${marker.color} contrasts ${formatRatio(ratio)} against ${PAPER}, want >= ${MIN_PRINT_CONTRAST}:1`];
}

function inkedBoxReasons(marker) {
  const ratio = contrastRatio(marker.backgroundColor, PAPER);
  return [
    ...(ratio !== null && ratio >= MIN_PRINT_CONTRAST
      ? []
      : [`bar background-color ${marker.backgroundColor} contrasts ${formatRatio(ratio)} against ${PAPER}, want >= ${MIN_PRINT_CONTRAST}:1`]),
    ...(marker.printColorAdjust === "exact" ? [] : [`print-color-adjust is ${marker.printColorAdjust || "(unset)"}, want exact`]),
  ];
}

export function markerInkedReasons(marker) {
  if (isGlyph(marker)) {
    return inkedGlyphReasons(marker);
  }
  if (hasBox(marker)) {
    return inkedBoxReasons(marker);
  }
  return [];
}

export function bulletMarkerReasons(marker) {
  if (!marker) {
    return ["no .rz-bullet in the document"];
  }
  return [...markerExistsReasons(marker), ...markerInkedReasons(marker)];
}

export function describeMarker(marker) {
  if (isGlyph(marker)) {
    return `glyph ${marker.content} color ${marker.color} ${formatRatio(contrastRatio(marker.color, PAPER))}`;
  }
  return `box ${marker.width} x ${marker.height} background ${marker.backgroundColor} ${formatRatio(contrastRatio(marker.backgroundColor, PAPER))} print-color-adjust ${marker.printColorAdjust}`;
}

export function inkReasons(colors) {
  return colors.flatMap(({ selector, color }) => {
    if (color === null) {
      return [`${selector} is absent from the document`];
    }
    const ratio = contrastRatio(color, PAPER);
    return ratio !== null && ratio >= MIN_PRINT_CONTRAST ? [] : [`${selector} ${color} is ${formatRatio(ratio)} against ${PAPER}`];
  });
}

export function describeInk(colors) {
  return colors.map(({ selector, color }) => `${selector} ${formatRatio(contrastRatio(color, PAPER))}`).join(", ");
}
