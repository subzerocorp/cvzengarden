# AVRIL round 1 — Generator revise pass (cycle 3b, after QA Architect cycle 2)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-23 · **Board:** Pinto `ZG` (labels `avril`, `round-1`)
**Scope:** ZG-6, ZG-10, ZG-17 only — the three QA cycle-2 REJECTs. Nothing else is edited.
**Inputs read in full:** `docs/plans/round-1-avril-qa-round2.md` (the three REJECT sections and the set-level notes), `docs/plans/round-1-avril-qa-round1.md` (set-level conventions), `docs/plans/round-1-avril-generator-round3.md` (fixture ownership table, probe conventions), `docs/plans/round-1-avril-intent.md`, `pinto show ZG-6 ZG-10 ZG-17 --plain`, `pinto show ZG-3 ZG-5 ZG-7 ZG-11 ZG-14 ZG-16 ZG-19 ZG-20 --plain` (+ ZG-8, ZG-15, ZG-18 for attribute names), `frontend/scripts/probes.mjs` (`printToPdf`, `countPdfPages`, `pdfPagesForTheme`, `waitForThemeHref`, the U3 shell-print route, the existing `page.route('**/themes/*.css')`), `frontend/scripts/{copy-dist,serve,generate}.mjs`, `frontend/static/ports.js` (`emulatePrint`, `setThemeHref`, `hoistResumeForShellPrint`), `frontend/src/Main.elm` (`viewStage`, print controls), `frontend/css/chrome.css`, `themes/*.css` `@page` rules, `themes/_blank.css`, `themes/README.md`, `README.md`, `renderer/src/{lib,emit}.rs`, `renderer/Cargo.toml`, `justfile`, `pinto dod`.

Only the QA-cited blockers were applied (plus the non-blocking folds QA said could go in without re-review). Cycle-3 conventions are kept: `PASS  ZG-n/<slug>` lines, never `SKIPPED` (`FAIL … prerequisite missing: <what>`), `textContent` not `innerText`, `just verify` offline, clipboard permissions stated, one owner per shared fixture (ZG-3 numeric score, ZG-4 `render.rs`/`ada.json`, ZG-5 paste panel + fixtures, ZG-11 long fixture + `U3_PRINT_PAGES`, ZG-14 serves skeleton assets). Nothing is BLESSed by this document.

## Facts verified before writing AC

| Fact | How | Used by |
| --- | --- | --- |
| `probes.mjs` `printToPdf(page)` is CDP `Page.printToPDF` with `preferCSSPageSize: true`; `pdfPagesForTheme(browser, href)` prints `sandbox.html` with it; `countPdfPages` regexes `/Type /Page`; the U3 shell route is `.preview-controls__print` click (iframe `print` stubbed) → `beforeprint` → `#garden-print-host` → `printToPdf(page)` → `afterprint`. `page.route("**/themes/*.css")` is already used (line 590). | read | ZG-6 `junior-all-themes`, ZG-10 `estimate-near-pdf`, `paper-size-fallbacks` |
| `@page`: Quarto top-level `size: letter; margin: 0.55in 0.7in 0.6in` + `@page :first { margin-top: 0.48in }`; Nightgarden inside `@media print`, `size: letter; margin: 0.36in 0.5in 0.28in`; Switchyard inside `@media print`, `size: A4; margin: 14mm 16mm 16mm`. `_blank.css` has no `@page`. | grep | ZG-10 geometry (content 720 × 994.56 / 681.6 × 945.6 / 672.8 × 1009.1 px) |
| `copy-dist.mjs` publishes only `index.html`, `ports.js`, `chrome.css`, `sandbox.html`, `themes/*.css` (not `_blank.css`); nothing from `skeleton/`. ZG-14 adds `skeleton/samples/*.{html,json,svg}` "when present" and never `skeleton/resume.json`. | read | ZG-6 sample-byte delivery |
| `viewStage` renders `main.garden-stage` with exactly one child, `iframe#garden-frame`; `sandbox.html` `<head>` = 2 `<meta>`, `<title>`, a comment, one `<link>`; `<body>` = one `article.rz-resume`. `setThemeHref` briefly holds two `<link>`s (`data-theme-incoming`) then removes the old one. | read | ZG-10 `no-guide-lines` |
| `render_json` emits a full document (`<!DOCTYPE html>` …); `format_score` prefixes `GPA ` for any numeric string, so `"score": "3.7"` renders `GPA 3.7` today without ZG-3. | read `html.rs`, `emit.rs:844` | ZG-6 string score |
| Upstream `jsonresume/resume-schema` master = commit `b25e3f4bbafd349c2c5bbaa62602c03c228762db` (2026-06-12, "schema moved to the jsonresume.org monorepo"); `schema.json` is draft-07 with `$id`, 15 018 bytes, sha256 `8911e912ee487954b10cb59da39265c7e62ef7cba5973706d125448adc853969`; `education[].score` is `string`; only `format`s are `email` and `uri`; dates use an `iso8601` `pattern` (`YYYY`, `YYYY-MM`, `YYYY-MM-DD`); `basics.name` is not `required`. `ajv` is not installed. | `curl`, `shasum`, GitHub API, `ls node_modules` | ZG-6 vendored schema pin, runner options, anti-stub shape |
| First-party headers read ` * License:     MIT` (five spaces); `_blank.css` line 5 is `License:     (e.g. CC BY-NC-SA 4.0, MIT)` and contains no other `NC`; `README.md` contains neither `license` (any case) nor `stays yours`; no `LICENSE` file; Cargo `MIT OR Apache-2.0`. | grep | ZG-17 greps |
| `pinto dod` appends the common DoD at display time; bodies do not carry it. `pinto dep add <ID> <DEPENDS_ON>`. | `pinto dod`, `--help` | body edits |

