# AVRIL round 1 — Product Owner review (cycle 5)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-23 · **Cycle:** 5 (fresh review after the Generator's QA-driven revises, cycles 4 and 4b)
**Scope:** ZG-11, ZG-12, ZG-13, ZG-17, ZG-19, ZG-20, ZG-21 — the six ids QA rejected in cycle 3 and revised in `round-1-avril-generator-round4.md`, plus ZG-17, rejected by QA in cycle 4 and revised in `round-1-avril-generator-round4b.md`. My cycle-3 and cycle-4 blessings on them lapsed with the body edits; each is judged from scratch. No other id is touched.
**Inputs read in full:** `docs/plans/round-1-avril-po-round3.md` and `round4.md` (my last verdicts and the seams I named), `docs/plans/round-1-avril-qa-round3.md` and `round4.md` (why QA rejected), `docs/plans/round-1-avril-generator-round4.md` and `round4b.md` (what changed, helper ownership, dependency edges), `docs/plans/round-1-avril-intent.md`, the seven current bodies (`pinto show … --plain`), `pinto list --json` (graph, timestamps), and two cross-checks outside scope: ZG-14's copy step (already publishes `skeleton/samples/*.{html,json,svg}`, so ZG-19's new edge asks nothing new of ZG-14) and ZG-22's `api-errors` stub (`{"error":"name"}`, compatible with the body ZG-21 now pins).

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

The revise was driven by QA's oracles, not by me, so for each item I ask only product questions: is there still exactly one persona-traceable outcome; did the oracle rewrite (printable widths, a top-level résumé page helper, a rest state for Nightgarden's rise, lint rules, an error-body shape, LICENSE diff exclusions) add anything a user sees or promise anything the item does not ship; are the `scope_out` lines still honest about the tempting extras; did the new edges (ZG-12 → ZG-11, ZG-19 → ZG-14) or the helper ownership push a persona's path out unreasonably; and is any item now a review nobody can finish in ten minutes. I do not rewrite bodies, touch the board, or judge test mechanics except where they change what a persona sees.

---

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

**What the user sees.** Unchanged in kind, extended by one line: sections may break across pages, entries may not, no forced page before Projects in Switchyard, Switchyard's bullet bar prints, Nightgarden's four secondary colours print dark, and — new — Nightgarden's mint bullet dot prints as ink instead of vanishing. Jordan prints 2 pages in every theme (Quarto and Switchyard were 3); Marcus's four-job fixture prints ≤ 3 with page 1 ≥ 85 % full. Still E1 / E2 / E3, still Marcus, Priya, Mika, Elena.

**The one scope addition, judged.** The Nightgarden print marker. QA found that the cycle-3 AC held Nightgarden to an inked-marker assertion the scope never touched; the Generator put the marker in scope rather than exempting Nightgarden. That is the right product answer: a bullet that prints pale or not at all is Priya's E2 on a second theme, and "bullets print on every first-party theme" is one promise, not two. It is one `@media print` rule. `Covers` now says so honestly. Accepted.

**The oracle rewrite, judged as product.** `printableWidthPx` (682 / 673 / 720) and `openResumePage` are test infrastructure; nothing a persona sees changes. What matters to me is what they protect: the cycle-3 geometry probes measured the article at the chrome's width, so a fixture that clearly tripped E1 on paper could have passed the probe without ever proving the defect. Now the fixture is proven to break at paper width before the fix is judged, and `page1-fill` must FAIL on the pre-change sheets — which is the guard against the round-0 failure mode (testing print only on a résumé that fits). The `article-width` guard is the width assumption made honest. I accept the helper living here and ZG-12 depending on it: ZG-11 is dep-free and the first item I want AXEL to pick, so owning shared plumbing here costs no persona anything.

**Size.** This is the heaviest themes item: three sheets, a fixture pair with a cargo lock, five probe helpers, nine probes, two re-baselined constants. The CSS diff is small, the fixture HTML is generated and locked, and the probe code is one file. One shippable outcome — the printed page — and I judged it reviewable in cycle 3 with the same helper set minus one function; the additions are one width table, one guard, and one CSS rule. Still under the bar. If QA or the CTO disagree, the seam is unchanged: the fixture + lock + `paginate`/`openResumePage` helpers as a bounded, labelled `spike` prerequisite — never the CSS, which is the product.

