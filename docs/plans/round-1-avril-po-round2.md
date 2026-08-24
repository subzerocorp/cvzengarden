# AVRIL round 1 — Product Owner review (cycle 2)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-23 · **Cycle:** 2 (fresh review of revised items)
**Scope:** ZG-6, ZG-10, ZG-17, ZG-19 only — the four items whose body or dependencies changed in the Generator's revise pass. Cycle-1 blessings on these four do not carry; each is judged from scratch. The other eighteen items are untouched and keep their cycle-1 PO verdicts.
**Inputs read in full:** `docs/plans/round-1-avril-po-round1.md` (my cycle-1 blockers), `docs/plans/round-1-avril-generator-round2.md` (what changed and why), `docs/plans/round-1-avril-intent.md`, `docs/persona-rounds/round-0/{elena,mika,devon,priya}.md`, `pinto show ZG-6 ZG-10 ZG-17 ZG-19 --plain`, `pinto show ZG-14 ZG-16 ZG-18 ZG-21 --json` (dependency context), plus `pinto show ZG-3 ZG-4 ZG-5 --json` and `renderer/src/emit.rs` lines 113–124 to check two facts that bear on what a persona would see.

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

For each item I ask three things: did the revise remove my blocker, did it smuggle anything new under the same id, and is what remains still the thinnest honest slice with honest non-goals. I do not rewrite bodies or touch the board.

---

## ZG-6 — Explain the résumé format in plain words and start from a sample

**Cycle-1 blocker:** the junior sample bundled Mika's contract-coverage fixture (`basics.image` + `portrait.svg`) into Elena's thin starting file — two audiences, one id, and a line the JSON-averse persona would have to delete by hand.

**Did the revise address it?** Yes, completely and with nothing added. `junior.json` is now stated to be Elena's file: `basics` has no `image`, there is no `portrait.svg`, and the scope-in line says outright "nothing in the file a first-timer must delete by hand". The cut is made falsifiable rather than silent: `ZG-6/start-junior` now asserts **no** `.rz-photo`, and a new AC checks `grep -c '"image"' skeleton/samples/junior.json` prints `0` and that ZG-6 adds no image file under `skeleton/samples/`. `## Why` and `## Covers` drop Mika and C8. Scope-out names the photo as a non-goal with a reason and a pointer to where proofing went (ZG-19). Dependencies unchanged (ZG-5).

**Persona check.** Elena, row 12: "My résumé is one bootcamp, three projects, and a retail job. I can't tell what a thin résumé looks like in any of these themes." The sample is now exactly that — bootcamp, one retail job, three projects, GPA, no awards/publications/references — and `ZG-6/junior-all-themes` proves it in every theme at 1280px and on paper. Priya, row 2: "If the answer is 'JSON Resume' it is never said." One sentence naming it, a link, a copyable 8–12 line example with a Copy button. Elena, row 1: "Use this sample as a starting point" — "Start from Jordan's sample" / "Start from a short sample". Every scope line still maps to a quoted complaint.

**Thinnest slice?** Yes. The remaining pieces — name the format, one copyable example, two one-click samples, one thin fixture locked to the Renderer — are the minimum that lets a first-timer begin. Non-goals are honest: no form editor, no PDF/DOCX/LinkedIn conversion, no in-place editing, no byte-lock change. One audience, one outcome.

**Dependency sanity.** The junior sample keeps a numeric `score: 3.7`, which the Renderer only accepts once ZG-3 lands. ZG-6 → ZG-5 → ZG-3 is on the board, so the "Start from a short sample" button can never ship ahead of the fix that makes it render. Covered.

**BLESS ZG-6 — the junior sample is now Elena's file and nothing else; the photo cut is enforced by AC, and a first-timer can name the format, copy an example, and start from a résumé shaped like her own.**

## ZG-10 — Show an honest page count in print preview and how to save a PDF

**Cycle-1 blocker:** page-boundary guide lines drawn as an overlay on an unpaginated column cannot show where `break-inside: avoid` actually pushes content; a wrong break line misleads exactly the print Designer this item serves.

**Did the revise address it?** Yes. Scope-in line 3 (the overlay) is gone. The first scope-out line now states the cut with the reason verbatim, so nobody re-adds it later without re-arguing it. The AC that existed only to police the overlay's injection (`no-skeleton-injection`) is replaced by `ZG-10/no-guide-lines`, which asserts `.garden-stage--print` contains no overlay element and the iframe holds nothing beyond the Skeleton and the theme `<link>` — the cut is now falsifiable. Nothing new was added; readout AC, paper-size AC, updates AC, and hint AC are unchanged.

