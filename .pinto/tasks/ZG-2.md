+++
id = "ZG-2"
title = "Never panic on a wild date: tolerate timestamps, drop unparseable dates"
status = "todo"
rank = "j"
labels = ["avril", "round-1", "avril-blessed"]
depends_on = ["ZG-1"]
created = "2026-08-23T23:53:41.365926Z"
updated = "2026-08-24T01:13:07.398128Z"
+++

## Why
Devon's fullwidth-digit date crashed the whole render and Marcus's conference talk silently lost its date; a wild JSON Resume must always render (Devon, Marcus; also protects every Author who pastes in ZG-5 and every hosted page in ZG-21).
## Covers
D1, D3 — Devon, Marcus
## Scope in
- `renderer/src/slug.rs::iso_year` and `renderer/src/date.rs`: char-boundary-safe year extraction; never index bytes
- `releaseDate`/`startDate`/`endDate`/`date` with a time component (`2023-05-31T09:00:00Z`) → truncate at `T`/space to the date part and render it
- Unparseable date (`March 2020`, `Present` as endDate, `2020-13`, `２０２０`, `日本語`) → emit `<span class="rz-date …">` with the raw text and **no** `datetime` attribute; never `<time datetime="March 2020">`
- Entry gets `rz-is-current` / `data-rz-current` only when `startDate` parses and `endDate` is absent; an unparseable start never marks current
- Validate day against month incl. leap years (`2020-02-30` → unparseable; `2024-02-29` → valid)
- Document the rule in `skeleton/CLASS-CONTRACT.md` §5.3 "Dates" (no `data-rz-schema` bump: no class or attribute is added)
## Scope out
- Locale-formatted dates other than English (contract §8 says renderer owns words; i18n is not this round)
- Numeric `score` and other type coercion (ZG-3)
- Rejecting the document on a bad date — the entry must survive
## Acceptance criteria
- [ ] `cargo test --test wild` in `renderer/` has a test `multibyte_start_date_does_not_panic` that calls `render_json` on `{"basics":{"name":"A"},"work":[{"name":"X","startDate":"２０２０"}]}` and on `startDate: "日本語"`, `"€€"`, `"20€0"`, and asserts `Ok(_)` for each
- [ ] Rendering `{"publications":[{"name":"Talk","releaseDate":"2023-05-31T09:00:00Z"}]}` emits `<time class="rz-date" datetime="2023-05-31">May 31, 2023</time>`
- [ ] Rendering `work[0].startDate = "March 2020"` emits `<span class="rz-date rz-date--start">March 2020</span>` and the output contains no `datetime="March 2020"` and no `rz-is-current`
- [ ] Rendering `work[0].startDate = "2020-13"` (no endDate) emits no `<time` inside that entry, no `rz-is-current`, no `data-rz-current`, and still emits `<h3 class="rz-entry-primary">`
- [ ] Rendering `startDate = "2020-02-30"` emits no `<time`; `startDate = "2024-02-29"` emits `datetime="2024-02-29"`
- [ ] `endDate: "Present"` with a valid `startDate` renders start as `<time datetime>` and end as `<span class="rz-date rz-date--end">Present</span>` without `datetime`
- [ ] `skeleton/resume.json` still renders byte-identical to `skeleton/example.html` (`cargo test --test acceptance` green)
- [ ] `skeleton/CLASS-CONTRACT.md` §5.3 states the timestamp-truncation and unparseable→`span` rule (grep `unparseable`)
- [ ] `just verify` green
## Dependencies
- ZG-1
## Notes
- none
