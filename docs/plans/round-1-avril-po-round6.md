# AVRIL round 1 — Product Owner review (cycle 6)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-23 · **Cycle:** 6 (fresh review after the Generator's QA-cycle-5 revise)
**Scope:** ZG-11, ZG-12, ZG-20 — the three ids QA rejected in cycle 5 and revised in `round-1-avril-generator-round5.md`. My cycle-5 blessings on them lapsed with the body edits; each is judged from scratch. ZG-19 and ZG-21 are being revised concurrently and are not touched here; no other id is touched.
**Inputs read in full:** `docs/plans/round-1-avril-po-round5.md` (my last verdicts and the seams I named), `docs/plans/round-1-avril-qa-round5.md` (the three REJECTs and the set-level notes), `docs/plans/round-1-avril-generator-round5.md` (what changed, and the claim that no edge moved), `docs/plans/round-1-avril-intent.md`, the five round-0 persona reports (`docs/persona-rounds/round-0/{marcus,priya,mika,elena,devon}.md`), the three current bodies (`pinto show ZG-11 ZG-12 ZG-20 --plain`), and two cross-checks outside scope that bear on ownership: ZG-10 and ZG-19 run their unit tests by hand (`node --test <file>`) and neither edits `frontend/package.json` (today `test` = `npm run probe`), so ZG-20's glob wiring has one owner; `CONTRIBUTING.md` does not exist today and is ZG-18's file, whose body already names `npm run lint-theme` with "until it lands, the manual checklist".

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

The cycle-5 revise was oracle repair driven by QA — an empty-content ink-bar marker clause, a whole-sheet break scan plus computed-style check, element-scoped animation checks, a CJK letter-run clause with its negatives, and a `--static` flag on `probes.mjs`. So for each item I ask only product questions: is there still exactly one persona-traceable outcome; did any oracle fix change what a persona sees or promise something the item does not ship; are the `scope_out` lines still honest about the tempting extras; did ownership or wiring smuggle a second feature under the id; and is any item now a review nobody can finish in ten minutes. I do not rewrite bodies, touch the board, or judge test mechanics except where they change user-visible scope.

---

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

