import { test } from "node:test";
import assert from "node:assert/strict";
import { articleReasons, rejectionReasons, stackReasons, swapReasons } from "./zg-4.mjs";

test("rejectionReasons accepts a rejection whose message has the required word", () => {
  assert.deepEqual(rejectionReasons({ ok: false, message: "The renderer could not be loaded." }, "renderer"), []);
});

test("rejectionReasons flags a missing word and a message-less rejection", () => {
  assert.equal(rejectionReasons({ ok: false, message: "TypeError: x" }, "renderer").length, 1);
  assert.equal(rejectionReasons({ ok: false }, "renderer").length, 1);
});

test("stackReasons flags a stack frame and accepts plain words", () => {
  assert.equal(stackReasons("TypeError: x\n    at init (wasm.js:3)").length, 1);
  assert.deepEqual(stackReasons("The renderer could not be loaded in this browser."), []);
});

test("rejectionReasons flags a resolved outcome", () => {
  assert.deepEqual(rejectionReasons({ ok: true, html: "<x>" }, "line 1"), ["render resolved instead of rejecting"]);
});

const before = { src: "sandbox.html", themeHref: "themes/nightgarden.css" };
const ada = { src: "sandbox.html", themeHref: "themes/nightgarden.css", name: "Ada Lovelace", title: "Ada Lovelace", hasJordan: false };

test("swapReasons is empty when Ada replaced Jordan in an untouched frame", () => {
  assert.deepEqual(swapReasons(before, ada), []);
});

test("swapReasons catches a stub that left Jordan in place or touched the Theme link", () => {
  assert.equal(swapReasons(before, { ...ada, name: "Jordan Hale", hasJordan: true }).length, 2);
  assert.equal(swapReasons(before, { ...ada, themeHref: "themes/quarto.css" }).length, 1);
  assert.equal(swapReasons(before, { ...ada, src: "blob:x" }).length, 1);
});

test("articleReasons wants the sandbox article byte-equal to the rendered one", () => {
  assert.deepEqual(articleReasons("<article class=\"rz-resume\">a</article>", "<article class=\"rz-resume\">a</article>"), []);
  assert.equal(articleReasons("<article class=\"rz-resume\">a</article>", "<article class=\"rz-resume\">b</article>").length, 1);
  assert.equal(articleReasons("<article class=\"rz-resume\">a</article>", undefined).length, 1);
});
