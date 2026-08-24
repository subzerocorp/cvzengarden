# AVRIL round 1 — Product Owner review (cycle 1)

**Role:** `product-owner-agent` (first adversary) · **Date:** 2026-08-23 · **Cycle:** 1
**Inputs read in full:** `docs/plans/round-1-avril-intent.md`, `docs/plans/round-1-avril-generator-round1.md`, the five round-0 reports (`docs/persona-rounds/round-0/*.md`), all 22 PBI bodies (`pinto show ZG-1 … ZG-22`), `ROADMAP.md`, `CONTEXT.md`, `qa/MARKET-QUALITY-BAR.md`.

Mandate: *Only PBIs that deliver clear user or business value in the thinnest honest slice earn BLESS; everything else is REJECT with a cut list.*

I ask only product questions. I do not rewrite bodies, touch the board, or judge code structure and test matrices except where they change what a persona sees.

---

## ZG-1 — Make the renderer pass clippy pedantic so `just verify` is green

Nobody in round 0 benefits from this directly, and the title is a chore, not an outcome. It earns its place for one reason only: every other PBI's Definition of Done is `just verify`, and it is red today, so no persona-facing slice can be honestly called shipped until this lands. Scope is the thinnest possible (renderer only, no behaviour change, no lint suppression) and the non-goals are honest. I would not accept a second item like this in the round.

**BLESS ZG-1 — the gate every persona slice is verified against is red; fixing it, and nothing else, is the honest enabler.**

## ZG-2 — Never panic on a wild date: tolerate timestamps, drop unparseable dates

Devon's fullwidth-digit crash and Marcus's silently lost talk date are real, and both protect every future paste (ZG-5) and hosted page (ZG-21). The user-visible promise is right: the entry always survives, the raw text is still shown, and a date that cannot be parsed no longer marks a job "current". Cutting non-English date words is honest. One shippable outcome.

**BLESS ZG-2 — a wild file's dates never crash or silently vanish; that is the exact complaint, no more.**

## ZG-3 — Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs

Marcus's whole résumé was rejected over `3.7`; that alone is worth the item. The rest are small, persona-cited, and share one outcome: "a file from the wild renders". The `work[].description` cut is stated with a reason (contract bump, not a bug), and "coerce only `score`, no evidence for more" is the right restraint. The `dir="auto"` / `rz-link-value` contract question is CTO territory and is flagged in notes.

**BLESS ZG-3 — a real person's file renders instead of failing on one number; every fix traces to a persona line.**

## ZG-4 — Run the Renderer in the browser via Wasm and prove it matches the crate

The title is solution-shaped and no persona will ever see this item. I accept it for a product reason, not an architectural one: the live site is static Netlify with no backend host authenticated, so in-browser rendering is the only way paste (ZG-5) reaches the deployed URL, and it makes "nothing leaves your browser" literally true — which matters to Priya (phone number) and Marcus (ownership). Its sole consumer is ZG-5, which immediately follows. Non-blocking: I would not bless a second horizontal layer in this round.

**BLESS ZG-4 — the only path to paste on the static site, consumed immediately by ZG-5, and it keeps the Author's data in the browser.**

## ZG-5 — Paste or open your own JSON Resume and see it in every Theme

This is Priya's, Elena's, and Marcus's blocker (A1) and the "not this round" line is honest (no editor, no PDF/LinkedIn import, no download headline). Elena's walk-away trigger (A4, cryptic errors) is met directly: plain sentences, line and column, no serde tokens, trailing-comma hint, "that is a PDF, this needs a JSON Resume". On its own it fully serves Marcus and Elena-with-a-file. It does *not* serve Priya alone: she opens "Use my résumé" and sees a textarea with nothing that says what to paste until ZG-6. That is an ordering concern (see set notes), not a bundling fault. Non-blocking copy nit: "Nothing leaves your browser until you publish" names a feature that does not exist until ZG-22; say "Nothing leaves your browser." until then.

**BLESS ZG-5 — the missing input step, with humane errors, in the thinnest honest form; Marcus and Elena can finish their first goal.**

## ZG-6 — Explain the résumé format in plain words and start from a sample

