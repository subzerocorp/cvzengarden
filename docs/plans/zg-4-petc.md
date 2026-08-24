# ZG-4 PETC — Run the Renderer in the browser via Wasm and prove it matches the crate

**PBI:** ZG-4 (triple-blessed) · deps ZG-1 done
**AXEL:** Generator `code-writer` + `rust-code-writer` (+ `rust-frontend` for the Wasm crate); adversaries `rust-code-reviewer` → `rust-code-tester` → `rust-architect` (JS legs judged by the same voices)
**Decomposition mode:** off

## Goal
`window.resumezen.render(json)` in the Garden returns byte-identical output to `cargo run --example render`, fails in plain words when the module can't load, handles 4.8 MB in ≤ 5 s, and can swap the sandbox article without touching the Theme link or leaving the browser.

## Approach
Phase 1 (Rust): `renderer-wasm/` crate (`wasm-bindgen` only; pure crate untouched except `rust-version = "1.87"` pin); `renderer/examples/render.rs` stdin→stdout oracle; `renderer/tests/example.rs::example_render_matches_render_json` + the `{` → exit 1 / `line 1` case; `justfile` `wasm` target + clippy over `renderer-wasm`. Phase 2 (JS/Elm): `npm run build` runs `wasm-pack build --target web` into `frontend/static/wasm/` (gitignored) with a fail-fast install hint; `ports.js` exposes `window.resumezen.render` (async, plain-words rejection on load failure) + Elm ports `renderResume`/`onRendered`; sandbox swap action; `frontend/fixtures/ada.json`; probes `ZG-4/wasm-{parity,error,load-failure,large,swap,no-network}` in `frontend/scripts/probes/zg-4.mjs`.

## Files likely
`renderer-wasm/{Cargo.toml,src/lib.rs}`, `renderer/{Cargo.toml,examples/render.rs,tests/example.rs}`, `justfile`, `.gitignore`, `frontend/{package.json,static/ports.js,src/Main.elm,scripts/build-wasm.mjs,scripts/copy-dist.mjs,scripts/probes.mjs,scripts/probes/zg-4.mjs,fixtures/ada.json}`.

## Test strategy
Per AC; parity via same-run crate stdout; anti-stub AC (a stub render fails swap + parity).

## Risk
wasm-pack build time in `just verify`; Netlify cannot build Rust (deploy is human — noted, not AC).

## Phases
1. **Phase 1 of 2** — Rust side + oracle.
2. **Phase 2 of 2** — JS/Elm bridge, swap, probes.

## Unresolved questions
- none
