# AVRIL round 1 — Product Owner review (cycle 3)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-23 · **Cycle:** 3 (fresh review after the Generator's QA-driven revise)
**Scope:** the 13 ids whose bodies or dependencies changed materially in `round-1-avril-generator-round3.md` — ZG-1, ZG-3, ZG-4, ZG-5, ZG-7, ZG-8, ZG-11, ZG-12, ZG-13, ZG-19, ZG-20, ZG-21, ZG-22. (ZG-6, ZG-10, ZG-17 are with the Generator concurrently; not reviewed. ZG-2, ZG-9, ZG-14, ZG-15, ZG-16, ZG-18 are unchanged and keep their earlier marks.)
**Inputs read in full:** `docs/plans/round-1-avril-po-round1.md` (my cycle-1 rationales and non-blocking notes), `docs/plans/round-1-avril-generator-round3.md` (what changed, fixture ownership, dependency delta), `docs/plans/round-1-avril-qa-round1.md`, `docs/plans/round-1-avril-intent.md`, the five round-0 reports, the 13 current bodies (`pinto show … --plain`), and `pinto list --json` for the graph.

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

Prior blessings do not carry forward. For each item I asked only: did the QA-driven changes keep the slice thin and user-valuable, or did AC growth turn it into a bundle, a horizontal chore, or a review no one can finish in ten minutes? Did fixture ownership or new dependencies smuggle scope or push a persona's path out unreasonably? Are the `scope_out` lines still honest? I re-raise a cycle-1 non-blocking note only where the revise made it blocking. I do not rewrite bodies, touch the board, or judge test mechanics except where they change what a persona sees.

---

## ZG-1 — Make the renderer pass clippy pedantic so `just verify` is green

What changed: AC 4 is now "0 failed, no test removed, ≥ 19", AC 5 excludes the two harness tracking files from the "only `renderer/`" claim. Neither changes what ships; both stop the item contradicting its own DoD. Scope is still renderer-only, no behaviour change, no suppression. Nothing was smuggled in; the "tree-equality lock" wording is a correction of fact. Still the only chore I accept this round, for the reason given in cycle 1: every persona slice's Definition of Done is red until it lands.

**BLESS ZG-1 — the gate every persona slice is verified against is red; the revise fixed two self-contradictions and added nothing.**

## ZG-3 — Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs

What changed: the bad-URL/no-username profile now has an outcome (omit the `<li>`, and the empty `.rz-links`/`.rz-contacts` wrapper with it), publications-with-only-url mirrors certificates, integer `score`, the `javascript:`-plus-username shape, and a dependency on ZG-2 because both append to `renderer/tests/wild.rs`. Every addition is a case Devon or Marcus produced in round 0 and every one lands under the same promise: a file from the wild renders and never leaves an empty or unsafe node. The omit rule is a better answer for Devon than the cycle-1 "no `<a>`" — his complaint was the lonely `border-left` bar, and a label-only `<li>` would have drawn it again. `scope_out` is unchanged and still honest (`work[].description` cut with the contract reason; type coercion limited to `score`).

The new ZG-2 → ZG-3 edge serialises two renderer items that used to be parallel. Priya's and Elena's paths do not get longer in item count — ZG-5 already needed both — and ZG-4 still runs alongside. Acceptable.

**BLESS ZG-3 — every new AC is a persona-produced file rendering correctly under the one promise "wild input is valid input"; the ZG-2 dependency is file ownership, not scope.**

## ZG-4 — Run the Renderer in the browser via Wasm and prove it matches the crate

What changed: the parity oracle is now crate output produced in the same run (a `cargo` example on stdin/stdout, owned here), parity runs on three inputs, and two failure bounds were added — module load failure must reject with plain words and no uncaught exception, and Devon's 4.8 MB document must come back in ≤ 5 s. It also owns `frontend/fixtures/ada.json`. `scope_out` gained an honest line explaining why `skeleton/example.html` is not the oracle.

