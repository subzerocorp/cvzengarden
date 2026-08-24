# AVRIL round 1 — Visionary CTO review (cycle 7)

**Role:** `visionary-cto-agent` (third and final adversary) · **Date:** 2026-08-24 · **Cycle:** 7 (one new harness item, after PO and QA cycle-7 BLESS)
**Scope:** ZG-23 only. The other 22 bodies were re-read for the whole-set view and the dependency graph; no verdict is emitted for them.
**Inputs read in full:** `docs/plans/round-1-avril-po-round7.md`, `docs/plans/round-1-avril-qa-round7.md`, `docs/plans/round-1-avril-generator-round7.md`, `docs/plans/round-1-avril-intent.md`, my own set-level notes in `round-1-avril-cto-round1.md` (execution rules 1–9, especially rule 6, and "what I will look for in cycle 2"), `pinto show ZG-23 --plain`, `pinto show ZG-1 --plain`, `frontend/scripts/probes.mjs` (1,126 lines; `s1Probes` 589–634, `browserProbes` 1090–1126, the top-of-file comment that still names RZ-3/RZ-S1…S5/U3 as the whole matrix), `frontend/static/ports.js`, `frontend/scripts/{serve,copy-dist}.mjs`, `justfile`. `frontend/scripts/probes/` does not exist yet.

Mandate: *BLESS only backlog items that advance a coherent two-year trajectory without irreversible entanglement; REJECT anything that buys short-term motion at the cost of future clarity.*

I ask only strategic questions. Product value is PO's and settled; AC falsifiability is QA's and settled. I do not rewrite bodies and I do not touch the board.

---

## ZG-23 — Make the S1 cold-load FOUC probe deterministic with a painted-frame oracle

### What is right, and I want it kept

**The oracle is the correct kind of oracle.** The old block asked the style engine a question ("what would `.rz-name` compute to right now?") and treated the answer as a fact about pixels. The new block asks the browser what it painted and when. That is a category change, not a tuning change, and it is the one that generalises: every future "no flash" claim on this product — the ZG-4 Wasm swap of the sandbox, the ZG-15 local-theme blob URL, the ZG-8 `view=` restore — will need the same instrument, "first contentful paint in the sandbox frame vs. arrival of the sheet it depends on". Buying that instrument now, on the smallest possible item, is complexity pulled forward exactly where it reduces option-value loss.

**No entanglement with the thing under test.** `scope_out` walls off `ports.js`, `generate.mjs`, the sandbox, chrome, and themes. That matters strategically: the sandbox is the seam between Elm chrome and the Skeleton (locked decision 5), and a "fix" that moved the theme link or added an `onload` dance to make a probe happy would have weakened the seam to satisfy the harness. The item refuses that. Its static lock (`cold-sheet-blocking`) also pins the property the whole product relies on — the theme sheet is render-blocking in `<head>` — as a stated invariant rather than folklore. That is architecture made clearer.

**Acyclic and teachable.** `Dependencies: none`; it is the unblocker for ZG-1's last box and therefore for every chain rooted at ZG-1. The conductor should add `ZG-1 → ZG-23` on the board so the ordering is visible (a `pinto dep add`, not a body edit). Nothing in the item asks the execution team to invent a second product, a second sandbox, or a second harness.

**No retry, no skip.** A retry loop would have been a "temporary" shortcut with no exit criteria — the precise thing my role exists to refuse. The item names it and rejects it.

### The trajectory blocker

My cycle-1 execution rule 6, which the Generator's own inputs list says it read, is:

> **`probes.mjs` becomes a runner.** It is 1,126 lines before this round adds roughly a hundred named probes and a dozen shared helpers. **The ACs pin the `PASS  ZG-n/<slug>` lines and the entry point, not the layout.** Layout: `frontend/scripts/probes/lib/*.mjs` for helpers, one module per PBI or per surface, `probes.mjs` imports and runs them in the order the bodies require.

ZG-23's last AC reads: "`git diff --name-only -- . ':!progress.md' ':!features.json'` lists **exactly** `frontend/scripts/probes.mjs`". That pins the layout, and pins it to the shape rule 6 says we are leaving. Concretely:

