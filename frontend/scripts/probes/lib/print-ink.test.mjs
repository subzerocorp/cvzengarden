import { test } from "node:test";
import assert from "node:assert/strict";
import { bulletMarkerReasons, hasBox, inkReasons, isGlyph } from "./print-ink.mjs";

const marker = (overrides) => ({
  content: "none",
  width: "auto",
  height: "auto",
  color: "rgb(0, 0, 0)",
  backgroundColor: "rgba(0, 0, 0, 0)",
  printColorAdjust: "",
  listStyleType: "none",
  ...overrides,
});

test("isGlyph accepts a quoted string with at least one character", () => {
  assert.equal(isGlyph(marker({ content: '"– "' })), true);
});

test("isGlyph rejects the empty quoted string", () => {
  assert.equal(isGlyph(marker({ content: '""' })), false);
});

test("hasBox requires empty content and positive used width and height", () => {
  assert.equal(hasBox(marker({ content: '""', width: "6px", height: "2px" })), true);
});

test("hasBox is false when width is auto", () => {
  assert.equal(hasBox(marker({ content: "none", width: "auto", height: "auto" })), false);
});

test("bulletMarkerReasons passes an inked glyph", () => {
  const reasons = bulletMarkerReasons(marker({ content: '"– "', color: "rgb(0, 0, 0)" }));
  assert.deepEqual(reasons, []);
});

test("bulletMarkerReasons fails a pale glyph on the contrast clause", () => {
  const reasons = bulletMarkerReasons(marker({ content: '"– "', color: "rgb(200, 200, 200)" }));
  assert.equal(reasons.length, 1);
  assert.match(reasons[0], /^glyph "– " color rgb\(200, 200, 200\) contrasts 1\.67:1 against #fff, want >= 4\.5:1$/);
});

test("bulletMarkerReasons fails content none / width auto / list-style none as no marker", () => {
  const reasons = bulletMarkerReasons(marker({ content: "none", width: "auto", height: "auto" }));
  assert.deepEqual(reasons, ["no marker: ::before content none, width auto, height auto, list-style-type none"]);
});

test("bulletMarkerReasons passes a sized dark bar with print-color-adjust exact", () => {
  const bar = marker({ content: '""', width: "6px", height: "2px", backgroundColor: "rgb(0, 0, 0)", printColorAdjust: "exact" });
  assert.deepEqual(bulletMarkerReasons(bar), []);
});

test("bulletMarkerReasons fails a pale bar on economy with both ink reasons", () => {
  const bar = marker({ content: '""', width: "6px", height: "2px", backgroundColor: "rgb(180, 240, 220)", printColorAdjust: "economy" });
  const reasons = bulletMarkerReasons(bar);
  assert.equal(reasons.length, 2);
  assert.match(reasons[0], /^bar background-color rgb\(180, 240, 220\) contrasts \d\.\d\d:1 against #fff, want >= 4\.5:1$/);
  assert.equal(reasons[1], "print-color-adjust is economy, want exact");
});

test("bulletMarkerReasons fails a zero-height bar as no marker", () => {
  const bar = marker({ content: '""', width: "6px", height: "0px", backgroundColor: "rgb(0, 0, 0)", printColorAdjust: "exact" });
  const reasons = bulletMarkerReasons(bar);
  assert.deepEqual(reasons, ['no marker: ::before content "", width 6px, height 0px, list-style-type none']);
});

test("bulletMarkerReasons passes a list-style-type disc with no pseudo box", () => {
  assert.deepEqual(bulletMarkerReasons(marker({ listStyleType: "disc" })), []);
});

test("bulletMarkerReasons reports a missing .rz-bullet for a null marker", () => {
  assert.deepEqual(bulletMarkerReasons(null), ["no .rz-bullet in the document"]);
});

test("inkReasons is empty for dark ink", () => {
  assert.deepEqual(inkReasons([{ selector: ".rz-dates", color: "rgb(0, 0, 0)" }]), []);
});

test("inkReasons names a pale selector with its ratio", () => {
  const reasons = inkReasons([{ selector: ".rz-dates", color: "rgb(200, 200, 200)" }]);
  assert.deepEqual(reasons, [".rz-dates rgb(200, 200, 200) is 1.67:1 against #fff"]);
});

test("inkReasons reports an absent selector", () => {
  assert.deepEqual(inkReasons([{ selector: ".rz-meta", color: null }]), [".rz-meta is absent from the document"]);
});

test("inkReasons fails an unparseable colour as n/a rather than passing it", () => {
  const reasons = inkReasons([{ selector: ".rz-dates", color: "oklch(0.5 0.1 200)" }]);
  assert.deepEqual(reasons, [".rz-dates oklch(0.5 0.1 200) is n/a against #fff"]);
});
