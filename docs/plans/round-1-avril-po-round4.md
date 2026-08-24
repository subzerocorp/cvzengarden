# AVRIL round 1 — Product Owner review (cycle 4)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-23 · **Cycle:** 4 (fresh review after the Generator's QA-driven revise, cycle 3b)
**Scope:** ZG-6, ZG-10, ZG-17 only — the three items QA rejected in cycle 2 and the Generator revised in cycle 3b. My cycle-2 blessings on them lapsed with the body edits; each is judged from scratch. No other item is touched.
**Inputs read in full:** `docs/plans/round-1-avril-po-round2.md` (my cycle-2 verdicts), `docs/plans/round-1-avril-qa-round2.md` (the blockers that sent them back), `docs/plans/round-1-avril-generator-round3b.md` (what changed), `docs/plans/round-1-avril-intent.md`, `docs/persona-rounds/round-0/{elena,priya,mika,devon}.md`, `pinto show ZG-6 ZG-10 ZG-17 --plain`, `pinto list --json` (dependency graph), plus `ls skeleton/` and `git ls-files frontend/generated` to confirm two facts below.

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

The revise was driven by QA, not by me, so the question this cycle is different from cycle 2. QA asked for oracles; the Generator answered with mechanisms, fixtures, and rules. For each item I ask: is the user-visible outcome still exactly one and exactly what the personas asked for; did any of the testability rewrite smuggle a feature, a doc, or a dependency under the same id; are the non-goals still honest; and do the dependencies leave Elena, Priya, and Mika no further from a walk than they were in cycle 2. I do not rewrite bodies or touch the board.

---

## ZG-6 — Explain the résumé format in plain words and start from a sample

**What the user sees (unchanged from cycle 2).** One sentence naming JSON Resume with a link; a copyable 8–12 line example with a Copy button; two one-click samples (Jordan, and Sam Okoro's short one); a plain sentence in the sidebar. Priya, row 2: "If the answer is 'JSON Resume' it is never said." Elena, rows 1 and 12: "Use this sample as a starting point" and "I can't tell what a thin résumé looks like." Every scope line still maps to a quoted complaint. Still one audience, one outcome.

**What the rewrite added, judged line by line.**

- *String `score: "3.7"`.* This is the resolution I asked for in cycle 2 — the file we hand Elena next to a schema link should be the canonical well-formed shape. It also drops the only reason ZG-6 wanted ZG-3, and the body says so. Product-positive, no scope.
- *Vendored schema + `ajv` runner + `schema-rejects` anti-stub.* The one genuinely new artefact. It is a test oracle, not a feature: nothing an Author sees changes. Its product purpose is the promise that the example, the junior sample, and Jordan's file are all valid JSON Resume — which is the difference between "here is an example" and "here is an example that will not fire Elena's walk-away trigger on the first paste." `skeleton/README.md` exists today, so the provenance line is an edit, not a new doc. Offline, pinned, one owner. Accepted as the price of the promise.
- *`example-renders`.* Proves Priya's next move (paste → Show it) works on the text we tell her to copy. This is the AC that was missing in cycle 2 for the item's own headline claim. Pure value.
- *Sidebar sentence AC.* Was already in scope; now provable. No change.
- *Build-time embedding (`generate.mjs` → `Samples.elm`).* A delivery mechanism, not a feature. It removes any need to serve `skeleton/` and therefore any ZG-6 → ZG-14 edge, which keeps Elena's chain short (ZG-5 → ZG-6) and keeps ZG-14 as the single owner of the copy step. `frontend/generated/` is already tracked (`sandbox.html`), so the generated file follows an existing convention. Product-neutral, dependency-positive.
- *Clipboard failure state.* User-visible and honest: "Copy failed — select the text and copy it" instead of a lying "Copied". Same two states as ZG-8, so the chrome has one vocabulary. Tiny, correct.
- *Sample-not-stored rule.* This is the one real product decision in the rewrite, and it is the right one: a sample is a starting point, so an accidental click on "Start from Jordan's sample" must not destroy the Author's stored résumé; editing the sample and pressing "Show it" stores it exactly as a paste does. The rule is stated in scope-in, not hidden in a test, and it is the safer default for the persona who is nervous about losing her work. The one surprise it creates — click a sample, reload, get your own résumé back — is the correct surprise.
- *Pinned names (`Sam Okoro`, `Alex Rivera`), `acceptance.rs` lock, image-diff command, shell-print route for `junior-all-themes`.* Test plumbing. None alters what ships.

**Scope creep?** None user-visible. The junior sample is still Elena's file and nothing else (no `image`, enforced two ways). Non-goals are unchanged and still honest: no form editor, no PDF/DOCX/LinkedIn conversion, no in-place editing, no serving, no numeric score, no schema fetch. The title still names the user need, not the mechanism.

**Dependencies.** Still `ZG-5` only. Elena's path is ZG-1 → ZG-2/ZG-3/ZG-4 → ZG-5 → ZG-6, identical to cycle 2; the rewrite added no edge and explicitly declined three (ZG-14, ZG-3, ZG-11). Good.

**One thing the conductor must not lose.** The schema probes FAIL (never skip) until the human approves `ajv` or the `jsonschema` crate, and `just verify` green is in the DoD. So ZG-6 cannot close until open question "third-party for human approval" in `## Notes` is answered. That is exactly the path the intent mandates for a non-locked dependency, so it is not a product blocker — but it is a human decision sitting on Elena's critical path, and it should be put to the human before AXEL reaches ZG-6, not discovered when the probe goes red.

**BLESS ZG-6 — the rewrite proves the item's own headline (the example renders, the samples validate, the copy button tells the truth) and adds one honest product rule (a sample click never destroys the Author's file); nothing user-visible was added, the non-goals hold, and Elena's chain is no longer than it was.**