Product read: this is still a single horizontal layer with a single consumer (ZG-5), and I said in cycle 1 I would not accept a second one. The additions do not add product surface. The load-failure bound is the one I care about most: it is the surface Elena will see if the module ever fails to arrive, and "a plain message, never a stack trace" is the difference between her walking away and not. The size bound is a ceiling, not a feature. The example binary is a test oracle, not a shipped CLI, and is not headlined anywhere. `wasm-no-network` is the proof behind "nothing leaves your browser". The fixture and oracle ownership here keeps ZG-11 and ZG-21 free of a Wasm dependency, which is the right shape.

Non-blocking, unchanged from cycle 1: the title is solution-shaped; the `why` carries the need. Also unchanged: the note that Netlify's build image cannot run this build, so the live site's deploy path becomes a human decision the moment ZG-4 lands. That belongs in `notes`, where it is.

**BLESS ZG-4 — still the only path to paste on the static site, consumed immediately by ZG-5; the revise added a humane load-failure surface and a size ceiling, not a second feature.**

## ZG-5 — Paste or open your own JSON Resume and see it in every Theme

What changed: the PDF fixture is specified, the drop zone has probes, a `render-failed` class covers "parsed fine but could not draw", the serde-token ban applies to every error, content-first file classification is pinned, and corrupt `localStorage` is discarded silently. Scope grew, so I checked each line against the personas rather than accepting it as "hardening":

- Drop zone and `open-pdf`/`drop-pdf` → "that is `not-a-resume.pdf`, this needs a JSON Resume": Priya dragged her PDF onto the page in round 0 and got nothing. This is her exact moment. Keep.
- `render-failed` with "We could not draw this résumé": Elena's walk-away trigger is a cryptic error; a raw serde string surfacing after a successful parse is precisely that. Keep.
- Content-first classification (`.txt` with valid JSON renders; `.json` with a trailing comma says `line 1` and `comma`): a first-timer who saved the sample as `.txt` is served instead of scolded. Keep.
- Corrupt storage → Jordan, no banner: the one state a user cannot recover from without dev tools. Keep.

None of these is a second shippable outcome; all are the same control not lying to the same three people. `scope_out` is honest and unchanged (format explanation is ZG-6, publishing is ZG-21/22, no editor, no import, no download headline).

Non-blocking, carried from cycle 1 and still not applied: the sidebar copy "Nothing leaves your browser until you publish" names a feature that does not exist until ZG-22; the AC asserts only "Nothing leaves your browser", so the implementer can drop the clause without touching the card. And the ordering rule stands: do not walk Priya between ZG-5 and ZG-6.

**BLESS ZG-5 — every added path is a round-0 moment (Priya's PDF drag, Elena's cryptic error) handled in plain words under one control; still the thinnest honest input step.**

## ZG-7 — Rewrite the chrome in plain language with an About panel and a free-during-preview line

What changed: the `one-print` probe is pinned to a button name starting `Print /`, the "Print preview" View toggle keeps its name and `scope_out` says so, text probes use `textContent`, the GitHub link is asserted by string equality so `just verify` stays offline, and the print-on-white sentence is tied to the S3/U3 guard. No copy changed; no scope line was added.

Product check on the retained toggle: Priya's and Mika's "two things called Print" complaint was the filter chip versus the action button. With chips reading "For paper" and the action reading "Print / Save as PDF", the remaining "Print preview" toggle is a view name, not a third "Print". The `scope_out` reason given is test breakage; the persona reason is stronger (nobody complained about the toggle), but the line is honest either way.

Non-blocking, unchanged from cycle 1: "Free during the preview" lives only inside the About dialog; Elena's page-text search would still miss it until ZG-22 puts "free preview" beside Publish. The revise did not make this blocking.

**BLESS ZG-7 — three personas' verbatim confusions removed with their own words; the revise pinned selectors and changed no user-visible scope.**

## ZG-8 — Copy a link to this exact view and say so when a theme in the URL does not exist

