import { test } from "node:test";
import assert from "node:assert/strict";
import { LOAD_FAILURE_MESSAGE, plainMessage, renderedParts } from "./render.js";

test("plainMessage passes a thrown string through (wasm-bindgen Err shape)", () => {
  assert.equal(plainMessage("not a valid JSON Resume document: EOF at line 1 column 1"), "not a valid JSON Resume document: EOF at line 1 column 1");
});

test("plainMessage takes the message of an Error, not its stack", () => {
  assert.equal(plainMessage(new TypeError("boom")), "boom");
});

test("load failure message names the renderer in plain words with no stack marker", () => {
  assert.match(LOAD_FAILURE_MESSAGE, /renderer/);
  assert.equal(LOAD_FAILURE_MESSAGE.includes("at "), false);
});

test("renderedParts returns the document title and its article", () => {
  const article = { tag: "article" };
  const rendered = { title: "Ada Lovelace", querySelector: (selector) => (selector === "article.rz-resume" ? article : null) };
  assert.deepEqual(renderedParts(rendered), { title: "Ada Lovelace", article });
});

test("renderedParts rejects a document without an article", () => {
  assert.throws(() => renderedParts({ title: "", querySelector: () => null }), /no article\.rz-resume/);
});
