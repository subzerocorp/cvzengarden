/**
 * ZG-9 probes: phone résumé first, Theme sheet, desktop unchanged.
 *
 * Phone viewport is 390×844. Desktop checks stay at 1280×800 so S1–S5
 * date geometry is the same measurement the harden suite already runs.
 */
import { openGarden } from "./lib/page.mjs";

const PHONE = { width: 390, height: 844 };
const DESKTOP = { width: 1280, height: 800 };
const THEME_IDS = ["nightgarden", "quarto", "switchyard"];

function reportReasons(report, slug, reasons, okDetail) {
  if (reasons.length) {
    report.fail(`${slug} ${reasons.join("; ")}`);
    return false;
  }
  report.pass(`${slug} ${okDetail}`);
  return true;
}

// Calculation: why the stage is not the first thing on a phone.
export function mobileFirstReasons({ frameTop, nameVisible }) {
  const reasons = [];
  if (!(frameTop < 80)) {
    reasons.push(`#garden-frame top is ${frameTop}, want < 80`);
  }
  if (!nameVisible) {
    reasons.push(".rz-name is not within the visible viewport");
  }
  return reasons;
}

export function nameInViewport(nameTop, nameBottom, viewportHeight) {
  return nameBottom > 0 && nameTop < viewportHeight;
}

// Calculation: why the closed Theme control is not the prescribed button.
export function sheetClosedReasons({ name, expanded }) {
  const reasons = [];
  if (name !== "Theme") {
    reasons.push(`toggle accessible name is ${JSON.stringify(name)}, want "Theme"`);
  }
  if (expanded !== "false") {
    reasons.push(`aria-expanded is ${JSON.stringify(expanded)}, want "false"`);
  }
  return reasons;
}

// Calculation: why the open sheet is not usable.
export function sheetOpenReasons({ expanded, sidebarVisible, quartoClickable }) {
  const reasons = [];
  if (expanded !== "true") {
    reasons.push(`aria-expanded is ${JSON.stringify(expanded)}, want "true"`);
  }
  if (!sidebarVisible) {
    reasons.push(".app-sidebar is not visible");
  }
  if (!quartoClickable) {
    reasons.push("#theme-option-quarto is not clickable");
  }
  return reasons;
}

export function themeHrefReasons(href, want) {
  const got = String(href || "");
  return got.includes(`themes/${want}.css`)
    ? []
    : [`theme href is ${JSON.stringify(href)}, want themes/${want}.css`];
}

export function sheetClosedAfterSelectReasons({ expanded, href }) {
  return [
    ...(expanded === "false" ? [] : [`sheet still open: aria-expanded is ${JSON.stringify(expanded)}`]),
    ...themeHrefReasons(href, "quarto"),
  ];
}

export function escapeReasons({ expanded, focusedId }) {
  const reasons = [];
  if (expanded !== "false") {
    reasons.push(`aria-expanded is ${JSON.stringify(expanded)}, want "false"`);
  }
  if (focusedId !== "theme-toggle") {
    reasons.push(`focus is ${JSON.stringify(focusedId)}, want "theme-toggle"`);
  }
  return reasons;
}

export function desktopToggleReasons({ visible, width, height }) {
  const reasons = [];
  if (visible) {
    reasons.push("Theme toggle is visible");
  }
  if (width !== DESKTOP.width || height !== DESKTOP.height) {
    reasons.push(`viewport is ${width}×${height}, want ${DESKTOP.width}×${DESKTOP.height}`);
  }
  return reasons;
}

export function dateGeometryReasons(geometry, themeId) {
  if (!geometry?.ok) {
    return [`${themeId}: ${geometry?.reason || "missing resume"}`];
  }
  const reasons = [];
  if (geometry.count === 0) {
    reasons.push(`${themeId}: no .rz-date / time[datetime] nodes`);
  }
  if (geometry.clipped.length) {
    reasons.push(`${themeId}: ${geometry.clipped.length} date(s) overflow the .rz-resume content box`);
  }
  if (geometry.scrollX || geometry.parentScroll) {
    reasons.push(`${themeId}: horizontal overflow at 1280×800`);
  }
  return reasons;
}

export function hscrollReasons(scrollWidth, viewportWidth) {
  return scrollWidth <= viewportWidth
    ? []
    : [`scrollWidth ${scrollWidth} > ${viewportWidth}`];
}

function readMobileFirst() {
  const frame = document.getElementById("garden-frame");
  const frameBox = frame.getBoundingClientRect();
  const name = frame.contentDocument?.querySelector(".rz-name");
  const nameBox = name?.getBoundingClientRect();
  const nameTop = nameBox ? frameBox.top + nameBox.top : Number.POSITIVE_INFINITY;
  const nameBottom = nameBox ? frameBox.top + nameBox.bottom : Number.NEGATIVE_INFINITY;
  return {
    frameTop: frameBox.top,
    nameVisible: nameBottom > 0 && nameTop < window.innerHeight,
  };
}

function readToggle() {
  const toggle = document.getElementById("theme-toggle");
  const labelled = toggle?.getAttribute("aria-label");
  const name = labelled || (toggle?.textContent || "").replace(/\s+/g, " ").trim();
  return {
    name,
    expanded: toggle?.getAttribute("aria-expanded") ?? null,
    focusedId: document.activeElement?.id ?? null,
  };
}