**Non-goals.** Honest and sharpened: no widow/orphan tuning, no paper-size change, no PDF rasterisation (`pdftoppm` named as present-but-not-required), and now "nothing is measured inside the Garden iframe" with the reason. Fonts stay ZG-13's with the two-way re-check hand-off; name overflow and `rz-rise` stay ZG-12's.

**BLESS ZG-11 — the printed page is still the product and the only user-visible addition is Nightgarden's bullet printing as ink (E2 on a second theme, one rule); the width/top-level rewrite makes the fixture prove the defect on paper before the fix is judged, and owning the shared helper here costs no persona a day.**

## ZG-12 — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks

**What the user sees.** The same three screen fixes as cycle 3: Marcus's surname fits the rail, Cmd-A / crawlers / screenshots see every section without scrolling, and a highlight with embedded `\n` keeps its lines in all three themes. Marcus and Mika, E3 and D5.

**The one real product decision in the rewrite: the rest state.** QA showed that scope and AC contradicted each other — the cycle-3 body kept Chromium's below-fold sections at `opacity: 0` via `view()` + fill `both` while the probe demanded they be painted. The Generator decided it: the rise is declared only inside `@supports (animation-timeline: view())` with fill `forwards`, so an unentered section sits fully painted and the fade plays only while its top edge crosses into view; outside that block `.rz-section` has no animation. I checked what a human sees: a section below the fold is at opacity 1 while off-screen (nobody sees that), snaps to the `from` keyframe the instant it enters, and fades up over the first third of entry — the same rise as today from the reader's chair, and a painted page for Cmd-A, crawlers and screenshots. That is exactly the thinnest fix for Marcus's "wall of dark" that keeps locked decision 4 (motion is for screens), and `scope_out` now says in words that removing the rise was considered and rejected. Good.

**Dependency.** New edge ZG-12 → ZG-11 for `openResumePage`, with the honest secondary reason that both edit `themes/nightgarden.css` (print block first). ZG-12 leaves the ready-at-start set; Marcus's name fix now follows ZG-11. Since ZG-11 is the item I rank first among everything ready, this delays nothing in practice, and it removes a merge conflict on one file. Acceptable; it is an ordering fact, not smuggled scope.

**Bundle check.** The title names three fixes and the item is three fixes. I accepted that in cycles 1 and 3 because each is a few lines of CSS with no demo of its own, they share one persona and one sheet, and the contract note (highlights may contain `\n`) is the only prose. Nothing in the revise grows any of the three; the rewrite changed the proof and the rest state, not the surface. The title is honest about the bundle.

**Non-goals.** Unchanged and honest: no print rules, no nested lists from indented text (no markdown-in-JSON), no Quarto/Switchyard name sizing, no Firefox/WebKit install, BAR-L1 is ZG-13's, and the new line refusing to drop the rise.

**BLESS ZG-12 — the same three persona-cited screen fixes; the rewrite's only product decision (painted rest state, rise plays on entry, fill `forwards`) is the thinnest fix that honours the motion lock and says so in `scope_out`; the ZG-11 edge orders one file, it does not lengthen Marcus's path.**

## ZG-13 — Self-host first-party theme fonts so a résumé page never calls jsDelivr

**What the user sees.** Unchanged: a hosted or printed résumé page that fetches nothing from a third party, the same three faces, and one README sentence that answers Mika's font-allowlist question ("any https origin, self-hosted preferred").

**What the rewrite added.** Three things, none user-visible: `fallback` now ignores only the console errors its own route-abort causes (the convention ZG-4 already follows, stated here for future route-abort probes); the `@font-face` counts are pinned at 4 / 4 / 5 so "no face added or dropped" is checkable without git; and `fonts-load` also fails if any of the three families has a `FontFace` in `status === 'error'` — which is the one case that could have shipped a broken relative `url()` behind a working `local()` on the developer's machine and then fallen to a fallback face on every visitor's. That last one is the product promise (Marcus's page looks the same on his reader's laptop) made falsifiable. Accepted.

**Non-goals.** Unchanged and honest: no subsetting, no contributor font licensing (ZG-18), no typeface changes, and the reflow rule — a same-face swap must not move page counts; if it does the item returns to planning rather than editing constants. Font binaries remain a human approval in `notes`.

