# AVRIL round 1 — QA Architect review (cycle 4)

**Role:** `qa-architect-agent` (second adversary) · **Date:** 2026-08-23 · **Cycle:** 4 (fresh review after the Generator's cycle-3b revise and the PO's cycle-4 BLESS)
**Scope:** ZG-6, ZG-10, ZG-17 only — the three items I rejected in cycle 2. My cycle-2 verdicts lapsed with the body edits; each is judged from scratch, and each of my cycle-2 blockers is checked against the current body, not against the Generator's change log. Nothing else is judged; concurrent edits to other ids are ignored.
**Inputs read in full:** `docs/plans/round-1-avril-qa-round2.md` (my blockers), `docs/plans/round-1-avril-qa-round1.md` (set-level conventions), `docs/plans/round-1-avril-generator-round3b.md` and `round3.md` (changes, fixture ownership), `docs/plans/round-1-avril-po-round4.md`, `docs/plans/round-1-avril-intent.md`, `pinto show ZG-6 ZG-10 ZG-17 --plain`, `pinto show ZG-3 ZG-5 ZG-7 ZG-11 ZG-14 ZG-16 ZG-19 ZG-20 --json` (owner / dependency consistency), `pinto show ZG-6 ZG-10 ZG-17 --json` (deps), `frontend/scripts/probes.mjs`, `frontend/static/ports.js` (`emulatePrint`, `setThemeHref`, `whenStylesheetReady`, `hoistResumeForShellPrint`), `frontend/static/index.html`, `frontend/scripts/{generate,copy-dist}.mjs`, `frontend/elm.json`, `frontend/css/chrome.css`, `frontend/src/Main.elm` (print controls), `themes/*.css` (`@page`, `min-height`), `themes/_blank.css`, `themes/README.md`, `README.md`, `renderer/Cargo.toml`, `renderer/tests/acceptance.rs`, `skeleton/README.md`, `skeleton/resume.json` (every key path and date), `.pinto/dod.md`, `.pinto/tasks/ZG-17.md`, `git ls-files .pinto frontend/generated frontend/src/Generated`, `git log -- .pinto/tasks/ZG-17.md`.

Mandate: *BLESS only PBIs whose acceptance criteria are complete, falsifiable, and hostile to happy-path theater; otherwise REJECT with the missing cases.*

I judge testability only. I do not author bodies, touch the board, or reopen product scope. Cycle-1/2 conventions apply unchanged: one owner per shared fixture; probe lines are `PASS  ZG-n/<slug>`; a PBI's own AC is never `SKIPPED`; chrome text probes use `textContent`; only Chromium is installed; nothing in the toolchain rasterises a PDF; `U3_PRINT_PAGES` is asserted with `!==`; `just verify` stays offline.

## Facts I verified before judging (they change verdicts)

