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

## Phase 2 — Reviewer

Skills: `rust-code-reviewer` (applied to JS/Elm), `code-writer`. Scope: `frontend/static/{render.js,render.test.mjs,ports.js,index.html}`, `frontend/src/Main.elm`, `frontend/scripts/{build-wasm.mjs,build-wasm.test.mjs,copy-dist.mjs,serve.mjs,generate.mjs,probes.mjs}`, `frontend/scripts/probes/zg-4.mjs` + `lib/{byte-parity,request-log,resume-size}.mjs` (+ tests), `frontend/fixtures/ada.json`, `frontend/README.md`, `renderer-wasm/src/lib.rs`. Evidence: `/tmp/persona-lab/conductor/zg-4-phase2-evidence.md`.

Verified locally: `npm run test:unit` 132/132; `PROBE_PORT=4399 npm test` exit 0 with all eight `ZG-4/*` PASS lines (a first attempt on 4397 hit `EADDRINUSE` from an unrelated listener — environment, not code); `PROBE_PORT=4398 just verify` exit 0, 98 PASS; `git ls-files frontend/static/wasm frontend/dist | wc -l` = 0.

**`render.js`.** The module is the one place that knows the Wasm glue exists. `loadModule` memoises the init promise and clears it in the `catch` so a failed load is retried on the next call — correct, and the `console.warn` keeps the cause off the Chrome surface while `LOAD_FAILURE_MESSAGE` (plain words, no `at `) is what rejects. Note for honesty: the retry only helps when `wasm.default()` (the `_bg.wasm` fetch) fails; a failed dynamic `import()` of the glue is recorded in the browser's module map and re-imports fail without a refetch — the message already says "Reload the page", so behaviour and copy agree. `plainMessage` is a two-branch calculation (string / `Error` / other) and is unit-tested for the first two. `render` wraps only `render_json`'s throw; a load failure propagates already wrapped. `swapResume` parses with `DOMParser` (scripts in a parsed document are inert and stay inert after `adoptNode`, so crate output can never execute in the sandbox), replaces the article via `replaceWith`, and sets `doc.title` — assigning `title` on a document that has a `<title>` element updates its text, no new element, so the iframe `<title>` update is safe. `renderedParts` throws when the rendered HTML has no `article.rz-resume`, which is the right guard: it makes a non-crate string unswappable.

**`rz-` in Chrome source.** `render.js` and `ports.js` both carry the DOM query string `"article.rz-resume"`. The S-probe regex `(?:\bclass|\bid|classList)\s*[=\[]?\s*["']rz-|["']rz-[a-z]` does not match either file (checked by running the regex over both): it catches a class/id *assignment* or a bare quoted `"rz-…"` token, and `"article.rz-resume"` is neither. That is the right line to draw — the DoD forbids Chrome *owning* an `rz-` class or id, not *addressing* the Skeleton it hosts (the pre-existing `ports.js` already queried `.rz-resume` at line 47, and `probes.mjs` does the same). Accept; no probe change needed.

**`ports.js` → ES module.** `git diff -w` shows exactly: the header comment, one `import`, removal of the IIFE wrapper, and the appended port wiring (two one-line record builders, one `subscribe`, `swapInFrame`, the `window.resumezen` literal). The 537-line unified diff is the de-indent. Behaviour change from IIFE → module: (1) module scripts are deferred, so `ports.js` now runs after parsing rather than synchronously at its tag — `garden.js` is a classic script before it, so `Elm` is defined either way, and the old code already waited for the frame with rAF; (2) top-level `const`s are module-scoped instead of closure-scoped — same visibility. The S1 static probe still reads the source and passes. No logic entered `ports.js`: `renderedOk`/`renderedErr` are record constructors, nothing inspects the résumé.

**Elm.** `renderResume : String -> Cmd msg`, `onRendered : (Decode.Value -> msg) -> Sub msg`, decoded by `decodeRendered` into `Result String String` with the "undecodable is a failure" rule spelled out in the doc comment. `rendered : Maybe (Result String String)` is stored and nothing reads it yet — that is ZG-5's field, placed here so the port compiles against a real consumer. Acceptable; it is one field, not a UI.

**`build-wasm.mjs`.** `buildFailure` is a pure calculation over `spawnSync`'s result (ENOENT / other spawn error / non-zero status / success), tested for all four; the `import.meta.url === pathToFileURL(argv[1]).href` guard lets the test import the calculation without spawning. `stdio: "inherit"` keeps wasm-pack's own output visible. Fail-fast is one line on stderr, exit 1 — verified through the process boundary with `PATH=""`.