**What the user sees.** Unchanged from cycle 5: sections may break across pages, entries may not, no forced page before Projects in Switchyard, Switchyard's bullet bar and Nightgarden's bullet dot print as ink, Nightgarden's four secondary colours print dark. Jordan prints 2 pages in every theme (Quarto and Switchyard were 3); Marcus's four-job fixture prints ≤ 3 with page 1 ≥ 85 % full. Still E1 / E2 / E3 — Marcus (#5, #7-adjacent), Priya (#5, #6), Mika (#7), Elena (#10). One outcome: the printed page.

**The two oracle fixes, judged as product.**

- *`bullets-print` now admits an empty-content bar or dot with a sized box.* This is the AC catching up with the scope, not the scope moving: the scope has recommended "ink-coloured bar … or a text glyph" for Switchyard since cycle 3 and for Nightgarden since cycle 4. The cycle-5 wording would have forced a glyph on both, which is a design change nobody asked for — Priya's complaint is that markers vanish on paper, not that they are bars. The fix keeps the designer's choice open and holds all three themes to one ink assertion. No user-visible change; the thin slice is preserved.
- *`no-forced-break` reads computed `breakInside` / `breakBefore` in print emulation and scans the whole Switchyard sheet.* The cycle-5 static grep could never see Quarto's top-level rule — the exact rule Marcus and Mika both cite by line number (`quarto.css:174-178`) as the cause of the 70 %-blank first page. An AC that cannot fail on the theme that has E1 is an AC that cannot protect Marcus's outcome. This fix makes the promise falsifiable on the one theme that matters most for print (Quarto is the "print" flagship per Priya and Mika). Product-positive, no scope added.

**The three folded-in notes.** "Ranges are a guide, not a ceiling — the AC decides" for the fixture is the right product stance: the fixture exists to be a real senior résumé that trips E1 at paper width, and a fixture capped below that threshold would repeat round 0's failure (print tested only on a résumé that fits). The oversize-atomic-block rule in `paginate` and the `--hide-scrollbars` note are test determinism; nothing a persona sees.

**Scope-in prose.** The break line now carries the per-sheet location of each rule (top-level vs. `@media print`) and a sentence forbidding `extractMediaBlocks` for any "no theme has X in print" claim. That is implementation guidance, not scope growth; it names five CSS edits, the same five as cycle 5.

**Size.** This is still the heaviest themes item, and the body's word count is now roughly two-thirds test infrastructure (fixture spec, `openResumePage`, `printableWidthPx`, `paginate`, ten probe ACs) against five CSS rules. I judged it under the ten-minute bar in cycle 5 and the cycle-6 additions are prose precision on existing probes, not new deliverables — no new helper, no new file, no new constant. Still one shippable outcome and still under the bar for me. The seam is unchanged and I restate it for the CTO: if size is called, cut the fixture + cargo lock + `paginate` / `openResumePage` helpers out as a labelled `spike` prerequisite — never the CSS, which is the product.

**Non-goals.** Unchanged and honest: name overflow and `rz-rise` are ZG-12's; fonts are ZG-13's with the two-way `U3_PRINT_PAGES` re-check; no widow/orphan tuning; no paper-size change; no PDF rasterisation (`pdftoppm` present-but-not-required); nothing measured inside the Garden iframe.

**Dependencies.** None; ready at start; ZG-12 still depends on it for `openResumePage`. First item I want AXEL to pick, unchanged.

**BLESS ZG-11 — the printed page is still the one outcome and nothing a persona sees moved; the two oracle fixes make the promise falsifiable on the exact Quarto rule Marcus and Mika cite for E1 and stop forcing a glyph marker the scope never asked for; the size seam (fixture + helpers as a spike, never the CSS) is unchanged.**

## ZG-12 — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks

**What the user sees.** Unchanged from cycle 5: Marcus's surname fits the rail (#7), Cmd-A / crawlers / screenshots see every section without scrolling (#11), a highlight with embedded `\n` keeps its lines in all three themes (#9, Mika-adjacent D5). Marcus and Mika, E3 and D5. The rest-state decision from cycle 5 — painted before entry, rise plays on entry with fill `forwards` — is untouched; it remains the thinnest fix that honours locked decision 4.

**The oracle fix, judged as product.** `painted-without-support` and `reduced-motion` are now scoped to `.rz-section` animations instead of `document.getAnimations()`. The cycle-5 wording could only pass by deleting Nightgarden's name sheen and current-entry foxfire — two decorative animations no persona complained about, which `scope_out` and locked decision 4 keep. So the fix prevents an accidental scope *expansion* (stripping animations to make a probe green), not a contraction. The new scope-in line recording the sheen and foxfire verbatim as untouched is a non-goal placed where the implementer will read it; I would ordinarily want it in `scope_out`, but it is honest either way and the `scope_out` line refusing to drop the rise already carries the product decision.

**The two folded-in notes.** Naming computed `opacity` as the primary oracle (pixel count as confirmation) and the `#070b14` body-colour correction change nothing a human sees; they stop a tester mis-reading a transient partial-opacity frame as a defect. `pre-line` on the top-level page is consistency with the other probes.

**Bundle check.** The title names three fixes and the item is three fixes — I accepted that in cycles 1, 3 and 5 because each is a few lines of CSS with no demo of its own, they share one persona and one sheet, and the contract note (highlights may contain `\n`) is the only prose. Cycle 6 grows none of the three.

**Non-goals.** Unchanged and honest: no print rules (ZG-11), no nested lists from indented text (no markdown-in-JSON), no Quarto/Switchyard name sizing, no Firefox/WebKit install, BAR-L1 is ZG-13's, and the rise is not removed.

**Dependencies.** Still ZG-11 (`openResumePage`; same sheet, print block first). Marcus's name fix follows his print fix on the item I rank first; no persona path lengthens.

**BLESS ZG-12 — the same three persona-cited screen fixes and the same painted-rest-state decision; the only change scopes the "nothing animates" oracle to the sections so a correct sheet passes without stripping the sheen and foxfire that no persona asked to lose, which protects the thin slice rather than growing it.**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

**What the user sees.** Unchanged in kind: one command, one verdict, an exit code that matches what the reviewer will say. Devon's four Cathode `content:` values (`"$ "`, `"["`/`"]"`, `"▌"`, `counter(rz-sec, …)`) still pass, `"Jordan Hale"` still fails, `"Page " counter(page)` is still a warning for a human. Devon (#11) and Mika, C7. Two additions are visible to a Designer and I judge each.

**The `content:` letter-run rule, judged as product.** The cycle-5 rule (`\p{L}{3,}`) had a hole exactly where locked decision 3 ("résumé words never only in `content:`") bites hardest for a non-Latin résumé: a two-character CJK label like `名前` ("name") is a résumé word and the rule let it through. QA offered three fixes; the Generator took the script-class clause rather than lowering the threshold, which would have flagged `"Jr"` and `"vs"` — decorative abbreviations a designer legitimately writes. The clause is one regex with the `u` flag, no dependency, and comes with the negatives that keep it from over-reaching (`"氏"` single glyph passes, `"Jr"` / `"vs"` pass). This is the lint telling the truth about the rule the reviewer already applies, not a new rule; a lint with a known hole for the world's most common two-character labels would send Devon and Mika a false PASS. Thin and honest. Neither persona writes CJK, so this is business value (the reviewer's verdict and the lint's verdict stay one program), not persona value — that is acceptable for a lint whose whole point is parity with the human reviewer.

**`probes.mjs --static`, judged as product.** A flag that stops after `staticProbes()` — no server, no Chromium, no port — owned here and used by the meta-test. It is not a user feature and I would reject it as a standalone PBI; here it is the enabling plumbing that keeps the cycle-5 business value (lint-by-hand and lint-in-`just verify` are provably the same program) from costing two full browser-suite runs per `just verify`. A dozen lines, one AC (under 10 s, no browser-suite line, flag-less behaviour unchanged). Thinnest honest support for a promise already in the item. Accepted.

**`npm test` wiring with a glob, judged for smuggling.** `test` becomes `npm run probe && node --test scripts/*.test.mjs`, which also picks up ZG-10's `page-estimate.test.mjs` and ZG-19's `blank-theme.test.mjs`. I checked both bodies: each runs its unit test by hand (`node --test <file>`) and neither edits `package.json`, so ZG-20 is the sole owner of "unit tests are part of `just verify`" and the glob is additive — no collision, no second feature. Ordering fact for AXEL: until ZG-20 lands, ZG-10's and ZG-19's unit tests are not in `just verify`; their own ACs run them explicitly, so nothing is unprotected.

**New unit cases** (`@page :first{}`, `::selection`, `::marker`): they pin constructs the first-party themes or any designer already writes; no rule changed.

**One ownership note, non-blocking.** The AC `grep -n "lint-theme" CONTRIBUTING.md frontend/package.json` requires a file that does not exist today and is ZG-18's. ZG-18 already writes the `npm run lint-theme` sentence and anticipates either ordering ("until it lands, the manual checklist"); the two items become ready together (both wait on ZG-14 and ZG-17) and no edge orders them. If ZG-18 lands first, the AC is satisfied by ZG-18's text; if ZG-20 lands first, its implementer would create a one-line `CONTRIBUTING.md` that ZG-18 then completes — not a second shippable outcome, but a sliver of ZG-18's file under ZG-20's id. Instruction for AXEL: run ZG-18 before ZG-20 (or the conductor adds the one edge). This line has been in the body since cycle 3 and is unchanged this cycle; it does not block.

**Notes.** The `notes` line is an open question addressed to QA ("confirm the rule including the two-character CJK clause or tighten it"). It drains on QA's BLESS and must be empty before the CTO's final gate — the conductor's check, not mine.

**Non-goals.** Unchanged and honest: no full CSS parser (limits documented in the file), not in CI, no taste/size/contrast judgments. No new dependency (still ZG-19, owner of the `_blank.css` header the `header` warning reads).

**Size.** Grew by a flag, a `package.json` line, one regex clause and six unit cases. The lint is still a pure `checkTheme` plus a thin CLI plus a unit file; one command, one verdict, one demo (`npm run lint-theme themes/cathode.css`). Reviewable in one pass.

**BLESS ZG-20 — the pass/fail Devon asked for, now honest for a non-Latin résumé label under the locked "words stay in HTML" rule without flagging `"Jr"`; the `--static` flag and the `npm test` glob are the thinnest plumbing for a promise already in the item and I verified they collide with no other owner; the only ordering note (ZG-18 owns `CONTRIBUTING.md`) is an AXEL instruction, not scope.**

---

## Summary

| id | PO cycle 5 | QA cycle 5 | PO cycle 6 | user-visible scope changed | new deps | human decision pending |
| --- | --- | --- | --- | --- | --- | --- |
| ZG-11 | BLESS | REJECT | **BLESS** | no — marker clause admits the bar/dot the scope already recommended; break check now falsifiable on Quarto's top-level rule | none (ZG-12 still depends on it) | none |
| ZG-12 | BLESS | REJECT | **BLESS** | no — animation oracles scoped to `.rz-section`; sheen and foxfire explicitly kept | none (still ZG-11) | none |
| ZG-20 | BLESS | REJECT | **BLESS** | yes, one rule — a 2+ CJK-script run in `content:` is an error (with `"氏"` / `"Jr"` / `"vs"` negatives); `--static` and `npm test` wiring are plumbing | none (still ZG-19) | none |

3 BLESS, 0 REJECT. All three proceed to the QA Architect, then the Visionary CTO.

## Set-level notes (non-blocking; for the conductor and AXEL)

- **ZG-18 before ZG-20.** Both become ready together after ZG-14 and ZG-17 (via ZG-19); ZG-18 owns `CONTRIBUTING.md` and already names the lint. Order them, or add the one edge, so no stub `CONTRIBUTING.md` is created under ZG-20's id.
- **ZG-20 owns "unit tests in `just verify`".** ZG-10's and ZG-19's `node --test` files join `just verify` only when ZG-20 lands; their own ACs run them by hand until then. No edge needed.
- **ZG-11 seam restated for the CTO.** If size is called: fixture + cargo lock + `paginate` / `openResumePage` as a labelled `spike` — never the CSS.
- **ZG-20 `notes` must drain.** The QA question on the CJK clause closes on QA's BLESS; the CTO should see an empty `notes`.
- **Persona ordering unchanged from cycle 5.** ZG-11 first among ready items, ZG-12 immediately after; walk Marcus on print and screen after both land, not between them. ZG-13 before any hosted page is shown to a persona. Do not walk Priya or Elena between ZG-5 and ZG-6.
- **Phase-5 check (lock 10).** Nothing crept in: no accounts, payments, slugs, PDF pipeline, AI, import, or cross-origin API in any of the three bodies.
