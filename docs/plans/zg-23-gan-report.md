# ZG-23 GAN report

## Phase 1 — Reviewer

Mandate: write layered, modular code built from pure calculations on immutable data; isolate actions at the edges; prefer std; use composition so any human can understand and safely modify the system.

Diff reviewed: `frontend/scripts/probes.mjs` (M), `frontend/scripts/probes/lib/paint.mjs` (new), `frontend/scripts/probes/lib/sheet-blocking.mjs` (new). Self-verified: `PROBE_PORT=4335 node scripts/probes.mjs` green with the three `ZG-23/*` PASS lines and no `S1 cold load` line; `grep -c SKIP` = 0; `git diff` touches `isFoucSample`/`captureFrame`/`sampleDuring` only at the two removed cold-load call sites — the definitions and the swap-FOUC block are byte-identical to HEAD.

Checklist:
- Data/Calculation/Action separation: `readSandboxPaintTiming` is the single action in `paint.mjs` and returns a plain record; `paintStart`, `paintOrderReasons`, `describePaintOrder`, `paintPresenceReasons`, `sheetBlockingReasons` are pure (string/record in, reason list out). `isUaDefaultSerif` is injected, so `paint.mjs` owns no font heuristic. Correct.
- Oracle vs PBI: `paintOrderReasons` fails when FCP is missing, when the sheet resource entry is missing, when `fcp < responseEnd`, and when `fcp < 400` — both numbers printed in FAIL and PASS lines. `paintPresenceReasons` requires exactly `first-paint` + `first-contentful-paint` (missing or extra both FAIL — absence can never pass), `cssRules.length > 0`, `.rz-name` not UA serif. `sheetBlockingReasons` requires exactly one `id="theme-stylesheet"` link, before `<body`, `rel="stylesheet"`, no `media`/`disabled`/`onload` (attribute regex is whitespace-anchored so `href` text cannot false-match). Matches the PBI clause by clause.
- Runner: `coldLoadPaintTiming` is a fresh page, `waitUntil: 'commit'`, waits for the sandbox frame's `readyState === 'complete'` + `COLD_SETTLE_MS`, reads inside `page.frames().find(url endsWith sandbox.html)`, `unroute`s before `close`. Old `S1 cold load` strings retired; no retry, no SKIP.
- Nesting ≤ 2 everywhere; every function < 15 lines; names intention-revealing (`holdThemeSheets`, `waitForSandboxComplete`, `sandboxFrame`, `reportColdPaint`). No dead code; all exports are used by the runner (`PAINT_ENTRY_NAMES` internal-but-exported is acceptable for future tests). Std only, no new dependency.

Nits (not blocking, recorded as follow-ups):
- `coldLoadPaintTiming` has no `try/finally`; a timeout in `waitForSandboxComplete` leaves the cold page open. Consistent with the pre-existing style in this runner (the removed code had the same shape), and the whole run aborts on throw anyway.
- `describePaintOrder` assumes FCP non-null; safe only because it is called after `paintOrderReasons` returned empty. A one-line guard would make it total.

BLESS ZG-23 phase-1 — oracle logic matches the PBI clause by clause, calcs and actions are cleanly separated, helpers byte-identical, no SKIP, no retry.

## Phase 1 — Tester

Mandate: ensure every calculation and public item has complete, deterministic tests with exhaustive error-path coverage; no weakened oracle.

Unit-testability: `paintStart`, `paintOrderReasons`, `paintPresenceReasons`, `describePaintOrder`, `sheetBlockingReasons` take plain data (record / HTML string / injected predicate) and return arrays — trivially testable with `node:test`, no browser needed. Unit tests present: none. The frontend package has no unit-test runner (`npm test` = build + probes).

