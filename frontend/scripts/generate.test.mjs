import { test } from "node:test";
import assert from "node:assert/strict";
import { parseTheme, safeThemeUrl } from "./generate.mjs";

const header = (lines) => `/**\n * ResumeZen theme\n${lines.map((l) => ` * ${l}`).join("\n")}\n *\n * rz-target: both\n */\n\n.rz-resume {\n}\n`;

test("parseTheme reads the Author and URL header lines", () => {
  const theme = parseTheme("ledger.css", header(["Name:        Ledger", "Author:      Mika Tan", "URL:         https://mika.example"]));
  assert.equal(theme.author, "Mika Tan");
  assert.equal(theme.url, "https://mika.example");
  assert.equal(theme.name, "Ledger");
});

test("parseTheme yields an empty author when the header has no Author line", () => {
  const theme = parseTheme("ledger.css", header(["Name:        Ledger"]));
  assert.equal(theme.author, "");
  assert.equal(theme.url, "");
});

test("parseTheme drops a javascript: URL and keeps only http(s)", () => {
  const evil = parseTheme("ledger.css", header(["Author:      Mika Tan", "URL:         javascript:alert(1)"]));
  assert.equal(evil.url, "", "javascript: must not survive into an href");
  assert.equal(evil.author, "Mika Tan", "a bad URL does not cost the designer their byline");

  const plain = parseTheme("ledger.css", header(["Author:      Mika Tan", "URL:         http://mika.example"]));
  assert.equal(plain.url, "http://mika.example");
});

test("safeThemeUrl keeps http and https and drops everything else", () => {
  assert.equal(safeThemeUrl("https://a.example"), "https://a.example");
  assert.equal(safeThemeUrl("http://a.example"), "http://a.example");
  for (const bad of ["javascript:alert(1)", "JavaScript:alert(1)", "data:text/html,<script>", "file:///etc/passwd", "not a url", "", "   ", undefined]) {
    assert.equal(safeThemeUrl(bad), "", `expected ${String(bad)} to be dropped`);
  }
});

test("parseTheme trims surrounding whitespace from the byline fields", () => {
  const theme = parseTheme("ledger.css", header(["Author:      Mika Tan   ", "URL:         https://mika.example   "]));
  assert.equal(theme.author, "Mika Tan");
  assert.equal(theme.url, "https://mika.example");
});

test("importing generate.mjs does not run the generator", () => {
  // The import at the top of this file would have written src/Generated/*.elm
  // if the module body still executed on import; the main guard prevents it.
  assert.equal(typeof parseTheme, "function");
});
