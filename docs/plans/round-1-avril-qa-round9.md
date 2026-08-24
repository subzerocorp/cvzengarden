# AVRIL round 1 — QA Architect review (cycle 9)

**Role:** `qa-architect-agent` (second adversary) · **Date:** 2026-08-24 · **Cycle:** 9 (ZG-23 revised after the cycle-7 CTO REJECT; after PO cycle-9 BLESS)
**Scope:** ZG-23 only.
**Inputs read in full:** `docs/plans/round-1-avril-po-round9.md`, `docs/plans/round-1-avril-generator-round9.md`, `docs/plans/round-1-avril-cto-round7.md`, my own `round-1-avril-qa-round7.md` (the fact table there still holds; I re-verified the rows the edits touch), `pinto show ZG-23 --plain`, `frontend/package.json`, `frontend/scripts/copy-dist.mjs`, `frontend/scripts/probes.mjs` (path resolution at 18–21, static read at 215), `.gitignore`.

Mandate: *BLESS only PBIs whose acceptance criteria are complete, falsifiable, and hostile to happy-path theater; otherwise REJECT with the missing cases.*

Only two AC lines changed; the oracle, the anti-stub tables, and the N = 10 loop I walked through in cycle 7 are byte-identical and I do not re-litigate them. I judge the two edits for falsifiability and for whether either opened a hole.

## Facts re-verified

| Fact | How | Affects |
| --- | --- | --- |
| `frontend/dist` is gitignored (`.gitignore:9`), so `git checkout` leaves an edited `dist/sandbox.html` in place | `git check-ignore -v frontend/dist/sandbox.html` | the old restore clause was a no-op |
| `npm run build` = `gen` → `elm make` → `copy-dist.mjs`, and `copy-dist.mjs` unconditionally copies `frontend/generated/sandbox.html` over `dist/sandbox.html` | `package.json:7`, `copy-dist.mjs` | the new restore clause really restores |
| `node frontend/scripts/probes.mjs` from the repo root resolves `dist/` from its own file location, not cwd | `probes.mjs:18–21`, `215` | the root-invoked anti-stub command still reads the edited file |
| `frontend/scripts/probes/` does not exist today | `ls` | the widened diff-scope list is a future allowance, not a present blind spot |

## Edit 1 — restore step (`cd frontend && npm run build`)

Falsifiable: after the two anti-stub runs the tester runs the build and then `grep -c 'onload=' frontend/dist/sandbox.html` prints `0` and the link is back before `<body`; or simply runs the next AC (`just test-frontend`), which rebuilds anyway. The clause states *why* (`frontend/dist/` is gitignored) so an executor cannot substitute `git checkout` and claim equivalence. This closes the "mark the step done on a no-op" hole I recorded in cycle 7. No new failure mode: the build is the same command every later AC already depends on.

## Edit 2 — diff-scope list widened to `frontend/scripts/probes/`

Falsifiable as a set test: the output of `git diff --name-only -- . ':!progress.md' ':!features.json'` must be a subset of `{frontend/scripts/probes.mjs} ∪ frontend/scripts/probes/**`, and the five named paths must be absent. A tester checks it with one `grep -v` and needs no source. "Only … and, if …" is permissive wording but it defines a closed set, so it is not the vague "support/handle" pattern I reject.

**The one thing the widening could have weakened, checked.** AC 1's `grep -c "SKIP" frontend/scripts/probes.mjs` locks the runner file only; a helper under `probes/` is outside that grep. Does a SKIP hidden in a module get through? No: AC 1 requires the three literal `PASS  ZG-23/<slug>` lines, AC 4 requires ten `PASS  ZG-23/cold-paint-order` lines each carrying FCP/responseEnd numbers with every FCP ≥ 400, and AC 2/3 require the corresponding `FAIL` lines on the stubbed sandboxes. A probe that skipped instead of running would print none of those, so it fails on the observable output regardless of where the source lives. The grep is defence in depth on the monolith, and it still holds for the file that is required to change. I record for AXEL's tester — not as a body change — that the evidence run should extend the grep to `frontend/scripts/probes.mjs frontend/scripts/probes/` if that directory appears; it costs nothing and keeps the lock aligned with the layout. This is a one-argument clarification at evidence time, not a missing case in the ACs.

**Anti-stub still hostile.** Moving the probe into a module does not change what the two edited sandboxes produce: the behavioural and static FAIL lines are demanded on the runner's stdout and exit code, which are layout-independent. A hard-coded `PASS` in a module is caught exactly as it was in cycle 7.

## Conventions

Unchanged from cycle 7: `PASS  ZG-23/<slug>` / `FAIL  ZG-23/<slug> <reason>` with numbers, no `SKIP`, offline, atomic checkboxes (six ACs, one behaviour each), no implementation dictation beyond the diff-scope guard, dependencies explicit (AC 5 on ZG-1's renderer commit, already on the tree).

**BLESS ZG-23 — the restore clause is now a real, checkable action instead of a gitignored no-op, the widened diff-scope list is a closed set a tester verifies with one grep, and every stub, skip, or missing-hold failure is still forced onto stdout and the exit code by ACs that do not depend on where the probe source lives.**

---

## Blessing log (cycle 9)

- ZG-23: PO BLESS | QA BLESS
