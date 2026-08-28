/**
 * ZG-10 probes: honest About N pages in Print preview, Save as PDF hint.
 *
 * The probe recomputes N from the iframe sheet + constrained height so
 * first-party page counts are not pinned. Fallbacks intercept Switchyard
 * bytes; content updates are probe-side DOM edits, not a paste route.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { estimatePages, pageGeometry } from "../../static/page-estimate.js";
import { openGarden, waitThemeReady } from "./lib/page.mjs";
import { pageErrorReasons } from "./lib/paste.mjs";
import { countPdfPages, printToPdf } from "./lib/pdf.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoDir = path.resolve(__dirname, "../../..");
const THEME_IDS = ["nightgarden", "quarto", "switchyard"];
const PAPER_WANT = {
  nightgarden: "Letter",
  quarto: "Letter",
  switchyard: "A4",
};
const FALLBACK_SHEET = ".rz-resume{color:#000}@media print{@page{size:8.5in 11in}}";

function reportReasons(report, slug, reasons, okDetail) {
  if (reasons.length) {
    report.fail(`${slug} ${reasons.join("; ")}`);
    return false;
  }
  report.pass(`${slug} ${okDetail}`);
  return true;
}

export function paperSizeReasons({ size, source, wantSize }) {
  return [
    ...(size === wantSize ? [] : [`data-page-size is ${JSON.stringify(size)}, want ${JSON.stringify(wantSize)}`]),
    ...(source === "declared" ? [] : [`data-page-size-source is ${JSON.stringify(source)}, want "declared"`]),
  ];
}

export function fallbackReasons({ size, source, wantSource }) {
  return [
    ...(size === "Letter" ? [] : [`data-page-size is ${JSON.stringify(size)}, want "Letter"`]),
    ...(source === wantSource ? [] : [`data-page-size-source is ${JSON.stringify(source)}, want ${JSON.stringify(wantSource)}`]),
  ];
}

export function nearPdfReasons({ estimate, pdfPages, label }) {
  const delta = Math.abs(estimate - pdfPages);
  return [
    ...(delta <= 1 ? [] : [`|${estimate} − ${pdfPages}| is ${delta}, want ≤ 1`]),
    ...(String(label).startsWith("About ") ? [] : [`readout is ${JSON.stringify(label)}, want to start with "About "`]),
  ];
}

export function hintReasons({ tag, nestedButtons, screenVisible, printVisible, text, printSentence, printButtons }) {
  return [
    ...(tag === "P" ? [] : [`[data-pdf-hint] tag is ${JSON.stringify(tag)}, want P`]),
    ...(nestedButtons === 0 ? [] : [`[data-pdf-hint] contains ${nestedButtons} button(s)`]),
    ...(screenVisible ? [] : ["[data-pdf-hint] is not visible in Screen"]),
    ...(printVisible ? [] : ["[data-pdf-hint] is not visible in Print preview"]),
    ...(text.includes("Save as PDF") ? [] : [`hint lacks "Save as PDF": ${JSON.stringify(text)}`]),
    ...(text.includes("in the print dialog") ? [] : [`hint lacks "in the print dialog": ${JSON.stringify(text)}`]),
    ...(printSentence ? [] : ["ZG-7 sentence is missing under the print button"]),
    ...(printButtons === 1 ? [] : [`Print / buttons: ${printButtons}, want 1`]),
  ];
}

export function guideLineReasons({ stageChildren, stageChildId, bodyChildren, bodyChild, headStyles, headScripts, themeLinks, htmlStyle }) {
  return [
    ...(stageChildren === 1 ? [] : [`.garden-stage--print has ${stageChildren} element children, want 1`]),
    ...(stageChildId === "garden-frame" ? [] : [`stage child is #${stageChildId}, want #garden-frame`]),
    ...(bodyChildren === 1 ? [] : [`iframe body has ${bodyChildren} element children, want 1`]),
    ...(bodyChild ? [] : ["iframe body child is not article.rz-resume"]),
    ...(headStyles === 0 ? [] : [`iframe head has ${headStyles} <style>, want 0`]),
    ...(headScripts === 0 ? [] : [`iframe head has ${headScripts} <script>, want 0`]),
    ...(themeLinks === 1 ? [] : [`iframe head has ${themeLinks} stylesheets, want 1`]),
    ...(htmlStyle === null ? [] : [`iframe html style is ${JSON.stringify(htmlStyle)}, want null`]),
  ];
}

export function consoleErrorReasons(messages) {
  return messages
    .filter((message) => message.type === "error")
    .map((message) => `console error: ${message.text}`);
}

async function waitForThemeHref(page, id) {
  await page.waitForFunction((want) => {
    const href = document
      .getElementById("garden-frame")
      ?.contentDocument?.getElementById("theme-stylesheet")
      ?.getAttribute("href");
    return href && href.includes(`${want}.css`);
  }, id);
}

async function selectTheme(page, id) {
  await page.locator(`#theme-option-${id}`).click();
  await waitForThemeHref(page, id);
}

async function clickPrintPreview(page) {
  await page.getByRole("button", { name: "Print preview" }).click();
}

async function clickScreen(page) {
  await page.getByRole("button", { name: "Screen", exact: true }).click();
}

async function collectIframePageRules(page) {
  return page.evaluate(() => {
    const doc = document.getElementById("garden-frame").contentDocument;
    const sheet = doc.getElementById("theme-stylesheet").sheet;
    const found = [];
    const walk = (rules) => {
      if (!rules) {
        return;
      }
      for (const rule of Array.from(rules)) {
        if (rule.type === CSSRule.PAGE_RULE) {
          found.push({
            selector: rule.selectorText ?? "",
            size: rule.style.getPropertyValue("size"),
            marginTop: rule.style.getPropertyValue("margin-top"),
            marginRight: rule.style.getPropertyValue("margin-right"),
            marginBottom: rule.style.getPropertyValue("margin-bottom"),
            marginLeft: rule.style.getPropertyValue("margin-left"),
          });
        }
        if (rule.type === CSSRule.MEDIA_RULE || rule.type === CSSRule.SUPPORTS_RULE) {
          walk(rule.cssRules);
        }
      }
    };
    walk(sheet.cssRules);
    return found;
  });
}

async function measureConstrainedHeight(page, contentWidthPx) {
  return page.evaluate((width) => {
    const doc = document.getElementById("garden-frame").contentDocument;
    const html = doc.documentElement;
    const resume = doc.querySelector(".rz-resume");
    html.style.setProperty("width", `${width}px`);
    const height = resume.getBoundingClientRect().height;
    html.style.removeProperty("width");
    html.removeAttribute("style");
    return height;
  }, contentWidthPx);
}

async function probeComputedPages(page) {
  const rules = await collectIframePageRules(page);
  const geometry = pageGeometry(rules);
  const heightPx = await measureConstrainedHeight(page, geometry.contentWidthPx);
  return estimatePages(heightPx, geometry.contentHeightPx);
}

async function htmlStyleAttribute(page) {
  return page.evaluate(() => {
    return document.getElementById("garden-frame").contentDocument.documentElement.getAttribute("style");
  });
}

async function pdfPagesForTheme(browser, origin, href) {
  const page = await browser.newPage();
  await page.goto(`${origin}/sandbox.html`, { waitUntil: "networkidle" });
  await waitThemeReady(page, href);
  const pdf = await printToPdf(page);
  const pages = countPdfPages(pdf);
  await page.close();
  return { pages };
}

async function readPageEstimate(page) {
  const node = page.locator("[data-page-estimate]");
  return {
    pages: Number(await node.getAttribute("data-page-estimate")),
    size: await node.getAttribute("data-page-size"),
    source: await node.getAttribute("data-page-size-source"),
    label: await node.textContent(),
  };
}

async function paperSizeProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, { path: "/?view=print" });
  const reasons = [];
  for (const id of THEME_IDS) {
    await selectTheme(page, id);
    await page.waitForSelector(`[data-page-size="${PAPER_WANT[id]}"]`);
    const readout = await readPageEstimate(page);
    reasons.push(...paperSizeReasons({ size: readout.size, source: readout.source, wantSize: PAPER_WANT[id] }).map((reason) => `${id}: ${reason}`));
  }
  await page.close();
  reportReasons(
    report,
    "ZG-10/paper-size",
    reasons,
    "Quarto and Nightgarden declare Letter; Switchyard declares A4",
  );
}

async function openSwitchyardWithSheet(browser, origin, body, wantSource) {
  const opened = await openGarden(browser, origin, {
    path: "/?view=print",
    beforeNavigate: async (garden) => {
      await garden.route("**/themes/switchyard.css", async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "text/css",
          headers: { "cache-control": "no-store" },
          body,
        });
      });
    },
  });
  await selectTheme(opened.page, "switchyard");
  await opened.page.waitForSelector(`[data-page-size-source="${wantSource}"]`);
  const readout = await readPageEstimate(opened.page);
  await opened.page.unroute("**/themes/switchyard.css");
  await opened.page.close();
  return { readout, pageErrors: opened.pageErrors, consoleMessages: opened.consoleMessages };
}

