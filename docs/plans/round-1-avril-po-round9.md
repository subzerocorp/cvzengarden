# AVRIL round 1 — Product Owner review (cycle 9)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-24 · **Cycle:** 9 (ZG-23 revised after the cycle-7 CTO REJECT; fresh chain)
**Scope:** ZG-23 only.
**Inputs read in full:** `docs/plans/round-1-avril-generator-round9.md`, `docs/plans/round-1-avril-cto-round7.md`, `docs/plans/round-1-avril-qa-round7.md`, my own `round-1-avril-po-round7.md`, `docs/plans/round-1-avril-intent.md`, `pinto show ZG-23 --plain` (diffed by eye against the cycle-7 body).

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

I ask product questions only. I do not comment on runner layout except where it changes what a user can observe.

## What changed since my cycle-7 BLESS

Exactly two lines, both in `## Acceptance criteria`; I confirmed nothing else moved (title, `why`, `Covers`, `scope_in`, `scope_out`, `Dependencies`, `Notes`, labels).

1. The diff-scope AC now allows paths under `frontend/scripts/probes/` in addition to `frontend/scripts/probes.mjs`, keeping the "untouched" list (`ports.js`, `generate.mjs`, `skeleton/`, `themes/`, `renderer/`) verbatim.
2. The behavioural anti-stub AC says the edited `dist/sandbox.html` is restored by `cd frontend && npm run build`, not `git checkout`.

## Product questions, re-asked against the revised body

**Who benefits, and how do we know it shipped?** Unchanged. Every Author/Designer-facing slice in round 1 is gated on `just verify`, and `just verify` is currently a coin flip on identical trees. The user-observable outcome is "the harness stops lying", proven by the N = 10 distinct-port loop printing `ALL-GREEN` and `just verify` exiting 0. Neither edited AC touches that.

**Is this still the thinnest slice?** Yes. Widening the positive path list does not widen scope: `scope_in` still says "replace the cold-load block of `s1Probes`", `scope_out` still forbids touching the sandbox, chrome, themes, `ports.js`, `generate.mjs`, the swap probe, and the `justfile`. Allowing the executor to put a helper in a sibling directory is not a second deliverable; it produces no new probe line, no new user-facing behaviour, and no new AC. I checked specifically for scope smuggling — "if the executor extracts … into modules" is permissive, not mandatory, and the observable contract (the three `PASS  ZG-23/<slug>` lines, the two FAIL lines with numbers, `ALL-GREEN`) is exactly what it was in cycle 7. Had the Generator added a "refactor the runner" bullet or a fourth probe I would cut it; it did not.

**Does the restore-step change alter value?** It makes the anti-stub AC honest. In cycle 7 an executor following the body literally would run `git checkout`, see no change (the file is gitignored), and could mark the step done while the stubbed sandbox was still on disk. That is precisely the "done that cannot fail" pattern this item exists to kill; correcting it protects the value hypothesis rather than expanding it.

**Anything to cut?** I looked again at the CTO's optional `Guidance for AXEL` note — the Generator left it out, and I agree: a layout hint in a PBI body is internal chatter that earns no user outcome. `Points` is still omitted rather than invented. Good.

**Honest non-goals present?** `scope_out` is unchanged and still names the tempting extras (retry/skip, screenshots, computed-style sampling, any sandbox "fix"). The new diff-scope wording keeps the strongest of these — the sandbox is not to be touched to make a probe happy — as a mechanically checked list.

**BLESS ZG-23 — the two cycle-9 edits change no user-observable outcome, add no deliverable, and make the anti-stub restore step something a tester can actually do; the item remains the thinnest honest slice that turns `just verify` from a coin flip into a gate every round-1 persona slice can be verified against.**

---

## Blessing log (cycle 9)

- ZG-23: PO BLESS
