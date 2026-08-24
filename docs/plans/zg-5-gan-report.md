# ZG-5 GAN report

Adversaries run in sequence (reviewer → tester → architect) on the uncommitted phase-1 diff of branch `garden/persona-loop`, 2026-08-24.

Verification re-run by the adversaries (not taken from the Generator's evidence):
- `npm run test:unit` → 142 pass, 0 fail.
- `PROBE_PORT=4405 npm test` → exit 0; 10 `ZG-5/*` PASS lines (`paste-sample`, `paste-ada`, `paste-then-switch`, `paste-empty`, `paste-trailing-comma`, `paste-not-resume`, `paste-missing-name`, `render-failed`, `no-serde-tokens`, `copy`).
- `PROBE_PORT=4406 just verify` → exit 0; 108 PASS, 0 FAIL (log `/tmp/zg5-verify.log`).
- Adversary in-browser hint run (`/tmp/persona-lab/conductor/zg5-adv-hints.mjs`, port 4407) — findings quoted below.

## Phase 1 — Reviewer

Files read: `frontend/src/Paste.elm`, `frontend/src/Paste/JsonScan.elm`, `frontend/src/Paste/Classify.elm`, diffs of `Main.elm`, `static/ports.js`, `static/render.js`, `css/chrome.css`, `scripts/probes/*`.

### Structure
- `Paste.update : Msg -> Model -> ( Model, Effect )` is a calculation; `Effect` (`NoEffect | Render | Swap | LogDebug`) is a clean seam. `Main.pasteCommand` is the single place an effect becomes a `Cmd` and it is documented as such. Good. `Paste.rendered` taking `Result String String` keeps the port decoding in `Main` — right layer.
- The old `Model.rendered : Maybe (Result String String)` in `Main` is gone (replaced by `paste : Paste.Model`); no dead state left behind.
- View copy is separated from logic: every visible sentence lives under `-- COPY` (`problemSentence`, `faultHint`, `shapeWords`, `renderFailedSentence`), names under `-- NAMES`. Nesting is flat (max one `case` inside a `case` in `viewFailure`). Naming is consistent (`Failure`/`Problem`/`Kind`/`Shape`).
- `Classify.classify`: order is empty → decode → shape → name. `firstWrongShape` walks `knownKeys` in schema order and takes the first hit — deterministic, matches "name the key". `hasWrongShape` treats absent/`null` as fine, which mirrors the renderer contract. `hasName` trims — `{"name":"   "}` is `missing-name` (verified in-browser).
- `JsonScan`: readable recursive descent; primitives (`peek`, `advance`, `skipSpace`, `consumeWhile`) are tail-recursive so Elm compiles them to loops. `items → separator → afterComma → items` is mutual recursion that is *not* TCO'd, so stack depth grows with container length. Not a phase-1 problem (see performance) but worth a comment.
- Performance on a 4.8 MB paste: confirmed the scanner runs only in the `Err _` branch of `Decode.decodeString` (`Classify.classify`), so a valid large paste never touches `String.toList`. An *invalid* multi-megabyte paste would build a 4.8M-element `List Char` and recurse per item; the ZG-4 large fixture (9942 jobs) would overflow the JS stack in `items` if it were made invalid. Follow-up, not a blocker: the AC has no large-invalid case, but the failure mode would be a `pageerror`, which is the one thing the panel promises never to do.
- **Fallback path is a wrong answer, not a shrug.** `Classify.invalidJson` returns `line 1, column 1, Stray` when `JsonScan` finds nothing. Confirmed in-browser: `{"basics":{"name":"E"},"n":01}`, `…"n":-}` and `"E\x"` all show "Look at line 1, column 1: there is a character we cannot read there." The first character is `{`, which is fine; the message points Elena at the wrong place with full confidence. This must become either an honest sentence ("we could not tell where") or a tighter number/escape scan. Flagged for the Tester, who owns the decision on the phase.

### Chrome / JS
- `chrome.css`: only tokens (`--input`, `--ring`, `--destructive`, `--link*`, `--success`, `--radius`, `--background`, `--foreground`); `color-mix` on the error border is fine; no `rz-` (grep confirms only the pre-existing comment). The monospace font stack is a literal but DESIGN.md constrains colour and radius, not font families.
- `ports.js`: still wiring — subscribe/send/`console.debug`; the render call goes through `window.resumezen.render` so the probe override and the product share one path. Acceptable and documented in the comment.
- `render.js`: the null guard throws a named error instead of a `TypeError` on `null.replaceWith`; `swapInFrame(...).catch(console.warn)` in ports keeps it from becoming a `pageerror`. Good.
- `data-paste-status` / `data-paste-attempt`: acceptable product surface. They are state, not test hooks — `status` is what a screen-reader-adjacent tool or CSS could key on, and `attempt` is the only race-free way a caller can tell "a new result arrived" from "the same result". Keep them, but they should be listed in the panel doc comment as public.

### Copy (as Priya / Elena / Marcus would read it)
- "Use my résumé" → Priya's own words from round 0; correct verb, correct placement (above Themes).
- "Show it" — right verb. Elena does not know the word "render"; "Show it" is what she would say. Keep.
- `empty`: "There is nothing to show yet. Paste your résumé into the box above, then press Show it." — no blame. Good.
- `invalid-json` trailing comma: "This is not quite valid JSON yet. Look at line 1, column 27: there is a comma right before a closing bracket. Remove that last comma." — "not quite … yet" is exactly the tone; names the fix. Elena would not feel it is her fault. Screenshots at 1280 and 390 show it inside a red-outlined box under "Show it", readable, wraps to three lines on the phone.
- `not-a-resume`: names the key and says what shape it should be in words, with the bracket glyphs. Good.
- `missing-name`: shows the literal snippet to add. Good.
- `render-failed`: "It is valid JSON and shaped like a résumé, so this is on us, not on you." — humane, but **overclaims**: the crate rejects `basics.profiles: "x"` (verified: `console.debug` shows `invalid type: string "x", expected a sequence`) and the panel tells the Author it is our fault. Phase 1 scope is top-level keys only, so the class is right; the sentence should not assert blame either way. Suggest "We could not draw this résumé, and we would like to know why." (keeps the AC word "could not").
- "Nothing leaves your browser until you publish." — publish does not exist yet; PBI text mandates the sentence, so it stands. Note for ZG-22: this sentence becomes a promise the moment publish ships.
- `Html.a … target "_blank"` on "Report this" opens a GitHub issue with a prefilled title; fine. The repo slug `subzerocorp/cvzengarden` should be checked against the real remote before phase 2 (not verifiable offline here).

**BLESS ZG-5 phase-1 — structure, seam and chrome are clean; the `invalidJson` line-1/column-1 fallback and the "on us, not on you" overclaim are handed to the Tester and recorded as follow-ups.**

## Phase 1 — Tester

### AC coverage (phase-1 ACs)
| AC | PASS line | Note |
| --- | --- | --- |
| paste-sample | `ZG-5/paste-sample` | checks `.rz-name`, `data-rz-schema="1.0"`, no error |
| paste-ada | `ZG-5/paste-ada` | no Jordan anywhere in iframe, src + href unchanged |
| paste-then-switch | `ZG-5/paste-then-switch` | Quarto href with stylesheet rules loaded, then Print preview |
| paste-empty | `ZG-5/paste-empty` | both `""` and `"   \n"` in one page |
| paste-trailing-comma | `ZG-5/paste-trailing-comma` | `line 1` and `comma`, fixture bytes verified `{"basics":{"name":"Elena",}}` |
| paste-not-resume | `ZG-5/paste-not-resume` | plus the crate-oracle check (`renderOutcome` must reject) |
| paste-missing-name | `ZG-5/paste-missing-name` | |
| render-failed | `ZG-5/render-failed` | override rejects with a serde sentence; raw text at `console.debug` only (`debugOnlyReasons`); report link present; no pageerror |
| no-serde-tokens | `ZG-5/no-serde-tokens` | applied after every error probe incl. render-failed; a leak emits a FAIL line and suppresses the PASS |
| copy (phase-1 part) | `ZG-5/copy` | accessible name contains `résumé`; "Nothing leaves your browser" |

Anti-stub: recorded in the evidence (`zg5-stub-run.log`): string-replace stub fails `paste-ada`, `paste-then-switch`, `paste-not-resume` (the last via the oracle check). Good — the oracle check is what makes `work: "nope"` a real assertion rather than a text match.

Probe-side calcs (`lib/paste.mjs`) all have node:test coverage, including the `unexpected`-contains-`expected` case-sensitivity trap. `articleReasons` in ZG-4 now requires byte-equal article, closing the "swap only the name" hole. Good.

### Where the scanner is tested
`Paste.JsonScan` has five `Kind`s plus a fallback in `Classify.invalidJson`. In the suite, exactly **one** (`TrailingComma`, before `}` in a one-line text) is exercised. `UnquotedText`, `UnterminatedString`, `Truncated`, `Stray`, trailing comma before `]`, and the multi-line line/column arithmetic exist only in an ad-hoc log (`zg5-hints.log`) produced by a script outside the suite. The plan explicitly accepted "pure Elm calcs are exercised through probes" as the strategy — so probes *are* the unit tests here, and a strategy that says "through probes" is not met by one probe and a log file. A regression in `positionOf` (say, off-by-one on line 3) would ship green.

### Fallback path: tested by the adversary, and wrong
Decoder-fails / scanner-passes was not tested by the Generator. Adversary run (port 4407):
- `{"basics":{"name":"E"},"n":01}` → `invalid-json` "Look at line 1, column 1: there is a character we cannot read there."
- `{"basics":{"name":"E"},"n":-}` → same, line 1 column 1.
- `{"basics":{"name":"E\x"}}` → same, line 1 column 1.

The panel gives a confident, wrong location and a hint ("check the brackets, commas and quotes around it") that points at `{`. This is Elena's round-0 trigger in a new coat: not a serde token, but a message that sends her to the wrong place. She would retype the first line, get the same message, and conclude the tool is broken.

### Other cases asked for
- Non-object top level: `"x"`, `42`, `[1,2]` all → `missing-name` ("We could not find a name in it. A résumé needs "basics": …"). Class is defensible (the AC has no `not-an-object` class) and the sentence still tells her what to add. Untested in the suite; acceptable as a follow-up probe.
- Deep-nested wrong shape `basics.profiles: "x"` → crate rejects → `render-failed`; message is humane, no serde token on the panel, raw text in `console.debug`. Confirmed. But the sentence says "this is on us, not on you" for a file that is the Author's mistake — see Reviewer. Untested in the suite.
- Marcus's `score: 3.7` now renders (`shown`) — ZG-4 fix holds through the paste path.
- `no-serde-tokens` after render-failed: yes, `renderFailedProbe` runs `serdeTokenReasons` and the aggregate PASS depends on it.

### Verdict
Every phase-1 AC has a PASS line and the anti-stub is real. But the calc at the heart of the slice — "where is the mistake" — has 1 of 6 paths under regression protection and a demonstrably wrong message on the path nobody tested. The plan's own strategy (calcs exercised through probes) is not satisfied.

Required to clear:
1. Add one probe `ZG-5/scanner-hints` (single page, table-driven like `zg5-hints.mjs`) covering: unquoted value (multi-line, asserts `line 3`), unterminated string (asserts the *opening-quote* line), truncated, stray after a value, missing comma between members, trailing comma before `]` on line 2, and the three fallback inputs above. Each row asserts class, `line N, column M`, and a distinguishing word; the serde-token check applies to every row.
2. Make the fallback honest. Either (a) tighten `JsonScan` so numbers (`-` alone, leading zero) and string escapes are checked, which makes it find a real offset for these three, or (b) change `Classify.invalidJson`'s `Nothing` branch to a distinct `Kind` (e.g. `Unknown`) whose sentence does not name a position: "This is not quite valid JSON yet, and we could not tell exactly where. Check the numbers and the backslashes in it." Either is a small change; (a) is better for Elena, (b) is the minimum.
3. One non-object top-level row (`[]` or `"x"`) in the same probe so the `missing-name` choice is pinned.

**REJECT ZG-5 phase-1 — the JSON position calc is regression-protected on one of six paths and produces a confident wrong location ("line 1, column 1") whenever the decoder and scanner disagree; add the `ZG-5/scanner-hints` probe and make the fallback honest, then re-run the chain.**

## Phase 1 — Architect

Not run: the chain stopped at the Tester's REJECT. Notes gathered while reading, for the re-run:
- Stratification `JsonScan → Classify → Paste → Main → ports` is clean; no upward imports; `lib/paste.mjs` is probe-side reason calcs only (no classification duplicated in JS).
- `Accepted String` (raw text) as the stored shape is right for ZG-22 (JSON Resume is the only stored Resume; the crate re-parses); phase 2's `localStorage` should store the same string, not the rendered HTML.
- ZG-6 sample buttons will need a `Msg` that sets `text` and submits — `TextChanged` + `ShowIt` already compose; the panel view will want to split into `viewPanel` / `viewHelp` rather than growing `viewPanel`.

---

# Re-run after the Generator closed the Tester's blockers (2026-08-24, later)

Generator changes since the REJECT (all uncommitted, on `garden/persona-loop`):
- `frontend/src/Paste/JsonScan.elm`: strict numbers (`-? (0|[1-9]\d*) (.\d+)? ([eE][+-]?\d+)?`, reported at the number's start as `BadNumber`), strict escapes (eight simple escapes and `\uXXXX`, reported at the backslash as `BadEscape`), raw control characters in strings are `Stray`; running out of text is always `Truncated` (also inside a string and inside a cut-off `tru`). `scan : String -> Outcome` (`Clean | Found Fault | Lost`) replaces `firstFault`; only the first 64 KB are scanned and nesting stops at 64 levels, both yielding `Lost`; `items` is self-tail-recursive (Elm emits a loop) via a `Next = More | Done` step.
- `frontend/src/Paste/Classify.elm`: `Problem.InvalidJsonSomewhere` for `Clean`/`Lost`; no invented position.
- `frontend/src/Paste.elm`: two new `faultHint`s, the no-position sentence ("…we could not tell exactly where. Check the numbers and the backslashes in it, and that the whole file was pasted."), render-failed sentence is now "We could not draw this résumé, and we would like to know why." (no blame either way).
- `frontend/scripts/probes/zg-5.mjs`: `ZG-5/scanner-hints`, 13 rows on one page; `lib/paste.mjs` `errorReasons` gained `without` (unit-tested).
- Report link slug `subzerocorp/cvzengarden` matches `git remote -v`.

Verification re-run by the adversaries: `npm run build && npm run test:unit && PROBE_PORT=4408 npm test` → exit 0 (143 unit pass, 109 probe PASS); `PROBE_PORT=4409 just verify` → **exit 0**, 109 PASS, 0 FAIL (`/tmp/zg5-verify2.log`).

## Phase 1 — Reviewer (pass 2)

Files re-read in full: `Paste/JsonScan.elm`, `Paste/Classify.elm`, `Paste.elm`, `scripts/probes/zg-5.mjs`, `lib/paste.mjs`, `lib/paste.test.mjs`; the rest of the diff is unchanged since pass 1.

- **Fallback is honest now.** `Classify.invalidJson` maps `Found` to a position and both `Clean` and `Lost` to `InvalidJsonSomewhere`. The line-1/column-1 lie is gone; the three inputs from pass 1 now get real offsets (`BadNumber` at the `0`/`-`, `BadEscape` at the backslash). Keeping `Clean` and `Lost` distinct in the scanner while Classify collapses them is right: the scanner states what it knows, the classifier decides the sentence.
- **Stratification inside the scanner** is uniform: primitives (`peek`, `peekIs`, `advance`, `consumeWhile`, `skipChar`) → values (`number` with `integerPart`/`fractionPart`/`exponentPart`/`digits`, `literal`, `string`/`stringBody`/`escape`/`hex4`) → containers (`container`, `items`, `afterItem`). Every function is under 20 lines. `fault : Kind -> Scanner -> Result Stop a` being polymorphic lets `afterItem` return `Result Stop Next` without a `Result.map Done` — good.
- **Recursion guard is real, not cosmetic.** `items` calls itself only in tail position of a `case`; Elm 0.19 compiles that to a `while`. `stringBody` likewise (the nested `case escape scanner of` exists precisely so the recursive call stays a direct tail call — the comment on `items` says why; `stringBody` should carry the same one-line why). Depth is bounded by `maxDepth` in `container`; length by `windowSize` in `scan`. In a clipped scan only `Truncated` is discarded, which is correct because every "ran out of text" path now reports `Truncated` (string, `literal` prefix, `hex4`, `digits`, `integerPart`) — I checked each `Nothing` branch.
- Nits (follow-ups, not blockers): (1) `isSimpleEscape` via `String.contains (String.fromChar c) "\"\\/bfnrt"` is a little clever — a `List.member c [...]` reads plainer; (2) `stringBody` lacks the "why nested case" comment; (3) the no-position sentence is 27 words, the longest on the panel — acceptable, but Elena reads it twice.
- Copy: "there is a number written in a way JSON cannot read. Numbers need no leading zeros, a digit on each side of any dot, and digits after any minus sign." — plain and actionable. "…and we would like to know why. Report this so we can fix it." keeps `could not`, drops the blame claim. No serde tokens anywhere (the suite asserts it on 18 texts now).
- Probe code: `SCANNER_ROWS` is data, `scannerHintsProbe` is the one action, `positionPhrase` and `errorReasons` are calcs. The PASS line prints each row's class and `line N, column M` — the evidence is readable without opening the browser.

**BLESS ZG-5 phase-1 — the invalid-JSON position calc is strict where a hand slips, honest where it cannot see, and stack-safe; nits (`isSimpleEscape` phrasing, a why-comment on `stringBody`) are follow-ups.**

## Phase 1 — Tester (pass 2)

Every pass-1 blocker, checked against the re-run (`/tmp/zg5-partA.log`, `/tmp/zg5-verify2.log`):

| Blocker | Status | Evidence |
| --- | --- | --- |
| 1. `ZG-5/scanner-hints` table probe | closed | one page, 13 rows, all PASS; each row asserts class + `line N, column M` as a single string (an off-by-one on either number fails) or `without: ["line "]` for the no-position rows, plus a distinguishing word; serde-token check on every row feeds the `no-serde-tokens` aggregate |
| 2. Honest fallback | closed | `{"n":01}` → line 1, column 28 "number"; `{"n":-}` → line 1, column 28 "number"; `"E\x"` → line 1, column 21 "backslash"; no path prints a made-up position (`InvalidJsonSomewhere` has none) |
| 3. Non-object top level | closed | `[]` → `missing-name`, word `name` |
| Follow-up: large invalid, no pageerror | closed | `[1,1,…x` at 1.2 MB → `invalid-json`, "could not tell", no `line `; `{"n":01,"a":1,…}` at 1.2 MB → line 1, column 6 (fault inside the window is still located); `[`×10,000 → "could not tell"; zero `pageerror` on the page |
| Follow-up: render-failed copy | closed | sentence contains `could not`, no longer asserts blame |

Row-by-row PASS line (from `just verify`): unquoted → line 3, column 9; unterminated (raw newline) → line 2, column 20 (the opening quote, not the newline); truncated → line 1, column 23; stray after value → line 1, column 25; missing comma → line 1, column 24; trailing comma before `]` → line 2, column 11; leading zero / lone minus → line 1, column 28; bad escape → line 1, column 21; `[]` → missing-name; two 1.2 MB pastes and the 10,000-deep paste → no position, no pageerror.

Mutation evidence (adversary-run, `/tmp/zg5-mutation.log`): with `positionOf` changed to `column = column` (off by one), `PROBE_PORT=4410 npm run probe` exits 1 and `ZG-5/scanner-hints` fails on every located row ("Look at line 3, column 8" vs wanted `line 3, column 9`). Notably `ZG-5/paste-trailing-comma` still passed under the mutation (it asserts only `line 1`), which is exactly the gap pass 1 named; the table probe is what closes it. Source restored, `dist/` rebuilt, `git status` confirms only the intended files are touched.

Unit side: `errorReasons` `without` has a node:test with both a pass and a fail case; 143 unit tests pass. The Elm calcs (`scan`, `positionOf`, `classify`) remain covered through the probe table only — consistent with the plan's stated strategy, and now actually satisfied (13 rows across all 7 kinds plus both no-position paths).

Coverage gaps I would still like, as follow-ups: a row for `1.` / `1e` (BadNumber fraction/exponent paths — reachable but not pinned), a row for `\u12G` (`hex4` BadEscape), and one where the text is exactly `windowSize` characters long (the boundary). None changes the verdict.

`PROBE_PORT=4409 just verify` exit code: **0**.

**BLESS ZG-5 phase-1 — every blocker is closed with a PASS line I can read, the table probe demonstrably catches a one-column regression, and a megabyte of garbage produces a sentence instead of a pageerror.**

## Phase 1 — Architect

Read: the full phase-1 diff, `AGENTS.md` (stack lock, `rz-` rule, persona loop), the ZG-5 PBI body, and the pass-1 notes gathered while the chain was stopped.

- **Stratification.** `Paste.JsonScan → Paste.Classify → Paste → Main → static/ports.js → static/render.js`. No upward import; `Main` is the only module that knows both `Paste` and ports; `ports.js` is wiring and `render.js` holds the logic. The scanner knows nothing about résumés, the classifier knows JSON Resume keys and nothing about sentences, the panel owns every sentence. In two years someone can change the copy, the schema keys, or the scanner grammar without opening the other two files. This is the layering I want and it survived the Tester's rework without a single cross-layer leak.
- **The Effect seam.** `Paste.update : Msg -> Model -> ( Model, Effect )` and `Main.pasteCommand : Effect -> Cmd Msg` is the right shape: the panel is a calculation over its own model, and there is exactly one place where an effect becomes an action. ZG-5 phase 2 (file input, drop zone, `localStorage`) should add `Effect` constructors (`Store String`, `Forget`, `ReadFile …`) and nothing else in `Main` — if phase 2 grows `Main.update`, that is the smell to reject.
- **Probe side.** `lib/paste.mjs` is reason calcs only; nothing in JS re-implements classification, so the crate stays the oracle (`crateRejects`) and the Elm code stays the single authority for the panel. `openGarden` moving to `lib/page.mjs` and `zg-4.mjs` consuming it is the right deduplication.
- **Stored shape for ZG-22.** `Accepted String` — the raw JSON text — is what phase 2 must write to `localStorage` and what ZG-22 must publish. Do not store rendered HTML; the crate re-renders and the Skeleton contract is the only thing that persists. `Paste.Model.text` is the editing buffer, `Accepted json` is the datum; keep those two apart when `localStorage` restore lands (restore sets both, "Forget" clears both).
- **ZG-6 seam.** Sample buttons compose from `TextChanged` + `ShowIt`; no new effect is needed. The view should split `viewPanel` into `viewPanel` / `viewHelp` at that point rather than growing `viewPanel`; that is a phase-2/ZG-6 note, not a phase-1 finding.
- **Scanner guards as architecture.** The 64 KB window and 64-level depth cap are policy constants inside the scanner, invisible to callers except through `Lost`. That is the correct place: the classifier and panel do not know a window exists, only that a position may be unknown. If a future PBI wants a larger window it changes one constant.
- **What I would reject and did not find.** No `rz-` in chrome; no second classification in JS; no crate text on the panel; no state in `ports.js`; no growth of `Main` beyond the seam. `data-paste-status` / `data-paste-attempt` are product state, fine.
- Direction for phase 2: keep `Paste` as the one module that owns the Author's résumé state; the file/drop input becomes another way to call `TextChanged`, classification stays byte-content-first exactly as the PBI says, and `not-json-file` is a `Problem` constructor with a filename, nothing more.

**BLESS ZG-5 phase-1 — layered the way the stack lock intends (scanner → classifier → panel → Main → ports), one effect seam, the raw JSON as the only stored shape; phase 2 extends `Effect`, not `Main`.**