**Dependencies.** None; still ready at start. My cycle-3 ordering note stands: land this before any hosted page is shown to a persona.

**BLESS ZG-13 — a hosted résumé page that phones nobody, unchanged in scope; the revise made the fallback probe runnable and closed the one path by which a broken self-hosted URL could ship invisibly.**

## ZG-17 — Add the repo LICENSE and state the theme-contribution license terms

**What the user sees.** Unchanged from cycle 4: a root `LICENSE` (MIT), a `## License` section in `themes/README.md` that is a policy (MIT or CC BY 4.0; the Garden may host on free and paid pages; credit is the switcher byline from ZG-16; CC BY-NC refused, with the reason), a `_blank.css` `License:` line that is no longer a menu, and a README line naming MIT plus "Your résumé JSON stays yours". Mika's C3 and Marcus's ownership question, one outcome.

**What the rewrite changed.** Exactly three AC lines, verified by the Generator against a line diff: `':!.pinto'` joins the diff exclusions (the board file is git-tracked and must change when the item finishes — the AC was unsatisfiable, not the product); the AC now tells the implementer that the required hosting sentence must be phrased without the exact strings `hosted page(s)` / `published page(s)` so the negative grep and the scope sentence stop fighting; and a parenthetical says the standard first line `MIT License` satisfies `head -1`. None of the three touches a word Mika reads. The phrasing constraint is not a product cost: "the Garden may host Themes on free and paid pages" is clearer than either banned phrase.

**Non-goals.** Unchanged and honest: no hosted-page byline (named, with the reason and the place it would live), no CLA/DCO, no trademark policy, no privacy text.

**Dependencies.** Still ZG-16; dependents ZG-18 and ZG-19 unchanged. Devon's chain is ZG-16 → ZG-17 → ZG-18, as it has been since cycle 2. The two human decisions (copyright holder; MIT-only versus keeping the Cargo dual license) are still in `notes` and still one-line changes — they should be answered before AXEL starts the item so the file is written once.

**BLESS ZG-17 — the same five user-facing files and the same policy Mika asked for; the revise fixed a diff AC that could not pass on a finished branch and added nothing a Designer reads.**

## ZG-19 — Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look

**What the user sees.** Unchanged in kind: the paper rule stated where designers look (contract §2 and the themes README), a `_blank.css` with every §6 selector, a print block and a reduced-motion block, the §5.10 wrapper fix, one fonts sentence and one `content:` rule instead of four contradicting ones, and the proofing fixture `skeleton/samples/contract.{json,html}` on which `rz-photo` / `rz-score` can be proofed — now with a photo that actually loads. Devon's C6 (major), Mika's C6 / C8 / C7. One audience, one outcome: what a Designer reads and proofs against stops contradicting the product.

**What the rewrite added, judged.**

- *`basics.image = "portrait.svg"` as a sibling, an explicitly sized neutral SVG, `photo-loads`, a `curl` for the SVG, `src="portrait.svg"` in the lock.* Cycle 3's fixture shipped a broken image and no AC would have noticed — the one class the fixture exists to proof would have rendered as a broken icon for Mika. This is the fixture doing its only job. `scope_out` names the two rejected paths with the reason (a `samples/…` prefix 404s from the served directory; an absolute path breaks the from-disk proof). Pure correction, no scope.
- *Dependency ZG-19 → ZG-14.* The product reason is stronger than the test reason: Mika's C4 was "designer assets unreachable from the served site", and the README this item writes points her at the *served* `/skeleton/samples/contract.html`. A disk-only alternative would have satisfied QA but left the README pointing at a URL that 404s until ZG-14 lands. The edge makes the README true on the day the item closes. I checked ZG-14: it already copies `skeleton/samples/*.{html,json,svg}`, so the edge asks nothing new of ZG-14 and no scope is smuggled either way.

