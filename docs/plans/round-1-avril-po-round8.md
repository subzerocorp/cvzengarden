# AVRIL round 1 — Product Owner review (cycle 8)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-24 · **Cycle:** 8 (fresh review after the Generator's cycle-8 revise, which answered the QA Architect's cycle-6 REJECTs)
**Scope:** ZG-11 and ZG-20 — the two ids QA rejected in cycle 6 and revised in `round-1-avril-generator-round8.md`. My cycle-6 blessings on them lapsed with the body edits; each is judged from scratch. ZG-12 (triple-blessed) and ZG-19 (triple-blessed) were read for consistency only and are not touched. No other id is touched.
**Inputs read in full:** `docs/plans/round-1-avril-po-round6.md` (my last verdicts and the seams I named), `docs/plans/round-1-avril-qa-round6.md` (the two REJECTs and the set-level notes), `docs/plans/round-1-avril-generator-round8.md` (what changed; the claim that no edge moved), `docs/plans/round-1-avril-intent.md`, the two current bodies (`pinto show ZG-11 ZG-20 --plain`, `Updated` 2026-08-24T11:25 on both, `Depends on` unchanged: ZG-11 none, ZG-20 → ZG-19; ZG-12 still `Depends on: ZG-11`), and `pinto show ZG-12 ZG-19 --plain` for the ownership cross-checks below.

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

The cycle-8 revise was, for the third time on these two items, oracle repair driven by QA: a computed-style read for a pseudo-element box, a corrected computed value in an anti-vacuity sentence, a header block added to a simulated-pagination list, two pre-change failure modes named in evidence, a `--static` negative rewritten to name browser-only lines, a `@keyframes` exclusion on the selector rule with one unit case, and a concurrency constraint on the meta-test. So I ask only product questions: is there still exactly one persona-traceable outcome per id; did any of these edits change what a persona sees, or promise something the item does not ship; are the `scope_out` lines still honest about the tempting extras; did any wiring smuggle a second feature under the id; and is either item now a review nobody can finish in ten minutes. I do not rewrite bodies, touch the board, or judge test mechanics except where they change user-visible scope.

---

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

**What the user sees.** Unchanged from cycle 6: sections may break across pages, entries may not; no forced page before Projects in Switchyard; Switchyard's bullet bar and Nightgarden's bullet dot print as ink; Nightgarden's four secondary colours print dark. Jordan prints 2 pages in every theme; Marcus's four-job fixture prints ≤ 3 with page 1 ≥ 85 % full. Still E1 / E2 / E3 — Marcus, Priya, Mika, Elena. One outcome: the printed page.

**The four edits, judged as product.**

- *`bullets-print` reads the `::before` box with `getComputedStyle(el, '::before').width`/`.height` instead of a rect.* This is the AC's measuring instrument changing, not the thing measured. The designer's choice (ink bar, ink dot, or text glyph) that I defended in cycle 6 is preserved verbatim — the three alternatives, the `list-style-type` branch and the ink clause are as blessed. Priya's complaint (markers vanish on paper) is still what the probe protects. No user-visible change.
- *`no-forced-break`'s anti-vacuity now says pre-change Quarto computes `avoid`, not `avoid-page`.* One token in a sentence about the recorded evidence line. The assertion (`auto` on every `.rz-section`) and its target — the exact Quarto rule Marcus and Mika cite for the 70 %-blank first page — are unchanged. No user-visible change.
- *`.rz-header` is the first block placed on page 1 in `paginate`.* Test determinism: the simulated page can no longer claim more capacity than the real one. This makes the `page1-fill` ≥ 0.85 promise slightly *harder* to satisfy, which is the direction a persona wants. No scope added.
- *Both pre-change `bullets-print` failure modes recorded in evidence.* Switchyard's bar living only in `@media screen` is E2 itself — Priya's lost bullets — and Nightgarden's mint dot with no print ink is the E2 sibling this PBI pulled in at cycle 4. Naming them once in evidence is the item proving it reproduced the complaint before fixing it. That is product hygiene, not growth.

**Scope-in prose.** The Switchyard bar's location is now stated correctly in the AC (`@media screen`, 256–264). I note for honesty that the scope-in bullet for Switchyard still says "`@media print .rz-bullet::before` gets a printed marker", which is the fix, not the current state — consistent. Five CSS edits, the same five as cycles 5 and 6.

**Size.** Third consecutive cycle in which the deliverables did not grow: no new helper, no new file, no new constant, no new probe slug. The body is long because the fixture spec, `openResumePage`, `printableWidthPx`/`printableHeightPx`, `paginate` and ten probe ACs are spelled out; the product is five CSS rules. Still one shippable outcome and still under the ten-minute bar for a reviewer who reads the ACs as a checklist. My seam for the CTO is unchanged: if size is called, cut the fixture + cargo lock + `paginate` / `openResumePage` helpers out as a labelled `spike` prerequisite — never the CSS.

**Non-goals.** Unchanged and honest: name overflow and `rz-rise` are ZG-12's; fonts are ZG-13's with the two-way `U3_PRINT_PAGES` re-check; no widow/orphan tuning; no paper-size change; no PDF rasterisation; nothing measured inside the Garden iframe.

