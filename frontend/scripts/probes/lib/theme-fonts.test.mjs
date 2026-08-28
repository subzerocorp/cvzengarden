import { test } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import {
  barL1PairReasons,
  dateGeometryReasons,
  extractFontFaceBlocks,
  fallbackLayoutReasons,
  fontFaceUrls,
  fontFetchReasons,
  fontFileListReasons,
  fontsLoadReasons,
  ignoredFontLoadCount,
  isIgnoredFontLoadError,
  isLoopbackHost,
  resolveThemeUrl,
  themeFontDistPath,
  themeFontRows,
  themePairs,
  thirdPartyRequests,
  unexpectedConsoleErrors,
} from "./theme-fonts.mjs";

const SHEET = `
/* comment with url("https://cdn.example/ignore.woff2") */
@font-face {
  font-family: "EB Garamond";
  src: local("EB Garamond"),
    url("fonts/eb-garamond/latin-400-normal.woff2") format("woff2");
}
.rz-name { font-family: "EB Garamond"; }
@font-face {
  font-family: "EB Garamond";
  src: url('fonts/eb-garamond/latin-400-italic.woff2') format("woff2");
}
`;

test("extractFontFaceBlocks is brace-matched and ignores comments", () => {
  assert.equal(extractFontFaceBlocks(SHEET).length, 2);
  assert.equal(extractFontFaceBlocks("/* @font-face { url('x') } */ .x{color:red}").length, 0);
});

test("fontFaceUrls reads only @font-face url() tokens", () => {
  assert.deepEqual(fontFaceUrls(SHEET), [
    "fonts/eb-garamond/latin-400-normal.woff2",
    "fonts/eb-garamond/latin-400-italic.woff2",
  ]);
});

test("fontFileListReasons wants a non-empty list per theme", () => {
  assert.deepEqual(fontFileListReasons(themeFontRows({ quarto: SHEET })), []);
  assert.ok(fontFileListReasons([{ id: "blank", urls: [] }]).some((reason) => reason.includes("blank.css")));
  assert.ok(fontFileListReasons([]).some((reason) => reason.includes("no @font-face")));
});

test("resolveThemeUrl is relative to /themes/", () => {
  assert.equal(
    resolveThemeUrl("fonts/eb-garamond/latin-400-normal.woff2", "http://127.0.0.1:4310"),
    "http://127.0.0.1:4310/themes/fonts/eb-garamond/latin-400-normal.woff2",
  );
});

test("themeFontDistPath lands under dist/themes/fonts", () => {
  assert.equal(
    themeFontDistPath("fonts/eb-garamond/latin-400-normal.woff2", "/app/frontend/dist/themes"),
    path.join("/app/frontend/dist/themes", "fonts/eb-garamond/latin-400-normal.woff2"),
  );
});

test("fontFetchReasons wants 200 font/woff2 on disk", () => {
  assert.deepEqual(
    fontFetchReasons({ url: "/f", status: 200, contentType: "font/woff2", onDisk: true }),
    [],
  );
  assert.ok(fontFetchReasons({ url: "/f", status: 404, contentType: "font/woff2", onDisk: true }).length);
  assert.ok(fontFetchReasons({ url: "/f", status: 200, contentType: "text/plain", onDisk: true }).length);
  assert.ok(fontFetchReasons({ url: "/f", status: 200, contentType: "font/woff2", onDisk: false }).length);
});

test("thirdPartyRequests keeps only loopback hosts", () => {
  const urls = [
    "http://127.0.0.1:4310/themes/quarto.css",
    "http://localhost:4310/themes/fonts/syne/latin-700-normal.woff2",
    "https://cdn.jsdelivr.net/fontsource/fonts/syne@5.2.5/latin-700-normal.woff2",
  ];
  assert.equal(isLoopbackHost(urls[0]), true);
  assert.deepEqual(thirdPartyRequests(urls), [urls[2]]);
  assert.equal(isLoopbackHost("not a url"), false);
});

test("fontsLoadReasons wants loaded and never error on the three families", () => {
  const faces = [
    { family: '"EB Garamond"', status: "loaded" },
    { family: "IBM Plex Sans", status: "unloaded" },
  ];
  assert.deepEqual(fontsLoadReasons(faces, "EB Garamond"), []);
  assert.ok(fontsLoadReasons(faces, "Syne").some((reason) => reason.includes("Syne")));
  assert.ok(
    fontsLoadReasons([{ family: "EB Garamond", status: "error" }], "EB Garamond").some((reason) =>
      reason.includes("status error"),
    ),
  );
});

test("themePairs is the three first-party pairs", () => {
  assert.deepEqual(themePairs(["nightgarden", "quarto", "switchyard"]), [
    ["nightgarden", "quarto"],
    ["nightgarden", "switchyard"],
    ["quarto", "switchyard"],
  ]);
});

test("barL1PairReasons passes when color or font-family differs", () => {
  assert.deepEqual(
    barL1PairReasons({ color: "rgb(1, 2, 3)", fontFamily: "Syne" }, { color: "rgb(1, 2, 3)", fontFamily: "EB Garamond" }, "n/q"),
    [],
  );
  assert.deepEqual(
    barL1PairReasons({ color: "rgb(1, 2, 3)", fontFamily: "Syne" }, { color: "rgb(9, 9, 9)", fontFamily: "Syne" }, "n/q"),
    [],
  );
  assert.ok(
    barL1PairReasons({ color: "rgb(1, 2, 3)", fontFamily: "Syne" }, { color: "rgb(1, 2, 3)", fontFamily: "Syne" }, "n/q")
      .length,
  );
});

test("fallback console filter ignores only /themes/fonts/ resource errors", () => {
  const ignored = { type: "error", text: "Failed to load resource: net::ERR_FAILED", locationUrl: "http://127.0.0.1:4310/themes/fonts/syne/x.woff2" };
  const other = { type: "error", text: "boom", locationUrl: "http://127.0.0.1:4310/garden.js" };
  const textOnly = { type: "error", text: "Failed to load resource http://127.0.0.1/themes/fonts/x.woff2", locationUrl: "" };
  assert.equal(isIgnoredFontLoadError(ignored), true);
  assert.equal(isIgnoredFontLoadError(textOnly), true);
  assert.equal(isIgnoredFontLoadError(other), false);
  assert.deepEqual(unexpectedConsoleErrors([ignored, other, { type: "log", text: "x" }]), [other]);
  assert.equal(ignoredFontLoadCount([ignored, textOnly, other]), 2);
});

test("dateGeometryReasons and fallbackLayoutReasons pin S2 + BAR-U2 + name height", () => {
  const ok = { ok: true, count: 2, clipped: [], scrollX: false, parentScroll: false };
  assert.deepEqual(dateGeometryReasons(ok, "quarto"), []);
  assert.ok(dateGeometryReasons({ ok: false, reason: "missing resume" }, "quarto").length);
  assert.deepEqual(
    fallbackLayoutReasons({ nameHeight: 24, scrollWidth: 1280, clientWidth: 1280, geometryByTheme: { quarto: ok } }),
    [],
  );
  assert.ok(fallbackLayoutReasons({ nameHeight: 0, scrollWidth: 1280, clientWidth: 1280, geometryByTheme: { quarto: ok } }).length);
  assert.ok(fallbackLayoutReasons({ nameHeight: 24, scrollWidth: 1300, clientWidth: 1280, geometryByTheme: { quarto: ok } }).some((reason) => reason.includes("BAR-U2")));
});
