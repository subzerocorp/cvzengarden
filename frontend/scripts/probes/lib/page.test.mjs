import { test } from "node:test";
import assert from "node:assert/strict";
import { extractArticle } from "./page.mjs";

test("extractArticle returns the rz-resume article including its tags", () => {
  const html = '<html><body><p>x</p><article class="rz-resume" lang="en"><h1>Hi</h1></article><script></script></body></html>';
  assert.equal(extractArticle(html), '<article class="rz-resume" lang="en"><h1>Hi</h1></article>');
});

test("extractArticle throws when the document has no rz-resume article", () => {
  assert.throws(() => extractArticle("<html><body></body></html>"), /no <article class="rz-resume">/);
});
