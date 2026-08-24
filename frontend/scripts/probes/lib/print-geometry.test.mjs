import { test } from "node:test";
import assert from "node:assert/strict";
import {
  page1Fill,
  pageIndexOfY,
  paginateBlocks,
  printableHeightPx,
  printableWidthPx,
  splitEntries,
  tallBlocks,
} from "./print-geometry.mjs";

const block = (top, bottom, extra = {}) => ({ label: `${top}-${bottom}`, top, bottom, forcedBefore: false, ...extra });
const labels = (pages) => pages.map((page) => page.map((b) => b.label));

test("paginateBlocks places an oversize block alone and starts the next block on a fresh page", () => {
  const blocks = [block(0, 10), block(10, 150), block(150, 160)];
  const pages = paginateBlocks(blocks, 100);
  assert.deepEqual(labels(pages), [["0-10"], ["10-150"], ["150-160"]]);
});

test("paginateBlocks closes the current page when a block declares forcedBefore", () => {
  const blocks = [block(0, 10), block(10, 20, { forcedBefore: true }), block(20, 30)];
  const pages = paginateBlocks(blocks, 100);
  assert.deepEqual(labels(pages), [["0-10"], ["10-20", "20-30"]]);
});

test("paginateBlocks keeps a block that exactly fits on the same page", () => {
  const blocks = [block(0, 50), block(50, 100)];
  const pages = paginateBlocks(blocks, 100);
  assert.deepEqual(labels(pages), [["0-50", "50-100"]]);
});

test("paginateBlocks moves a block that overflows by one pixel to the next page", () => {
  const blocks = [block(0, 50), block(50, 101)];
  const pages = paginateBlocks(blocks, 100);
  assert.deepEqual(labels(pages), [["0-50"], ["50-101"]]);
});

test("paginateBlocks returns no pages for no blocks", () => {
  assert.deepEqual(paginateBlocks([], 100), []);
});

test("page1Fill measures from the first block top so the top offset does not leak", () => {
  const pages = paginateBlocks([block(20, 50), block(60, 110), block(115, 130)], 100);
  assert.equal(page1Fill(pages, 100), 0.9);
});

test("page1Fill is 0 when there are no pages", () => {
  assert.equal(page1Fill([], 100), 0);
});

test("page1Fill is 0 when the first page is empty", () => {
  assert.equal(page1Fill([[]], 100), 0);
});

test("tallBlocks returns only blocks taller than the printable height", () => {
  const pages = [[block(0, 10)], [block(10, 150)], [block(150, 160)]];
  assert.deepEqual(tallBlocks(pages, 100).map((b) => b.label), ["10-150"]);
});

test("pageIndexOfY finds the page whose block contains y", () => {
  const pages = [[block(0, 10)], [block(20, 30)]];
  assert.equal(pageIndexOfY(pages, 25), 1);
});

test("pageIndexOfY is -1 for a y in the gap between blocks", () => {
  const pages = [[block(0, 10)], [block(20, 30)]];
  assert.equal(pageIndexOfY(pages, 15), -1);
});

test("splitEntries is empty when header and dates share a page", () => {
  const pages = [[block(0, 50)]];
  const marks = [{ entry: "acme", headerY: 5, datesY: 10 }];
  assert.deepEqual(splitEntries(pages, marks), []);
});

test("splitEntries names an entry whose header and dates land on different pages", () => {
  const pages = [[block(0, 50)], [block(50, 100)]];
  const marks = [{ entry: "acme", headerY: 45, datesY: 55 }];
  assert.deepEqual(splitEntries(pages, marks), ["acme"]);
});

test("splitEntries ignores marks with no dates", () => {
  const pages = [[block(0, 50)], [block(50, 100)]];
  const marks = [{ entry: "acme", headerY: 45, datesY: null }];
  assert.deepEqual(splitEntries(pages, marks), []);
});

test("printable dimensions match the PBI numbers for the three themes", () => {
  const dims = ["quarto", "switchyard", "nightgarden"].map((theme) => [printableWidthPx(theme), printableHeightPx(theme)]);
  assert.deepEqual(dims, [
    [682, 952],
    [673, 1009],
    [720, 995],
  ]);
});

test("printableWidthPx throws for an unknown theme", () => {
  assert.throws(() => printableWidthPx("nope"), /no @page geometry recorded for theme nope/);
});

test("printableHeightPx throws for an unknown theme", () => {
  assert.throws(() => printableHeightPx("nope"), /no @page geometry recorded for theme nope/);
});
