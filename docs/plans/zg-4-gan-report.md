# ZG-4 — code GAN report

PBI: ZG-4 "Run the Renderer in the browser via Wasm and prove it matches the crate". Plan: `docs/plans/zg-4-petc.md`. Evidence: `/tmp/persona-lab/conductor/zg-4-phase1-evidence.md`.

## Phase 1 — Reviewer

Skills: `rust-code-reviewer`, `rust-errors`, `code-writer`. Scope: `renderer/src/error.rs`, `renderer/src/lib.rs`, `renderer/Cargo.toml`, `renderer/examples/render.rs`, `renderer/tests/example.rs`, `renderer-wasm/{Cargo.toml,src/lib.rs}`, `justfile`, `.gitignore`.

Verified locally: `cargo fmt --check`, `cargo clippy --all-targets -D warnings -D clippy::pedantic`, `cargo test` clean in both crates (renderer 29+9+2+2+28, renderer-wasm 3). `just wasm` 1.0 s warm; `git status --short` shows no `frontend/static/wasm/` entries. `PROBE_PORT=4392 just verify` exit 0, 90 PASS lines.

**RenderError (`renderer/src/error.rs`).** One data-only variant `InvalidDocument { message, line, column }`, `thiserror` derive, `Debug + Clone + PartialEq + Eq` — matchable and testable, no `Box<dyn Error>`, no `anyhow`. `From<serde_json::Error>` is the only conversion and lives next to the type, so `render_json` uses `?` with no inline `map_err` — that is exactly the `rust-errors` shape. Display wording `not a valid JSON Resume document: <serde message>` is plain words; the serde suffix carries `at line N column M`, which the AC requires on stderr.

- Line/column redundancy: `message` already contains the position, so `line`/`column` are duplicated data. I accept it: the fields are the structured half (the Chrome/API may highlight a position without regex-parsing the message) and the `From` impl is the single place both are set, so they cannot drift. The doc comment says so. Not a blocker.
- `serde_json::Error` leak: `Resume::from_json` (`renderer/src/resume.rs:46`) still returns `serde_json::Error` publicly, and the module header of `error.rs` claims callers "never need to depend on `serde_json`". That claim is only true for the `render_json` façade. `from_json` is used by nothing but `render_json` inside the crate (grep: one call site), so tightening it to `Result<Self, RenderError>` is a two-line change with no external caller. Acceptable for this phase because ZG-4's contract is `render_json` and ZG-21's Axum will call `render_json` too; but it must be closed before the Axum crate lands, otherwise the API gets a second error type to map. Follow-up, not blocker.
- Nothing else in the public surface names `serde_json` (checked `renderer/src`, `tests`, `examples`).

**Example binary (`renderer/examples/render.rs`).** No `unwrap`/`expect`; `ExitCode` returned from `main`, not `process::exit`; three flat helpers (`read_stdin`, `write_stdout`, `fail`) and a two-arm `main` — no nesting beyond one `match`. stdout is written only on `Ok` via a locked handle and explicitly flushed; stderr only on failure; exit 1 on every failure path (read, render, write). `fail` takes `impl Display` so the same function handles `io::Error`, `RenderError`, and the formatted stdin message. `map_or_else(fail, |()| ExitCode::SUCCESS)` is terse but readable. Fine.

**Test (`renderer/tests/example.rs`).** Uses `env!("CARGO")` + `env!("CARGO_MANIFEST_DIR")` so the test runs the example through the same toolchain and target dir regardless of `CARGO_TARGET_DIR`, profile, or invoking cwd — that is deterministic and is what the doc comment argues. Nested `cargo run` inside `cargo test` is safe because cargo drops the build lock before running test binaries (observed: 0.2 s). `expect` in test helpers is allowed. `jordan_json` uses the shared `skeleton/resume.json`, consistent with `tests/fixtures.rs`.

**Wasm crate (`renderer-wasm/`).** `map_err(|err| err.to_string())` is the one and only inline `map_err`, and it is at the ABI edge with a comment explaining why (`wasm-bindgen` carries `String`, not a custom error) — this is the sanctioned exception. `crate-type = ["cdylib", "rlib"]`: `cdylib` for wasm-pack, `rlib` so native `cargo test` links unit tests and any future integration test. `[profile.release] opt-level = "s", lto = true` is the standard size profile for a web module. Only dependency besides the pure crate is `wasm-bindgen = "0.2"`; the pure crate's `Cargo.toml` gained only `thiserror` and the `rust-version` pin — it stays wasm-free, as the PBI demands. `contract_version()` exposes `CONTRACT_VERSION` per Avril's set-level note 8.

