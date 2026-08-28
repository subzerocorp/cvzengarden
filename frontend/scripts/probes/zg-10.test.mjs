import { test } from "node:test";
import assert from "node:assert/strict";
import {
  consoleErrorReasons,
  fallbackReasons,
  guideLineReasons,
  hintReasons,
  nearPdfReasons,
  paperSizeReasons,
} from "./zg-10.mjs";

test("paperSizeReasons wants the declared paper", () => {
  assert.deepEqual(paperSizeReasons({ size: "Letter", source: "declared", wantSize: "Letter" }), []);
  assert.ok(paperSizeReasons({ size: "A4", source: "declared", wantSize: "Letter" }).some((reason) => reason.includes("data-page-size")));
  assert.ok(paperSizeReasons({ size: "Letter", source: "default", wantSize: "Letter" }).some((reason) => reason.includes("data-page-size-source")));
});

test("fallbackReasons pins Letter plus the source", () => {
  assert.deepEqual(fallbackReasons({ size: "Letter", source: "default", wantSource: "default" }), []);
  assert.deepEqual(fallbackReasons({ size: "Letter", source: "fallback", wantSource: "fallback" }), []);
  assert.ok(fallbackReasons({ size: "A4", source: "default", wantSource: "default" }).length >= 1);
});

test("nearPdfReasons allows a one-page miss and requires About", () => {
  assert.deepEqual(nearPdfReasons({ estimate: 2, pdfPages: 3, label: "About 2 pages (A4)" }), []);
  assert.ok(nearPdfReasons({ estimate: 2, pdfPages: 4, label: "About 2 pages (A4)" }).length >= 1);
  assert.ok(nearPdfReasons({ estimate: 2, pdfPages: 2, label: "2 pages (Letter)" }).some((reason) => reason.includes("About")));
});

test("hintReasons wants a visible paragraph under the ZG-7 sentence", () => {
  assert.deepEqual(
    hintReasons({
      tag: "P",
      nestedButtons: 0,
      screenVisible: true,
      printVisible: true,
      text: 'Choose "Save as PDF" in the print dialog to get a PDF.',
      printSentence: true,
      printButtons: 1,
    }),
    [],
  );
  assert.ok(hintReasons({
    tag: "BUTTON",
    nestedButtons: 1,
    screenVisible: false,
    printVisible: false,
    text: "hint",
    printSentence: false,
    printButtons: 2,
  }).length >= 4);
});

test("guideLineReasons wants one iframe and a clean sandbox head", () => {
  assert.deepEqual(
    guideLineReasons({
      stageChildren: 1,
      stageChildId: "garden-frame",
      bodyChildren: 1,
      bodyChild: true,
      headStyles: 0,
      headScripts: 0,
      themeLinks: 1,
      htmlStyle: null,
    }),
    [],
  );
  assert.ok(guideLineReasons({
    stageChildren: 2,
    stageChildId: "guide",
    bodyChildren: 2,
    bodyChild: false,
    headStyles: 1,
    headScripts: 1,
    themeLinks: 2,
    htmlStyle: "width: 720px",
  }).length >= 4);
});

test("consoleErrorReasons keeps only console.error", () => {
  assert.deepEqual(consoleErrorReasons([{ type: "log", text: "ok" }]), []);
  assert.deepEqual(consoleErrorReasons([{ type: "error", text: "boom" }]), ["console error: boom"]);
});
