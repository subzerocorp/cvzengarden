/**
 * RZ-3 + RZ-S1…S5 + U3 (reopened RZ-S3) acceptance probes.
 *
 * Named stubs these must fail:
 *   S1 — only swap #theme-stylesheet href and drop the old sheet first
 *   S2 — overflow:hidden that hides the bar while dates still overflow
 *   S3 — keep Nightgarden print as a dark full-bleed
 *   S4 — pointer-only / opacity-0 radios that Tab skips
 *   S5 — no ?theme= history (Back does nothing; unknown 500 / empty stage)
 *   U3 — shell Print with .garden-frame still at min-height: 100vh
 */
import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import {
  COLD_SETTLE_MS,
  COLD_SHEET_DELAY_MS,
  describePaintOrder,
  paintOrderReasons,
  paintPresenceReasons,
  readSandboxPaintTiming,
} from "./probes/lib/paint.mjs";
import { sheetBlockingReasons } from "./probes/lib/sheet-blocking.mjs";
import { parseRgb } from "./probes/lib/contrast.mjs";
import {
  holdThemeSheets,
  releaseThemeSheets,
  sandboxFrame,
  waitForSandboxComplete,
  waitThemeReady,
} from "./probes/lib/page.mjs";
import { countPdfPages, printToPdf } from "./probes/lib/pdf.mjs";
import { sheetSourceFor } from "./probes/lib/sheet-source.mjs";
import { zg4Probes } from "./probes/zg-4.mjs";
import { zg5Probes } from "./probes/zg-5.mjs";
import { zg6Probes } from "./probes/zg-6.mjs";
import { zg7Probes } from "./probes/zg-7.mjs";
import { zg8Probes } from "./probes/zg-8.mjs";
import { zg9Probes } from "./probes/zg-9.mjs";
import { zg10Probes } from "./probes/zg-10.mjs";
import { zg11Probes } from "./probes/zg-11.mjs";
import { zg12Probes } from "./probes/zg-12.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const frontendDir = path.resolve(__dirname, "..");
const repoDir = path.resolve(frontendDir, "..");
const distDir = path.join(frontendDir, "dist");
const port = Number(process.env.PROBE_PORT || 4173);
const origin = `http://127.0.0.1:${port}`;

const THEME_IDS = ["nightgarden", "quarto", "switchyard"];
const failures = [];

function fail(message) {
  failures.push(message);
  console.error(`FAIL  ${message}`);
}

function pass(message) {
  console.log(`PASS  ${message}`);
}

function chromeSourceFiles() {
  const roots = [
    path.join(frontendDir, "src"),
    path.join(frontendDir, "css"),
    path.join(frontendDir, "static"),
  ];
  const files = [];
  for (const root of roots) {
    const stack = [root];
    while (stack.length) {
      const current = stack.pop();
      for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
        const full = path.join(current, entry.name);
        if (entry.isDirectory()) {
          stack.push(full);
        } else {
          files.push(full);
        }
      }
    }
  }
  return files;
}

function readTheme(id) {
  return fs.readFileSync(path.join(repoDir, "themes", `${id}.css`), "utf8");
}

function extractMediaBlocks(css) {
  const blocks = [];
  const re = /@media\b/g;
  let match = re.exec(css);
  while (match) {
    const start = match.index;
    const brace = css.indexOf("{", start);
    if (brace === -1) {
      break;
    }
    let depth = 0;
    let end = -1;
    for (let i = brace; i < css.length; i += 1) {
      if (css[i] === "{") {
        depth += 1;
      } else if (css[i] === "}") {
        depth -= 1;
        if (depth === 0) {
          end = i;
          break;
        }
      }
    }
    if (end === -1) {
      break;
    }
    blocks.push({
      prelude: css.slice(start, brace),
      body: css.slice(brace + 1, end),
    });
    re.lastIndex = end + 1;
    match = re.exec(css);
  }
  return blocks;
}

