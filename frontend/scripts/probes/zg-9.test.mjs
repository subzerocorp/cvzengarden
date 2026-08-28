import { test } from "node:test";
import assert from "node:assert/strict";
import {
  dateGeometryReasons,
  desktopToggleReasons,
  escapeReasons,
  hscrollReasons,
  mobileFirstReasons,
  nameInViewport,
  sheetClosedAfterSelectReasons,
  sheetClosedReasons,
  sheetOpenReasons,
  themeHrefReasons,
} from "./zg-9.mjs";

test("mobileFirstReasons wants frame top < 80 and a visible name", () => {
  assert.deepEqual(mobileFirstReasons({ frameTop: 0, nameVisible: true }), []);
  assert.ok(mobileFirstReasons({ frameTop: 80, nameVisible: true }).some((reason) => reason.includes("top")));
  assert.ok(mobileFirstReasons({ frameTop: 0, nameVisible: false }).some((reason) => reason.includes(".rz-name")));
});

test("nameInViewport is true when the name intersects the chrome viewport", () => {
  assert.equal(nameInViewport(12, 40, 844), true);
  assert.equal(nameInViewport(900, 940, 844), false);
  assert.equal(nameInViewport(-40, 0, 844), false);
});

test("sheetClosedReasons pins the Theme name and aria-expanded false", () => {
  assert.deepEqual(sheetClosedReasons({ name: "Theme", expanded: "false" }), []);
  assert.ok(sheetClosedReasons({ name: "Themes", expanded: "false" }).length === 1);
  assert.ok(sheetClosedReasons({ name: "Theme", expanded: "true" }).length === 1);
});

test("sheetOpenReasons wants expanded, visible sidebar, clickable quarto", () => {
  assert.deepEqual(sheetOpenReasons({ expanded: "true", sidebarVisible: true, quartoClickable: true }), []);
  assert.equal(sheetOpenReasons({ expanded: "false", sidebarVisible: false, quartoClickable: false }).length, 3);
});

test("themeHrefReasons matches themes/<id>.css", () => {
  assert.deepEqual(themeHrefReasons("themes/quarto.css", "quarto"), []);
  assert.equal(themeHrefReasons("themes/nightgarden.css", "quarto").length, 1);
});

test("sheetClosedAfterSelectReasons wants quarto href and a closed sheet", () => {
  assert.deepEqual(sheetClosedAfterSelectReasons({ expanded: "false", href: "themes/quarto.css" }), []);
  assert.ok(sheetClosedAfterSelectReasons({ expanded: "true", href: "themes/quarto.css" }).some((reason) => reason.includes("open")));
});

test("escapeReasons wants a closed sheet and focus on theme-toggle", () => {
  assert.deepEqual(escapeReasons({ expanded: "false", focusedId: "theme-toggle" }), []);
  assert.equal(escapeReasons({ expanded: "true", focusedId: "theme-option-quarto" }).length, 2);
});

test("desktopToggleReasons hides Theme at 1280×800", () => {
  assert.deepEqual(desktopToggleReasons({ visible: false, width: 1280, height: 800 }), []);
  assert.ok(desktopToggleReasons({ visible: true, width: 1280, height: 800 }).some((reason) => reason.includes("visible")));
  assert.ok(desktopToggleReasons({ visible: false, width: 390, height: 844 }).some((reason) => reason.includes("viewport")));
});

test("dateGeometryReasons flags missing, clipped, and overflowing dates", () => {
  assert.deepEqual(
    dateGeometryReasons({ ok: true, count: 3, clipped: [], scrollX: false, parentScroll: false }, "nightgarden"),
    [],
  );
  assert.ok(dateGeometryReasons({ ok: false, reason: "missing resume" }, "quarto")[0].includes("quarto"));
  assert.ok(dateGeometryReasons({ ok: true, count: 0, clipped: [], scrollX: false, parentScroll: false }, "quarto").length);
  assert.ok(
    dateGeometryReasons({ ok: true, count: 2, clipped: [{ text: "2020" }], scrollX: false, parentScroll: false }, "quarto")
      .length,
  );
});

test("hscrollReasons allows scrollWidth up to the viewport", () => {
  assert.deepEqual(hscrollReasons(390, 390), []);
  assert.equal(hscrollReasons(391, 390).length, 1);
});
