# ZG-2 GAN report

## Phase 1 — Reviewer

Mandate: write layered, modular Rust code built from pure calculations on immutable data; isolate actions at the edges; prefer std; use strong typing and composition so any human can understand and safely modify the system.

Diff reviewed: `renderer/src/date.rs`, `renderer/src/emit.rs`, `renderer/src/slug.rs`, `skeleton/CLASS-CONTRACT.md` §5.3, new `renderer/tests/wild.rs`. Self-verified from `renderer/`: `cargo fmt --all -- --check` exit 0; `cargo clippy --all-targets -- -D warnings -D clippy::pedantic` clean; `cargo test` 16/9/2/13 green; `PROBE_PORT=4372 just verify` exit 0 (90 PASS, 0 FAIL). `grep -rn "allow(clippy" renderer/src renderer/tests` empty.

Checklist:
- Purity: `parse_iso_date`, `date_part`, `digits`, `is_calendar_valid`, `days_in_month`, `is_leap_year`, `month_name`, `IsoDate::datetime`, `IsoDate::visible` are all `&str`/`Copy` in, value out, no `&mut`, no I/O. `date_token` is a pure lift of `Option<&str>` into `Option<DateToken>`. Correct.
- Byte indexing: `grep -nE '\[\.\.|\.as_bytes\(\)|get\(\.\.'` over `date.rs`, `slug.rs`, `emit.rs` returns nothing. `slug::iso_year` (the `date[..4]` panic site from Devon's finding) is deleted, not patched. `digits` walks `chars()`; `date_part` uses `split_once`, which returns char-boundary slices. Correct.
- `unwrap`/`expect` on user data: none in the diff. The single `unwrap` in `date.rs` is inside `#[cfg(test)]`. The three pre-existing `filter-then-expect` sites in `emit.rs` (`profile.url`, `item.language`, `item.name`) are untouched and out of scope (noted by the generator).
- Stratification: `resume` (data) -> `date`/`slug` (calculations) -> `emit` (assembly) -> `html` (escaping). `entry_slug(&str, Option<u16>, &mut HashSet)` now takes a year, not a date string, so the slug layer no longer parses dates. `emit_entry` derives both the slug year and `is_current` from the same `token.parsed`, removing the raw-string/parsed-string disagreement that produced Devon's finding 8. Correct.
- `DateToken` is a `Copy` view-model (`raw` + `parsed`) private to `emit.rs`; `emit_dates` is one flat three-way match, `emit_date` is a two-arm match, `emit_range_end` a two-arm match. Max nesting 2. Every function < 15 lines. Params <= 3.
- Types: `IsoDate { year: u16, month: Option<u8>, day: Option<u8> }` is a real domain value with `PartialEq`/`Eq`/`Copy`, tested by structural equality, not string comparison. `digits<N: FromStr>` cannot overflow (4 digits <= 9999 fits `u16`; 2 digits fit `u8`).
- Docs: module doc, `IsoDate`, `datetime`, `visible`, `parse_iso_date`, `date_part`, `digits`, `days_in_month`, `DateToken`, `emit_date`, `emit_range_end` all documented with backticked identifiers. No `# Errors` sections needed (nothing returns `Result`). `render_json`'s doc is unchanged.
- Contract §5.3: "Dates", "Timestamps", "Unparseable dates" paragraphs match the code line for line (four-digit year, two-digit month/day, leap validation, `T`/space truncation, `<span>` without `datetime`, no `.rz-is-current` from an unparseable start, plain `<span class="rz-date">` for a single date). `grep unparseable` hits lines 303 and 318. No new class or attribute, so no `data-rz-schema` bump. Correct.

Nits (recorded as follow-ups, not blocking):
- The "unparseable start + omitted end" state (the `rz-date--present` `Present` span still appears, entry is not `.rz-is-current`) is only derivable by composing three contract sentences; one explicit sentence in "Unparseable dates" would save a theme author the inference. The `data-rz-entry` row still says `startYear` without saying it is the year of the *parsed* `startDate`.
- Invariant 3 ("Dates have machine `datetime` values") and the §8 checkbox are now true only for parseable dates; a parenthetical would keep §1 honest.
- `IsoDate` has public fields, so `{month: None, day: Some(_)}` is representable inside the crate (the module is private so it is not exported). An enum precision would make the invalid state unrepresentable. Fine for now.
- `digits`: `chars().count() == len` is redundant with `all(is_ascii_digit)` (ASCII implies one byte per char); harmless.
- `year.is_multiple_of` needs Rust >= 1.87 and `Cargo.toml` has no `rust-version`; a pin would make the MSRV explicit before ZG-4 adds a Wasm toolchain.
- `date_part` truncates at the first space regardless of what follows, so `2020 (approx)` parses as `2020`. Consistent with the contract's "truncated at the `T` or space", but worth a locking test.

BLESS ZG-2 phase-1 — pure `IsoDate` calc with no byte indexing, `emit` derives slug year and current-state from one parsed token, flat matches throughout, contract §5.3 matches the code, all gates green.

## Phase 1 — Tester

Mandate: ensure every calculation and public item has complete, layered, deterministic tests following Arrange-Act-Assert with exhaustive error-path coverage so the codebase stays reliably maintainable, verifiable, and handover-clean — zero tolerance, delegate all fixes.

Verification: `cargo test` 16 unit / 9 acceptance / 2 fixtures / 13 wild green; pedantic clippy clean. Mutation runs against a scratch copy (`/tmp/zg2-mut`, product tree untouched):

| Mutant | Killed by |
|---|---|
| `parse_iso_date` returns `None` for everything | 4 unit, 2 acceptance, 2 fixtures, 5 wild (incl. `fixture_rz_resume_tree_matches_example`, `long_resume_html_is_crate_output`) — acceptance lock holds |
| day validation replaced by `1..=31` | `validates_day_against_month_and_leap_year` |
| leap arm removed | `validates_day_against_month_and_leap_year` |
| `T`/space truncation removed | `truncates_time_component_at_t_or_space`, `formats_fixture_dates` |
| `is_current` computed from raw start | `unparseable_start_date_is_span_without_datetime`, `unparseable_start_does_not_mark_current` |
| `chars().count()` -> `len()` | equivalent mutant (ASCII-digit check already forces one byte per char); not a gap |
| `days_in_month` fallback `_ => 0` -> `_ => 31` | **SURVIVED** |

AC coverage: every acceptance checkbox has a named test in `renderer/tests/wild.rs` (`multibyte_start_date_does_not_panic`, `timestamp_release_date_truncates`, `unparseable_start_date_is_span_without_datetime`, `unparseable_start_does_not_mark_current`, `invalid_calendar_day_is_unparseable` + `leap_day_is_valid`, `present_end_date_is_span`); acceptance and fixture locks green; contract grep green; `just verify` exit 0. `render_json` error paths: empty input, malformed JSON, wrong field type (`{"basics":{"name":[]}}`, `{"work":{}}`) each have a test. The serde `[]`-as-positional-struct quirk is locked by `render_json_accepts_empty_array_as_empty_basics` with a doc comment naming ZG-3 as the owner of the decision.

Boundary coverage present: month `00`/`13`, `2020-1` strict padding, day `00`, Apr 31, Feb 29 for 1900/2000/2020/2021/2024, Feb 30, `T` and space timestamps, surrounding whitespace, empty string, `-`, fullwidth/kanji/euro strings, `March 2020`, `Present`.

TEST VERDICT: REJECTED

The calculation `days_in_month` has an explicitly documented fallback arm ("`0` for a month outside `1..=12`") that no test reaches: `2020-13` is only tested at month precision, so `(Some(month), Some(day))` with an out-of-range month is never exercised and the surviving mutant proves a regression there (accepting `2020-13-01` or `2020-00-15` as `<time datetime="2020-13-01">`) would ship unnoticed. Day 32 and a four-part string are likewise asserted nowhere. These are the exact boundaries the checklist names (month 0/13, day 0/32); "the other arm covers it" is not an answer. "It works on my machine is not an answer."

Missing tests:
- `parse_iso_date("2020-13-01")` and `parse_iso_date("2020-00-15")` must be `None` (kills the `days_in_month` fallback mutant)
- `parse_iso_date("2020-01-32")` must be `None` (day > 31 upper bound)
- `parse_iso_date("2020-01-01-01")` must be `None` (four-part `_ => return None` arm)
- (non-blocking, hand to ZG-3 with the serde quirk) lock `date_part` space truncation on non-time text: `parse_iso_date("2020 (approx)")` currently yields `Some(2020)`; assert whichever behavior the contract intends

Delegate to `rust-code-writer`: add the four assertions to `date::tests` (`rejects_unpadded_month_and_month_zero` / `validates_day_against_month_and_leap_year` or one new `rejects_out_of_range_parts` test). No production change required; the code is correct, the lock is missing.

REJECT ZG-2 phase-1 — `days_in_month` out-of-range fallback and day-32 / four-part boundaries have no test; mutant `_ => 31` survives the full suite.

## Phase 1 — Architect (pass 1, superseded)

Not run: chain stopped at the Tester REJECT. Re-submission reviewed below.

## Phase 1 — Reviewer (pass 2)

Mandate: write layered, modular Rust code built from pure calculations on immutable data; isolate actions at the edges; prefer std; use strong typing and composition so any human can understand and safely modify the system.

Re-submission diff: one new unit test in `renderer/src/date.rs` (`rejects_out_of_range_parts_at_day_precision`) and one sentence appended to `skeleton/CLASS-CONTRACT.md` §5.3 "Unparseable dates". No production code changed (`git diff` on `date.rs` outside `mod tests` is byte-identical to pass 1; `emit.rs`, `slug.rs` untouched since pass 1). Self-verified from `renderer/`: `cargo fmt --all` no-op; `cargo clippy --all-targets -- -D warnings -D clippy::pedantic` clean; `cargo test` 17 unit / 9 acceptance / 2 fixtures / 13 wild green. `grep -rn "allow(clippy" renderer/src renderer/tests` still empty.

Checklist on the delta:
- The new test is AAA with labelled sections, one named fixture array, `assert_eq!(parsed, None, "{raw:?}")` so a failure names the input. Name says what is rejected (`out_of_range_parts`) and at which precision (`day`). It does not duplicate `rejects_unpadded_month_and_month_zero` (month precision) — the two tests own different arms of `is_calendar_valid`. Correct.
- The four inputs map one-to-one to the Tester's demand: `2020-13-01`, `2020-00-15` (both hit `days_in_month`'s `_ => 0` arm through `(Some(month), Some(day))`), `2020-01-32` (day upper bound), `2020-01-01-01` (the `_ => return None` slice arm). Nothing extra was smuggled in.
- Contract sentence: "still emits the `.rz-date--present` `Present` span, but the entry is not `.rz-is-current`, and the `startYear` in `data-rz-entry` is the year of the *parsed* `startDate` (no year segment when it is unparseable)". Cross-checked against code: `emit_range_end(None)` emits the `Present` span unconditionally when `end` is `None`; `is_current` requires `token.parsed.is_some()`; `emit_entry` computes `year` from `token.parsed` and `entry_slug(primary, None, ..)` yields `primary` alone. Locked by `wild::unparseable_start_does_not_mark_current` (asserts `rz-date--present` present, `rz-is-current` absent) and `wild::unparseable_start_year_is_dropped_from_slug` (`data-rz-entry="x"` vs `"x-2020"`). Sentence matches code and tests. No new class or attribute, so no `data-rz-schema` bump. Correct.
- Pass-1 nits still open, still non-blocking: §1 invariant 3 parenthetical; `IsoDate` public fields; `chars().count()` redundancy; `rust-version` pin (handed to Architect); `2020 (approx)` lock (handed to ZG-3).

