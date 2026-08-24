# ZG-23 PETC — Deterministic cold-load FOUC probe

**PBI:** ZG-23 (AVRIL triple-blessed, cycle 9)
**AXEL:** `code-writer` Generator (JS/Playwright); adversaries reviewer → tester → architect personas applied to JS
**Decomposition mode:** off

## Goal
Replace the computed-style cold-load sampler in `frontend/scripts/probes.mjs` with a paint-order oracle (FCP ≥ theme-sheet `responseEnd` ≥ 400 ms held) plus a static render-blocking lock, deterministic across 10 ports, still failing on a non-render-blocking sheet.

## Approach
Per the PBI scope: route-hold `**/themes/*.css` 400 ms on a fresh page, read `performance` paint + resource entries inside the sandbox frame, three probes `ZG-23/cold-paint-order`, `cold-paint-present`, `cold-sheet-blocking`; retire the old strings; keep the swap-FOUC probe byte-identical. Paint-timing helper may live under `frontend/scripts/probes/lib/` (CTO rule 6).

## Files likely
`frontend/scripts/probes.mjs`, optionally `frontend/scripts/probes/lib/paint.mjs`; tracking files.

## Test strategy
AC commands verbatim: `npm test` on 4320; anti-stub edits of `dist/sandbox.html` (link at end of body; `media=print onload`) → both FAIL lines; N=10 loop 4320–4329 → ALL-GREEN; `PROBE_PORT=4330 just verify` exit 0.

## Risk
Paint entries missing inside the iframe (Notes say: FAIL, investigate; no fallback to computed style).

## Phases
1. **Phase 1 of 1** — oracle + helper + evidence.

## Unresolved questions
- none