function isBlankCanvas(color) {
  if (!color || color === "transparent") {
    return true;
  }
  const rgb = parseRgb(color);
  if (!rgb) {
    return /^(#fff(?:fff)?|white)$/i.test(color);
  }
  if (rgb.a < 0.08) {
    return true;
  }
  return rgb.r >= 250 && rgb.g >= 250 && rgb.b >= 250;
}

function isDarkFill(color) {
  const rgb = parseRgb(color);
  if (!rgb || rgb.a < 0.4) {
    return false;
  }
  const luminance = (0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b) / 255;
  return luminance < 0.28;
}

function isUaDefaultSerif(fontFamily) {
  if (!fontFamily) {
    return true;
  }
  const lower = fontFamily.toLowerCase();
  if (
    lower.includes("syne") ||
    lower.includes("outfit") ||
    lower.includes("garamond") ||
    lower.includes("plex") ||
    lower.includes("palatino") ||
    lower.includes("ibm")
  ) {
    return false;
  }
  const uaSerif = /(^|,\s*)(times(?: new roman)?|serif)(\s*,|$)/i.test(fontFamily);
  return uaSerif && !/sans-serif/i.test(lower);
}

function isFoucSample(sample) {
  if (!sample?.name) {
    return false;
  }
  const canvasBlank =
    isBlankCanvas(sample.htmlBg) && isBlankCanvas(sample.bodyBg) && isBlankCanvas(sample.resumeBg);
  return canvasBlank && isUaDefaultSerif(sample.font);
}

function staticProbes() {
  const chromeFiles = chromeSourceFiles();
  const bannedClassOrId = /(?:\bclass|\bid|classList)\s*[=\[]?\s*["']rz-|["']rz-[a-z]/i;
  const cssRz = /(?:^|[^\w-])(?:\.#?|[#.])rz-[a-z]/m;

  for (const file of chromeFiles) {
    const source = fs.readFileSync(file, "utf8");
    const rel = path.relative(frontendDir, file);

    if (/(?:@import|href\s*=|url\()\s*["'][^"']*preview\.css/.test(source)) {
      fail(`Chrome file ${rel} links skeleton/preview.css`);
    }

    if (rel.endsWith(".css") && cssRz.test(source)) {
      fail(`Chrome CSS ${rel} uses an rz- selector`);
    }

    if ((rel.endsWith(".elm") || rel.endsWith(".html") || rel.endsWith(".css")) && bannedClassOrId.test(source)) {
      fail(`Chrome markup ${rel} has a class or id prefixed rz-`);
    }
  }

  const themesElm = fs.readFileSync(path.join(frontendDir, "src", "Generated", "Themes.elm"), "utf8");
  if (/\bid\s*=\s*"_blank"/.test(themesElm) || /preview\.css/.test(themesElm)) {
    fail("Generated theme list includes _blank or preview.css");
  } else {
    pass("Generated theme list excludes _blank and preview.css");
  }

  const themeFiles = fs
    .readdirSync(path.join(repoDir, "themes"))
    .filter((name) => name.endsWith(".css") && name !== "_blank.css")
    .map((name) => name.replace(/\.css$/, ""));

  for (const id of themeFiles) {
    if (!themesElm.includes(`id = "${id}"`)) {
      fail(`Generated Themes.elm is missing ${id}`);
    }
  }
  pass(`Generated Themes.elm lists ${themeFiles.join(", ")}`);

  const sandbox = fs.readFileSync(path.join(distDir, "sandbox.html"), "utf8");
  if (!sandbox.includes('class="rz-resume"') || !sandbox.includes('data-rz-schema="1.0"')) {
    fail("Sandbox document is missing .rz-resume / data-rz-schema");
  } else {
    pass("Sandbox document contains .rz-resume and data-rz-schema=\"1.0\"");
  }
  if (/preview\.css/.test(sandbox)) {
    fail("Sandbox links or mentions preview.css");
  } else {
    pass("Sandbox does not link preview.css");
  }
  if (!sandbox.includes('id="theme-stylesheet"')) {
    fail("Sandbox is missing #theme-stylesheet");
  }
  const blocking = sheetBlockingReasons(sandbox);
  if (blocking.length) {
    fail(`ZG-23/cold-sheet-blocking ${blocking.join("; ")}`);
  } else {
    pass("ZG-23/cold-sheet-blocking #theme-stylesheet is a render-blocking <link> in <head>");
  }

  const ports = fs.readFileSync(path.join(frontendDir, "static", "ports.js"), "utf8");
  const dualLink =
    /createElement\(\s*["']link["']\s*\)/.test(ports) &&
    /data-theme-incoming/.test(ports) &&
    /whenStylesheetReady/.test(ports);
  if (!dualLink) {
    fail("S1 stub: ports.js only swaps #theme-stylesheet href and would drop the old sheet first");
  } else {
    pass("S1 ports.js keeps the outgoing Theme sheet until the incoming sheet is ready");
  }

  if (!/printGarden\.subscribe/.test(ports) || !/contentWindow\.print/.test(ports)) {
    fail("U3 stub: Garden Print no longer calls iframe.contentWindow.print()");
  } else {
    pass("U3 Garden Print still prints the child document via contentWindow.print()");
  }
  if (!/data-garden-shell-printing/.test(ports) || !/garden-print-host/.test(ports)) {
    fail("U3 stub: File → Print no longer hoists .rz-resume into the chrome shell");
  } else {
    pass("U3 File → Print / Ctrl+P hoists .rz-resume so Theme page-breaks apply");
  }

  const nightgarden = readTheme("nightgarden");
  const quarto = readTheme("quarto");
  const switchyard = readTheme("switchyard");

  if (!/\/\*\s*rz-target:\s*web\s*\*\//i.test(nightgarden) || !/@keyframes/.test(nightgarden)) {
    fail("S3 Nightgarden must stay rz-target:web with @keyframes");
  } else {
    pass("S3 Nightgarden is rz-target:web and still has @keyframes");
  }
  if (/@media\s+print[\s\S]{0,400}background:\s*#070b14/.test(nightgarden)) {
    fail("S3 Nightgarden print still uses a dark full-bleed background");
  } else {
    pass("S3 Nightgarden print no longer sets a dark full-bleed background");
  }

  if (!/\/\*\s*rz-target:\s*print\s*\*\//i.test(quarto) || /@keyframes/.test(quarto)) {
    fail("S2 Quarto must stay rz-target:print with no @keyframes");
  } else {
    pass("S2 Quarto is rz-target:print and has no @keyframes");
  }
  if (!/\/\*\s*rz-target:\s*both\s*\*\//i.test(switchyard) || /@keyframes/.test(switchyard)) {
    fail("Switchyard must stay rz-target:both with no @keyframes");
  }

  const themeId = fs.readFileSync(path.join(frontendDir, "src", "ThemeId.elm"), "utf8");
  if (!/fallback\s*=\s*"nightgarden"/.test(themeId)) {
    fail("S5 ThemeId.fallback is not nightgarden");
  } else {
    pass("S5 unknown/empty Theme query defaults to nightgarden in pure calc");
  }

  const chromeCss = fs.readFileSync(path.join(frontendDir, "css", "chrome.css"), "utf8");
  if (/\.theme-switcher__item input[\s\S]{0,120}pointer-events:\s*none/.test(chromeCss)) {
    fail("S4 theme options are hidden from pointer/keyboard with pointer-events:none");
  }
  if (!/\.theme-switcher__option:focus-visible/.test(chromeCss)) {
    fail("S4 missing :focus-visible ring on theme options");
  } else {
    pass("S4 theme options are buttons with a :focus-visible ring");
  }

  const printCss = extractMediaBlocks(chromeCss)
    .filter((block) => /\bprint\b/.test(block.prelude))
    .map((block) => block.body.replace(/\/\*[\s\S]*?\*\//g, " "))
    .join("\n");
  if (/(\.garden-frame|\.garden-stage--print)[\s\S]{0,240}(?:min-)?height:\s*[^;]*\d(?:\.\d+)?(?:v[hwd]|dvh|svh|lvh)/i.test(printCss)) {
    fail("U3 stub: @media print still sets a viewport-height on .garden-frame / .garden-stage--print");
  } else if (!/\.garden-stage--print\s+\.garden-frame/.test(printCss) || !/min-height:\s*0/.test(printCss)) {
    fail("U3 @media print does not beat .garden-stage--print .garden-frame { min-height: 100vh }");
  } else {
    pass("U3 @media print drops viewport-height on .garden-frame and .garden-stage--print");
  }

  const leftoverNarrowVh = extractMediaBlocks(chromeCss).some((block) => {
    if (!/max-width/.test(block.prelude)) {
      return false;
    }
    const isScreen = /\bscreen\b/.test(block.prelude);
    return !isScreen && /\.garden-frame[\s\S]{0,80}\d(?:\.\d+)?vh/.test(block.body);
  });
  if (leftoverNarrowVh) {
    fail("U3 leftover: a non-screen max-width rule still sets .garden-frame to a vh height (clips letter-width print)");
  } else {
    pass("U3 narrow .garden-frame vh is screen-only");
  }
}

function startServer() {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [path.join(__dirname, "serve.mjs")], {
      cwd: frontendDir,
      env: { ...process.env, PORT: String(port) },
      stdio: ["ignore", "pipe", "pipe"],
    });
    const onData = (buf) => {
      const text = buf.toString();
      if (text.includes("Garden chrome")) {
        child.stdout.off("data", onData);
        resolve(child);
      }
    };
    child.stdout.on("data", onData);
    child.stderr.on("data", (buf) => process.stderr.write(buf));
    child.on("error", reject);
    setTimeout(() => reject(new Error("Server did not start")), 8000);
  });
}

async function captureFrame(page) {
  return page.evaluate(() => {
    const iframe = document.getElementById("garden-frame");
    const doc = iframe?.contentDocument;
    const name = doc?.querySelector(".rz-name");
    const resume = doc?.querySelector(".rz-resume");
    if (!doc || !name || !resume) {
      return null;
    }
    const ns = getComputedStyle(name);
    return {
      schema: resume.getAttribute("data-rz-schema"),
      name: name.textContent.trim(),
      html: resume.innerHTML,
      href: doc.getElementById("theme-stylesheet")?.getAttribute("href") || "",
      incoming: Boolean(doc.querySelector('link[data-theme-incoming="true"]')),
      sheets: [...doc.querySelectorAll('link[rel="stylesheet"]')].map((n) => n.getAttribute("href")),
      src: iframe.getAttribute("src"),
      pathname: location.pathname,
      search: location.search,
      font: ns.fontFamily,
      color: ns.color,
      resumeBg: getComputedStyle(resume).backgroundColor,
      htmlBg: getComputedStyle(doc.documentElement).backgroundColor,
      bodyBg: getComputedStyle(doc.body).backgroundColor,
    };
  });
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

async function sampleDuring(page, action, frames = 48) {
  const started = page.evaluate((limit) => {
    return new Promise((resolve) => {
      const samples = [];
      let count = 0;
      const tick = () => {
        const iframe = document.getElementById("garden-frame");
        const doc = iframe?.contentDocument;
        const name = doc?.querySelector(".rz-name");
        const resume = doc?.querySelector(".rz-resume");
        if (name && resume) {
          const ns = getComputedStyle(name);
          samples.push({
            name: name.textContent.trim(),
            html: resume.innerHTML,
            src: iframe.getAttribute("src"),
            href: doc.getElementById("theme-stylesheet")?.getAttribute("href") || "",
            font: ns.fontFamily,
            resumeBg: getComputedStyle(resume).backgroundColor,
            htmlBg: getComputedStyle(doc.documentElement).backgroundColor,
            bodyBg: getComputedStyle(doc.body).backgroundColor,
          });
        }
        count += 1;
        if (count < limit) {
          requestAnimationFrame(tick);
        } else {
          resolve(samples);
        }
      };
      requestAnimationFrame(tick);
    });
  }, frames);
  await action();
  return started;
}

async function dateGeometry(page) {
  return page.evaluate(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    const resume = doc?.querySelector(".rz-resume");
    if (!doc || !resume) {
      return { ok: false, reason: "missing resume" };
    }
    const style = getComputedStyle(resume);
    const box = resume.getBoundingClientRect();
    const left = box.left + parseFloat(style.paddingLeft);
    const right = box.right - parseFloat(style.paddingRight);
    const top = box.top + parseFloat(style.paddingTop);
    const bottom = box.bottom - parseFloat(style.paddingBottom);
    const nodes = [...doc.querySelectorAll(".rz-date, time[datetime]")];
    const clipped = [];
    for (const node of nodes) {
      const r = node.getBoundingClientRect();
      if (r.width === 0 && r.height === 0) {
        continue;
      }
      const slack = 0.6;
      if (r.left + slack < left || r.right - slack > right || r.top + slack < top || r.bottom - slack > bottom) {
        clipped.push({
          text: node.textContent.trim(),
          left: r.left,
          right: r.right,
          contentLeft: left,
          contentRight: right,
        });
      }
    }
    const scrollX =
      doc.documentElement.scrollWidth > doc.documentElement.clientWidth + 1 ||
      doc.body.scrollWidth > doc.body.clientWidth + 1;
    const parentScroll = document.documentElement.scrollWidth > document.documentElement.clientWidth + 1;
    return {
      ok: true,
      clipped,
      scrollX,
      parentScroll,
      overflowX: style.overflowX,
      htmlOverflowX: getComputedStyle(doc.documentElement).overflowX,
      bodyOverflowX: getComputedStyle(doc.body).overflowX,
      count: nodes.length,
    };
  });
}

async function rz3BrowserProbes(page) {
  const sandboxMeta = await captureFrame(page);
  if (!sandboxMeta) {
    fail("Sandbox frame is missing after load");
    return null;
  }
  if (sandboxMeta.schema !== "1.0") {
    fail(`Sandbox data-rz-schema is ${sandboxMeta.schema}`);
  } else {
    pass("Live sandbox has data-rz-schema=\"1.0\"");
  }
  if (sandboxMeta.name !== "Jordan Hale") {
    fail(`Expected Jordan Hale in .rz-name, got ${sandboxMeta.name}`);
  } else {
    pass("Jordan Hale is in .rz-name");
  }

  const switcherVisible = await page.locator(".theme-switcher").evaluate((el) => {
    const style = getComputedStyle(el);
    return style.display !== "none" && style.visibility !== "hidden";
  });
  if (!switcherVisible) {
    fail("Chrome .theme-switcher is not visible");
  } else {
    pass("Chrome renders a visible .theme-switcher");
  }

  const themeButtons = page.locator(".theme-switcher__option");
  const count = await themeButtons.count();
  if (count < 3) {
    fail(`Theme switcher lists ${count} themes; expected at least 3`);
  } else {
    pass(`Theme switcher lists ${count} themes`);
  }

  await selectTheme(page, "quarto");
  const afterQuarto = await captureFrame(page);
  if (!afterQuarto.href.includes("quarto.css")) {
    fail(`Theme href after Quarto is ${afterQuarto?.href}`);
  } else {
    pass(`Theme <link> href swapped to ${afterQuarto.href}`);
  }
  if (afterQuarto.html !== sandboxMeta.html) {
    fail(".rz-resume inner HTML changed during theme swap");
  } else {
    pass(".rz-resume inner HTML is unchanged after swap");
  }
  if (afterQuarto.name !== "Jordan Hale") {
    fail("Jordan Hale missing after swap");
  } else {
    pass("Jordan Hale is still in .rz-name after swap");
  }
  if (afterQuarto.pathname !== sandboxMeta.pathname) {
    fail("location.pathname changed during swap");
  } else {
    pass("Chrome location.pathname is unchanged");
  }
  if (afterQuarto.src !== sandboxMeta.src) {
    fail(`iframe src changed from ${sandboxMeta.src} to ${afterQuarto.src}`);
  } else {
    pass("iframe src is unchanged");
  }

  await selectTheme(page, "nightgarden");
  const motion = await page.evaluate(() => {
    const root = document.getElementById("garden-frame").contentDocument.querySelector(".rz-resume");
    return [...root.querySelectorAll("*")].some((el) => {
      const name = getComputedStyle(el).animationName;
      return name && name !== "none";
    });
  });
  if (!motion) {
    fail("Nightgarden screen motion is missing (animation-name: none on every descendant)");
  } else {
    pass("Nightgarden screen motion is running on a .rz-resume descendant");
  }

  await page.getByRole("button", { name: "Print preview" }).click();
  await page.waitForTimeout(400);
  const printMotion = await page.evaluate(() => {
    const root = document.getElementById("garden-frame").contentDocument.querySelector(".rz-resume");
    return [...root.querySelectorAll("*")].map((el) => getComputedStyle(el).animationName).filter((n) => n && n !== "none");
  });
  if (printMotion.length) {
    fail(`Print preview still runs Nightgarden motion (${printMotion.join(", ")})`);
  } else {
    pass("Print preview does not keep Nightgarden screen motion running");
  }

  await page.getByRole("button", { name: "Screen", exact: true }).click();
  await page.waitForTimeout(200);

  const leak = await page.evaluate(() => {
    const iframe = document.getElementById("garden-frame");
    const style = iframe.contentDocument.createElement("style");
    style.textContent = ".theme-switcher{display:none}";
    iframe.contentDocument.head.appendChild(style);
    return getComputedStyle(document.querySelector(".theme-switcher")).display;
  });
  if (leak === "none") {
    fail("Theme CSS leaked: Chrome .theme-switcher computed display is none");
  } else {
    pass(`Theme .theme-switcher{display:none} left Chrome display as ${leak}`);
  }

  const chromePreview = await page.evaluate(() => {
    return [...document.styleSheets].some((sheet) => {
      const href = sheet.href || "";
      return href.includes("preview.css");
    });
  });
  if (chromePreview) {
    fail("Chrome linked skeleton/preview.css");
  } else {
    pass("Chrome does not link skeleton/preview.css");
  }

  return sandboxMeta;
}

async function s1Probes(browser, page, identity) {
  await page.route("**/themes/*.css", async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 180));
    await route.continue();
  });

  const cycle = ["quarto", "switchyard", "nightgarden"];
  const samples = await sampleDuring(page, async () => {
    for (const id of cycle) {
      await page.locator(`#theme-option-${id}`).click();
      await page.waitForTimeout(80);
    }
  }, 70);

  await waitForThemeHref(page, "nightgarden");
  await page.unroute("**/themes/*.css");

  const fouc = samples.filter(isFoucSample);
  if (fouc.length) {
    fail(`S1 FOUC: ${fouc.length} committed frame(s) painted UA-default serif on a blank canvas`);
  } else {
    pass("S1 Nightgarden → Quarto → Switchyard → Nightgarden never painted UA-default serif on a blank canvas");
  }

  const drifted = samples.filter((sample) => sample.name !== "Jordan Hale" || sample.src !== identity.src || sample.html !== identity.html);
  if (drifted.length) {
    fail("S1 identity drifted during swap (.rz-name / iframe src / .rz-resume HTML)");
  } else {
    pass("S1 identity stayed put: .rz-resume HTML, iframe src, .rz-name text");
  }

  reportColdPaint(await coldLoadPaintTiming(browser));
}

async function coldLoadPaintTiming(browser) {
  const cold = await browser.newPage();
  await holdThemeSheets(cold, COLD_SHEET_DELAY_MS);
  await cold.goto(origin + "/", { waitUntil: "commit" });
  await waitForSandboxComplete(cold);
  await cold.waitForTimeout(COLD_SETTLE_MS);
  const timing = await readSandboxPaintTiming(sandboxFrame(cold));
  await releaseThemeSheets(cold);
  await cold.close();
  return timing;
}

function reportColdPaint(timing) {
  const order = paintOrderReasons(timing, COLD_SHEET_DELAY_MS);
  if (order.length) {
    fail(`ZG-23/cold-paint-order ${order.join("; ")}`);
  } else {
    pass(`ZG-23/cold-paint-order ${describePaintOrder(timing)}`);
  }

  const presence = paintPresenceReasons(timing, isUaDefaultSerif);
  if (presence.length) {
    fail(`ZG-23/cold-paint-present ${presence.join("; ")}`);
  } else {
    pass("ZG-23/cold-paint-present first-paint and first-contentful-paint recorded in the styled sandbox");
  }
}

async function s2Probes(page) {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.getByRole("button", { name: "Screen", exact: true }).click();

  for (const id of THEME_IDS) {
    await selectTheme(page, id);
    await page.waitForTimeout(150);
    const geometry = await dateGeometry(page);
    if (!geometry.ok) {
      fail(`S2 ${id}: ${geometry.reason}`);
      continue;
    }
    if (geometry.count === 0) {
      fail(`S2 ${id}: no .rz-date / time[datetime] nodes`);
      continue;
    }
    if (geometry.clipped.length) {
      fail(
        `S2 ${id}: ${geometry.clipped.length} date(s) overflow the .rz-resume content box` +
          ` (${geometry.clipped[0].text})`,
      );
    } else {
      pass(`S2 ${id}: every .rz-date and time[datetime] is inside the .rz-resume content box`);
    }
    if (geometry.scrollX || geometry.parentScroll) {
      const hidden =
        geometry.overflowX === "hidden" ||
        geometry.htmlOverflowX === "hidden" ||
        geometry.bodyOverflowX === "hidden";
      if (hidden) {
        fail(`S2 ${id}: overflow:hidden hid a horizontal bar while the document still overflows`);
      } else {
        fail(`S2 ${id}: horizontal scrollbar at 1280×800`);
      }
    }
  }
}

const REQUIRED_PRINT_SECTIONS = [
  { id: "education", title: "Education" },
  { id: "awards", title: "Awards" },
  { id: "projects", title: "Projects" },
  { id: "certificates", title: "Certificates" },
];
const U3_PRINT_PAGES = {
  nightgarden: 2,
  quarto: 2,
  switchyard: 2,
};
// Exact per-theme printToPDF page counts of frontend/fixtures/long-resume.html
// (every value <= 3), measured with the ZG-11 theme sheets.
const LONG_PRINT_PAGES = {
  nightgarden: 3,
  quarto: 3,
  switchyard: 3,
};

function missingPrintSections(sections) {
  return sections.filter((section) => !section.present || section.titleText !== section.want);
}

async function readPrintSections(page, root = "document") {
  return page.evaluate((wanted) => {
    const doc = document;
    return wanted.map((section) => {
      const el =
        doc.getElementById(`rz-${section.id}`) || doc.querySelector(`[data-rz-section="${section.id}"]`);
      return {
        id: section.id,
        want: section.title,
        present: Boolean(el),
        titleText: (el?.querySelector(".rz-section-title")?.textContent || "").trim(),
      };
    });
  }, REQUIRED_PRINT_SECTIONS);
}

async function pdfPagesForTheme(browser, href) {
  const page = await browser.newPage();
  await page.goto(origin + "/sandbox.html", { waitUntil: "networkidle" });
  await waitThemeReady(page, href);
  const pdf = await printToPdf(page);
  const pages = countPdfPages(pdf);
  const sections = await readPrintSections(page);
  const lastSection = await page.evaluate(() => {
    const nodes = [...document.querySelectorAll("[data-rz-section]")];
    return nodes.at(-1)?.getAttribute("data-rz-section") || "";
  });
  await page.emulateMedia({ media: "print" });
  const fills = await page.evaluate(() => {
    const resume = document.querySelector(".rz-resume");
    return {
      html: getComputedStyle(document.documentElement).backgroundColor,
      body: getComputedStyle(document.body).backgroundColor,
      resume: resume ? getComputedStyle(resume).backgroundColor : "transparent",
    };
  });
  await page.close();
  return { pages, fills, sections, lastSection, pdf };
}

async function s3Probes(browser, page) {
  await selectTheme(page, "nightgarden");
  await page.getByRole("button", { name: "Screen", exact: true }).click();
  await page.waitForTimeout(200);

  const screenMotion = await page.evaluate(() => {
    const root = document.getElementById("garden-frame").contentDocument.querySelector(".rz-resume");
    return [...root.querySelectorAll("*")]
      .map((el) => getComputedStyle(el).animationName)
      .filter((name) => name && name !== "none");
  });
  if (!screenMotion.length) {
    fail("S3 Nightgarden screen has no animation-name other than none");
  } else {
    pass(`S3 Nightgarden screen still animates (${screenMotion[0]})`);
  }

  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.waitForTimeout(200);
  const reduced = await page.evaluate(() => {
    const root = document.getElementById("garden-frame").contentDocument.querySelector(".rz-resume");
    return [...root.querySelectorAll("*")]
      .map((el) => getComputedStyle(el).animationName)
      .filter((name) => name && name !== "none");
  });
  if (reduced.length) {
    fail(`S3 prefers-reduced-motion still runs motion (${reduced.join(", ")})`);
  } else {
    pass("S3 prefers-reduced-motion kills Nightgarden motion");
  }
  await page.emulateMedia({ reducedMotion: "no-preference" });

  const night = await pdfPagesForTheme(browser, "themes/nightgarden.css");
  const quarto = await pdfPagesForTheme(browser, "themes/quarto.css");
  const switchyard = await pdfPagesForTheme(browser, "themes/switchyard.css");
  const budget = Math.max(quarto.pages, switchyard.pages) + 1;

  if (isDarkFill(night.fills.html) || isDarkFill(night.fills.body) || isDarkFill(night.fills.resume)) {
    fail(`S3 Nightgarden print still has a dark full-bleed (${night.fills.html} / ${night.fills.body} / ${night.fills.resume})`);
  } else {
    pass("S3 Nightgarden print paper is not a dark full-bleed");
  }

  if (!night.pages || !quarto.pages || !switchyard.pages) {
    fail(`S3 could not count print pages (N=${night.pages} Q=${quarto.pages} S=${switchyard.pages})`);
  } else if (night.pages > budget) {
    fail(`S3 Nightgarden print is ${night.pages} pages; budget is max(${quarto.pages}, ${switchyard.pages})+1 = ${budget}`);
  } else {
    pass(`S3 Nightgarden print is ${night.pages} pages (Quarto ${quarto.pages}, Switchyard ${switchyard.pages})`);
  }

  for (const [id, result] of [
    ["nightgarden", night],
    ["quarto", quarto],
    ["switchyard", switchyard],
  ]) {
    const missing = missingPrintSections(result.sections || []);
    const wantPages = U3_PRINT_PAGES[id];
    if (result.pages !== wantPages) {
      fail(`U3 ${id} Garden/iframe printToPDF is ${result.pages} page(s); walk bar is ${wantPages}`);
    } else if (missing.length) {
      fail(`U3 ${id} print document is missing ${missing.map((section) => section.want).join(", ")}`);
    } else if (result.lastSection !== "projects") {
      fail(`U3 ${id} print document ends at ${result.lastSection || "(none)"}; walk bar ends at Projects`);
    } else {
      pass(`U3 ${id} Garden/iframe printToPDF is ${result.pages} pages and ends at Projects`);
    }
  }
}

async function u3IframePrintProbes(browser, page) {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.getByRole("button", { name: "Screen", exact: true }).click();

  for (const id of THEME_IDS) {
    await selectTheme(page, id);
    await page.waitForTimeout(150);

    await page.evaluate(() => {
      const iframe = document.getElementById("garden-frame");
      const win = iframe.contentWindow;
      win.__originalPrint = win.print.bind(win);
      win.__printCalled = false;
      win.print = function () {
        win.__printCalled = true;
      };
    });

    await page.locator(".preview-controls__print").click();
    const buttonPath = await page.waitForFunction(() => {
      return Boolean(document.getElementById("garden-frame")?.contentWindow?.__printCalled);
    });

    await page.evaluate(() => {
      const win = document.getElementById("garden-frame")?.contentWindow;
      if (win && win.__originalPrint) {
        win.print = win.__originalPrint;
        win.__printCalled = false;
      }
    });

    if (!buttonPath) {
      fail(`U3 ${id}: Garden Print did not call iframe.contentWindow.print()`);
    } else {
      pass(`U3 ${id}: Garden Print still calls iframe.contentWindow.print()`);
    }

    const wantPages = U3_PRINT_PAGES[id];
    const garden = await pdfPagesForTheme(browser, `themes/${id}.css`);
    if (garden.pages !== wantPages) {
      fail(`U3 ${id}: Garden printToPDF is ${garden.pages} page(s); walk bar is ${wantPages}`);
    } else if (missingPrintSections(garden.sections).length) {
      fail(`U3 ${id}: Garden printToPDF is missing a required section`);
    } else if (garden.lastSection !== "projects") {
      fail(`U3 ${id}: Garden printToPDF ends at ${garden.lastSection}; walk bar ends at Projects`);
    } else {
      pass(`U3 ${id}: Garden printToPDF is ${garden.pages} pages and ends at Projects`);
    }

    await page.evaluate(() => {
      window.dispatchEvent(new Event("beforeprint"));
    });
    const late = await page.evaluate((wanted) => {
      const host = document.getElementById("garden-print-host");
      const doc = host || document.getElementById("garden-frame")?.contentDocument;
      const last = [...(doc?.querySelectorAll("[data-rz-section]") || [])]
        .at(-1)
        ?.getAttribute("data-rz-section") || "";
      return {
        hoisted: Boolean(host),
        last,
        sections: wanted.map((section) => {
          const el =
            doc?.querySelector(`#rz-${section.id}`) ||
            doc?.querySelector(`[data-rz-section="${section.id}"]`);
          return {
            id: section.id,
            want: section.title,
            present: Boolean(el),
            titleText: (el?.querySelector(".rz-section-title")?.textContent || "").trim(),
          };
        }),
      };
    }, REQUIRED_PRINT_SECTIONS);

    const shellPdf = await printToPdf(page);
    await page.evaluate(() => {
      window.dispatchEvent(new Event("afterprint"));
    });
    const shellPages = countPdfPages(shellPdf);
    const missing = missingPrintSections(late.sections);
    if (!late.hoisted) {
      fail(`U3 ${id}: File → Print did not hoist .rz-resume into the chrome shell`);
    } else if (shellPages !== wantPages) {
      fail(`U3 ${id}: chrome-shell printToPDF is ${shellPages} page(s); walk bar is ${wantPages}`);
    } else if (missing.length) {
      fail(`U3 ${id}: chrome-shell print is missing ${missing.map((section) => section.want).join(", ")}`);
    } else if (late.last !== "projects") {
      fail(`U3 ${id}: chrome-shell print ends at ${late.last}; walk bar ends at Projects`);
    } else {
      pass(`U3 ${id}: chrome-shell printToPDF is ${shellPages} pages and ends at Projects`);
    }

    const artifactDir = process.env.U3_ARTIFACT_DIR;
    if (artifactDir) {
      fs.mkdirSync(artifactDir, { recursive: true });
      fs.writeFileSync(path.join(artifactDir, `u3_${id}_garden_printtopdf.pdf`), garden.pdf);
      fs.writeFileSync(path.join(artifactDir, `u3_${id}_shell_printtopdf.pdf`), shellPdf);
    }
  }
}

async function s4Probes(page) {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto(origin + "/", { waitUntil: "networkidle" });
  await page.waitForSelector(".theme-switcher__option");

  for (const name of ["Nightgarden", "Quarto", "Switchyard"]) {
    const visible = await page.locator(".theme-switcher__name", { hasText: name }).isVisible();
    if (!visible) {
      fail(`S4 Theme name ${name} is not visible`);
    }
  }
  pass("S4 Theme names Nightgarden, Quarto, Switchyard are visible");

  await page.evaluate(() => {
    const active = document.activeElement;
    if (active && active !== document.body) {
      active.blur();
    }
    document.body.focus();
  });

  const visited = [];
  let sawIframe = false;
  let iframeBeforeChrome = false;
  for (let i = 0; i < 24; i += 1) {
    await page.keyboard.press("Tab");
    const info = await page.evaluate(() => {
      const el = document.activeElement;
      if (!el) {
        return null;
      }
      const style = getComputedStyle(el);
      return {
        id: el.id || "",
        tag: el.tagName,
        className: typeof el.className === "string" ? el.className : "",
        text: (el.innerText || el.textContent || "").replace(/\s+/g, " ").trim(),
        outlineStyle: style.outlineStyle,
        outlineWidth: style.outlineWidth,
        boxShadow: style.boxShadow,
      };
    });
    if (!info) {
      continue;
    }
    visited.push(info);
    if (info.id === "garden-frame") {
      sawIframe = true;
      const chromeClicked = visited.some((item) => item.className.includes("theme-switcher__option") || /Screen|Print/.test(item.text));
      if (!chromeClicked) {
        iframeBeforeChrome = true;
      }
      break;
    }
  }

  if (iframeBeforeChrome) {
    fail("S4 Tab reached the iframe before garden chrome controls");
  } else {
    pass("S4 Tab visits chrome before the iframe");
  }

  const reached = {
    nightgarden: visited.some((item) => item.id === "theme-option-nightgarden"),
    quarto: visited.some((item) => item.id === "theme-option-quarto"),
    switchyard: visited.some((item) => item.id === "theme-option-switchyard"),
    screen: visited.some((item) => item.text === "Screen"),
    print: visited.some((item) => item.text === "Print" || item.text === "Print preview"),
  };
  for (const [key, ok] of Object.entries(reached)) {
    if (!ok) {
      fail(`S4 Tab never reached ${key}`);
    }
  }
  if (Object.values(reached).every(Boolean)) {
    pass("S4 Tab reaches each theme option and Print/Screen without a pointer");
  }

  const themed = visited.filter((item) => item.className.includes("theme-switcher__option") || item.className.includes("btn"));
  const ringless = themed.filter((item) => {
    const width = parseFloat(item.outlineWidth || "0");
    const hasOutline = item.outlineStyle && item.outlineStyle !== "none" && width > 0;
    const hasShadow = item.boxShadow && item.boxShadow !== "none";
    return !hasOutline && !hasShadow;
  });
  if (ringless.length) {
    fail(`S4 focused chrome control is missing a visible :focus-visible ring (${ringless[0].text || ringless[0].id})`);
  } else if (themed.length) {
    pass("S4 focused garden controls show a visible :focus-visible ring");
  }

  await page.locator("#theme-option-nightgarden").focus();
  await page.keyboard.press("Tab");
  await page.keyboard.press("Space");
  await waitForThemeHref(page, "quarto");
  const afterSpace = await captureFrame(page);
  if (!afterSpace.href.includes("quarto.css")) {
    fail("S4 Space/Enter did not activate the focused theme option");
  } else {
    pass("S4 Space activates the focused theme option");
  }
}

async function s5Probes(page) {
  await page.goto(origin + "/", { waitUntil: "networkidle" });
  await page.waitForSelector("#theme-option-nightgarden");
  await selectTheme(page, "quarto");
  const quartoUrl = new URL(page.url());
  if (quartoUrl.searchParams.get("theme") !== "quarto") {
    fail(`S5 selecting Quarto set ${quartoUrl.search}, expected ?theme=quarto`);
  } else {
    pass("S5 selecting a Theme sets ?theme=quarto (lowercase)");
  }

  await selectTheme(page, "nightgarden");
  const nightUrl = new URL(page.url());
  if (nightUrl.searchParams.get("theme") !== "nightgarden") {
    fail(`S5 selecting Nightgarden set ${nightUrl.search}, expected ?theme=nightgarden`);
  } else {
    pass("S5 selecting Nightgarden sets ?theme=nightgarden");
  }

  await selectTheme(page, "quarto");
  await page.goBack();
  await waitForThemeHref(page, "nightgarden");
  const back = await captureFrame(page);
  const backParam = new URL(page.url()).searchParams.get("theme");
  if (!back.href.includes("nightgarden.css") || back.name !== "Jordan Hale") {
    fail("S5 Back after Nightgarden→Quarto did not restore Nightgarden");
  } else if (backParam && backParam !== "nightgarden") {
    fail(`S5 Back restored href Nightgarden but query is ${backParam}`);
  } else {
    pass("S5 Back after Nightgarden→Quarto restores Nightgarden");
  }

  await page.goto(origin + "/?theme=switchyard", { waitUntil: "networkidle" });
  await waitForThemeHref(page, "switchyard");
  const coldSwitch = await captureFrame(page);
  const selected = await page.locator("#theme-option-switchyard").getAttribute("aria-pressed");
  if (!coldSwitch.href.includes("switchyard.css") || selected !== "true") {
    fail("S5 cold load of ?theme=switchyard did not select Switchyard");
  } else {
    pass("S5 cold load of ?theme=switchyard selects Switchyard");
  }

  for (const raw of ["", "NOPE", "Theme%20X"]) {
    const href = raw === "" ? "/?theme=" : `/?theme=${raw}`;
    const response = await page.goto(origin + href, { waitUntil: "networkidle" });
    if (!response || response.status() >= 500) {
      fail(`S5 ${href} returned ${response?.status()}`);
      continue;
    }
    await page.waitForSelector(".rz-resume, #garden-frame");
    await waitForThemeHref(page, "nightgarden");
    const frame = await captureFrame(page);
    if (!frame || !frame.html || frame.name !== "Jordan Hale") {
      fail(`S5 ${href} left an empty stage`);
    } else if (!frame.href.includes("nightgarden.css")) {
      fail(`S5 ${href} did not default to Nightgarden (${frame.href})`);
    } else {
      pass(`S5 ${href} defaults to Nightgarden without emptying the stage`);
    }
  }
}

async function browserProbes() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto(origin + "/", { waitUntil: "networkidle" });
  await page.waitForSelector(".theme-switcher");
  await page.waitForSelector("#garden-frame");
  await page.frameLocator("#garden-frame").locator(".rz-resume").waitFor();

  const identity = await rz3BrowserProbes(page);
  if (identity) {
    await s1Probes(browser, page, identity);
    await s2Probes(page);
    await s3Probes(browser, page);
    await u3IframePrintProbes(browser, page);
    await s4Probes(page);
    await s5Probes(page);
    await zg11Group(browser);
    await zg12Group(browser);
    await zg4Probes({ browser, origin, report: { pass, fail }, repoDir, frontendDir });
    await zg5Probes({ browser, origin, report: { pass, fail }, repoDir, frontendDir });
    await zg6Probes({ browser, origin, report: { pass, fail }, repoDir, frontendDir });
    await zg7Probes({ browser, origin, report: { pass, fail }, repoDir, frontendDir });
    await zg8Probes({ browser, origin, report: { pass, fail }, repoDir, frontendDir });
    await zg9Probes({ browser, origin, report: { pass, fail }, repoDir, frontendDir });
    await zg10Probes({ browser, origin, report: { pass, fail }, repoDir, frontendDir });
  }

  await browser.close();
}

// RZ_ZG11_BASE=<git rev> / RZ_ZG12_BASE=<git rev> run that group against the
// revision's theme sheets (injected in place of #theme-stylesheet) for
// anti-vacuity evidence.
async function zg11Group(browser) {
  await zg11Probes({
    browser,
    origin,
    report: { pass, fail },
    fixtureHtml: fs.readFileSync(path.join(frontendDir, "fixtures", "long-resume.html"), "utf8"),
    expectedPages: { jordan: U3_PRINT_PAGES, long: LONG_PRINT_PAGES },
    sheetSource: sheetSourceFor(repoDir, process.env.RZ_ZG11_BASE),
  });
}

async function zg12Group(browser) {
  await zg12Probes({ browser, origin, report: { pass, fail }, sheetSource: sheetSourceFor(repoDir, process.env.RZ_ZG12_BASE) });
}

staticProbes();

const server = await startServer();
try {
  await browserProbes();
} finally {
  server.kill("SIGTERM");
}

if (failures.length) {
  console.error(`\n${failures.length} probe(s) failed.`);
  process.exit(1);
}

console.log("\nAll RZ-3, RZ-S1…S5, U3 print, ZG-23, ZG-4, ZG-5, ZG-6, ZG-7, ZG-8, ZG-9, ZG-10, ZG-11 and ZG-12 probes passed.");