BLESS ZG-2 phase-1 — re-submission is exactly the demanded test plus one contract sentence, both verified against the code and existing wild locks; no production change, all gates green.

## Phase 1 — Tester (pass 2)

Mandate: ensure every calculation and public item has complete, layered, deterministic tests following Arrange-Act-Assert with exhaustive error-path coverage so the codebase stays reliably maintainable, verifiable, and handover-clean — zero tolerance, delegate all fixes.

Verification: `cargo test` 17 unit / 9 acceptance / 2 fixtures / 13 wild green; pedantic clippy clean. `PROBE_PORT=4374 just verify` exit code **0** (90 PASS, 0 FAIL).

Mutant re-run (scratch copy `/tmp/zg2-mut`, product tree untouched): `days_in_month` fallback `_ => 0` -> `_ => 31`. Reasoning: with `_ => 31`, `is_calendar_valid(IsoDate{2020, Some(13), Some(1)})` evaluates `1 >= 1 && 1 <= 31` = `true`, so `parse_iso_date("2020-13-01")` returns `Some(IsoDate { year: 2020, month: Some(13), day: Some(1) })` instead of `None`. `rejects_out_of_range_parts_at_day_precision` iterates its array in order and the first element is `"2020-13-01"`, so that assertion fails first. Confirmed empirically:

