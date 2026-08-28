/**
 * ZG-8 probes: copy the exact view, keep an unknown ?theme=, mirror view=.
 *
 * Clipboard happy path grants both permissions. Failure path overrides
 * writeText before navigation. Notice copy is `textContent` so a raw
 * query value cannot become markup.
 */
import { openGarden } from "./lib/page.mjs";
import { pageErrorReasons } from "./lib/paste.mjs";
import { parseRgb } from "./lib/contrast.mjs";

const COPY_FAILED = "Copy failed — select the address bar and copy it";
const FALLBACK_NAME = "Nightgarden";

function reportReasons(report, slug, reasons, okDetail) {
  if (reasons.length) {
    report.fail(`${slug} ${reasons.join("; ")}`);
    return false;
  }
  report.pass(`${slug} ${okDetail}`);
  return true;
}

// Calculation: why a garden href is missing the prescribed search params.
export function searchParamReasons(href, want) {
  const params = new URL(href, "https://garden.invalid").searchParams;
  return Object.entries(want).flatMap(([key, value]) => {
    const got = params.get(key);
    return got === value ? [] : [`${key} is ${JSON.stringify(got)}, wanted ${JSON.stringify(value)}`];
  });
}

export function isPaperWhite(color) {
  if (!color) {
    return false;
  }
  if (/^(#fff(?:fff)?|white)$/i.test(color)) {
    return true;
  }
  const rgb = parseRgb(color);
  if (!rgb || rgb.a < 0.9) {
    return false;
  }
  return rgb.r >= 250 && rgb.g >= 250 && rgb.b >= 250;
}

export function paperWhiteReasons(color) {
  return isPaperWhite(color) ? [] : [`iframe body background is ${JSON.stringify(color)}, wanted paper white`];
}

export function copiedReasons({ clipboardHref, copiedText, heldForSecond, cleared }) {
  return [
    ...searchParamReasons(clipboardHref, { theme: "quarto", view: "print" }),
    ...(copiedText === "Copied" ? [] : [`copied text is ${JSON.stringify(copiedText)}`]),
    ...(heldForSecond ? [] : ["Copied was gone before 1s"]),
    ...(cleared ? [] : ["Copied was still present after the 2s window"]),
  ];
}

export function copyFailedReasons({ failedText, sawCopied }) {
  return [
    ...(failedText.includes("select the address bar") ? [] : [`failed text is ${JSON.stringify(failedText)}`]),
    ...(failedText === COPY_FAILED ? [] : [`failed text is ${JSON.stringify(failedText)}, wanted ${JSON.stringify(COPY_FAILED)}`]),
    ...(sawCopied.length ? [`Copied appeared: ${JSON.stringify(sawCopied[0])}`] : []),
  ];
}

export function noticeTextReasons({ text, raw, shown }) {
  return [
    ...(text.includes(raw) ? [] : [`notice lacks ${JSON.stringify(raw)}: ${JSON.stringify(text)}`]),
    ...(text.includes(shown) ? [] : [`notice lacks ${JSON.stringify(shown)}: ${JSON.stringify(text)}`]),
  ];
}

export function noticeEscapeReasons({ text, hasB }) {
  return [
    ...(text.includes("<b>x</b>") ? [] : [`notice textContent is ${JSON.stringify(text)}`]),
    ...(hasB ? ["notice contains a <b> element"] : []),
  ];
}

export function noNoticeReasons(count) {
  return count === 0 ? [] : [`[data-theme-notice] count is ${count}`];
}

export function viewPressedReasons(pressed, want) {
  return pressed === want ? [] : [`aria-pressed is ${JSON.stringify(pressed)}, wanted ${JSON.stringify(want)}`];
}

export function viewBackReasons({ screenPressed, viewParam }) {
  const reasons = [];
  if (screenPressed !== "true") {
    reasons.push(`Screen aria-pressed is ${JSON.stringify(screenPressed)}`);
  }
  if (viewParam === "print") {
    reasons.push("URL still has view=print");
  } else if (viewParam !== null && viewParam !== "screen") {
    reasons.push(`view is ${JSON.stringify(viewParam)}`);
  }
  return reasons;
}

async function waitViewParam(page, value) {
  await page.waitForFunction((want) => new URL(window.location.href).searchParams.get("view") === want, value);
}

async function iframeBodyBackground(page) {
  return page.evaluate(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    return doc ? getComputedStyle(doc.body).backgroundColor : "";
  });
}