**`copy-dist.mjs` / `serve.mjs`.** dist copy filters to `*.js` and `*_bg.wasm` (drops `.d.ts`, `package.json`, `.gitignore` from wasm-pack) and throws when `static/wasm` is missing, so a stale `dist` cannot hide a skipped build. `application/wasm` MIME added — required for `WebAssembly.instantiateStreaming`. `generate.mjs`/`sandbox.html` comment now states the swap rule ("crate output only") in place of "Do not change .rz-resume". README says `npm test` needs Rust + `wasm-pack` (CTO rule 9, arrived one PBI early).

**`renderer-wasm` `version()`.** Phase-1 Architect follow-up; three lines plus a test that pins it to `CARGO_PKG_VERSION`. In scope, accept.

Nits (no action): `render.js` `swapResume` does `doc.querySelector(ARTICLE).replaceWith(…)` without a null guard — the sandbox always has the article and a missing one would be a `TypeError` in the caller's promise, not an uncaught error, but a named error would read better; `renderedParts` is exported only for its test.

**BLESS ZG-4 phase-2 — render.js is the single owner of the Wasm module with a memoised, retryable load and plain-words failures; ports.js changed only by de-indent plus twenty lines of wiring; the Elm port shape is decoded once into a Result; the build fails fast in one line and no artifact is tracked.**

## Phase 2 — Tester

Skills: `rust-code-tester` (applied to JS), `code-writer`.

Ran: `npm run test:unit` 132/132 (build-wasm 4, render 5, zg-4 6, byte-parity 4, request-log 3, resume-size 4 are the new ones); `PROBE_PORT=4399 npm test` exit 0; `PROBE_PORT=4398 just verify` exit 0. Read the stub run and cargo-absent run in the evidence file.

**Every AC has a PASS line with numbers.** parity ×3 (18575 B / 499 B / 1086 B, "byte-equal"), error (the exact rejection text with `line 1`), load-failure (the exact plain message, "sandbox still Jordan Hale", "no pageerror"), large (4.80 MiB, 9942 jobs, 77 ms ≤ 5000 ms, `Job 9942 present`), swap (src, href, title), no-network (0 during, 14 initial). The build/artifact ACs are covered by the unit test through the process boundary (`PATH=""`) and by `git ls-files` = 0; the clippy/verify AC by `just verify`.

**Prerequisite-missing paths FAIL, not skip.** `crateRender` returns `null` on spawn error *or* non-zero exit, and the probe emits `FAIL  ZG-4/wasm-parity prerequisite missing: cargo example render` once per input — three FAIL lines in the evidence with cargo off PATH. `build-wasm` with `wasm-pack` absent exits 1 with the hint (unit test + evidence). `copy-dist` throws if `static/wasm` is absent. No path silently passes.

**Stub run.** A `render` returning `sandbox.html` fails all three parity cases (first diff at byte 153/195, sizes named), error, load-failure, large, and swap (`.rz-name is "Jordan Hale"`; title still Jordan) — the anti-stub AC holds with margin. `wasm-no-network` still passes under the stub, and that is right: it measures requests, not output.

**`wasm-no-network` methodology.** The probe renders `{}` first (loads the glue + `_bg.wasm`), marks the request count, then renders Ada + swaps and waits for `networkidle`; assertion is zero requests after the mark *and* zero foreign among them. Two consequences to state plainly: (a) the Wasm module's own two same-origin fetches are counted as "initial assets", which is the only sensible reading — the AC's "initial page assets" cannot exclude the renderer itself, and `foreignRequests` would still flag a CDN-hosted module; (b) the initial 14 include jsDelivr font requests from Themes, which this probe does not judge. That is correct scoping: the AC is about render + swap, and ZG-13 (fonts self-hosted) owns the initial-asset question. Acceptable. `foreignRequests` treats any `/api*` path on the origin and any other origin as foreign — unit-tested both ways.

**`at ` reading.** The AC puts "no stack trace (`at ` absent)" on `wasm-load-failure` only; `wasm-error`'s message legitimately contains `at line 1 column 1`. `stackReasons` is applied only in `loadFailureProbe`, with a comment saying why. Correct reading; the alternative (a `\n\s+at ` regex) would be more precise but the AC text says `at `, and the load-failure copy is checked against the literal at unit level too.

**Unit coverage of the new calculations.** `firstMismatch` (equal / mid-diff / prefix both directions), `parityReasons`, `foreignRequests`, `requestsSince`, `largeResume` (floor reached with the smallest count — the "one fewer job is under the floor" assertion is the good one; renaming; input untouched), `mebibytes`, `buildFailure` ×3 + process test, `plainMessage` ×2, `renderedParts` ×2, `rejectionReasons` ×3, `stackReasons` ×2, `swapReasons` ×4. Gaps: `plainMessage` for a non-string non-Error (e.g. `42`) is untested — one line, add when touched; `render`/`loadModule` are browser-only and are exercised by the probes (load failure, error, parity), which is the right level.

