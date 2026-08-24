# ZG-12 PETC — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks

**PBI:** ZG-12 (AVRIL triple-blessed, cycle 3b) · deps ZG-11 done
**AXEL:** Generator `code-writer` (CSS + JS probes + one contract note); adversaries reviewer → tester → architect
**Decomposition mode:** off

## Goal
Long names fit Nightgarden's rail at 1280 and 390; below-fold sections are painted (opacity 1) before entry with or without scroll-driven-animation support; `\n` in highlights renders as line breaks in all themes.

## Approach
Per PBI scope: `.rz-name` overflow-wrap/hyphens + size step; `rz-rise` declared only inside `@supports (animation-timeline: view())` with `animation-fill-mode: forwards`; keep sheen/foxfire and the print/reduced-motion guard; `.rz-bullet, .rz-prose p { white-space: pre-line }` ×3; CLASS-CONTRACT §5.3 note. Probes in `frontend/scripts/probes/zg-12.mjs` reusing `openResumePage`; brace-matching CSS structure check as a pure calc with unit tests.

## Files likely
`themes/nightgarden.css`, `themes/quarto.css`, `themes/switchyard.css`, `skeleton/CLASS-CONTRACT.md` (§5.3 one sentence), `frontend/scripts/probes/zg-12.mjs` (+ lib css-structure calc + tests), `frontend/scripts/probes.mjs` wiring.

## Test strategy
ZG-12/name-fits, rise-css-structure, painted-without-support, painted-with-support, reduced-motion, pre-line; anti-vacuity FAIL lines against `git show 72596c7:themes/nightgarden.css`; BAR-T1 + S3 green; `just verify`.

## Risk
`fullPage` screenshot may nudge `view()` timelines — computed opacity is the primary oracle per the PBI.

## Phases
1. **Phase 1 of 1**

## Unresolved questions
- none
