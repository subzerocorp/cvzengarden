/**
 * ZG-16 probes: every theme card credits its designer. First-party cards read
 * `by ResumeZen` and link the repo; a theme whose header has no `Author:` gets
 * no byline at all rather than an invented one; and crediting the designer
 * never costs the reader their theme selection.
 *
 * The card is `li.theme-switcher__item` and the byline is a sibling of
 * `#theme-option-*`, never a descendant: `button` forbids interactive
 * descendants, so a link nested inside one is never exposed as a link. Moving
 * the frame onto the card also moved the hit box, so the card's geometry is
 * asserted here too: what lightens under the pointer must be what a click
 * selects.
 *
 * Reading the page is an action; every judgement about what was read is a pure
 * calculation — `bylineReasons`, `plainBylineReasons`, `noFakeBylineReasons`
 * and `hitBoxReasons` are all unit-tested without a browser in
 * `zg-16.test.mjs`. `repoDir` and `frontendDir` are injected by the runner.
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { openGarden } from "./lib/page.mjs";

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

/** Calculation: what is wrong with an authorless card, if anything. */
export function noFakeBylineReasons(card, id) {
  return [
    ...(card.present ? [] : [`#theme-option-${id} never appeared in the catalog`]),
    ...(card.hasByline ? [`card shows a byline "${card.text}" for a theme with no Author: header`] : []),
  ];
}

/** Calculation: what is wrong with an `Author:`-without-`URL:` card, if anything. */
export function plainBylineReasons(card, { id, wantAuthor }) {
  if (!card.present) {
    return [`#theme-option-${id} never appeared in the catalog`];
  }
  if (!card.hasByline) {
    return [`card for ${id} has no .theme-switcher__author`];
  }
  return [
    ...(card.text === wantAuthor ? [] : [`byline reads "${card.text}", want "${wantAuthor}"`]),
    ...(card.linkHref === null ? [] : [`byline for a theme with no URL: header is a link to ${card.linkHref}`]),
    ...(card.bylineInsideOption ? [`byline is nested inside #theme-option-${id}`] : []),
  ];
}

/**
 * The share of the card's height the option button must at least cover. The
 * byline is a row of its own outside the button, so the button can never be
 * the whole card — but it must be everything else.
 */
export const HIT_BOX_MIN_HEIGHT_SHARE = 0.5;

const round1 = (value) => Math.round(value * 10) / 10;

/**
 * Calculation: what is wrong with one card's hit box, if anything.
 *
 * `card` is the card's *padding* box — the frame's own border is nobody's hit
 * box — and `button` is `#theme-option-*`'s border box, both in viewport
 * coordinates. `points` are sampled spots inside the card, each carrying
 * whether the card lightens under the pointer there (`highlighted`) and
 * whether `document.elementFromPoint` lands inside the option (`insideOption`).
 *
 * The invariant: the option spans the card's full width, starts flush with its
 * top, and reaches down to the byline row, so the only region a click can miss
 * is the byline's own box — and nothing outside the option may lighten, which
 * is how a shrunken target advertises itself as clickable.
 *
 * `selected` exempts a card from the "must lighten" half only: `--accent` and
 * `--sidebar-accent` are the same value, so the current selection is already
 * painted at the hover tint and has no colour left to change. The other two
 * cards carry that assertion.
 */
