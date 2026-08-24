import { test } from "node:test";
import assert from "node:assert/strict";
import { countDifferingPixels, differsFrom } from "./pixels.mjs";

const BG = { r: 7, g: 11, b: 20 };

test("differsFrom is false at exactly the threshold and true one step past it", () => {
  assert.equal(differsFrom({ r: 39, g: 11, b: 20 }, BG, 32), false);
  assert.equal(differsFrom({ r: 40, g: 11, b: 20 }, BG, 32), true);
});

test("differsFrom fires on any single channel", () => {
  assert.equal(differsFrom({ r: 7, g: 11, b: 200 }, BG, 32), true);
});

test("countDifferingPixels counts RGBA quads and ignores alpha", () => {
  const bytes = Uint8Array.from([7, 11, 20, 255, 215, 224, 234, 255, 7, 11, 20, 0]);
  assert.equal(countDifferingPixels(bytes, BG, 32), 1);
});

test("countDifferingPixels of an empty buffer is 0", () => {
  assert.equal(countDifferingPixels(new Uint8Array(0), BG, 32), 0);
});
