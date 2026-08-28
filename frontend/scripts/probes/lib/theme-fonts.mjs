/**
 * Calculations over first-party Theme `@font-face` blocks, request hosts,
 * FontFace lists, and BAR-L1 pair styles. Actions (fetch, click, abort)
 * stay in the ZG-13 probe module.
 */
import path from "node:path";
import { topLevelBlocks } from "./css-structure.mjs";

const WATCHED_FAMILIES = ["EB Garamond", "IBM Plex Sans", "Syne"];
const URL_TOKEN = /url\(\s*(['"]?)([^'")]+)\1\s*\)/gi;

function squash(text) {
  return text.replace(/\s+/g, " ").trim();
}

export function extractFontFaceBlocks(css) {
  return topLevelBlocks(css).filter((block) => squash(block.prelude) === "@font-face");
}

export function fontFaceUrls(css) {
  return extractFontFaceBlocks(css).flatMap((block) => {
    const found = [];
    const scanner = new RegExp(URL_TOKEN.source, "gi");
    let match = scanner.exec(block.body);
    while (match) {
      found.push(match[2].trim());
      match = scanner.exec(block.body);
    }
    return found;
  });
}

export function themeFontRows(themeCssById) {
  return Object.entries(themeCssById).map(([id, css]) => ({ id, urls: fontFaceUrls(css) }));
}

export function fontFileListReasons(rows) {
  const all = rows.flatMap((row) => row.urls);
  return [
    ...(all.length > 0 ? [] : ["no @font-face url() in themes/*.css"]),
    ...rows.filter((row) => row.urls.length === 0).map((row) => `${row.id}.css has no @font-face url()`),
  ];
}

export function resolveThemeUrl(spec, origin) {
  return new URL(spec, `${String(origin).replace(/\/$/, "")}/themes/`).href;
}

export function themeFontDistPath(spec, distThemesDir) {
  const resolved = new URL(spec, "http://probe.invalid/themes/");
  const relative = decodeURIComponent(resolved.pathname.replace(/^\/themes\//, ""));
  return path.join(distThemesDir, relative);
}

export function fontFetchReasons({ url, status, contentType, onDisk }) {
  const type = String(contentType || "").toLowerCase();
  return [
    ...(status === 200 ? [] : [`${url} status ${status}, want 200`]),
    ...(type.includes("font/woff2") ? [] : [`${url} Content-Type ${JSON.stringify(contentType)}, want font/woff2`]),
    ...(onDisk ? [] : [`${url} missing under frontend/dist/themes/fonts/`]),
  ];
}

export function isLoopbackHost(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }
  return parsed.hostname === "127.0.0.1" || parsed.hostname === "localhost";
}

export function thirdPartyRequests(urls) {
  return urls.filter((url) => !isLoopbackHost(url));
}

export function faceFamily(family) {
  return String(family).replace(/["']/g, "");
}

export function fontsLoadReasons(faces, family) {
  const named = faces.map((face) => ({ family: faceFamily(face.family), status: face.status }));
  const loaded = named.some((face) => face.family === family && face.status === "loaded");
  const errored = named.filter((face) => WATCHED_FAMILIES.includes(face.family) && face.status === "error");
  return [
    ...(loaded ? [] : [`no FontFace family ${family} with status loaded`]),
    ...errored.map((face) => `${face.family} has status error`),
  ];
}

export function themePairs(ids) {
  const pairs = [];
  for (let i = 0; i < ids.length; i += 1) {
    for (let j = i + 1; j < ids.length; j += 1) {
      pairs.push([ids[i], ids[j]]);
    }
  }
  return pairs;
}

export function barL1PairReasons(left, right, label) {
  if (left.color !== right.color || left.fontFamily !== right.fontFamily) {
    return [];
  }
  return [`${label}: color and font-family both ${left.color} / ${left.fontFamily}`];
}

export function isIgnoredFontLoadError(message) {
  if (message.type !== "error") {
    return false;
  }
  const loc = message.locationUrl ?? "";
  const text = message.text ?? "";
  return loc.includes("/themes/fonts/") || text.includes("/themes/fonts/");
}

export function unexpectedConsoleErrors(messages) {
  return messages.filter((message) => message.type === "error" && !isIgnoredFontLoadError(message));
}

export function ignoredFontLoadCount(messages) {
  return messages.filter(isIgnoredFontLoadError).length;
}

export function dateGeometryReasons(geometry, id) {
  if (!geometry.ok) {
    return [`S2 ${id}: ${geometry.reason}`];
  }
  if (geometry.count === 0) {
    return [`S2 ${id}: no .rz-date / time[datetime] nodes`];
  }
  return [
    ...(geometry.clipped.length === 0 ? [] : [`S2 ${id}: ${geometry.clipped.length} date(s) overflow the .rz-resume content box`]),
    ...(geometry.scrollX || geometry.parentScroll ? [`S2 ${id}: horizontal overflow`] : []),
  ];
}

export function fallbackLayoutReasons({ nameHeight, scrollWidth, clientWidth, geometryByTheme }) {
  return [
    ...(nameHeight > 0 ? [] : [`.rz-name height is ${nameHeight}, want > 0`]),
    ...(scrollWidth <= clientWidth ? [] : [`BAR-U2 documentElement.scrollWidth ${scrollWidth} > clientWidth ${clientWidth}`]),
    ...Object.entries(geometryByTheme).flatMap(([id, geometry]) => dateGeometryReasons(geometry, id)),
  ];
}
