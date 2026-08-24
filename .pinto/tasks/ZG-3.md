+++
id = "ZG-3"
title = "Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs"
status = "todo"
rank = "k"
labels = ["avril", "round-1", "renderer", "avril-blessed"]
depends_on = ["ZG-1", "ZG-2"]
created = "2026-08-23T23:53:41.429847Z"
updated = "2026-08-24T01:13:24.266843Z"
+++

## Why
Marcus's real file (numeric `score`) was rejected wholesale and Devon's edge fixtures produced empty `<li>`s, junk ids and unsafe hrefs; "a file from the wild is valid input" must be true before Authors paste (Marcus, Devon).
## Covers
D2, D4, D5 — Marcus, Devon
## Scope in
- `education[].score` accepts a JSON number (integer or float) or string (serde helper `string_or_number`); `3.7` renders `GPA 3.7`, `4` renders `GPA 4`
- Certificate / publication with only `url` → primary text is the hostname wrapped in `.rz-entry-primary-link`; an `<li class="rz-entry">` with no child nodes is impossible
- `basics.profiles[]` with `network` + `username` but no `url` → `.rz-link` with `.rz-link-label` and a plain `<span class="rz-link-value">` (no `<a>`); contract §5.2 updated to say so
- Normalize `\r\n` → `\n` before paragraph/bullet splitting in `emit_prose`
- URL hygiene: a profile / contact / entry URL with an empty hostname (`https://`, `//`) or a non-`http(s)`/`mailto:`/`tel:` scheme (`javascript:alert(1)`) is never emitted as an `href`; the value is emitted as plain text (`username` for a profile, hostname for `basics.url`); when that plain text would be empty the whole `.rz-link` / `.rz-contact` `<li>` is omitted, and an empty `.rz-links` / `.rz-contacts` wrapper is omitted with it (Invariant 5: omit empties) — contract §5.2 states both rules
- Slug fallback: when the slugified name part is empty, use `entry` / `skill` before appending year or counter (`🔥🔥`+2020 → `entry-2020`; second → `entry-2020-2`; skill `🎨` → `skill`)
- Emit `dir="auto"` on `.rz-resume`; contract §3 lists it as an attribute (no class added, no `data-rz-schema` bump)
- Tests are appended to `renderer/tests/wild.rs` (created by ZG-2 — never a second wild-input test file)
## Scope out
- Rendering `work[].description` — contract 1.0 §5.4 says "not rendered"; changing the field map is a contract 1.1 decision, not a bug fix (Marcus D5, cut with reason)
- Highlight `\n` inside one bullet — that is theme whitespace (ZG-12)
- Per-field warnings surfaced to the Author (ZG-5 shows parse errors; field-level lint is later)
- Coercing types other than `score` (no evidence yet)
## Acceptance criteria
- [ ] `cargo test --test wild` (tests appended to `renderer/tests/wild.rs` after ZG-2's): rendering `{"basics":{"name":"M"},"education":[{"institution":"U","score":3.7}]}` returns `Ok` and contains `<p class="rz-score">GPA 3.7</p>`; `"score":"3.7"` renders identically; `"score":4` renders `<p class="rz-score">GPA 4</p>`; `"score":"First Class"` renders `First Class`
- [ ] Rendering `{"basics":{"name":"M"},"certificates":[{"url":"https://verify.example/abc"}]}` emits `<a class="rz-entry-primary-link" href="https://verify.example/abc">verify.example</a>`; rendering `{"basics":{"name":"M"},"publications":[{"url":"https://doi.example/10.1/x"}]}` emits `<a class="rz-entry-primary-link" href="https://doi.example/10.1/x">doi.example</a>`; the regex `<li class="rz-entry[^>]*>\s*</li>` matches nothing in the output of every fixture rendered by `renderer/tests/`
- [ ] Rendering a profile `{"network":"Keybase","username":"marcus"}` emits `<li class="rz-link rz-link--other"` containing `<span class="rz-link-value">marcus</span>` and no `<a` inside that `li`
- [ ] Rendering `basics.summary = "Para one.\r\n\r\nPara two."` emits exactly two `<p>` inside `.rz-summary`
- [ ] Rendering `{"basics":{"name":"M","profiles":[{"network":"Site","url":"https://"}]}}` (Devon's fixture: bad URL, no `username`) emits no `<li class="rz-link` and no `<nav class="rz-links"` at all; rendering a profile `{"network":"Site","username":"marcus","url":"javascript:alert(1)"}` emits `<li class="rz-link rz-link--other"` containing `<span class="rz-link-value">marcus</span>` and no `href` inside that `li`; `basics.url = "javascript:alert(1)"` emits no `rz-contact--url`; the output contains no `javascript:` anywhere
- [ ] The regex `<li class="rz-(link|contact)[^>]*>\s*(<span class="rz-(link|contact)-label">[^<]*</span>\s*)?</li>` (a link/contact item with no value node) matches nothing in the output of every fixture rendered by `renderer/tests/`
- [ ] Rendering two work entries named `🔥🔥` with `startDate` `2020` yields `data-rz-entry="entry-2020"` then `data-rz-entry="entry-2020-2"`; a skill group named `🎨` yields `data-rz-skill-group="skill"`
- [ ] Output `<article class="rz-resume"` carries `dir="auto"`; `skeleton/example.html` is regenerated to match and `cargo test --test acceptance` is green; `skeleton/CLASS-CONTRACT.md` §3 table lists `dir`; `grep -n "omitted entirely" skeleton/CLASS-CONTRACT.md` hits inside §5.2
- [ ] BAR-R1 still holds: `{ "basics": { "name": "Ada" } }` renders `Ada` and no `Jordan Hale`, `#rz-experience`, contacts, or photo
- [ ] `just verify` green
## Dependencies
- ZG-1
- ZG-2 (owner of `renderer/tests/wild.rs`)
## Notes
- `dir="auto"` and `<span class="rz-link-value">` are attribute/element-shape changes inside existing classes; the Generator treats them as non-breaking under contract §9 (no rename, no new class). CTO to confirm or demand a `1.1` bump.
