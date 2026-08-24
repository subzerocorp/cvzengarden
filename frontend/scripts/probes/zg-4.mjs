/**
 * ZG-4 probes: the Renderer runs in the browser via Wasm and matches the
 * crate byte for byte. The crate side of the parity check is produced in
 * the same run by `cargo run -q --example render` in `renderer/`; when that
 * cannot run the probe FAILS (a prerequisite, never a skip).
 *
 * Each probe opens its own Garden page so an aborted Wasm route or a
 * swapped article never leaks into another probe. The runner owns
 * reporting; this module only calls the injected `pass` / `fail`.
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { parityReasons } from "./lib/byte-parity.mjs";
import { foreignRequests, requestsSince } from "./lib/request-log.mjs";
import { largeResume, mebibytes } from "./lib/resume-size.mjs";
import { openGarden } from "./lib/page.mjs";

const PUBLICATION_DOC = '{"basics":{"name":"T"},"publications":[{"name":"Talk","releaseDate":"2023-05-31T09:00:00Z"}]}';
const LARGE_MIN_BYTES = Math.ceil(4.8 * 1024 * 1024);
const LARGE_MAX_MS = 5000;
const ORACLE_MISSING = "ZG-4/wasm-parity prerequisite missing: cargo example render";
const WASM_GLOB = "**/*_bg.wasm";

// Calculation: why a render outcome is not a rejection whose message has the expected words.
export function rejectionReasons(outcome, mustContain) {
  if (outcome.ok) {
    return ["render resolved instead of rejecting"];
  }
  if (typeof outcome.message !== "string") {
    return ["rejection carried no message"];
  }
  return outcome.message.includes(mustContain) ? [] : [`message lacks "${mustContain}": ${JSON.stringify(outcome.message)}`];
}

// Calculation: a stack frame in text meant for the Chrome. (The crate's own
// error says "at line 1" — this check is for the load-failure text only.)
export function stackReasons(message) {
  return String(message).includes("at ") ? ["message carries a stack frame (\"at \")"] : [];
}

// Calculation: why the sandbox article is not the one the crate rendered.
// (A swap that only rewrote `.rz-name` and the title would pass `swapReasons`.)
export function articleReasons(renderedArticle, sandboxArticle) {
  if (typeof sandboxArticle !== "string") {
    return ["sandbox has no article.rz-resume"];
  }
  return renderedArticle === sandboxArticle ? [] : ["sandbox article.rz-resume differs from the rendered article"];
}

// Calculation: why the swapped sandbox is not Ada in an untouched frame.
export function swapReasons(before, after) {
  return [
    ...(after.src === "sandbox.html" ? [] : [`iframe src changed to ${after.src}`]),
    ...(after.themeHref === before.themeHref ? [] : [`#theme-stylesheet href changed ${before.themeHref} → ${after.themeHref}`]),
    ...(after.name === "Ada Lovelace" ? [] : [`.rz-name is ${JSON.stringify(after.name)}`]),
    ...(after.hasJordan ? ["sandbox still contains Jordan Hale"] : []),
    ...(after.title === "Ada Lovelace" ? [] : [`iframe title is ${JSON.stringify(after.title)}`]),
  ];
}

function crateRender(repoDir, input) {
  const result = spawnSync("cargo", ["run", "-q", "--example", "render"], {
    cwd: path.join(repoDir, "renderer"),
    input,
    maxBuffer: 64 * 1024 * 1024,
  });
  return result.error || result.status !== 0 ? null : result.stdout;
}

function readFixture(dir, name) {
  return fs.readFileSync(path.join(dir, name), "utf8");
}

// Runs in the page: awaits the renderer and reports the outcome as data.
function renderOutcome(json) {
  return window.resumezen.render(json).then(
    (html) => ({ ok: true, html }),
    (failure) => ({ ok: false, message: failure.message }),
  );
}

function timedRender(json) {
  const started = performance.now();
  return window.resumezen.render(json).then((html) => ({ html, ms: performance.now() - started }));
}

function readFrameState() {
  const iframe = document.getElementById("garden-frame");
  const doc = iframe.contentDocument;
  return {
    src: iframe.getAttribute("src"),
    themeHref: doc.getElementById("theme-stylesheet").getAttribute("href"),
    name: doc.querySelector(".rz-name")?.textContent ?? null,
    title: doc.title,
    hasJordan: doc.documentElement.outerHTML.includes("Jordan Hale"),
    articleHtml: doc.querySelector("article.rz-resume")?.outerHTML,
  };
}

// Runs in the page: the article of a rendered document, serialised the same
// way the sandbox serialises its own.
function renderedArticleHtml(html) {
  return new DOMParser().parseFromString(html, "text/html").querySelector("article.rz-resume")?.outerHTML ?? "";
}

async function parityProbe({ browser, origin, report, repoDir, frontendDir }) {
  const inputs = [
    ["skeleton/resume.json", readFixture(repoDir, "skeleton/resume.json")],
    ["fixtures/ada.json", readFixture(frontendDir, "fixtures/ada.json")],
    ["inline publications", PUBLICATION_DOC],
  ];
  const { page } = await openGarden(browser, origin);
  for (const [label, input] of inputs) {
    const expected = crateRender(repoDir, input);
    if (!expected) {
      report.fail(ORACLE_MISSING);
      continue;
    }
    const outcome = await page.evaluate(renderOutcome, input);
    const reasons = outcome.ok ? parityReasons(expected, Buffer.from(outcome.html, "utf8")) : [`render rejected: ${outcome.message}`];
    if (reasons.length) {
      report.fail(`ZG-4/wasm-parity ${label}: ${reasons.join("; ")}`);
    } else {
      report.pass(`ZG-4/wasm-parity ${label}: wasm output byte-equal to cargo example render (${expected.length} B)`);
    }
  }
  await page.close();
}

