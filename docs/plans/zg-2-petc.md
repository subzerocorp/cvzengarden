# ZG-2 PETC — Never panic on a wild date: tolerate timestamps, drop unparseable dates

**PBI:** ZG-2 (triple-blessed) · deps ZG-1 done
**AXEL:** Generator `code-writer` + `rust-code-writer` + `rust-errors`; adversaries `rust-code-reviewer` → `rust-code-tester` → `rust-architect`
**Decomposition mode:** off

## Goal
Any JSON Resume date string renders without panic: timestamps truncate to the date; unparseable strings become `<span class="rz-date …">` without `datetime`; `rz-is-current` only when start parses and end is absent; day/month/leap validated. Fixture lock unchanged.

## Approach
Pure date calc in `date.rs` (`parse_iso_date -> Option<IsoDate>` with y/m/d validation and `T`/space truncation); `slug.rs::iso_year` built on chars, never byte indices; `emit.rs` date emission chooses `<time datetime>` vs `<span>` from the parse result; current-marking derived from the parsed start. Tests in `renderer/tests/wild.rs` (owner: ZG-2; ZG-3 appends).

## Files likely
`renderer/src/{date,slug,emit}.rs`, `renderer/tests/wild.rs`, `skeleton/CLASS-CONTRACT.md` §5.3.

## Test strategy
One named test per AC (`multibyte_start_date_does_not_panic`, timestamp, `March 2020`, `2020-13`, Feb 30 / Feb 29, `Present`), acceptance tree lock green, fixtures lock green (long-resume has only valid dates → byte-identical), clippy pedantic, `just verify`.

## Risk
Date-format change must not touch valid dates (locks catch it).

## Phases
1. **Phase 1 of 1**

## Unresolved questions
- none
