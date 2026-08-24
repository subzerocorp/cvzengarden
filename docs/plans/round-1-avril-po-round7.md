# AVRIL round 1 — Product Owner review (cycle 7)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-24 · **Cycle:** 7 (one new harness item)
**Scope:** ZG-23 only. Nothing else on the board changed in this cycle; no other verdict is emitted or carried.
**Inputs read in full:** `docs/plans/round-1-avril-generator-round7.md`, `docs/plans/round-1-avril-intent.md`, `pinto show ZG-23 --plain`, `pinto show ZG-1 --plain` (its execution evidence is the thing this item unblocks), `frontend/scripts/probes.mjs` (the cold-load block at 620–634, `captureFrame`, `isFoucSample`, `isUaDefaultSerif`, the static S1 stub check at 226–238), `frontend/static/ports.js`, `frontend/generated/sandbox.html` head, `justfile` (`verify: fmt clippy test`, `test-frontend` on `PROBE_PORT`). One fact I checked myself because it decides whether this is a real problem or an internal fantasy: the current probe samples `getComputedStyle` 36 times at 20 ms on a page opened with `waitUntil: "commit"`, and ZG-1's evidence records the identical tree passing 2 of 3 runs on that probe alone.

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

I ask only product questions. I do not judge the paint-timing mechanics (QA) or the file layout of the probe runner (CTO).

---

## ZG-23 — Make the S1 cold-load FOUC probe deterministic with a painted-frame oracle

**Who benefits, and how do we know it shipped?** Every persona, indirectly, and the human running this loop, directly. The intent's stop condition for every round-1 PBI is `just verify` green; the DoD on every card says so. Today that gate is a coin toss on the frontend leg for reasons that have nothing to do with what any persona sees: ZG-1 is parked in `review` with four of five boxes ticked and the fifth reading "identical tree passes 2 of 3 runs". Twenty-one persona-facing items are queued behind that box. A flaky gate is worse than no gate: the team either learns to re-run until green (and stops believing the gate) or stops shipping. "Shipped" is observable without reading source — ten consecutive first-attempt green runs on ten ports, then `just verify` exiting 0 on the ZG-1 tree.

**Is it a real user problem or an internal fantasy?** The value hypothesis is explicit in `## Why` and it is the same one I accepted for ZG-1 in cycle 1: harness debt named as such, `Covers: none`, no persona complaint claimed. This is honest. The item does not pretend a persona asked for it, and it does not pretend the personas do not depend on it. The one product promise it protects is BAR-U1 / RZ-S1 "no FOUC on cold load" — a thing round 0 explicitly listed under "what worked (keep)". The tempting cut would be to delete the cold-load probe and move on; the item refuses that cut, and it is right to, because a gate that stops checking the one thing users praised is a regression waiting for a persona to notice.

**Is this the thinnest honest slice?** Yes, and I tried to make it thinner:

- *Retry instead of replace?* The intent's AXEL DoD and the Generator's rejected-alternatives list both forbid it, and as a product matter a retry that swallows a real flash is a lie told to the user in the name of a green badge. Cut correctly.
- *Just widen the timing window / lower the sample count?* Still the same oracle, still the same race; that is "improve" without a measurable condition. Not thinner, just quieter.
- *Only the paint-order check, drop the two guards?* The two guards (`cold-paint-present`, `cold-sheet-blocking`) are not scope creep; they are what stops the new oracle from passing by silence if paint entries are ever absent, and what makes a stubbed sandbox fail even when timing is unavailable. Without them the item would replace one dishonest green with a potentially different dishonest green. They add three `PASS` lines and no new user-facing behaviour.
- *Fold it into ZG-1?* ZG-1 is in flight with a blessed `renderer/`-only diff scope; smuggling a `probes.mjs` change into it would break ZG-1's own AC and mix two shippable outcomes. Separate id is right.

The slice is one file (`frontend/scripts/probes.mjs`), one probe block replaced, three named lines, no product surface touched. It sits well under the ten-minute review bar; I read it in one pass.

**Is anything smuggled in?** I looked for the usual suspects. `scope_in` keeps the swap-FOUC probe and its helpers byte-identical; `scope_out` names the sandbox markup, `ports.js`, `generate.mjs`, chrome, themes, `justfile`, screenshots, and ZG-1's diff as non-goals — that is the honest list of things a tired executor would be tempted to "fix" instead of the oracle. The `COLD_SHEET_DELAY_MS = 400` knob is an oracle parameter, not a feature. `Dependencies: none` is correct: nothing on the board must land first, and the note is candid that ZG-1's body is not edited by this item (the conductor may add the `ZG-1 → ZG-23` edge; that is board hygiene, not scope). The `just verify` AC is conditioned on "once ZG-1's renderer fix is on the same tree", which it already is (commit 59f52ca is on the branch), so that AC is not a hidden dependency on unfinished work.

**Title and why.** The title is outcome-first ("deterministic") with the mechanism as the qualifier; given that the need is unambiguous — an honest gate — a solution-shaped tail is acceptable here. `## Why` is one sentence with the cause, the symptom, and who is stuck.

**Non-goals I would have wanted named and that are named.** No `SKIP`, no rerun, no screenshot pipeline, no touching the thing under test. Good.

**BLESS ZG-23 — it is the thinnest honest slice that turns `just verify` back into a gate the team can believe for all 22 round-1 items, keeps the one cold-load promise users already praised (BAR-U1) enforced instead of deleted, touches one harness file, and smuggles no product scope.**

---

## Blessing log (cycle 7)

- ZG-23: PO BLESS
