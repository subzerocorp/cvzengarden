import { test } from "node:test";
import assert from "node:assert/strict";
import {
  aboutCopyReasons,
  badgeReasons,
  guardianReasons,
  jargonReasons,
  printNameReasons,
  printOnWhiteReasons,
} from "./zg-7.mjs";

const cleanBody =
  "Pick a look for your résumé. Appearance For paper Print / Save as PDF Screen Paper Screen + paper";
const cleanHeadings = ["Garden", "Themes", "View", "Appearance"];

test("jargonReasons is empty for the prescribed closed-chrome copy", () => {
  assert.deepEqual(jargonReasons(cleanBody, cleanHeadings), []);
});

test("jargonReasons flags each banned token and a Chrome heading", () => {
  const dirty = "Labels come from /* rz-target */. Print preview emulates @media print. One Skeleton. judged on hover.";
  const reasons = jargonReasons(dirty, ["CHROME"]);
  assert.ok(reasons.some((reason) => reason.includes("rz-target")));
  assert.ok(reasons.some((reason) => reason.includes("@media")));
  assert.ok(reasons.some((reason) => reason.includes("Skeleton")));
  assert.ok(reasons.some((reason) => reason.includes("judged on hover")));
  assert.ok(reasons.some((reason) => reason.includes("CHROME")));
  assert.ok(reasons.some((reason) => reason.includes("Appearance")));
});

test("badgeReasons accepts Screen / Paper / Screen + paper and rejects web|print|both", () => {
  assert.deepEqual(
    badgeReasons({ nightgarden: "Screen", quarto: "Paper", switchyard: "Screen + paper" }),
    [],
  );
  assert.ok(badgeReasons({ nightgarden: "web", quarto: "print", switchyard: "both" }).length >= 3);
});

test("printNameReasons wants one Print / action and a unique Print preview toggle", () => {
  assert.deepEqual(printNameReasons(["Screen", "Print preview", "Print / Save as PDF", "All"]), []);
  assert.ok(printNameReasons(["Print", "Print preview"]).length >= 1);
  assert.ok(printNameReasons(["Print / Save as PDF", "Print / other", "Print preview"]).length >= 1);
});

test("aboutCopyReasons pins the free line and the exact GitHub href", () => {
  assert.deepEqual(
    aboutCopyReasons("Free during the preview. Pricing is not announced.", "https://github.com/subzerocorp/cvzengarden"),
    [],
  );
  assert.ok(aboutCopyReasons("About ResumeZen", "https://github.com/other/repo").length === 2);
});

test("printOnWhiteReasons matches the switcher substring", () => {
  assert.deepEqual(printOnWhiteReasons("Every theme prints in dark ink on white paper"), []);
  assert.equal(printOnWhiteReasons("Print stays print").length, 1);
});

test("guardianReasons requires the BAR-Q1 name", () => {
  assert.deepEqual(guardianReasons("Independent Product Experience Guardian"), []);
  assert.equal(guardianReasons("quality bar").length, 1);
});
