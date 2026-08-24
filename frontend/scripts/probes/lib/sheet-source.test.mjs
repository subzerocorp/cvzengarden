import { test } from "node:test";
import assert from "node:assert/strict";
import { gitSheets, liveSheets, sheetSourceFor, sheetSuffix } from "./sheet-source.mjs";

test("sheetSourceFor picks the live sheets when no revision is set", () => {
  assert.equal(sheetSourceFor("/repo", undefined).label, null);
  assert.equal(sheetSourceFor("/repo", "").label, null);
});

test("sheetSourceFor labels a git source with its revision", () => {
  assert.equal(sheetSourceFor("/repo", "abc123").label, "abc123");
});

test("sheetSuffix is empty for live sheets and names the revision otherwise", () => {
  assert.equal(sheetSuffix(liveSheets("/repo")), "");
  assert.equal(sheetSuffix(gitSheets("/repo", "abc123")), " [sheet abc123]");
});
