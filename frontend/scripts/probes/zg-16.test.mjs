import { test } from "node:test";
import assert from "node:assert/strict";
import {
  FIRST_PARTY_AUTHOR,
  FIRST_PARTY_URL,
  LAB_PLAIN_AUTHOR,
  bylineReasons,
  hitBoxReasons,
  noFakeBylineReasons,
  plainBylineReasons,
} from "./zg-16.mjs";

const want = { wantAuthor: FIRST_PARTY_AUTHOR, wantUrl: FIRST_PARTY_URL };

/** A well-formed first-party card, with the one field under test overridden. */
const card = (overrides = {}) => ({
  id: "nightgarden",
  present: true,
  hasByline: true,
  bylineInsideOption: false,
  text: FIRST_PARTY_AUTHOR,
  linkHref: FIRST_PARTY_URL,
  linkRel: "noopener",
  ...overrides,
});

test("bylineReasons is silent on a well-formed card", () => {
  assert.deepEqual(bylineReasons(card(), want), []);
});

test("bylineReasons tolerates extra rel tokens around noopener", () => {
  assert.deepEqual(bylineReasons(card({ linkRel: "noopener noreferrer" }), want), []);
});

test("bylineReasons reports a card that never rendered", () => {
  assert.deepEqual(bylineReasons(card({ present: false }), want), ["#theme-option-nightgarden is missing"]);
});

test("bylineReasons reports a card with no byline, and looks no further", () => {
  // A missing byline makes every downstream field null; one reason, not four.
  const reasons = bylineReasons(card({ hasByline: false, text: null, linkHref: null, linkRel: null }), want);
  assert.deepEqual(reasons, ["card for nightgarden has no .theme-switcher__author"]);
});

test("bylineReasons reports a byline nested inside the option button", () => {
  // AC1: `button` forbids interactive descendants, so the byline must be a
  // sibling of #theme-option-*. Everything else about this card is correct.
  const reasons = bylineReasons(card({ bylineInsideOption: true }), want);
  assert.deepEqual(reasons, ["byline is nested inside #theme-option-nightgarden, not a sibling of it"]);
});

test("bylineReasons reports byline text that does not credit the right designer", () => {
  const reasons = bylineReasons(card({ text: "by Someone Else" }), want);
  assert.deepEqual(reasons, [`byline reads "by Someone Else", want "${FIRST_PARTY_AUTHOR}"`]);
});

test("bylineReasons reports a wrong href and an absent link separately", () => {
  assert.deepEqual(bylineReasons(card({ linkHref: "https://evil.example" }), want), [
    `byline link href is https://evil.example, want ${FIRST_PARTY_URL}`,
  ]);
  assert.deepEqual(bylineReasons(card({ linkHref: null, linkRel: null }), want), [
    `byline link href is absent, want ${FIRST_PARTY_URL}`,
    'byline link rel is "", want noopener',
  ]);
});

test("bylineReasons reports a link that opens a new tab without noopener", () => {
  assert.deepEqual(bylineReasons(card({ linkRel: "noreferrer" }), want), ['byline link rel is "noreferrer", want noopener']);
  assert.deepEqual(bylineReasons(card({ linkRel: null }), want), ['byline link rel is "", want noopener']);
});

// --- lab-theme calculations -------------------------------------------------

const labCard = (overrides = {}) => ({
  id: "zg16-lab",
  present: true,
  hasByline: false,
  bylineInsideOption: false,
  text: null,
  linkHref: null,
  linkRel: null,
  ...overrides,
});

test("noFakeBylineReasons is silent on an authorless card with no byline", () => {
  assert.deepEqual(noFakeBylineReasons(labCard(), "zg16-lab"), []);
});

test("noFakeBylineReasons reports an invented byline and a missing card", () => {
  assert.deepEqual(noFakeBylineReasons(labCard({ hasByline: true, text: "by Nobody" }), "zg16-lab"), [
    'card shows a byline "by Nobody" for a theme with no Author: header',
  ]);
  assert.deepEqual(noFakeBylineReasons(labCard({ present: false }), "zg16-lab"), [
    "#theme-option-zg16-lab never appeared in the catalog",
  ]);
});

const plainWant = { id: "zg16-lab-plain", wantAuthor: LAB_PLAIN_AUTHOR };
const plainCard = (overrides = {}) =>
  labCard({ id: "zg16-lab-plain", hasByline: true, text: LAB_PLAIN_AUTHOR, ...overrides });

test("plainBylineReasons is silent on an unlinked byline", () => {
  assert.deepEqual(plainBylineReasons(plainCard(), plainWant), []);
});

test("plainBylineReasons reports a byline that became a link anyway", () => {
  // `URL:` was absent, so any href here came from somewhere it should not have.
  assert.deepEqual(plainBylineReasons(plainCard({ linkHref: "https://a.example/" }), plainWant), [
    "byline for a theme with no URL: header is a link to https://a.example/",
  ]);
});

test("plainBylineReasons reports a missing card, a missing byline, and a nested one", () => {
  assert.deepEqual(plainBylineReasons(plainCard({ present: false }), plainWant), [
    "#theme-option-zg16-lab-plain never appeared in the catalog",
  ]);
  assert.deepEqual(plainBylineReasons(plainCard({ hasByline: false, text: null }), plainWant), [
    "card for zg16-lab-plain has no .theme-switcher__author",
  ]);
  assert.deepEqual(plainBylineReasons(plainCard({ bylineInsideOption: true }), plainWant), [
    "byline is nested inside #theme-option-zg16-lab-plain",
  ]);
});

