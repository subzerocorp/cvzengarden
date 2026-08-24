# ZG-11 PETC — Print a real résumé without blank pages, lost bullets, or pale ink

**PBI:** ZG-11 (AVRIL triple-blessed, cycle 8)
**AXEL:** Generator `code-writer` (+ `rust-code-writer` for the fixture test); adversaries reviewer → tester → architect (Rust + CSS + JS)
**Decomposition mode:** off

## Goal
Quarto/Switchyard/Nightgarden print a long résumé with a full first page, intact entries, inked bullets, and readable secondary text; Jordan prints 2 pages on every theme; long fixture ≤ 3 pages.

## Approach
Phase 1 builds the oracle before the fix: the `long-resume.json` fixture (Marcus Okafor-Lindqvist) + byte-locked crate output + cargo test; probe helpers `openResumePage`, `printableWidthPx/HeightPx`, `paginate`, `contrastRatio` in `frontend/scripts/probes/lib/` (CTO rule 6) with the ZG-11 probes wired in; capture the anti-vacuity FAIL lines against the current sheets. Phase 2 edits the three theme sheets (section `break-inside: auto` in print; keep entry-level avoid; drop Switchyard's forced projects break; printed markers with `print-color-adjust: exact`; Nightgarden print ink ≥ 4.5:1), re-baselines `U3_PRINT_PAGES` to 2/2/2 and adds `LONG_PRINT_PAGES`.

## Files likely
`frontend/fixtures/long-resume.{json,html}`, `renderer/tests/fixtures.rs`, `frontend/scripts/probes.mjs`, `frontend/scripts/probes/lib/{page,geometry,contrast}.mjs`, `themes/{quarto,switchyard,nightgarden}.css`.

## Test strategy
Every AC is a named probe `ZG-11/<slug>` or the cargo test; anti-vacuity lines recorded from phase 1 (pre-change sheets); `just verify` green.

## Risk
Fixture must trip E1 at 682 px under Quarto — lean long. `paginate` is an approximation; page-count AC uses real `printToPDF`.

## Phases
1. **Phase 1 of 2** — fixture, cargo lock, helpers, probes (expected FAILs recorded as anti-vacuity evidence; suite not required green yet — phase 1 commit may leave ZG-11 probes red only if gated behind an env flag; prefer landing probes + fixture and keeping `npm test` green by running ZG-11 probes only when `themes/` are fixed… see Generator note).
2. **Phase 2 of 2** — theme CSS + page-count re-baseline + verify.

## Unresolved questions
- none
