+++
id = "ZG-3"
title = "Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs"
status = "todo"
rank = "k"
labels = ["avril", "round-1", "renderer"]
depends_on = ["ZG-1"]
created = "2026-08-23T23:53:41.429847Z"
updated = "2026-08-23T23:59:42.150791Z"
+++

## Why
Marcus's real file (numeric `score`) was rejected wholesale and Devon's edge fixtures produced empty `<li>`s, junk ids and unsafe hrefs; "a file from the wild is valid input" must be true before Authors paste (Marcus, Devon).
## Covers
D2, D4, D5 — Marcus, Devon
## Scope in
- `education[].score` accepts a JSON number or string (serde helper `string_or_number`); `3.7` renders `GPA 3.7`
- Certificate / publication with only `url` → primary text is the hostname wrapped in `.rz-entry-primary-link`; an `<li class="rz-entry">` with no child nodes is impossible
- `basics.profiles[]` with `network` + `username` but no `url` → `.rz-link` with `.rz-link-label` and a plain `<span class="rz-link-value">` (no `<a>`); contract §5.2 updated to say so
- Normalize `\r\n` → `\n` before paragraph/bullet splitting in `emit_prose`
- URL hygiene: profile/entry URL with empty hostname (`https://`, `//`) or non-`http(s)`/`mailto:`/`tel:` scheme (`javascript:alert(1)`) → link omitted (primary emitted as plain text)
- Slug fallback: when the slugified name part is empty, use `entry` / `skill` before appending year or counter (`🔥🔥`+2020 → `entry-2020`; second → `entry-2020-2`; skill `🎨` → `skill`)
- Emit `dir="auto"` on `.rz-resume`; contract §3 lists it as an attribute (no class added, no `data-rz-schema` bump)
## Scope out
- Rendering `work[].description` — contract 1.0 §5.4 says "not rendered"; changing the field map is a contract 1.1 decision, not a bug fix (Marcus D5, cut with reason)
- Highlight `\n` inside one bullet — that is theme whitespace (ZG-12)
- Per-field warnings surfaced to the Author (ZG-5 shows parse errors; field-level lint is later)
- Coercing types other than `score` (no evidence yet)
## Acceptance criteria
- [ ] `cargo test --test wild`: rendering `{"basics":{"name":"M"},"education":[{"institution":"U","score":3.7}]}` returns `Ok` and contains `<p class="rz-score">GPA 3.7</p>`; `"score":"3.7"` renders identically; `"score":"First Class"` renders `First Class`
- [ ] Rendering `{"certificates":[{"url":"https://verify.example/abc"}]}` emits `<a class="rz-entry-primary-link" href="https://verify.example/abc">verify.example</a>` and no `<li class="rz-entry rz-entry--extra" data-rz-entry="entry"></li>`; a regex over all output `<li class="rz-entry[^>]*>\s*</li>` matches nothing for every fixture in `renderer/tests/`
- [ ] Rendering a profile `{"network":"Keybase","username":"marcus"}` emits `<li class="rz-link rz-link--other"` containing `<span class="rz-link-value">marcus</span>` and no `<a` inside that `li`
- [ ] Rendering `basics.summary = "Para one.\r\n\r\nPara two."` emits exactly two `<p>` inside `.rz-summary`
- [ ] Rendering a profile `url: "https://"` emits no `<a` for that profile; `url: "javascript:alert(1)"` emits no `href="https://javascript:` and no `javascript:` anywhere in output
- [ ] Rendering two work entries named `🔥🔥` with `startDate` `2020` yields `data-rz-entry="entry-2020"` then `data-rz-entry="entry-2020-2"`; a skill group named `🎨` yields `data-rz-skill-group="skill"`
- [ ] Output `<article class="rz-resume"` carries `dir="auto"`; `skeleton/example.html` is regenerated to match and `cargo test --test acceptance` is green; `skeleton/CLASS-CONTRACT.md` §3 table lists `dir`
- [ ] BAR-R1 still holds: `{ "basics": { "name": "Ada" } }` renders `Ada` and no `Jordan Hale`, `#rz-experience`, contacts, or photo
- [ ] `just verify` green
## Dependencies
- ZG-1
## Notes
- `dir="auto"` and `<span class="rz-link-value">` are attribute/element-shape changes inside existing classes; the Generator treats them as non-breaking under contract §9 (no rename, no new class). CTO to confirm or demand a `1.1` bump.
