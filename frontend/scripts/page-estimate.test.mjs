import { test } from "node:test";
import assert from "node:assert/strict";
import { estimateLabel, estimatePages, pageGeometry } from "../static/page-estimate.js";

function closeTo(actual, expected, delta = 0.5) {
  assert.ok(
    Math.abs(actual - expected) <= delta,
    `${actual} is not within ${delta} of ${expected}`,
  );
}

const quartoMargins = {
  selector: "",
  size: "letter",
  marginTop: "0.55in",
  marginRight: "0.7in",
  marginBottom: "0.6in",
  marginLeft: "0.7in",
};

const switchyardMargins = {
  selector: "",
  size: "a4",
  marginTop: "14mm",
  marginRight: "16mm",
  marginBottom: "16mm",
  marginLeft: "16mm",
};

test("estimatePages is max(1, ceil(height / contentHeight))", () => {
  assert.equal(estimatePages(0, 946), 1);
  assert.equal(estimatePages(946, 946), 1);
  assert.equal(estimatePages(946.5, 946), 2);
  assert.equal(estimatePages(1892, 946), 2);
  assert.equal(estimatePages(1893, 946), 3);
});

test("estimateLabel is singular at 1", () => {
  assert.equal(estimateLabel(1, "Letter"), "About 1 page (Letter)");
  assert.equal(estimateLabel(3, "A4"), "About 3 pages (A4)");
});

test("pageGeometry([]) is Letter / default with Chromium 1 cm margins", () => {
  const geometry = pageGeometry([]);
  assert.equal(geometry.paper, "Letter");
  assert.equal(geometry.source, "default");
  closeTo(geometry.contentHeightPx, 1056 - 2 * 37.8);
});

test("base letter with Quarto margins is Letter / declared / 681.6 × 945.6", () => {
  const geometry = pageGeometry([quartoMargins]);
  assert.equal(geometry.paper, "Letter");
  assert.equal(geometry.source, "declared");
  closeTo(geometry.contentWidthPx, 681.6);
  closeTo(geometry.contentHeightPx, 945.6);
});

test("base a4 with Switchyard margins is A4 / 672.8 × 1009.1", () => {
  const geometry = pageGeometry([switchyardMargins]);
  assert.equal(geometry.paper, "A4");
  assert.equal(geometry.source, "declared");
  closeTo(geometry.contentWidthPx, 672.8);
  closeTo(geometry.contentHeightPx, 1009.1);
});

test("pageGeometry compares size case-insensitively", () => {
  const geometry = pageGeometry([{ ...switchyardMargins, size: "A4" }]);
  assert.equal(geometry.paper, "A4");
  assert.equal(geometry.source, "declared");
});

test("pageGeometry ignores @page :first and uses the base rule only", () => {
  const geometry = pageGeometry([
    { ...switchyardMargins, size: "a4" },
    { selector: ":first", size: "", marginTop: "0.48in" },
  ]);
  assert.equal(geometry.paper, "A4");
  closeTo(geometry.contentHeightPx, 1009.1);
});

test("a :first rule alone is Letter / default", () => {
  const geometry = pageGeometry([{ selector: ":first", size: "a4" }]);
  assert.equal(geometry.paper, "Letter");
  assert.equal(geometry.source, "default");
});

test("unrecognized size tokens fall back to Letter", () => {
  for (const size of ["8.5in 11in", "a4 landscape", "legal"]) {
    const geometry = pageGeometry([{ selector: "", size }]);
    assert.equal(geometry.paper, "Letter", size);
    assert.equal(geometry.source, "fallback", size);
  }
});

test("none of the prescribed pageGeometry / estimate cases throw", () => {
  const cases = [
    () => estimatePages(0, 946),
    () => estimatePages(946, 946),
    () => estimatePages(946.5, 946),
    () => estimatePages(1892, 946),
    () => estimatePages(1893, 946),
    () => estimateLabel(1, "Letter"),
    () => estimateLabel(3, "A4"),
    () => pageGeometry([]),
    () => pageGeometry([quartoMargins]),
    () => pageGeometry([switchyardMargins]),
    () => pageGeometry([{ ...switchyardMargins, size: "A4" }]),
    () => pageGeometry([switchyardMargins, { selector: ":first", size: "", marginTop: "0.48in" }]),
    () => pageGeometry([{ selector: ":first", size: "a4" }]),
    () => pageGeometry([{ selector: "", size: "8.5in 11in" }]),
    () => pageGeometry([{ selector: "", size: "a4 landscape" }]),
    () => pageGeometry([{ selector: "", size: "legal" }]),
  ];
  for (const run of cases) {
    assert.doesNotThrow(run);
  }
});