The Author half is exactly right: name "JSON Resume" once, show a copyable eight-line example, one-click "Start from a sample" — that is Priya's JSON-literacy test and Elena's "start from the sample" in one panel. But the item then bundles a second audience's outcome under the same id. The junior sample exists so Elena can see *her* thin résumé ("one bootcamp, three projects, and a retail job"); the body loads it with `basics.image` and a `portrait.svg` so *Mika* can proof `rz-photo`/`rz-score` (C8) on a real skeleton. A photo turns Elena's thin sample into a different kind of résumé, and it puts a line she must delete by hand into the file of the one persona who fears JSON errors. Two shippable outcomes for two audiences, one of which distorts the other.

Cut list: (1) the junior sample is Elena's — no `image`, no `portrait.svg`; a GPA is natural for a bootcamp grad and can stay. (2) Mika's `rz-photo`/`rz-score` proofing belongs in the designer kit (ZG-14 or ZG-19 as a designer-facing fixture), or is cut with a reason in the coverage matrix. (3) Non-blocking: the single sentence naming "JSON Resume" is cheap enough to live in ZG-5 so that slice stands alone for Priya.

**REJECT ZG-6 — bundles Mika's contract-coverage sample into Elena's thin starting sample; drop the photo/portrait from `junior.json`, move `rz-photo`/`rz-score` proofing to the designer kit or cut it with a reason.**

## ZG-7 — Rewrite the chrome in plain language with an About panel and a free-during-preview line

Elena "felt dumb", Priya clicked the wrong "Print" and mistook "CHROME" for her browser, and nobody could find the word "free". Every scope line maps to a quoted complaint; the replacement copy is the personas' own words; no price is invented (open question 4 respected). The About panel is thin and gives ZG-14 a home rather than smuggling designer links in here. One concern, non-blocking: the "Free during the preview" line lives only inside a closed dialog — Elena's round-0 search scanned visible chrome text and would still miss it; a one-line footer would answer her without a click (ZG-22 adds "free preview" next to Publish later, which closes the gap once it ships).

**BLESS ZG-7 — three personas' verbatim confusions removed with their own suggested words, and an honest "free during preview" with no invented price.**

## ZG-8 — Copy a link to this exact view and say so when a theme in the URL does not exist

