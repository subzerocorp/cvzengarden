import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { parseTheme, safeThemeUrl, suspectThemeHost } from "./generate.mjs";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const generator = path.join(scriptsDir, "generate.mjs");
const themesElm = path.resolve(scriptsDir, "..", "src", "Generated", "Themes.elm");

const header = (lines) => `/* rz-target: both */\n\n/**\n * ResumeZen theme\n${lines.map((l) => ` * ${l}`).join("\n")}\n */\n\n.rz-resume {\n}\n`;

test("parseTheme reads the Author and URL header lines", () => {
  const theme = parseTheme("ledger.css", header(["Name:        Ledger", "Author:      Mika Tan", "URL:         https://mika.example"]));
  assert.equal(theme.author, "Mika Tan");
  // The URL parser's canonical form of the header's `https://mika.example`.
  assert.equal(theme.url, "https://mika.example/");
  assert.equal(theme.name, "Ledger");
});

test("parseTheme yields an empty author when the header has no Author line", () => {
  const theme = parseTheme("ledger.css", header(["Name:        Ledger"]));
  assert.equal(theme.author, "");
  assert.equal(theme.url, "");
  assert.equal(theme.droppedUrl, "");
});

test("parseTheme drops a javascript: URL and keeps only http(s)", () => {
  const evil = parseTheme("ledger.css", header(["Author:      Mika Tan", "URL:         javascript:alert(1)"]));
  assert.equal(evil.url, "", "javascript: must not survive into an href");
  assert.equal(evil.author, "Mika Tan", "a bad URL does not cost the designer their byline");

  const plain = parseTheme("ledger.css", header(["Author:      Mika Tan", "URL:         http://mika.example"]));
  assert.equal(plain.url, "http://mika.example/");
});

test("parseTheme reports a dropped URL so the build can warn about a typo", () => {
  const typo = parseTheme("ledger.css", header(["Author:      Mika Tan", "URL:         mika.example"]));
  assert.equal(typo.url, "", "a schemeless URL is not a link we will render");
  assert.equal(typo.droppedUrl, "mika.example", "the raw text survives for the build warning");
});

test("safeThemeUrl keeps http and https and drops everything else", () => {
  assert.equal(safeThemeUrl("https://a.example"), "https://a.example/");
  assert.equal(safeThemeUrl("http://a.example"), "http://a.example/");
  for (const bad of ["javascript:alert(1)", "JavaScript:alert(1)", "data:text/html,<script>", "file:///etc/passwd", "not a url", "", "   ", undefined]) {
    assert.equal(safeThemeUrl(bad), "", `expected ${String(bad)} to be dropped`);
  }
});

test("safeThemeUrl returns the parser's own href, not the raw input", () => {
  // Whatever the URL parser normalised away must not ride along into the href.
  assert.equal(safeThemeUrl("https://a.example/a b"), "https://a.example/a%20b");
  assert.equal(safeThemeUrl("HTTPS://A.example/Path"), "https://a.example/Path");
});

test("suspectThemeHost flags a kept URL whose host is not a domain", () => {
  // The scheme filter passes these: the URL parser reads a special scheme with
  // no `//` as a host, so they ship as live links that resolve for nobody.
  assert.equal(suspectThemeHost(safeThemeUrl("https:alert(1)")), "alert(1)");
  assert.equal(suspectThemeHost(safeThemeUrl("http:evil")), "evil");
  assert.equal(suspectThemeHost("https://intranet/"), "intranet");
});

test("suspectThemeHost is silent on hosts a reader can reach", () => {
  for (const fine of [
    "https://mika.example/",
    "http://a.b.c.example/path",
    "http://127.0.0.1:8080/",
    "http://localhost:3000/",
    "http://dev.localhost/",
    "http://[::1]/",
    "",
  ]) {
    assert.equal(suspectThemeHost(fine), "", `expected ${fine || "(empty)"} to pass unremarked`);
  }
});

test("parseTheme reports a suspect host so the build can warn, and still links it", () => {
  const degenerate = parseTheme("ledger.css", header(["Author:      Mika Tan", "URL:         https:alert(1)"]));
  assert.equal(degenerate.url, "https://alert(1)/", "the scheme filter kept it, so the href is the parser's own");
  assert.equal(degenerate.suspectHost, "alert(1)");
  assert.equal(degenerate.droppedUrl, "", "it was not dropped — the warning is the whole remedy");

  const good = parseTheme("ledger.css", header(["Author:      Mika Tan", "URL:         https://mika.example"]));
  assert.equal(good.suspectHost, "");
});

test("parseTheme trims surrounding whitespace from the byline fields", () => {
  const theme = parseTheme("ledger.css", header(["Author:      Mika Tan   ", "URL:         https://mika.example   "]));
  assert.equal(theme.author, "Mika Tan");
  assert.equal(theme.url, "https://mika.example/");
});

test("parseTheme reads rz-target only from its own comment, not the doc block", () => {
  assert.equal(parseTheme("ledger.css", header(["Name: Ledger"])).target, "Both");
  assert.equal(parseTheme("ledger.css", "/* rz-target: print */\n\n/**\n * Name: Ledger\n */\n").target, "Print");
  // The form themes/README.md must never teach: inside the block it is prose.
  assert.equal(parseTheme("ledger.css", "/**\n * Name: Ledger\n *\n * rz-target: print\n */\n").target, "Both");
});

// The main() guard is what lets the tests above import the generator. Assert it
// by observation: a child process that only imports the module must neither
// announce a run nor touch the catalog it would have rewritten.
test("importing generate.mjs does not run the generator", () => {
  const before = fs.readFileSync(themesElm);
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "zg16-import-"));
  try {
    const importer = path.join(dir, "importer.mjs");
    fs.writeFileSync(importer, `import ${JSON.stringify(pathToFileURL(generator).href)};\n`);
    const result = spawnSync(process.execPath, [importer], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.doesNotMatch(result.stdout, /Generated \d+ theme\(s\)/, "importing the module ran main()");
    assert.deepEqual(fs.readFileSync(themesElm), before, "importing the module rewrote src/Generated/Themes.elm");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

// argv[1] is undefined under `node --eval`, where pathToFileURL throws, and the
// ESM loader realpaths the entry, so a symlinked `npm run gen` must still run.
test("the generator runs when invoked through a symlink", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "zg16-symlink-"));
  try {
    const link = path.join(dir, "gen-link.mjs");
    fs.symlinkSync(generator, link);
    const result = spawnSync(process.execPath, [link], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /Generated \d+ theme\(s\)/, "a symlinked invocation must not be a silent no-op");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("--eval does not crash the entry-point guard", () => {
  const result = spawnSync(process.execPath, ["--input-type=module", "--eval", `import ${JSON.stringify(pathToFileURL(generator).href)};`], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.doesNotMatch(result.stdout, /Generated \d+ theme\(s\)/);
});
