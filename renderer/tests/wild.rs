//! ZG-2: a wild JSON Resume always renders. Dates that are not `iso8601`
//! become `<span class="rz-date …">` with no `datetime`; timestamps truncate;
//! nothing panics. ZG-3 appends its coercion cases here.

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
/// is an empty `basics`, not an error. Locked here so ZG-3 decides on purpose.
#[test]
fn render_json_accepts_empty_array_as_empty_basics() {
    assert!(render_json(r#"{"basics":[]}"#).is_ok());
}
