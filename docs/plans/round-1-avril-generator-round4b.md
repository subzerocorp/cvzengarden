# AVRIL round 1 — Generator revise pass (cycle 4b, after QA Architect cycle 4)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-23 · **Board:** Pinto `ZG` (labels `avril`, `round-1`)
**Scope:** ZG-17 only — the single QA cycle-4 REJECT in this lane. ZG-11/12/13/19/20/21 are being revised by a concurrent Generator instance and are not touched here.
**Inputs read in full:** `docs/plans/round-1-avril-qa-round4.md` (the ZG-17 section and verdict table), `pinto show ZG-17 --plain` / `--json` (body, labels, dependencies), `docs/plans/round-1-avril-generator-round3b.md` (prior conventions).

Only the QA-cited blocker was applied, plus the two non-blocking notes QA said to fold in with the fix. Every heading, every other AC, the labels, and the dependencies are unchanged. Nothing is BLESSed by this document.

## Cycle 4b — ZG-17

**QA blocker (cycle 4):** the "exactly six files" diff AC excluded only `progress.md` and `features.json`, but `.pinto/tasks/ZG-17.md` is git-tracked and must change on a finished item (`status` / `updated` front-matter rewritten by `pinto start` / `pinto done`, and the DoD's `## Execution Evidence` lives on the PBI). The AC was therefore unsatisfiable or non-deterministic — the same defect QA rejected in ZG-1 (cycle 1) and in this item (cycle 2).

**Change 1 — the blocker (diff AC).** Added `':!.pinto'` to the pathspec exclusion list and restated the parenthetical:

- before: `git diff --name-only <base>..HEAD -- . ':!progress.md' ':!features.json'` … `(the tracking files the DoD mandates are the only exception)`
- after: `git diff --name-only <base>..HEAD -- . ':!progress.md' ':!features.json' ':!.pinto'` … `(the tracking files and the board — `progress.md`, `features.json`, `.pinto/` — are the only exception)`

The six listed files are unchanged. A tester on a finished branch now gets one verdict whether or not the board file is committed alongside the change.

**Change 2 — non-blocking fold (hosting sentence vs. negative grep).** The `themes/README.md` License-section AC keeps its negative grep (`published page|hosted page|<link> comment` prints nothing) and now says explicitly that the hosting sentence the section requires (the Garden may host Themes on free and paid pages) must be phrased without the words `hosted page(s)` / `published page(s)`, so the implementer does not trip the guard while writing the sentence the scope demands.

**Change 3 — non-blocking fold (LICENSE first line).** `head -1 LICENSE` contains `MIT` is kept as QA asked; a parenthetical notes that the standard first line `MIT License` satisfies it, so nobody rewrites the file header to pass the check.

**Not changed:** `## Why`, `## Covers`, `## Scope in`, `## Scope out`, `## Dependencies`, `## Notes`, all other ACs verbatim, labels (`avril`, `round-1`, `designer`, `docs`), depends-on (`ZG-16`), dependents (`ZG-18`, `ZG-19`). Verified with `pinto show ZG-17 --json` and a line diff against the pre-edit body: exactly three AC lines differ.

**Items changed this cycle:** ZG-17.
