/**
 * WCAG 2.x colour contrast over CSS colour strings. Pure calculations.
 *
 * Accepts the `rgb()` / `rgba()` forms getComputedStyle returns and 3/6-digit
 * hex literals; anything else parses to null. A translucent foreground is
 * composited over the background before measuring, so `rgba(0, 0, 0, 0)`
 * against white reads as 1:1, not as black.
 */

const RGB_FUNCTION = /rgba?\(\s*([\d.]+)\s*,?\s*([\d.]+)\s*,?\s*([\d.]+)\s*(?:[,/]\s*([\d.]+%?))?\s*\)/i;
const HEX = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i;

function parseAlpha(raw) {
  if (raw === undefined) {
    return 1;
  }
  return raw.endsWith("%") ? Number(raw.slice(0, -1)) / 100 : Number(raw);
}

function parseHex(hex) {
  const digits = hex.length === 3 ? [...hex].map((d) => d + d) : [hex.slice(0, 2), hex.slice(2, 4), hex.slice(4, 6)];
  const [r, g, b] = digits.map((pair) => Number.parseInt(pair, 16));
  return { r, g, b, a: 1 };
}

export function parseRgb(color) {
  if (!color) {
    return null;
  }
  const trimmed = color.trim();
  if (trimmed === "transparent") {
    return { r: 0, g: 0, b: 0, a: 0 };
  }
  const hex = trimmed.match(HEX);
  if (hex) {
    return parseHex(hex[1]);
  }
  const fn = trimmed.match(RGB_FUNCTION);
  if (!fn) {
    return null;
  }
  return { r: Number(fn[1]), g: Number(fn[2]), b: Number(fn[3]), a: parseAlpha(fn[4]) };
}

function compositeOver(fg, bg) {
  const blend = (f, b) => f * fg.a + b * (1 - fg.a);
  return { r: blend(fg.r, bg.r), g: blend(fg.g, bg.g), b: blend(fg.b, bg.b), a: 1 };
}

function linearChannel(value) {
  const c = value / 255;
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

export function relativeLuminance({ r, g, b }) {
  return 0.2126 * linearChannel(r) + 0.7152 * linearChannel(g) + 0.0722 * linearChannel(b);
}

// Returns the WCAG ratio (1..21) or null when either colour is unparseable.
export function contrastRatio(foreground, background) {
  const bg = parseRgb(background);
  const fg = parseRgb(foreground);
  if (!fg || !bg) {
    return null;
  }
  const lighter = Math.max(relativeLuminance(compositeOver(fg, bg)), relativeLuminance(bg));
  const darker = Math.min(relativeLuminance(compositeOver(fg, bg)), relativeLuminance(bg));
  return (lighter + 0.05) / (darker + 0.05);
}

export function formatRatio(ratio) {
  return ratio === null ? "n/a" : `${ratio.toFixed(2)}:1`;
}