Elena nearly took screenshots; three personas sent or would send the wrong theme in silence. Copy link, view-in-URL, and an "unknown theme" notice are one promise: the link you share means what you think. Not rewriting the URL (keeps the sender's intent) and not putting the Resume in the URL are the right non-goals. ZG-22 reusing the control is a reuse, not a smuggle.

**BLESS ZG-8 — a shareable link that says what it shows; the smallest slice that stops silent wrong-theme links.**

## ZG-9 — On a phone show the résumé first and fold the controls into a Theme button

Elena's friend on a 390px phone sees a control panel and asks "where's the résumé?". Résumé first, controls in a sheet, desktop unchanged — nothing more. Non-blocking: once ZG-5 and ZG-22 land, "Use my résumé" and "Publish" must be reachable inside that sheet; the AC only exercises the theme list.

**BLESS ZG-9 — the résumé is the first thing a phone shows; the controls survive as one button.**

## ZG-10 — Show an honest page count in print preview and how to save a PDF

The readout and the hint are the thin slice and both are asked for by name: Mika and Priya want "at least a 'N pages' readout / a hint before I print", Elena wants to know that "Save as PDF" lives in the dialog. The third scope line — page-boundary guide lines drawn as an overlay — is gold-plating that can mislead the very persona whose complaint this is. The preview is an unpaginated column; an overlay at multiples of page height cannot show where `break-inside: avoid` actually pushes content, which is precisely what a print designer looks for (and precisely E1). A line that says "the page breaks here" when it does not is worse than no line, and no AC checks it. The readout can honestly say "About"; a guide line cannot.

Cut list: move the guide-line overlay to scope_out with the reason "an overlay cannot reflect break-avoid pushes; wrong break lines mislead print designers"; keep the "About N pages (Letter|A4)" readout and the Save-as-PDF hint. Non-blocking: the dependency on ZG-7 is for label placement only and need not gate the value.

**REJECT ZG-10 — cut the page-boundary guide lines (unverifiable, misleading to Mika); ship the "About N pages" readout and the Save-as-PDF hint alone.**

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

The paper result is half of what job seekers pay for (BAR-J1), and today a senior résumé prints 70% blank on page 1, Switchyard loses bullets, and Nightgarden prints pale. Four personas hit it. Fixing break discipline on a real four-job fixture rather than on Jordan is the right product framing; keeping paper sizes and not touching screen or fonts are honest non-goals.

**BLESS ZG-11 — the printed page is the product; this makes the reference themes print a real résumé the way a hiring manager expects.**

## ZG-12 — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks

"Okafor-Lindqvist" overflowing its own rail, sections invisible to a recruiter's Cmd-A or a link crawler, and sub-bullets collapsing to one line are all Marcus's and Mika's words. Three fixes, one outcome: the screen theme shows the whole résumé correctly. Not inventing nested-list parsing is the right cut.

**BLESS ZG-12 — a real name and a full résumé are visible on screen without scrolling tricks; every fix is persona-cited.**

## ZG-13 — Self-host first-party theme fonts so a résumé page never calls jsDelivr

Minor for Marcus and Mika on the demo, but it becomes a hosted-page trust issue the moment ZG-21 exists: every visitor to Priya's public page would ping a CDN, and an offline print loses its face. Thin, and it answers the "what is the font allowlist" question with one sentence. Font binaries are flagged for human approval, as they should be.

**BLESS ZG-13 — a hosted résumé page that phones nobody; the smallest change that makes the trust copy in ZG-22 true.**

## ZG-14 — Serve and link the designer kit: sample HTML, contract, blank CSS, second sample

Mika and Devon only found `rz-*` because someone handed them a repo path; the served site 404s on everything a designer needs (BAR-D1 FAIL). Serving four files and linking them from About is the thin slice; no `/design` marketing page, no Markdown renderer. The BAR-D1 probe honestly prints PENDING until ZG-18 ships the submit link — good, no false pass.

**BLESS ZG-14 — a designer can reach the sample, the contract, and the blank file from the product; nothing beyond that.**

## ZG-15 — Try a local CSS file in the real switcher without a build

Mika proofed her theme by hand-editing HTML because the flagship experience needs npm and an Elm build. A file input, a blob URL, and the existing swap path give her the real switcher, print preview, and paper on her own file with no upload, no account, no persistence. That is exactly her ask and nothing more.

**BLESS ZG-15 — the flagship "flip a theme, print stays print" opens to the designers we are recruiting, with no build and no upload.**

## ZG-16 — Credit the Designer with name and link on every theme card

For a Zen Garden the byline is the point; today the `Author:` header is thrown away and there is no portfolio field. Name plus link on the card, no fake bylines, no profiles or avatars. Mika's blocker, thin.

**BLESS ZG-16 — the byline Mika will not work without, on the card where her theme is chosen, and nothing else.**

## ZG-17 — Add the repo LICENSE and state the theme-contribution license terms

Adding the MIT file the themes already declare and stating the contribution terms is the right, human-gated slice for Mika's "what rights am I handing over" and Marcus's missing LICENSE. The blocker is a promise the set does not keep. The `themes/README.md` text says attribution is "displayed in the switcher and on published pages' `<link>` comment". The switcher byline is ZG-16, which ZG-17 does not depend on; the published-page credit is delivered by no PBI at all — ZG-21's public page is deliberately a bare Skeleton plus `<link>`. Mika's exact condition for spending real hours is "whether attribution is guaranteed"; a license doc that guarantees something no item ships is the one thing we must not tell her.

What must change: (1) depend on ZG-16 so the switcher promise is true when stated; (2) either drop the "published pages" clause or deliver it (one HTML comment on ZG-21's public page — if the Generator chooses that, ZG-21 changes materially and goes back through the chain). Non-blocking: collapsing Cargo's `MIT OR Apache-2.0` to `MIT` is not persona-driven; it is correctly left to the human in notes.

**REJECT ZG-17 — promises attribution on published pages that no PBI delivers and a switcher byline it does not depend on; back both promises with ZG-16 (dep) and ZG-21 (credit comment) or drop the published-page clause.**

## ZG-18 — Give Designers a visible submit path with a stated review turnaround

Devon's walk-away in one sentence: "nowhere to put it and nobody who has said how long they'd take". A `CONTRIBUTING.md`, a PR template, a visible "Submit a theme" link, and a stated "we reply within 7 days" is the whole fix, and a PR being the Submission is lock 9. The number is a human commitment and is flagged. Non-blocking: "merged themes go live on the next deploy" is unbounded while deploys are manual; a sentence like "within N days of merge" or "deploys happen on <cadence>" would close Devon's real question fully.

**BLESS ZG-18 — Devon's blocker answered with a visible path and a number; a PR is enough this round.**

## ZG-19 — Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look

Devon shipped four pages of black ink because the paper rule lives only in the QA bar; Mika retyped §6 into `_blank.css` by hand; four docs disagree on fonts and `content:`. Putting the rule where designers read, scaffolding every selector with an `@media print` block, and marking the old backlog historical are all documentation of truths that already exist — no contract change. One outcome: designer docs stop contradicting the product.

**BLESS ZG-19 — the rules a designer is judged by, stated once, where they look; no new rules invented.**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

Devon could not tell whether `"$ "` and `counter()` were legal and had no lint to run. One local command that prints the same verdict a reviewer applies, no new dependency, not in CI. The `content:` rule operationalisation is QA's to confirm; the product need — a yes/no before the PR — is met.

**BLESS ZG-20 — the pass/fail Devon asked for, before he opens a PR, with no new dependency.**

## ZG-21 — Publish a résumé to a stable public URL with an unguessable edit link (API)

This is the paid product's spine (locks 7–8): hosted-plus-print, not export-HTML — exactly Marcus's test. The edit key is the account substitute lock 10 permits; no payments, no vanity slugs (cut with a reason Priya will accept: a link is her goal, `/priya` was her guess at the shape), no retention automation (stated honestly). Wrong key → 404, deleted → 410 "taken down", `noindex`, `no-store`: those are Priya's privacy answers made real. Serving `frontend/dist` from the same process is a convenience for running the whole product locally, not a second feature. It is the largest item in the set; if QA/CTO find it over the review bar, the static-serving lines are the natural seam. Non-blocking: the public page carries no credit for the Designer whose theme it wears (see ZG-17).

**BLESS ZG-21 — a stable URL that is yours, with delete and export, and nothing Phase 5 smuggled in; the thing job seekers pay for exists.**

## ZG-22 — Publish, copy your link, delete — with plain answers to who can see it

Priya's Publish/Copy link plus the sentence about her phone number, Marcus's delete and JSON export, Elena's "does hosting exist" (answered honestly with "not available on this build yet" on Netlify). It carries a lot, so I checked the seams: Publish without Delete would make "delete anytime" a lie; Publish without Update would force a delete-and-republish that changes the URL and breaks the LinkedIn link — the whole point is a stable link the Author controls. So the coupling is real and one promise. Download JSON and the footer Privacy link are small. Non-blocking: give the one-time edit link its own Copy button — Priya will lose it otherwise — and the retention/free wording is correctly left to the human.

**BLESS ZG-22 — the job seeker's goal end to end: publish, copy, control, take down, with plain trust answers and no invented policy.**

---

## Summary

| id | verdict |
| --- | --- |
| ZG-1 | BLESS |
| ZG-2 | BLESS |
| ZG-3 | BLESS |
| ZG-4 | BLESS |
| ZG-5 | BLESS |
| ZG-6 | REJECT |
| ZG-7 | BLESS |
| ZG-8 | BLESS |
| ZG-9 | BLESS |
| ZG-10 | REJECT |
| ZG-11 | BLESS |
| ZG-12 | BLESS |
| ZG-13 | BLESS |
| ZG-14 | BLESS |
| ZG-15 | BLESS |
| ZG-16 | BLESS |
| ZG-17 | REJECT |
| ZG-18 | BLESS |
| ZG-19 | BLESS |
| ZG-20 | BLESS |
| ZG-21 | BLESS |
| ZG-22 | BLESS |

19 BLESS, 3 REJECT.

## Set-level notes

### Coverage against the five personas

- **Priya** (JSON-literacy test, hosted link, privacy): ZG-5 gives the input step, ZG-6 names the format and gives her a copyable example and a sample, ZG-21/22 give the link and the "who can see it / delete" sentence. Covered — but only once ZG-6 lands (see ordering).
- **Elena** (humane errors, price, start from sample, thin sample): ZG-5 errors are plain and name the cause; ZG-2 makes bad dates tolerated rather than errors; ZG-7 says "free during preview"; ZG-6 (after fix) gives her the thin starting file. Her "download HTML with the theme included" workaround is correctly not built (lock 8); her need was "start from the sample", which ZG-6 covers.
- **Marcus** (hosted-plus-print, not export-HTML; retention; delete; JSON back; license): ZG-21/22 are hosted-plus-print; retention wording, delete, and export are in ZG-22; license in ZG-17. Covered.
- **Mika** (credit, license, submit, try-local, kit): ZG-16, ZG-17 (after fix), ZG-18, ZG-15, ZG-14. Her print-preview ask is honestly narrowed in ZG-10. Covered.
- **Devon** (submit path with turnaround, lint, print rule, renderer panics): ZG-18, ZG-20, ZG-19, ZG-2/3. Covered.
- **Phase-5 check (lock 10):** nothing sneaks in. The edit key (ZG-21) and `localStorage` persistence (ZG-5, ZG-22) are the permitted account substitutes; Wasm is lock 6. No payments, subdomains, PDF pipeline, AI, or LinkedIn import anywhere.
- **Coverage matrix:** I found no round-0 complaint without a PBI or a stated cut. The `work[].description` cut (ZG-3) and the true-pagination cut (ZG-10) both carry reasons.

### Ordering concerns that change user value (non-blocking, for the conductor and AXEL)

1. **Do not walk personas between ZG-5 and ZG-6.** After ZG-5 alone, Priya opens "Use my résumé" and sees a textarea that does not say what to paste — a worse first impression than today's "demo". Execute them back to back.
2. **ZG-13 before hosted pages are shown to anyone.** Without it every visitor to Priya's public page pings jsDelivr — Marcus's exact hosted-page complaint — and ZG-22's "no analytics / phones nobody" trust copy is not fully true. Consider making ZG-22 depend on ZG-13.
3. **ZG-11 before ZG-22.** Publishing and printing a real résumé with page 1 seventy percent blank is the paid product failing on day one. It is already a suggested first pick; keep it there.
4. **ZG-18 is gated behind ZG-7 → ZG-14.** Devon's blocker waits on a chrome copy rewrite. The sidebar "Submit a theme" link and `CONTRIBUTING.md` need only ZG-17 (and ZG-16 per my ZG-17 reject); BAR-D1 PASS can wait for ZG-14. The Generator may loosen the dependency.
5. **Priya's full path is nine items long** (ZG-1 → ZG-2/3/4 → ZG-5 → ZG-6, plus ZG-8, ZG-21 → ZG-22). That is the product, not gold-plating, but it means her round-1 walk cannot happen until the end of the round.

### Things I want the Generator to reconsider on blessed items (all non-blocking)

- **ZG-4** title is solution-shaped ("via Wasm"); the *why* carries the user need. Fine as is; I would not bless a second horizontal layer.
- **ZG-5** copy: "until you publish" references a feature that ships in ZG-22; say "Nothing leaves your browser." until then.
- **ZG-7**: put the "Free during the preview" line somewhere visible without opening About (a footer line), so Elena's page search finds it before ZG-22 exists.
- **ZG-9**: the mobile sheet must contain "Use my résumé" (ZG-5) and "Publish" (ZG-22) once they exist; the AC only proves the theme list.
- **ZG-18**: bound "go live on the next deploy" with a cadence or a day count while deploys are manual.
- **ZG-21**: the public page carries no credit for the Designer whose theme it wears; an HTML comment is the smallest honest byline for a Zen Garden's hosted page and is where my ZG-17 reject points. If added, ZG-21 goes back through the chain.
- **ZG-22**: a Copy button for the one-time edit link; and, for the CTO, `/?edit={id}:{key}` puts the key in server logs and history — a fragment (`#`) would not, and it is user-visible trust, not just architecture.
- **ZG-22 size**: product-wise one promise; if QA/CTO find it over the bar, the footer Privacy panel and Download-JSON are the follow-on seam, never Delete or Update.
