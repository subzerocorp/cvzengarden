# AVRIL round 1 — Generator pass (cycle 7, one new harness PBI)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-23 · **Board:** Pinto `ZG` (labels `avril`, `round-1`, `harness`)
**Created:** **ZG-23** — "Make the S1 cold-load FOUC probe deterministic with a painted-frame oracle" (`pinto add`, deps none). No other item was edited; ZG-1's body is untouched. Nothing is BLESSed by this document.
**Inputs read in full:** `frontend/scripts/probes.mjs` (S1 swap probe 589–617, cold-load block 620–632, `captureFrame` 340–360, `isUaDefaultSerif` / `isFoucSample` 146–170, static S1 stub check 226–238, `waitThemeReady` 699–708), `frontend/static/ports.js` (dual-link swap, `whenStylesheetReady`), `frontend/scripts/generate.mjs::writeSandbox`, `frontend/dist/sandbox.html` head, `frontend/static/index.html`, `frontend/src/Main.elm` (iframe `src="sandbox.html"` constant), `themes/nightgarden.css` (`html`/`body` background `#070b14`), `justfile` (`verify: fmt clippy test`, `test-frontend` on `PROBE_PORT`), `pinto show ZG-1 --plain`, set-level conventions in `docs/plans/round-1-avril-qa-round1.md` and `docs/plans/round-1-avril-generator-round3.md`.

## Why the current probe flakes (root cause, not symptom)

The cold-load block opens a fresh page with `waitUntil: "commit"` and takes 36 samples of `getComputedStyle(.rz-name)` inside the sandbox iframe. The sandbox's `#theme-stylesheet` sits in `<head>`, so the document is *render-blocked* until the sheet arrives — but a forced style query in a render-blocked document is resolved ignoring pending stylesheets. The sampler therefore can observe "UA-default serif on a blank canvas" for a state Chromium never painted. Whether it does depends on where the 20 ms ticks fall relative to sheet arrival, which is why identical trees give 60/60, then 3/3 failures, then 2/3. It is a computed-style race, not a flash.

## Oracle decision: paint-timing order inside the sandbox frame

Chosen oracle (`ZG-23/cold-paint-order`): on a fresh page, hold `**/themes/*.css` for 400 ms via `page.route`, then read in the sandbox frame `performance.getEntriesByType('paint')` and the theme sheet's resource-timing entry. Pass iff `first-contentful-paint.startTime >= responseEnd` of the theme sheet and `>= 400`. Two guards ride with it: `cold-paint-present` (the paint entries must exist, the sheet has rules, `.rz-name` is not UA serif after load — absence is FAIL, never PASS-by-silence) and `cold-sheet-blocking` (static lock: one `#theme-stylesheet` before `<body`, `rel="stylesheet"`, no `media`/`disabled`/`onload`), so a stub is caught even if paint timing were ever unavailable.

**Why this is honest and falsifiable.** FCP is by definition the first *painted* contentful frame, so the assertion is exactly BAR-U1's claim: no content was painted before the theme applied. Verified 2026-08-23 with a throwaway Playwright run (`/tmp/persona-lab/cold-fouc-oracle.mjs`, not in the repo) against `dist/` on a free port, sheet held 400 ms, two runs each:

| Sandbox | FP / FCP | theme sheet `responseEnd` | Verdict |
| --- | --- | --- | --- |
| real (`link` in `<head>`) | 444 ms / 452 ms | 413 / 412 ms | PASS |
| `link` moved to end of `<body>` | 32 ms | ~410 ms | FAIL |
| `media="print" onload="this.media='all'"` in `<head>` | 32 ms | ~411 ms | FAIL |

Paint entries are reported inside the same-origin iframe in headless Chromium (`poErr` empty), and the ~400 ms separation between the two outcomes is what makes the verdict independent of machine load (2–4 during the flake), while a genuinely non-render-blocking sandbox still paints at ~30 ms and fails. The 400 ms hold is the determinism knob: it converts a race into a gap.

**Rejected alternatives.** (a) Sampling only after `#theme-stylesheet` exists — still computed style, still ignores pending sheets, same race. (b) `link.sheet`/`cssRules` transitions — observes loading, not painting. (c) In-iframe `requestAnimationFrame` gating — the spike's rAF trace was empty/unreliable in the render-blocked window, so I did not build a gate on it. (d) Screenshots / pixel checks — no PNG decoder in the toolchain and the ZG-12 canvas trick cannot draw a cross-document iframe. (e) Retries — explicitly forbidden by the intent; a retry that swallows a real FOUC is worse than a red gate.

## AC shape (per set conventions)

- Lines `PASS  ZG-23/<slug>` / `FAIL  ZG-23/<slug> <reason>`; no `SKIP` anywhere in `probes.mjs` (grep-asserted); offline (only the local server is touched); `textContent` where text is read.
- Anti-stub AC is behavioural (two edited sandboxes → `FAIL  ZG-23/cold-paint-order` with printed numbers) and static (same two → `FAIL  ZG-23/cold-sheet-blocking`).
- Determinism AC: N = 10, `for p in $(seq 4320 4329); do PROBE_PORT=$p just test-frontend || exit 1; done; echo ALL-GREEN`, first attempt, zero reruns, all ten FCP values ≥ 400 listed as evidence.
- `PROBE_PORT=4330 just verify` exits 0 once ZG-1's renderer fix is on the same tree.
- Diff scope: exactly `frontend/scripts/probes.mjs` (plus the DoD tracking files). This does not contradict ZG-1's last AC ("only paths under `renderer/`"): that AC governs ZG-1's own diff; ZG-23 lands as its own commit(s) referencing ZG-23.

## Board effects

- New: ZG-23 (todo, rank #22, deps none). It is the unblocking item for ZG-1's `just verify exits 0` AC; I did not add `ZG-1 → ZG-23` as a Pinto dependency because ZG-1 is in-progress and its body was not to be edited — the conductor may add it with `pinto dep add` if the board should show the ordering.
- Unchanged: every other ZG id, all labels, all dependencies.
