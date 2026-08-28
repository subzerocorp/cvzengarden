import { test } from "node:test";
import assert from "node:assert/strict";
import { barL1PairReasons, fontsLoadReasons, thirdPartyRequests } from "./lib/theme-fonts.mjs";

test("ZG-13 re-exports keep BAR-L1 and fonts-load calculations stable", () => {
  assert.equal(thirdPartyRequests(["http://127.0.0.1/x", "https://cdn.jsdelivr.net/x"]).length, 1);
  assert.deepEqual(fontsLoadReasons([{ family: "Syne", status: "loaded" }], "Syne"), []);
  assert.equal(
    barL1PairReasons({ color: "a", fontFamily: "x" }, { color: "b", fontFamily: "x" }, "pair").length,
    0,
  );
});
