//! Golden-file locks: a JSON Resume fixture in, its HTML byte-locked to the
//! crate's output, so a committed `.html` can never drift from its `.json`.
//!
//! One table, one helper, one env var. Each PBI adds a `FixtureRow`;
//! `RZ_UPDATE_FIXTURES=1 cargo test --test fixtures` rewrites every row's
//! HTML from the current crate output.

use std::fs;
use std::path::PathBuf;

use resumezen_renderer::render_json;

/// A JSON fixture and the HTML file locked to its render, both repo-relative.
struct FixtureRow {
    json: &'static str,
    html: &'static str,
}

const LONG_RESUME: FixtureRow = FixtureRow {
    json: "frontend/fixtures/long-resume.json",
    html: "frontend/fixtures/long-resume.html",
};

/// Every locked fixture. Later PBIs (ZG-19's samples) append rows here.
const FIXTURES: &[FixtureRow] = &[LONG_RESUME];

const UPDATE_ENV: &str = "RZ_UPDATE_FIXTURES";

fn repo_path(relative: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join(relative)
}

fn update_requested() -> bool {
    std::env::var_os(UPDATE_ENV).is_some_and(|value| !value.is_empty())
}

/// Action: render the row's JSON, optionally rewrite the golden HTML, and
/// assert byte equality. Returns the rendered document for further checks.
fn locked_html(row: &FixtureRow) -> String {
    let json = fs::read_to_string(repo_path(row.json))
        .unwrap_or_else(|err| panic!("read {}: {err}", row.json));
    let rendered = render_json(&json).unwrap_or_else(|err| panic!("render {}: {err}", row.json));
    if update_requested() {
        fs::write(repo_path(row.html), &rendered)
            .unwrap_or_else(|err| panic!("write {}: {err}", row.html));
    }
    let committed = fs::read_to_string(repo_path(row.html)).unwrap_or_else(|err| {
        panic!(
            "read {}: {err} (run {UPDATE_ENV}=1 cargo test --test fixtures)",
            row.html
        )
    });
    assert!(
        rendered == committed,
        "{} is not the crate output for {} (run {UPDATE_ENV}=1 cargo test --test fixtures)",
        row.html,
        row.json
    );
    rendered
}

/// Calculation: the markup of one `<section id="…">` (sections never nest).
fn section_html<'a>(html: &'a str, id: &str) -> &'a str {
    let marker = format!("id=\"{id}\"");
    let start = html
        .find(&marker)
        .unwrap_or_else(|| panic!("missing section #{id}"));
    let end = html[start..]
        .find("</section>")
        .map_or(html.len(), |offset| start + offset);
    &html[start..end]
}

fn count(html: &str, needle: &str) -> usize {
    html.matches(needle).count()
}

#[test]
fn every_fixture_row_is_crate_output() {
    for row in FIXTURES {
        locked_html(row);
    }
}

#[test]
fn long_resume_html_is_crate_output() {
    let html = locked_html(&LONG_RESUME);

    assert_eq!(
        count(&html, "rz-entry--experience"),
        4,
        "experience entries"
    );
    assert_eq!(count(&html, "rz-entry--project"), 3, "project entries");
    assert_eq!(count(&html, "rz-entry--education"), 2, "education entries");

    let experience_bullets = count(section_html(&html, "rz-experience"), "class=\"rz-bullet\"");
    assert!(
        experience_bullets >= 16,
        "#rz-experience has {experience_bullets} bullets, want >= 16"
    );
}
