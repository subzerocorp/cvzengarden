import { test } from "node:test";
import assert from "node:assert/strict";
import { contrastRatio, formatRatio, parseRgb, relativeLuminance } from "./contrast.mjs";

test("parseRgb reads the comma rgb() form", () => {
  assert.deepEqual(parseRgb("rgb(10, 20, 30)"), { r: 10, g: 20, b: 30, a: 1 });
});

test("parseRgb reads the comma rgba() form with a decimal alpha", () => {
  assert.deepEqual(parseRgb("rgba(10, 20, 30, 0.5)"), { r: 10, g: 20, b: 30, a: 0.5 });
});

test("parseRgb reads the space/slash form", () => {
  assert.deepEqual(parseRgb("rgb(10 20 30 / 0.25)"), { r: 10, g: 20, b: 30, a: 0.25 });
});

test("parseRgb reads a percentage alpha", () => {
  assert.deepEqual(parseRgb("rgb(0 0 0 / 50%)"), { r: 0, g: 0, b: 0, a: 0.5 });
});

test("parseRgb expands a 3-digit hex literal", () => {
  assert.deepEqual(parseRgb("#fff"), { r: 255, g: 255, b: 255, a: 1 });
});

test("parseRgb reads a 6-digit hex literal", () => {
  assert.deepEqual(parseRgb("#0a141e"), { r: 10, g: 20, b: 30, a: 1 });
});

test("parseRgb reads transparent as fully transparent black", () => {
  assert.deepEqual(parseRgb("transparent"), { r: 0, g: 0, b: 0, a: 0 });
});

test("parseRgb returns null for an unsupported colour function", () => {
  assert.equal(parseRgb("oklch(0.5 0.1 200)"), null);
});

test("parseRgb returns null for an empty string", () => {
  assert.equal(parseRgb(""), null);
});

test("relativeLuminance is 1 for white", () => {
  assert.equal(relativeLuminance({ r: 255, g: 255, b: 255 }), 1);
});

test("contrastRatio of black on white is 21", () => {
  assert.equal(Number(contrastRatio("#000", "#fff").toFixed(2)), 21);
});

test("contrastRatio of white on white is 1", () => {
  assert.equal(contrastRatio("#fff", "#fff"), 1);
});

test("contrastRatio composites a fully transparent foreground over the background", () => {
  assert.equal(contrastRatio("rgba(0, 0, 0, 0)", "#fff"), 1);
});

test("contrastRatio composites a half-transparent black over white", () => {
  assert.equal(Number(contrastRatio("rgb(0 0 0 / 50%)", "#fff").toFixed(2)), 3.98);
});

test("contrastRatio is null when the foreground is unparseable", () => {
  assert.equal(contrastRatio("oklch(0.5 0.1 200)", "#fff"), null);
});

test("contrastRatio is null when the background is unparseable", () => {
  assert.equal(contrastRatio("#000", "garbage"), null);
});

test("formatRatio prints n/a for null", () => {
  assert.equal(formatRatio(null), "n/a");
});

test("formatRatio prints two decimals and the :1 suffix", () => {
  assert.equal(formatRatio(4.5), "4.50:1");
});