async function waitPaperBody(page) {
  await page.waitForFunction(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    if (!doc) {
      return false;
    }
    const color = getComputedStyle(doc.body).backgroundColor;
    const match = color.match(/rgba?\(\s*(\d+)[,\s]+(\d+)[,\s]+(\d+)/);
    return Boolean(match && Number(match[1]) >= 250 && Number(match[2]) >= 250 && Number(match[3]) >= 250);
  });
}

async function copyLinkProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin, {
    permissions: ["clipboard-read", "clipboard-write"],
    path: "/?theme=quarto",
  });
  await page.getByRole("button", { name: "Print preview" }).click();
  await waitViewParam(page, "print");
  await page.locator(".copy-link").click();
  const copied = page.locator('.copy-link[data-copy-state="copied"]');
  await copied.waitFor();
  const copiedText = await copied.textContent();
  const clipboardHref = await page.evaluate(() => navigator.clipboard.readText());
  await page.waitForTimeout(1000);
  const heldForSecond = (await page.locator('.copy-link[data-copy-state="copied"]').count()) === 1;
  await page.waitForSelector('.copy-link[data-copy-state="copied"]', { state: "detached" });
  const cleared = (await page.locator('.copy-link[data-copy-state="copied"]').count()) === 0;
  await page.close();
  reportReasons(
    report,
    "ZG-8/copy-link",
    [
      ...copiedReasons({ clipboardHref, copiedText, heldForSecond, cleared }),
      ...pageErrorReasons(pageErrors),
    ],
    "Copy link writes ?theme=quarto&view=print and shows Copied for ≥ 1s",
  );
}

async function copyFailedProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin, {
    beforeNavigate: (gardenPage) =>
      gardenPage.addInitScript(() => {
        Object.defineProperty(navigator, "clipboard", {
          configurable: true,
          value: {
            writeText: () => Promise.reject(new DOMException("Permission denied", "NotAllowedError")),
          },
        });
      }),
  });
  await page.locator(".copy-link").click();
  await page.waitForSelector('.copy-link[data-copy-state="failed"]');
  const failedText = await page.locator('.copy-link[data-copy-state="failed"]').textContent();
  const sawCopied = [];
  const started = Date.now();
  while (Date.now() - started < 500) {
    const state = await page.evaluate(() => {
      const copied = document.querySelector('.copy-link[data-copy-state="copied"]');
      return copied ? copied.textContent : null;
    });
    if (state) {
      sawCopied.push(state);
      break;
    }
    await page.waitForTimeout(50);
  }
  await page.close();
  reportReasons(
    report,
    "ZG-8/copy-failed",
    [...copyFailedReasons({ failedText, sawCopied }), ...pageErrorReasons(pageErrors)],
    "rejected writeText shows Copy failed and never Copied",
  );
}

async function viewUrlProbe({ browser, origin, report }) {
  const quarto = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const quartoPage = await quarto.newPage();
  const pageErrors = [];
  quartoPage.on("pageerror", (error) => pageErrors.push(error.message));
  await quartoPage.goto(`${origin}/?theme=quarto&view=print`, { waitUntil: "networkidle" });
  await quartoPage.frameLocator("#garden-frame").locator(".rz-resume").waitFor();
  await quartoPage.waitForSelector('.app-shell[data-preview="print"]');
  const quartoPressed = await quartoPage.getByRole("button", { name: "Print preview" }).getAttribute("aria-pressed");
  await quarto.close();

  const night = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const nightPage = await night.newPage();
  nightPage.on("pageerror", (error) => pageErrors.push(error.message));
  await nightPage.goto(`${origin}/?theme=nightgarden&view=print`, { waitUntil: "networkidle" });
  await nightPage.frameLocator("#garden-frame").locator(".rz-resume").waitFor();
  await nightPage.waitForSelector('.app-shell[data-preview="print"]');
  await waitPaperBody(nightPage);
  const nightBg = await iframeBodyBackground(nightPage);
  await nightPage.reload({ waitUntil: "networkidle" });
  await nightPage.frameLocator("#garden-frame").locator(".rz-resume").waitFor();
  const viewAfterReload = new URL(nightPage.url()).searchParams.get("view");
  const nightPressed = await nightPage.getByRole("button", { name: "Print preview" }).getAttribute("aria-pressed");
  await night.close();

  reportReasons(
    report,
    "ZG-8/view-url",
    [
      ...viewPressedReasons(quartoPressed, "true"),
      ...paperWhiteReasons(nightBg),
      ...(viewAfterReload === "print" ? [] : [`reload view is ${JSON.stringify(viewAfterReload)}`]),
      ...viewPressedReasons(nightPressed, "true"),
      ...pageErrorReasons(pageErrors),
    ],
    "?theme=&view=print opens Print preview; Nightgarden print body is white; reload keeps view",
  );
}

