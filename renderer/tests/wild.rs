//! ZG-2: a wild JSON Resume always renders. Dates that are not `iso8601`
//! become `<span class="rz-date …">` with no `datetime`; timestamps truncate;
//! nothing panics.
//!
//! ZG-3 (appended below): numeric `score`, url-only entries, profiles without
//! a URL, CRLF prose, unsafe URLs never as `href`, emoji-only slugs,
//! `dir="auto"`, and two "matches nothing" sweeps over every fixture.

use std::fs;
use std::path::PathBuf;

use resumezen_renderer::render_json;

/// Calculation: a one-entry `work` résumé with the given date fields.
fn work_json(start: &str, end: Option<&str>) -> String {
    let end = end.map_or(String::new(), |end| format!(r#","endDate":"{end}""#));
    format!(r#"{{"basics":{{"name":"A"}},"work":[{{"name":"X","startDate":"{start}"{end}}}]}}"#)
}

fn render_work(start: &str, end: Option<&str>) -> String {
    render_json(&work_json(start, end)).expect("valid JSON")
}

/// Calculation: the markup of the single `<li class="rz-entry …">`.
fn entry_html(html: &str) -> &str {
    let start = html.find("<li class=\"rz-entry ").expect("one entry");
    let end = html[start..].find("</li>").expect("entry closes") + start;
    &html[start..end]
}

#[test]
fn multibyte_start_date_does_not_panic() {
    for start in ["２０２０", "日本語", "€€", "20€0", "2020"] {
        let result = render_json(&work_json(start, None));
        assert!(result.is_ok(), "startDate {start:?} must render");
    }
}

#[test]
fn timestamp_release_date_truncates() {
    let html = render_json(
        r#"{"basics":{"name":"A"},"publications":[{"name":"Talk","releaseDate":"2023-05-31T09:00:00Z"}]}"#,
    )
    .unwrap();
    assert!(
        html.contains(r#"<time class="rz-date" datetime="2023-05-31">May 31, 2023</time>"#),
        "{html}"
    );
    assert!(!html.contains("09:00"), "time component must not leak");
}

#[test]
fn unparseable_start_date_is_span_without_datetime() {
    let html = render_work("March 2020", None);
    let entry = entry_html(&html);
    assert!(
        entry.contains(r#"<span class="rz-date rz-date--start">March 2020</span>"#),
        "{entry}"
    );
    assert!(!html.contains(r#"datetime="March 2020""#));
    assert!(!html.contains("rz-is-current"));
}

#[test]
fn unparseable_start_does_not_mark_current() {
    let html = render_work("2020-13", None);
    let entry = entry_html(&html);
    assert!(!entry.contains("<time"), "{entry}");
    assert!(!entry.contains("rz-is-current"), "{entry}");
    assert!(!entry.contains("data-rz-current"), "{entry}");
    assert!(
        entry.contains(r#"<h3 class="rz-entry-primary">"#),
        "{entry}"
    );
}

#[test]
fn invalid_calendar_day_is_unparseable() {
    let html = render_work("2020-02-30", None);
    let entry = entry_html(&html);
    assert!(!entry.contains("<time"), "{entry}");
    assert!(
        entry.contains(r#"<span class="rz-date rz-date--start">2020-02-30</span>"#),
        "{entry}"
    );
}

#[test]
fn leap_day_is_valid() {
    let html = render_work("2024-02-29", None);
    let entry = entry_html(&html);
    assert!(entry.contains(r#"datetime="2024-02-29""#), "{entry}");
    assert!(entry.contains("February 29, 2024"), "{entry}");
    assert!(entry.contains("rz-is-current"), "{entry}");
}

#[test]
fn present_end_date_is_span() {
    let html = render_work("2020-03", Some("Present"));
    let entry = entry_html(&html);
    assert!(
        entry.contains(
            r#"<time class="rz-date rz-date--start" datetime="2020-03">March 2020</time>"#
        ),
        "{entry}"
    );
    assert!(
        entry.contains(r#"<span class="rz-date rz-date--end">Present</span>"#),
        "{entry}"
    );
    assert!(!entry.contains(r#"datetime="Present""#), "{entry}");
    assert!(!entry.contains("rz-date--present"), "{entry}");
    assert!(!entry.contains("rz-is-current"), "{entry}");
}

#[test]
fn valid_start_without_end_is_current_and_present() {
    let html = render_work("2020-03", None);
    let entry = entry_html(&html);
    assert!(entry.contains("rz-is-current"), "{entry}");
    assert!(entry.contains(r#"data-rz-current="true""#), "{entry}");
    assert!(
        entry.contains(r#"<span class="rz-date rz-date--end rz-date--present">Present</span>"#),
        "{entry}"
    );
}

#[test]
fn unparseable_start_year_is_dropped_from_slug() {
    let html = render_work("March 2020", None);
    assert!(html.contains(r#"data-rz-entry="x""#), "{html}");
    let html = render_work("2020-03", None);
    assert!(html.contains(r#"data-rz-entry="x-2020""#), "{html}");
}

#[test]
fn render_json_rejects_empty_input() {
    assert!(render_json("").is_err());
}

#[test]
fn render_json_rejects_malformed_json() {
    assert!(render_json("{").is_err());
}

#[test]
fn render_json_rejects_wrong_field_type() {
    assert!(render_json(r#"{"basics":{"name":[]}}"#).is_err());
    assert!(render_json(r#"{"work":{}}"#).is_err());
}

/// serde-derived structs accept a JSON array positionally, so an empty array
/// is an empty `basics`, not an error. ZG-3 decision: keep it — a wild file
/// is valid input, and an empty `basics` renders like a missing one.
#[test]
fn render_json_accepts_empty_array_as_empty_basics() {
    assert!(render_json(r#"{"basics":[]}"#).is_ok());
}

// ---------------------------------------------------------------------------
// ZG-3
// ---------------------------------------------------------------------------

const SCORE_FLOAT: &str =
    r#"{"basics":{"name":"M"},"education":[{"institution":"U","score":3.7}]}"#;
const SCORE_STRING: &str =
    r#"{"basics":{"name":"M"},"education":[{"institution":"U","score":"3.7"}]}"#;
const SCORE_INTEGER: &str =
    r#"{"basics":{"name":"M"},"education":[{"institution":"U","score":4}]}"#;
const SCORE_TEXT: &str =
    r#"{"basics":{"name":"M"},"education":[{"institution":"U","score":"First Class"}]}"#;
const URL_ONLY_CERTIFICATE: &str =
    r#"{"basics":{"name":"M"},"certificates":[{"url":"https://verify.example/abc"}]}"#;
const URL_ONLY_PUBLICATION: &str =
    r#"{"basics":{"name":"M"},"publications":[{"url":"https://doi.example/10.1/x"}]}"#;
const KEYBASE_PROFILE: &str =
    r#"{"basics":{"name":"M","profiles":[{"network":"Keybase","username":"marcus"}]}}"#;
const CRLF_SUMMARY: &str =
    "{\"basics\":{\"name\":\"M\",\"summary\":\"Para one.\\r\\n\\r\\nPara two.\"}}";
const EMPTY_HOST_PROFILE: &str =
    r#"{"basics":{"name":"M","profiles":[{"network":"Site","url":"https://"}]}}"#;
const JAVASCRIPT_PROFILE: &str = r#"{"basics":{"name":"M","profiles":[{"network":"Site","username":"marcus","url":"javascript:alert(1)"}]}}"#;
const JAVASCRIPT_BASICS_URL: &str = r#"{"basics":{"name":"M","url":"javascript:alert(1)"}}"#;
const EMOJI_NAMES: &str = r#"{"basics":{"name":"M"},"work":[{"name":"🔥🔥","startDate":"2020"},{"name":"🔥🔥","startDate":"2020"}],"skills":[{"name":"🎨"}]}"#;
const ADA: &str = r#"{ "basics": { "name": "Ada" } }"#;
const UNSAFE_ENTRY_URLS: &str = r#"{"basics":{"name":"M"},"certificates":[{"url":"javascript:alert(1)"},{"url":"https://"}],"publications":[{"url":"//"}],"projects":[{"url":"data:text/html,x"}]}"#;
const END_WITHOUT_START: &str =
    r#"{"basics":{"name":"M"},"work":[{"name":"X","endDate":"2021-06"}]}"#;

/// Every inline fixture in this file, so the "matches nothing" sweeps cover
/// them all. File-backed fixtures are appended by `all_fixture_html`.
const INLINE_FIXTURES: &[(&str, &str)] = &[
    ("score float", SCORE_FLOAT),
    ("score string", SCORE_STRING),
    ("score integer", SCORE_INTEGER),
    ("score text", SCORE_TEXT),
    ("url-only certificate", URL_ONLY_CERTIFICATE),
    ("url-only publication", URL_ONLY_PUBLICATION),
    ("keybase profile", KEYBASE_PROFILE),
    ("crlf summary", CRLF_SUMMARY),
    ("empty-host profile", EMPTY_HOST_PROFILE),
    ("javascript profile", JAVASCRIPT_PROFILE),
    ("javascript basics.url", JAVASCRIPT_BASICS_URL),
    ("emoji names", EMOJI_NAMES),
    ("ada", ADA),
    ("unsafe entry urls", UNSAFE_ENTRY_URLS),
    ("end without start", END_WITHOUT_START),
    ("empty basics array", r#"{"basics":[]}"#),
    (
        "multibyte start",
        r#"{"basics":{"name":"A"},"work":[{"name":"X","startDate":"２０２０"}]}"#,
    ),
];

/// JSON fixtures on disk, repo-relative.
const FILE_FIXTURES: &[&str] = &["skeleton/resume.json", "frontend/fixtures/long-resume.json"];

fn repo_path(relative: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join(relative)
}

fn render(json: &str) -> String {
    render_json(json).expect("fixture renders")
}

/// Action: every fixture this crate's tests render, as `(name, html)`.
fn all_fixture_html() -> Vec<(String, String)> {
    let inline = INLINE_FIXTURES
        .iter()
        .map(|(name, json)| ((*name).to_string(), render(json)));
    let files = FILE_FIXTURES.iter().map(|relative| {
        let json = fs::read_to_string(repo_path(relative)).expect("fixture file");
        ((*relative).to_string(), render(&json))
    });
    inline.chain(files).collect()
}

/// Calculation: the markup of the first `<li class="{class_prefix}…">`.
fn first_li(html: &str, class_prefix: &str) -> String {
    let open = format!("<li class=\"{class_prefix}");
    let start = html.find(&open).expect("li present");
    let end = html[start..].find("</li>").expect("li closes") + start;
    html[start..end].to_string()
}

/// Calculation: the inner markup of the first `<{tag} class="{class}">`.
fn inner_of(html: &str, tag: &str, class: &str) -> String {
    let open = format!("<{tag} class=\"{class}\">");
    let start = html.find(&open).expect("element present") + open.len();
    let close = format!("</{tag}>");
    let end = html[start..].find(&close).expect("element closes") + start;
    html[start..end].to_string()
}

/// Calculation: the byte offset just past the `>` closing the tag that starts
/// at `open`, then past any whitespace.
fn after_open_tag(html: &str, open: usize) -> Option<usize> {
    let close = html[open..].find('>')? + open + 1;
    Some(close + html[close..].len() - html[close..].trim_start().len())
}

/// The regex `<li class="rz-entry[^>]*>\s*</li>` as a scan: an entry item
/// with no child nodes.
fn empty_entry_li(html: &str) -> Option<&str> {
    html.match_indices("<li class=\"rz-entry")
        .filter_map(|(open, _)| after_open_tag(html, open).map(|pos| (open, pos)))
        .find(|(_, pos)| html[*pos..].starts_with("</li>"))
        .map(|(open, pos)| &html[open..pos])
}

/// The regex
/// `<li class="rz-(link|contact)[^>]*>\s*(<span class="rz-(link|contact)-label">[^<]*</span>\s*)?</li>`
/// as a scan: a link/contact item with no value node.
fn valueless_item_li(html: &str) -> Option<&str> {
    ["link", "contact"].iter().find_map(|kind| {
        let open_tag = format!("<li class=\"rz-{kind}");
        let label_open = format!("<span class=\"rz-{kind}-label\">");
        html.match_indices(open_tag.as_str())
            .filter_map(|(open, _)| after_open_tag(html, open).map(|pos| (open, pos)))
            .map(|(open, pos)| (open, skip_label(html, pos, &label_open)))
            .find(|(_, pos)| html[*pos..].starts_with("</li>"))
            .map(|(open, pos)| &html[open..pos])
    })
}

/// `(<span class="…-label">[^<]*</span>\s*)?` — position after an optional
/// label span and trailing whitespace.
fn skip_label(html: &str, pos: usize, label_open: &str) -> usize {
    let Some(rest) = html[pos..].strip_prefix(label_open) else {
        return pos;
    };
    let text_len = rest.find('<').unwrap_or(rest.len());
    match rest[text_len..].strip_prefix("</span>") {
        Some(after) => html.len() - after.trim_start().len(),
        None => pos,
    }
}

#[test]
fn numeric_score_renders_gpa_prefix() {
    let float = render(SCORE_FLOAT);
    assert!(
        float.contains(r#"<p class="rz-score">GPA 3.7</p>"#),
        "{float}"
    );
    assert_eq!(
        float,
        render(SCORE_STRING),
        "3.7 and \"3.7\" render identically"
    );
    let integer = render(SCORE_INTEGER);
    assert!(
        integer.contains(r#"<p class="rz-score">GPA 4</p>"#),
        "{integer}"
    );
    let text = render(SCORE_TEXT);
    assert!(
        text.contains(r#"<p class="rz-score">First Class</p>"#),
        "{text}"
    );
}

#[test]
fn url_only_certificate_and_publication_link_hostname() {
    let certificate = render(URL_ONLY_CERTIFICATE);
    assert!(
        certificate.contains(
            r#"<a class="rz-entry-primary-link" href="https://verify.example/abc">verify.example</a>"#
        ),
        "{certificate}"
    );
    let publication = render(URL_ONLY_PUBLICATION);
    assert!(
        publication.contains(
            r#"<a class="rz-entry-primary-link" href="https://doi.example/10.1/x">doi.example</a>"#
        ),
        "{publication}"
    );
}

#[test]
fn no_entry_li_is_empty_in_any_fixture() {
    for (name, html) in all_fixture_html() {
        assert_eq!(empty_entry_li(&html), None, "{name}: empty rz-entry");
    }
    // The scan itself sees an empty entry when one is fed to it.
    assert!(empty_entry_li("<li class=\"rz-entry rz-entry--extra\">\n  </li>").is_some());
}

#[test]
fn unsafe_entry_urls_without_names_omit_the_entries() {
    let html = render(UNSAFE_ENTRY_URLS);
    assert!(!html.contains("rz-entry"), "{html}");
    assert!(!html.contains("javascript:"), "{html}");
}

#[test]
fn profile_without_url_is_span_value() {
    let html = render(KEYBASE_PROFILE);
    let li = first_li(&html, "rz-link rz-link--other");
    assert!(
        li.contains(r#"<span class="rz-link-label">Keybase</span>"#),
        "{li}"
    );
    assert!(
        li.contains(r#"<span class="rz-link-value">marcus</span>"#),
        "{li}"
    );
    assert!(!li.contains("<a"), "{li}");
}

#[test]
fn crlf_summary_splits_into_two_paragraphs() {
    let html = render(CRLF_SUMMARY);
    let summary = inner_of(&html, "div", "rz-prose rz-summary");
    assert_eq!(summary.matches("<p>").count(), 2, "{summary}");
    assert!(summary.contains("<p>Para one.</p>"), "{summary}");
    assert!(summary.contains("<p>Para two.</p>"), "{summary}");
    assert!(!html.contains('\r'), "{html}");
}

#[test]
fn empty_host_profile_without_username_omits_links_nav() {
    let html = render(EMPTY_HOST_PROFILE);
    assert!(!html.contains(r#"<li class="rz-link"#), "{html}");
    assert!(!html.contains(r#"<nav class="rz-links""#), "{html}");
}

#[test]
fn javascript_profile_url_is_span_value_without_href() {
    let html = render(JAVASCRIPT_PROFILE);
    let li = first_li(&html, "rz-link rz-link--other");
    assert!(
        li.contains(r#"<span class="rz-link-value">marcus</span>"#),
        "{li}"
    );
    assert!(!li.contains("href"), "{li}");
    assert!(!html.contains("javascript:"), "{html}");
}

#[test]
fn javascript_basics_url_omits_contact() {
    let html = render(JAVASCRIPT_BASICS_URL);
    assert!(!html.contains("rz-contact--url"), "{html}");
    assert!(!html.contains("rz-contacts"), "{html}");
    assert!(!html.contains("javascript:"), "{html}");
}

#[test]
fn no_link_or_contact_li_lacks_a_value_in_any_fixture() {
    for (name, html) in all_fixture_html() {
        assert_eq!(valueless_item_li(&html), None, "{name}: valueless item");
    }
    // The scan itself sees both shapes the regex describes.
    assert!(valueless_item_li("<li class=\"rz-link rz-link--x\">\n</li>").is_some());
    assert!(valueless_item_li(
        "<li class=\"rz-contact rz-contact--url\">\n  <span class=\"rz-contact-label\">Website</span>\n</li>"
    )
    .is_some());
    assert_eq!(
        valueless_item_li(
            "<li class=\"rz-link rz-link--x\">\n  <span class=\"rz-link-label\">X</span>\n  <span class=\"rz-link-value\">me</span>\n</li>"
        ),
        None
    );
}

#[test]
fn emoji_only_names_fall_back_to_entry_and_skill_slugs() {
    let html = render(EMOJI_NAMES);
    let first = html
        .find(r#"data-rz-entry="entry-2020""#)
        .expect("first slug");
    let second = html
        .find(r#"data-rz-entry="entry-2020-2""#)
        .expect("second slug");
    assert!(first < second, "{html}");
    assert!(html.contains(r#"data-rz-skill-group="skill""#), "{html}");
}

#[test]
fn article_carries_dir_auto() {
    let html = render(ADA);
    assert!(
        html.contains(r#"<article class="rz-resume" data-rz-schema="1.0" dir="auto""#),
        "{html}"
    );
}

/// BAR-R1 restated here so the wild suite fails on its own if it regresses.
#[test]
fn ada_name_only_still_renders_bare() {
    let html = render(ADA);
    assert!(html.contains("Ada"));
    for forbidden in ["Jordan Hale", "rz-experience", "rz-contacts", "rz-photo"] {
        assert!(!html.contains(forbidden), "{forbidden} leaked: {html}");
    }
}

/// Contract §5.3: `endDate` without `startDate` is a single plain `.rz-date`.
#[test]
fn end_date_without_start_is_a_single_date() {
    let html = render(END_WITHOUT_START);
    let entry = entry_html(&html);
    assert!(
        entry.contains(r#"<time class="rz-date" datetime="2021-06">June 2021</time>"#),
        "{entry}"
    );
    assert!(!entry.contains("rz-date--"), "{entry}");
    assert!(!entry.contains("rz-date-sep"), "{entry}");
    assert!(!entry.contains("rz-is-current"), "{entry}");
    assert!(entry.contains(r#"data-rz-entry="x""#), "{entry}");
}

/// Contract §5.3: only a time-like tail is truncated; prose after a space
/// leaves the whole token unparseable.
#[test]
fn approximate_year_is_unparseable() {
    let html = render_work("2020 (approx)", None);
    let entry = entry_html(&html);
    assert!(
        entry.contains(r#"<span class="rz-date rz-date--start">2020 (approx)</span>"#),
        "{entry}"
    );
    assert!(!entry.contains("<time"), "{entry}");
    assert!(entry.contains(r#"data-rz-entry="x""#), "{entry}");
}