**Does the edge push a persona out?** ZG-14 depends on ZG-7, so ZG-19 and ZG-20 now transitively wait on the chrome plain-language pass. But ZG-18 — the item that actually unblocks Devon and Mika — already sat behind ZG-14 → ZG-7 and behind ZG-17 → ZG-16. The designer lane's longest chain is still four items (ZG-16 → ZG-17 → ZG-19 → ZG-20, or ZG-7 → ZG-14 → ZG-19 → ZG-20), and neither persona could be walked to a finish before ZG-18 in any ordering. So the edge changes which small items must land first, not when a Designer's walk can succeed. Ordering instruction for AXEL, not a blocker: ZG-7 first in the chrome lane, ZG-16 and ZG-17 first in the designer lane, then ZG-14, so ZG-18 and ZG-19 unblock together.

**Size.** This remains the heaviest docs item and the revise made the fixture slightly heavier (an SVG asset, one probe, one `curl`). I named the seam in cycle 3 and it is still the right one: the `skeleton/samples/contract.*` proofing fixture has its own small demo ("proof a photo and a GPA on a real Skeleton") and could stand alone as a Mika C8 item, which would also let the rest of ZG-19 drop the ZG-14 edge if `blank-readable` went disk-based. I am not forcing the split: the human-reviewed prose is a handful of sentences, the scaffold is mechanical, the fixture HTML is generated and locked, and QA judged the whole in one pass in cycle 3 without calling size. If the CTO calls it, cut the fixture out, not the paper rule.

**Non-goals.** Honest: no class or contract-version change, no edit to the RZ-2 byte-locked sample (the fixture is a superset copy), the lint is ZG-20's, the QA bar is QA's, and the new line on rejected image paths.

**BLESS ZG-19 — one Designer outcome, unchanged in scope; the revise makes the proofing fixture's photo actually load (its only job) and the ZG-14 edge makes the README's served link true on the day the item closes without lengthening any Designer's path to a finished walk.**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

**What the user sees.** Unchanged: one command, one verdict, an exit code that matches what the reviewer will say. Devon's four Cathode `content:` values still pass, `"Jordan Hale"` still fails, `"Page " counter(page)` is still a warning for a human. Devon and Mika, C7.

**What the rewrite added, judged as product.**

- *The universal selector is decided.* `*` is allowed anywhere in a selector anchored by `html` / `body` / `.rz-*` / `[data-rz-*]`; a selector made only of `*`/type/pseudo compounds is an error. This is the rule the first-party themes already live by (`html *::before`, `.rz-entry-header > *`), so it is the reviewer's real verdict, not an invented one — and it is the case a designer will hit on line one of almost every sheet (`*, *::before, *::after { box-sizing: border-box }` is an error; `html *, …` passes). Pinning it is the whole point of the item: no guesswork. Six unit cases make it deterministic. Accepted.
- *Lint runs first in `staticProbes()` with named `PASS`/`FAIL  ZG-20/lint` lines; the meta-test asserts those lines, not the exit code.* QA showed the cycle-3 meta-test passed with no lint wired at all. The rewrite makes "the verdict the reviewer applies" and "the verdict `just verify` applies" provably the same program. That is the business value here — a contributed theme cannot pass CI-by-hand and fail the reviewer, or vice versa. No user-visible change beyond the probe lines.
- *`url-origin` warns only on non-https absolute origins.* After ZG-13 every first-party sheet uses relative font URLs; without this a clean theme would have carried a spurious warning that makes Devon doubt a correct file. Copy quality, not scope.

**One non-blocking product note for the implementer.** The error *codes* are pinned; the *messages* are not. For `selector` the message must say what to do — name the anchors (`html`, `body`, `.rz-*`, `[data-rz-*]`) and show the fix for the bare-`*` reset — otherwise Devon gets a verdict without a reason, which is half of what he asked for. No AC change needed; the scope line already says every line carries a `<message>`.

**Non-goals.** Unchanged and honest: no full CSS parser (limits documented in the file), not in CI, no taste/size/contrast judgments. No new dependency (still ZG-19, which owns the `_blank.css` header the `header` warning reads).

**BLESS ZG-20 — the pass/fail Devon asked for, now deterministic on the one selector every designer writes first and provably the same program the harness runs; the revise added rules the first-party themes already obey, not new ones.**

## ZG-21 — Publish a résumé to a stable public URL with an unguessable edit link (API)

**What the user sees.** Unchanged: a stable `/r/{id}` that is Priya's to put on LinkedIn, an unguessable edit link that is the account substitute, `no-store` / `noindex` on the page, a 410 "taken down" after delete, and JSON export. B1's API half, Priya, Marcus, Elena.

