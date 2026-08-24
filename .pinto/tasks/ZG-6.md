+++
id = "ZG-6"
title = "Explain the résumé format in plain words and start from a sample"
status = "todo"
rank = "n"
labels = ["avril", "round-1", "chrome"]
depends_on = ["ZG-5"]
created = "2026-08-23T23:54:23.466605Z"
updated = "2026-08-23T23:59:42.180102Z"
+++

## Why
Priya never learned the site wants "JSON Resume" and Elena could only start from the sample by hand-editing View Source; naming the format, showing a copyable example, and one-click "Start from a sample" (including a short junior sample) lets a first-timer begin (Priya, Elena, Mika for the fuller sample).
## Covers
A2, A3, C8 (sample lacks `rz-photo` / `rz-score`) — Priya, Elena, Mika
## Scope in
- In the paste panel (ZG-5): one sentence naming **JSON Resume** with a link to `https://jsonresume.org/schema`, and a copyable 8–12 line example (`<pre>` + "Copy" button) with `basics.name`, `label`, `email`, one `work` entry
- Buttons "Start from Jordan's sample" (loads `skeleton/resume.json` into the textarea and renders) and "Start from a short sample" (loads `skeleton/samples/junior.json`)
- New `skeleton/samples/junior.json`: a bootcamp graduate — `basics` with `image` (relative `samples/portrait.svg`, a neutral vector), summary, one retail job, `education` with numeric `score: 3.7` and `courses`, three `projects`, `skills`; no awards/publications/references
- `skeleton/samples/junior.html` rendered by the crate (test-locked like `example.html`) so designers can proof `rz-photo` and `rz-score` on a real skeleton
- Sidebar copy under "Use my résumé": "Your résumé is a small text file (JSON Resume). Paste it, open it, or start from a sample."
## Scope out
- A guided form editor (Phase 5 "ingest")
- Converting PDF/DOCX/LinkedIn into JSON Resume
- Editing the sample in place inside the iframe (`contenteditable`) — the JSON is the document of record
- Changing `skeleton/resume.json` / `example.html` (keeps the RZ-2 byte-lock stable)
## Acceptance criteria
- [ ] Probe `ZG-6/format-named`: chrome `body.innerText` contains `JSON Resume` and an `<a href="https://jsonresume.org/schema">` exists in the paste panel
- [ ] Probe `ZG-6/example-copy`: the panel's `<pre>` parses as JSON with `basics.name` set; clicking "Copy" puts that exact text on the clipboard (Playwright `context.grantPermissions(['clipboard-read'])`)
- [ ] Probe `ZG-6/start-sample`: clicking "Start from Jordan's sample" fills `#paste-input` with the bytes of `skeleton/resume.json` and the sandbox shows `Jordan Hale`
- [ ] Probe `ZG-6/start-junior`: clicking "Start from a short sample" renders a `.rz-name` that is not `Jordan Hale`, exactly one `.rz-entry--experience`, three `.rz-entry--project`, a `.rz-score` containing `GPA 3.7`, an `img.rz-photo-img` with non-empty `alt`, and **no** `#rz-awards`, `#rz-publications`, `#rz-references`
- [ ] Probe `ZG-6/junior-all-themes`: the junior sample in each of Nightgarden, Quarto, Switchyard has no horizontal scrollbar at 1280px and prints to ≤ 2 pages (Playwright `page.pdf`)
- [ ] `cargo test --test acceptance` in `renderer/` locks `skeleton/samples/junior.json` → `skeleton/samples/junior.html` `.rz-resume` bytes
- [ ] `skeleton/samples/junior.json` validates against `jsonresume/resume-schema` `schema.json` (a Node or Rust test that runs the schema; name the runner in evidence)
- [ ] `git diff --stat skeleton/resume.json skeleton/example.html` is empty
- [ ] A stub that hard-codes the junior HTML instead of rendering the JSON fails the `GPA 3.7` probe once `score` is changed in the fixture
## Dependencies
- ZG-5
## Notes
- Schema validation runner: prefer a dev-only dependency already in `frontend/` (none exists); if `ajv` is needed as a devDependency, that is a third-party addition for human approval — alternative is a Rust test using `jsonschema` crate (also third-party). Generator proposes `ajv` dev-only.
