import { test } from "node:test";
import assert from "node:assert/strict";
import { sheetBlockingReasons } from "./sheet-blocking.mjs";

const doc = (link, { inBody = false } = {}) =>
  inBody ? `<html><head></head><body>${link}</body></html>` : `<html><head>${link}</head><body></body></html>`;
const LINK = '<link id="theme-stylesheet" rel="stylesheet" href="themes/quarto.css">';

test("sheetBlockingReasons is empty for a plain render-blocking link in head", () => {
  assert.deepEqual(sheetBlockingReasons(doc(LINK)), []);
});

test("sheetBlockingReasons reports zero theme links", () => {
  assert.deepEqual(sheetBlockingReasons(doc("")), ["expected exactly one #theme-stylesheet link, found 0"]);
});

test("sheetBlockingReasons reports duplicate theme links", () => {
  assert.deepEqual(sheetBlockingReasons(doc(LINK + LINK)), ["expected exactly one #theme-stylesheet link, found 2"]);
});

test("sheetBlockingReasons reports a link placed inside body", () => {
  assert.deepEqual(sheetBlockingReasons(doc(LINK, { inBody: true })), ["#theme-stylesheet link is not before <body>"]);
});

test("sheetBlockingReasons reports a link without rel=stylesheet", () => {
  const link = '<link id="theme-stylesheet" rel="preload" href="themes/quarto.css">';
  assert.deepEqual(sheetBlockingReasons(doc(link)), ['#theme-stylesheet link lacks rel="stylesheet"']);
});

test("sheetBlockingReasons reports a media attribute", () => {
  const link = '<link id="theme-stylesheet" rel="stylesheet" media="print" href="themes/quarto.css">';
  assert.deepEqual(sheetBlockingReasons(doc(link)), ["#theme-stylesheet link carries media/disabled/onload"]);
});

test("sheetBlockingReasons reports an onload attribute", () => {
  const link = '<link id="theme-stylesheet" rel="stylesheet" href="themes/quarto.css" onload="this.media=\'all\'">';
  assert.deepEqual(sheetBlockingReasons(doc(link)), ["#theme-stylesheet link carries media/disabled/onload"]);
});

test("sheetBlockingReasons reports a disabled attribute", () => {
  const link = '<link id="theme-stylesheet" rel="stylesheet" href="themes/quarto.css" disabled>';
  assert.deepEqual(sheetBlockingReasons(doc(link)), ["#theme-stylesheet link carries media/disabled/onload"]);
});