```
test date::tests::rejects_out_of_range_parts_at_day_precision ... FAILED
  left: Some(IsoDate { year: 2020, month: Some(13), day: Some(1) })
 right: None
test result: FAILED. 16 passed; 1 failed
```

`"2020-00-15"` would also kill it (same arm, `15 <= 31`). `"2020-01-32"` exercises the genuine `31` arm and is unaffected by this mutant — it locks the day upper bound against a hypothetical `<=` -> `<` flip or a `days_in_month + 1` off-by-one instead. `"2020-01-01-01"` reaches neither: it dies at `parts.as_slice()` with four elements, locking the `_ => return None` arm that previously had zero coverage.

Updated mutant table: all seven mutants from pass 1 are now killed or proven equivalent (`chars().count()` -> `len()`). No surviving mutant.

Remaining test-quality observations (non-blocking, already on the ZG-3 hand-off list): `2020 (approx)` truncation behaviour unlocked; `IsoDate::visible` for a month outside `1..=12` is unreachable through `parse_iso_date` but reachable through the public struct constructor inside the crate — the `_ =>` fallback in `visible` is untested, and would become testable if `IsoDate` gained a private constructor or an enum precision (Architect's call).

BLESS ZG-2 phase-1 — the surviving mutant is killed by a named AAA test whose first assertion fails for exactly the predicted reason; day-32 and four-part boundaries locked; `just verify` exit 0.

## Phase 1 — Architect

Mandate: protect the long-term clarity and evolvability of the system above all else.

System context read: `AGENTS.md` (stack lock: renderer is a pure crate, also compiled to Wasm; themes see only the class contract), `renderer/src/lib.rs` (module graph `resume` -> `date`/`slug` -> `emit` -> `html`, all modules private, public surface is `render`, `render_json`, `CONTRACT_VERSION`, the `resume` types), Pinto ZG-3 (wild files, depends on ZG-2) and ZG-4 (Wasm parity, depends on ZG-1).

1. Strata intact. Before this change the `slug` layer parsed dates (`iso_year` did byte slicing on user text) and `emit` parsed them again through `format_iso_date`, so two layers held two different opinions about what a date was — that is the root cause of Devon's slug/current disagreement, not a bug in either function. The diff deletes `iso_year` rather than patching it, and `entry_slug` now takes `Option<u16>`: slug knows about years as numbers, nothing about date syntax. `date` depends on nothing in the crate; `slug` depends on nothing in the crate; `emit` is the only module that composes them. Dependency direction is strictly downward and there is one fewer edge than before. This is the right shape.

2. `IsoDate` is a real domain calculation, not a string-formatting helper. It is a value (`Copy`, `Eq`), produced by one total function `&str -> Option<IsoDate>`, with two pure projections (`datetime`, `visible`). The old `format_iso_date` returned `(String, String)` — a tuple of presentation strings, which is not a domain object and could not be reasoned about. Tests now assert structure, not rendered text. Good. Two reservations, neither blocking: (a) `year: u16, month: Option<u8>, day: Option<u8>` admits `{month: None, day: Some(_)}`; the module is private so the illegal state cannot escape the crate, and `datetime`/`visible` degrade it to year precision rather than panicking, so it is contained. When ZG-4 needs a Wasm ABI the crate boundary stays `render_json(&str) -> Result<String>`, so `IsoDate` never crosses it and the representation is free to change later. (b) `digits<N: FromStr>` is generic over the return type where only `u16` and `u8` are ever used; harmless, but a second reader will wonder why. Leave it.

3. `DateToken` placement is correct. It is `{raw: &str, parsed: Option<IsoDate>}` — the pairing of what the Author wrote with what the renderer decided — and that pairing is an HTML-emission concern (`<time>` vs `<span>`), not a date concern. Putting it in `date.rs` would leak the contract's fallback policy into the calculation layer. Keeping it private to `emit.rs`, `Copy`, and constructed by a single `date_token` lift means `EntryBits` carries one type for all three date slots and `emit_entry` reads `token.parsed` once for both slug year and current-state. One source of truth, one place to change it.

4. Present-without-current semantics are coherent. The three states are now orthogonal and each has a single owner: the visible `Present` span is a function of `end == None` alone (`emit_range_end`); `.rz-is-current` is a function of `start.parsed.is_some() && end.is_none()` (`emit_entry`); the slug year is a function of `parsed` (`emit_entry`). A theme author reads "Present" as "the Author omitted an end", and `.rz-is-current` as "the renderer trusts the start". Those are different facts and the contract now states both explicitly (§5.3 sentence added this pass). For ZG-4 parity this matters because the Wasm build must produce byte-identical HTML for the same JSON; all three decisions are pure functions of the parsed token with no locale, clock, or platform input, so parity is structural rather than something to be tested into existence. For ZG-3 it matters because "wild" files will have many unparseable dates and the entry must survive with its raw text visible; that guarantee lives in `emit_date`'s `None` arm and nowhere else.

5. `rust-version`. `u16::is_multiple_of` stabilised in Rust 1.87; the local toolchain is 1.94.1 and `Cargo.toml` carries no `rust-version`, no `rust-toolchain.toml` exists. Today nothing pins it. ZG-4 introduces a second toolchain target (`wasm32-unknown-unknown`, probably via `wasm-pack` or `trunk` on a CI image) and that is exactly when an unpinned MSRV bites. This is not a ZG-2 defect — ZG-2 did not introduce the toolchain drift, it merely used a recent std method — but it is a ZG-4 precondition: add `rust-version = "1.87"` (or whatever ZG-4's CI image provides) to `renderer/Cargo.toml` as the first commit of ZG-4, before any Wasm work.

6. Two-year question. The `emit_dates` match `(Some(date), _, _) | (None, None, Some(date))` folds "single date" and "end date without start" into the same arm. That is the pre-existing behaviour preserved, and it is the reasonable choice, but the contract does not name the end-only case. Someone in 2028 will hit a wild file with `endDate` and no `startDate` and not know whether the plain `.rz-date` (no `--end` modifier) is intended. One row in §5.3 would close it; hand to ZG-3 alongside the `2020 (approx)` lock.

Nothing here increases accidental complexity; the diff removes a layer violation, replaces a tuple with a value type, and collapses a 70-line branchy emitter into three flat functions with one match each.

BLESS ZG-2 phase-1 — strata are cleaner than before the change (one fewer date-parsing site, dependency edges only downward), `IsoDate` is a proper value type confined to the crate, `DateToken` sits in the only layer that cares about the `<time>`/`<span>` decision, and Present/current/slug are three independent pure functions of one parsed token, which is what ZG-4 Wasm parity needs. Follow-ups: `rust-version` pin as ZG-4's first commit; end-only date row and `2020 (approx)` lock to ZG-3.