1. **It forbids the seam it should seed.** ZG-23 is, by construction, the first round-1 item to touch `probes.mjs` (everything else waits on ZG-1, which waits on this). It introduces the first paint-timing helper (`getEntriesByType('paint')` + resource-timing lookup for a sheet href inside a named frame) — a helper ZG-4, ZG-8, ZG-11, ZG-12, ZG-13, ZG-15 will want. Under the AC as written, that helper must be inlined into a 1,126-line file, and the executor is *prohibited* from creating `frontend/scripts/probes/lib/paint-timing.mjs`. I told the code GAN in cycle 1 to reject probe helpers landing inline ("that probe helpers land in `probes/lib/` rather than inline"). This AC would make the first item on the board a mandated violation of that instruction, and the second item would inherit a `probes.mjs` that is already the wrong shape with a blessed AC saying so.

2. **It sets the precedent that per-PBI ACs may pin `probes.mjs` layout.** Twenty-one items follow. If the harness item that unblocks them carries "exactly `probes.mjs`", the Generator will reasonably copy the guard into the next probe-bearing body, and rule 6 dies by precedent rather than by decision. A rule that the very first landing contradicts is not a rule.

3. **The guard's real purpose is achievable without pinning layout.** The AC's second half — `ports.js`, `generate.mjs`, `skeleton/`, `themes/`, `renderer/` untouched — is the strategically important part: it stops the executor from "fixing" the sandbox instead of the oracle and keeps ZG-1's `renderer/`-only scope true. That protection survives intact if the positive list is widened to the probe runner's directory.

This is not a nit about a file name. In two years the probe suite is the executable statement of every BAR we promise Authors and Designers; whether it is a runner over small modules or one 3,000-line file decides whether a persona complaint can be traced to one probe and one fixture, or to a scroll. The seam is cheap today (an `import` and a directory) and expensive after the hundred probes land.

**Minimal delta for the Generator** (one AC, no other change; `scope_in`'s "replace the cold-load block of `s1Probes`" is compatible, the block becomes the call):

- Last AC: replace "lists exactly `frontend/scripts/probes.mjs`" with "lists only `frontend/scripts/probes.mjs` and, if the executor extracts the paint-timing helper or the ZG-23 probe into modules, paths under `frontend/scripts/probes/`". Keep the untouched list verbatim.

Optional, and not required for BLESS: a `Guidance for AXEL` line in `notes` that the paint-timing reader (frame lookup + `paint`/`resource` entries for a given href) is expected to be reused by ZG-4/ZG-8/ZG-11–13/ZG-15 and so belongs in `probes/lib/`, with `s1Probes` importing it. The ACs already pin the observable lines; the layout stays the architect's call inside the widened guard.

### Everything else I checked

- **Two-year cost of `COLD_SHEET_DELAY_MS = 400` and the 200 ms settle:** two named constants at the top of a module, both explained by the `notes`. If a future host is slower they move once. No exit criteria needed; they are parameters, not shortcuts.
- **Vendor lock-in:** none. Paint Timing and Resource Timing are W3C, shipped in every engine we would ever run probes on; only Chromium is installed today (QA cycle 1), and the AC does not pretend otherwise.
- **Does it paint us into a corner for the Wasm sandbox (ZG-4)?** No — the oracle is keyed on the frame URL ending in `sandbox.html` and the `#theme-stylesheet` href; ZG-4 keeps both by its own AC. The static lock reads `dist/sandbox.html`, which ZG-4 continues to emit.
- **`just verify` needing both toolchains:** already true (rule 9); unchanged.

**REJECT ZG-23 — the diff-scope AC "lists exactly `frontend/scripts/probes.mjs`" pins the probe layout to the monolith that cycle-1 rule 6 retires, forbids the first paint-timing helper from landing in `probes/lib/`, and sets the precedent that per-PBI ACs may pin `probes.mjs` layout; widen the positive list to `frontend/scripts/probes.mjs` plus paths under `frontend/scripts/probes/` (keep the untouched list verbatim) and the item is ready for a fresh chain — oracle, guards, non-goals, and determinism AC are otherwise exactly the seam I want.**

---

## Blessing log (cycle 7)

- ZG-23: PO BLESS | QA BLESS | CTO REJECT (one-line delta on the diff-scope AC; re-run PO → QA → CTO after revise)