async function readDateGeometry(page) {
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
        clipped.push({ text: node.textContent.trim() });
      }
    }
    const scrollX =
      doc.documentElement.scrollWidth > doc.documentElement.clientWidth + 1 ||
      doc.body.scrollWidth > doc.body.clientWidth + 1;
    const parentScroll = document.documentElement.scrollWidth > document.documentElement.clientWidth + 1;
    return { ok: true, clipped, scrollX, parentScroll, count: nodes.length };
  });
}

async function mobileFirstProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, PHONE);
  const snapshot = await page.evaluate(readMobileFirst);
  await page.close();
  reportReasons(
    report,
    "ZG-9/mobile-first",
    mobileFirstReasons(snapshot),
    `#garden-frame top ${snapshot.frameTop} < 80 and .rz-name is in the 390×844 viewport`,
  );
}

async function sheetProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, PHONE);
  const toggle = page.getByRole("button", { name: "Theme", exact: true });
  const closed = await page.evaluate(readToggle);
  const reasons = sheetClosedReasons(closed);
  if ((await toggle.count()) !== 1) {
    reasons.push(`getByRole Theme resolved to ${await toggle.count()} element(s)`);
  }

  await toggle.click();
  const quarto = page.locator("#theme-option-quarto");
  await quarto.waitFor();
  const open = await page.evaluate(readToggle);
  const sidebarVisible = await page.locator(".app-sidebar").isVisible();
  const quartoClickable = await quarto.isEnabled();
  reasons.push(...sheetOpenReasons({ expanded: open.expanded, sidebarVisible, quartoClickable }));

  await quarto.click();
  await page.waitForFunction(() => {
    const href = document
      .getElementById("garden-frame")
      ?.contentDocument?.getElementById("theme-stylesheet")
      ?.getAttribute("href");
    return Boolean(href && href.includes("quarto.css"));
  });
  const after = await page.evaluate(() => {
    const toggle = document.getElementById("theme-toggle");
    const href =
      document.getElementById("garden-frame")?.contentDocument?.getElementById("theme-stylesheet")?.getAttribute(
        "href",
      ) || "";
    return { expanded: toggle?.getAttribute("aria-expanded") ?? null, href };
  });
  reasons.push(...sheetClosedAfterSelectReasons(after));
  await page.close();
  reportReasons(
    report,
    "ZG-9/sheet",
    reasons,
    "Theme opens the sheet; #theme-option-quarto swaps themes/quarto.css and closes it",
  );
}

async function escapeProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, PHONE);
  const toggle = page.getByRole("button", { name: "Theme", exact: true });
  await toggle.click();
  await page.locator("#theme-option-quarto").waitFor();
  await page.keyboard.press("Escape");
  const closed = await page
    .waitForFunction(() => {
      const toggle = document.getElementById("theme-toggle");
      return toggle?.getAttribute("aria-expanded") === "false" && document.activeElement?.id === "theme-toggle";
    })
    .then(() => true)
    .catch(() => false);
  const snapshot = await page.evaluate(readToggle);
  await page.close();
  const reasons = [
    ...escapeReasons(snapshot),
    ...(closed ? [] : ["Escape did not close the sheet and return focus to Theme"]),
  ];
  reportReasons(report, "ZG-9/escape", reasons, "Escape closes the sheet and returns focus to Theme");
}

async function desktopUnchangedProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin, DESKTOP);
  const visible = await page.locator("#theme-toggle").isVisible();
  const viewport = page.viewportSize();
  const reasons = desktopToggleReasons({
    visible,
    width: viewport?.width,
    height: viewport?.height,
  });
  for (const id of THEME_IDS) {
    await page.locator(`#theme-option-${id}`).click();
    await page.waitForFunction((want) => {
      const href = document
        .getElementById("garden-frame")
        ?.contentDocument?.getElementById("theme-stylesheet")
        ?.getAttribute("href");
      return Boolean(href && href.includes(`${want}.css`));
    }, id);
    const geometry = await readDateGeometry(page);
    reasons.push(...dateGeometryReasons(geometry, id));
  }
  await page.close();
  reportReasons(
    report,
    "ZG-9/desktop-unchanged",
    reasons,
    "Theme toggle hidden at 1280×800; S1–S5 date geometry unchanged",
  );
}

async function noHscrollProbe({ browser, origin, report }) {
  const reasons = [];
  for (const id of THEME_IDS) {
    const { page } = await openGarden(browser, origin, { ...PHONE, path: `/?theme=${id}` });
    const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    reasons.push(...hscrollReasons(scrollWidth, PHONE.width).map((reason) => `${id}: ${reason}`));
    await page.close();
  }
  reportReasons(report, "ZG-9/no-hscroll", reasons, "documentElement.scrollWidth ≤ 390 for all three themes");
}

export async function zg9Probes(context) {
  await mobileFirstProbe(context);
  await sheetProbe(context);
  await escapeProbe(context);
  await desktopUnchangedProbe(context);
  await noHscrollProbe(context);
}
