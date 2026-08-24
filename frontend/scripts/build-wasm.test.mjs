import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { INSTALL_URL, buildFailure } from "./build-wasm.mjs";

const script = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "build-wasm.mjs");

test("buildFailure names wasm-pack and the installer URL when the binary is absent", () => {
  const message = buildFailure({ error: Object.assign(new Error("spawn wasm-pack ENOENT"), { code: "ENOENT" }) });
  assert.match(message, /wasm-pack/);
  assert.ok(message.includes(INSTALL_URL));
  assert.equal(message.includes("\n"), false);
});

test("buildFailure reports a non-zero wasm-pack exit", () => {
  assert.match(buildFailure({ status: 101 }), /status 101/);
});

test("buildFailure is null on success", () => {
  assert.equal(buildFailure({ status: 0 }), null);
});

// AC: with wasm-pack removed from PATH, the build exits non-zero and prints
// wasm-pack plus an install URL. An empty PATH makes the binary unfindable.
test("build-wasm exits non-zero with the install hint when wasm-pack is absent from PATH", () => {
  const result = spawnSync(process.execPath, [script], { env: { PATH: "" }, encoding: "utf8" });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /wasm-pack/);
  assert.ok(result.stderr.includes(INSTALL_URL));
  assert.doesNotMatch(result.stderr, /\n\s+at /, "hint must be one line, not a stack trace");
});