// --- hit box ----------------------------------------------------------------

// The measured first-party card at 1280x800: a 259.8x55.2 li with a 1px frame,
// a 257.8x29.4 option flush with the padding box's top, and a 23.8px byline row
// filling the rest.
const CARD = { left: 18.6, top: 413, width: 257.8, height: 53.2 };
const OPTION = { left: 18.6, top: 413, width: 257.8, height: 29.4 };
const BYLINE = { left: 18.6, top: 442.4, width: 257.8, height: 23.8 };

const point = (overrides = {}) => ({
  label: "the card's inner top-left corner",
  x: 20.6,
  y: 415,
  hit: "button#theme-option-nightgarden",
  insideOption: true,
  highlighted: true,
  mustLighten: true,
  ...overrides,
});

const geometry = (overrides = {}) => ({
  id: "nightgarden",
  card: CARD,
  button: OPTION,
  byline: BYLINE,
  points: [point(), point({ label: "the byline row's left edge", y: 454, hit: "span", insideOption: false, highlighted: false, mustLighten: false })],
  ...overrides,
});

test("hitBoxReasons is silent on an option that is the card down to the byline", () => {
  assert.deepEqual(hitBoxReasons(geometry()), []);
});

test("hitBoxReasons rejects the cycle-2 regression: a 33%-height option under a full-card highlight", () => {
  // Measured at 8af53d2 — padding on the li, `padding: 0` on the button.
  const shrunk = geometry({
    button: { left: 29, top: 421.8, width: 237, height: 18.2 },
    points: [
      point({ hit: "li", insideOption: false }),
      point({ label: "the byline row's left edge", y: 454, hit: "li", insideOption: false, highlighted: true, mustLighten: false }),
    ],
  });
  assert.deepEqual(hitBoxReasons(shrunk), [
    "option spans 29..266 inside a card spanning 18.6..276.4",
    "8.8px of card sits above the option",
    "2.4px of card between the option and the byline row is not clickable",
    "option covers 34.2% of the card's height (18.2 of 53.2), want at least 50%",
    "the card lightens at the card's inner top-left corner (20.6, 415) but a click there lands on li, not #theme-option-nightgarden",
    "the card lightens at the byline row's left edge (20.6, 454) but a click there lands on li, not #theme-option-nightgarden",
  ]);
});

test("hitBoxReasons reports an option narrower than its card", () => {
  assert.deepEqual(hitBoxReasons(geometry({ button: { ...OPTION, width: 200 } })), [
    "option spans 18.6..218.6 inside a card spanning 18.6..276.4",
  ]);
});

test("hitBoxReasons reports dead card left below the option", () => {
  // A byline pushed down the card leaves an unclickable strip above it.
  assert.deepEqual(hitBoxReasons(geometry({ byline: { ...BYLINE, top: 452.4 } })), [
    "10px of card between the option and the byline row is not clickable",
  ]);
});

test("hitBoxReasons measures a bylineless card against its own bottom", () => {
  const noByline = geometry({ byline: null, button: { ...OPTION, height: CARD.height }, points: [point()] });
  assert.deepEqual(hitBoxReasons(noByline), []);
  const short = hitBoxReasons(geometry({ byline: null, points: [point()] }));
  assert.deepEqual(short, ["23.8px of card between the option and the card's bottom is not clickable"]);
});

test("hitBoxReasons reports a hit box with no hover feedback", () => {
  const silent = geometry({ points: [point({ highlighted: false })] });
  assert.deepEqual(hitBoxReasons(silent), [
    "the card's inner top-left corner (20.6, 415) is inside the option but shows no hover feedback",
  ]);
});

test("hitBoxReasons refuses to pass when nothing was required to lighten", () => {
  // Anti-vacuity: without a mustLighten point the highlight filter is satisfied
  // by a card that stopped responding to the pointer altogether.
  const vacuous = geometry({ points: [point({ mustLighten: false, highlighted: false })] });
  assert.deepEqual(hitBoxReasons(vacuous), ["no sampled point was required to lighten, so hover feedback is unasserted"]);
});

test("hitBoxReasons tolerates sub-pixel layout noise", () => {
  const nudged = geometry({ button: { left: 19.4, top: 413.8, width: 256.5, height: 29.4 } });
  assert.deepEqual(hitBoxReasons(nudged), []);
});

test("hitBoxReasons exempts the selected card from hover feedback, but not from geometry", () => {
  // --accent and --sidebar-accent are the same value, so the current selection
  // is already painted at the hover tint: there is no colour left to change.
  const selected = geometry({ selected: true, points: [point({ highlighted: false })] });
  assert.deepEqual(hitBoxReasons(selected), []);

  const shrunkAndSelected = hitBoxReasons({
    ...selected,
    button: { left: 29, top: 421.8, width: 237, height: 18.2 },
    points: [point({ highlighted: true, insideOption: false, hit: "li" })],
  });
  assert.deepEqual(shrunkAndSelected, [
    "option spans 29..266 inside a card spanning 18.6..276.4",
    "8.8px of card sits above the option",
    "2.4px of card between the option and the byline row is not clickable",
    "option covers 34.2% of the card's height (18.2 of 53.2), want at least 50%",
    "the card lightens at the card's inner top-left corner (20.6, 415) but a click there lands on li, not #theme-option-nightgarden",
  ]);
});