async function paperSizeFallbacksProbe({ browser, origin, report }) {
  const blank = fs.readFileSync(path.join(repoDir, "themes", "_blank.css"), "utf8");
  const missing = await openSwitchyardWithSheet(browser, origin, blank, "default");
  const fallback = await openSwitchyardWithSheet(browser, origin, FALLBACK_SHEET, "fallback");
  reportReasons(
    report,
    "ZG-10/paper-size-fallbacks",
    [
      ...fallbackReasons({ size: missing.readout.size, source: missing.readout.source, wantSource: "default" }).map((reason) => `blank: ${reason}`),
      ...fallbackReasons({ size: fallback.readout.size, source: fallback.readout.source, wantSource: "fallback" }).map((reason) => `8.5in 11in: ${reason}`),
      ...pageErrorReasons(missing.pageErrors),
      ...pageErrorReasons(fallback.pageErrors),
      ...consoleErrorReasons(missing.consoleMessages),
      ...consoleErrorReasons(fallback.consoleMessages),
    ],
    "missing @page is Letter/default; 8.5in 11in is Letter/fallback",
  );
}

async function estimateMatchesFormulaProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, { path: "/?view=print" });
  const reasons = [];
  const seen = [];
  for (const id of THEME_IDS) {
    await selectTheme(page, id);
    await waitForThemeHref(page, id);
    const n = await probeComputedPages(page);
    await page.waitForSelector(`[data-page-estimate="${n}"]`, { timeout: 5000 });
    try {
      await page.waitForFunction(() => {
        return document.getElementById("garden-frame")?.contentDocument?.documentElement.getAttribute("style") === null;
      }, { timeout: 5000 });
    } catch {
      // fall through to the style assertion
    }
    const style = await htmlStyleAttribute(page);
    seen.push(`${id} ${n}`);
    if (style !== null) {
      reasons.push(`${id}: iframe html style is ${JSON.stringify(style)}, want null`);
    }
  }
  await page.close();
  reportReasons(
    report,
    "ZG-10/estimate-matches-formula",
    reasons,
    `readout matches the constrained-height formula (${seen.join(", ")})`,
  );
}

