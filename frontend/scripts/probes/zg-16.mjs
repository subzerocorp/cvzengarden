/**
 * ZG-16 probes: every theme card credits its designer. First-party cards read
 * `by ResumeZen` and link the repo; a theme whose header has no `Author:` gets
 * no byline at all rather than an invented one; and crediting the designer
 * never costs the reader their theme selection.
 *
 * The card is `li.theme-switcher__item` and the byline is a sibling of
 * `#theme-option-*`, never a descendant: `button` forbids interactive
 * descendants, so a link nested inside one is never exposed as a link.
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

// Theme files that exist only for the duration of `labBylineProbe`. One has no
// `Author:` at all, the other an `Author:` with no `URL:` — the two `viewByline`
// branches no shipped theme reaches.
const LAB_AUTHORLESS = "zg16-lab";
const LAB_PLAIN = "zg16-lab-plain";
export const LAB_PLAIN_AUTHOR = "by Lab Designer";

const labCss = (fields) => `/* rz-target: both */

/**
 * ResumeZen theme
${[...fields, "License:     MIT"].map((line) => ` * ${line}`).join("\n")}
 *
 * Written and deleted by the ZG-16 lab-byline probe. If you are reading this
 * in a checkout, a probe run was interrupted — delete it and re-run
 * \`npm run gen\`.
 */

.rz-resume {
}
`;

const LAB_FILES = [
  [LAB_AUTHORLESS, labCss(["Name:        ZG-16 Lab"])],
  [LAB_PLAIN, labCss(["Name:        ZG-16 Lab Plain", "Author:      Lab Designer"])],
];

/** Calculation: what is wrong with one card's linked byline, if anything. */
export function bylineReasons(card, { wantAuthor, wantUrl }) {
  if (!card.present) {
    return [`#theme-option-${card.id} is missing`];
  }
  if (!card.hasByline) {
    return [`card for ${card.id} has no .theme-switcher__author`];
  }
  return [
    ...(card.bylineInsideOption ? [`byline is nested inside #theme-option-${card.id}, not a sibling of it`] : []),
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
      const card = option?.closest("li.theme-switcher__item");
      const author = card?.querySelector(".theme-switcher__author");
      const link = author?.querySelector("a");
      return {
        id,
        present: Boolean(option),
        hasByline: Boolean(author),
        bylineInsideOption: Boolean(author && option?.contains(author)),
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
        : report.pass(`${line} "${card.text}" -> ${card.linkHref} rel=${card.linkRel}, sibling of #theme-option-${card.id}`);
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

/**
 * The two `viewByline` branches the shipped catalog cannot reach: an authorless
 * theme renders no byline, and an author with no URL renders plain text with no
 * link. Both lab themes go in, get built, get asserted, and come out again in
 * `finally` — a failed run must not leave the tree or dist dirty.
 */
async function labBylineProbe({ browser, origin, report }) {
  const written = LAB_FILES.map(([id, css]) => {
    const file = path.join(repoDir, "themes", `${id}.css`);
    fs.writeFileSync(file, css);
    return { id, file };
  });
  let page = null;
  try {
    rebuildCatalog();
    ({ page } = await openGarden(browser, origin));
    const [authorless, plain] = await readCards(page, [LAB_AUTHORLESS, LAB_PLAIN]);

    const authorlessReasons = [
      ...(authorless.present ? [] : [`#theme-option-${LAB_AUTHORLESS} never appeared in the catalog`]),
      ...(authorless.hasByline ? [`card shows a byline "${authorless.text}" for a theme with no Author: header`] : []),
    ];
    authorlessReasons.length
      ? report.fail(`ZG-16/no-fake-byline: ${authorlessReasons.join("; ")}`)
      : report.pass("ZG-16/no-fake-byline authorless lab theme renders a card with no .theme-switcher__author");

    const plainReasons = [
      ...(plain.present ? [] : [`#theme-option-${LAB_PLAIN} never appeared in the catalog`]),
      ...(plain.hasByline ? [] : [`card for ${LAB_PLAIN} has no .theme-switcher__author`]),
      ...(plain.hasByline && plain.text !== LAB_PLAIN_AUTHOR ? [`byline reads "${plain.text}", want "${LAB_PLAIN_AUTHOR}"`] : []),
      ...(plain.linkHref === null ? [] : [`byline for a theme with no URL: header is a link to ${plain.linkHref}`]),
      ...(plain.bylineInsideOption ? [`byline is nested inside #theme-option-${LAB_PLAIN}`] : []),
    ];
    plainReasons.length
      ? report.fail(`ZG-16/plain-byline: ${plainReasons.join("; ")}`)
      : report.pass(`ZG-16/plain-byline lab theme with Author: and no URL: renders "${plain.text}" as plain text, no <a>`);
  } finally {
    if (page) {
      await page.close();
    }
    for (const { id, file } of written) {
      fs.rmSync(file, { force: true });
      fs.rmSync(path.join(frontendDir, "dist", "themes", `${id}.css`), { force: true });
    }
    rebuildCatalog();
  }
}

async function bylineLinkProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  try {
    // The link follows its option in the card, so one Tab off the option reaches it.
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
    await page.locator("#theme-option-quarto ~ .theme-switcher__author a").click();
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
  await labBylineProbe(context);
}
