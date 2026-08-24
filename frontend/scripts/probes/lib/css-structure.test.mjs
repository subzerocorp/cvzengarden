import { test } from "node:test";
import assert from "node:assert/strict";
import {
  hiddenRestReasons,
  isViewSupports,
  parseRules,
  riseInsideSupportsReasons,
  riseOutsideSupportsReasons,
  riseStructureReasons,
  topLevelBlocks,
  withoutViewSupports,
} from "./css-structure.mjs";

const SUPPORTS = "@supports (animation-timeline: view())";
const KEYFRAMES = "@keyframes rz-rise { from { opacity: 0; transform: translateY(1.15rem); } to { opacity: 1; } }";
const GOOD_RISE = `${SUPPORTS} { .rz-section { animation-name: rz-rise; animation-fill-mode: forwards; animation-timeline: view(); animation-range: entry 0% entry 32%; } }`;
const GUARD = "@media print, (prefers-reduced-motion: reduce) { .rz-section { animation: none !important; transform: none !important; } }";
const PRE_CHANGE = `${KEYFRAMES} .rz-section { animation: rz-rise 0.7s ease both; } ${SUPPORTS} { .rz-section { animation-timeline: view(); } }`;

test("topLevelBlocks brace-matches nested blocks and keeps the prelude", () => {
  const blocks = topLevelBlocks("a { b: 1; } @media x { c { d: 2; } }");
  assert.deepEqual(
    blocks.map((block) => [block.prelude.trim(), block.body.trim()]),
    [["a", "b: 1;"], ["@media x", "c { d: 2; }"]],
  );
});

test("topLevelBlocks starts a prelude after a top-level semicolon", () => {
  const blocks = topLevelBlocks('@import "x.css"; a { b: 1; }');
  assert.deepEqual(blocks.map((block) => block.prelude.trim()), ["a"]);
});

test("parseRules records the at-rule context chain", () => {
  const rules = parseRules("@media print { @supports (x) { .rz-section { opacity: 1; } } }");
  assert.deepEqual(rules, [{ selector: ".rz-section", context: ["@media print", "@supports (x)"], declarations: [{ property: "opacity", value: "1" }] }]);
});

test("parseRules excludes @keyframes bodies from the selector scan", () => {
  const rules = parseRules(`${KEYFRAMES} .rz-section { margin: 0; }`);
  assert.deepEqual(rules.map((rule) => rule.selector), [".rz-section"]);
});

test("parseRules ignores comments, including a commented-out rule", () => {
  const rules = parseRules("/* .rz-section { opacity: 0; } */ .rz-section { margin: 0; }");
  assert.deepEqual(rules[0].declarations, [{ property: "margin", value: "0" }]);
});

test("isViewSupports accepts whitespace variants and rejects other supports queries", () => {
  assert.equal(isViewSupports("@supports ( animation-timeline : view( ) )"), true);
  assert.equal(isViewSupports("@supports (display: grid)"), false);
});

test("withoutViewSupports removes a view() block preceded by a comment containing ; and {", () => {
  const css = ".a { x: 1; } /* why; because { */ @supports (animation-timeline: view()) { .b { y: 2; } }";
  // The comment belongs to the block's prelude span and goes with it.
  assert.equal(withoutViewSupports(css).trim(), ".a { x: 1; }");
});

test("withoutViewSupports removes only the view() supports blocks", () => {
  const css = ".a { x: 1; } @supports (animation-timeline: view()) { .b { y: 2; } } @supports (display: grid) { .c { z: 3; } }";
  assert.equal(withoutViewSupports(css).replace(/\s+/g, " ").trim(), ".a { x: 1; } @supports (display: grid) { .c { z: 3; } }");
});

test("riseOutsideSupportsReasons flags a top-level .rz-section rise (the pre-change sheet)", () => {
  assert.deepEqual(riseOutsideSupportsReasons(parseRules(PRE_CHANGE)), [
    "(a) `.rz-section` animation: rz-rise 0.7s ease both outside @supports (animation-timeline: view())",
  ]);
});

test("riseOutsideSupportsReasons flags a rise inside a plain @media", () => {
  const rules = parseRules("@media screen { .rz-section { animation-name: rz-rise; } }");
  assert.equal(riseOutsideSupportsReasons(rules).length, 1);
});

test("riseOutsideSupportsReasons ignores rz-rise on selectors other than .rz-section", () => {
  const rules = parseRules(".rz-section-title { animation: rz-rise 1s; } .rz-entry { animation-name: rz-rise; }");
  assert.deepEqual(riseOutsideSupportsReasons(rules), []);
});

test("riseInsideSupportsReasons passes the longhand forwards + view() rule", () => {
  assert.deepEqual(riseInsideSupportsReasons(parseRules(GOOD_RISE)), []);
});

test("riseInsideSupportsReasons accepts the shorthand's forwards token", () => {
  const rules = parseRules(`${SUPPORTS} { .rz-section { animation: rz-rise 0.7s ease forwards; animation-timeline: view(); } }`);
  assert.deepEqual(riseInsideSupportsReasons(rules), []);
});

test("riseInsideSupportsReasons reports a missing rise rule inside the block", () => {
  assert.deepEqual(riseInsideSupportsReasons(parseRules(".rz-section { margin: 0; }")), [
    "(b) no `.rz-section` rz-rise rule inside @supports (animation-timeline: view())",
  ]);
});

test("riseInsideSupportsReasons reports a missing timeline and a non-forwards fill", () => {
  const rules = parseRules(`${SUPPORTS} { .rz-section { animation-name: rz-rise; } }`);
  assert.deepEqual(riseInsideSupportsReasons(rules), [
    "(b) `.rz-section` inside @supports lacks animation-timeline: view()",
    "(b) `.rz-section` inside @supports fill mode is not forwards",
  ]);
});

test("riseInsideSupportsReasons flags both / backwards on any .rz-section animation declaration", () => {
  const rules = parseRules(`${GOOD_RISE} .rz-section:nth-of-type(2) { animation-fill-mode: backwards; }`);
  assert.deepEqual(riseInsideSupportsReasons(rules), ["(b) `.rz-section:nth-of-type(2)` animation-fill-mode: backwards uses a both/backwards fill"]);
});

test("hiddenRestReasons flags opacity < 1 and translateY on .rz-section or .rz-rise outside keyframes", () => {
  const rules = parseRules(`${KEYFRAMES} .rz-section { opacity: 0; } .rz-rise { transform: translateY(1rem); } .rz-section { opacity: 1; }`);
  assert.deepEqual(hiddenRestReasons(rules), [
    "(c) `.rz-section` opacity: 0 hides the rest state",
    "(c) `.rz-rise` transform: translateY(1rem) hides the rest state",
  ]);
});

test("hiddenRestReasons ignores the reduced-motion guard's transform: none", () => {
  assert.deepEqual(hiddenRestReasons(parseRules(GUARD)), []);
});

test("riseStructureReasons is empty for the post-change structure", () => {
  assert.deepEqual(riseStructureReasons(`${KEYFRAMES} .rz-section { margin: 0; } ${GOOD_RISE} ${GUARD}`), []);
});

test("riseStructureReasons fails the pre-change sheet on (a)", () => {
  const reasons = riseStructureReasons(PRE_CHANGE);
  assert.equal(reasons.some((reason) => reason.startsWith("(a)")), true);
});