**Dependencies.** None; ready at start; ZG-12 still depends on it for `openResumePage` (its body still names the same signature). First item I want AXEL to pick, unchanged.

**BLESS ZG-11 — the printed page is still the one outcome and nothing a persona sees moved; the four cycle-8 edits change how the probes read the page (a computed-style read, a corrected evidence token, a stricter page-1 simulation, the two round-0 complaints reproduced once in evidence), not what the page looks like; the size seam (fixture + helpers as a spike, never the CSS) is unchanged.**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

**What the user sees.** One command, one verdict, an exit code that matches what the reviewer will say. Devon's four Cathode `content:` values still pass, `"Jordan Hale"` still fails, `"Page " counter(page)` is still a warning for a human. Devon (#11) and Mika, C7. One of the three edits is visible to a Designer and I judge it first.

**The `@keyframes` exclusion, judged as product.** Without it, the rule as written would have made a Designer's blink or flicker animation (`0%`, `50%`, `to`) a `selector` error — and Devon's Cathode has exactly such an animation (`rz-blink`). A lint that fails the persona it was built for, on a construct the contract permits, would be worse than no lint: Devon would trust the red verdict and rewrite a legal theme. This is the lint telling the truth about the reviewer's rule (the reviewer has never rejected a keyframe selector), and it comes with one unit case that pins percentages, not just `from`/`to`. Thin, honest, product-positive. It is also the same exclusion ZG-12's own probe already states, so the two items agree on what a "selector" is.

**The `--static` negative and success output, judged as product.** The AC now names the lines a Designer would *not* see (`Live sandbox …`, `S2 <id>:`, `U3 <id>:`, `printToPDF`, `All RZ-3`) and says what success prints (nothing after the last probe line). This is the meta-test's plumbing being made runnable; a Designer never runs `probes.mjs --static`. The business value it protects — lint-by-hand and lint-in-`just verify` are provably one program — is the one I accepted in cycle 6. No change in kind.

**The concurrency constraint, judged for smuggling.** "The meta-test is the only test that writes into `themes/`" is a stated constraint for future test authors, not a feature; `--test-concurrency=1` was explicitly *not* taken. Nothing new is owned. I re-checked the two other test-file owners: ZG-19's `blank-theme.test.mjs` reads `themes/_blank.css` by name, and ZG-10's `page-estimate.test.mjs` reads no theme — neither lists `themes/`, so the constraint costs nothing today.

**Ownership notes, unchanged.** `CONTRIBUTING.md` is ZG-18's file; the AXEL instruction "ZG-18 before ZG-20" from cycle 6 stands and is not scope. ZG-20 remains the sole owner of `package.json` `test` (ZG-10 and ZG-19 run their unit tests by hand). No new dependency.

**Notes.** The `notes` line is still the open question to QA on the CJK clause. QA confirmed the rule by execution in cycle 6; on QA's cycle-8 BLESS it drains, and the conductor should see it emptied before the CTO's final gate. Not my gate.

**Non-goals.** Unchanged and honest: no full CSS parser (limits documented in the file), not in CI, no taste/size/contrast judgments.

**Size.** Grew by one sentence in the selector rule, one unit case, one rewritten negative and one constraint sentence. Still a pure `checkTheme` plus a thin CLI plus a unit file; one command, one verdict, one demo (`npm run lint-theme themes/cathode.css`). Reviewable in one pass.

**BLESS ZG-20 — the pass/fail Devon asked for, now honest on the one construct his own theme uses (a percentage keyframe) instead of sending him a false FAIL; the `--static` and concurrency edits are plumbing for a promise already in the item, collide with no other owner, and add nothing a Designer sees; ordering (ZG-18 before ZG-20) is an AXEL instruction, not scope.**

---

## Summary

| id | PO cycle 6 | QA cycle 6 | PO cycle 8 | user-visible scope changed | new deps | human decision pending |
| --- | --- | --- | --- | --- | --- | --- |
| ZG-11 | BLESS | REJECT | **BLESS** | no — probe reads and evidence wording only; `.rz-header` makes `page1-fill` stricter, not looser | none (ZG-12 still depends on it) | none |
| ZG-20 | BLESS | REJECT | **BLESS** | yes, one rule narrowed — keyframe selectors (`from`/`to`/`<percentage>`) are never `selector` errors, which protects Devon's `rz-blink`; `--static` wording and the `themes/` write constraint are plumbing | none (still ZG-19) | none |

2 BLESS, 0 REJECT. Both proceed to the QA Architect, then the Visionary CTO.

## Set-level notes (non-blocking; for the conductor and AXEL)

- **ZG-18 before ZG-20** (unchanged from cycle 6): ZG-18 owns `CONTRIBUTING.md`; order them or add the one edge so no stub file is created under ZG-20's id.
- **ZG-20 `notes` must drain** on QA's BLESS this cycle; the CTO should see an empty `notes`.
- **ZG-11 seam restated for the CTO:** if size is called, fixture + cargo lock + `paginate` / `openResumePage` as a labelled `spike` — never the CSS.
- **Persona ordering unchanged:** ZG-11 first among ready items, ZG-12 immediately after; walk Marcus on print and screen after both land, not between them.
- **Phase-5 check (lock 10):** nothing crept in — no accounts, payments, slugs, PDF pipeline, AI, import, or cross-origin API in either body.
