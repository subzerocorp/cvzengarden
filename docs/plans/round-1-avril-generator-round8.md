# AVRIL round 1 — Generator revise pass (cycle 8, after QA Architect cycle 6)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-24 · **Board:** Pinto `ZG` (labels `avril`, `round-1`)
**Inputs read in full:** `docs/plans/round-1-avril-qa-round6.md` (the two REJECT sections and the set-level notes), `docs/plans/round-1-avril-generator-round5.md`, `pinto show ZG-11 ZG-20 --plain` (rejected), `pinto show ZG-12 ZG-19 --plain` (blessed, consistency only — not edited), `themes/quarto.css`, `themes/switchyard.css`, `themes/nightgarden.css`, `frontend/scripts/probes.mjs`, `skeleton/example.html`.

Only the two QA-cited REJECTs were applied, plus the non-blocking notes QA asked to fold in with the fix (ZG-11: `.rz-header` in `paginate`, the two pre-change `bullets-print` failure modes; ZG-20: concurrent `node --test` and the meta-test's `themes/` write). ZG-12 (QA-blessed cycle 6), ZG-19, and every other id are untouched. No dependency changed. Nothing is BLESSed by this document. This is the third QA pass on these two items, so each change is a read that exists or a value Chromium reports, and every AC example was run against its stated rule by hand before saving (below).

## Facts verified before writing (each QA fact re-checked against today's tree)

| Fact | How | Used by |
| --- | --- | --- |
| Quarto `.rz-section { margin…; break-inside: avoid-page; page-break-inside: avoid }` at 174–178, top level; `.rz-bullet::before { content: "– " }` at 268–269 | `sed -n` | ZG-11 `no-forced-break`, `bullets-print` |
| Switchyard `@media screen` opens at 129, `@media print` at 334; the bar `.rz-bullet::before { content: ""; … width: 0.55rem; height: 2px; background: #b45309 }` is at 256–264 — **inside `@media screen`**, so print emulation has no bar today (round-5 doc called it the print block; the body never did); `.rz-section` avoid 397–398; `.rz-section--projects { break-before: page; page-break-before: always }` 402–403 | `sed -n` | ZG-11 `bullets-print` pre-change sentence |
| Nightgarden `@keyframes rz-rise` 68, `rz-foxfire` 80, `rz-name-sheen` 90, all `from`/`to`; `.rz-bullet::before { content: "" … }` 309–310 | `sed -n` | ZG-20 selector rule; ZG-11 |
| `staticProbes()` (174) prints `PASS  S1`/`U3`/`S3`/`S2`/`S5`/`S4`/`U3`/`U3` at 238, 244, 249, 259, 264, 270, 280, 290, 302, 315 — ten lines, all before `startServer()` (1114); browser-only lines: `Live sandbox has data-rz-schema="1.0"` 478, `Jordan Hale is in .rz-name` 483, `U3 <id>: … printToPDF …` 813–914, `All RZ-3, RZ-S1…S5, and U3 print probes passed.` 1126; `N probe(s) failed.` summary at 1122 | `grep -n 'pass('`, `sed -n 1112,1126p` | ZG-20 `--static` AC and scope line |
| `skeleton/example.html` has one `class="rz-header"`; Quarto styles `.rz-header` at 104 | `grep -c` | ZG-11 `paginate` block list |
| The pseudo-element rect claim (no `getBoundingClientRect()`, `el.pseudo('::before')` undefined; `getComputedStyle(el,'::before').width` = `8.79688px`/`2px` for a bar, `auto` for no box) and the `breakInside` = `avoid` claim are QA's Chromium runs (`/tmp/persona-lab/qa6-facts.mjs`); consistent with the cascade (177 after 176, alias of the same property) — not re-run | QA round 6 | ZG-11 both blockers |
| ZG-12 `rise-css-structure` already says "`@keyframes` bodies excluded from the selector scan"; ZG-19 owns `blank-theme.test.mjs` and does not touch `package.json` `test` | `pinto show` grep | ZG-20 consistency |
| Pinto body holds the DoD block once; `pinto edit -b` replaces the whole body; edits were exact-match replacements over the JSON body, each asserted to occur exactly once, then `pinto show --json` re-read (`Definition of Done` count 1, `depends_on` unchanged: ZG-11 `[]`, ZG-20 `['ZG-19']`) | script | edit method |

---

## Per-item: QA blocker → exact change

### ZG-11
| QA blocker / note | Change |
| --- | --- |
| **Blocker 1 — `bullets-print`'s marker-exists clause requires `getBoundingClientRect()` on a `::before` box, which has no such method** | The second alternative now reads: `content` is `""` / `none` / `normal` **and** `getComputedStyle(el, '::before').width` and `.height` each parse to > 0 px (parenthetical: a pseudo-element is not an Element, so there is no node to call `getBoundingClientRect()` on; the computed read returns the used box size, e.g. `8.79688px` / `2px` for a bar, and `auto` when `content: none` generates no box, which fails). The closing parenthetical adds "both clauses use the one read `getComputedStyle(el, '::before')`". Nothing else in the clause changed (the three alternatives, the `""` serialisation note, the `list-style-type` branch and the ink clause are as blessed) |
| **Blocker 2 — `no-forced-break`'s anti-vacuity says pre-change Quarto computes `avoid-page`; Chromium computes `avoid`** | The parenthetical now says the pre-change top-level `.rz-section` rule (lines 174–178) computes `breakInside` `avoid` in Chromium — line 177's `page-break-inside: avoid` is an alias of `break-inside: avoid`, is declared after line 176's `avoid-page`, and wins the cascade; anything other than `auto` fails — and that the recorded FAIL line reads `avoid`. The assertion (`auto` on every `.rz-section`) is unchanged |
| Non-blocking — `.rz-header` not in `paginate`'s block list | `.rz-header` added to the leaf block list, with "the `.rz-header` is the first block placed on page 1, so the simulated page 1 has no more capacity than the real one" |
| Non-blocking — both pre-change `bullets-print` failure modes seen once | One sentence appended to the AC: against the pre-change sheets (`git show <base>:themes/<theme>.css` injected) Switchyard fails the marker-exists clause — its bar lives only in `@media screen` (256–264), so in print emulation `content` is `none` and `width` is `auto` (E2 reproduced) — and Nightgarden fails the ink clause — its dot has a box but a mint `background-color` and no `print-color-adjust`; both FAIL lines are recorded in evidence |

Examples run against the rule by hand: Quarto post-change — `content` `"– "` (quoted, not `""`) → marker exists; ink via `color` contrast → pass. Switchyard post-change bar — `content` `""`, computed `width`/`height` > 0 px → marker exists; `background-color` `#b45309`-class ink + `print-color-adjust: exact` → pass. Switchyard pre-change — print emulation has no bar: `content` `none`, `width` `auto` → marker-exists fails (the E2 reproduction). Nightgarden pre-change — `content` `""`, box `0.4rem` → marker exists; mint `background-color`, no `print-color-adjust` → ink fails. `no-forced-break` pre-change Quarto — `breakInside` `avoid` ≠ `auto` → FAIL, and the AC text now names `avoid`.

### ZG-20
| QA blocker / note | Change |
| --- | --- |
| **Blocker 1 — the `--static` AC forbids any `PASS  S1`…`S5`/`U3` line, but `staticProbes()` prints ten of them** | The negative now names browser-only lines: no `Live sandbox has data-rz-schema` / `Jordan Hale is in .rz-name` line, no `S2 <id>:` / `U3 <id>:` per-theme line, no line containing `printToPDF`, no `All RZ-3` summary — and nothing after its last probe line; it states that `staticProbes()` itself prints ten `PASS  S1`…`S5`/`U3` static file-check lines (`probes.mjs` 238–315), which are expected and are not `PASS  ZG-20/lint` lines, so the meta-test's count of exactly three is undisturbed. The scope-in `--static` line gains the success output: nothing after the last probe line (the `All RZ-3…` summary belongs to the browser suite). The 10 s bound, exit 0, three `PASS  ZG-20/lint` lines and the flag-less clause are unchanged |
| **Blocker 2 — the selector rule, as written, errors on `from`/`to` inside `@keyframes`; AC 1 requires Nightgarden exit 0; no keyframe unit case** | Selector rule gains: "The selector rule does not apply inside `@keyframes` bodies: `from`, `to` and `<percentage>` (`0%`, `50%`) are keyframe selectors, not selectors — Nightgarden's three `@keyframes` (lines 68–99) use `from`/`to`, and a Designer's blink or flicker animation uses percentages" (same exclusion ZG-12's `rise-css-structure` already states). Selector unit list gains `@keyframes x{from{opacity:0}50%{opacity:.5}to{opacity:1}}` → no `selector` error (keyframe selectors; the snippet has no reduced-motion guard, so warning `motion` is also present — as for every bare snippet, the case asserts only the named codes) |
| Non-blocking — `node --test` runs files concurrently; the meta-test writes into `themes/` | Wiring line gains: "`node --test` runs test files concurrently, and the meta-test is the only test that writes into `themes/` (it removes `zz-bad.css` in `finally`) — a future test that lists `themes/` must respect that". `--test-concurrency=1` not taken (nothing today needs it; the constraint is stated instead) |
| Non-blocking — `CONTRIBUTING.md` ownership is ZG-18's | No change (QA: testability unaffected; the PO's AXEL ordering decides) |

Examples run against the rule by hand: the new keyframe snippet — `@keyframes` is an allowed at-rule; its body is excluded from the selector rule, so `from`, `50%`, `to` produce no `selector` error; `@keyframes` present with no `prefers-reduced-motion` → `motion`, consistent with the existing `@keyframes x{}` → `motion` case. Nightgarden AC 1 — `from`/`to` at 68–99 are now excluded by rule, every other selector has an `html`/`.rz-*` compound → `0 errors`, exit 0. `--static` on today's `probes.mjs` shape — the ten static `PASS  S…`/`U3 …` lines are permitted, none of the named browser-only strings is printed before `startServer()`, and the run ends after the last static probe line. The `content` examples are unchanged from cycle 5 (QA re-ran all thirteen in Node 20 and confirmed the rule).

---

## Set-level notes applied

- **Pseudo-elements have no rect.** ZG-11 measures the `::before` box with `getComputedStyle(el, '::before')` in both clauses; no AC in either body names `getBoundingClientRect()` on a generated box.
- **`page-break-*` aliases win when declared later.** ZG-11's anti-vacuity names `avoid` and says "anything other than `auto` fails".
- **`staticProbes()` is not silent about S1–S5/U3.** ZG-20's negative names browser-only lines and states the ten static ones are expected.
- **A regex lint's selector rule says where it does not apply.** ZG-20 excludes `@keyframes` bodies with a `from`/`50%`/`to` unit case, matching `@page :first{}` and ZG-12's probe.
- **Over-specification removed rather than added.** The `--static` AC no longer forbids a class of lines the source prints; the keyframe unit case asserts only the named codes.

## Dependency changes

None. Edges remain ZG-12 → ZG-11 and ZG-20 → ZG-19; `pinto show --json` confirms `depends_on` unchanged on both edited items.

## Changed ids

Every PBI whose body changed in this pass (prior blessings invalidated; full PO → QA → CTO chain required):

- **ZG-11** — body (`bullets-print` marker-exists clause reads `getComputedStyle(el, '::before').width`/`.height`, one read for both clauses, plus the two pre-change failure modes; `no-forced-break` anti-vacuity names `avoid` with the line-177 alias explanation; `.rz-header` first in `paginate`)
- **ZG-20** — body (`--static` AC names browser-only lines and states the ten static `S…`/`U3` lines are expected, success prints nothing after the last probe line; selector rule excludes `@keyframes` bodies with a `from`/`50%`/`to` unit case; concurrent `node --test` / `themes/` write constraint)

Untouched: ZG-1 … ZG-10, ZG-12, ZG-13, ZG-14, ZG-15, ZG-16, ZG-17, ZG-18, ZG-19, ZG-21, ZG-22.
