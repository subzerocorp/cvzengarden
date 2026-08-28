import { test } from "node:test";
import assert from "node:assert/strict";
import {
  copiedReasons,
  copyFailedReasons,
  isPaperWhite,
  noNoticeReasons,
  noticeEscapeReasons,
  noticeTextReasons,
  paperWhiteReasons,
  searchParamReasons,
  viewBackReasons,
  viewPressedReasons,
} from "./zg-8.mjs";

test("searchParamReasons is order-insensitive", () => {
  assert.deepEqual(searchParamReasons("https://garden.example/?view=print&theme=quarto", { theme: "quarto", view: "print" }), []);
  assert.ok(searchParamReasons("/?theme=quarto", { theme: "quarto", view: "print" }).some((reason) => reason.includes("view")));
});

test("copiedReasons wants quarto+print, Copied, held, then cleared", () => {
  assert.deepEqual(
    copiedReasons({
      clipboardHref: "http://127.0.0.1:4310/?theme=quarto&view=print",
      copiedText: "Copied",
      heldForSecond: true,
      cleared: true,
    }),
    [],
  );
  assert.ok(copiedReasons({ clipboardHref: "/", copiedText: "Copied", heldForSecond: true, cleared: true }).length >= 1);
  assert.ok(copiedReasons({ clipboardHref: "http://x/?theme=quarto&view=print", copiedText: "Copy link", heldForSecond: true, cleared: true }).length >= 1);
});

test("copyFailedReasons forbids Copied and requires the address-bar sentence", () => {
  assert.deepEqual(
    copyFailedReasons({ failedText: "Copy failed — select the address bar and copy it", sawCopied: [] }),
    [],
  );
  assert.ok(copyFailedReasons({ failedText: "Copied", sawCopied: ["Copied"] }).length >= 2);
});

test("noticeTextReasons requires the raw name and Nightgarden", () => {
  assert.deepEqual(noticeTextReasons({ text: 'No theme called "banana" — showing Nightgarden.', raw: "banana", shown: "Nightgarden" }), []);
  assert.ok(noticeTextReasons({ text: "Nightgarden", raw: "banana", shown: "Nightgarden" }).length === 1);
});

test("noticeEscapeReasons wants literal <b>x</b> and no <b> element", () => {
  assert.deepEqual(noticeEscapeReasons({ text: 'No theme called "<b>x</b>" — showing Nightgarden.', hasB: false }), []);
  assert.ok(noticeEscapeReasons({ text: "x", hasB: true }).length === 2);
});

test("noNoticeReasons is empty only when the count is 0", () => {
  assert.deepEqual(noNoticeReasons(0), []);
  assert.equal(noNoticeReasons(1).length, 1);
});

test("viewPressedReasons and viewBackReasons", () => {
  assert.deepEqual(viewPressedReasons("true", "true"), []);
  assert.equal(viewPressedReasons("false", "true").length, 1);
  assert.deepEqual(viewBackReasons({ screenPressed: "true", viewParam: null }), []);
  assert.deepEqual(viewBackReasons({ screenPressed: "true", viewParam: "screen" }), []);
  assert.ok(viewBackReasons({ screenPressed: "true", viewParam: "print" }).length >= 1);
});

test("isPaperWhite accepts rgb near white and rejects Nightgarden screen ink", () => {
  assert.equal(isPaperWhite("rgb(255, 255, 255)"), true);
  assert.equal(isPaperWhite("#ffffff"), true);
  assert.equal(isPaperWhite("rgb(12, 12, 14)"), false);
  assert.deepEqual(paperWhiteReasons("rgb(255, 255, 255)"), []);
  assert.equal(paperWhiteReasons("rgb(12, 12, 14)").length, 1);
});