**What the rewrite added, judged line by line.**

- *Ordered validation with a pure shape check and "422, never 500".* Elena's half-filled sections (`work: "nope"`) are the commonest real error and, in cycle 3, had no defined status — a 500 would have reached ZG-22's chrome as "try again" when the honest answer is "your `work` section is not a list". Now the API names the offending key for the top-level shape, and anything deeper that the renderer rejects is still a 422 with a plain sentence. A row is written only after the bytes render, so a stored page can never 500 on read. This is Priya's page never being half-broken and Elena's cryptic-error trigger not firing from the server side. Product-positive; no new endpoint, no new field.
- *Error body pinned: `{"error": <code>, "message": <sentence>}`, six codes, serde-token ban.* The shape is what ZG-22 shows on screen, so it belongs to the API's owner, and pinning it here keeps ZG-22 unchanged (I confirmed the stub `{"error":"name"}` and the real `{"error":"missing-name","message":"…name…"}` both satisfy ZG-22's "text contains `name`"). The `message` must contain the key / `name` / `line N column M` and never a serde token — ZG-5's ban list applied to the server. Same promise, other side of the wire.
- *No CORS layer; `no_cors` test; cross-origin named in `scope_out` as Phase 5.* A product decision I agree with: publishing works only where the backend serves the Garden, so ZG-22's "not available on this build" sentence on the static Netlify site stays true, and no third-party page can post résumés into our store. It also keeps the deploy question (open question 1) a human's, not a code default.

**Non-goals.** Honest and extended by two lines: cross-origin access and field-level schema validation (the renderer is the oracle; no `serde_path_to_error`-style crate). Accounts, payments, slugs, retention automation, stored HTML, deploy, Turso credentials all unchanged.

**Size.** This is the largest item in the set and the revise added one pure function, three tests, and a README paragraph. It is still one shippable outcome — a résumé gets a URL — and the growth is entirely the promise's own failure edges. I will not split it into a horizontal "static serving + `just serve`" layer with no demo of its own; the cycle-1 seam (static serving + `just serve` + `missing_dist_is_a_clear_error`, never key handling, 404-not-403, or the 410) remains the only honest cut if the CTO calls size, and AXEL's decomposition mode is the better tool than a planning-time layer. Human approvals in `notes` are unchanged (`sha2` / `rand`, retention wording).

**Non-blocking, carried forward.** The public page still carries no Designer credit; ZG-17 chose "drop the clause" and its `scope_out` says a hosted-page byline is a separate PBI if the human wants it. ZG-21's purity AC leaves room for an HTML comment, so the seam stays open. Not this round.

**BLESS ZG-21 — the paid product's spine, hardened only on the edges of its own promise (a server that never says 500 to a half-filled résumé, an error body the chrome can show in plain words, no cross-origin posting); nothing Phase 5 crept in and the size seam is unchanged.**

---

## Summary

| id | PO cycle 3/4 | QA cycle 3/4 | PO cycle 5 | user-visible scope changed | new deps | human decision pending |
| --- | --- | --- | --- | --- | --- | --- |
| ZG-11 | BLESS (c3) | REJECT (c3) | **BLESS** | yes, one line — Nightgarden bullet prints as ink (E2, second theme) | none (gains dependent ZG-12) | none |
| ZG-12 | BLESS (c3) | REJECT (c3) | **BLESS** | no — rest state decided: painted before entry, rise plays on entry | + ZG-11 (`openResumePage`, same sheet) | none |
| ZG-13 | BLESS (c3) | REJECT (c3) | **BLESS** | no | none | font binaries (unchanged) |
| ZG-17 | BLESS (c4) | REJECT (c4) | **BLESS** | no — three AC lines, no user-facing word | none (still ZG-16) | copyright holder; MIT vs dual in Cargo (unchanged) |
| ZG-19 | BLESS (c3) | REJECT (c3) | **BLESS** | no — the proofing photo now loads (its only job) | + ZG-14 (served paths; makes the README link true) | none |
| ZG-20 | BLESS (c3) | REJECT (c3) | **BLESS** | no — `*` rule matches what first-party themes already do | none (still ZG-19) | none |
| ZG-21 | BLESS (c3) | REJECT (c3) | **BLESS** | no — 422-never-500 and a pinned error body are the same promise, server side | none (still ZG-2, ZG-3) | `sha2`/`rand`; retention wording (unchanged) |

