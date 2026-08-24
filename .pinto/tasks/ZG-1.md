+++
id = "ZG-1"
title = "Make the renderer pass clippy pedantic so just verify is green"
status = "todo"
rank = "i"
labels = ["avril", "round-1", "harness"]
created = "2026-08-23T23:52:45.617948Z"
updated = "2026-08-24T00:29:13.747383Z"
+++

## Why
Every round-1 PBI is gated by `just verify`; today it is red on the renderer, so no persona-facing slice can be honestly verified (all five personas indirectly; AXEL DoD).
## Covers
none (harness debt named in the intent's repo facts and `progress.md`)
## Scope in
- Fix the 11 `clippy::pedantic` findings in `renderer/` (`must_use`, `missing_errors_doc`, `Option<&T>` param, wildcard import, elided lifetime, `map().unwrap_or`, doc backticks, pass-by-value)
- Keep `renderer/tests/acceptance.rs` (the tree-equality lock against `skeleton/example.html`) unchanged
## Scope out
- Any behaviour change to emitted HTML (that is ZG-2 / ZG-3)
- Allowing lints (`#[allow(clippy::…)]`) or lowering the gate in `justfile` — suppression is debt, not a fix
- Backend crate scaffolding
## Acceptance criteria
- [ ] `cd renderer && cargo clippy --all-targets -- -D warnings -D clippy::pedantic` exits 0
- [ ] `just verify` exits 0 on a free `PROBE_PORT` (fmt, clippy, cargo test, frontend probes all green)
- [ ] `grep -rn "allow(clippy" renderer/src renderer/tests` prints nothing
- [ ] `cd renderer && cargo test` reports `0 failed` in every test binary; no test is removed (every name printed by `cargo test -- --list` before the change is still printed after) and the total count is ≥ 19 (today's count; more is fine if ZG-2/ZG-3 land first); `skeleton/example.html` is unchanged (`git diff --stat skeleton/` empty)
- [ ] `git diff --name-only -- . ':!progress.md' ':!features.json'` lists only paths under `renderer/` — the harness tracking files the DoD requires are the sole exception
## Dependencies
- none
## Notes
- none
