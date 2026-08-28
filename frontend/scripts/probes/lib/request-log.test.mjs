import { test } from "node:test";
import assert from "node:assert/strict";
import { foreignRequests, offGardenRequests, requestsSince } from "./request-log.mjs";

const origin = "http://127.0.0.1:4310";

test("foreignRequests keeps same-origin static assets out", () => {
  assert.deepEqual(foreignRequests([`${origin}/`, `${origin}/wasm/x_bg.wasm`], origin), []);
});

test("foreignRequests flags third-party hosts and /api on the origin", () => {
  const urls = [`${origin}/api/render`, "https://cdn.example/x.js", `${origin}/themes/quarto.css`];
  assert.deepEqual(foreignRequests(urls, origin), [`${origin}/api/render`, "https://cdn.example/x.js"]);
});

test("requestsSince returns only the entries after the mark", () => {
  assert.deepEqual(requestsSince(["a", "b", "c"], 2), ["c"]);
});

test("offGardenRequests keeps page assets and Theme sheets", () => {
  const urls = [`${origin}/`, `${origin}/wasm/x_bg.wasm`, `${origin}/themes/quarto.css`, `${origin}/themes/fonts/syne/latin-700-normal.woff2`, `${origin}/sandbox.html`, `${origin}/clipboard.js`, `${origin}/garden-query.js`];
  assert.deepEqual(offGardenRequests(urls, origin), []);
});

test("offGardenRequests flags skeleton JSON, /api, and third-party hosts", () => {
  const urls = [`${origin}/skeleton/resume.json`, `${origin}/api/render`, "https://cdn.example/x.js", `${origin}/themes/quarto.css`];
  assert.deepEqual(offGardenRequests(urls, origin), [`${origin}/skeleton/resume.json`, `${origin}/api/render`, "https://cdn.example/x.js"]);
});
