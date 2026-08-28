import { test } from "node:test";
import assert from "node:assert/strict";
import { gardenSearch, isPrintView, readGardenQuery } from "./garden-query.js";

test("gardenSearch sets theme and keeps view, hash, and other params", () => {
  assert.equal(
    gardenSearch("https://garden.example/?view=print&ref=1#top", { theme: "quarto" }),
    "/?view=print&ref=1&theme=quarto#top",
  );
});

test("gardenSearch sets view and keeps an unknown theme", () => {
  assert.equal(
    gardenSearch("https://garden.example/?theme=banana", { view: "print" }),
    "/?theme=banana&view=print",
  );
});

test("gardenSearch can set view=screen without dropping theme", () => {
  assert.equal(
    gardenSearch("https://garden.example/?theme=quarto&view=print", { view: "screen" }),
    "/?theme=quarto&view=screen",
  );
});

test("readGardenQuery treats missing and empty theme as empty strings", () => {
  assert.deepEqual(readGardenQuery(""), { theme: "", view: "" });
  assert.deepEqual(readGardenQuery("?theme="), { theme: "", view: "" });
  assert.deepEqual(readGardenQuery("?theme=banana&view=print"), { theme: "banana", view: "print" });
});

test("isPrintView is only the print token, case-insensitive", () => {
  assert.equal(isPrintView("print"), true);
  assert.equal(isPrintView("PRINT"), true);
  assert.equal(isPrintView(" screen "), false);
  assert.equal(isPrintView("sideways"), false);
  assert.equal(isPrintView(""), false);
});
