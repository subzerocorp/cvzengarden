# PBI Completion — ZG-23

## Title
Make the S1 cold-load FOUC probe deterministic with a painted-frame oracle

## Phases
- phase-1: BLESS reviewer | tester | architect — commit `748892a`

## AC Evidence
- [x] three `ZG-23/*` PASS lines, no `S1 cold load`, no SKIP — `PROBE_PORT=4320 npm test`
- [x] anti-stub behavioural (link at end of body; media=print onload) — both `FAIL ZG-23/cold-paint-order` (fcp 44 / 24 ms < ~420 ms), exit 1
- [x] anti-stub static — both `FAIL ZG-23/cold-sheet-blocking`
- [x] determinism N=10 (4320–4329) — ALL-GREEN, FCP 440–456 ms (first invocation hit EADDRINUSE from an orphaned persona-lab server; disclosed on the PBI)
- [x] `PROBE_PORT=4330 just verify` exit 0
- [x] diff scope — probes.mjs + probes/lib/{paint,sheet-blocking}.mjs

## Verification matrix
- fmt / clippy pedantic / cargo test / frontend probes: PASS

## Board
- status: done

## Follow-ups / non-goals honored
- Unit tests for the pure calcs (node:test) before the next probes/lib module; try/finally on the cold page; shared page actions → lib later. Swap-FOUC probe byte-identical.