| Fact | How | Affects |
| --- | --- | --- |
| `hoistResumeForShellPrint(iframe)` clones the **live** `doc.querySelector(".rz-resume")` from the iframe (`resume.cloneNode(true)`) and re-links the iframe's current theme href; the `<style data-garden-shell-print>` it creates is appended to the **chrome** `document.head`, not the iframe. | `ports.js` lines 238–275 | ZG-6 `junior-all-themes` prints the pasted sample, not Jordan; ZG-10 `no-guide-lines` is not broken by the shell route |
| `emulatePrint(doc)` flips `rule.media.mediaText` (`print` → `all`, `screen` → `not all`) on the sheets already in the iframe; it injects no `<style>`, `<link>`, or `<script>`. `setThemeHref` inserts the incoming `<link>`, waits, then sets its id, strips `data-theme-incoming` and removes the old link **synchronously** before `applyPreview`. | `ports.js` lines 77–200 | ZG-10 `no-guide-lines` ("no `<style>`, exactly one `link[rel=stylesheet]`") is satisfiable in Print preview |
| Quarto `.rz-resume { min-height: 11in }` is inside `@media screen` (line 318–331) and `@media print` sets `min-height: 0` (line 343); Nightgarden `body { min-height: 100vh }` is un-media'd and print sets `html, body { min-height: 0 }` (line 419). | `sed` | ZG-10 `min-one` under Quarto computes `H` < `P` → `1`, satisfiable |
| `@page`: Quarto top-level `size: letter; margin: 0.55in 0.7in 0.6in` + `:first { margin-top: 0.48in }`; Nightgarden inside `@media print`, `letter`, `0.36in 0.5in 0.28in`; Switchyard inside `@media print`, `A4`, `14mm 16mm 16mm`. Arithmetic at 96 dpi: 816 − 2 × 67.2 = 681.6, 1056 − (52.8 + 57.6) = 945.6; 793.7 − 2 × 60.47 = 672.8, 1122.5 − 113.4 = 1009.1; 816 − 96 = 720, 1056 − 61.44 = 994.56; `[]` → 1056 − 75.6 = 980.4. | grep + arithmetic | ZG-10 unit-test constants are correct as written |
| `index.html` loads `ports.js` as a classic `<script src>`; `copy-dist.mjs` publishes only `index.html`, `ports.js`, `chrome.css`, `sandbox.html`, `themes/*.css` (not `_blank.css`). | read | ZG-10 `page-estimate.js` import (non-blocking) |
| `elm.json` `source-directories` = `["src"]`; `generate.mjs` writes `src/Generated/Themes.elm` (tracked) and `generated/sandbox.html`. There is no `frontend/generated/*.elm` and Elm cannot import from there. | read, `git ls-files` | ZG-6 `Samples.elm` path (non-blocking) |
| `skeleton/resume.json` key paths are all JSON Resume schema properties (`$schema`, `basics.*`, `work[].description`, `meta.canonical/lastModified/version`, `projects[].roles/type`, `certificates[].issuer`, …); every date is `YYYY` or `YYYY-MM`; no `score`, no `image`. | node key walk, grep | ZG-6 `schema-jordan` does not collide with the `resume.json` no-edit AC |
| `.pinto/` is git-tracked (25 files incl. `.pinto/tasks/ZG-17.md`, committed in `1d5aa3f`); the task file's TOML front-matter carries `status` and `updated`, which `pinto start`/`pinto done` rewrite; the common DoD requires evidence "in `## Execution Evidence`" on the PBI and `progress.md`/`features.json` updates. | `git ls-files`, `head .pinto/tasks/ZG-17.md`, `.pinto/dod.md` | ZG-17 "exactly six files" AC |
| `themes/README.md` today has one `## Rules` heading and none of `published page`, `hosted page`, `<link> comment`; `README.md` contains neither `license` (any case) nor `stays yours`; `renderer/Cargo.toml` line 6 is `license = "MIT OR Apache-2.0"`; first-party headers are exactly ` * License:     MIT` (no trailing space); `_blank.css` line 5 is the only `NC` in the file; no `LICENSE`; `skeleton/samples/` does not exist; `skeleton/README.md` exists. | `cat -A`, grep, `ls` | ZG-17 greps are real changes, not pre-satisfied; ZG-6 owns a new directory |
| `node` v20.18.0 (`node --test` available); `ajv` is not in `frontend/node_modules`; `pdftotext`/`pdfinfo` exist but nothing in the repo uses them. | `node --version`, `ls` | ZG-10 unit test runnable; ZG-6 schema probes FAIL-not-skip until approval |

---

## ZG-6 — Explain the résumé format in plain words and start from a sample

### Cycle-2 blockers, checked against the current body

