# PBI Completion — ZG-11

## Title
Print a real résumé without blank pages, lost bullets, or pale ink

## Phases
- phase-1: BLESS reviewer | tester | architect — commit `79cc260` (after one Tester REJECT: unit tests + node --test runner added)
- phase-2: BLESS reviewer | tester | architect — commit (see git log "ZG-11 phase 2")

## AC Evidence
See `## Execution Evidence` on the PBI (`pinto show ZG-11`): page-1 fill 0.93/0.91 (was 0.36/0.30), pages 2/2/2 Jordan and 3/3/3 long, inked markers 17.9/18.9/16.5:1, Nightgarden ink ≥ 7.56:1, no forced breaks, entries intact, anti-vacuity FAILs recorded against 020e991.

## Verification matrix
- fmt / clippy pedantic / cargo test (10+9+2) / node:test 79 / Playwright probes: PASS

## Board
- status: done

## Follow-ups / non-goals honored
- ZG-19: document long/short section print convention + entry-header grid; Switchyard `dense` may float Languages above Skills; ZG-13: page counts depend on hosted faces (offline → 4 pages); PAGE_RULES duplicates @page numbers; split `rendered(row)` in fixtures.rs.
