/**
 * Serve frontend/dist on 0.0.0.0:$PORT (default 4173).
 */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const distDir = path.resolve(__dirname, "..", "dist");
const port = Number(process.env.PORT || 4173);

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".woff2": "font/woff2",
  ".svg": "image/svg+xml",
  ".wasm": "application/wasm",
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  let filePath = path.join(distDir, decodeURIComponent(url.pathname));
  if (filePath.endsWith("/")) {
    filePath = path.join(filePath, "index.html");
  }

  const resolved = path.resolve(filePath);
  if (!resolved.startsWith(distDir)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.stat(resolved, (err, stat) => {
    if (err || !stat.isFile()) {
      const index = path.join(distDir, "index.html");
      if (resolved === path.join(distDir, "index.html") || err) {
        if (!fs.existsSync(index)) {
          res.writeHead(404);
          res.end("Not found");
          return;
        }
      }
      res.writeHead(404);
      res.end("Not found");
      return;
    }

    res.writeHead(200, {
      "Content-Type": TYPES[path.extname(resolved)] || "application/octet-stream",
      "Cache-Control": "no-store",
    });
    fs.createReadStream(resolved).pipe(res);
  });
});

server.listen(port, "0.0.0.0", () => {
  console.log(`Garden chrome at http://127.0.0.1:${port}/`);
});
