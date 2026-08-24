/**
 * ZG-23 paint-order oracle for the S1 cold-load FOUC probe.
 *
 * Why paint timing instead of computed style: a render-blocked document
 * resolves computed style while ignoring the pending sheet, so a sampler can
 * "see" an unstyled frame the browser never painted. `first-contentful-paint`
 * is the frame that was actually painted; if it lands after the held theme
 * sheet finished downloading, no unstyled frame was ever shown.
 *
 * Everything here is a calculation except `readSandboxPaintTiming`, the single
 * action that reads the timing record inside the sandbox frame.
 */

export const COLD_SHEET_DELAY_MS = 400;
export const COLD_SETTLE_MS = 200;
export const PAINT_ENTRY_NAMES = ["first-paint", "first-contentful-paint"];

// Action: evaluates inside the sandbox frame and returns an immutable record.
export function readSandboxPaintTiming(frame) {
  return frame.evaluate(() => {
    const link = document.getElementById("theme-stylesheet");
    const sheet = link
      ? performance.getEntriesByType("resource").find((entry) => entry.name === link.href)
      : undefined;
    const name = document.querySelector(".rz-name");
    return {
      paints: performance.getEntriesByType("paint").map((entry) => ({
        name: entry.name,
        startTime: entry.startTime,
      })),
      sheetResponseEnd: sheet ? sheet.responseEnd : null,
      sheetRuleCount: link?.sheet ? link.sheet.cssRules.length : 0,
      nameFont: name ? getComputedStyle(name).fontFamily : "",
    };
  });
}

function ms(value) {
  return `${Math.round(value)}ms`;
}

export function paintStart(timing, entryName) {
  const entry = timing.paints.find((paint) => paint.name === entryName);
  return entry ? entry.startTime : null;
}

export function paintOrderReasons(timing, delayMs) {
  const fcp = paintStart(timing, "first-contentful-paint");
  const responseEnd = timing.sheetResponseEnd;
  if (fcp === null) {
    return ["no first-contentful-paint entry in the sandbox frame"];
  }
  if (responseEnd === null) {
    return ["no resource entry for #theme-stylesheet in the sandbox frame"];
  }
  return [
    ...(fcp < responseEnd ? [`fcp ${ms(fcp)} < sheet responseEnd ${ms(responseEnd)}`] : []),
    ...(fcp < delayMs ? [`fcp ${ms(fcp)} < held ${delayMs}ms`] : []),
  ];
}

export function describePaintOrder(timing) {
  const fcp = paintStart(timing, "first-contentful-paint");
  return `${ms(fcp)} >= ${ms(timing.sheetResponseEnd)}`;
}

// `isUaSerif` is injected so this module owns no font heuristics.
export function paintPresenceReasons(timing, isUaSerif) {
  const names = timing.paints.map((paint) => paint.name);
  const missing = PAINT_ENTRY_NAMES.filter((name) => !names.includes(name));
  const extra = names.filter((name) => !PAINT_ENTRY_NAMES.includes(name));
  return [
    ...missing.map((name) => `missing ${name} entry in the sandbox frame`),
    ...extra.map((name) => `unexpected paint entry ${name}`),
    ...(timing.sheetRuleCount > 0 ? [] : ["#theme-stylesheet has no cssRules after load"]),
    ...(isUaSerif(timing.nameFont) ? [`.rz-name font-family is UA serif (${timing.nameFont})`] : []),
  ];
}