What changed: a visible `Copy failed — select the address bar and copy it` state that never claims `Copied`, the empty `?theme=` no-notice case, and a probe that the echoed theme name is literal text. All three are the same promise — the link you share means what you think — protected on its failure edges. The copy-failed state is directly Elena: a silent "Copied" that copied nothing sends her back to screenshots. `scope_out` is unchanged and honest (no URL rewriting, no Resume in the URL, ZG-22 reuses the control rather than growing it).

**BLESS ZG-8 — the smallest slice that stops silent wrong-theme links, now honest when the clipboard says no; nothing added beyond the promise's own failure edges.**

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

What changed most in the set. The oracle moved from PDF rasterisation (tooling absent) to print-emulated geometry with two probe helpers; the fixture (`long-resume.json` + `.html`) is owned here and locked to crate output by a cargo test; the fixture must be proven to trip E1 before the fix is judged; `U3_PRINT_PAGES` is re-baselined to exact `{2, 2, 2}` for Jordan with a sibling `LONG_PRINT_PAGES ≤ 3`; all four pale-ink selectors and all three themes' bullet markers are asserted; `pdftoppm` is named in `scope_out` as present-but-not-required.

Product read, which is what I am here for: the CSS change is unchanged and small (sections may break, entries may not, no forced page before Projects, an inked Switchyard marker, four Nightgarden colours). The user-visible numbers are exactly the personas' expectations — Priya: "3 pages for a résumé that is really 2" → Jordan now prints 2 in Quarto and Switchyard; Marcus's four-job résumé at ≤ 3 pages with page 1 ≥ 85 % full. The fixture is named for Marcus and shaped like his file, and "prove it trips E1 first" guards against the round-0 failure mode of testing print only on a résumé that fits. The geometry helpers are test infrastructure, not product; they change nothing a persona sees, so they are QA's and CTO's to weigh, not mine. Owning the fixture here (not in ZG-4) keeps ZG-11 in the ready-at-start set, which matters because it is the first thing I want AXEL to pick.

`scope_out` is still honest: no widow/orphan tuning, no paper-size changes, fonts are ZG-13's, name overflow and `rz-rise` are ZG-12's, and the "whichever lands second re-checks the constants" hand-off with ZG-13 is stated on both cards.

**BLESS ZG-11 — the printed page is the product; the revise kept the CSS fix thin and turned the personas' page-count expectations into the exact numbers the item must hit.**

## ZG-12 — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks

What changed: the painted-before-scroll oracle is now Chromium-only (a static CSS-structure check plus a stripped-`@supports` runtime check plus a pixel threshold), `pre-line` compares against a sibling bullet, the phantom "BAR-L1 unchanged" claim was dropped with a reason, and the long name is injected by the probe rather than pulled from ZG-11's fixture (so no dependency). No user-visible scope changed: three CSS fixes, one contract note, same three complaints (Marcus's surname, Marcus's Cmd-A wall of dark, Marcus's sub-bullets). `scope_out` gained two honest lines — Firefox/WebKit install is a human decision, BAR-L1 is ZG-13's.

**BLESS ZG-12 — the same three persona-cited screen fixes; the revise changed how they are proven, not what ships.**

## ZG-13 — Self-host first-party theme fonts so a résumé page never calls jsDelivr

What changed: load is proven by `FontFace.status`, every `@font-face` URL is fetched, fallback is proven by aborting the font requests, this item now owns the `BAR-L1` distinctness probe, and its diff must not touch the print page constants — with the honest `scope_out` line that a reflow sends it back to planning rather than silently re-baselining. The README sentence still answers Mika's allowlist question in one line ("any https origin, self-hosted preferred").

Product read: unchanged and thin. Owning BAR-L1 here is right — self-hosting is the one change that can regress all three themes to the same fallback face, and Marcus's hosted-page trust ("every visitor's IP to jsDelivr") is the reason this must land before Priya's public page is shown to anyone. Font binaries remain a human approval in `notes`.

**BLESS ZG-13 — a hosted résumé page that phones nobody; the revise made the promise falsifiable and refused to let a reflow hide behind edited constants.**

