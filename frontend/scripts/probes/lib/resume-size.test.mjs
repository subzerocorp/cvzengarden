import { test } from "node:test";
import assert from "node:assert/strict";
import { largeResume, mebibytes } from "./resume-size.mjs";

const resume = { basics: { name: "T" }, work: [{ name: "A", position: "x".repeat(40) }, { name: "B", position: "y".repeat(40) }] };

test("largeResume reaches the byte floor with the smallest job count", () => {
  const grown = largeResume(resume, 5000);
  assert.ok(grown.bytes >= 5000, `${grown.bytes} < 5000`);
  assert.ok(Buffer.byteLength(JSON.stringify({ ...JSON.parse(grown.text), work: JSON.parse(grown.text).work.slice(0, -1) })) < 5000);
});

test("largeResume renames entries Job 1 … Job N and keeps the other fields", () => {
  const grown = largeResume(resume, 500);
  const work = JSON.parse(grown.text).work;
  assert.equal(work[0].name, "Job 1");
  assert.equal(work.at(-1).name, grown.lastName);
  assert.equal(work.length, grown.jobs);
  assert.equal(work[1].position, "y".repeat(40));
});

test("largeResume leaves the input untouched", () => {
  largeResume(resume, 500);
  assert.equal(resume.work.length, 2);
});

test("mebibytes formats two decimals", () => {
  assert.equal(mebibytes(5 * 1024 * 1024), "5.00");
});
