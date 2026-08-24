import { test } from "node:test";
import assert from "node:assert/strict";
import {
  SERDE_TOKENS,
  debugOnlyReasons,
  errorReasons,
  oracleReasons,
  pageErrorReasons,
  serdeTokenReasons,
  shownReasons,
  switchedReasons,
  unchangedReasons,
} from "./paste.mjs";

const jordan = { errorClass: null, errorText: "", name: "Jordan Hale", src: "sandbox.html", themeHref: "themes/nightgarden.css" };
const ada = { ...jordan, name: "Ada Lovelace" };

test("SERDE_TOKENS is exactly the six banned tokens from the AC", () => {
  assert.deepEqual(SERDE_TOKENS, ["expected", "EOF", "invalid type", "serde", "Err(", "panicked"]);
});

test("serdeTokenReasons is empty for plain English and names each leaked token", () => {
  assert.deepEqual(serdeTokenReasons("Look at line 1, column 27: there is a comma right before a closing bracket."), []);
  assert.equal(serdeTokenReasons("invalid type: string, expected a sequence").length, 2);
  assert.equal(serdeTokenReasons("There is an unexpected character").length, 1, "'unexpected' contains 'expected'");
  assert.deepEqual(serdeTokenReasons("Expected a value"), [], "case-sensitive: 'Expected' is not 'expected'");
});

test("errorReasons checks the class first, then every required word", () => {
  const trailing = { errorClass: "invalid-json", errorText: "Look at line 1, column 27: there is a comma right before a closing bracket." };
  assert.deepEqual(errorReasons(trailing, { errorClass: "invalid-json", words: ["line 1", "comma"] }), []);
  assert.equal(errorReasons(trailing, { errorClass: "empty" }).length, 1);
  assert.equal(errorReasons(trailing, { errorClass: "invalid-json", words: ["line 2", "comma"] }).length, 1);
  assert.equal(errorReasons({ errorClass: null, errorText: "" }, { errorClass: "empty" }).length, 1);
});

test("errorReasons rejects a forbidden word, so an unlocated message may not name a position", () => {
  const somewhere = { errorClass: "invalid-json", errorText: "This is not quite valid JSON yet, and we could not tell exactly where." };
  assert.deepEqual(errorReasons(somewhere, { errorClass: "invalid-json", words: ["could not tell"], without: ["line "] }), []);
  assert.equal(errorReasons(somewhere, { errorClass: "invalid-json", without: ["could not"] }).length, 1);
});

test("unchangedReasons flags a sandbox that changed on a rejected paste", () => {
  assert.deepEqual(unchangedReasons(jordan, jordan), []);
  assert.equal(unchangedReasons(jordan, ada).length, 1);
});

test("shownReasons passes for Ada in an untouched frame and names each drift", () => {
  assert.deepEqual(shownReasons(jordan, ada, "Ada Lovelace"), []);
  assert.equal(shownReasons(jordan, jordan, "Ada Lovelace").length, 1);
  assert.equal(shownReasons(jordan, { ...ada, errorClass: "render-failed" }, "Ada Lovelace").length, 1);
  assert.equal(shownReasons(jordan, { ...ada, src: "blob:x", themeHref: "themes/quarto.css" }, "Ada Lovelace").length, 2);
});

test("switchedReasons wants both the Theme href and the name", () => {
  const quarto = { ...ada, themeHref: "themes/quarto.css" };
  assert.deepEqual(switchedReasons(quarto, { href: "themes/quarto.css", name: "Ada Lovelace" }), []);
  assert.equal(switchedReasons(ada, { href: "themes/quarto.css", name: "Ada Lovelace" }).length, 1);
  assert.equal(switchedReasons({ ...quarto, name: "Jordan Hale" }, { href: "themes/quarto.css", name: "Ada Lovelace" }).length, 1);
});

test("oracleReasons fails when the crate accepts what the Chrome rejected", () => {
  assert.deepEqual(oracleReasons({ ok: false, message: "…" }), []);
  assert.equal(oracleReasons({ ok: true, html: "<html>" }).length, 1);
});

test("debugOnlyReasons wants the raw error at debug level and nowhere louder", () => {
  const raw = "expected value at line 3 column 1";
  assert.deepEqual(debugOnlyReasons([{ type: "debug", text: `renderer error ${raw}` }], raw), []);
  assert.equal(debugOnlyReasons([], raw).length, 1);
  assert.equal(debugOnlyReasons([{ type: "debug", text: raw }, { type: "error", text: raw }], raw).length, 1);
});

test("pageErrorReasons prefixes each page error", () => {
  assert.deepEqual(pageErrorReasons([]), []);
  assert.deepEqual(pageErrorReasons(["boom"]), ["pageerror: boom"]);
});
