/**
 * ZG-13 probes: first-party Themes self-host faces. A résumé page never
 * phones jsDelivr; print still has a face when the Font Library seed is
 * aborted (system/local fallback). BAR-L1 lives here.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { openGarden, sandboxFrame } from "./lib/page.mjs";
import { pageErrorReasons } from "./lib/paste.mjs";
import { printToPdf } from "./lib/pdf.mjs";
import {
  barL1PairReasons,
  fallbackLayoutReasons,
  fontFetchReasons,
  fontFileListReasons,
  fontsLoadReasons,
  ignoredFontLoadCount,
  resolveThemeUrl,
  themeFontDistPath,
  themeFontRows,
  themePairs,
  thirdPartyRequests,
  unexpectedConsoleErrors,
} from "./lib/theme-fonts.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoDir = path.resolve(__dirname, "../../..");
const THEME_IDS = ["nightgarden", "quarto", "switchyard"];
const LOAD_FACES = [
  ["quarto", "EB Garamond"],
  ["switchyard", "IBM Plex Sans"],
  ["nightgarden", "Syne"],
];

function reportReasons(report, slug, reasons, okDetail) {
  if (reasons.length) {
    report.fail(`${slug} ${reasons.join("; ")}`);
    return false;
  }
  report.pass(`${slug} ${okDetail}`);
  return true;
}

function readThemeCss() {
  return Object.fromEntries(THEME_IDS.map((id) => [id, fs.readFileSync(path.join(repoDir, "themes", `${id}.css`), "utf8")]));
}

async function waitThemeHref(page, id) {
  await page.waitForFunction((want) => {
    const href = document.getElementById("garden-frame")?.contentDocument?.getElementById("theme-stylesheet")?.getAttribute("href");
    return href && href.includes(`${want}.css`);
  }, id);
}

async function selectTheme(page, id) {
  await page.locator(`#theme-option-${id}`).click();
  await waitThemeHref(page, id);
  const frame = sandboxFrame(page);
  await frame.evaluate(() => document.fonts.ready);
}

function readNameStyle() {
  const name = document.querySelector(".rz-name");
  const style = getComputedStyle(name);
  return { color: style.color, fontFamily: style.fontFamily, height: name.getBoundingClientRect().height };
}

function readDateGeometry() {
  const resume = document.querySelector(".rz-resume");
  if (!resume) {
    return { ok: false, reason: "missing resume" };
  }
  const style = getComputedStyle(resume);
  const box = resume.getBoundingClientRect();
  const left = box.left + Number.parseFloat(style.paddingLeft);
  const right = box.right - Number.parseFloat(style.paddingRight);
  const top = box.top + Number.parseFloat(style.paddingTop);
  const bottom = box.bottom - Number.parseFloat(style.paddingBottom);
  const nodes = [...document.querySelectorAll(".rz-date, time[datetime]")];
  const clipped = [];
  for (const node of nodes) {
    const rect = node.getBoundingClientRect();
    if (rect.width === 0 && rect.height === 0) {
      continue;
    }
    const slack = 0.6;
    if (rect.left + slack < left || rect.right - slack > right || rect.top + slack < top || rect.bottom - slack > bottom) {
      clipped.push({ text: node.textContent.trim() });
    }
  }
  const scrollX =
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1 ||
    document.body.scrollWidth > document.body.clientWidth + 1;
  return { ok: true, clipped, scrollX, parentScroll: false, count: nodes.length };
}

async function noThirdPartyProbe({ browser, origin, report }) {
  const { page, requests, pageErrors } = await openGarden(browser, origin);
  for (const id of THEME_IDS) {
    await selectTheme(page, id);
  }
  await page.getByRole("button", { name: "Print preview" }).click();
  await page.waitForTimeout(400);
  await printToPdf(page);
  await page.waitForLoadState("networkidle");
  const foreign = thirdPartyRequests(requests);
  await page.close();
  reportReasons(
    report,
    "ZG-13/no-third-party",
    [...(foreign.length ? [`third-party request(s): ${foreign.join(", ")}`] : []), ...pageErrorReasons(pageErrors)],
    `cycled ${THEME_IDS.join(" → ")} and printed; ${requests.length} request(s), all 127.0.0.1/localhost`,
  );
}

async function fontFilesProbe({ browser, origin, report, frontendDir }) {
  const { page } = await openGarden(browser, origin);
  const rows = themeFontRows(readThemeCss());
  const listReasons = fontFileListReasons(rows);
  const distThemes = path.join(frontendDir, "dist", "themes");
  const fetchReasons = [];
  for (const spec of rows.flatMap((row) => row.urls)) {
    const url = resolveThemeUrl(spec, origin);
    const disk = themeFontDistPath(spec, distThemes);
    const response = await page.request.get(url);
    fetchReasons.push(
      ...fontFetchReasons({
        url,
        status: response.status(),
        contentType: response.headers()["content-type"],
        onDisk: fs.existsSync(disk),
      }),
    );
  }
  await page.close();
  const count = rows.reduce((sum, row) => sum + row.urls.length, 0);
  reportReasons(report, "ZG-13/font-files", [...listReasons, ...fetchReasons], `${count} @font-face url(s) 200 font/woff2 under /themes/fonts/ and frontend/dist/themes/fonts/`);
}

async function fontsLoadProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin);
  const reasons = [...pageErrorReasons(pageErrors)];
  const loaded = [];
  for (const [id, family] of LOAD_FACES) {
    await selectTheme(page, id);
    const faces = await sandboxFrame(page).evaluate(async () => {
      await document.fonts.ready;
      return [...document.fonts].map((face) => ({ family: face.family, status: face.status }));
    });
    reasons.push(...fontsLoadReasons(faces, family));
    loaded.push(`${family} @ ${id}`);
  }
  await page.close();
  reportReasons(report, "ZG-13/fonts-load", reasons, `${loaded.join("; ")}; no watched family in error`);
}

async function fallbackProbe({ browser, origin, report }) {
  const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await context.newPage();
  const pageErrors = [];
  const consoleMessages = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  page.on("console", (message) => {
    consoleMessages.push({ type: message.type(), text: message.text(), locationUrl: message.location().url });
  });
  await page.route("**/themes/fonts/**", (route) => route.abort());
  await page.goto(`${origin}/`, { waitUntil: "networkidle" });
  await page.frameLocator("#garden-frame").locator(".rz-resume").waitFor();
  const geometryByTheme = {};
  let nameHeight = 0;
  for (const id of THEME_IDS) {
    await page.locator(`#theme-option-${id}`).click();
    await waitThemeHref(page, id);
    const frame = sandboxFrame(page);
    await frame.evaluate(() => document.fonts.ready);
    nameHeight = await frame.evaluate(() => document.querySelector(".rz-name").getBoundingClientRect().height);
    geometryByTheme[id] = await frame.evaluate(readDateGeometry);
  }
  const box = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
  }));
  const ignored = ignoredFontLoadCount(consoleMessages);
  const reasons = [
    ...pageErrorReasons(pageErrors),
    ...unexpectedConsoleErrors(consoleMessages).map((message) => `console.error: ${message.text}`),
    ...fallbackLayoutReasons({ nameHeight, scrollWidth: box.scrollWidth, clientWidth: box.clientWidth, geometryByTheme }),
  ];
  await context.close();
  reportReasons(
    report,
    "ZG-13/fallback",
    reasons,
    `aborted **/themes/fonts/**; .rz-name height ${nameHeight}; S2 + BAR-U2 green; ignored ${ignored} font-load error(s)`,
  );
}

async function barL1Probe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin);
  const styles = {};
  for (const id of THEME_IDS) {
    await selectTheme(page, id);
    styles[id] = await sandboxFrame(page).evaluate(readNameStyle);
  }
  const pairReasons = themePairs(THEME_IDS).flatMap(([left, right]) =>
    barL1PairReasons(styles[left], styles[right], `${left}/${right}`),
  );
  await page.close();
  if (pairReasons.length || pageErrors.length) {
    report.fail(`BAR-L1 ${[...pairReasons, ...pageErrorReasons(pageErrors)].join("; ")}`);
  } else {
    report.pass("BAR-L1 PASS");
  }
}

export async function zg13Probes(context) {
  await noThirdPartyProbe(context);
  await fontFilesProbe(context);
  await fontsLoadProbe(context);
  await fallbackProbe(context);
  await barL1Probe(context);
}