**Persona check.** Mika, row 5: "or at least a 'N pages' readout next to the Print button" — that is the readout. Priya, row 5: "at least a hint before I print that it will be N pages" — same. Elena, row 9: "a hint 'Choose Save as PDF in the dialog'" — that is the hint, word for word. The readout says "About", which is the honest word for an estimate; `estimate-matches-pdf` holds it to ±0 on the two print themes.

**Thinnest slice?** Yes — one readout, one sentence. Non-goals are honest and now complete: no guide lines, no true pagination (third-party runtime), no server PDF pipeline, no exact fidelity claimed. The dependency on ZG-7 remains for label placement; I said in cycle 1 that this need not gate the value, and I still think so, but it is not a blocker and the Generator was right to leave it for QA/CTO.

**BLESS ZG-10 — the misleading overlay is cut with its reason on record and an AC that proves its absence; what ships is the "About N pages" readout and the Save-as-PDF hint three personas asked for by name.**

## ZG-17 — Add the repo LICENSE and state the theme-contribution license terms

**Cycle-1 blocker:** the terms promised attribution "on published pages' `<link>` comment" — which no PBI delivers — and a switcher byline that ZG-17 did not depend on. Mika's exact condition for spending real hours is "whether attribution is guaranteed"; a license doc that guarantees something no item ships is the one thing we must not tell her.

**Did the revise address it?** Yes, by the option I would have chosen. The published-page clause is dropped, ZG-17 now depends on ZG-16, and the License section promises exactly what ZG-16 ships: name + link from the `Author:` / `URL:` header lines, displayed on the theme's card in the switcher. `## Why` now carries the rule that the terms may only promise the credit the product actually shows. Scope-out names the hosted-page byline as an explicit non-goal, with the reason (ZG-21 serves a bare Skeleton plus `<link>`) and where it would live if the human wants it (a separate PBI against ZG-21). A new AC enforces the promise in both directions: `switcher` must appear inside the License section, and `published page|hosted page|<link> comment` must appear nowhere in `themes/README.md`.

**Was dropping honest to Mika?** Her row 3 asks for "that attribution is displayed"; her row 2 fix is "Designer name and a link under each theme in the switcher". The switcher is where a theme is chosen and where she will look. The Generator is right that the `<link>`-comment clause was its own cycle-0 invention, not a persona line, and that delivering it would have reopened ZG-21 — the largest item in the set — for a credit nobody asked for. The terms are now narrower and true, which is what a designer deciding whether to hand over rights needs. The hosted-page byline is carried forward as an open, separate idea, not smuggled and not promised.

**Scope creep?** None. Same five files; the "No file outside … changes" AC still holds. The `MIT OR Apache-2.0` → `MIT` collapse and the CC BY 4.0 / MIT choice remain correctly parked for the human (open question 3).

**Dependency cost.** ZG-16 is a leaf and small; the designer chain becomes ZG-16 → ZG-17 → ZG-18. Devon's blocker (ZG-18) waits one small item longer. That is the price of not lying in a license doc, and I asked for it.

**BLESS ZG-17 — the terms now promise only the credit ZG-16 ships and depend on it; the unbacked published-page clause is gone, named as a non-goal with a reason, and guarded by AC.**

## ZG-19 — Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look

**Why it is here:** not rejected in cycle 1; it received the `rz-photo` / `rz-score` proofing fixture that my ZG-6 reject sent out, so its body changed materially and its blessing lapsed. I offered ZG-14 or ZG-19 as the home; the Generator chose ZG-19.

**Is the fixture real user value or a smuggle?** Real, and persona-cited. Mika, row 8: "§6 lists `rz-photo`, `rz-photo-img`, `rz-score`; none exist in `example.html`, so I cannot proof a photo treatment or a GPA line against the real skeleton … Either a second sample with `basics.image` + `education[].score`, or those nodes present in `example.html`." The fixture is the first of her two options exactly: Jordan's file plus those two fields, rendered by the crate and locked. The byte-lock on `example.html` is left alone (scope-out, plus an AC that `git diff --stat` is empty), and the superset assertion — every `rz-*` class in `example.html` must also appear in `contract.html` — prevents the fixture from forking into a second reference sample. That is the right non-goal for a one-Skeleton product.