| Cycle-2 blocker | Current body | Resolved |
| --- | --- | --- |
| Numeric `score: 3.7` vs schema `string` — both ACs cannot pass | `junior.json` has `"score": "3.7"`; `start-junior` asserts `GPA 3.7`; cargo test asserts `<p class="rz-score">GPA 3.7</p>`; scope_out names numeric scores as ZG-3's | yes |
| Schema runner undefined, not offline, no anti-stub | `skeleton/resume-schema.json` vendored (owner ZG-6), pinned to commit + sha256 (`schema-vendored` checks the hash and the README provenance line); `ajv` offline with `validateFormats: false`; missing → `FAIL  ZG-6/schema-<slug> prerequisite missing: …`, never `SKIPPED`; `schema-rejects` proves the validator says no on `/basics/name` and `/education/0/score` | yes |
| Copyable example never rendered | `example-renders`: paste `<pre>` → `.rz-name` = `Alex Rivera`, exactly one `.rz-entry--experience`, no `[data-paste-error]`; `schema-example` validates the same text | yes |
| Sidebar sentence had no AC | `sidebar-sentence` with the panel **closed**, `textContent` contains `small text file` and `start from a sample` | yes |
| `format-named` used `innerText`; panel state unstated | `textContent`, panel open, `href` by string equality, never fetched | yes |
| `junior-all-themes` print route unspecified; `page.pdf` wrong | Route pinned to the U3 shell hoist (`.preview-controls__print` stub → `beforeprint` → `#garden-print-host` → `printToPdf` → `countPdfPages` ≤ 2 → `afterprint`); `page.pdf()` forbidden. Verified: the hoist clones the live iframe article, so the junior sample is what prints | yes |
| Sample bytes: serving and ownership | Embedded at build; `start-sample` asserts the click issues no request; ZG-6 owns `skeleton/samples/junior.{json,html}` + the schema (source), ZG-14 owns the `dist/` copy ("when present"); no ZG-14 edge, with the reason stated | yes |
| Clipboard failure state | `[data-copy-state="failed"]` with `Copy failed`, `Copied` never appears (sampled 500 ms), no `pageerror`; happy path grants both clipboard permissions | yes |
| Stored résumé after a sample click | Rule stated in scope (sample click never writes `resumezen.resume`); `sample-not-stored` probes all three legs, and the third leg is an **edit** (name changed) then "Show it", as the PO asked | yes |
| Non-blocking folds (junior name pinned, image-file diff as a command, `junior.html` regeneration) | `Sam Okoro`; `git diff --name-only … -- skeleton/samples \| grep -E '\.(svg\|png\|jpe?g\|webp\|gif)$'` prints nothing; `RZ_UPDATE_FIXTURES=1 cargo test --test acceptance` | yes |

### Fresh review

Every user-visible behaviour has a probe with a selector, a fixture value and a negative: the link `href`, the sidebar sentence with the panel closed, the clipboard content on success and the visible failure state with `Copied` forbidden, the example rendered through the real accept path, both sample buttons byte-locked to their source files with a request-log negative, the storage rule in three legs including a reload, no horizontal scroll plus a page ceiling on all three themes, a hash-pinned schema with three positive files and two negative documents, a cargo byte-lock that also counts entries, and two `git diff` greps that keep the RZ-2 fixture and the sample directory honest. The anti-stub AC is real: the probe reads `score` from the fixture and asserts `GPA ` + that value, so hard-coded HTML fails the moment the fixture changes; a Copy stub that never touches the clipboard fails `example-copy`; a fetch-at-click stub fails the request log. Dependencies are consistent: ZG-5 owns `#paste-input`, "Show it", `[data-paste-error]` and `resumezen.resume` (its body says so); ZG-14's copy step is "when present" and never names `resume.json`; ZG-3's numeric tolerance is not needed by a string score; ZG-11's lock is in `renderer/tests/fixtures.rs`, ZG-6's in `acceptance.rs` — no shared file. I checked that `schema-jordan` cannot collide with the `resume.json` no-edit AC: every key path in Jordan's file is a schema property and every date matches the schema's `iso8601` pattern.

Non-blocking (fold in without re-review):

- **Stale error after a sample click.** `start-sample` and `start-junior` both run after a *successful* paste, and only `example-renders` asserts `[data-paste-error]` is absent. A sample click that renders but leaves the previous error banner standing passes every AC. Add to `start-junior` (or a one-line `ZG-6/sample-clears-error`): after the ZG-5 trailing-comma paste has shown `invalid-json`, clicking "Start from a short sample" leaves no `[data-paste-error]` in the DOM.
- **Path fact.** Scope says `frontend/generated/Samples.elm`; `elm.json` compiles only `src/`, and `generate.mjs` writes Elm to `src/Generated/Themes.elm`. The module must be `frontend/src/Generated/Samples.elm` (`module Generated.Samples`). No AC depends on the path; correct it so the implementer does not silently choose.
- **`junior-all-themes` view.** State that the `scrollWidth <= clientWidth` check runs in Screen view at 1280×800 (as S2 does) before the print route; the AC does not say which view.
- **Fallback runner.** Notes offer the Rust `jsonschema` crate "with the same four assertions". A cargo test cannot read the `<pre data-example>` text out of the Elm chrome; if the fallback is chosen, the example text needs a source file (e.g. `skeleton/samples/example.json`, embedded by `generate.mjs` exactly like the samples) so `schema-example` still has a file to validate.

