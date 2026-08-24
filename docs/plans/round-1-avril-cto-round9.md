# AVRIL round 1 — Visionary CTO review (cycle 9)

**Role:** `visionary-cto-agent` (third and final adversary) · **Date:** 2026-08-24 · **Cycle:** 9 (ZG-23 revised after my cycle-7 REJECT; after PO and QA cycle-9 BLESS)
**Scope:** ZG-23 only; the other 22 bodies and the dependency graph were re-read for the whole-set view, no verdict for them.
**Inputs read in full:** `docs/plans/round-1-avril-po-round9.md`, `docs/plans/round-1-avril-qa-round9.md`, `docs/plans/round-1-avril-generator-round9.md`, my own `round-1-avril-cto-round7.md` and the cycle-1 execution rules (rule 6 in particular), `pinto show ZG-23 --plain`, `pinto show ZG-1 --plain`, `frontend/scripts/probes.mjs`.

Mandate: *BLESS only backlog items that advance a coherent two-year trajectory without irreversible entanglement; REJECT anything that buys short-term motion at the cost of future clarity.*

I ask strategic questions only. Product value is PO's and settled twice; falsifiability is QA's and settled twice.

## Was my delta applied, and only my delta?

Yes. The diff-scope AC now reads "lists only `frontend/scripts/probes.mjs` and, if the executor extracts the paint-timing helper or the ZG-23 probe into modules, paths under `frontend/scripts/probes/`", and the untouched list — `ports.js`, `generate.mjs`, `skeleton/`, `themes/`, `renderer/` — is verbatim. That is the minimal delta I asked for, word for word in its effect. The Generator declined my optional `Guidance for AXEL` note; correct call. The rule that helpers land in `probes/lib/` is already an execution-GAN instruction from cycle 1, and repeating layout advice inside a PBI body is the same category of mistake as pinning layout inside a PBI body, just with the opposite sign. The AC pins observables; the widened guard leaves the shape to the architect at execution time. That is the seam.

The second edit (restore via `npm run build`) is QA's and is not strategic, but I checked that it does not entangle anything: it names the build the whole harness already runs and adds no new tool.

## The three blockers from cycle 7, re-tested

1. **Forbids the seam it should seed** — resolved. The first paint-timing reader (frame lookup + `paint`/`resource` entries for a given href), which ZG-4, ZG-8, ZG-11–13 and ZG-15 will all want, can now land as a module under `probes/` on the first item that touches the runner, with `s1Probes` importing it. Nothing in the body forbids it, nothing mandates it.
2. **Precedent that per-PBI ACs may pin `probes.mjs` layout** — resolved. The AC now has the shape I want the next twenty-one probe-bearing bodies to copy: a positive set that names the runner's directory, plus a negative list that protects the product seams. If the Generator copies this guard forward, rule 6 survives by precedent instead of dying by it.
3. **The guard's real purpose** — intact. The executor still cannot "fix" the sandbox, `ports.js`, `generate.mjs`, the themes, or the renderer to make a probe happy, so the Elm-chrome / Skeleton seam (locked decision 5) and ZG-1's `renderer/`-only diff scope are both protected exactly as before.

## Everything else, re-checked

- **Oracle category** unchanged: asks the browser what it painted and when, not what a style engine would compute; the instrument every future "no flash" claim on this product will reuse.
- **Entanglement with the Wasm sandbox (ZG-4)**: none; keyed on the frame URL ending `sandbox.html` and the `#theme-stylesheet` href, both preserved by ZG-4's own AC.
- **"Temporary" shortcuts**: none. No retry, no skip, two named constants explained in `notes`.
- **Acyclic and teachable**: `Dependencies: none`; it is the root unblocker for every chain rooted at ZG-1. The board still shows `Depended by: -` on ZG-23. I repeat my cycle-7 request to the conductor: add `ZG-1 → ZG-23` with `pinto dep add` so the ordering is visible. That is a board relation, not a body edit, and it is not a condition of this blessing.
- **Two-year cost**: the probe suite stays on the path to a runner over small modules rather than one 3,000-line file; a persona complaint remains traceable to one probe and one fixture.

**BLESS ZG-23 — the diff-scope AC now names the runner's directory as a closed positive set while keeping the sandbox, ports, generator, themes, and renderer walled off verbatim, so the first paint-timing helper can seed `probes/` instead of being forced inline, the per-PBI guard sets the precedent rule 6 needs rather than the one that kills it, and the painted-frame oracle remains the instrument every later no-flash claim will reuse.**

---

## Blessing log (cycle 9)

- ZG-23: PO BLESS | QA BLESS | CTO BLESS
