import { test } from "node:test";
import assert from "node:assert/strict";
import { countPdfPages } from "./pdf.mjs";

test("countPdfPages counts /Type /Page objects and ignores the /Pages tree", () => {
  const pdf = Buffer.from("1 0 obj << /Type /Pages /Count 2 >> 2 0 obj << /Type /Page >> 3 0 obj << /Type/Page >>", "latin1");
  assert.equal(countPdfPages(pdf), 2);
});

test("countPdfPages is 0 for a buffer with no page objects", () => {
  assert.equal(countPdfPages(Buffer.from("%PDF-1.4", "latin1")), 0);
});
