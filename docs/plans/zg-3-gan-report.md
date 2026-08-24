# ZG-3 GAN report — Render wild JSON Resume files

Adversaries run in sequence on the uncommitted working tree of `garden/persona-loop` (2026-08-24). Gates re-run by the adversaries, not taken from the Generator's evidence: `cargo fmt --check` exit 0; `cargo clippy --all-targets -D warnings -D clippy::pedantic` clean; `cargo test` 27 / 9 / 2 / 28 green; `PROBE_PORT=4385 just verify` — see the line at the end of each voice.

## Phase 1 — Reviewer

Files: `renderer/src/{emit,url,resume,slug,date,lib}.rs`, `renderer/tests/wild.rs`, `skeleton/{CLASS-CONTRACT.md,example.html}`, `frontend/fixtures/long-resume.html`, `frontend/generated/sandbox.html`.

**emit.rs restructure — simpler and flatter, yes.** The old file had nine `*_has_content` predicates, one per record type, each hand-mirroring what `emit_entry` would later print; that mirror is exactly the bug Devon hit (`certificate_has_content` said yes, `emit_entry` had nothing to hang the link on). The new shape computes an `EntryBits` view model first and asks the view model (`EntryBits::has_content`) whether it will produce a child node, then `emit_entry_section` filters on that one predicate and drops the section when nothing survives. One truth, not nine. That is the minimum honest way to make "no empty `li` possible" a property rather than a coincidence, so it is in scope. The four unwrap/expect sites the ZG-1 follow-ups named (`expect("filtered")` in links, two `.unwrap()` in languages/interests, `bits.primary.unwrap_or("")`) are gone; `contacts()` / `profile_link()` / `primary_link()` are `filter_map`-shaped calculations and the emit functions are pure actions over rows. `grep unwrap\|expect(` on `src/` outside `cfg(test)` is empty except `unwrap_or(&[])` / `unwrap_or("")` defaults, which are not panics.

