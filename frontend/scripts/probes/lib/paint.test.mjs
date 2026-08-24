import { test } from "node:test";
import assert from "node:assert/strict";
import { paintOrderReasons, paintPresenceReasons, paintStart } from "./paint.mjs";

const timing = (overrides) => ({
  paints: [
    { name: "first-paint", startTime: 600 },
    { name: "first-contentful-paint", startTime: 600 },
  ],
  sheetResponseEnd: 450,
  sheetRuleCount: 12,
  nameFont: "Fraunces, serif",
  ...overrides,
});
const neverSerif = () => false;

test("paintStart returns the startTime of the named paint entry", () => {
  assert.equal(paintStart(timing({}), "first-contentful-paint"), 600);
});

test("paintStart is null when the entry is missing", () => {
  assert.equal(paintStart(timing({ paints: [] }), "first-contentful-paint"), null);
});

test("paintOrderReasons is empty when fcp follows the sheet and the hold", () => {
  assert.deepEqual(paintOrderReasons(timing({}), 400), []);
});

test("paintOrderReasons reports a missing first-contentful-paint", () => {
  assert.deepEqual(paintOrderReasons(timing({ paints: [] }), 400), ["no first-contentful-paint entry in the sandbox frame"]);
});

test("paintOrderReasons reports a missing sheet resource entry", () => {
  assert.deepEqual(paintOrderReasons(timing({ sheetResponseEnd: null }), 400), [
    "no resource entry for #theme-stylesheet in the sandbox frame",
  ]);
});

test("paintOrderReasons reports fcp before the sheet finished", () => {
  const reasons = paintOrderReasons(timing({ sheetResponseEnd: 700 }), 400);
  assert.deepEqual(reasons, ["fcp 600ms < sheet responseEnd 700ms"]);
});

test("paintOrderReasons reports fcp before the held delay", () => {
  const early = timing({ paints: [{ name: "first-contentful-paint", startTime: 100 }], sheetResponseEnd: 50 });
  assert.deepEqual(paintOrderReasons(early, 400), ["fcp 100ms < held 400ms"]);
});

test("paintPresenceReasons is empty for both paint entries, rules, and a themed font", () => {
  assert.deepEqual(paintPresenceReasons(timing({}), neverSerif), []);
});

test("paintPresenceReasons reports a missing paint entry", () => {
  const only = timing({ paints: [{ name: "first-paint", startTime: 600 }] });
  assert.deepEqual(paintPresenceReasons(only, neverSerif), ["missing first-contentful-paint entry in the sandbox frame"]);
});

test("paintPresenceReasons reports an unexpected paint entry", () => {
  const extra = timing({ paints: [...timing({}).paints, { name: "largest-contentful-paint", startTime: 900 }] });
  assert.deepEqual(paintPresenceReasons(extra, neverSerif), ["unexpected paint entry largest-contentful-paint"]);
});

test("paintPresenceReasons reports a sheet with no rules", () => {
  assert.deepEqual(paintPresenceReasons(timing({ sheetRuleCount: 0 }), neverSerif), ["#theme-stylesheet has no cssRules after load"]);
});

test("paintPresenceReasons reports a UA serif name font via the injected predicate", () => {
  const reasons = paintPresenceReasons(timing({ nameFont: "serif" }), (font) => font === "serif");
  assert.deepEqual(reasons, [".rz-name font-family is UA serif (serif)"]);
});
