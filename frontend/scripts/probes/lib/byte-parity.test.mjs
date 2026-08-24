import { test } from "node:test";
import assert from "node:assert/strict";
import { firstMismatch, parityReasons } from "./byte-parity.mjs";

test("firstMismatch is -1 for identical buffers", () => {
  assert.equal(firstMismatch(Buffer.from("abc"), Buffer.from("abc")), -1);
});

test("firstMismatch names the first differing offset", () => {
  assert.equal(firstMismatch(Buffer.from("abcd"), Buffer.from("abXd")), 2);
});

test("firstMismatch treats a shorter prefix as differing at its end", () => {
  assert.equal(firstMismatch(Buffer.from("abc"), Buffer.from("ab")), 2);
  assert.equal(firstMismatch(Buffer.from("ab"), Buffer.from("abc")), 2);
});

test("parityReasons is empty for equal buffers and names sizes otherwise", () => {
  assert.deepEqual(parityReasons(Buffer.from("x"), Buffer.from("x")), []);
  assert.deepEqual(parityReasons(Buffer.from("xy"), Buffer.from("x")), ["first difference at byte 1 (crate 2 B, wasm 1 B)"]);
});
