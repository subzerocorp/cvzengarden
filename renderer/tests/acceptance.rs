//! RZ-2 acceptance: a stub that returns "" or ignores the Resume must fail.

use std::fmt::Write;
use std::fs;
use std::path::PathBuf;

use resumezen_renderer::{render, render_json, Resume, CONTRACT_VERSION};
use scraper::{Html, Node, Selector};
use serde_json::{json, Value};

fn skeleton_path(name: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../skeleton")
        .join(name)
}

fn jordan_json() -> String {
    fs::read_to_string(skeleton_path("resume.json")).expect("skeleton/resume.json")
}

fn example_html() -> String {
    fs::read_to_string(skeleton_path("example.html")).expect("skeleton/example.html")
}

#[test]
fn fixture_rz_resume_tree_matches_example() {
    let html = render_json(&jordan_json()).expect("parse fixture resume");
    assert_resume_trees_eq(&html, &example_html());
}

#[test]
fn fixture_document_shell() {
    let html = render_json(&jordan_json()).unwrap();
    let doc = Html::parse_document(&html);

    let html_el = doc
        .select(&Selector::parse("html").unwrap())
        .next()
        .expect("html");
    assert_eq!(html_el.value().attr("lang"), Some("en"));

    let title = doc
        .select(&Selector::parse("title").unwrap())
        .next()
        .expect("title")
        .inner_html();
    assert!(
        title.contains("Jordan Hale") && title.contains("Design Engineer"),
        "title should contain name and label, got {title:?}"
    );

    let article = doc
        .select(&Selector::parse("article.rz-resume").unwrap())
        .next()
        .expect(".rz-resume");
    assert_eq!(
        article.value().attr("data-rz-schema"),
        Some(CONTRACT_VERSION)
    );
    assert_eq!(CONTRACT_VERSION, "1.0");
}

