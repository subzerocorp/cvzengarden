# Decision: unlock the Rust / Elm / Axum stack; ResumeZen is OCaml (Melange) end to end

**Date:** 2026-09-12 · **Decided by:** Nathan Sculli (product owner), in the session that produced PR #31 · **Status:** accepted

## Context

`main` locked the stack as a Rust renderer (`resumezen_renderer::render`, also compiled to Wasm), an Elm chrome, and a Rust + Axum API on libSQL/Turso, with a Pinto board (`.pinto/`), AVRIL/AXEL planning artefacts, a Netlify static deploy, and a JavaScript probe suite encoding the BAR-* rules.

The product owner asked for a complete, greenfield rewrite on a different stack and, when asked explicitly, confirmed pruning the planning artefacts and Rust/Elm agent skills.

## Decision

1. **Language.** Every line of code is OCaml compiled by Melange. The repository contains no hand-written JavaScript; `just no-js` enforces it. JS interop is `external` bindings only; `[%mel.raw]` is forbidden.
2. **Renderer.** A shared Melange library (`shared/`) replaces the Rust crate and its Wasm build. It stays byte-locked against `skeleton/example.html` (body) and `skeleton/samples/junior.html`, and BAR-R1 is a unit test.
3. **Chrome.** SolidJS (hyperscript, no JSX) replaces Elm. The Organic design system replaces the GPUI Component look for pages; the drawer keeps the GPUI panel.
4. **API and store.** Hono on Bun replaces Axum; `@libsql/client` keeps libSQL locally and Turso in production.
5. **Deploy.** The Bun server ships as a container (`Dockerfile`); the Netlify static config is retired. Until the container is live, the Netlify preview remains the live garden (see BAR-X3 in `qa/MARKET-QUALITY-BAR.md`).
6. **Process.** Pinto, AVRIL and AXEL are retired; `progress.md` and `docs/decisions/` carry the record. The BAR-* probes are re-encoded in OCaml under `probes/` (`just probe`), and `qa/MARKET-QUALITY-BAR.md` remains the binding quality model.

## Consequences

- `AGENTS.md`, `README.md`, `CONTEXT.md` and `ROADMAP.md` describe the new stack; the previous lock is superseded by this record, not silently edited away.
- The class contract, JSON Resume as the only stored form, the pure-CSS Theme rule and the persona docs are unchanged.
