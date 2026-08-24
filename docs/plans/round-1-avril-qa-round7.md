# AVRIL round 1 — QA Architect review (cycle 7)

**Role:** `qa-architect-agent` (second adversary) · **Date:** 2026-08-24 · **Cycle:** 7 (one new harness item, after PO cycle-7 BLESS)
**Scope:** ZG-23 only.
**Inputs read in full:** `docs/plans/round-1-avril-po-round7.md`, `docs/plans/round-1-avril-generator-round7.md` (oracle decision, spike table, rejected alternatives), `docs/plans/round-1-avril-intent.md`, my own set-level conventions in `round-1-avril-qa-round1.md` (probe naming, no `SKIPPED`, offline, `textContent`), `pinto show ZG-23 --plain`, `pinto show ZG-1 --plain`, `frontend/scripts/probes.mjs` (`fail`/`pass` at 28–35, static sandbox checks 215–238, `captureFrame` 340–370, `sampleDuring` 384–418, S1 swap + cold-load block 589–634, `browserProbes` and the exit path 1090–1126), `frontend/static/ports.js`, `frontend/generated/sandbox.html` head, `frontend/scripts/{serve,copy-dist}.mjs`, `frontend/package.json`, `justfile`, `.gitignore`.

Mandate: *BLESS only PBIs whose acceptance criteria are complete, falsifiable, and hostile to happy-path theater; otherwise REJECT with the missing cases.*

I judge testability only. I do not reopen product scope (PO, settled) or the runner layout (CTO, next).

## Facts I verified before judging

| Fact | How | Affects |
| --- | --- | --- |
| The current cold-load oracle is `captureFrame` → `getComputedStyle(.rz-name)` polled 36 × 20 ms after `goto(…, {waitUntil: "commit"})`; `isFoucSample` = blank canvas AND `isUaDefaultSerif(font)`. Nothing in it observes a paint. | read 340–370, 165–170, 620–634 | the defect is real and is what AC 1 retires |
| `grep -c "SKIP" frontend/scripts/probes.mjs` prints `0` today | ran it | AC 1's grep is a lock, not a cleanup |
| The strings `S1 cold load FOUC` / `S1 cold load never painted` exist only at 631 and 633 | grep | AC 1's "no line containing `S1 cold load`" is a real retire check |
| `npm test` = `npm run build && node scripts/probes.mjs`; `build` regenerates `dist/sandbox.html` from `frontend/generated/sandbox.html` via `copy-dist.mjs` | `package.json`, `copy-dist.mjs` | the anti-stub ACs must bypass the build — they do (`node frontend/scripts/probes.mjs`) |
| `frontend/dist` is gitignored (`.gitignore:9`); `frontend/generated/sandbox.html` is tracked | `git check-ignore -v`, `git ls-files` | the "`git checkout` restores the tree" clause (see below) |
| `probes.mjs` reads `dist/sandbox.html` for its static checks (215) and `serve.mjs` serves `dist/` | read | the static lock and the served page are the same file, so the two anti-stub ACs test the same edit |
| The sandbox iframe `src` is the constant `"sandbox.html"` (`Main.elm:447`), so the frame URL is `<origin>/sandbox.html` | grep | `page.frames().find(f => f.url().endsWith('sandbox.html'))` resolves to exactly one frame |
| Nightgarden sets `.rz-name` in `"Syne"`; `isUaDefaultSerif` returns `false` for any family containing `syne` | `themes/nightgarden.css:18`, `probes.mjs:146–163` | `cold-paint-present`'s post-load font check is satisfiable and meaningful |
| ZG-1's renderer commit 59f52ca is on `garden/persona-loop` | `git log` | AC 5's condition is already met on this tree |

## Is the oracle falsifiable and deterministic?

**Falsifiable.** `first-contentful-paint.startTime` is by specification the timestamp of the first frame that painted contentful pixels in that document. `responseEnd` on the theme sheet's resource-timing entry is when the sheet's bytes finished arriving. `FCP >= responseEnd` is therefore literally BAR-U1: "no contentful frame was painted before the theme could have applied". A skeptical tester does not need the source to falsify it; they need the two numbers, and the AC requires both to be printed on every PASS/FAIL line.

**Deterministic.** The old oracle raced 20 ms ticks against a sheet that arrives in ~5 ms from localhost. The new one holds the sheet for 400 ms, so the two outcomes are separated by ~400 ms (spike: 444/452 vs 32), not by scheduler jitter. The second clause, `FCP >= COLD_SHEET_DELAY_MS`, is not redundant with the first: if `page.route` ever failed to install (or matched nothing because the href changed shape), `responseEnd` would be ~5 ms, FCP ~30 ms, and clause one alone would pass a broken harness. Clause two turns "the hold did not happen" into a FAIL. Good — that is the kind of self-check a probe of a probe needs.

**What I probed for and did not find.** (a) *Pass by absence*: covered — `cold-paint-present` fails when either paint entry is missing; the `notes` line forbids falling back to computed style. If the resource-timing entry for the sheet is missing, `responseEnd` is `undefined`, `FCP >= undefined` is `false`, and `cold-paint-order` fails — the AC's printed numbers will show `undefined`, which is the honest readout. (b) *Wrong document*: a stub that read `performance` on the chrome page instead of the sandbox frame would see the chrome's own FCP (unblocked by any theme sheet, ~30 ms) and fail clause two. It cannot silently pass. (c) *Hold leaking into later probes*: `page.route` is installed on the fresh `cold` page, which is closed; the `unroute` line in `scope_in` is belt-and-braces, harmless. (d) *Settle timing*: paint entries are queued asynchronously; a 200 ms settle after the sandbox frame's `readyState === 'complete'` is generous relative to the sub-10 ms gap between `complete` and the first paint on a static document, and the failure mode if it were ever too short is a loud `cold-paint-present` FAIL, not a pass. The N = 10 AC is what proves this empirically; it is the right AC to carry the claim.

