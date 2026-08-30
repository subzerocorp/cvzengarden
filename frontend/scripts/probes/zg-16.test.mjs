import { test } from "node:test";
import assert from "node:assert/strict";
import { FIRST_PARTY_AUTHOR, FIRST_PARTY_URL, bylineReasons } from "./zg-16.mjs";

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
