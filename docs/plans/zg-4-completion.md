# PBI Completion — ZG-4
## Title
Run the Renderer in the browser via Wasm and prove it matches the crate
## Phases
- phase-1: BLESS ×3 — `81739dd` (renderer-wasm, RenderError, oracle)
- phase-2: BLESS ×3 — `08b8a17` (render.js bridge, swap, probes)
## AC Evidence
On the PBI (`pinto show ZG-4`).
## Verification matrix
- fmt / clippy pedantic (both crates) / cargo test / node:test 132 / probes 98: PASS
## Board
- status: done
## Follow-ups / non-goals honored
- swap probe: compare full article outerHTML; wasm-large 'warm' label; plainMessage non-Error case; swapResume null guard; fold Resume::from_json error into RenderError before ZG-21; ZG-13 makes initial assets same-origin. No server render path, no artifacts committed.