async function estimateNearPdfProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, { path: "/?view=print" });
  const reasons = [];
  const seen = [];
  for (const id of THEME_IDS) {
    await selectTheme(page, id);
    await waitForThemeHref(page, id);
    const n = await probeComputedPages(page);
    await page.waitForSelector(`[data-page-estimate="${n}"]`, { timeout: 5000 });
    const readout = await readPageEstimate(page);
    const pdf = await pdfPagesForTheme(browser, origin, `themes/${id}.css`);
    reasons.push(
      ...nearPdfReasons({ estimate: readout.pages, pdfPages: pdf.pages, label: readout.label }).map((reason) => `${id}: ${reason}`),
    );
    seen.push(`${id} estimate ${readout.pages} pdf ${pdf.pages}`);
  }
  await page.close();
  reportReasons(
    report,
    "ZG-10/estimate-near-pdf",
    reasons,
    seen.join("; "),
  );
}

async function updatesOnSwitchProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, { path: "/?view=print" });
  await selectTheme(page, "quarto");
  await page.waitForSelector('[data-page-size="Letter"]');
  await selectTheme(page, "switchyard");
  await page.waitForSelector('[data-page-size="A4"]');
  const n = await probeComputedPages(page);
  await page.waitForSelector(`[data-page-estimate="${n}"]`);
  const size = await page.locator("[data-page-estimate]").getAttribute("data-page-size");
  await page.close();
  reportReasons(
    report,
    "ZG-10/updates-on-switch",
    size === "A4" ? [] : [`data-page-size is ${JSON.stringify(size)}, want A4`],
    `Quarto Letter → Switchyard A4; estimate settled on ${n}`,
  );
}

async function updatesOnContentProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, { path: "/?theme=quarto&view=print" });
  await waitForThemeHref(page, "quarto");
  const original = await probeComputedPages(page);
  await page.waitForSelector(`[data-page-estimate="${original}"]`);

  await page.evaluate(() => {
    const doc = document.getElementById("garden-frame").contentDocument;
    const article = doc.querySelector("article.rz-resume");
    const experience = doc.querySelector("#rz-experience");
    article.appendChild(experience.cloneNode(true));
    article.appendChild(experience.cloneNode(true));
  });
  const grown = await probeComputedPages(page);
  const grew = grown > original;
  await page.waitForSelector(`[data-page-estimate="${grown}"]`);

  await page.evaluate(() => {
    const doc = document.getElementById("garden-frame").contentDocument;
    const extras = [...doc.querySelectorAll("#rz-experience")].slice(1);
    for (const node of extras) {
      node.remove();
    }
  });
  const restored = await probeComputedPages(page);
  await page.waitForSelector(`[data-page-estimate="${restored}"]`);

  await clickScreen(page);
  await page.waitForSelector("[data-page-estimate]", { state: "detached" });
  const hidden = (await page.locator("[data-page-estimate]").count()) === 0;

  await clickPrintPreview(page);
  await page.waitForSelector(`[data-page-estimate="${restored}"]`);
  await page.close();

  reportReasons(
    report,
    "ZG-10/updates-on-content",
    [
      ...(grew ? [] : [`cloned estimate ${grown} was not greater than ${original}`]),
      ...(restored === original ? [] : [`after remove, N is ${restored}, want ${original}`]),
      ...(hidden ? [] : ["Screen left [data-page-estimate] in the DOM"]),
    ],
    `clones raised ${original} → ${grown}; remove and Screen/Print preview restored ${original}`,
  );
}