**Does ZG-19 remain one outcome?** Yes. The item was already "the rules a designer is judged by, stated once, where they look" and it does not invent rules: the Renderer already emits these classes (`emit.rs` 113–124), so the fixture documents a truth that exists, the same way the `_blank.css` scaffold enumerates §6 on the CSS side. The C8 row is now covered in full under one id instead of being split across ZG-6 and ZG-19. Choosing a neutral vector portrait rather than a photograph is a good product call — no real face in a public sample.

**Did the Generator choose the right home?** ZG-14 is a serve-and-link item that already copies `skeleton/samples/*` when present, so it needs no change and keeps its blessing; a fixture-and-docs change belongs with the fixture-and-docs item. Agreed.

**Size and non-goals.** One JSON superset, one locked HTML, one SVG, one acceptance-test case, one node assertion, one README line, on top of the existing doc edits. Still reviewable in one pass, still no contract change, still no lint (ZG-20) and no QA-bar rewrite. The dependency list stays empty, which keeps it a ready-at-start item for the designer path.

**BLESS ZG-19 — Mika's proofing fixture lands where the other designer fixtures live, as a locked superset that cannot fork the sample; every §6 class is now proofable on a real Skeleton and the item still states only rules that already exist.**

---

## Summary

| id | cycle-1 | cycle-2 | blocker addressed | new scope smuggled |
| --- | --- | --- | --- | --- |
| ZG-6 | REJECT | **BLESS** | yes — photo/portrait removed, cut enforced by AC | no |
| ZG-10 | REJECT | **BLESS** | yes — guide lines cut with reason, absence proven by AC | no |
| ZG-17 | REJECT | **BLESS** | yes — published-page clause dropped, ZG-16 dependency added | no |
| ZG-19 | BLESS (lapsed) | **BLESS** | n/a — received the ZG-6 fixture, persona-cited, superset-locked | no |

4 BLESS, 0 REJECT. All four items proceed to the QA Architect.

## Non-blocking notes

These do not change product scope and therefore do not withhold a BLESS, but the next two adversaries should see them.

- **ZG-6, for QA — a self-contradicting AC pair.** The junior sample keeps a *numeric* `score: 3.7` while another AC requires the file to validate against `jsonresume/resume-schema` `schema.json`, where `score` is a string (the contract's own §5 snippet writes `"score": ""`). Both cannot pass. Product-wise the right resolution is the string form: this is the file we hand Elena next to a link to the schema, so it should be the canonical well-formed shape, not a wild-file shape (that is Marcus's case, and it belongs in ZG-3's tests). Going string also removes the only reason ZG-6 needs ZG-3, though the transitive dependency through ZG-5 is harmless. One character, no scope change.
- **ZG-19, for QA — prove the portrait actually renders.** The fixture's `basics.image` is a relative `samples/portrait.svg`, and `contract.html` lives *in* `skeleton/samples/`, so as written the `src` would resolve to `skeleton/samples/samples/portrait.svg` and Mika would proof a broken-image glyph. The Renderer passes the value through verbatim (`emit.rs:120`), so a path relative to the HTML's own directory works. The AC only greps for the `rz-photo-img` string; it should also assert the image loads (Playwright `naturalWidth > 0`) from both the served `/skeleton/samples/contract.html` and wherever the switcher's sandbox would load it. The outcome Mika needs is a visible photo treatment, not a class name.
- **ZG-17, for QA — the negative grep constrains phrasing.** `grep -i -E "published page|hosted page|<link> comment"` must print nothing, so the License section cannot use the phrase "hosted page" even to say honestly that hosted pages carry no byline today. The scope-in already says "the Garden may host them on free and paid pages", which passes. If the human wants the README to state the hosted-page gap explicitly, the AC will need loosening; as a product matter, promising less and stating it precisely ("on the theme's card in the switcher") is enough for Mika.
- **ZG-14, for the conductor — a link, not a change.** ZG-14's About panel lists "Second sample (when present)"; with ZG-19 there will be two samples under `skeleton/samples/` (`junior.html`, `contract.html`). ZG-14 is unchanged and blessed, and `themes/README.md` (ZG-19) names `contract.html` as the proofing file, which is where Mika reads. No action required this round; if ZG-14's link wording turns out to point only at the junior sample, that is a one-line follow-on.
- **Ordering (carried from cycle 1, still true).** Do not walk personas between ZG-5 and ZG-6; ZG-16 → ZG-17 → ZG-18 now adds one small leaf ahead of Devon's blocker, which is acceptable; the hosted-page Designer byline against ZG-21 remains an open idea for the human, not a round-1 promise.