## ZG-19 — Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look

What changed: the §6 expansion table is defined (5 contact types, 11 profile modifiers) so the scaffold test is deterministic; the `_blank.css` header fields are asserted and the item now depends on ZG-16 and ZG-17 so it edits that header last; the fonts sentence and the single-statement `content:` rule have greps; "readable" is a visibility probe. I also re-checked the cycle-1b addition that answers my ZG-6 reject: the designer proofing fixture `skeleton/samples/contract.json` / `.html` (Jordan plus `basics.image` and a `score`) so `rz-photo` / `rz-score` are proofable on a real Skeleton — where I said it belonged, in the designer kit, out of Elena's thin sample.

Is it a bundle now? It touches the contract, the README, the scaffold, a fixture, and a historical banner, but every piece serves one audience and one outcome: what a Designer reads and proofs against stops contradicting the product. Devon shipped black ink because the rule was elsewhere; Mika retyped §6 by hand and could not proof a photo. Nothing here changes a class or the contract version; `scope_out` says so and is honest. On review size it is the heaviest docs item in the set, but the fixture HTML is generated and test-locked, and the scaffold is mechanical; the human-reviewed prose is a handful of sentences. If QA or the CTO find it over the bar, the `samples/contract.*` fixture is the clean seam — it is the one part with its own small demo.

The new dependencies are the product cost. ZG-19 was ready at start; it now waits on ZG-16 and on ZG-17, which is still under revision and carries the human license question. Devon's print-honesty rule (his #3, major) therefore waits on a `License:` header line. The reason is real — three PBIs edit one file's header — and both prerequisites are small, so this is an ordering instruction for AXEL (ZG-16 and ZG-17 first in the designer lane), not a reason to reject.

**BLESS ZG-19 — the rules a designer is judged by, stated once where they look, plus the proofing fixture my ZG-6 cut sent here; one audience, one outcome, no contract change.**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

What changed: the selector rule now has complex-selector semantics with pass/fail unit cases (first-party `.rz-resume a` passes; `.btn`, `#root` fail); letters are `\p{L}{3,}`; a letter run beside `counter()` is a warning for the human reviewer rather than an error; `bad-theme.css` is exactly five lines with named errors and line numbers; `background-color` and unresolvable `var()` are covered; warnings exit 0, errors exit 1.

Product check against Devon's question, which is the whole item: Cathode's `"$ "`, `"▌"`, `"["`/`"]"`, and `counter(rz-sec, decimal-leading-zero)` all pass; `"Jordan Hale"` fails; `"Page " counter(page)` is a warning a human decides. That is the yes/no he asked for, and the warning tier is an honest answer to a genuinely ambiguous case instead of an invented rule. Exit-code contract means a warning does not block his PR. No new dependency, not in CI, no taste judgments — `scope_out` unchanged and honest.

**BLESS ZG-20 — the pass/fail Devon asked for, now answering his exact four `content:` values, with no new dependency and no invented rule.**

## ZG-21 — Publish a résumé to a stable public URL with an unguessable edit link (API)

What changed: the two privacy headers have tests on 200 and 410; wrong-key denial covers PUT and DELETE; PUT validates like POST; malformed ids are 404 before any store read; key entropy is asserted; unknown keys round-trip (§1.8); the 1 MiB boundary is exact; `just serve` runs the backend and a missing `frontend/dist` is a clear startup error; the edit key is accepted only in the `Authorization` header. No endpoint was added, no field was added to the table, and `scope_out` is unchanged (no accounts, payments, vanity slugs, retention automation, stored HTML, deploy).

Product read: every addition is the same promise — a URL that is yours, that nobody can alter or enumerate, that says who can see it — tested on its edges. `key_only_in_header` and `no-store`/`noindex` are Priya's phone-number answer made real, not architecture. It remains the largest item in the set; the number of named tests is now the review, and I stand by the cycle-1 seam if QA or the CTO call it over the bar: static serving plus `just serve` is the natural split, never the key handling or the 410.