## ZG-10 — Show an honest page count in print preview and how to save a PDF

**What the user sees (unchanged from cycle 2).** In Print preview, "About N pages (Letter)" or "(A4)"; in both views, a sentence under the print button: "Choose 'Save as PDF' in the print dialog to get a PDF." Mika, row 5: "or at least a 'N pages' readout next to the Print button." Priya, row 5: "at least a hint before I print that it will be N pages." Elena, row 9: "a hint 'Choose Save as PDF in the dialog.'" Three personas, two lines, one outcome.

**The oracle change, judged as product.** QA measured that a column-height estimate cannot be ± 0 against the PDF (Switchyard: formula 2, PDF 3, because of its forced break before Projects) and that demanding ± 0 contradicted my own cycle-2 reasoning for cutting the guide lines. The Generator now claims exactly what the word "About" means: exact against a stated formula, within one page of the real PDF, and the scope-out says in plain words that page-break rules are not modelled and exact-vs-PDF is not claimed. That is the honest slice. A readout that says "About 2 pages" and prints 3 on Switchyard today is a smaller lie than a guide line in the wrong place, and it is the truth the item can afford without a paged-media runtime — which remains a stated non-goal. I accept ± 1 as the honest bar and I would reject any future edit that tightens the claim without also modelling breaks.

**What the rewrite added, judged line by line.**

- *Pure module `page-estimate.js` + node unit test, full geometry rules (base rules only, `:first` ignored, case-insensitive sizes, unit conversion, Letter default and fallback with a `source` attribute).* Internal structure needed to compute the two numbers the readout shows. The paper name in the readout was already in cycle 2 (`paper-size` AC). The fallback behaviour is user-relevant in one way: a contributed theme with no `@page` or an odd `size` still gets a readout instead of a blank or an exception. Product-neutral to positive. No new user-facing surface.
- *`ResizeObserver` recompute + theme-swap + view-toggle recompute.* The mechanism by which a ZG-5 paste updates the count without ZG-10 knowing about ZG-5. This is how the paste route and the long fixture were dropped, which removed two conditional dependencies (ZG-5, ZG-11). Dependency-positive.
- *Hint as its own element `[data-pdf-hint]`, after ZG-7's sentence.* Closes the hole where ZG-7's button label alone would have satisfied the AC. The user gets both sentences. Correct.
- *`min-one` / singular.* "About 1 page", never "About 0 pages" or "1 pages". Copy quality, not scope.
- *`no-guide-lines` pinned to exact DOM shape; "touches nothing under `themes/`, does not edit `U3_PRINT_PAGES`."* Guards that the readout cannot move page counts and that the cut overlay cannot return. Good non-goal enforcement.

**Scope creep?** None. Same two user-visible things as cycle 2. Non-goals are unchanged and one is sharpened (break modelling is now explicitly out, with the measured reason). Readout is Print-preview-only, as the title has said since cycle 1; the hint is in both views, which is where Elena needs it.

**Dependencies.** Still `ZG-7` only, a leaf. The rewrite removed the two conditional edges QA raised rather than adding them. Priya's print path is ZG-7 → ZG-10, unchanged.

**Ordering note for the conductor, not a blocker.** Today the Switchyard readout will be one page under the PDF until ZG-11 removes the forced break before Projects. ZG-11 is independent and ranked immediately after ZG-10. Rank ZG-11 ahead of ZG-10, or at least do not walk personas between them; that is a reorder, not a dependency, and I do not want an edge that ties a chrome item to a themes item.

**BLESS ZG-10 — the readout now claims exactly what "About" means (formula-exact, PDF ± 1, breaks explicitly not modelled) and the hint is its own sentence; the rewrite added no user-facing scope, removed two conditional dependencies, and leaves the two lines three personas asked for by name.**

## ZG-17 — Add the repo LICENSE and state the theme-contribution license terms

**What the user sees (unchanged from cycle 2).** A root `LICENSE` (MIT); a License section in `themes/README.md` naming MIT or CC BY 4.0, saying the Garden may host on free and paid pages, promising switcher attribution only, and refusing CC BY-NC; a `_blank.css` header line that is a policy, not a menu; a README line naming MIT plus "Your résumé JSON stays yours." Mika, row 3: "which licenses the Garden accepts, what the Garden may do with the file (commercial hosting, yes/no), and that attribution is displayed. A root LICENSE." Marcus's ownership question answered in one sentence. One outcome.