export function hitBoxReasons(geometry, { minHeightShare = HIT_BOX_MIN_HEIGHT_SHARE, tolerance = 1 } = {}) {
  const { id, card, button, byline, points = [], selected = false } = geometry;
  const cardRight = card.left + card.width;
  const cardBottom = card.top + card.height;
  const buttonRight = button.left + button.width;
  const buttonBottom = button.top + button.height;
  // Everything below the option is unclickable card; only the byline's own box
  // is allowed to be there.
  const floor = byline ? byline.top : cardBottom;

  return [
    ...(button.left > card.left + tolerance || buttonRight < cardRight - tolerance
      ? [`option spans ${round1(button.left)}..${round1(buttonRight)} inside a card spanning ${round1(card.left)}..${round1(cardRight)}`]
      : []),
    ...(button.top > card.top + tolerance
      ? [`${round1(button.top - card.top)}px of card sits above the option`]
      : []),
    ...(buttonBottom < floor - tolerance
      ? [`${round1(floor - buttonBottom)}px of card between the option and ${byline ? "the byline row" : "the card's bottom"} is not clickable`]
      : []),
    ...(button.height < card.height * minHeightShare
      ? [`option covers ${round1((button.height / card.height) * 100)}% of the card's height (${round1(button.height)} of ${round1(card.height)}), want at least ${round1(minHeightShare * 100)}%`]
      : []),
    ...points
      .filter((point) => point.highlighted && !point.insideOption)
      .map((point) => `the card lightens at ${point.label} (${round1(point.x)}, ${round1(point.y)}) but a click there lands on ${point.hit}, not #theme-option-${id}`),
    ...(selected
      ? []
      : points
          .filter((point) => point.mustLighten && !point.highlighted)
          .map((point) => `${point.label} (${round1(point.x)}, ${round1(point.y)}) is inside the option but shows no hover feedback`)),
    // Anti-vacuity: with no point required to lighten, the filter above is
    // satisfied by hover feedback that vanished entirely.
    ...(points.length && !selected && !points.some((point) => point.mustLighten)
      ? ["no sampled point was required to lighten, so hover feedback is unasserted"]
      : []),
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

// Somewhere in the preview stage, far from the switcher: the pointer parks
// here to read each sample point's unhovered colour.
const PARK = { x: 900, y: 780 };

/**
 * Action: read one card's boxes and the colour painted at each sample point,
 * first with the pointer parked away and then with it on the point itself.
 *
 * The colour is the first non-transparent background up from
 * `elementFromPoint`, which is what the reader actually sees there.
 */
async function readHitBox(page, id) {
  const readPoint = (x, y) =>
    page.evaluate(([px, py, themeId]) => {
      const option = document.getElementById(`theme-option-${themeId}`);
      let node = document.elementFromPoint(px, py);
      const hit = node ? `${node.tagName.toLowerCase()}${node.id ? `#${node.id}` : ""}` : "nothing";
      const insideOption = Boolean(option && node && option.contains(node));
      let background = "";
      while (node) {
        const value = getComputedStyle(node).backgroundColor;
        if (value && value !== "transparent" && !/^rgba\(.*,\s*0\)$/.test(value)) {
          background = value;
          break;
        }
        node = node.parentElement;
      }
      return { hit, insideOption, background };
    }, [x, y, id]);

  await page.mouse.move(PARK.x, PARK.y);
  const boxes = await page.evaluate((themeId) => {
    const option = document.getElementById(`theme-option-${themeId}`);
    const card = option?.closest("li.theme-switcher__item");
    if (!option || !card) {
      return null;
    }
    const rect = (element) => {
      const { left, top, width, height } = element.getBoundingClientRect();
      return { left, top, width, height };
    };
    // The card's padding box: its own border is nobody's hit box.
    const frame = card.getBoundingClientRect();
    const style = getComputedStyle(card);
    const edge = (side) => parseFloat(style[`border${side}Width`]) || 0;
    const byline = card.querySelector(".theme-switcher__author");
    return {
      // The current selection is already painted at the hover tint, so it is
      // the other cards that prove hover feedback still exists.
      selected: option.getAttribute("aria-pressed") === "true",
      card: {
        left: frame.left + edge("Left"),
        top: frame.top + edge("Top"),
        width: frame.width - edge("Left") - edge("Right"),
        height: frame.height - edge("Top") - edge("Bottom"),
      },
      frame: rect(card),
      button: rect(option),
      byline: byline ? rect(byline) : null,
    };
  }, id);
  if (!boxes) {
    return { id, missing: true };
  }

  const { card, byline } = boxes;
  const sampled = [
    { label: "the card's inner top-left corner", x: card.left + 2, y: card.top + 2, mustLighten: true },
    { label: "the card's inner top-right corner", x: card.left + card.width - 3, y: card.top + 2 },
    { label: "the left edge of the name row", x: card.left + 2, y: card.top + card.height * 0.25 },
    ...(byline
      ? [
          { label: "the byline row's left edge", x: card.left + 2, y: byline.top + byline.height / 2 },
          { label: "the card's inner bottom-left corner", x: card.left + 2, y: card.top + card.height - 2 },
        ]
      : []),
  ];

  const parked = [];
  for (const point of sampled) {
    parked.push(await readPoint(point.x, point.y));
  }

  const points = [];
  for (const [index, point] of sampled.entries()) {
    await page.mouse.move(point.x, point.y);
    const hovered = await readPoint(point.x, point.y);
    points.push({
      ...point,
      hit: hovered.hit,
      insideOption: hovered.insideOption,
      highlighted: hovered.background !== parked[index].background,
    });
  }
  await page.mouse.move(PARK.x, PARK.y);

  return { id, ...boxes, points };
}

/**
 * The card's frame moved to the `li`, so the option button no longer defines
 * the card's box — nothing but this probe stops it drifting back to a strip
 * the reader cannot hit while the whole card still lights up under the pointer.
 */
async function hitBoxProbe({ browser, origin, report }) {
  const { page } = await openGarden(browser, origin);
  try {
    for (const id of FIRST_PARTY_IDS) {
      const geometry = await readHitBox(page, id);
      const line = `ZG-16/hit-box ${id}`;
      if (geometry.missing) {
        report.fail(`${line}: #theme-option-${id} is missing`);
        continue;
      }
      const reasons = hitBoxReasons(geometry);
      if (reasons.length) {
        report.fail(`${line}: ${reasons.join("; ")}`);
      } else {
        const share = round1((geometry.button.height / geometry.card.height) * 100);
        const hover = geometry.selected
          ? "already at the hover tint as the current selection"
          : `lightens under the pointer and every point that lightens hits the option (${geometry.points.filter((point) => point.highlighted).length} of ${geometry.points.length} sampled points)`;
        report.pass(
          `${line} option ${round1(geometry.button.width)}x${round1(geometry.button.height)} covers the ${round1(geometry.card.width)}x${round1(geometry.card.height)} card down to the byline row (${share}% of its height); ${hover}`,
        );
      }
    }
  } finally {
    await page.close();
  }
}

/** Action: regenerate the catalog and relink the bundle the server is serving. */
function rebuildCatalog(frontendDir) {
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
 * link. Both lab themes go in, get built, get asserted, and come out again — a
 * failed run must not leave the tree or dist dirty.
 *
 * Cleanup is deliberately not in a `finally`: deleting the files and rebuilding
 * the catalog is itself fallible, and a `throw` from there would replace the
 * probe's own exception with a rebuild error about a tree that has already been
 * restored. It runs after the probe body instead, reports its own failure, and
 * then the original error — if there was one — is the one that propagates.
 */
async function labBylineProbe({ browser, origin, report, repoDir, frontendDir }) {
  const written = LAB_FILES.map(([id, css]) => {
    const file = path.join(repoDir, "themes", `${id}.css`);
    fs.writeFileSync(file, css);
    return { id, file };
  });

  let probeError = null;
  let page = null;
  try {
    rebuildCatalog(frontendDir);
    ({ page } = await openGarden(browser, origin));
    const [authorless, plain] = await readCards(page, [LAB_AUTHORLESS, LAB_PLAIN]);

    const noFakeReasons = noFakeBylineReasons(authorless, LAB_AUTHORLESS);
    noFakeReasons.length
      ? report.fail(`ZG-16/no-fake-byline: ${noFakeReasons.join("; ")}`)
      : report.pass("ZG-16/no-fake-byline authorless lab theme renders a card with no .theme-switcher__author");

    const plainReasons = plainBylineReasons(plain, { id: LAB_PLAIN, wantAuthor: LAB_PLAIN_AUTHOR });
    plainReasons.length
      ? report.fail(`ZG-16/plain-byline: ${plainReasons.join("; ")}`)
      : report.pass(`ZG-16/plain-byline lab theme with Author: and no URL: renders "${plain.text}" as plain text, no <a>`);
  } catch (error) {
    probeError = error;
  } finally {
    if (page) {
      await page.close().catch(() => {});
    }
  }

  try {
    for (const { id, file } of written) {
      fs.rmSync(file, { force: true });
      fs.rmSync(path.join(frontendDir, "dist", "themes", `${id}.css`), { force: true });
    }
    rebuildCatalog(frontendDir);
  } catch (error) {
    report.fail(`ZG-16/lab-cleanup: the lab themes were removed but the catalog did not rebuild: ${error.message}`);
  }

  if (probeError) {
    throw probeError;
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
  await hitBoxProbe(context);
  await bylineLinkProbe(context);
  await labBylineProbe(context);
}