Non-blocking, carried forward and now time-sensitive: the public page still carries no credit for the Designer whose theme it wears. My ZG-17 reject points at an HTML comment on this page as the smallest honest byline. If the Generator's ZG-17 revise chooses that route, ZG-21 changes materially and returns through the chain; its "exactly one `<link`, nothing else in the document" purity AC leaves room for a comment, so the seam is open.

**BLESS ZG-21 — the paid product's spine, hardened only on the edges of its own promise; nothing Phase 5 crept in and the seam for size is unchanged.**

## ZG-22 — Publish, copy your link, delete — with plain answers to who can see it

What changed: `SKIPPED` is forbidden and the probe harness starts the ZG-21 backend itself; a second click reads "Update" and reuses the id (never a second page); 413/422/5xx get a plain sentence with no spinner; Delete has a cancel; the edit link is now a fragment (`/#edit=id:key`) that never reaches the server and is cleared from the address bar on load; a tampered stored key is denied. `scope_out` gained the honest rejection of the `?edit=` query form with its reason.

Product read, item by item: "Update, not a second page" is the stable-link promise itself — Priya will click twice, and a second URL would break the LinkedIn link she already posted. "Delete then cancel keeps the page" is what "delete anytime" means to a nervous person. The fragment edit link is my cycle-1 user-visible-trust note adopted, and it is user-visible: her key is no longer in anyone's logs. The API-error sentences are Elena's cryptic-error trigger applied to the one button that talks to a server. All of it is the same promise — publish, copy, control, take down — surviving its own failure paths. Nothing new to demo; nothing added to headline.

Non-blocking, carried from cycle 1 and still open: the one-time edit link has no Copy button, and Priya will lose it (the stored key on the publishing browser softens this). The retention wording remains correctly flagged for the human. The cycle-1 seam stands if size is challenged: Download-JSON and the footer Privacy panel are the follow-on, never Publish/Update/Delete.

**BLESS ZG-22 — the job seeker's goal end to end, now honest on a second click, a cancelled delete, and a server that says no; the fragment edit link keeps her key out of every log.**

---

## Summary

| id | verdict | one-line rationale |
| --- | --- | --- |
| ZG-1 | BLESS | two self-contradictions fixed; still renderer-only, no suppression |
| ZG-3 | BLESS | every new AC is a persona-produced wild file; ZG-2 dep is file ownership |
| ZG-4 | BLESS | same single layer for ZG-5; added a humane load-failure surface, not a feature |
| ZG-5 | BLESS | drop zone, render-failed, file classes, corrupt storage are all round-0 moments |
| ZG-7 | BLESS | selectors pinned; no copy or scope change |
| ZG-8 | BLESS | copy-failed state stops the silent "Copied" that sends Elena to screenshots |
| ZG-11 | BLESS | CSS fix unchanged; persona page-count expectations are now exact numbers |
| ZG-12 | BLESS | same three screen fixes; only the proof changed |
| ZG-13 | BLESS | falsifiable now; a reflow returns to planning instead of editing constants |
| ZG-19 | BLESS | one designer outcome incl. the proofing fixture my ZG-6 cut sent here |
| ZG-20 | BLESS | answers Devon's exact four `content:` values; warnings do not block a PR |
| ZG-21 | BLESS | same promise on its edges; static-serving seam unchanged |
| ZG-22 | BLESS | update-not-duplicate, delete-cancel, fragment key are the promise surviving failure |

13 BLESS, 0 REJECT.

## Set-level notes (non-blocking; for the conductor and AXEL)

### Persona paths after the dependency delta

