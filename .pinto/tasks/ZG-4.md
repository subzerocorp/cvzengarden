+++
id = "ZG-4"
title = "Run the Renderer in the browser via Wasm and prove it matches the crate"
status = "todo"
rank = "l"
labels = ["avril", "round-1", "renderer", "chrome", "avril-blessed"]
depends_on = ["ZG-1"]
created = "2026-08-23T23:53:41.440185Z"
updated = "2026-08-24T01:13:24.280432Z"
+++

## Why
An Author's paste (ZG-5) must render instantly, offline, with nothing leaving the browser and no backend running — the locked stack says the pure crate may run in the browser (lock 6); this slice makes that true and provable (Priya, Elena, Marcus).
## Covers
enables A1 (no complaint id of its own; render-side decision from the intent)
## Scope in
- New crate `renderer-wasm/` (depends on `resumezen-renderer`; `wasm-bindgen`) exporting `render_json(json: &str) -> Result<String, String>`; the pure crate stays free of wasm deps
- Crate reference oracle (owner: this PBI) `renderer/examples/render.rs`: reads one JSON Resume on stdin, writes `resumezen_renderer::render_json` output to stdout unchanged and exits 0; on `Err` writes the error `Display` to stderr and exits 1 (`cargo run -q --example render < file.json`)
- Shared fixture (owner: this PBI) `frontend/fixtures/ada.json` with the content `{"basics":{"name":"Ada Lovelace"}}` — reused by ZG-5 and ZG-22 (parsed, never byte-compared)
- `frontend/package.json` build step runs `wasm-pack build --target web` into `frontend/static/wasm/` (gitignored); `npm run build` fails fast with a one-line install hint when `wasm-pack` is absent
- `frontend/static/ports.js` exposes `window.resumezen.render(json)` (async) backed by the module; when the module fails to load, `render` rejects with a plain-words message (never an uncaught exception — this is the surface ZG-5 displays); an Elm port `renderResume : String -> Cmd msg` and `onRendered : (Result String String)`-shaped subscription
- Sandbox swap action: replace the `article.rz-resume` in `sandbox.html` with the rendered article and update the iframe `<title>`; the Theme `<link id="theme-stylesheet">` is untouched
- `justfile` gains `wasm` target and `clippy` covers `renderer-wasm`
## Scope out
- Any paste UI, error copy, or storage (ZG-5)
- Server-side render endpoint (`/api/render`) — hosted pages render on the server in ZG-21 with the same crate; no duplicate path
- Committing built `.wasm`/glue artifacts
- Streaming/large-file optimisation beyond the 5 s bound below
- Comparing against `skeleton/example.html` — it is hand-maintained and not byte-identical to crate output (verified: first diff at byte 311); it is not a parity oracle
## Acceptance criteria
- [ ] `cd frontend && npm run build` produces `dist/wasm/resumezen_renderer_wasm.js` and `dist/wasm/*_bg.wasm`; `git status` shows neither as tracked
- [ ] With `wasm-pack` removed from `PATH`, `npm run build` exits non-zero and prints `wasm-pack` and an install URL
- [ ] `cd renderer && cargo run -q --example render < ../skeleton/resume.json` exits 0; a cargo test `example_render_matches_render_json` (in `renderer/tests/`) runs the example binary on `skeleton/resume.json` and asserts its stdout is byte-identical to `render_json` of the same input; `printf '{' | cargo run -q --example render` exits 1 with `line 1` on stderr and nothing on stdout
- [ ] Probe `ZG-4/wasm-parity` in `frontend/scripts/probes.mjs`: for each input — `skeleton/resume.json`, `frontend/fixtures/ada.json`, and the inline document `{"basics":{"name":"T"},"publications":[{"name":"Talk","releaseDate":"2023-05-31T09:00:00Z"}]}` — the probe spawns `cargo run -q --example render` (crate output produced in the same run) and asserts `await window.resumezen.render(input)` in the served Garden returns a string byte-equal to that stdout; if the example cannot run the line is `FAIL  ZG-4/wasm-parity prerequisite missing: cargo example render` (never a skip)
- [ ] Probe `ZG-4/wasm-error`: `window.resumezen.render('{')` rejects (or returns `Err`) with a message containing `line 1`; `page.on('pageerror')` records nothing
- [ ] Probe `ZG-4/wasm-load-failure`: in a fresh page with `**/*_bg.wasm` aborted via `page.route`, `window.resumezen.render(ada)` rejects with a message containing the word `renderer` and no stack trace (`at ` absent), `page.on('pageerror')` records nothing, and the sandbox still shows `Jordan Hale`
- [ ] Probe `ZG-4/wasm-large`: a document built in the probe from `skeleton/resume.json` by repeating its `work` entries (renamed `Job 1 … Job N`) until the JSON text is ≥ 4.8 MB (Devon's 2 000-job size) resolves through `window.resumezen.render` in ≤ 5 s, the output contains the last entry's name, and no `pageerror` is recorded
- [ ] Probe `ZG-4/wasm-swap`: calling the swap with the rendered `frontend/fixtures/ada.json` leaves the iframe `src` = `sandbox.html`, `#theme-stylesheet` href unchanged, `.rz-name` = `Ada Lovelace`, and the iframe document contains no `Jordan Hale`
- [ ] Probe `ZG-4/wasm-no-network`: during render + swap the Playwright request log records zero requests other than the initial page assets (no `fetch` to any `/api` or third-party host)
- [ ] `cd renderer-wasm && cargo clippy --all-targets -- -D warnings -D clippy::pedantic` exits 0; `just verify` green
- [ ] A stub `window.resumezen.render` that returns `sandbox.html`'s existing markup fails the Ada swap probe and all three parity cases
## Dependencies
- ZG-1
## Notes
- `wasm-bindgen` / `wasm-pack` are pre-approved by the intent. Netlify's build image lacks Rust; production deploy needs either a Rust build step or a CI artifact — deployment is a human step and out of AC, but AXEL must not commit artifacts.