---

## ZG-6 — Explain the résumé format in plain words and start from a sample

| QA blocker | Exact change |
| --- | --- |
| Numeric `score: 3.7` vs schema (`string`) cannot both pass | `junior.json` uses `"score": "3.7"` (schema type; verified `GPA 3.7` today). `start-junior` asserts `.rz-score` text `GPA 3.7`; scope_out says numeric scores are ZG-3's tolerance. ZG-6 no longer needs ZG-3 (the transitive edge through ZG-5 stays) |
| Schema runner undefined, not offline, no anti-stub | Schema vendored as `skeleton/resume-schema.json` (owner ZG-6), pinned to upstream commit `b25e3f4b…` and sha256 `8911e912…`; `skeleton/README.md` records the provenance (`ZG-6/schema-vendored`). Runner: `ajv` (dev-only, `validateFormats: false`) inside `probes.mjs`; missing → `FAIL  ZG-6/schema-<slug> prerequisite missing: ajv devDependency (Notes)`. Probes `schema-junior`, `schema-example`, `schema-jordan`; anti-stub `ZG-6/schema-rejects` (`{"basics":{"name":5}}` → `/basics/name`; numeric score → `/education/0/score`). `## Notes` carries `ajv` for human approval with the Rust `jsonschema` fallback |
| Copyable example never rendered | `ZG-6/example-renders`: paste `pre[data-example]` text into `#paste-input`, "Show it" → `.rz-name` = `Alex Rivera`, one `.rz-entry--experience`, no `[data-paste-error]`; same text validates (`schema-example`) |
| Sidebar sentence has no AC | `ZG-6/sidebar-sentence`: panel **closed**, sidebar `textContent` contains `small text file` and `start from a sample` |
| `format-named` uses `innerText`, panel state unstated | `textContent`, panel opened first, `href` asserted by string equality |
| `junior-all-themes` print route unspecified; `page.pdf` wrong | Route pinned: junior sample rendered in the chrome → U3 shell-print hoist (`.preview-controls__print` stub, `beforeprint`, `#garden-print-host`) → existing `printToPdf(page)` → `countPdfPages` ≤ 2 → `afterprint`; `page.pdf()` forbidden; no served `junior.html` needed |
| Serving / ownership of sample bytes | Bytes embedded at build (`generate.mjs` → `frontend/generated/Samples.elm`); a click issues no request (asserted via `page.on('request')` in `start-sample`). ZG-6 owns the source files `skeleton/samples/junior.{json,html}` and the vendored schema; ZG-14 stays the sole owner of the `skeleton/samples/*` → `dist/` copy step. **No ZG-6 → ZG-14 dependency** — QA's own `junior-all-themes` fix removes the only reason for one, and embedding keeps ZG-5's `no-network` rule true |
| Clipboard failure state | `[data-copy-example]` with `[data-copy-state="copied"|"failed"]` (ZG-8 names); `ZG-6/example-copy` grants `clipboard-read` + `clipboard-write`; `ZG-6/example-copy-failed` overrides `writeText` via `addInitScript` → `Copy failed`, never `Copied`, no `pageerror` |
| Stored résumé after a sample click | Pinned: a sample click renders but does **not** write `resumezen.resume` (a sample is a starting point; an accidental click cannot destroy the Author's stored file); editing + "Show it" stores as ZG-5 says. `ZG-6/sample-not-stored` probes all three legs (stored Ada survives + reload; nothing stored → Jordan + `null`; edited sample → stored) |
| Non-blocking folds | Junior `basics.name` pinned (`Sam Okoro`), example name pinned (`Alex Rivera`); "no image file" as `git diff --name-only <base>..HEAD -- skeleton/samples \| grep -E '\.(svg\|png\|jpe?g\|webp\|gif)$'` prints nothing; `junior.html` regenerated with `RZ_UPDATE_FIXTURES=1 cargo test --test acceptance` (new test `junior_sample_html_is_crate_output`, byte equality, appended to the existing `acceptance.rs` — no ZG-11 file shared); `start-sample` runs after the Ada paste so `Jordan Hale` is a change, not the default |

Dependencies: unchanged (`ZG-5`). Body states why ZG-14, ZG-3, ZG-11 are not dependencies.

## ZG-10 — Show an honest page count in print preview and how to save a PDF

| QA blocker | Exact change |
| --- | --- |
| `estimate-matches-pdf` ± 0 unsatisfiable (Switchyard 2 vs 3) and contradicts scope_out | Replaced by QA's decided oracle: **(1)** `ZG-10/estimate-matches-formula` — readout equals `N = max(1, ceil(H / P))` recomputed by the probe with `H` = `.rz-resume` height at paper content width (iframe `html` inline width, restored) and `P` = page height − vertical base-rule margins, ± 0, waited on via `[data-page-estimate="N"]`; **(2)** `ZG-10/estimate-near-pdf` — `\|N − pdfPagesForTheme(...).pages\| ≤ 1` on all three themes, readout starts with `About `; **(3)** node unit test `frontend/scripts/page-estimate.test.mjs` on a pure module `frontend/static/page-estimate.js` (`pageGeometry`, `estimatePages`, `estimateLabel`). Scope_out now says explicitly that page-break rules are not modelled and exact-vs-PDF is not claimed |
| `hint` satisfied by ZG-7's button label | Hint is its own element `[data-pdf-hint]` (not a button, contains none), visible in both views, `textContent` contains `Save as PDF` **and** `in the print dialog`; ZG-7's sentence must still be present; `Print /` button count still 1 |
| `updates` needs ZG-5 and an unowned fixture | Paste route and `long-resume.json` dropped. `ZG-10/updates-on-switch` (Quarto → Switchyard: `Letter` → `A4`, `N` recomputed) and `ZG-10/updates-on-content` (probe-side clones of `#rz-experience` raise `N`, removal restores it; Screen hides, Print preview shows). Mechanism in scope: `ResizeObserver` on the iframe `body` + recompute on theme swap / view toggle, so a ZG-5 paste recomputes without ZG-10 knowing ZG-5. **No ZG-5 / ZG-11 dependency** |
| `paper-size` negatives and the verified traps | Scope pins: recurse `CSSMediaRule`/`CSSSupportsRule`; only base rules (`selectorText === ""`), `:first` ignored; case-insensitive (`a4`); empty/no `@page` → Letter `default`; unrecognised (`8.5in 11in`, `a4 landscape`, `legal`) → Letter `fallback`, no throw; margins in `in/cm/mm/pt/px`, none → 1 cm. Unit test covers every case; `ZG-10/paper-size` covers the three real themes (top-level vs nested, lower-case, `:first`); `ZG-10/paper-size-fallbacks` serves `_blank.css` and an `8.5in 11in` sheet under the Switchyard URL via `page.route` and asserts `data-page-size-source` |
| `no-guide-lines` undefined | Pinned exactly as QA wrote: `.garden-stage--print` has one element child `#garden-frame`; iframe `body` has one element child `article.rz-resume`; iframe `head` has no `<style>`/`<script>` and exactly one `link[rel=stylesheet]` after `waitForThemeHref`; plus no inline `style` on the iframe `html` (the measurement leaves no residue) |
| Minimum and singular | `estimatePages(0, 946)` → 1 and `About 1 page (Letter)` in the unit test; `ZG-10/min-one` in the browser (single `.rz-name` child → `data-page-estimate="1"`, text `About 1 page (Letter)`) |
| Settling | Readout carries `data-page-estimate="N"`, `data-page-size`, `data-page-size-source`; every probe uses `waitForSelector` on the value, never a timeout |
| Non-blocking: ZG-7 sentence must survive | In `ZG-10/hint` |

Dependencies: unchanged (`ZG-7`). Also added: this PBI's diff touches nothing under `themes/` and not `U3_PRINT_PAGES` (S3/U3 stay green), since the readout must not move page counts.

## ZG-17 — Add the repo LICENSE and state the theme-contribution license terms

| QA blocker | Exact change |
| --- | --- |
| "No file outside …" contradicts the DoD | `git diff --name-only <base>..HEAD -- . ':!progress.md' ':!features.json'` lists exactly six files (the five plus `frontend/scripts/probes.mjs`, which now carries the static probe) |
| `_blank.css` still advertises `CC BY-NC-SA` | `License:` line must contain both `MIT` and `CC BY 4.0`; `grep -n -i -E "BY-NC\|noncommercial\|non-commercial" themes/_blank.css` prints nothing |
| README License line has no AC | `grep -n -i "license" README.md` hits and a matching line contains `MIT` (verified: no such line today) |
| `LICENSE` stub-passable | `grep -c "Permission is hereby granted, free of charge" LICENSE` = 1 and `^Copyright \(c\) [0-9]{4} .+` hits; holder is a human decision (Notes proposes `Nathan Sculli`) |
| `themes/*.css` glob includes `_blank.css` | Named: `grep -n -E "^ \* License: +MIT$" themes/nightgarden.css themes/quarto.css themes/switchyard.css` hits all three |
| Non-blocking: section-scoped greps, wire into a test | License section defined as `## License` → next `## `; must contain `MIT`, `CC BY 4.0`, `CC BY-NC`, `not accepted`, `switcher`; file-wide negative for hosted-page promises. All greps also live in static probe `ZG-17/license-docs` in `probes.mjs` so ZG-18/ZG-19 cannot regress them |

Dependencies: unchanged (`ZG-16`; dependents ZG-18, ZG-19 untouched).

---

## Dependency changes

None. QA's conditional edges were resolved by design rather than by adding edges:

- ZG-6 → ZG-14: **not added** — sample bytes are embedded at build, `junior-all-themes` prints through the chrome shell route, and ZG-14 keeps sole ownership of the `skeleton/samples/*` copy step ("when present"). Ownership table delta: ZG-6 owns `skeleton/samples/junior.{json,html}` (source), `skeleton/resume-schema.json`, `frontend/generated/Samples.elm`; ZG-14 owns `dist/skeleton/**`.
- ZG-6 → ZG-3: **not needed** (string score); the existing ZG-5 → ZG-3 edge remains.
- ZG-10 → ZG-5 / ZG-11: **not added** — no paste route, no long fixture; content-change recompute is proven probe-side.
- ZG-17: unchanged.

Graph unchanged from cycle 3 (still acyclic; ready-at-start set unchanged).

## Shared-fixture / tool additions (for the ownership table)

| Path | Owner | Notes |
| --- | --- | --- |
| `skeleton/samples/junior.json` + `junior.html` | ZG-6 | locked in `renderer/tests/acceptance.rs`, `RZ_UPDATE_FIXTURES=1` |
| `skeleton/resume-schema.json` (+ provenance line in `skeleton/README.md`) | ZG-6 | pinned commit + sha256; any later schema assertion references it |
| `frontend/generated/Samples.elm` (build output of `generate.mjs`) | ZG-6 | embedded sample bytes |
| `frontend/static/page-estimate.js` + `frontend/scripts/page-estimate.test.mjs` | ZG-10 | pure geometry/estimate module and its `node --test` |
| `ajv` devDependency | ZG-6 (human approval pending) | offline; FAIL-not-skip until installed |

## Changed ids

Every PBI whose body changed in this pass (prior blessings invalidated; full PO → QA → CTO chain required):

- **ZG-6** — body (string score, vendored schema + `ajv` runner with anti-stub, `example-renders`, sidebar sentence, `textContent`, shell-print route, build-time embedding / no ZG-14 dep, copy-failed state, sample-not-stored rule, pinned names, image-file diff command, `acceptance.rs` lock)
- **ZG-10** — body (formula oracle at paper width + ± 1 PDF check + node unit test, `[data-pdf-hint]`, switch/content recompute probes without ZG-5/ZG-11, `paper-size` negatives and fallbacks, `no-guide-lines` assertions, min-one/singular, settle-on-attribute, themes/`U3_PRINT_PAGES` untouched)
- **ZG-17** — body (DoD-compatible diff AC with six files, `_blank.css` negatives, README License line, MIT text greps, three named first-party files, section-scoped README greps, static probe `ZG-17/license-docs`)

No other PBI body or dependency was edited. Untouched: ZG-1–ZG-5, ZG-7–ZG-9, ZG-11–ZG-16, ZG-18–ZG-22.
