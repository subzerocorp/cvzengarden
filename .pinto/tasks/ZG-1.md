+++
id = "ZG-1"
title = "Make the renderer pass clippy pedantic so just verify is green"
status = "todo"
rank = "i"
labels = ["avril", "round-1", "harness"]
created = "2026-08-23T23:52:45.617948Z"
updated = "2026-08-23T23:52:45.617948Z"
+++

## Why
Every round-1 PBI is gated by `just verify`; today it is red on the renderer, so no persona-facing slice can be honestly verified (all five personas indirectly; AXEL DoD).
## Covers
none (harness debt named in the intent's repo facts and `progress.md`)
## Scope in
- Fix the 11 `clippy::pedantic` findings in `renderer/` (`must_use`, `missing_errors_doc`, `Option<&T>` param, wildcard import, elided lifetime, `map().unwrap_or`, doc backticks, pass-by-value)
- Keep `renderer/tests/acceptance.rs` byte-lock unchanged
## Scope out
- Any behaviour change to emitted HTML (that is ZG-2 / ZG-3)
- Allowing lints (`#[allow(clippy::…)]`) or lowering the gate in `justfile` — suppression is debt, not a fix
- Backend crate scaffolding
## Acceptance criteria
- [ ] `cd renderer && cargo clippy --all-targets -- -D warnings -D clippy::pedantic` exits 0
- [ ] `just verify` exits 0 on a free `PROBE_PORT` (fmt, clippy, cargo test, frontend probes all green)
- [ ] `grep -rn "allow(clippy" renderer/src renderer/tests` prints nothing
- [ ] `cargo test` in `renderer/` still reports the same 19 tests passing and `skeleton/example.html` is byte-identical to before (`git diff --stat skeleton/` empty)
- [ ] The diff touches only `renderer/` (`git diff --name-only` contains no other path)
## Dependencies
- none
## Notes
- none