async function viewBackProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin, { path: "/?theme=quarto" });
  await page.getByRole("button", { name: "Print preview" }).click();
  await waitViewParam(page, "print");
  await page.goBack();
  await page.waitForSelector('.app-shell[data-preview="screen"]');
  const screenPressed = await page.getByRole("button", { name: "Screen", exact: true }).getAttribute("aria-pressed");
  const viewParam = new URL(page.url()).searchParams.get("view");
  await page.close();
  reportReasons(
    report,
    "ZG-8/view-back",
    [...viewBackReasons({ screenPressed, viewParam }), ...pageErrorReasons(pageErrors)],
    "Back after Print preview returns to Screen and drops or sets view=screen",
  );
}

async function unknownThemeProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin, { path: "/?theme=banana" });
  const themeParam = new URL(page.url()).searchParams.get("theme");
  const nightPressed = await page.locator("#theme-option-nightgarden").getAttribute("aria-pressed");
  const notice = page.locator('[data-theme-notice="unknown"]');
  await notice.waitFor();
  const text = await notice.evaluate((node) => node.textContent);
  await notice.locator("button").click();
  const gone = (await page.locator("[data-theme-notice]").count()) === 0;
  const themeAfter = new URL(page.url()).searchParams.get("theme");
  await page.close();
  reportReasons(
    report,
    "ZG-8/unknown-theme",
    [
      ...(themeParam === "banana" ? [] : [`theme is ${JSON.stringify(themeParam)}`]),
      ...(themeAfter === "banana" ? [] : [`theme after dismiss is ${JSON.stringify(themeAfter)}`]),
      ...viewPressedReasons(nightPressed, "true"),
      ...noticeTextReasons({ text, raw: "banana", shown: FALLBACK_NAME }),
      ...(gone ? [] : ["notice remained after Close"]),
      ...pageErrorReasons(pageErrors),
    ],
    "unknown ?theme=banana keeps the URL, names the miss, and Close dismisses it",
  );
}

async function noticeEscapedProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin, { path: "/?theme=%3Cb%3Ex%3C%2Fb%3E" });
  const notice = page.locator('[data-theme-notice="unknown"]');
  await notice.waitFor();
  const { text, hasB } = await notice.evaluate((node) => ({
    text: node.textContent,
    hasB: node.querySelector("b") !== null,
  }));
  await page.close();
  reportReasons(
    report,
    "ZG-8/notice-escaped",
    [...noticeEscapeReasons({ text, hasB }), ...pageErrorReasons(pageErrors)],
    "unknown theme notice renders the raw query as text, not markup",
  );
}

async function noNoticeProbe({ browser, origin, report }) {
  const reasons = [];
  const pageErrors = [];
  for (const path of ["/?theme=Quarto", "/", "/?theme="]) {
    const opened = await openGarden(browser, origin, { path });
    pageErrors.push(...opened.pageErrors);
    const count = await opened.page.locator("[data-theme-notice]").count();
    reasons.push(...noNoticeReasons(count).map((reason) => `${path} ${reason}`));
    await opened.page.close();
  }
  reportReasons(
    report,
    "ZG-8/no-notice",
    [...reasons, ...pageErrorReasons(pageErrors)],
    "/?theme=Quarto, /, and /?theme= show no theme notice",
  );
}

async function invalidViewProbe({ browser, origin, report }) {
  const { page, pageErrors } = await openGarden(browser, origin, { path: "/?view=sideways" });
  const screenPressed = await page.getByRole("button", { name: "Screen", exact: true }).getAttribute("aria-pressed");
  const noticeCount = await page.locator("[data-theme-notice]").count();
  await page.close();
  reportReasons(
    report,
    "ZG-8/invalid-view",
    [
      ...viewPressedReasons(screenPressed, "true"),
      ...noNoticeReasons(noticeCount),
      ...pageErrorReasons(pageErrors),
    ],
    "?view=sideways opens Screen with no notice and no crash",
  );
}

export async function zg8Probes(context) {
  await copyLinkProbe(context);
  await copyFailedProbe(context);
  await viewUrlProbe(context);
  await viewBackProbe(context);
  await unknownThemeProbe(context);
  await noticeEscapedProbe(context);
  await noNoticeProbe(context);
  await invalidViewProbe(context);
}