**What the rewrite added, judged line by line.**

- *`_blank.css` negative grep (no `BY-NC`, no "non-commercial").* This delivers Mika's actual complaint — line 5 today still reads `(e.g. CC BY-NC-SA 4.0, MIT)`. Cycle 2 only asserted that `CC BY 4.0` appeared; a body that left the NC example in place would have kept the menu. This is the AC that makes the scope-in line true. Pure value.
- *README License line AC; MIT standard-text greps; `Copyright (c) <year> <holder>` line.* Prove what was already promised. The holder is a human decision and is correctly parked in `## Notes` with a proposal; the intent's open question 3 permits MIT and flags anything else to the human — that is precisely what the body does.
- *Three named first-party files instead of the glob.* Correctness; `_blank.css` legitimately stops saying `License: MIT`.
- *Section-scoped greps (`## License` to next `## `).* Makes "in the License section" checkable. No scope.
- *Static probe `ZG-17/license-docs` in `probes.mjs`, and a sixth file in the diff AC.* A regression guard so ZG-18 and ZG-19 — both of which edit the same docs and depend on this item — cannot quietly reintroduce a hosted-page promise or a non-commercial example after the license is set. Test-only; no user-visible change. I accept the sixth file for that reason: the alternative is a license doc that drifts one PBI later.
- *DoD-compatible diff AC (`':!progress.md' ':!features.json'`).* Housekeeping.

**Scope creep?** None. The same five user-facing files. Non-goals unchanged: no hosted-page byline (named, with the reason and the place it would live), no CLA/DCO, no trademark policy, no privacy text. The terms still promise only the credit ZG-16 ships.

**Dependencies.** Still `ZG-16`; dependents ZG-18 and ZG-19 unchanged. Devon's chain is ZG-16 → ZG-17 → ZG-18, exactly as in cycle 2 — one small leaf ahead of his blocker, the price I accepted for a license doc that does not lie.

**Human decisions on this item, for the conductor.** Two, both already in `## Notes` and both one-line changes: the copyright holder, and MIT-only versus keeping `MIT OR Apache-2.0` in Cargo. Neither changes what Mika reads. Get the answers before AXEL starts ZG-17 so the `LICENSE` file is written once.

**BLESS ZG-17 — the rewrite makes the `_blank.css` policy line and the switcher-only promise falsifiable and guards them against the two dependent doc items; nothing beyond the same five user-facing files ships, the non-goals hold, and Devon's chain is unchanged.**

---

## Summary

| id | PO cycle 2 | QA cycle 2 | PO cycle 4 | user-visible scope changed | new deps | human decision pending |
| --- | --- | --- | --- | --- | --- | --- |
| ZG-6 | BLESS | REJECT | **BLESS** | no — one product rule added (sample click never overwrites stored résumé), string score | none (still ZG-5) | `ajv` devDependency (or `jsonschema` crate) |
| ZG-10 | BLESS | REJECT | **BLESS** | no — claim narrowed to what "About" means, hint is its own sentence | none (still ZG-7; two conditional edges avoided) | none |
| ZG-17 | BLESS | REJECT | **BLESS** | no — same five user-facing files | none (still ZG-16) | copyright holder; MIT vs dual in Cargo |

3 BLESS, 0 REJECT. All three proceed to the QA Architect.

## Non-blocking notes

These do not change product scope and do not withhold a BLESS.

- **Conductor — three human decisions sit on critical paths.** ZG-6 cannot go green without the `ajv` / `jsonschema` decision; ZG-17 cannot be written once without the holder name and the Cargo license choice. All three are already in `## Notes` per the intent. Put them to the human now, together, rather than one at a time when AXEL hits each probe.
- **Conductor — rank, not edge.** Move ZG-11 ahead of ZG-10 (or do not walk personas between them) so the first readout a persona sees on Switchyard matches its PDF. Do not add a ZG-10 → ZG-11 dependency; a chrome item should not wait on a themes item for correctness it does not own.
- **QA — ZG-6 `sample-not-stored`, third leg.** The product rule is stated as "editing the sample text and pressing Show it stores it exactly as a paste does." Please hold the probe to an *edit* (name changed) rather than an unedited Show it; whether an unedited sample pressed through Show it stores Jordan's file is a ZG-5 accept-path question and I do not want ZG-6 to pin it either way by accident.
- **QA — ZG-10 readout copy.** `estimateLabel` is pinned to `About 3 pages (A4)`. If ZG-7's plain-language pass settles on a different paper word for people like Elena (e.g. "A4 paper"), the label is the only place it must change; the formula and attributes are unaffected.
- **Carried from cycle 2, still true.** Do not walk personas between ZG-5 and ZG-6; the hosted-page Designer byline against ZG-21 remains an open idea for the human, not a round-1 promise.