**Scope check, honestly.** In scope by the PBI or the ZG-1/ZG-2 hand-offs: `string_or_number`, `url.rs`, the view models, `Section` consts (they replace the 5-positional-arg `open_section(html, id, title, extra, kind)` that the restructure touched at every call site; a struct with named fields is the flatter form of the same data — mild, but earned), `dir="auto"`, slug fallbacks, CRLF, contract wording, lock regeneration. Beyond the PBI bullets but explicitly handed to ZG-3 by the ZG-2 Architect/Tester (`docs/plans/zg-2-gan-report.md` lines 57, 120, 124): the `date_part` change so `2020 (approx)` is no longer truncated to `2020`, the `endDate`-without-`startDate` contract row, and the serde `[]` decision. The `date_part` change is a behaviour change, not just a lock; the hand-off said "assert whichever behavior the contract intends" and the Generator chose the stricter reading and wrote it into §5.3 with a reason (an Author's hedge must not become a machine `datetime`). I agree with the choice and it is documented in the contract, so it passes — but it should be named in the commit message as a ZG-2 hand-off, not buried. Nothing else crept in: `emit_skills`, `emit_languages`, `emit_dates`, `html.rs`, `profile_type`, `tel_href` are behaviour-identical.

**url.rs correctness.**
- Scheme detection follows RFC 3986 §3.1 (`ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ) ":"`). Consequence: `localhost:8080` and `example.com:443/x` are read as a scheme and rejected (`None`). Acceptable — the alternative (guessing that a scheme-shaped token is a host:port) is precisely the ambiguity that makes `javascript:` slip through, and a bare host with an explicit port in a résumé is vanishingly rare. Contract §5.2 already says "a `scheme:`-shaped token" is never an href. Followup, not blocker.
- `//host` → `https://host`; `//` → `None`; `https:///path` → `None` (host empty after strip). Correct.
- Bare `example.com/me` → `https://example.com/me`. Correct and matches the pre-existing `abs_http_url` behaviour Marcus praised.
- Whitespace: `raw.trim()` runs first, so `" http://example.com "` and `"\tjavascript:alert(1)"` are both handled; the returned href is the trimmed string. A tab or newline *inside* a token (`java\nscript:alert(1)`) fails `has_scheme` and becomes `https://java\nscript:…`; `escape_attr` keeps it a harmless string. Fine.
- Uppercase schemes: `has_scheme` is case-insensitive by construction (any ASCII letters), so `JAVASCRIPT:`, `JavaScript:`, `Data:` are all `None` (unit test `rejects_empty_hosts_and_foreign_schemes` includes `JAVASCRIPT:alert(1)`). The flip side: `HTTPS://example.com` is also `None` because `strip_http_scheme` is case-sensitive, so an uppercase-scheme good URL is rendered as plain text instead of a link. Fails safe; RFC says schemes are case-insensitive, so this is a followup (`eq_ignore_ascii_case` on the first 7/8 bytes), not a blocker.
- `hostname` is documented as "of an `http(s)` URL (or bare host)"; callers only pass it hrefs that came out of `safe_href`, and `safe_href` can return `mailto:`/`tel:` values. `primary_link(None, Some("mailto:a@b.example"))` therefore renders the primary text as `mailto:a@b.example`, and `basics.url = "tel:+1555"` yields a Website contact reading `tel:+1555`. Not wrong, not empty, escaped — but the contract says "hostname" and this is not one. Followup: either `hostname` returns `None` for opaque schemes and the callers fall through to omission, or the contract says "the href itself for `mailto:`/`tel:`".
- `has_host` → `hostname` → `strip_http_scheme` re-runs on a string that already had the scheme stripped; harmless because a stripped remainder never starts with `http://`, but `has_host` could take `rest.split(...)` directly. Nit.

**`string_or_number`.** `#[serde(untagged)]` over `String | serde_json::Number` is the right tool: `serde_json::Number::to_string` prints `3.7` as `3.7` and `4` as `4` (no `4.0`), and `1e2` prints as `100.0` — acceptable for a GPA field. `Option<StringOrNumber>` keeps `null`/missing as `None`. Other shapes error with serde's own untagged message ("data did not match any variant"), which is less precise than the old `expected a string` — ZG-5 will surface parse errors to the Author, so note it there. `From<StringOrNumber> for String` is a clean calculation. No `allow`.

**`Cow` normalisation.** `normalize_newlines` borrows unless `\r\n` is present; used in `emit_prose` and per-bullet in `emit_bullets`. Correct and cheap. `Contact::text` / `Link::text` / `Primary::text` as `Cow<'a, str>` avoid allocating for the common borrowed case; `href: Option<String>` is owned because `safe_href` may synthesise `https://`. Consistent.

**Contract wording vs code — decision: widen the contract, and it is already widened.** The Generator applied hostname-as-primary to every entry kind that has a `url` (work, volunteer, education, certificates, publications, projects) via one `primary_link`, not just certificates/publications. §5.3 now says "When an entry has a safe `url` but no name (a certificate or publication that is only a link), the primary text is the URL's hostname" — the parenthetical reads as an example, not a restriction, and §5.3 is the *shared* dated-entry chrome, so the sentence already governs all kinds. I rule: keep the code, keep the sentence; no narrowing. A nameless `work[]` with only a `url` rendering as `<h3><a>acme.example</a></h3>` is strictly better than an empty `li` or a dropped job.

**example.html / sandbox / long-resume.html** — `git diff` shows exactly one line each (the `<article>` tag gaining `dir="auto"`). Confirmed.

**Contract diff** — §3 shell + table row for `dir`; §5.2 `basics.url`, `.rz-contacts`, `.rz-links`, `.rz-link-value` rows and the new **Safe hrefs** paragraph containing "omitted entirely"; §5.3 primary/hostname/omission sentence, CRLF sentence, `data-rz-entry` slug rule with the `entry` fallback, `endDate`-without-`startDate` row, Timestamps paragraph; §5.4 `description` note; §5.6 `score` accepts a number. All match the code I read. `data-rz-schema` stays `1.0` per the CTO ruling.

Nits (non-blocking): `INTERESTS_ENTRIES` / `INTERESTS_TAGS` differ only in `kind` — a `Section::with_kind` would remove the duplicate; `SKILLS`/`LANGUAGES`/`SUMMARY` consts are defined after their first use (rustc does not care, a reader does); `emit_value` takes `Vec<Attr>` by value only to push — fine, but `text_el` could accept an extra attr.

Gates: fmt clean, clippy pedantic clean, 27/9/2/28.

BLESS ZG-3 phase-1 — the restructure removes nine hand-mirrored predicates and every unwrap site for one view-model truth; `url.rs` fails safe on every hostile shape I could construct, including uppercase schemes; contract text matches code with hostname-as-primary governing all entry kinds via §5.3. Followups: case-insensitive `http(s)://` acceptance; `hostname` of `mailto:`/`tel:` hrefs; name the `2020 (approx)` behaviour change in the commit message.

## Phase 1 — Tester

**AC → named test** (all in `renderer/tests/wild.rs` unless stated; all green):

| AC | Test |
| --- | --- |
| score 3.7 / "3.7" / 4 / First Class | `numeric_score_renders_gpa_prefix` (+ unit `resume::tests::score_accepts_string_float_and_integer`, `score_missing_or_null_is_none`, `score_rejects_other_shapes`) |
| url-only certificate / publication hostname link | `url_only_certificate_and_publication_link_hostname` |
| `<li class="rz-entry[^>]*>\s*</li>` matches nothing, every fixture | `no_entry_li_is_empty_in_any_fixture` |
| Keybase profile → span value, no `<a>` | `profile_without_url_is_span_value` |
| CRLF summary → exactly two `<p>` | `crlf_summary_splits_into_two_paragraphs` (asserts count == 2, both texts, no `\r`) |
| `https://` profile → no `rz-link` li, no `rz-links` nav | `empty_host_profile_without_username_omits_links_nav` |
| `javascript:` profile → span, no `href`, no `javascript:` anywhere | `javascript_profile_url_is_span_value_without_href` |
| `javascript:` basics.url → no `rz-contact--url`, no `javascript:` | `javascript_basics_url_omits_contact` (also asserts no `rz-contacts` wrapper) |
| link/contact valueless regex matches nothing, every fixture | `no_link_or_contact_li_lacks_a_value_in_any_fixture` |
| `🔥🔥` ×2 → `entry-2020`, `entry-2020-2`; `🎨` → `skill` | `emoji_only_names_fall_back_to_entry_and_skill_slugs` (asserts order too) + unit `slug::tests::{emoji_only_name_falls_back_to_entry_and_counts,skill_slug_falls_back_and_counts}` |
| `dir="auto"`; example.html regenerated; acceptance green; contract §3 lists `dir`; "omitted entirely" in §5.2 | `article_carries_dir_auto`; `acceptance::fixture_rz_resume_tree_matches_example` green; contract grep: §3 line 134, §5.2 lines 222/260 |
| BAR-R1 | `ada_name_only_still_renders_bare` + `acceptance::ada_name_only_omits_optional_chrome` |
| `just verify` | see gate line below |

**Sweep scans.** Both regexes are hand-translated to `std` scans (`empty_entry_li`, `valueless_item_li`). Each has a positive self-check inside the same test: a deliberately empty `<li class="rz-entry rz-entry--extra">\n  </li>` is caught; a `rz-link` with only whitespace and a `rz-contact` with only a label span are both caught; a `rz-link` with label + value is *not* caught (negative control). The corpus is 17 inline fixtures + `skeleton/resume.json` + `frontend/fixtures/long-resume.json` — "every fixture rendered by `renderer/tests/`" is honoured, and `all_fixture_html` will fail loudly if a file moves. The `skip_label` translation of `(<span …-label">[^<]*</span>\s*)?` is faithful: `[^<]*` is `rest.find('<')`, the optional group returns `pos` unchanged when the prefix is absent.

**Mutant reasoning** (which test goes red):
- `safe_href` accepts everything → `javascript_profile_url_is_span_value_without_href` (href present, `javascript:` present), `javascript_basics_url_omits_contact`, `empty_host_profile_without_username_omits_links_nav` (an `<a href="https://">` reappears), `unsafe_entry_urls_without_names_omit_the_entries`, and `url::tests::rejects_empty_hosts_and_foreign_schemes`.
- floats stringified as `3.70` → `numeric_score_renders_gpa_prefix` (`GPA 3.7</p>` not found; float ≠ string render) and `resume::tests::score_accepts_string_float_and_integer`.
- slug fallback removed → `emoji_only_names_fall_back_to_entry_and_skill_slugs` (`entry-2020` absent, `skill` absent) and the two slug unit tests.
- CRLF not normalised → `crlf_summary_splits_into_two_paragraphs` (one `<p>`, and `\r` present).
- `dir` missing → `article_carries_dir_auto`, plus `acceptance::fixture_rz_resume_tree_matches_example` / `fixture_document_shell` and `fixtures.rs` lock.
- `emit_entry_section` filter removed → `no_entry_li_is_empty_in_any_fixture` via the `unsafe entry urls` fixture (four entries with only unsafe URLs).
- `.rz-links` wrapper emitted when rows empty → `empty_host_profile_without_username_omits_links_nav`.

**Uppercase `JAVASCRIPT:`.** Tested at the unit level (`url::tests::rejects_empty_hosts_and_foreign_schemes` includes `"JAVASCRIPT:alert(1)"` → `None`) and the rejection is structural (any ASCII-letter scheme that is not lowercase `http`/`https`/`mailto:`/`tel:` is refused), so a case-folding regression cannot slip past the unit test. Not tested end-to-end in `wild.rs`; the AC's "no `javascript:` anywhere" is asserted only for the lowercase fixture. Not a REJECT: the unit test pins exactly the calculation that would have to break, and a wild-level assertion would test the same code path. Followup: add `"JavaScript:alert(1)"` to `UNSAFE_ENTRY_URLS` and assert case-insensitively (`to_ascii_lowercase().contains("javascript:")`) so the sweep says it in the AC's own words.

**`mailto:` / `tel:` empty body.** Unit-tested: `keeps_mailto_and_tel_with_a_body` asserts `mailto:` → `None` and `tel: ` → `None`. Not exercised through `render_json` — no fixture has a profile/entry with `url: "mailto:"`. `contacts()` builds `mailto:{email}` / `tel_href(phone)` without going through `safe_href`, so an Author's `basics.email` is never subject to the empty-body rule (it is `nonempty`-guarded instead) — correct, and the contact tests cover it. Followup: one wild fixture `{"network":"Mail","url":"mailto:"}` → no `rz-link`.

**Other test-quality notes.** Arrange-Act-Assert is explicit in `date::tests::keeps_prose_after_a_space_unparseable` and implicit but clear elsewhere. Failure messages carry the rendered HTML. Helpers (`first_li`, `inner_of`) `expect` with a reason and are test-only. No `#[ignore]`, no commented-out tests, no external I/O beyond two repo fixtures resolved from `CARGO_MANIFEST_DIR`. Untested calculation: `hostname` on a `mailto:` input (see Reviewer followup) — the behaviour exists and is unlocked.

Gates: `cargo test` 27 / 9 / 2 / 28 green.

BLESS ZG-3 phase-1 — every AC has a named green test, both sweeps carry positive and negative self-checks over the whole fixture corpus, and each plausible mutant is killed by at least one named test. Followups: uppercase-scheme and empty `mailto:` wild-level fixtures; lock `hostname` on opaque schemes once the Reviewer's followup decides its meaning.

## Phase 1 — Architect

**Strata after the change** (edges only downward):

1. `resume.rs` — storage shape, serde only; `string_or_number` is a deserialisation coercion and belongs here, not in emit.
2. `date.rs`, `slug.rs`, `url.rs` — pure calculations over `&str`; no `Html`, no `Resume`, no allocation beyond the returned value. `url.rs` depends on nothing in the crate.
3. `html.rs` — the writer; escaping lives only here.
4. `emit.rs` view models — `Contact`, `Link`, `Primary`, `EntryBits`, `Section`, `DateToken` plus the calculations that build them (`contacts`, `profile_link`, `primary_link`, `*_bits`, `project_meta`, `location_text`, `education_secondary`, `format_score`, `tel_href`, `profile_type`). These are functions `Resume-record → view model`, testable without an `Html`.
5. `emit.rs` orchestration — `render`, `emit_article`, `emit_*`: actions that walk view models into `Html`.

Strata 4 and 5 share a file; that is fine at 1 000 lines but is the seam ZG-4 will want to cut (`emit/model.rs` vs `emit/write.rs`) when a second backend appears. `has_content` moved from nine per-record predicates to one method on the view model, which is the correct altitude: "will this print anything" is a question about the view, not the storage record.

**`url.rs` as a shared calc.** It is `pub fn` inside a private `mod url` — the crate does not re-export it. The Axum layer (paste → render) and the Wasm build both consume `render_json`, so they get URL hygiene for free and need not call `safe_href` directly; if ZG-5's lint wants to warn "this URL was dropped", the function should then be re-exported from `lib.rs` — one line, no restructure. No `url` crate, no regex: `std` only, which is exactly what Wasm wants (binary size, no `regex` unicode tables). Approved.

**`Section` consts vs a data table.** A `&[Section]` table would invite a generic loop over sections, but the sections are *not* uniform: each has its own record type, its own `*_bits` projection, and interests pick their `kind` at runtime. Twelve named consts consumed by twelve one-line `emit_*` functions is the honest shape; a table would hide the type dispatch behind a trait or an enum for no reader benefit. Acceptable. The only wart is `INTERESTS_ENTRIES`/`INTERESTS_TAGS` duplicating a const to vary one field — a `const fn with_kind` is a two-line fix for later.

**Serde `[]` quirk.** Decision recorded in the doc comment on `render_json_accepts_empty_array_as_empty_basics`: keep it, because a wild file is valid input and an empty `basics` renders like a missing one. Consistent with the product stance ("a file from the wild is valid input") and with Invariant 5. The `from_json` doc comment was corrected to stop claiming schema-level type checking. Agreed; no `deny_unknown_fields`, no custom visitor — right amount of machinery.

**Contract 1.0 additive changes.** `dir="auto"` is a new attribute on an existing element; `<span class="rz-link-value">` is a new element choice inside an existing class whose §5.2 row already listed `<a>` or `<span>` for the sibling `.rz-contact-value`. Neither renames, removes, or adds a class; `data-rz-schema` stays `1.0`; the contract text was widened in place. This matches the CTO ruling in cto-round1 and §9's definition of non-breaking. Themes that styled `.rz-link-value` as `a.rz-link-value` will now miss the span — that is the documented risk of selecting by element, not class, and the three first-party themes pass `just verify`.

**What ZG-4 (Wasm) will fight.**
- Nothing structural. `render_json(&str) -> Result<String, _>` is the only entry point, all calcs are `std`, no filesystem, no time, no randomness. `HashSet` for slugs is deterministic per document.
- `serde_json::Number` (`arbitrary_precision` off) prints floats via `ryu`; identical output native vs Wasm. Good.
- The one thing to watch: `emit.rs` at 1 000 lines with both strata in it. When ZG-4 adds `#[wasm_bindgen]` glue, put it in a new crate or `wasm.rs`, do not touch `emit.rs`.
- `IsoDate::visible` month names are English literals; that is a ZG-4 non-issue but a future i18n issue already noted in ZG-2.

**Two-year question.** Someone in 2028 reading `primary_link` will understand in one screen why a nameless certificate shows a hostname and why an `li` can never be empty. Someone reading the old file needed to cross-reference nine predicates against `emit_entry`. Easier.

Gates: fmt, clippy pedantic, tests green; `just verify` line below.

BLESS ZG-3 phase-1 — strata are cleaner than before (nine mirrored predicates collapsed into one view-model truth; URL hygiene is a dependency-free `std` calc that Axum and Wasm inherit through `render_json`), the `Section` consts are the honest non-uniform shape, the serde `[]` decision is recorded where the test lives, and the 1.0 additive changes match the CTO ruling. Followups for ZG-4: split `emit.rs` into model/write at the first second-backend commit; re-export `url::safe_href` only when ZG-5's lint needs it.

## Gate line (all three voices)

`PROBE_PORT=4385 just verify` → exit 0; frontend probes 90 PASS / 0 FAIL (log: /tmp/zg3-verify.log). `cargo test` 27 / 9 / 2 / 28 (log: /tmp/zg3-cargo.log).
