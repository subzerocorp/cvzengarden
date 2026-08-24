import { test } from "node:test";
import assert from "node:assert/strict";
import { forcedBreakReasons } from "./zg-11.mjs";

test("forcedBreakReasons ignores a forced break that only appears in a comment", () => {
  const css = "/* .rz-section { break-before: page; } */ .rz-section { break-inside: auto; }";
  assert.deepEqual(forcedBreakReasons(css, "x.css"), []);
});

test("forcedBreakReasons catches the page-break-before alias inside @media print", () => {
  const css = "@media print { #rz-projects { page-break-before : always; } }";
  assert.deepEqual(forcedBreakReasons(css, "x.css"), ["x.css declares break-before: page / page-break-before: always"]);
});

test("forcedBreakReasons catches break-before: page at the top level", () => {
  const css = "#rz-projects { break-before: page; }";
  assert.deepEqual(forcedBreakReasons(css, "x.css"), ["x.css declares break-before: page / page-break-before: always"]);
});

test("forcedBreakReasons ignores break-before: auto", () => {
  assert.deepEqual(forcedBreakReasons("#rz-projects { break-before: auto; }", "x.css"), []);
});