async function errorProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin);
  const outcome = await page.evaluate(renderOutcome, "{");
  const reasons = [...rejectionReasons(outcome, "line 1"), ...pageErrors.map((e) => `pageerror: ${e}`)];
  await page.close();
  if (reasons.length) {
    report.fail(`ZG-4/wasm-error ${reasons.join("; ")}`);
  } else {
    report.pass(`ZG-4/wasm-error render('{') rejects with ${JSON.stringify(outcome.message)}; no pageerror`);
  }
}

async function loadFailureProbe({ browser, origin, report, frontendDir }) {
  const abortWasm = (page) => page.route(WASM_GLOB, (route) => route.abort());
  const { page, pageErrors } = await openGarden(browser, origin, { beforeNavigate: abortWasm });
  const outcome = await page.evaluate(renderOutcome, readFixture(frontendDir, "fixtures/ada.json"));
  const frame = await page.evaluate(readFrameState);
  const reasons = [
    ...rejectionReasons(outcome, "renderer"),
    ...stackReasons(outcome.message),
    ...(frame.name === "Jordan Hale" ? [] : [`sandbox no longer shows Jordan Hale (${JSON.stringify(frame.name)})`]),
    ...pageErrors.map((e) => `pageerror: ${e}`),
  ];
  await page.close();
  if (reasons.length) {
    report.fail(`ZG-4/wasm-load-failure ${reasons.join("; ")}`);
  } else {
    report.pass(`ZG-4/wasm-load-failure with *_bg.wasm aborted render rejects ${JSON.stringify(outcome.message)}; sandbox still Jordan Hale; no pageerror`);
  }
}

async function largeProbe({ browser, origin, report, repoDir }) {
  const grown = largeResume(JSON.parse(readFixture(repoDir, "skeleton/resume.json")), LARGE_MIN_BYTES);
  const { page, pageErrors } = await openGarden(browser, origin);
  await page.evaluate(renderOutcome, "{}");
  const { html, ms } = await page.evaluate(timedRender, grown.text);
  const reasons = [
    ...(ms <= LARGE_MAX_MS ? [] : [`took ${ms.toFixed(0)} ms > ${LARGE_MAX_MS} ms`]),
    ...(html.includes(grown.lastName) ? [] : [`output lacks ${grown.lastName}`]),
    ...pageErrors.map((e) => `pageerror: ${e}`),
  ];
  await page.close();
  if (reasons.length) {
    report.fail(`ZG-4/wasm-large ${reasons.join("; ")}`);
  } else {
    report.pass(`ZG-4/wasm-large ${mebibytes(grown.bytes)} MiB (${grown.jobs} jobs) rendered in ${ms.toFixed(0)} ms ≤ ${LARGE_MAX_MS} ms; ${grown.lastName} present`);
  }
}

async function swapProbe({ browser, origin, report, frontendDir }) {
  const { page, pageErrors } = await openGarden(browser, origin);
  const before = await page.evaluate(readFrameState);
  const outcome = await page.evaluate(renderOutcome, readFixture(frontendDir, "fixtures/ada.json"));
  if (outcome.ok) {
    await page.evaluate((html) => window.resumezen.swap(html), outcome.html);
  }
  const after = await page.evaluate(readFrameState);
  const renderedArticle = outcome.ok ? await page.evaluate(renderedArticleHtml, outcome.html) : "";
  const reasons = [
    ...(outcome.ok ? swapReasons(before, after) : [`render rejected: ${outcome.message}`]),
    ...(outcome.ok ? articleReasons(renderedArticle, after.articleHtml) : []),
    ...pageErrors.map((e) => `pageerror: ${e}`),
  ];
  await page.close();
  if (reasons.length) {
    report.fail(`ZG-4/wasm-swap ${reasons.join("; ")}`);
  } else {
    report.pass(`ZG-4/wasm-swap Ada in the sandbox (article byte-equal to the rendered one, ${renderedArticle.length} chars); iframe src ${after.src}; #theme-stylesheet ${after.themeHref} unchanged; title ${JSON.stringify(after.title)}`);
  }
}

async function noNetworkProbe({ browser, origin, report, frontendDir }) {
  const ada = readFixture(frontendDir, "fixtures/ada.json");
  const { page, requests } = await openGarden(browser, origin);
  await page.evaluate(renderOutcome, "{}");
  const mark = requests.length;
  const outcome = await page.evaluate(renderOutcome, ada);
  if (outcome.ok) {
    await page.evaluate((html) => window.resumezen.swap(html), outcome.html);
  }
  await page.waitForLoadState("networkidle");
  const during = requestsSince(requests, mark);
  const foreign = foreignRequests(during, origin);
  await page.close();
  const reasons = [
    ...(outcome.ok ? [] : [`render rejected: ${outcome.message}`]),
    ...(foreign.length ? [`/api or third-party request(s) during render+swap: ${foreign.join(", ")}`] : []),
    ...(during.length ? [`${during.length} request(s) during render+swap: ${during.join(", ")}`] : []),
  ];
  if (reasons.length) {
    report.fail(`ZG-4/wasm-no-network ${reasons.join("; ")}`);
  } else {
    report.pass(`ZG-4/wasm-no-network ${during.length} requests during render+swap (0 /api, 0 third-party); ${mark} initial page assets untouched`);
  }
}

export async function zg4Probes(context) {
  await parityProbe(context);
  await errorProbe(context);
  await loadFailureProbe(context);
  await largeProbe(context);
  await swapProbe(context);
  await noNetworkProbe(context);
}