7 BLESS, 0 REJECT. All seven proceed to the QA Architect, then the Visionary CTO.

## Set-level notes (non-blocking; for the conductor and AXEL)

### Persona paths after the two new edges

- **Marcus.** ZG-12 (his surname) now follows ZG-11 (his print). Both are on the first thing I want AXEL to pick, so the cost is nil; the benefit is one `nightgarden.css` edited in order (print block first). Walk him on print and screen after ZG-11 + ZG-12 land together, not between them.
- **Devon / Mika.** ZG-19 and ZG-20 now transitively wait on ZG-7 → ZG-14 as well as ZG-16 → ZG-17. The designer lane's longest chain is still four items, and ZG-18 (their actual blocker) already sat behind both prerequisites, so no Designer walk can finish earlier under any ordering. **Execute ZG-7 first in the chrome lane and ZG-16, ZG-17 first in the designer lane**, then ZG-14, so that ZG-18, ZG-19 unblock together and ZG-20 follows immediately.
- **Priya / Elena.** Untouched by this cycle. The rule from cycle 1 holds: do not walk either persona between ZG-5 and ZG-6.

### Ordering that changes user value (restated, unchanged)

1. **ZG-11 first** among ready items; ZG-12 immediately after it.
2. **ZG-13 before any hosted page is shown to a persona.** ZG-22 still does not depend on ZG-13; without it, "phones nobody" is not fully true on Priya's page. Let AXEL order it; I do not need an edge.
3. **ZG-3's `dir="auto"` regenerates every crate-output lock** (`example.html`, `long-resume.html`, `samples/contract.html`). Whichever of ZG-11 / ZG-19 lands before ZG-3 needs its fixture regenerated when ZG-3 lands.
4. **ZG-11 ahead of ZG-10** (rank, not edge) so the first Switchyard page-count readout a persona sees matches its PDF.

### Cross-item facts the next adversaries should hold

- **ZG-22 must render `message` first, `error` as fallback.** ZG-21 now owns `{"error": <code>, "message": <sentence>}`; ZG-22's `api-errors` stub sends `{"error":"name"}` with no `message`. Both contain `name`, so ZG-22 needs no edit — but its implementer must prefer `message` or the real backend will show Elena the code `missing-name` instead of the sentence. ZG-22 is outside this cycle's scope; I flag it for the conductor.
- **ZG-20's `selector` message must name the fix** (anchors and the `html *` reset). Codes are pinned; messages are the implementer's, and this is the one designers hit first.
- **ZG-19 → ZG-14 asks nothing of ZG-14.** ZG-14 already copies `skeleton/samples/*.{html,json,svg}`; the edge is ordering only.

### Seams if QA or the CTO judge an item over the size bar

- **ZG-11:** fixture + cargo lock + `paginate` / `openResumePage` helpers as a labelled `spike` prerequisite — never the CSS.
- **ZG-19:** the `skeleton/samples/contract.*` proofing fixture (own demo: "proof a photo and a GPA"); if cut, `blank-readable` can go disk-based and the ZG-14 edge can drop with it.
- **ZG-21:** static serving + `just serve` + `missing_dist_is_a_clear_error` — never key handling, 404-not-403, or the 410. Prefer AXEL decomposition mode over a planning-time horizontal layer.
- **ZG-12, ZG-13, ZG-17, ZG-20:** none; each is already the thinnest slice.

### Human decisions still on critical paths (unchanged, restated so they are asked once)

`ajv` / `jsonschema` (ZG-6, Elena's path); copyright holder and MIT-vs-dual (ZG-17, three Designer items behind it); font binaries (ZG-13); `sha2` / `rand` and retention wording (ZG-21 / ZG-22, Priya's path); the Netlify build path after ZG-4. Put them to the human together before AXEL starts, not one at a time when a probe goes red.

### Phase-5 check (lock 10)

Nothing crept in. The no-CORS decision, the fragment edit key, `localStorage` persistence and the render-on-read rule remain the permitted account substitutes; no payments, slugs, PDF pipeline, AI, import, or cross-origin API anywhere.
