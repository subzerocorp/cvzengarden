/**
 * ZG-5 probes: an Author pastes or opens a JSON Resume, sees it in every
 * Theme, gets a plain-English sentence when the file is wrong, and has
 * the last accepted résumé restored from localStorage on reload.
 *
 * Every probe opens its own Garden page. The runner owns reporting; this
 * module only calls the injected `pass` / `fail`. `beforeNavigate` in the
 * context is the anti-stub seam (a route that serves a stubbed ports.js).
 */
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { openGarden } from "./lib/page.mjs";
import {
  debugOnlyReasons,
  errorReasons,
  forgottenReasons,
  oracleReasons,
  pageErrorReasons,
  serdeTokenReasons,
  shownReasons,
  silentRestoreReasons,
  switchedReasons,
  unchangedReasons,
} from "./lib/paste.mjs";
import { offGardenRequests, requestsSince } from "./lib/request-log.mjs";

const NOT_A_RESUME = '{"basics":{"name":"E"},"work":"nope"}';
const MISSING_NAME = '{"basics":{"label":"Junior Developer"}}';
const RENDER_FAILURE = "expected value at line 3 column 1";
const QUARTO_HREF = "themes/quarto.css";

// One page, one row per scanner path. `words` must all appear in the
// sentence (the position is asserted as one string so an off-by-one on
// either number fails); `without` must not.
const SCANNER_ROWS = [
  { label: "unquoted value on line 3", text: '{\n"basics": {\n"name": Elena\n}\n}', expected: { errorClass: "invalid-json", words: ["line 3, column 9", "quotes"] } },
  { label: "unterminated string at its opening quote", text: '{\n"basics": {"name": "Elena\n}}', expected: { errorClass: "invalid-json", words: ["line 2, column 20", "never closes"] } },
  { label: "truncated", text: '{"basics":{"name":"E"}', expected: { errorClass: "invalid-json", words: ["line 1, column 23", "ends before"] } },
  { label: "stray after the value", text: '{"basics":{"name":"E"}} x', expected: { errorClass: "invalid-json", words: ["line 1, column 25", "cannot read"] } },
  { label: "missing comma between members", text: '{"basics":{"name":"E"} "work":[]}', expected: { errorClass: "invalid-json", words: ["line 1, column 24", "cannot read"] } },
  { label: "trailing comma before ] on line 2", text: '{"basics":{"name":"E"},\n"work":[1,]}', expected: { errorClass: "invalid-json", words: ["line 2, column 11", "comma"] } },
  { label: "leading zero", text: '{"basics":{"name":"E"},"n":01}', expected: { errorClass: "invalid-json", words: ["line 1, column 28", "number"] } },
  { label: "lone minus", text: '{"basics":{"name":"E"},"n":-}', expected: { errorClass: "invalid-json", words: ["line 1, column 28", "number"] } },
  { label: "bad escape", text: '{"basics":{"name":"E\\x"}}', expected: { errorClass: "invalid-json", words: ["line 1, column 21", "backslash"] } },
  { label: "non-object top level []", text: "[]", expected: { errorClass: "missing-name", words: ["name"] } },
  { label: "1.2 MB invalid list (fault past the window)", text: `[${"1,".repeat(600000)}x`, expected: { errorClass: "invalid-json", words: ["could not tell"], without: ["line "] } },
  { label: "1.2 MB invalid object (fault inside the window)", text: `{"n":01,${'"a":1,'.repeat(200000)}}`, expected: { errorClass: "invalid-json", words: ["line 1, column 6", "number"] } },
  { label: "10,000 nested [", text: "[".repeat(10000), expected: { errorClass: "invalid-json", words: ["could not tell"], without: ["line "] } },
];

function readFixture(dir, name) {
  return fs.readFileSync(path.join(dir, name), "utf8");
}