#[test]
fn ada_name_only_omits_optional_chrome() {
    let html = render_json(r#"{ "basics": { "name": "Ada" } }"#).unwrap();
    let doc = Html::parse_document(&html);

    let name = doc
        .select(&Selector::parse(".rz-name").unwrap())
        .next()
        .expect(".rz-name")
        .text()
        .collect::<String>();
    assert_eq!(name.trim(), "Ada");

    assert!(
        !html.contains("Jordan Hale"),
        "Ada render must not reuse the Jordan Hale fixture"
    );
    assert!(
        !html.contains("id=\"rz-experience\""),
        "name-only resume must omit empty experience"
    );
    assert!(
        !html.contains("class=\"rz-contacts\""),
        "name-only resume must omit empty contacts"
    );
    assert!(
        !html.contains("class=\"rz-photo\""),
        "name-only resume must omit photo"
    );
}

#[test]
fn ignores_schema_resume_meta_and_work_description() {
    let mut value: Value = serde_json::from_str(&jordan_json()).unwrap();
    value["meta"]["x-schema-resume"] = json!({
        "marker": "SCHEMA_RESUME_SECRET_MARKER"
    });
    value["work"][0]["description"] = json!("WORK_DESCRIPTION_SECRET_MARKER");
    // Also keep the fixture's stored-only tagline so a hardcoded example.html
    // copy would still fail if it leaked company blurbs.
    let resume: Resume = serde_json::from_value(value).unwrap();
    let html = render(&resume);

    assert!(html.contains("Jordan Hale"), "must still render the Resume");
    assert!(
        !html.contains("SCHEMA_RESUME_SECRET_MARKER"),
        "meta.x-schema-resume must not appear in HTML"
    );
    assert!(
        !html.contains("WORK_DESCRIPTION_SECRET_MARKER"),
        "work[].description must not appear in HTML"
    );
    assert!(
        !html.contains("Product design studio"),
        "fixture work[0].description must stay stored-only"
    );
    assert!(
        !html.contains("Civic technology"),
        "fixture work[1].description must stay stored-only"
    );
}

#[test]
fn empty_string_stub_would_fail_ada_and_fixture() {
    // Documents the probes a constant-"" stub cannot satisfy.
    let stub = "";
    assert!(Html::parse_document(stub)
        .select(&Selector::parse(".rz-name").unwrap())
        .next()
        .is_none());
    let real = render_json(r#"{ "basics": { "name": "Ada" } }"#).unwrap();
    assert_ne!(real, stub);
    assert!(real.contains("Ada"));
}

#[test]
fn ignores_input_stub_would_fail_ada() {
    let ada = render_json(r#"{ "basics": { "name": "Ada" } }"#).unwrap();
    let jordan = render_json(&jordan_json()).unwrap();
    assert_ne!(
        ada, jordan,
        "render must depend on the input Resume; a fixture-only stub fails"
    );
}

#[test]
fn omits_empty_work_and_blank_highlights() {
    let html = render_json(
        r#"{
            "basics": { "name": "Ada" },
            "work": [
                { "name": "", "highlights": [""] },
                { "name": "Only Job", "startDate": "2020" }
            ]
        }"#,
    )
    .unwrap();
    assert!(html.contains("id=\"rz-experience\""));
    assert!(html.contains("data-rz-entry=\"only-job-2020\""));
    assert_eq!(html.matches("class=\"rz-entry ").count(), 1);
    assert!(!html.contains("class=\"rz-bullets\""));
}

#[test]
fn country_code_fallback_and_photo() {
    let html = render_json(
        r#"{
            "basics": {
                "name": "Ada",
                "image": "https://example.com/ada.jpg",
                "location": { "countryCode": "NL", "address": "Hidden", "postalCode": "0000" }
            }
        }"#,
    )
    .unwrap();
    assert!(html.contains("class=\"rz-photo\""));
    assert!(html.contains("alt=\"Portrait of Ada\""));
    assert!(html.contains("NL"));
    assert!(!html.contains("Hidden"));
    assert!(!html.contains("0000"));
}

#[test]
fn does_not_ship_preview_css() {
    let html = render_json(&jordan_json()).unwrap();
    assert!(!html.contains("preview.css"));
}

fn assert_resume_trees_eq(actual_html: &str, expected_html: &str) {
    let actual_doc = Html::parse_document(actual_html);
    let expected_doc = Html::parse_document(expected_html);
    let sel = Selector::parse("article.rz-resume").unwrap();
    let actual = actual_doc
        .select(&sel)
        .next()
        .unwrap_or_else(|| panic!("actual document is missing article.rz-resume:\n{actual_html}"));
    let expected = expected_doc
        .select(&sel)
        .next()
        .expect("example.html is missing article.rz-resume");
    if let Err(msg) = nodes_eq(actual, expected, "article.rz-resume") {
        panic!(
            "{msg}\n\n--- actual ---\n{}\n\n--- expected ---\n{}",
            dump(actual, 0),
            dump(expected, 0)
        );
    }
}

fn nodes_eq(
    actual: scraper::ElementRef<'_>,
    expected: scraper::ElementRef<'_>,
    path: &str,
) -> Result<(), String> {
    if actual.value().name() != expected.value().name() {
        return Err(format!(
            "{path}: tag <{}> != <{}>",
            actual.value().name(),
            expected.value().name()
        ));
    }
    let a_attrs = norm_attrs(actual);
    let e_attrs = norm_attrs(expected);
    if a_attrs != e_attrs {
        return Err(format!(
            "{path} <{}>: attrs {a_attrs:?} != {e_attrs:?}",
            actual.value().name()
        ));
    }
    let a_kids = significant(actual);
    let e_kids = significant(expected);
    if a_kids.len() != e_kids.len() {
        return Err(format!(
            "{path} <{}>: {} children vs {}",
            actual.value().name(),
            a_kids.len(),
            e_kids.len()
        ));
    }
    for (i, (ak, ek)) in a_kids.iter().zip(e_kids.iter()).enumerate() {
        match (ak, ek) {
            (Kid::Text(t1), Kid::Text(t2)) if t1 == t2 => {}
            (Kid::Text(t1), Kid::Text(t2)) => {
                return Err(format!("{path} text[{i}]: {t1:?} != {t2:?}"));
            }
            (Kid::Elem(e1), Kid::Elem(e2)) => {
                let child_path = format!("{path}/{}[{i}]", e1.value().name());
                nodes_eq(*e1, *e2, &child_path)?;
            }
            _ => return Err(format!("{path}: mixed node types at child {i}")),
        }
    }
    Ok(())
}

enum Kid<'a> {
    Text(String),
    Elem(scraper::ElementRef<'a>),
}

fn significant(el: scraper::ElementRef<'_>) -> Vec<Kid<'_>> {
    let mut kids = Vec::new();
    for child in el.children() {
        match child.value() {
            Node::Text(t) if t.trim().is_empty() => {}
            Node::Text(t) => kids.push(Kid::Text(t.trim().to_string())),
            Node::Element(_) => {
                if let Some(child_el) = scraper::ElementRef::wrap(child) {
                    kids.push(Kid::Elem(child_el));
                }
            }
            // Comments, doctype, and processing instructions carry no tree meaning.
            _ => {}
        }
    }
    kids
}

fn norm_attrs(el: scraper::ElementRef<'_>) -> Vec<(String, String)> {
    let mut attrs: Vec<(String, String)> = el
        .value()
        .attrs()
        .map(|(k, v)| {
            if k == "class" {
                let mut tokens: Vec<&str> = v.split_whitespace().collect();
                tokens.sort_unstable();
                (k.to_string(), tokens.join(" "))
            } else if k == "itemscope" {
                (k.to_string(), String::new())
            } else {
                (k.to_string(), v.to_string())
            }
        })
        .collect();
    attrs.sort_by(|a, b| a.0.cmp(&b.0));
    attrs
}

fn junior_json() -> String {
    fs::read_to_string(skeleton_path("samples/junior.json")).expect("skeleton/samples/junior.json")
}

fn junior_html() -> String {
    fs::read_to_string(skeleton_path("samples/junior.html")).expect("skeleton/samples/junior.html")
}

fn update_requested() -> bool {
    std::env::var_os("RZ_UPDATE_FIXTURES").is_some_and(|value| !value.is_empty())
}

/// Byte-lock `skeleton/samples/junior.html` to `render_json(junior.json)`.
/// `RZ_UPDATE_FIXTURES=1 cargo test --test acceptance` rewrites the HTML.
#[test]
fn junior_sample_html_is_crate_output() {
    let json = junior_json();
    let rendered = render_json(&json).expect("render junior sample");
    if update_requested() {
        fs::write(skeleton_path("samples/junior.html"), &rendered)
            .expect("write skeleton/samples/junior.html");
    }
    let committed = junior_html();
    assert_eq!(
        rendered, committed,
        "skeleton/samples/junior.html is not the crate output for skeleton/samples/junior.json (run RZ_UPDATE_FIXTURES=1 cargo test --test acceptance)"
    );

    assert_eq!(
        rendered.matches("rz-entry--experience").count(),
        1,
        "junior sample must have exactly one experience entry"
    );
    assert_eq!(
        rendered.matches("rz-entry--project").count(),
        3,
        "junior sample must have exactly three project entries"
    );
    assert!(
        rendered.contains(r#"<p class="rz-score">GPA 3.7</p>"#),
        "junior sample must render the string score as GPA 3.7"
    );
    assert!(
        !rendered.contains("rz-photo"),
        "junior sample must omit a photo"
    );
}

fn dump(el: scraper::ElementRef<'_>, depth: usize) -> String {
    let pad = "  ".repeat(depth);
    let mut attrs: Vec<String> = el
        .value()
        .attrs()
        .map(|(k, v)| {
            if v.is_empty() {
                k.to_string()
            } else {
                format!("{k}=\"{v}\"")
            }
        })
        .collect();
    attrs.sort();
    let mut out = format!("{pad}<{} {}>\n", el.value().name(), attrs.join(" "));
    for kid in significant(el) {
        match kid {
            // fmt::Write into a String is infallible.
            Kid::Text(t) => writeln!(out, "{pad}  {t:?}").expect("String fmt::Write"),
            Kid::Elem(child) => out.push_str(&dump(child, depth + 1)),
        }
    }
    out
}
