/**
 * Shared Playwright page actions for the probe runner.
 *
 * Two surfaces live here: the Garden chrome (index.html with the sandbox in
 * `#garden-frame`) and the sandbox opened as a top-level page. Geometry and
 * print probes use the top-level page only — the Garden iframe lays the
 * article out at the chrome's width, never the paper's.
 *
 * Everything is an action except `extractArticle`, a pure calculation over
 * an HTML string.
 */

const THEME_SHEET_GLOB = "**/themes/*.css";

// Calculation: the `<article class="rz-resume" …>…</article>` of a document.
export function extractArticle(html) {
  const open = html.indexOf('<article class="rz-resume"');
  const close = html.lastIndexOf("</article>");
  if (open === -1 || close === -1 || close < open) {
    throw new Error("fixture HTML has no <article class=\"rz-resume\">");
  }
  return html.slice(open, close + "</article>".length);
}

export async function holdThemeSheets(page, delayMs) {
  await page.route(THEME_SHEET_GLOB, async (route) => {
    await new Promise((resolve) => setTimeout(resolve, delayMs));
    await route.continue();
  });
}

export async function releaseThemeSheets(page) {
  await page.unroute(THEME_SHEET_GLOB);
}

export async function waitForSandboxComplete(page) {
  await page.waitForFunction(() => {
    const doc = document.getElementById("garden-frame")?.contentDocument;
    return Boolean(doc && doc.location.pathname.endsWith("sandbox.html") && doc.readyState === "complete");
  });
}

export function sandboxFrame(page) {
  return page.frames().find((frame) => frame.url().endsWith("sandbox.html"));
}

// Swaps #theme-stylesheet on a top-level sandbox page and waits for the
// sheet's rules and fonts.
export async function waitThemeReady(page, href) {
  await page.evaluate((nextHref) => {
    document.getElementById("theme-stylesheet").setAttribute("href", nextHref);
  }, href);
  await page.waitForFunction((nextHref) => {
    const link = document.getElementById("theme-stylesheet");
    return link.getAttribute("href") === nextHref && link.sheet && link.sheet.cssRules.length > 0;
  }, href);
  await page.evaluate(() => document.fonts.ready);
}

// Replaces #theme-stylesheet with an inline sheet of the given text (used to
// run a probe against a historical sheet, e.g. `git show <base>:themes/x.css`).
export async function useSheetText(page, cssText) {
  await page.evaluate((css) => {
    const style = document.createElement("style");
    style.id = "theme-stylesheet";
    style.textContent = css;
    document.getElementById("theme-stylesheet").replaceWith(style);
  }, cssText);
  await page.evaluate(() => document.fonts.ready);
}

async function replaceArticle(page, articleHtml) {
  await page.evaluate((html) => {
    document.querySelector("article.rz-resume").outerHTML = html;
  }, articleHtml);
  await page.evaluate(() => document.fonts.ready);
}

/**
 * Opens `/sandbox.html` as the top-level document in a fresh page of the
 * suite's headless browser (default args hide scrollbars), applies the
 * theme, and optionally swaps in the article from `fixtureHtml`.
 */
export async function openResumePage(browser, { origin, theme, width, height = 800, fixtureHtml }) {
  const page = await browser.newPage({ viewport: { width, height } });
  await page.goto(`${origin}/sandbox.html`, { waitUntil: "networkidle" });
  await waitThemeReady(page, `themes/${theme}.css`);
  if (fixtureHtml) {
    await replaceArticle(page, extractArticle(fixtureHtml));
  }
  return page;
}