- **Priya / Elena (Author lane).** Critical path is now serial through the renderer: ZG-1 → ZG-2 → ZG-3 → ZG-5 → ZG-6, with ZG-4 alongside ZG-2/3 and ZG-21 startable as soon as ZG-3 is done. Item count is unchanged; one pair that was parallel is now sequential. Priya's full walk still lands at the end of the round (ZG-22). The cycle-1 rule holds: **do not walk either persona between ZG-5 and ZG-6** — after ZG-5 alone, "Use my résumé" opens a textarea that does not say what to paste.
- **Marcus.** ZG-2/3 (his file renders), ZG-11 (his four-job print), ZG-12 (his name), ZG-13 (his hosted-page trust), ZG-21/22 (his URL, delete, export). ZG-11/12/13 are ready at start; walk him on print and screen early, on hosting at the end.
- **Mika.** Unchanged except ZG-19 now follows ZG-16 → ZG-17. Her blocker (ZG-16 credit, ZG-18 submit) is unaffected.
- **Devon.** His blocker (ZG-18) was already behind ZG-17 and ZG-14 → ZG-7. His major C6 (print-honesty rule, ZG-19) and minor C7 (lint, ZG-20) now also wait on ZG-16 → ZG-17. **Execute ZG-16 and ZG-17 first in the designer lane** — both are small — so ZG-18, ZG-19, and ZG-20 all unblock together. If ZG-17's revise drags on the human license decision, the conductor should surface it; it is now on three Designer items' critical path.

### Ordering that changes user value

1. **ZG-11 first** among ready items. Publishing and printing a real résumé with page 1 seventy percent blank is the paid product failing on day one.
2. **ZG-13 before any hosted page is shown to a persona.** ZG-22 still does not depend on ZG-13; without it, ZG-22's "no analytics / phones nobody" trust copy is not fully true and Marcus's jsDelivr complaint reappears on Priya's page. Either add the dependency or let AXEL order it; I do not need the card changed.
3. **ZG-5 and ZG-6 back to back** (above).
4. **ZG-3's `dir="auto"` regenerates every locked crate-output fixture.** ZG-11 (`long-resume.html`), ZG-19 (`samples/contract.html`), and ZG-3 itself (`skeleton/example.html`) all byte-lock crate output; whichever of ZG-11/ZG-19 lands before ZG-3 will need its fixture regenerated when ZG-3 lands, and ZG-3's AC names only `example.html`. This is an execution-order fact, not a product defect; AXEL should run the regeneration hooks (`RZ_UPDATE_FIXTURES=1`, the acceptance lock) as part of ZG-3 if it lands second.

### Seams if QA or the CTO judge an item over the size bar

- **ZG-21:** static serving of `frontend/dist` + `just serve` (never key handling, 404-not-403, or the 410 page).
- **ZG-22:** Download-JSON and the footer Privacy panel (never Publish/Update/Delete or the trust sentence beside Publish).
- **ZG-19:** the `skeleton/samples/contract.*` proofing fixture (it has its own small demo: "proof a photo and a GPA").
- **ZG-5:** none I would take — every path traces to a round-0 moment.

### Cycle-1 non-blocking notes, status after the revise

| note | status |
| --- | --- |
| ZG-4 title is solution-shaped | unchanged; `why` carries the need — fine |
| ZG-5 "until you publish" copy | not applied; AC asserts only "Nothing leaves your browser" — implementer can fix |
| ZG-7 "Free during the preview" visible without a click | not applied; ZG-22 closes it beside Publish — still non-blocking |
| ZG-21 no Designer credit on the public page | open, tied to the concurrent ZG-17 revise; ZG-21's purity AC leaves room for a comment |
| ZG-22 Copy button for the one-time edit link | not applied; still non-blocking |
| ZG-22 `?edit=` in server logs — use a fragment | **adopted** (`/#edit=…`, `replaceState`, header-only key) |
| ZG-6 photo/`rz-score` proofing belongs in the designer kit | **adopted** in ZG-19 (`skeleton/samples/contract.*`) |

### Phase-5 check (lock 10)

Nothing crept in during the revise. The fragment edit key and `localStorage` persistence remain the permitted account substitutes; the `cargo` render example is a test oracle, not a product CLI; no payments, slugs, PDF pipeline, AI, or import anywhere. Human approvals still pending in `notes`: font binaries (ZG-13), `sha2`/`rand` (ZG-21), retention wording (ZG-22), the Netlify build path after ZG-4.
