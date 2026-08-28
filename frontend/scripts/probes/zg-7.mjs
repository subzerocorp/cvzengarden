/**
 * ZG-7 probes: plain-language chrome, one print action, About dialog.
 *
 * Copy checks use `textContent` (not `innerText`) so CSS `text-transform`
 * cannot mask a heading that still says Chrome. The GitHub href is asserted
 * by string equality and is never fetched. Print still uses the U3 path:
 * the named action calls `iframe.contentWindow.print()`.
 */
import fs from "node:fs";
import path from "node:path";
import { openGarden } from "./lib/page.mjs";

const REPO_HREF = "https://github.com/subzerocorp/cvzengarden";
const BANNED = ["rz-target", "@media", "Skeleton", "judged on hover"];
const REQUIRED = ["Appearance", "For paper", "Print / Save as PDF", "Pick a look for your résumé"];
const BADGE_WANT = {
  nightgarden: "Screen",
  quarto: "Paper",
  switchyard: "Screen + paper",
};

function reportReasons(report, slug, reasons, okDetail) {
  if (reasons.length) {
    report.fail(`${slug} ${reasons.join("; ")}`);
    return false;
  }
  report.pass(`${slug} ${okDetail}`);
  return true;
}

// Calculation: why closed-chrome body text still talks like a developer.
export function jargonReasons(bodyText, headingTexts) {
  const reasons = [];
  for (const word of BANNED) {
    if (bodyText.includes(word)) {
      reasons.push(`body textContent contains ${JSON.stringify(word)}`);
    }
  }
  for (const phrase of REQUIRED) {
    if (!bodyText.includes(phrase)) {
      reasons.push(`body textContent lacks ${JSON.stringify(phrase)}`);
    }
  }
  for (const heading of headingTexts) {
    if (heading === "Chrome" || heading === "CHROME") {
      reasons.push(`heading textContent is ${JSON.stringify(heading)}`);
    }
  }
  return reasons;
}

// Calculation: why theme badges are still the old three tokens.
export function badgeReasons(badges) {
  const reasons = [];
  for (const [id, want] of Object.entries(BADGE_WANT)) {
    if (badges[id] !== want) {
      reasons.push(`${id} badge is ${JSON.stringify(badges[id])}, want ${JSON.stringify(want)}`);
    }
  }
  for (const label of Object.values(badges)) {
    if (label === "web" || label === "print" || label === "both") {
      reasons.push(`badge textContent equals ${JSON.stringify(label)}`);
    }
  }
  return reasons;
}

// Calculation: why the print action / View toggle names are wrong.
export function printNameReasons(names) {
  const slash = names.filter((name) => name.startsWith("Print /"));
  const reasons = [];
  if (slash.length !== 1) {
    reasons.push(`${slash.length} button(s) start with "Print /": ${slash.join(" | ") || "(none)"}`);
  }
  if (!names.includes("Print / Save as PDF")) {
    reasons.push('missing accessible name "Print / Save as PDF"');
  }
  const preview = names.filter((name) => name === "Print preview");
  if (preview.length !== 1) {
    reasons.push(`${preview.length} button(s) named "Print preview"`);
  }
  return reasons;
}

// Calculation: why the open About dialog is not the promised copy / href.
export function aboutCopyReasons(text, href) {
  const reasons = [];
  if (!String(text).includes("Free during the preview")) {
    reasons.push("dialog textContent lacks Free during the preview");
  }
  if (href !== REPO_HREF) {
    reasons.push(`repo href is ${JSON.stringify(href)}, want ${JSON.stringify(REPO_HREF)}`);
  }
  return reasons;
}

// Calculation: why the switcher no longer claims paper-honest print.
export function printOnWhiteReasons(switcherText) {
  return String(switcherText).includes("prints in dark ink on white paper")
    ? []
    : ["switcher textContent lacks prints in dark ink on white paper"];
}

// Calculation: BAR-Q1 name must still be in the quality bar file.
export function guardianReasons(barMarkdown) {
  return String(barMarkdown).includes("Independent Product Experience Guardian")
    ? []
    : ["qa/MARKET-QUALITY-BAR.md lost Independent Product Experience Guardian"];
}

function readClosedChrome() {
  const dialog = document.querySelector('[role="dialog"].about-panel');
  const headings = [...document.querySelectorAll("h1, h2, h3, h4, h5, h6")].map((node) => node.textContent);
  return {
    open: Boolean(dialog),
    body: document.body.textContent,
    headings,
    switcher: document.querySelector(".theme-switcher")?.textContent || "",
    badges: Object.fromEntries(
      ["nightgarden", "quarto", "switchyard"].map((id) => [
        id,
        document.querySelector(`#theme-option-${id} .badge`)?.textContent ?? null,
      ]),
    ),
  };
}

function buttonAccessibleNames() {
  return [...document.querySelectorAll("button")].map((el) => {
    const labelled = el.getAttribute("aria-label");
    if (labelled) {
      return labelled;
    }
    return (el.textContent || "").replace(/\s+/g, " ").trim();
  });
}