**justfile / .gitignore.** `check`, `fmt`, `clippy`, `test-rust` each gained the `renderer-wasm` line in the same shape as `renderer`; `wasm` recipe uses `--out-dir ../frontend/static/wasm`; `.gitignore` ignores `renderer-wasm/target` and `frontend/static/wasm/` (verified with `git check-ignore`). `renderer-wasm/Cargo.lock` is tracked — correct for a crate that produces a deployable artifact.

Nits (no action needed this phase): the example doc says "prints the error to stderr" — it also prints stdin/stdout I/O failures there, which the code handles but the sentence does not mention; `wasm-pack` warns about a missing LICENSE file for the `license` key — cosmetic.

**BLESS ZG-4 phase-1 — one thiserror façade, a clean oracle binary with disciplined stdout/stderr/exit codes, and a wasm bridge whose only `map_err` sits at the ABI edge; the remaining `serde_json::Error` on `Resume::from_json` is an internal loose end to close before ZG-21, not a defect in this slice.**

## Phase 1 — Tester

Skills: `rust-code-tester`, `code-writer`.

Ran: `cargo test` in `renderer` (70 tests, all pass, `tests/example.rs` 2/2 in 0.19 s) and `renderer-wasm` (3/3). Ran the AC commands by hand: `cargo run -q --example render < ../skeleton/resume.json` exit 0, 18 575 bytes, `cmp` against `render_json` identical (evidence file); `printf '{' | cargo run -q --example render` exit 1, stdout 0 bytes, stderr `not a valid JSON Resume document: EOF while parsing an object at line 1 column 1`.

**Parity test** `example_render_matches_render_json`: Arrange (read fixture, compute `render_json` in-process), Act (spawn example with the fixture on stdin), Assert (`status.success()` with stderr as the failure message, then `assert_eq!(output.stdout, expected.into_bytes())`). Byte-equal on raw `Vec<u8>`, not a lossy string compare — a trailing-newline or encoding regression would be caught. Good.

**`{` case** `example_render_reports_malformed_json_on_stderr`: asserts `code() == Some(1)` (not merely "not success"), `stderr.contains("line 1")`, and `stdout.is_empty()` — all three AC clauses, exactly. Good.

**stdin/stdout failure paths.** `read_stdin` failing (non-UTF-8 stdin, or a closed handle) and `write_stdout` failing (EPIPE on a closed pipe) are not covered by tests. Non-UTF-8 stdin is testable cheaply — feed `b"\xff"` and assert exit 1, stderr starts with `could not read stdin`, stdout empty — and I would like to see it added, but the paths are three lines each, delegate entirely to `io::Error`'s Display, and cannot produce a false-positive parity result (they never write to stdout with exit 0). The stdout EPIPE path needs a closed reader and is platform-flaky; not worth a test. Acceptable for phase 1; the non-UTF-8 case is a follow-up.

**RenderError unit tests** (`error.rs`): `from_serde_keeps_line_and_column` asserts `(line, column) == (1, 1)` and that the message names the line; `display_is_plain_words_with_position` asserts the prefix and `line 2` on a two-line input — so the conversion and the Display are both pinned, and a variant whose Display forgot the position would fail. The `parse_failure` helper keeps the tests AAA-flat. Coverage of the only public item in the module: complete.

**Wasm crate tests run natively.** `cargo test` in `renderer-wasm` compiles the `rlib` for the host and exercises `render_json`, the error path (`line 1`), and `contract_version`. Native is the right level for phase 1: the crate's only logic is the `map_err`, and browser behaviour (module load, thrown string vs `Result`) is exactly what phase 2's `ZG-4/wasm-parity` / `wasm-error` probes prove. No `wasm-bindgen-test` needed.