**Would a swap that only replaced `.rz-name` text be caught?** Not by `swapReasons` alone: the sandbox's two "Jordan Hale" occurrences are the `<title>` and `.rz-name`, so a stub that set both strings would satisfy `.rz-name`, `hasJordan`, and `title`. The probe relies on `render` (parity-proven) plus `renderedParts` throwing on a non-article. To close it, `swapProbe` should additionally compare the iframe's `article.rz-resume` `outerHTML` against the article parsed from the rendered HTML in the probe — one `page.evaluate`, no product change. Follow-up, not blocker: the AC lists exactly the four checks implemented, and the production `swapResume` cannot take the shortcut because it has no other input than the crate string.

**`wasm-large` timing** excludes module load (the `{}` warm-up). The AC's "resolves through `window.resumezen.render` in ≤ 5 s" is about the render; at 77 ms the margin is 65× and adding the ~50 ms load would not change the verdict. Fine, but the PASS line should say "warm" when the probe is next edited.

Determinism: each probe opens a fresh page; the aborted `_bg.wasm` route cannot leak; the crate oracle is produced in-run from the same checkout. `npm test` wall time is dominated by `wasm-pack` (≈1 s warm).

**BLESS ZG-4 phase-2 — every AC line is a PASS with its numbers, both prerequisite paths are FAILs, the stub run trips seven of eight probes, and every new pure calculation is unit-tested; strengthen the swap probe with an article-equality check and label the large timing as warm when next touched.**

## Phase 2 — Architect

Skills: `rust-architect`, `code-writer`. Judged against CTO execution rules 4, 6, 8, 9 and the ZG-4 set-level note (c).

**Rule 4 — ports.js is wiring.** Honoured. The render concern (module load, error translation, sandbox swap) lives in `render.js`; `ports.js` imports four names and adds one `subscribe`, one frame-await wrapper, and the `window.resumezen` literal. The file did not grow logic; a reader can find "where does the Wasm live" in one import. This is the second concern module after `page-estimate.js` and follows the same shape (pure calculations exported and unit-tested, actions at the bottom), so ZG-5 (file/storage) and ZG-8 (clipboard/history) have a template.

**Rule 6 — probes.mjs is a runner.** `zg-4.mjs` is one module per PBI with injected `{browser, origin, report, repoDir, frontendDir}`; helpers under `probes/lib/` are pure and shared (`request-log` will serve ZG-5/ZG-22's "nothing leaves the browser" claims). `probes.mjs` gained two lines.

**`window.resumezen` as the ZG-5/ZG-22 surface.** `{ render(json) → Promise<string>, swap(html) → Promise<void>, contractVersion() → Promise<string>, version() → Promise<string> }`. Four async functions, all thin. Stable enough: ZG-5 needs `render` + `swap`; the deploy-time skew probe needs the two versions. What it must not become is a namespace for Elm-adjacent state; the comment says "thin wrappers only" and the architect will hold the line there.

**Elm port contract.** `{ ok, html, error }` over a `Decode.Value`, folded to `Result String String` in one decoder, undecodable → `Err`. A tagged union (`{ tag: "ok" | "err", value }`) would be marginally more honest but Elm ports cannot carry a `Result` either way; the record is explicit, the decoder is the single translation point, and the JS side builds it with two named constructors. Good enough; do not churn it.

**One render path.** The Wasm module is the pure crate; the oracle is the pure crate; ZG-21's server render will be the pure crate. `render.js` contains no parsing, no template, no fallback markup. `renderedParts` refusing a non-article string means the sandbox can only ever host crate output — the Theme contract survives the sandbox becoming writable (note (c)).

**`npm test` needs Rust + wasm-pack.** Documented in README; `just verify` is the gate and already needed Rust. Given locks 6 and 8 (pure crate in the browser; deploy is a human step) there is no lighter honest option — a committed artifact would be the CTO's rejected shortcut. Accept.

**Nothing to undo later.** ZG-5 fills `rendered` and calls `swap`; ZG-21 links the same crate; ZG-8 adds its own module next to `render.js`; ZG-13 shrinks the "initial assets" count. The `version()` follow-up is closed. The remaining phase-1 follow-up (`Resume::from_json` → `RenderError`) is still open and still due before ZG-21.

**Two-year test.** A new engineer reads `index.html` → `ports.js` (wiring) → `render.js` (one screen) → `renderer-wasm/src/lib.rs` (one screen) → the pure crate, and at every hop there is exactly one thing to understand. Easier, not harder.

**BLESS ZG-4 phase-2 — the render concern is a single module with ports.js reduced to wiring, one crate behind one browser surface, and a probe layout that the rest of the round can copy; hold `window.resumezen` to thin wrappers and close the `from_json` error follow-up before ZG-21.**
