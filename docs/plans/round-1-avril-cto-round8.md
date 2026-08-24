# AVRIL round 1 — Visionary CTO review (cycle 8)

**Role:** `visionary-cto-agent` (third and final adversary) · **Date:** 2026-08-24 · **Cycle:** 8
**Scope:** ZG-11 and ZG-20 — both carry a fresh PO BLESS (`round-1-avril-po-round8.md`) and a fresh QA BLESS (`round-1-avril-qa-round8.md`) on the cycle-8 bodies. This is my first verdict on either id (cycle 1 deferred all seven concurrent items); I judge the current bodies against the target shape and the execution rules I set in cycle 1, not against their revise history. ZG-12 and ZG-19 are read for the whole-set view and the dependency graph; no verdict is emitted for them.
**Inputs read in full:** `docs/plans/round-1-avril-cto-round1.md` (my target shape, dependency graph, execution guidance 1–9, "what I will look for in cycle 2"), `round-1-avril-intent.md` (locked decisions, repo facts), the PO and QA cycle-8 reviews, the two current bodies (`pinto show ZG-11 ZG-20 --plain`), `pinto show ZG-12 ZG-19 --plain`, `frontend/scripts/probes.mjs` (1126 lines, no `lib/`), `frontend/scripts/generate.mjs` (`parseTheme` at 27 — today's only Theme-header parser), `frontend/package.json`, `justfile`, `themes/*.css`.

Mandate: *BLESS only backlog items that advance a coherent two-year trajectory without irreversible entanglement; REJECT anything that buys short-term motion at the cost of future clarity.*

I ask only strategic questions. Product priority is PO's and settled; AC detail is QA's and settled. I do not rewrite bodies or touch the board. Guidance that does not block is labelled "Guidance for AXEL" and is not an AC.

---

## What I said I would look for (cycle 1) and what the bodies pin

| Cycle-1 rule | ZG-11 | ZG-20 |
| --- | --- | --- |
| 6. `probes.mjs` becomes a runner: helpers in `frontend/scripts/probes/lib/*.mjs`, one module per PBI, `probes.mjs` imports and runs them; ACs pin `PASS  ZG-n/<slug>` lines and the entry point, not layout | Body names `openResumePage`, `printableWidthPx`, `printableHeightPx`, `paginate`, `contrastRatio` as "probe helpers in `probes.mjs`" with owners; every AC pins a `ZG-11/<slug>` line and the helper *signatures*, never a file path inside `probes.mjs` | Body says `probes.mjs` runs `checkTheme` first in `staticProbes()`, `--static` stops after `staticProbes()`; `lint-theme.mjs` is its own module with a pure `checkTheme(source)`; ACs pin lines, exit codes and the `node scripts/probes.mjs --static` entry point |
| 5. One Theme-header parser (`theme-header.mjs`), three importers | — | The `header` warning reads `Author:`/`URL:`/`License:` — the same fields ZG-16 makes canonical and `generate.mjs` `parseTheme` reads today. The body does not say which parser; it does not forbid sharing one |
| Re-baseline print constants exactly once | `U3_PRINT_PAGES` → `{2,2,2}` and new `LONG_PRINT_PAGES`, both in this PBI; ZG-13's AC asserts it does not edit them; "whichever lands second re-checks" | — |
| 3. One table-driven golden-file lock | `renderer/tests/fixtures.rs::long_resume_html_is_crate_output` with `RZ_UPDATE_FIXTURES=1` — the same env var and shape as `acceptance.rs` | — |
| 2. `dir="auto"` (ZG-3) regenerates every crate-output lock | `long-resume.html` is one of the four; ordering fact stands | — |

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

**Trajectory.** The product change is five CSS rules across three first-party sheets; the durable asset is the print-geometry toolkit around them. Two-year view: every future Theme submission (Phase 4) and every future paper-size or font change (ZG-13 today) will need exactly these instruments — a real senior résumé at paper width, an `@page`-derived printable box per theme, a break simulator, and a PDF page count asserted with `!==`. This PBI builds them once, with named owners, and ZG-12 already consumes `openResumePage`. That is complexity pulled forward because it reduces option-value loss: without it, every later print item would grow a bespoke measurement, and round 0's failure (print tested only on Jordan) would recur.

**Seam check.** The body states "in `probes.mjs`" for the helpers, but every AC pins behaviour (`PASS  ZG-11/article-width … <n>px`, helper signatures, constant names) and no AC greps `probes.mjs` for a helper. So the layout rule from cycle 1 — helpers land in `frontend/scripts/probes/lib/` and `probes.mjs` imports them — is satisfiable without touching a single AC. The code GAN's architect is bound by that rule, not by the body's prose location. Clean seam.

**Coupling I checked.** (a) `paginate` is a stated approximation of Chromium's break positions, cross-checked by `page-count` against a real PDF; if Chromium's break algorithm changes, `page-count` moves first and the simulator is corrected against it — the approximation is bounded by an oracle, not trusted. (b) The printable constants are derived from each theme's `@page` in prose and hard-coded as numbers in the helper; if `printableWidthPx` ever reads the sheet instead of a table, the AC's numbers still hold. Guidance, not a blocker. (c) The fixture lock reuses `RZ_UPDATE_FIXTURES` and the `fixtures.rs` file — the same shape as `acceptance.rs`, so execution rule 3 (one helper over `(json, html)` pairs) applies and nothing here prevents it. (d) Re-baseline happens once here; ZG-13 is forbidden from editing the constants — the rule I asked for is in both bodies.

**Nothing irreversible.** No new dependency, no new toolchain (`pdftoppm` explicitly not a prerequisite), Chromium-only stated as a fact rather than a design. The scope-out on the Garden iframe is the right stratification: paper geometry is measured on the Skeleton as the top-level document, never through the Chrome.

**Size.** PO's seam (fixture + helpers as a `spike`, never the CSS) is sound and I do not need to call it: the five helpers and one fixture are small, each has one owner, and splitting them would make ZG-12 depend on a spike instead of a product item.

Guidance for AXEL: `openResumePage`, `printableWidthPx`/`printableHeightPx`, `paginate`, `contrastRatio` and `printToPdf` go in `frontend/scripts/probes/lib/` as pure or narrowly-effectful modules; `probes.mjs` imports them. `LONG_PRINT_PAGES` and `U3_PRINT_PAGES` live together in one constants module so "re-baselined exactly once" is one diff. Implement `long_resume_html_is_crate_output` as a row in the shared golden-file helper, not a fourth bespoke test.

**BLESS ZG-11 — builds the print-geometry instruments the next two years of Theme and font work will reuse, with single owners and ACs that pin behaviour rather than file layout, so the `probes/lib/` runner shape and the one-time constant re-baseline are enforceable at execution without reopening the body.**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

**Trajectory.** This is the executable form of locked decision 9 ("lint for `rz-*` selectors, forbid script") and decision 3 ("résumé words never only in `content:`"). It puts the reviewer's rule in one pure function with a stated limit (regex/tokeniser, limits documented in the file header) — the right honest shape for a Phase-4 gate that humans still back. In two years, when Theme submissions arrive by PR from strangers, the thing that scales is *this* function being the same one `probes.mjs` runs on first-party sheets every `just verify`; the meta-test proves the two are one program. That is the parity discipline I asked for on the renderer (ZG-4) applied to the Designer lane.

**Shared header parser.** The `header` warning is the third reader of the Theme header (`generate.mjs` at build, ZG-15 in the browser, this lint). The body neither names nor forbids `theme-header.mjs`; it depends on ZG-19, which itself depends on ZG-16, the item that makes the five header fields canonical. So by the time ZG-20 executes, the canonical format exists and execution rule 5 (one pure `theme-header.mjs`, three importers; three regexes is a reject at code review) is enforceable without a body change. Clean seam — provided the code GAN holds the rule. I restate it below.

**Runner shape.** `checkTheme` first in `staticProbes()`, and `--static` stopping after `staticProbes()`, are the first concrete steps toward the runner I described in rule 6: a static half and a browser half with a documented boundary. The `--static` AC's list of browser-only lines is, in effect, the specification of that boundary. Nothing here paints us in: the flag is additive, the flag-less run is unchanged, and no AC pins the position of `staticProbes()` inside the file.

**Regex lint, not a parser — is that a trap?** No, because the limit is bounded and stated: `@keyframes` bodies and at-rule preludes are the two places a tokeniser is wrong, and the body now excludes both (`@page :first`, `from`/`50%`/`to`). The exit criterion for the shortcut is explicit in `scope_out` ("document the known limits in the file header"). If a future Theme needs nesting or `@scope`, the replacement is a parser behind the same pure `checkTheme(source) -> {errors, warnings}` signature and the same unit file — the seam is the function, and it is already there. Not a "temporary" shortcut without an exit.

**Test wiring.** `test` = `npm run probe && node --test scripts/*.test.mjs` is the one place unit tests join `just verify`; ZG-10 and ZG-19 add rows, not wiring. The concurrency constraint (only the meta-test writes into `themes/`) is a stated invariant for future test authors; `--test-concurrency=1` was not taken — correct, it would hide the constraint rather than state it. Rule 9 (once ZG-22 lands `npm test` needs Rust) is unaffected.

**Dependencies.** ZG-19 → ZG-20 is the right edge (the `header` warning must read the canonical header). PO's AXEL ordering (ZG-18 before ZG-20 for `CONTRIBUTING.md`) is ownership hygiene, not a graph change; I do not add an edge. No cycle.

Guidance for AXEL: `lint-theme.mjs` imports `theme-header.mjs` (the same module `generate.mjs` must be refactored to use when ZG-16 lands, and ZG-15's browser port after it); `checkTheme` stays pure — file I/O and `process.exit` only in the thin CLI. The `--static` return happens before `startServer()`; do not relocate the static `S…`/`U3` checks out of `staticProbes()` (QA's note). Document the tokeniser's known limits in the file header as `scope_out` requires, including "no nesting, no `@scope`".

**BLESS ZG-20 — makes the human reviewer's Theme rule one pure function that both the Designer and `just verify` run, with the tokeniser's limit stated and an exit behind the same signature; it depends on the canonical header (ZG-16 → ZG-19) so the single `theme-header.mjs` parser is enforceable at execution, and the `--static` boundary is the first real step toward the static/browser runner shape.**

---

## Summary

| id | PO cycle 8 | QA cycle 8 | CTO verdict | one-line reason |
| --- | --- | --- | --- | --- |
| ZG-11 | BLESS | BLESS | **BLESS** | reusable print-geometry instruments with single owners; ACs pin behaviour, so `probes/lib/` layout, the shared golden-file helper and the one-time constant re-baseline are enforceable in AXEL |
| ZG-20 | BLESS | BLESS | **BLESS** | reviewer's rule as one pure function run by Designer and `just verify` alike; bounded tokeniser with an exit behind the same signature; header parser shareable because ZG-16 → ZG-19 precede it |

2 BLESS, 0 REJECT. Both ids now carry fresh PO → QA → CTO BLESS on the cycle-8 bodies. The `notes` line on ZG-20 is answered by QA's cycle-8 BLESS and should be emptied by the conductor before the `avril-blessed` label is applied.

## Set-level notes (execution rules restated for these two ids)

- **`probes/lib/` is where ZG-11's helpers land** (`openResumePage`, `printableWidthPx`/`printableHeightPx`, `paginate`, `contrastRatio`, `printToPdf`); `probes.mjs` imports and sequences. ZG-12 and ZG-13 import from the same place.
- **One `theme-header.mjs`** for `generate.mjs`, ZG-15's browser path and ZG-20's `lint-theme.mjs`. Three regexes is a reject at code review.
- **Print constants re-baselined exactly once**, in ZG-11, in one module; ZG-13 re-checks and does not edit.
- **One golden-file helper** across `acceptance.rs` and `fixtures.rs`; ZG-11 adds a row. `dir="auto"` (ZG-3) regenerates `long-resume.html` in ZG-3's own commit if ZG-11 lands first.
- **Order** (unchanged from cycle 1): ZG-11 is ready at start and goes early, before ZG-10; ZG-12 immediately after; ZG-16, ZG-17 before ZG-14 so ZG-18/ZG-19 unblock together, then ZG-18 before ZG-20.