**Stub detection.** A `render_json` in the wasm crate that returns a constant is caught by `render_json_matches_pure_crate`, which compares against `resumezen_renderer::render_json` of the Ada document at test time; a stub that returned `Ok` for `{` is caught by `render_json_error_names_the_line`; a `contract_version` stub returning `"1.0"` literally would pass, but it compares against the crate constant so it fails the day the constant moves. The oracle side has the same property: a stubbed example that printed `skeleton/example.html` would fail the byte-equal test (PBI notes the first diff at byte 311).

Determinism: `env!("CARGO")` pins the toolchain; the fixture is repo-owned; no network, no time, no randomness. Runtime 0.2 s.

**BLESS ZG-4 phase-1 — every public item added in this phase has a test that would fail on a stub, the AC commands reproduce exactly, and the untested I/O error legs cannot corrupt the parity signal; add the non-UTF-8 stdin case when the example is next touched.**

## Phase 1 — Architect

Skills: `rust-architect`, `code-writer`. Judged against the Avril round-1 set-level notes (one renderer; CONTRACT_VERSION exposed from Wasm; parity enforced not assumed).

**Strata.** Three layers, each one direction: `resumezen-renderer` (pure: JSON → HTML, one error type) → `resumezen-renderer-wasm` (adapter: `String` in, `Result<String,String>` out, `contract_version()`) → (phase 2) `ports.js`. The pure crate gained nothing browser-shaped — no feature flag, no `cfg(target_arch)`, no `wasm-bindgen` — so ZG-21's Axum crate will link the identical crate and call the identical `render_json`. There is exactly one render path; the bridge has no branching, no parsing, no caching, and the `examples/render.rs` oracle is a 30-line adapter of the same function to stdin/stdout. That is the "thin wasm crate, pure crate untouched" decision artifact Avril blessed, made real.

**One error type at the boundary.** `RenderError` is the crate's error façade; the wasm bridge and the example both consume it via `Display`, the future Axum handler will match on it for 422 vs 500. The lingering `serde_json::Error` on `Resume::from_json` is a stratification wart (a lower-layer type visible through a public constructor); it is not reachable from any current caller and must be folded into `RenderError` before a second consumer (ZG-21) exists. Noted as a follow-up with a hard deadline, not a blocker for this slice.

**Skew check.** `contract_version()` is exported from the Wasm module (visible in the generated `.d.ts`), satisfying set-level note 8's zero-cost half. Avril also asked for crate `version()`; it is not there. Cheap to add (`env!("CARGO_PKG_VERSION")`) and it should ride along in phase 2 when `ports.js` reads `contract_version`, so the deploy-time probe can compare both. Follow-up.

**Toolchain pin.** `rust-version = "1.87"` in both crates — the two crates cannot drift apart on MSRV, and the pin is on the pure crate so the Axum crate inherits the same floor. Local toolchain is 1.94; the pin is honest rather than aspirational.

**Justfile matrix.** `check`, `fmt`, `clippy`, `test-rust` all iterate `renderer` then `renderer-wasm` in the same form as the conditional `backend` line — when ZG-21 adds `backend/Cargo.toml` it slots in without editing the recipes. Two separate workspaces (two `Cargo.lock`s) is a mild smell; a root virtual workspace would give one lock, one `target`, and one `cargo clippy --workspace`, and is the natural moment to do it when `backend/` arrives. Not now.

**Should `just wasm` be in `just verify`?** No, and the plan is coherent as written: phase 2 makes `npm run build` invoke `wasm-pack build --target web` (with the fail-fast install hint), and `test-frontend` already runs `npm test` which builds before probing — so `verify` will build the module and the `ZG-4/wasm-parity` probe will compare it against the same-checkout oracle. Adding `wasm` to `verify` separately would build it twice. `just wasm` stays as the developer shortcut. The only thing to hold phase 2 to: `test-frontend` must fail (not skip) when `wasm-pack` is absent, which the AC already pins.

**Two-year test.** A new engineer reading `renderer-wasm/src/lib.rs` understands the whole bridge in one screen and cannot introduce logic there without it being obviously out of place; the oracle binary means "does the browser match the crate" is a `cmp`, not an argument. This makes the system easier to understand, not harder.

**BLESS ZG-4 phase-1 — the renderer is one crate linked twice with a byte-level oracle between them, the bridge is logic-free, and the version hook Avril asked for is in place; fold `from_json`'s error into `RenderError` and add `version()` before the Axum crate exists.**
