# ZG-12 GAN report

PBI ZG-12 — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks. Phase 1 of 1. Working tree on `garden/persona-loop`, uncommitted; base `72596c7`.

Independent verification by the adversaries (2026-08-24):
- `cd frontend && npm run test:unit` — 106 pass, 0 fail.
- `PROBE_PORT=4365 npm test` — exit 0, 90 PASS, 0 FAIL/SKIP; all nine ZG-12 lines PASS with the same numbers as the evidence; ZG-11 page counts 2/3 for all three themes; the 18 live `ZG-11/*` PASS lines are byte-identical to the ZG-11 phase-2 evidence.
- `RZ_ZG12_BASE=72596c7 PROBE_PORT=4366 node scripts/probes.mjs` — exit 1, 7 FAIL (all ZG-12, none elsewhere), lines verbatim as in `/tmp/persona-lab/conductor/zg-12-evidence.md`.
- `PROBE_PORT=4367 just verify` — exit 0.
- Visual: `/tmp/persona-lab/zg12-gan/name-{1280,390}.png` (Nightgarden, `.rz-name` = "Marcus Okafor-Lindqvist Jr." via `openResumePage`).

## Phase 1 — Reviewer

CSS (`themes/nightgarden.css`)
- `.rz-identity { container-type: inline-size }` + `.rz-name { font-size: clamp(1.85rem, 11cqi, 3.1rem) }`: sizing off the rail rather than the viewport is the right axis (the rail is `minmax(15rem, 18.5rem)` at 1280 and full-width at 390, so a `vw` clamp cannot know the rail). At 1280 the name computes 32.56px and breaks on the hyphen into three lines, 296/296px; at 390 it is 39.0px, three lines, 355/355px. `overflow-wrap: anywhere; hyphens: auto` are the belt for a single unhyphenated surname. `container-type: inline-size` on `.rz-identity` does not change its layout (it is a block child of a sticky header; no `contain: size` side-effect on the inline axis). Comment explains the choice. Good.
- `rz-rise`: the top-level `.rz-section { animation: … both }` and the six `nth-of-type` delay rules are gone; the only `rz-rise` declaration is inside `@supports (animation-timeline: view())`, written as longhands with `animation-fill-mode: forwards`. The comment's rationale ("the shorthand would reset animation-timeline") is correct: `animation` resets `animation-timeline`/`animation-range` to their initial values, so longhands are the only safe form when the timeline is declared in the same block. Ordering is also correct (timeline declared after the name/duration longhands).
- Nothing else in the sheet changed: the diff hunks are exactly `.rz-identity`, `.rz-name`, the `.rz-section` block, the pre-line rule and the `@supports` block. `@keyframes rz-rise/rz-foxfire/rz-name-sheen` (lines 68/80/90), the sheen (178), the foxfire (268) and the print/reduced-motion guard (401–410) are outside every hunk, i.e. byte-identical.
- `white-space: pre-line` on `.rz-bullet, .rz-prose p` in all three sheets, placed with the bullet rules and before any `@media` block; no later `white-space` rule targets those selectors (Quarto's `white-space: normal` at :247 is `.rz-dates`). Same comment text in all three — fine, it cites the contract section.

Contract (`skeleton/CLASS-CONTRACT.md` §5.3): one additive sentence under the `.rz-entry-primary` note, before the class table. Uses "should", which matches the PBI's wording; it is a recommendation, not a new required class or attribute. Correct location.

JS — `lib/css-structure.mjs`
- `blankComments` keeps indices aligned so `withoutViewSupports` can slice the original text; verified by the scratch script that the real sheet loses exactly the `@supports` block (11148 → 10517 bytes, keyframes/sheen/foxfire/guard retained, no `animation-timeline: view` left). The preceding explanatory comment is removed with the block because `start` is the post-`;`/`}` boundary — intentional and harmless.
- `topLevelBlocks` handles: comments containing `;`/`{` (blanked), top-level `@import …;` (boundary reset), nested at-rules (depth counter), unterminated block (returns nothing, no throw), empty input.
- `parseRules` strips comments before scanning, skips `@keyframes` bodies at any nesting (so percentage selectors never appear as rules — verified), records the context chain so `@media` inside `@supports` still counts as "inside view() supports" (`context.some`).
- Predicates are small, named, pure; message strings are built by one `describe`. Reads well.
- Nits (not blocking, module is scoped to nightgarden.css by ZG-12): (1) `parseDeclarations` on a chunk with no `:` does `chunk.slice(0, -1)` — property "fo" for "foo". Harmless but a tell-tale of `indexOf` -1 not being guarded. (2) String literals are not tokenised: `content: "{"` would desync the brace matcher (scratch test returned `[]`). Nightgarden only has `content: ""`; if ZG-20 reuses this for a general lint, add string skipping. (3) `describeRiseStructure` prints the literal "fill forwards" rather than reading it — only reachable on the PASS path where it is true, but it is a hard-coded claim.

`lib/pixels.mjs`: two functions, strict `>` threshold, alpha ignored, loop guard `i + 2 < length` correct for a truncated buffer.

`lib/sheet-source.mjs`: the two-row strategy table lifted out of `zg-11.mjs` unchanged, plus `sheetSourceFor`/`sheetSuffix` so both groups share one selector. `zg-11.mjs` now imports `sheetSuffix` and drops three unused Node imports; its output is byte-identical (verified above). `probes.mjs` wiring mirrors the ZG-11 group; the stale `zg11SheetSource` helper is gone.

`zg-12.mjs`: calculations/actions/probes are separated and labelled; each probe reports one line through `report`; the animation oracle is `.rz-section`-scoped exactly as the PBI mandates and the comment says why. `readBoxPixels` decodes in-page and counts in Node — the split keeps the threshold logic unit-testable. `paintedWithSupportProbe` reads `tops` and `opacities` before the screenshot, so the primary oracle is measured on the untouched page.

BLESS ZG-12 phase-1 — CSS change is minimal and exactly the PBI's structure; scanner is correct for this sheet with three noted nits for a future general-purpose use.

## Phase 1 — Tester

AC coverage (each with a PASS line carrying numbers, from my own `npm test` run):
- name-fits: `1280×800 .rz-name 296/296px .rz-identity 296/296px`; `390×844 … 355/355px`. Base-sheet run: 1280 FAILs (`346 > 296`, Marcus's exact numbers), 390 PASSes (rail wide enough for the old clamp) — expected and stated in evidence.
- rise-css-structure: `5 .rz-section rule(s), rz-rise declared 1× (1 inside @supports view()), fill forwards, 0 hidden rest-state declaration(s)`. Base: FAIL on (a) top-level `… both`, plus (b) no rule inside and (b) both/backwards — matches the PBI's predicted mode.
- painted-without-support: `#rz-volunteer opacity 1, #rz-projects opacity 1, 0 .rz-section animations`. Base: opacity 0/0 and 12 running `rz-rise` — the PBI's predicted "finished fill-both" mode.
- painted-with-support: `top 1207.2px / 3372.3px` (both > 800 guard), opacity 1/1, `25830 pixels differ … by > 32`. Base: `#rz-projects opacity 0`, 0 painted pixels — exactly the PBI's predicted FAIL.
- reduced-motion: `12 sections, 0 .rz-section animations, all opacity 1`; passes on base too (guard pre-existed), as the PBI allows.
- pre-line ×3: 74/25, 68/23, 70/23 px (3.0× ≥ 2.5×). Base: all three FAIL at 1.0×.
- BAR-T1: `S3 Nightgarden … still has @keyframes` and `prefers-reduced-motion kills Nightgarden motion` PASS; S3 print probes PASS; ZG-11 page counts 2/3 unchanged.
- `just verify` exit 0.

Unit tests for the three new pure modules (27 tests):
- Comment containing `;`/`{`: covered (`withoutViewSupports … comment containing ; and {`, `parseRules ignores comments`). I additionally ran a comment with `;`/`{` inside a declaration block through `parseRules` — declarations parse correctly.
- Nested `@media` inside `@supports`: covered for the context chain (`@media print { @supports (x) {…} }`); the reverse nesting (`@supports view() { @media screen { .rz-section … } }`) is not in the file but I ran it: 0 reasons, correct. Worth adding as a test (follow-up, not blocking).
- `@keyframes` excluded: covered (`parseRules excludes @keyframes bodies`). Percentage keyframe selectors: not in the file; I ran `0% / 50% / 100%` — excluded correctly (the exclusion is by prelude, so the selector form is irrelevant). Follow-up: add one test so the intent is pinned.
- Empty file: not in the file; I ran it — `parseRules("") → []`, `withoutViewSupports("") → ""`, `riseStructureReasons("")` → the single "(b) no rule inside" reason. Follow-up: add.
- Pixels: threshold boundary (32 false / 33 true), any-channel, alpha ignored, empty buffer. Sheet-source: undefined/empty → live, revision → label, suffix. All AAA-shaped, no I/O.

Stub scanner: if `parseRules` always returned `[]`, `riseStructureReasons` yields the "(b) no `.rz-section` rz-rise rule inside" reason, so the live `npm test` run FAILs — caught. If `riseStructureReasons` itself were stubbed to `[]`, the live run passes but the anti-vacuity run would print `PASS ZG-12/rise-css-structure … [sheet 72596c7]` instead of the required FAIL line — caught by inspecting the anti-vacuity output (the exit code would still be 1 from the other six FAILs, so only the recorded FAIL line, not the exit code, catches it) and by the unit test `riseStructureReasons fails the pre-change sheet on (a)`. Yes, caught.

Pixel threshold determinism: the count (25830) is 129× the 200 floor; the primary oracle is computed opacity read before the screenshot; the body background is read from computed style, not hard-coded; fonts are awaited by `openResumePage`/`useSheetText`. A transient partial-opacity frame from `fullPage` can only lower the count toward the floor by the ratio of opacity, and Nightgarden's ink differs from `#070b14` by > 200 per channel, so at any opacity ≥ 0.16 the text still clears 32. Deterministic for this fixture.

BLESS ZG-12 phase-1 — every AC has a numbered PASS line, the anti-vacuity FAILs are the predicted modes, tests cover the tricky comment/keyframes/nesting cases; three cheap edge tests (reverse nesting, percentage keyframes, empty input) are follow-ups.

## Phase 1 — Architect

- Boundaries: `lib/css-structure.mjs` has two strata — a generic scanner (`topLevelBlocks`, `parseRules`, `withoutViewSupports`, `isViewSupports`) and ZG-12's `rz-rise` policy (`rise*Reasons`, `hiddenRestReasons`, `describeRiseStructure`). Both live in one file, which is acceptable at this size, but the file header says "for the ZG-12 rz-rise rules" while the scanner half is general. ZG-20's theme lint can import `parseRules`/`topLevelBlocks` as-is; when it does, split the policy half out (`rise-structure.mjs`) and generalise the header, and add string-literal skipping. Note recorded; no rework now.
- `lib/sheet-source.mjs` is the right home for the live/git strategy table: it was ZG-11-private and is now shared by two groups through one `sheetSourceFor(repoDir, env)` selector in the runner. No group imports from another group (`zg-12.mjs` imports only `lib/*`; `zg-11.mjs` the same); `probes.mjs` is the only composition point. `lib/pixels.mjs` is a pure calculation with no probe knowledge.
- The runner's env-var convention (`RZ_<PBI>_BASE`) is now documented in one comment above both groups.
- Contract note is additive prose under §5.3, no new class/attr, no schema-version bump — correct.
- Nothing here that ZG-13 (name colour/font distinctness — untouched) or ZG-20 must undo: the container query is local to `.rz-identity`, the `@supports` block is the single owner of `rz-rise`, and the print block (ZG-11's) is unchanged. The `hyphens: auto` on `.rz-name` depends on the document `lang`; if a future item changes the skeleton's `lang`, the fallback is still `overflow-wrap: anywhere`, so no coupling.

BLESS ZG-12 phase-1 — layering is clean, shared code was lifted rather than duplicated, and the scanner is reusable by ZG-20 with one noted split.
