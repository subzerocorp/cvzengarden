/**
 * Assemble the static Garden site. Chrome files stay free of rz-* and
 * never link skeleton/preview.css. Theme CSS is copied from themes/.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const frontendDir = path.resolve(__dirname, "..");
const repoDir = path.resolve(frontendDir, "..");
const distDir = path.join(frontendDir, "dist");
const themesDir = path.join(repoDir, "themes");

fs.mkdirSync(distDir, { recursive: true });

function copyFile(from, to) {
  fs.mkdirSync(path.dirname(to), { recursive: true });
  fs.copyFileSync(from, to);
}

copyFile(path.join(frontendDir, "static", "index.html"), path.join(distDir, "index.html"));
copyFile(path.join(frontendDir, "static", "ports.js"), path.join(distDir, "ports.js"));
copyFile(path.join(frontendDir, "static", "clipboard.js"), path.join(distDir, "clipboard.js"));
copyFile(path.join(frontendDir, "static", "garden-query.js"), path.join(distDir, "garden-query.js"));
copyFile(path.join(frontendDir, "static", "render.js"), path.join(distDir, "render.js"));
copyFile(path.join(frontendDir, "css", "chrome.css"), path.join(distDir, "chrome.css"));
copyFile(
  path.join(frontendDir, "generated", "sandbox.html"),
  path.join(distDir, "sandbox.html"),
);

const themeOut = path.join(distDir, "themes");
fs.mkdirSync(themeOut, { recursive: true });

for (const name of fs.readdirSync(themesDir)) {
  if (!name.endsWith(".css") || name === "_blank.css") {
    continue;
  }
  copyFile(path.join(themesDir, name), path.join(themeOut, name));
}

// Wasm glue + binary from `npm run build`'s wasm-pack step (never committed).
const wasmDir = path.join(frontendDir, "static", "wasm");
if (!fs.existsSync(wasmDir)) {
  throw new Error("static/wasm is missing: run `node scripts/build-wasm.mjs` (npm run build does)");
}
for (const name of fs.readdirSync(wasmDir)) {
  if (name.endsWith(".js") || name.endsWith("_bg.wasm")) {
    copyFile(path.join(wasmDir, name), path.join(distDir, "wasm", name));
  }
}

if (fs.existsSync(path.join(distDir, "preview.css"))) {
  throw new Error("dist must not contain preview.css");
}