async function minOneProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, { path: "/?theme=quarto&view=print" });
  await waitForThemeHref(page, "quarto");
  await page.evaluate(() => {
    const doc = document.getElementById("garden-frame").contentDocument;
    const article = doc.querySelector("article.rz-resume");
    const name = doc.createElement("h1");
    name.className = "rz-name";
    name.textContent = "A";
    article.replaceChildren(name);
  });
  await page.waitForSelector('[data-page-estimate="1"]');
  const readout = await readPageEstimate(page);
  await page.reload({ waitUntil: "networkidle" });
  await page.close();
  reportReasons(
    report,
    "ZG-10/min-one",
    [
      ...(readout.label === "About 1 page (Letter)" ? [] : [`text is ${JSON.stringify(readout.label)}`]),
      ...(readout.pages === 1 ? [] : [`data-page-estimate is ${readout.pages}`]),
      ...(readout.label.includes("1 pages") ? ["said 1 pages"] : []),
    ],
    "tiny Quarto résumé reads About 1 page (Letter)",
  );
}

async function hintProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  const hint = page.locator("[data-pdf-hint]");
  const tag = await hint.evaluate((el) => el.tagName);
  const nestedButtons = await hint.locator("button").count();
  const screenVisible = await hint.isVisible();
  const printSentence = await page.locator(".preview-controls__print + .preview-controls__hint").evaluate((el) => {
    return el.textContent.includes("What you see here is what the printer prints.");
  });
  await clickPrintPreview(page);
  const printVisible = await hint.isVisible();
  const text = await hint.textContent();
  const printButtons = await page.evaluate(() => {
    return [...document.querySelectorAll("button")].filter((button) => {
      const name = button.getAttribute("aria-label") || button.textContent || "";
      return name.trim().startsWith("Print /");
    }).length;
  });
  await page.close();
  reportReasons(
    report,
    "ZG-10/hint",
    hintReasons({ tag, nestedButtons, screenVisible, printVisible, text, printSentence, printButtons }),
    "Save as PDF hint is visible in both views under the ZG-7 sentence",
  );
}

async function noGuideLinesProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, { path: "/?view=print" });
  await waitForThemeHref(page, "nightgarden");
  await page.waitForSelector("[data-page-estimate]");
  try {
    await page.waitForFunction(() => {
      return document.getElementById("garden-frame")?.contentDocument?.documentElement.getAttribute("style") === null;
    }, { timeout: 5000 });
  } catch {
    // fall through to guideLineReasons
  }
  const snapshot = await page.evaluate(() => {
    const stage = document.querySelector(".garden-stage--print");
    const stageKids = stage ? [...stage.children] : [];
    const doc = document.getElementById("garden-frame").contentDocument;
    const bodyKids = [...doc.body.children];
    return {
      stageChildren: stageKids.length,
      stageChildId: stageKids[0]?.id || "",
      bodyChildren: bodyKids.length,
      bodyChild: bodyKids[0]?.matches("article.rz-resume") ?? false,
      headStyles: doc.head.querySelectorAll("style").length,
      headScripts: doc.head.querySelectorAll("script").length,
      themeLinks: doc.head.querySelectorAll('link[rel="stylesheet"]').length,
      htmlStyle: doc.documentElement.getAttribute("style"),
    };
  });
  await page.close();
  reportReasons(
    report,
    "ZG-10/no-guide-lines",
    guideLineReasons(snapshot),
    "Print preview has no page-boundary overlay and the iframe html has no leftover style",
  );
}

export async function zg10Probes(context) {
  await paperSizeProbe(context);
  await paperSizeFallbacksProbe(context);
  await estimateMatchesFormulaProbe(context);
  await estimateNearPdfProbe(context);
  await updatesOnSwitchProbe(context);
  await updatesOnContentProbe(context);
  await minOneProbe(context);
  await hintProbe(context);
  await noGuideLinesProbe(context);
}
