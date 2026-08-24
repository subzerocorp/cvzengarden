# ZG-1 PETC — Make the renderer pass clippy pedantic so `just verify` is green

**PBI:** ZG-1 (AVRIL triple-blessed, cycle: PO 3 / QA 3 / CTO 1)
**AXEL:** `code-writer` + `axel` + `rust-code-writer` + `rust-errors`; adversaries `rust-code-reviewer` → `rust-code-tester` → `rust-architect`
**Decomposition mode:** off

## Goal
`cd renderer && cargo clippy --all-targets -- -D warnings -D clippy::pedantic` exits 0 with no `#[allow(clippy::…)]`, no change to emitted HTML, no test removed, and `just verify` green.

## Approach
Fix each of the 11 pedantic findings at the source: `#[must_use]` on pure calcs, `# Errors` docs on `Result` fns, `&Option<T>` → `Option<&T>`, replace the wildcard `use crate::resume::*`, explicit lifetimes, `map_or`, backticked doc identifiers, borrow instead of pass-by-value. No behavioural edits.

## Files likely
`renderer/src/{lib,emit,html,date,slug,resume}.rs`; tracking: `progress.md`, `features.json`.

## Test strategy
`cargo test -- --list` name set identical before/after; `cargo test` 0 failed; `git diff --stat skeleton/` empty; `just verify` (PROBE_PORT=4310) green.

## Risk
Low. Pass-by-value → borrow changes could ripple signatures inside the crate only.

## Phases
1. **Phase 1 of 1** — clippy fixes + verification.

## Unresolved questions
- none
