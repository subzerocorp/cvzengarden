import { test } from "node:test";
import assert from "node:assert/strict";
import { foreignRequests, requestsSince } from "./request-log.mjs";

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
