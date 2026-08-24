/**
 * Where a probe group reads its theme sheets from: the working tree (loaded
 * by href, `label: null`) or a git revision (injected in place of
 * #theme-stylesheet for anti-vacuity runs). A two-row strategy table.
 */
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

export function liveSheets(repoDir) {
  return {
    label: null,
    cssFor: (theme) => fs.readFileSync(path.join(repoDir, "themes", `${theme}.css`), "utf8"),
  };
}

export function gitSheets(repoDir, revision) {
  return {
    label: revision,
    cssFor: (theme) => execFileSync("git", ["show", `${revision}:themes/${theme}.css`], { cwd: repoDir, encoding: "utf8" }),
  };
}

// Selects a source from an `RZ_<PBI>_BASE`-style environment value.
export function sheetSourceFor(repoDir, revision) {
  return revision ? gitSheets(repoDir, revision) : liveSheets(repoDir);
}

// Suffix for pass/fail lines so anti-vacuity output names the sheet it ran against.
export function sheetSuffix(sheetSource) {
  return sheetSource.label === null ? "" : ` [sheet ${sheetSource.label}]`;
}