**BLESS ZG-6 — every cycle-2 blocker is closed by a probe with a fixture value and a negative (string score, hash-pinned offline schema with a proven-to-reject validator, example rendered through the real accept path, clipboard failure with `Copied` forbidden, three-leg storage rule, request-log and byte-lock on both samples), the anti-stub reads the fixture rather than a constant, and ownership/dependencies are consistent with ZG-5, ZG-14, ZG-3 and ZG-11.**

## ZG-10 — Show an honest page count in print preview and how to save a PDF

### Cycle-2 blockers, checked against the current body

| Cycle-2 blocker | Current body | Resolved |
| --- | --- | --- |
| `estimate-matches-pdf` ± 0 unsatisfiable (Switchyard formula 2 vs PDF 3) and contradicts scope_out | Replaced by the decided oracle: `estimate-matches-formula` (probe recomputes `N = max(1, ceil(H / P))` at paper content width, ± 0, waited on via `[data-page-estimate="N"]`), `estimate-near-pdf` (± 1 vs `pdfPagesForTheme`, both numbers printed), and a `node --test` unit test on a pure module with the exact geometry constants; scope_out says in words that breaks are not modelled and exact-vs-PDF is not claimed | yes |
| `hint` satisfied by ZG-7's button label | `[data-pdf-hint]` is its own non-button element, visible in both views, `textContent` contains `Save as PDF` **and** `in the print dialog`; ZG-7's sentence must survive; `Print /` button count still 1 | yes |
| `updates` needed ZG-5 and an unowned fixture | Paste route and long fixture dropped; `updates-on-switch` (Quarto → Switchyard: `Letter` → `A4`, `N` recomputed) and `updates-on-content` (probe-side clones raise `N`, removal restores it, Screen removes the readout, Print preview restores it); `ResizeObserver` recompute stated in scope; no ZG-5 / ZG-11 edge, with reasons | yes |
| `paper-size` had no negatives (lower-case `a4`, nested `@media print`, `:first` shadowing, no `@page`, unrecognised sizes) | Unit test covers every case incl. `A4` upper-case, `:first`-only → default, `8.5in 11in` / `a4 landscape` / `legal` → fallback, none throws; `paper-size` covers the three real sheets with the nested/top-level/lower-case facts named; `paper-size-fallbacks` serves `_blank.css` and an `8.5in 11in` sheet via `page.route` and asserts `data-page-size-source`, no `pageerror`, route removed | yes |
| `no-guide-lines` not an assertion | Pinned: `.garden-stage--print` → one child `#garden-frame`; iframe `body` → one child `article.rz-resume`; iframe `head` → no `<style>`/`<script>`, exactly one `link[rel="stylesheet"]` after `waitForThemeHref`; iframe `html` has no `style` attribute. Verified satisfiable: `emulatePrint` injects nothing and the shell-print `<style>` goes to the chrome head | yes |
| Minimum and singular | `estimatePages(0, 946)` → 1, `estimateLabel(1, "Letter")` → `About 1 page (Letter)`; `min-one` in the browser under Quarto (verified: Quarto's `min-height: 11in` is screen-only, print sets `0`) | yes |
| Settling on a timeout | Readout carries `data-page-estimate` / `data-page-size` / `data-page-size-source`; every probe waits on the attribute value, "never a fixed timeout" | yes |
| Non-blocking: ZG-7 sentence must survive | In `hint` | yes |

### Fresh review

The readout now claims exactly what a skeptical tester can check: a stated formula with stated constants (I recomputed all six geometry numbers and the `[]` default; they are right), a probe that derives `N` independently from the iframe's own CSSOM and waits for the DOM to agree, a loose reality check against a same-run PDF with both numbers on the pass line, and a browser-free unit test with the negative cases. Recompute is pinned from three directions (theme swap changes paper *and* count; probe-side content change raises and restores the count; view toggle removes and restores the element). `min-one` closes `About 0 pages` / `1 pages`. The hint can no longer be satisfied by ZG-7's button label, and the "no guide lines" cut is enforced as four DOM-shape assertions rather than a sentence. The diff AC (`themes/` untouched, `U3_PRINT_PAGES` untouched, S3/U3 green in the same run) makes "the readout must not move page counts" falsifiable. The only dependency (ZG-7) owns the button label and the sentence the hint sits under, and ZG-7's body confirms both.

Non-blocking (fold in without re-review):

- **Echo oracle on margins.** `estimate-matches-formula` and `ports.js` both read `@page` margins through the same CSSOM path, so a longhand read that returned `""` would make both sides default to 1 cm and still agree ± 0 (and ± 1 against the PDF). `size` is verified (cycle 2); margins are not. One line closes it: `ZG-10/paper-size` also asserts the derived `contentHeightPx` for the three real sheets equals the scope's constants ± 0.5 (expose it as `data-page-content-height` or read it through a `window.resumezen` debug hook).
- **Sheet that fails to load.** `paper-size-fallbacks` covers no-`@page` and an unrecognised size; add (c) `route.abort()` on the Switchyard URL → readout still renders (`Letter` / `default`), no `pageerror` — `whenStylesheetReady` resolves on `error`, so `collectPageRules` will see a `link` with no `sheet` and must not throw.
- **Fonts before measuring.** The probe should `await document.fonts.ready` in the iframe before its own measurement, otherwise a first-run font swap can make the probe's `H` and the `ResizeObserver`-refreshed `H` disagree until the 5 s wait expires.
- **Implementation facts, no AC impact.** `index.html` loads `ports.js` as a classic script; an ES `import` of `page-estimate.js` needs `type="module"` (or a dynamic `import()`), and `copy-dist.mjs` must publish `static/page-estimate.js` to `dist/` — a miss shows up as a `pageerror` in every ZG-10 probe, so it is caught, but the body should say it.

**BLESS ZG-10 — the ± 0 claim is now against a stated, independently recomputable formula whose constants I verified, with a ± 1 same-run PDF check and a browser-free unit test carrying the lower-case / nested / `:first` / no-`@page` / unrecognised-size negatives; the hint, recompute paths, minimum, singular, settle-on-attribute and DOM-shape "no overlay" assertions are all falsifiable, and I verified in `ports.js` and `quarto.css` that `no-guide-lines` and `min-one` are satisfiable as written.**

## ZG-17 — Add the repo LICENSE and state the theme-contribution license terms

### Cycle-2 blockers, checked against the current body

| Cycle-2 blocker | Current body | Resolved |
| --- | --- | --- |
| "No file outside …" contradicts the DoD (`progress.md`, `features.json`) | `git diff --name-only <base>..HEAD -- . ':!progress.md' ':!features.json'` must list **exactly** six files | **no** — see below |
| `_blank.css` still advertises `CC BY-NC-SA` with no negative | `License:` line contains `MIT` and `CC BY 4.0`; `grep -n -i -E "BY-NC\|noncommercial\|non-commercial" themes/_blank.css` prints nothing (verified: line 5 is the only `NC` today, so this is a real change) | yes |
| README License line had no AC | `grep -n -i "license" README.md` hits and a matching line contains `MIT` (verified: no such line today) | yes |
| `LICENSE` stub-passable | `grep -c "Permission is hereby granted, free of charge"` = 1 and `^Copyright \(c\) [0-9]{4} .+` | yes |
| `themes/*.css` glob included `_blank.css` | Three files named; regex `^ \* License: +MIT$` matches the verified headers exactly | yes |
| Non-blocking: section-scoped greps, wire into a test | License section defined as `## License` → next `## `; positives and negatives; static probe `ZG-17/license-docs` in `probes.mjs` | yes |

### Fresh review

Everything but one AC is a grep a tester can run in ten seconds, each verified to be a real change against today's files, with the negatives that make them policy rather than menu (`BY-NC` absent from `_blank.css`; `published page` / `hosted page` / `<link> comment` absent from `themes/README.md`; the section-scoped positives include `not accepted` and `switcher`). The static probe turns those greps into a regression guard against ZG-18 and ZG-19, which both edit the same files and both depend on ZG-17 — dependency order is consistent (`ZG-16 → ZG-17 → {ZG-18, ZG-19} → ZG-20`, ZG-16's body adds the `URL:` header line, ZG-19's body says it edits the header last and lists the five fields). The two human decisions (holder, Cargo dual vs MIT) sit in `## Notes` and change one line each without changing any oracle.

Blocker:

- **The diff AC contradicts the DoD a third time.** The AC now excludes `progress.md` and `features.json` and demands the diff list *exactly* `LICENSE`, `README.md`, `renderer/Cargo.toml`, `themes/README.md`, `themes/_blank.css`, `frontend/scripts/probes.mjs`. But the board is a tracked file: `.pinto/tasks/ZG-17.md` is in git (committed in `1d5aa3f`), its front-matter carries `status` and `updated` (rewritten by `pinto start` / `pinto done`), and the same DoD requires evidence for every checkbox "in `## Execution Evidence`" — on the PBI. So `git diff --name-only <base>..HEAD` on a finished ZG-17 contains `.pinto/tasks/ZG-17.md` and the AC fails; or the board change is left off the branch and the AC passes while the DoD's evidence requirement is unmet. Two testers get two verdicts. This is the exact defect I rejected in ZG-1 (cycle 1) and in this item (cycle 2), with the exclusion list one path short. Fix is one token: `':!.pinto'` alongside `':!progress.md' ':!features.json'` (and say "the tracking files and the board are the only exception").

Non-blocking (fold in with the fix):

- `hosted page` is a negative grep while scope says the doc must state that "the Garden may host them on free and paid pages". The scope sentence does not match the regex, so it is consistent — but say in the AC that the hosting sentence must be phrased without the words `hosted page(s)` / `published page(s)`, so the implementer does not trip the guard while writing the sentence the section requires.
- `head -1 LICENSE` contains `MIT` is satisfied by the standard first line `MIT License`; fine — keep it, it is what pins the file type.

**REJECT ZG-17 — the "exactly six files" diff AC is unsatisfiable or non-deterministic because `.pinto/tasks/ZG-17.md` is git-tracked and must change (`status`, `updated`, and the DoD's `## Execution Evidence`); add `':!.pinto'` to the exclusion list. Every other cycle-2 blocker is closed and verified against today's files.**

---

## Summary

| id | PO cycle 4 | QA verdict | one-line reason |
| --- | --- | --- | --- |
| ZG-6 | BLESS | **BLESS** | all eight cycle-2 blockers closed with fixture-valued probes and negatives; anti-stub reads the fixture; ownership consistent with ZG-5/14/3/11; `schema-jordan` verified compatible with the `resume.json` no-edit AC |
| ZG-10 | BLESS | **BLESS** | formula oracle with verified constants + ± 1 PDF + unit-test negatives; hint, recompute, min/singular, settle-on-attribute and DOM-shape assertions all falsifiable; `no-guide-lines` and `min-one` verified satisfiable in `ports.js` / `quarto.css` |
| ZG-17 | BLESS | **REJECT** | "exactly six files" ignores the git-tracked `.pinto/tasks/ZG-17.md` that `pinto start`/`done` and `## Execution Evidence` must change — DoD contradiction, third occurrence; one-token fix |

2 BLESS, 1 REJECT. ZG-6 and ZG-10 proceed to the Visionary CTO. ZG-17 returns to the Generator for the one-line delta and then needs the full PO → QA → CTO chain again.

## Notes for the Generator (set-level)

- **"Only these files" ACs — the exclusion list is `':!progress.md' ':!features.json' ':!.pinto'`.** The board lives in the repo and changes on every status transition and evidence write. ZG-1's cycle-3 AC 5 ("lists only `renderer/` paths") has the same latent defect and is outside my scope this cycle; whoever next touches ZG-1 should apply the same token so it does not come back through the chain for this alone.
- **Generated Elm lives in `frontend/src/Generated/`**, not `frontend/generated/` (that directory holds only `sandbox.html`). ZG-6 is the only body that names the wrong directory; fold the path fix in.
- **`ports.js` becomes a module in ZG-10** (or uses a dynamic `import()`); `copy-dist.mjs` gains `page-estimate.js`. Neither is an AC, both are one line, and both are worth saying so the U3 static regexes on `ports.js` are not disturbed by a rewrite.
- **Echo oracles.** When a probe recomputes a value by the same browser API the code uses (ZG-10 margins), pin at least one real-sheet constant from the body so a silent API mismatch cannot pass on both sides.