AC coverage in the Generator evidence (`/tmp/persona-lab/conductor/zg-23-evidence.md`): AC1 (three PASS lines, no `S1 cold load`, SKIP=0) — covered. AC2 anti-stub behavioural, both edits, with FCP/responseEnd numbers (44 < 418; 24 < 421) — covered. AC3 anti-stub static, both edits FAIL `cold-sheet-blocking` with distinct reasons — covered. AC4 N=10 with ten FCP values 440–456 all ≥ 400, ten distinct ports, first clean attempt; EADDRINUSE disclosure was a port held by an orphan server, not an oracle failure — covered. AC5 `just verify` exit 0 on 4330 — covered. AC6 diff scope — covered.

Reproduced anti-stub (a) myself on port 4336 (link moved to just before `</body>`):
```
FAIL  ZG-23/cold-sheet-blocking #theme-stylesheet link is not before <body>
FAIL  ZG-23/cold-paint-order fcp 40ms < sheet responseEnd 420ms; fcp 40ms < held 400ms
2 probe(s) failed.
```
`npm run build` afterwards; `cmp` against the pre-edit copy: `dist/sandbox.html` restored byte-identical.

Stub-oracle falsification: an always-PASS oracle prints PASS on the edited dist and violates AC2/AC3 outright. An oracle comparing FCP to 0 (or dropping the `>= responseEnd` leg) passes the edited dist with FCP 40 ms, again caught by AC2 which demands the FAIL line with the printed numbers. The `>= 400` leg alone would also be caught the same way; both legs are independently exercised by the FAIL line, which prints two reasons. The static lock is independent of paint timing, so a paint-entry outage cannot silently turn the probe green. The oracle is not weakened.

Decision on missing unit tests: not a REJECT for this PBI. Rationale, explicitly: the PBI's scope is the probe and its DoD is evidence per behavioural AC, every AC has evidence, and the failure branches that carry the oracle's meaning (`fcp < responseEnd`, `fcp < 400`, link after `<body`, `media`/`onload` attribute) are exercised end-to-end by the anti-stub runs. The branches with no exercised evidence are the defensive ones (`fcp === null`, missing resource entry, missing/extra paint entry, `cssRules` = 0, UA serif font, link count ≠ 1, missing `rel`). `code-writer` requires calcs be trivially unit-testable — they are — and the tester persona wants them tested; that is a harness follow-up: add `node --test` files under `frontend/scripts/probes/lib/` for the four pure calcs, wired into `npm test`. It must land before the next `probes/lib/` module is added, so the lib grows with tests from its second module on.

BLESS ZG-23 phase-1 — every AC has evidence, anti-stub (a) reproduced independently with FCP 40 ms < responseEnd 420 ms, a stub oracle cannot survive AC2/AC3; unit tests for the pure calcs deferred as a named follow-up, not a blocker for this PBI's DoD.

## Phase 1 — Architect

Mandate: guard the system architecture ruthlessly; reject anything that degrades stratification or coherence; bless nothing until the design is future-proof.

ARCHITECTURE VERDICT: BLESSED

`probes/lib/` starts CTO rule 6 in the right shape: the runner (`probes.mjs`) orchestrates and owns reporting (`pass`/`fail`), page lifecycle, and Playwright plumbing; `paint.mjs` owns paint-timing data plus its one in-frame read action and the calcs over it; `sheet-blocking.mjs` is a pure static lock over an HTML string. Dependencies point one way (runner → lib); the lib imports nothing from the runner and the only runner-owned heuristic (`isUaDefaultSerif`) crosses the boundary as an injected function, not an import — no new coupling, no cycle. Layers are uniform: primitives/constants, domain calcs (reason lists), orchestration in the runner. A senior dev in two years reads `reportColdPaint` and the two lib files in under ten minutes. Later per-PBI probe modules can follow the same contract (record-returning action + pure reason calcs, runner does the printing) without touching this one.

Systemic note, not a blocker: the runner keeps accumulating small Playwright helpers (`holdThemeSheets`, `waitForSandboxComplete`, `sandboxFrame`) alongside 1,100 lines of older probes; when the next lib module lands, those shared page actions belong in a lib module of their own so the runner shrinks to orchestration only. Deciding that now, on one module, would be premature.

BLESS ZG-23 phase-1 — runner-over-lib boundary is clean, dependencies one-directional, nothing here makes the later per-PBI modules harder.
