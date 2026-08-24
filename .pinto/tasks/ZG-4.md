+++
id = "ZG-4"
title = "Run the Renderer in the browser via Wasm and prove it matches the crate"
status = "todo"
rank = "l"
labels = ["avril", "round-1", "renderer", "chrome"]
depends_on = ["ZG-1"]
created = "2026-08-23T23:53:41.440185Z"
updated = "2026-08-23T23:59:42.156957Z"
+++

## Why
An Author's paste (ZG-5) must render instantly, offline, with nothing leaving the browser and no backend running — the locked stack says the pure crate may run in the browser (lock 6); this slice makes that true and provable (Priya, Elena, Marcus).
## Covers
enables A1 (no complaint id of its own; render-side decision from the intent)
## Scope in
- New crate `renderer-wasm/` (depends on `resumezen-renderer`; `wasm-bindgen`) exporting `render_json(json: &str) -> Result<String, String>`; the pure crate stays free of wasm deps
- `frontend/package.json` build step runs `wasm-pack build --target web` into `frontend/static/wasm/` (gitignored); `npm run build` fails fast with a one-line install hint when `wasm-pack` is absent
- `frontend/static/ports.js` exposes `window.resumezen.render(json)` (async) backed by the module; an Elm port `renderResume : String -> Cmd msg` and `onRendered : (Result String String)`-shaped subscription
- Sandbox swap action: replace the `article.rz-resume` in `sandbox.html` with the rendered article and update the iframe `<title>`; the Theme `<link id="theme-stylesheet">` is untouched
- `justfile` gains `wasm` target and `clippy` covers `renderer-wasm`
## Scope out
- Any paste UI, error copy, or storage (ZG-5)
- Server-side render endpoint (`/api/render`) — hosted pages render on the server in ZG-21 with the same crate; no duplicate path
- Committing built `.wasm`/glue artifacts
- Streaming/large-file optimisation
## Acceptance criteria
- [ ] `cd frontend && npm run build` produces `dist/wasm/resumezen_renderer_wasm.js` and `dist/wasm/*_bg.wasm`; `git status` shows neither as tracked
- [ ] With `wasm-pack` removed from `PATH`, `npm run build` exits non-zero and prints `wasm-pack` and an install URL
- [ ] Probe `ZG-4/wasm-byte-lock` in `frontend/scripts/probes.mjs`: in the served Garden, `await window.resumezen.render(fs.readFileSync('skeleton/resume.json'))` returns HTML whose `<article class="rz-resume"…>…</article>` bytes equal that node in `skeleton/example.html`
- [ ] Probe `ZG-4/wasm-error`: `window.resumezen.render('{')` rejects/returns `Err` whose message contains `line 1` and does not throw an uncaught exception
- [ ] Probe `ZG-4/wasm-swap`: calling the swap with a rendered `{"basics":{"name":"Ada"}}` leaves the iframe `src` = `sandbox.html`, `#theme-stylesheet` href unchanged, `.rz-name` = `Ada`, and the iframe document contains no `Jordan Hale`
- [ ] Probe `ZG-4/wasm-no-network`: during render + swap the Playwright request log records zero requests other than the initial page assets (no `fetch` to any `/api` or third-party host)
- [ ] `cd renderer-wasm && cargo clippy --all-targets -- -D warnings -D clippy::pedantic` exits 0; `just verify` green
- [ ] A stub `window.resumezen.render` that returns `sandbox.html`'s existing markup fails the Ada swap probe
## Dependencies
- ZG-1
## Notes
- `wasm-bindgen` / `wasm-pack` are pre-approved by the intent. Netlify's build image lacks Rust; production deploy needs either a Rust build step or a CI artifact — deployment is a human step and out of AC, but AXEL must not commit artifacts.