async function noJargonProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  const snapshot = await page.evaluate(readClosedChrome);
  await page.close();
  const reasons = [
    ...(snapshot.open ? ["About panel was open"] : []),
    ...jargonReasons(snapshot.body, snapshot.headings),
  ];
  reportReasons(
    report,
    "ZG-7/no-jargon",
    reasons,
    "closed chrome textContent has Appearance / For paper / Print / Save as PDF / Pick a look for your résumé and none of the banned developer words",
  );
}

async function onePrintProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  const names = await page.evaluate(buttonAccessibleNames);
  const savePdf = page.getByRole("button", { name: "Print / Save as PDF" });
  const preview = page.getByRole("button", { name: "Print preview" });
  const saveCount = await savePdf.count();
  const previewCount = await preview.count();
  const reasons = printNameReasons(names);
  if (saveCount !== 1) {
    reasons.push(`getByRole Print / Save as PDF resolved to ${saveCount} element(s)`);
  }
  if (previewCount !== 1) {
    reasons.push(`getByRole Print preview resolved to ${previewCount} element(s)`);
  }

  await page.evaluate(() => {
    const iframe = document.getElementById("garden-frame");
    const win = iframe.contentWindow;
    win.__originalPrint = win.print.bind(win);
    win.__printCalled = false;
    win.print = function () {
      win.__printCalled = true;
    };
  });
  await savePdf.click();
  const called = await page.waitForFunction(() => {
    return Boolean(document.getElementById("garden-frame")?.contentWindow?.__printCalled);
  });
  await page.evaluate(() => {
    const win = document.getElementById("garden-frame")?.contentWindow;
    if (win && win.__originalPrint) {
      win.print = win.__originalPrint;
      win.__printCalled = false;
    }
  });
  await page.close();
  if (!called) {
    reasons.push("Print / Save as PDF did not call iframe.contentWindow.print()");
  }
  reportReasons(
    report,
    "ZG-7/one-print",
    reasons,
    "exactly one Print / action; Print / Save as PDF prints the iframe; Print preview toggle still unique",
  );
}

async function badgesProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  const badges = await page.evaluate(readClosedChrome).then((snapshot) => snapshot.badges);
  await page.close();
  reportReasons(
    report,
    "ZG-7/badges",
    badgeReasons(badges),
    "Nightgarden / Quarto / Switchyard badges read Screen / Paper / Screen + paper",
  );
}

async function aboutProbe({ browser, origin, report }) {
  const { page, requests } = await openGarden(browser, origin);
  const mark = requests.length;
  await page.getByRole("link", { name: "About" }).click();
  const dialog = page.locator('[role="dialog"].about-panel');
  await dialog.waitFor();
  const copy = await dialog.evaluate((el) => ({
    text: el.textContent,
    href: el.querySelector('a[href="https://github.com/subzerocorp/cvzengarden"]')?.getAttribute("href") ?? null,
  }));
  const fetched = requests.slice(mark).filter((url) => url.includes("github.com/subzerocorp/cvzengarden"));
  await page.keyboard.press("Escape");
  const closed = await page
    .waitForFunction(() => !document.querySelector('[role="dialog"].about-panel'))
    .then(() => true)
    .catch(() => false);
  const focused = await page
    .waitForFunction(() => document.activeElement?.id === "about-open")
    .then(() => true)
    .catch(() => false);
  await page.close();
  const reasons = [
    ...aboutCopyReasons(copy.text, copy.href),
    ...(fetched.length ? [`About opened fetched the repo: ${fetched.join(", ")}`] : []),
    ...(closed ? [] : ["Escape left [role=dialog].about-panel in the tree"]),
    ...(focused ? [] : ["Escape did not return focus to the About link"]),
  ];
  reportReasons(
    report,
    "ZG-7/about",
    reasons,
    "About dialog has Free during the preview and the GitHub href; Escape closes and restores focus",
  );
}

async function printOnWhiteProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  const switcher = await page.locator(".theme-switcher").evaluate((el) => el.textContent);
  await page.close();
  reportReasons(
    report,
    "ZG-7/print-on-white",
    printOnWhiteReasons(switcher),
    "switcher textContent claims prints in dark ink on white paper (S3/U3 remain the honesty guard)",
  );
}

export async function zg7Probes(context) {
  const { report, repoDir } = context;
  const bar = fs.readFileSync(path.join(repoDir, "qa", "MARKET-QUALITY-BAR.md"), "utf8");
  reportReasons(
    report,
    "ZG-7/bar-q1",
    guardianReasons(bar),
    "Independent Product Experience Guardian remains in qa/MARKET-QUALITY-BAR.md",
  );
  await noJargonProbe(context);
  await onePrintProbe(context);
  await badgesProbe(context);
  await aboutProbe(context);
  await printOnWhiteProbe(context);
}
