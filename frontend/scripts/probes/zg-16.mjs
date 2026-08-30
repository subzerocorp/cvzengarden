/**
 * ZG-16 probes: every theme card credits its designer. First-party cards read
 * `by ResumeZen` and link the repo; a theme whose header has no `Author:` gets
 * no byline at all rather than an invented one; and crediting the designer
 * never costs the reader their theme selection.
 *
 * Reading the page is an action; deciding whether a byline is well-formed is a
 * pure calculation, so `bylineReasons` is unit-testable without a browser.
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { openGarden } from "./lib/page.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const frontendDir = path.resolve(__dirname, "../..");
const repoDir = path.resolve(frontendDir, "..");

export const FIRST_PARTY_IDS = ["nightgarden", "quarto", "switchyard"];
export const FIRST_PARTY_AUTHOR = "by ResumeZen";
export const FIRST_PARTY_URL = "https://github.com/subzerocorp/cvzengarden";

// A theme file that exists only for the duration of `noFakeBylineProbe`.
const LAB_ID = "zg16-lab";
const LAB_CSS = `/**
 * ResumeZen theme
 * Name:        ZG-16 Lab
 * License:     MIT
 *
 * rz-target: both
 *
 * Written and deleted by the ZG-16 no-fake-byline probe. It deliberately has
 * no Author: line. If you are reading this in a checkout, a probe run was
 * interrupted — delete it and re-run \`npm run gen\`.
 */

.rz-resume {
}
`;

/** Calculation: what is wrong with one card's byline, if anything. */
export function bylineReasons(card, { wantAuthor, wantUrl }) {
  if (!card.present) {
    return [`#theme-option-${card.id} is missing`];
  }
  if (!card.hasByline) {
    return [`#theme-option-${card.id} has no .theme-switcher__author`];
  }
  return [
    ...(card.text !== wantAuthor ? [`byline reads "${card.text}", want "${wantAuthor}"`] : []),
    ...(card.linkHref !== wantUrl ? [`byline link href is ${card.linkHref ?? "absent"}, want ${wantUrl}`] : []),
    ...(!(card.linkRel ?? "").split(/\s+/).includes("noopener") ? [`byline link rel is "${card.linkRel ?? ""}", want noopener`] : []),
  ];
}

/** Action: read every theme card's byline out of the live switcher. */
async function readCards(page, ids) {
  return page.evaluate((wanted) =>
    wanted.map((id) => {
      const option = document.getElementById(`theme-option-${id}`);
      const author = option?.querySelector(".theme-switcher__author");
      const link = author?.querySelector("a");
      return {
        id,
        present: Boolean(option),
        hasByline: Boolean(author),
        text: author?.textContent?.replace(/\s+/g, " ").trim() ?? null,
        linkHref: link?.getAttribute("href") ?? null,
        linkRel: link?.getAttribute("rel") ?? null,
      };
    }), ids);
}

async function bylineProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  try {
    const cards = await readCards(page, FIRST_PARTY_IDS);
    for (const card of cards) {
      const reasons = bylineReasons(card, { wantAuthor: FIRST_PARTY_AUTHOR, wantUrl: FIRST_PARTY_URL });
      const line = `ZG-16/byline ${card.id}`;
      reasons.length
        ? report.fail(`${line}: ${reasons.join("; ")}`)
        : report.pass(`${line} "${card.text}" -> ${card.linkHref} rel=${card.linkRel}`);
    }
  } finally {
    await page.close();
  }
}

/** Action: regenerate the catalog and relink the bundle the server is serving. */
function rebuildCatalog() {
  for (const [command, args] of [
    [process.execPath, [path.join(frontendDir, "scripts", "generate.mjs")]],
    [path.join(frontendDir, "node_modules", ".bin", "elm"), ["make", "src/Main.elm", "--output=dist/garden.js"]],
    [process.execPath, [path.join(frontendDir, "scripts", "copy-dist.mjs")]],
  ]) {
    const result = spawnSync(command, args, { cwd: frontendDir, encoding: "utf8" });
    if (result.status !== 0) {
      throw new Error(`ZG-16 lab rebuild failed: ${command} ${args.join(" ")}\n${result.stderr ?? ""}`);
    }
  }
}

async function noFakeBylineProbe({ browser, origin, report }) {
  const labFile = path.join(repoDir, "themes", `${LAB_ID}.css`);
  fs.writeFileSync(labFile, LAB_CSS);
  let page = null;
  try {
    rebuildCatalog();
    ({ page } = await openGarden(browser, origin));
    const [card] = await readCards(page, [LAB_ID]);
    const reasons = [
      ...(card.present ? [] : [`#theme-option-${LAB_ID} never appeared in the catalog`]),
      ...(card.hasByline ? [`card shows a byline "${card.text}" for a theme with no Author: header`] : []),
    ];
    reasons.length
      ? report.fail(`ZG-16/no-fake-byline: ${reasons.join("; ")}`)
      : report.pass(`ZG-16/no-fake-byline authorless lab theme renders a card with no .theme-switcher__author`);
  } finally {
    if (page) {
      await page.close();
    }
    fs.rmSync(labFile, { force: true });
    rebuildCatalog();
  }
}

async function bylineLinkProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  try {
    // The link is its own tab stop, reachable from the option without a pointer.
    await page.locator("#theme-option-quarto").focus();
    await page.keyboard.press("Tab");
    const focused = await page.evaluate(() => {
      const el = document.activeElement;
      return { cls: el?.className ?? "", href: el?.getAttribute?.("href") ?? null };
    });

    // Crediting the designer must not swap the reader's theme. The byline opens
    // in a new tab, so block the navigation rather than let a probe reach the
    // network, and dispose of the popup the click spawns.
    await page.context().route(/github\.com/, (route) => route.abort());
    const popup = page.context().waitForEvent("page", { timeout: 2000 }).catch(() => null);
    const before = await page.locator("#theme-option-nightgarden").getAttribute("aria-pressed");
    await page.locator("#theme-option-quarto .theme-switcher__author a").click();
    const spawned = await popup;
    if (spawned) {
      await spawned.close();
    }
    await page.waitForTimeout(200);
    const after = await page.locator("#theme-option-nightgarden").getAttribute("aria-pressed");
    const quartoAfter = await page.locator("#theme-option-quarto").getAttribute("aria-pressed");

    const reasons = [
      ...(focused.cls.includes("theme-switcher__author-link") ? [] : [`Tab from the option focused "${focused.cls}", not the byline link`]),
      ...(after === before ? [] : [`clicking the byline changed nightgarden aria-pressed ${before} -> ${after}`]),
      ...(quartoAfter === "true" ? ["clicking the byline selected quarto"] : []),
    ];
    reasons.length
      ? report.fail(`ZG-16/byline-link: ${reasons.join("; ")}`)
      : report.pass(`ZG-16/byline-link is keyboard-focusable (${focused.href}) and its click does not select the theme`);
  } finally {
    await page.close();
  }
}

export async function zg16Probes(context) {
  await bylineProbe(context);
  await bylineLinkProbe(context);
  await noFakeBylineProbe(context);
}