// Runs in the page: what the Author and the sandbox show right now.
export function readPasteState() {
  const iframe = document.getElementById("garden-frame");
  const doc = iframe.contentDocument;
  const error = document.querySelector("[data-paste-error]");
  return {
    errorClass: error?.getAttribute("data-paste-error") ?? null,
    errorText: error?.textContent ?? "",
    name: doc.querySelector(".rz-name")?.textContent ?? null,
    schema: doc.querySelector(".rz-resume")?.getAttribute("data-rz-schema") ?? null,
    hasJordan: doc.documentElement.outerHTML.includes("Jordan Hale"),
    src: iframe.getAttribute("src"),
    themeHref: doc.getElementById("theme-stylesheet")?.getAttribute("href") ?? null,
    title: doc.title,
  };
}

// Runs in the page: awaits the renderer seam and reports the outcome as data.
function renderOutcome(json) {
  return window.resumezen.render(json).then(
    (html) => ({ ok: true, html }),
    (failure) => ({ ok: false, message: failure.message }),
  );
}

// Runs in the page: the panel settled on a new attempt.
export function pasteSettled(previousAttempt) {
  const panel = document.querySelector(".paste");
  const status = panel?.getAttribute("data-paste-status");
  return panel?.getAttribute("data-paste-attempt") !== previousAttempt && (status === "shown" || status === "failed");
}

export async function openPanel(page) {
  const toggle = page.getByRole("button", { name: "Use my résumé" });
  if ((await toggle.getAttribute("aria-expanded")) !== "true") {
    await toggle.click();
  }
  await page.locator("#paste-input").waitFor({ state: "visible" });
}

// Pastes `text`, presses "Show it", and waits for the panel to settle.
export async function paste(page, text) {
  await openPanel(page);
  await page.fill("#paste-input", text);
  const attempt = await page.locator(".paste").getAttribute("data-paste-attempt");
  await page.getByRole("button", { name: "Show it" }).click();
  await page.waitForFunction(pasteSettled, attempt);
  return page.evaluate(readPasteState);
}

export async function waitForName(page, name) {
  await page
    .frameLocator("#garden-frame")
    .locator(".rz-name", { hasText: name })
    .waitFor({ timeout: 5000 })
    .catch(() => undefined);
}

async function waitSettled(page, attempt) {
  await page.waitForFunction(pasteSettled, attempt);
  return page.evaluate(readPasteState);
}

async function openFile(page, filePath) {
  await openPanel(page);
  const attempt = await page.locator(".paste").getAttribute("data-paste-attempt");
  await page.locator("input[type=file]").setInputFiles(filePath);
  return waitSettled(page, attempt);
}

async function dropFile(page, filePath) {
  await openPanel(page);
  const name = path.basename(filePath);
  const bytes = Array.from(fs.readFileSync(filePath));
  const attempt = await page.locator(".paste").getAttribute("data-paste-attempt");
  await page.evaluate(
    ({ name, bytes }) => {
      const zone = document.querySelector("[data-drop-zone]");
      const file = new File([new Uint8Array(bytes)], name);
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file);
      const event = new Event("drop", { bubbles: true, cancelable: true });
      Object.defineProperty(event, "dataTransfer", { value: dataTransfer });
      zone.dispatchEvent(event);
    },
    { name, bytes },
  );
  return waitSettled(page, attempt);
}

function noteSerde(report, label, errorText) {
  const tokens = serdeTokenReasons(errorText);
  if (tokens.length) {
    report.fail(`ZG-5/no-serde-tokens ${label}: ${tokens.join("; ")}`);
  }
  return tokens.length === 0;
}

function reportReasons(report, label, reasons, passText) {
  if (reasons.length) {
    report.fail(`${label} ${reasons.join("; ")}`);
  } else {
    report.pass(`${label} ${passText}`);
  }
}

