/**
 * Build the renderer Wasm module into frontend/static/wasm (gitignored).
 *
 * `wasm-pack` is the only tool involved; when it is absent from PATH the
 * build stops with a one-line install hint instead of a stack trace.
 */
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const frontendDir = path.resolve(__dirname, "..");
const crateDir = path.resolve(frontendDir, "..", "renderer-wasm");
const outDir = path.join(frontendDir, "static", "wasm");

export const INSTALL_URL = "https://rustwasm.github.io/wasm-pack/installer/";

// Calculation: the one-line message for a failed wasm-pack spawn, or null on success.
export function buildFailure(result) {
  if (result.error?.code === "ENOENT") {
    return `wasm-pack not found on PATH; install it from ${INSTALL_URL} and re-run npm run build`;
  }
  if (result.error) {
    return `wasm-pack could not start: ${result.error.message}`;
  }
  return result.status === 0 ? null : `wasm-pack exited with status ${result.status}`;
}

function runWasmPack() {
  return spawnSync("wasm-pack", ["build", "--target", "web", crateDir, "--out-dir", outDir], {
    stdio: "inherit",
  });
}

function main() {
  const failure = buildFailure(runWasmPack());
  if (failure) {
    console.error(failure);
    process.exit(1);
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