## Does the anti-stub AC actually fail on a non-render-blocking theme link?

I ran the AC examples against the three rules by hand, using the spike numbers the `notes` record.

| Sandbox under test | `cold-paint-order`: FCP ≥ responseEnd AND ≥ 400 | `cold-paint-present`: both paint entries; sheet has rules; `.rz-name` not UA serif after load | `cold-sheet-blocking`: single `#theme-stylesheet` before `<body`, `rel=stylesheet`, no `media`/`disabled`/`onload` | Net |
| --- | --- | --- | --- | --- |
| Real (`link` in `<head>`) | 444 ≥ 413 and 444 ≥ 400 → PASS | entries present; Nightgarden rules loaded; `"Syne"` → PASS | link at line 11, before `<body>` at line 13, bare `rel="stylesheet"` → PASS | exits 0 |
| `link` moved to just before `</body>` | 32 ≥ ~410 is false → **FAIL** (numbers printed: 32 / ~410) | after load everything is styled → PASS (correct: this guard is not the one meant to catch it) | link appears after `<body` → **FAIL** | exits 1, two FAIL lines as AC 2 and AC 3 require |
| `link` in `<head>` with `media="print" onload="this.media='all'"` | the sheet is not render-blocking under `media="print"`, so the first paint is at ~32 ms; 32 ≥ ~411 false → **FAIL** | after `onload` the media flips to `all`, rules load, name is styled → PASS | carries `media` and `onload` → **FAIL** | exits 1, two FAIL lines |

Both stubs are caught twice, by independent mechanisms (one observed, one static), which is exactly the redundancy the AC claims ("so a stub is caught even if paint timing is unavailable"). A stub in the *probe* — say, an implementation that hard-codes `PASS  ZG-23/cold-paint-order` — is also caught, because AC 2 demands the FAIL lines with real numbers on the edited sandbox.

Two further negative cases I checked the rules against, beyond the AC's two: a `disabled` attribute on the link (static FAIL by the attribute list; behavioural FAIL because nothing render-blocks) and a second `<link rel="stylesheet">` inserted before the theme link (static: "the single `id="theme-stylesheet"`" is satisfied, but the theme link is still before `<body` → PASS; behavioural: the extra sheet is also render-blocking, FCP is still after the theme sheet → PASS). The second case passing is correct — an extra blocking sheet is not a FOUC — so the rules are not over-tight.

## Is the determinism AC real?

`for p in $(seq 4320 4329); do PROBE_PORT=$p just test-frontend || exit 1; done; echo ALL-GREEN`. Ten runs, ten distinct ports (so no run can be served a stale listener from the previous one), `just test-frontend` is `cd frontend && PROBE_PORT=… npm test` which rebuilds and runs the full probe file each time, `|| exit 1` stops at the first red, and "first attempt, zero reruns" is stated. Evidence is the ten `PASS  ZG-23/cold-paint-order` lines with numbers, every FCP ≥ 400. A tester can falsify this by running the loop once; a single red anywhere in ten runs sinks the checkbox. This is the strongest determinism AC on the board and it is not aspirational.

## Conventions

- Lines are `PASS  ZG-23/<slug>` / `FAIL  ZG-23/<slug> <reason>`; the reason carries the numbers. Matches the set convention.
- No `SKIP`: grep-asserted at `0`, and `scope_out` forbids retry/re-run/skip. A missing paint entry is a FAIL line, not a skip.
- Offline: only the local `serve.mjs` origin is touched; the route hold is local.
- `textContent` where text is read (`captureFrame` already does; the new block reads no chrome text).
- Atomic checkboxes: six ACs, one behaviour each; none dictates layout beyond the diff-scope guard (CTO's domain).
- Test order: none of the six depends on another PBI; AC 5 depends on ZG-1's commit, which is already on the tree.

## One correction for execution (not a blocker)

AC 2 ends "`git checkout` restores the tree afterwards". `frontend/dist/` is gitignored, so `git checkout` will not touch the edited `dist/sandbox.html`; the honest restore is `cd frontend && npm run build` (or `node scripts/copy-dist.mjs`). This does not affect falsifiability — the evidence is the FAIL lines, and the very next AC (`just test-frontend`) rebuilds `dist/` before it runs, so a stubbed `dist/` cannot leak into AC 4 — but the executor should read the restore step as "rebuild", not "checkout". I record it here so AXEL's tester does not mark the step done on a no-op. It is a one-word clarification and does not rise to a material change of the body.

**BLESS ZG-23 — the paint-order oracle asserts BAR-U1 in the browser's own terms (first painted contentful frame vs. sheet arrival) with both numbers printed, the 400 ms hold plus the `≥ 400` clause make the verdict a gap rather than a race and catch a missing hold, both anti-stub sandboxes fail twice over by hand-run rules, the N = 10 distinct-port first-attempt loop is a real determinism test, and nothing can pass by silence or skip.**

---

## Blessing log (cycle 7)

- ZG-23: PO BLESS | QA BLESS
