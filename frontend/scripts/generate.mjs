/**
 * Build-time Garden catalog.
 *
 * Reads themes/*.css (never _blank.css, never skeleton/preview.css)
 * and writes src/Generated/Themes.elm plus generated/sandbox.html.
 * Embeds skeleton/resume.json and skeleton/samples/junior.json as
 * Generated.Samples string constants so a sample click issues no HTTP.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const frontendDir = path.resolve(__dirname, "..");
const repoDir = path.resolve(frontendDir, "..");
const themesDir = path.join(repoDir, "themes");
const examplePath = path.join(repoDir, "skeleton", "example.html");

const SKIP = new Set(["_blank.css"]);

function titleFromId(id) {
  return id
    .split(/[-_]/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function parseTheme(fileName, source) {
  const id = fileName.replace(/\.css$/i, "");
  const targetMatch = source.match(/\/\*\s*rz-target:\s*(web|print|both)\s*\*\//i);
  const nameMatch = source.match(/^\s*\*\s*Name:\s*(.+)$/m);
  const targetRaw = (targetMatch?.[1] ?? "both").toLowerCase();
  const target =
    targetRaw === "web" ? "Web" : targetRaw === "print" ? "Print" : "Both";
  const name = (nameMatch?.[1] ?? "").trim() || titleFromId(id);

  return {
    id,
    name,
    href: `themes/${fileName}`,
    target,
  };
}

function elmEscape(value) {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

/** Exact file bytes as a single Elm string literal (preserves `\\n` in JSON). */
function elmStringLiteral(value) {
  return `"${elmEscape(value).replace(/\r/g, "\\r").replace(/\n/g, "\\n")}"`;
}

function writeThemesElm(themes) {
  const records = themes
    .map(
      (theme) => `    { id = "${elmEscape(theme.id)}"
      , name = "${elmEscape(theme.name)}"
      , href = "${elmEscape(theme.href)}"
      , target = ${theme.target}
      }`,
    )
    .join("\n    ,\n");

  const contents = `module Generated.Themes exposing (Target(..), Theme, all, hrefFor, themeById)


{-| Generated from the Garden theme directory. Do not edit by hand — run \`npm run gen\`.
-}


type Target
    = Web
    | Print
    | Both


type alias Theme =
    { id : String
    , name : String
    , href : String
    , target : Target
    }


all : List Theme
all =
    [ ${records.trim()}
    ]


themeById : String -> Maybe Theme
themeById id =
    all
        |> List.filter (\\theme -> theme.id == id)
        |> List.head


hrefFor : String -> Maybe String
hrefFor id =
    themeById id
        |> Maybe.map .href
`;

  const outDir = path.join(frontendDir, "src", "Generated");
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, "Themes.elm"), contents);
}

function writeSandbox(defaultHref) {
  const example = fs.readFileSync(examplePath, "utf8");
  if (/preview\.css/.test(example) === false) {
    throw new Error("skeleton/example.html no longer links preview.css; update the sandbox generator.");
  }

  const sandbox = example
    .replace(
      /<!--[\s\S]*?-->/,
      `<!--
      ResumeZen Garden sandbox (HTML contract v1.0).
      Chrome swaps #theme-stylesheet href and, for a pasted résumé, article.rz-resume (crate output only).
    -->`,
    )
    .replace(
      /<link rel="stylesheet" href="preview\.css">/,
      `<link id="theme-stylesheet" rel="stylesheet" href="${defaultHref}">`,
    );

  if (/preview\.css/.test(sandbox)) {
    throw new Error("sandbox still references preview.css");
  }

  const outDir = path.join(frontendDir, "generated");
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, "sandbox.html"), sandbox);
}

const files = fs
  .readdirSync(themesDir)
  .filter((name) => name.endsWith(".css") && !SKIP.has(name))
  .sort((a, b) => a.localeCompare(b));

if (files.length === 0) {
  throw new Error("No Garden themes found in themes/*.css");
}

const themes = files.map((fileName) => {
  const source = fs.readFileSync(path.join(themesDir, fileName), "utf8");
  return parseTheme(fileName, source);
});

const defaultTheme = themes.find((theme) => theme.id === "nightgarden") ?? themes[0];

function writeSamplesElm() {
  const jordanPath = path.join(repoDir, "skeleton", "resume.json");
  const juniorPath = path.join(repoDir, "skeleton", "samples", "junior.json");
  const jordan = fs.readFileSync(jordanPath, "utf8");
  const junior = fs.readFileSync(juniorPath, "utf8");
  const contents = `module Generated.Samples exposing (jordan, junior)


{-| Generated from skeleton sample files. Do not edit by hand — run \`npm run gen\`.
-}


jordan : String
jordan =
    ${elmStringLiteral(jordan)}


junior : String
junior =
    ${elmStringLiteral(junior)}
`;

  const outDir = path.join(frontendDir, "src", "Generated");
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, "Samples.elm"), contents);
}

writeThemesElm(themes);
writeSamplesElm();
writeSandbox(defaultTheme.href);

console.log(
  `Generated ${themes.length} theme(s): ${themes.map((theme) => theme.id).join(", ")}; embedded jordan + junior samples`,
);