async function sampleProbe({ browser, origin, report, repoDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const before = await page.evaluate(readPasteState);
  const after = await paste(page, readFixture(repoDir, "skeleton/resume.json"));
  await page.close();
  const reasons = [
    ...shownReasons(before, after, "Jordan Hale"),
    ...(after.schema === "1.0" ? [] : [`data-rz-schema is ${after.schema}`]),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/paste-sample", reasons, `skeleton/resume.json shows .rz-name ${JSON.stringify(after.name)} with data-rz-schema="1.0" and no [data-paste-error]`);
}

async function adaProbe({ browser, origin, report, frontendDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const before = await page.evaluate(readPasteState);
  await paste(page, readFixture(frontendDir, "fixtures/ada.json"));
  await waitForName(page, "Ada Lovelace");
  const after = await page.evaluate(readPasteState);
  await page.close();
  const reasons = [
    ...shownReasons(before, after, "Ada Lovelace"),
    ...(after.hasJordan ? ["iframe document still contains Jordan Hale"] : []),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/paste-ada", reasons, `ada.json shows .rz-name "Ada Lovelace"; no Jordan Hale in the iframe; src ${after.src}; #theme-stylesheet ${after.themeHref} unchanged`);
}

async function thenSwitchProbe({ browser, origin, report, frontendDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  await paste(page, readFixture(frontendDir, "fixtures/ada.json"));
  await waitForName(page, "Ada Lovelace");

  await page.click("#theme-option-quarto");
  await page.waitForFunction((href) => {
    const link = document.getElementById("garden-frame").contentDocument.getElementById("theme-stylesheet");
    return link?.getAttribute("href") === href && link.sheet?.cssRules?.length > 0;
  }, QUARTO_HREF);
  const switched = await page.evaluate(readPasteState);

  await page.getByRole("button", { name: "Print preview" }).click();
  await page.waitForSelector('.app-shell[data-preview="print"]');
  const previewed = await page.evaluate(readPasteState);
  await page.close();

  const reasons = [
    ...switchedReasons(switched, { href: QUARTO_HREF, name: "Ada Lovelace" }).map((reason) => `after Quarto: ${reason}`),
    ...switchedReasons(previewed, { href: QUARTO_HREF, name: "Ada Lovelace" }).map((reason) => `in Print preview: ${reason}`),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/paste-then-switch", reasons, `after the Ada paste, Quarto sets #theme-stylesheet ${switched.themeHref} with .rz-name "Ada Lovelace"; Print preview still shows "Ada Lovelace"`);
}

// The five error probes share this: the panel shows the class with the
// words, the sandbox is untouched, and the text carries no serde token.
async function errorProbe(context, label, text, expected, extra = async () => []) {
  const { browser, origin, report, beforeNavigate } = context;
  const { page, pageErrors, consoleMessages } = await openGarden(browser, origin, { beforeNavigate });
  const before = await page.evaluate(readPasteState);
  const after = await paste(page, text);
  const extraReasons = await extra(page, { after, consoleMessages });
  await page.close();
  const reasons = [...errorReasons(after, expected), ...unchangedReasons(before, after), ...extraReasons, ...pageErrorReasons(pageErrors)];
  reportReasons(report, label, reasons, `[data-paste-error="${after.errorClass}"] says ${JSON.stringify(after.errorText)}; .rz-name still ${JSON.stringify(after.name)}`);
  const tokens = serdeTokenReasons(after.errorText);
  if (tokens.length) {
    report.fail(`ZG-5/no-serde-tokens ${label}: ${tokens.join("; ")}`);
  }
  return tokens.length === 0;
}

async function emptyProbe(context) {
  const { browser, origin, report, beforeNavigate } = context;
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const before = await page.evaluate(readPasteState);
  const outcomes = [];
  for (const text of ["", "   \n"]) {
    const after = await paste(page, text);
    outcomes.push({ text, after });
  }
  await page.close();
  const reasons = outcomes.flatMap(({ text, after }) =>
    [...errorReasons(after, { errorClass: "empty" }), ...unchangedReasons(before, after)].map((reason) => `${JSON.stringify(text)}: ${reason}`),
  );
  const last = outcomes.at(-1).after;
  reportReasons(report, "ZG-5/paste-empty", [...reasons, ...pageErrorReasons(pageErrors)], `"" and "   \\n" both show [data-paste-error="empty"] saying ${JSON.stringify(last.errorText)}; .rz-name still ${JSON.stringify(last.name)}`);
  const tokens = outcomes.flatMap(({ after }) => serdeTokenReasons(after.errorText));
  if (tokens.length) {
    report.fail(`ZG-5/no-serde-tokens ZG-5/paste-empty: ${tokens.join("; ")}`);
  }
  return tokens.length === 0;
}

function positionPhrase(text) {
  return text.match(/line \d+, column \d+/)?.[0] ?? "no position";
}

// Every scanner path on one page: class, position (or none) and the
// distinguishing word, with the serde-token check on each row.
async function scannerHintsProbe({ browser, origin, report, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const rows = [];
  for (const row of SCANNER_ROWS) {
    const after = await paste(page, row.text);
    rows.push({ ...row, after });
  }
  await page.close();
  const reasons = rows.flatMap(({ label, after, expected }) => errorReasons(after, expected).map((reason) => `${label}: ${reason}`));
  reportReasons(report, "ZG-5/scanner-hints", [...reasons, ...pageErrorReasons(pageErrors)], `${rows.length} rows each show their class, position and hint (${rows.map(({ label, after }) => `${label} → ${after.errorClass} ${positionPhrase(after.errorText)}`).join("; ")}); no pageerror`);
  const tokens = rows.flatMap(({ label, after }) => serdeTokenReasons(after.errorText).map((reason) => `${label}: ${reason}`));
  if (tokens.length) {
    report.fail(`ZG-5/no-serde-tokens ZG-5/scanner-hints: ${tokens.join("; ")}`);
  }
  return tokens.length === 0;
}

// The crate must reject what the Chrome rejected (the crate is the oracle).
async function crateRejects(page, text) {
  const outcome = await page.evaluate(renderOutcome, text);
  return oracleReasons(outcome);
}

async function renderFailedProbe(context) {
  const overrideRender = (page) =>
    page.evaluate((message) => {
      window.resumezen.render = () => Promise.reject(new Error(message));
    }, RENDER_FAILURE);
  const { browser, origin, report, frontendDir, beforeNavigate } = context;
  const { page, pageErrors, consoleMessages } = await openGarden(browser, origin, { beforeNavigate });
  await overrideRender(page);
  const before = await page.evaluate(readPasteState);
  const after = await paste(page, readFixture(frontendDir, "fixtures/ada.json"));
  const hasReportLink = await page.locator('[data-paste-error="render-failed"] a[href]').count();
  await page.close();
  const reasons = [
    ...errorReasons(after, { errorClass: "render-failed", words: ["could not"] }),
    ...unchangedReasons(before, after),
    ...(hasReportLink ? [] : ["no report link inside the render-failed message"]),
    ...debugOnlyReasons(consoleMessages, RENDER_FAILURE),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/render-failed", reasons, `with render rejecting ${JSON.stringify(RENDER_FAILURE)}: [data-paste-error="render-failed"] says ${JSON.stringify(after.errorText)}; raw error in console.debug only; .rz-name still ${JSON.stringify(after.name)}; no pageerror`);
  const tokens = serdeTokenReasons(after.errorText);
  if (tokens.length) {
    report.fail(`ZG-5/no-serde-tokens ZG-5/render-failed: ${tokens.join("; ")}`);
  }
  return tokens.length === 0;
}

async function copyProbe({ browser, origin, report, beforeNavigate }) {
  const { page } = await openGarden(browser, origin, { beforeNavigate });
  const useMine = await page.getByRole("button", { name: "Use my résumé" }).count();
  const sidebarText = await page.locator(".app-sidebar").textContent();
  await page.close();
  const reasons = [
    ...(useMine >= 1 ? [] : ['no control whose accessible name contains "résumé"']),
    ...(sidebarText.includes("Nothing leaves your browser") ? [] : ['sidebar lacks "Nothing leaves your browser"']),
  ];
  reportReasons(report, "ZG-5/copy", reasons, 'the Use my résumé control\'s accessible name contains "résumé"; sidebar says "Nothing leaves your browser"; chrome rz- check is the static probe');
}

async function openPdfProbe({ browser, origin, report, frontendDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const after = await openFile(page, path.join(frontendDir, "fixtures/not-a-resume.pdf"));
  await page.close();
  const reasons = [
    ...errorReasons(after, { errorClass: "not-json-file", words: ["not-a-resume.pdf", "JSON Resume"] }),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/open-pdf", reasons, `[data-paste-error="not-json-file"] says ${JSON.stringify(after.errorText)}`);
  return noteSerde(report, "ZG-5/open-pdf", after.errorText);
}

async function openJsonProbe({ browser, origin, report, repoDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const before = await page.evaluate(readPasteState);
  await openFile(page, path.join(repoDir, "skeleton/resume.json"));
  await waitForName(page, "Jordan Hale");
  const shown = await page.evaluate(readPasteState);
  await page.close();
  const reasons = [
    ...shownReasons(before, shown, "Jordan Hale"),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/open-json", reasons, `skeleton/resume.json via the file input shows .rz-name "Jordan Hale" without using the textarea`);
}

async function fileClassesProbe({ browser, origin, report, frontendDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "zg-5-"));
  try {
    return await fileClassesOn(page, pageErrors, frontendDir, dir, report);
  } finally {
    await page.close();
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

async function fileClassesOn(page, pageErrors, frontendDir, dir, report) {
  const resumeTxt = path.join(dir, "resume.txt");
  const notesTxt = path.join(dir, "notes.txt");
  fs.writeFileSync(resumeTxt, readFixture(frontendDir, "fixtures/ada.json"));
  fs.writeFileSync(notesTxt, "hello");
  const trailing = await openFile(page, path.join(frontendDir, "fixtures/trailing-comma.json"));
  const beforeAda = await page.evaluate(readPasteState);
  await openFile(page, resumeTxt);
  await waitForName(page, "Ada Lovelace");
  const ada = await page.evaluate(readPasteState);
  const notes = await openFile(page, notesTxt);
  const reasons = [
    ...errorReasons(trailing, { errorClass: "invalid-json", words: ["line 1"] }).map((reason) => `trailing-comma.json: ${reason}`),
    ...(trailing.errorClass === "not-json-file" ? ["trailing-comma.json was classified as not-json-file"] : []),
    ...shownReasons(beforeAda, ada, "Ada Lovelace").map((reason) => `resume.txt: ${reason}`),
    ...errorReasons(notes, { errorClass: "not-json-file", words: ["notes.txt"] }).map((reason) => `notes.txt: ${reason}`),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(
    report,
    "ZG-5/file-classes",
    reasons,
    `trailing-comma.json → invalid-json ${JSON.stringify(trailing.errorText)}; resume.txt → Ada Lovelace; notes.txt → not-json-file ${JSON.stringify(notes.errorText)}`,
  );
  return [trailing, notes].every((observed) => noteSerde(report, "ZG-5/file-classes", observed.errorText));
}

async function dropJsonProbe({ browser, origin, report, repoDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const before = await page.evaluate(readPasteState);
  await dropFile(page, path.join(repoDir, "skeleton/resume.json"));
  await waitForName(page, "Jordan Hale");
  const after = await page.evaluate(readPasteState);
  await page.close();
  const reasons = [...shownReasons(before, after, "Jordan Hale"), ...pageErrorReasons(pageErrors)];
  reportReasons(report, "ZG-5/drop-json", reasons, `drop of skeleton/resume.json on [data-drop-zone] shows .rz-name "Jordan Hale"`);
}

async function dropPdfProbe({ browser, origin, report, frontendDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const after = await dropFile(page, path.join(frontendDir, "fixtures/not-a-resume.pdf"));
  await page.close();
  const reasons = [
    ...errorReasons(after, { errorClass: "not-json-file", words: ["not-a-resume.pdf", "JSON Resume"] }),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/drop-pdf", reasons, `[data-paste-error="not-json-file"] says ${JSON.stringify(after.errorText)}`);
  return noteSerde(report, "ZG-5/drop-pdf", after.errorText);
}

async function restoreProbe({ browser, origin, report, frontendDir, beforeNavigate }) {
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  await paste(page, readFixture(frontendDir, "fixtures/ada.json"));
  await waitForName(page, "Ada Lovelace");
  await page.reload({ waitUntil: "networkidle" });
  await page.frameLocator("#garden-frame").locator(".rz-resume").waitFor();
  await waitForName(page, "Ada Lovelace");
  const restored = await page.evaluate(readPasteState);
  await page.getByRole("button", { name: "Forget my résumé" }).click();
  await waitForName(page, "Jordan Hale");
  const forgotten = await page.evaluate(readPasteState);
  const stored = await page.evaluate(() => localStorage.getItem("resumezen.resume"));
  await page.close();
  const reasons = [
    ...(restored.name === "Ada Lovelace" ? [] : [`after reload .rz-name is ${JSON.stringify(restored.name)}, wanted "Ada Lovelace"`]),
    ...(forgotten.name === "Jordan Hale" ? [] : [`after Forget .rz-name is ${JSON.stringify(forgotten.name)}, wanted "Jordan Hale"`]),
    ...forgottenReasons(stored),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/restore", reasons, `reload shows Ada Lovelace; Forget restores Jordan Hale and localStorage['resumezen.resume'] is null`);
}

async function corruptStorageProbe({ browser, origin, report }) {
  const values = ["{", '{"basics":{"label":"x"}}'];
  const runs = [];
  for (const value of values) {
    const { page, pageErrors, consoleMessages } = await openGarden(browser, origin, {
      beforeNavigate: (page) => page.addInitScript((stored) => localStorage.setItem("resumezen.resume", stored), value),
    });
    await page.waitForFunction(() => localStorage.getItem("resumezen.resume") === null);
    const observed = await page.evaluate(readPasteState);
    const stored = await page.evaluate(() => localStorage.getItem("resumezen.resume"));
    await page.close();
    runs.push({ value, observed, stored, pageErrors, consoleMessages });
  }
  const reasons = runs.flatMap(({ value, observed, stored, pageErrors, consoleMessages }) =>
    silentRestoreReasons(observed, { stored, pageErrors, consoleMessages }).map((reason) => `${JSON.stringify(value)}: ${reason}`),
  );
  reportReasons(
    report,
    "ZG-5/corrupt-storage",
    reasons,
    `both ${values.map(JSON.stringify).join(" and ")} restore Jordan Hale with no [data-paste-error], no console error or pageerror, and the key removed`,
  );
}

async function noNetworkProbe({ browser, origin, report, frontendDir, repoDir, beforeNavigate }) {
  const { page, requests, pageErrors } = await openGarden(browser, origin, { beforeNavigate });
  const mark = requests.length;
  await paste(page, readFixture(frontendDir, "fixtures/ada.json"));
  await waitForName(page, "Ada Lovelace");
  await openFile(page, path.join(repoDir, "skeleton/resume.json"));
  await waitForName(page, "Jordan Hale");
  const during = requestsSince(requests, mark);
  const extra = offGardenRequests(during, origin);
  await page.close();
  const reasons = [
    ...(extra.length ? [`HTTP besides page assets and themes/*.css: ${extra.join(", ")}`] : []),
    ...pageErrorReasons(pageErrors),
  ];
  reportReasons(report, "ZG-5/no-network", reasons, `paste and file-open issued ${during.length} request(s) after load, all page assets or themes/*.css`);
}

export async function zg5Probes(context) {
  const { frontendDir, report } = context;
  await sampleProbe(context);
  await adaProbe(context);
  await thenSwitchProbe(context);
  const clean = [
    await emptyProbe(context),
    await errorProbe(context, "ZG-5/paste-trailing-comma", readFixture(frontendDir, "fixtures/trailing-comma.json"), { errorClass: "invalid-json", words: ["line 1", "comma"] }),
    await errorProbe(context, "ZG-5/paste-not-resume", NOT_A_RESUME, { errorClass: "not-a-resume", words: ["work"] }, (page) => crateRejects(page, NOT_A_RESUME)),
    await errorProbe(context, "ZG-5/paste-missing-name", MISSING_NAME, { errorClass: "missing-name", words: ["name"] }),
    await scannerHintsProbe(context),
    await renderFailedProbe(context),
    await openPdfProbe(context),
    await fileClassesProbe(context),
    await dropPdfProbe(context),
  ];
  await openJsonProbe(context);
  await dropJsonProbe(context);
  await restoreProbe(context);
  await corruptStorageProbe(context);
  await noNetworkProbe(context);
  if (clean.every(Boolean)) {
    report.pass(`ZG-5/no-serde-tokens none of expected / EOF / invalid type / serde / Err( / panicked in the error texts (empty, invalid-json, not-a-resume, missing-name, render-failed, not-json-file) nor in the ${SCANNER_ROWS.length} scanner-hints rows`);
  }
  await copyProbe(context);
}
