use std::collections::HashSet;

use crate::date::format_iso_date;
use crate::html::{flag, kv, Html};
use crate::resume::{
    Award, Basics, Certificate, Education, Interest, Language, Location, Profile, Project,
    Publication, Reference, Resume, Skill, Volunteer, Work,
};
use crate::slug::{entry_slug, iso_year, slugify, uniquify};
use crate::CONTRACT_VERSION;

const KNOWN_PROFILE_TYPES: &[&str] = &[
    "website", "github", "gitlab", "linkedin", "mastodon", "bluesky", "dribbble", "behance", "x",
    "other",
];

pub fn render(resume: &Resume) -> String {
    let mut html = Html::new();
    html.doctype();
    html.open("html", &[kv("lang", "en")]);
    html.open("head", &[]);
    html.void("meta", &[kv("charset", "utf-8")]);
    html.void(
        "meta",
        &[
            kv("name", "viewport"),
            kv("content", "width=device-width, initial-scale=1"),
        ],
    );
    html.text_el("title", &[], &document_title(resume));
    html.close("head");
    html.open("body", &[]);
    emit_article(&mut html, resume);
    html.close("body");
    html.close("html");
    html.finish()
}

fn document_title(resume: &Resume) -> String {
    let basics = resume.basics.as_ref();
    let name = basics.and_then(|b| nonempty(b.name.as_deref()));
    let label = basics.and_then(|b| nonempty(b.label.as_deref()));
    match (name, label) {
        (Some(n), Some(l)) => format!("{n} — {l}"),
        (Some(n), None) => n.to_string(),
        (None, Some(l)) => l.to_string(),
        (None, None) => String::new(),
    }
}

fn emit_article(html: &mut Html, resume: &Resume) {
    html.open(
        "article",
        &[
            kv("class", "rz-resume"),
            kv("data-rz-schema", CONTRACT_VERSION),
            flag("itemscope"),
            kv("itemtype", "https://schema.org/Person"),
        ],
    );

    let mut slugs = HashSet::new();
    emit_header(html, resume.basics.as_ref());
    emit_summary(html, resume.basics.as_ref());
    emit_experience(html, resume.work.as_deref().unwrap_or(&[]), &mut slugs);
    emit_volunteer(html, resume.volunteer.as_deref().unwrap_or(&[]), &mut slugs);
    emit_education(html, resume.education.as_deref().unwrap_or(&[]), &mut slugs);
    emit_awards(html, resume.awards.as_deref().unwrap_or(&[]), &mut slugs);
    emit_certificates(
        html,
        resume.certificates.as_deref().unwrap_or(&[]),
        &mut slugs,
    );
    emit_publications(
        html,
        resume.publications.as_deref().unwrap_or(&[]),
        &mut slugs,
    );
    emit_skills(html, resume.skills.as_deref().unwrap_or(&[]));
    emit_languages(html, resume.languages.as_deref().unwrap_or(&[]));
    emit_interests(html, resume.interests.as_deref().unwrap_or(&[]), &mut slugs);
    emit_references(
        html,
        resume.references.as_deref().unwrap_or(&[]),
        &mut slugs,
    );
    emit_projects(html, resume.projects.as_deref().unwrap_or(&[]), &mut slugs);

    html.close("article");
}

fn emit_header(html: &mut Html, basics: Option<&Basics>) {
    let Some(basics) = basics else {
        return;
    };
    let Some(name) = nonempty(basics.name.as_deref()) else {
        return;
    };

    html.open("header", &[kv("class", "rz-header")]);
    html.open("div", &[kv("class", "rz-identity")]);
    html.text_el(
        "h1",
        &[kv("class", "rz-name"), kv("itemprop", "name")],
        name,
    );
    if let Some(label) = nonempty(basics.label.as_deref()) {
        html.text_el(
            "p",
            &[kv("class", "rz-title"), kv("itemprop", "jobTitle")],
            label,
        );
    }
    html.close("div");

    if let Some(image) = nonempty(basics.image.as_deref()) {
        html.open("figure", &[kv("class", "rz-photo")]);
        let alt = format!("Portrait of {name}");
        html.void(
            "img",
            &[
                kv("class", "rz-photo-img"),
                kv("src", image),
                kv("alt", &alt),
            ],
        );
        html.close("figure");
    }

    emit_contacts(html, basics);
    emit_links(html, basics.profiles.as_deref().unwrap_or(&[]));
    html.close("header");
}

fn emit_contacts(html: &mut Html, basics: &Basics) {
    let email = nonempty(basics.email.as_deref());
    let phone = nonempty(basics.phone.as_deref());
    let url = nonempty(basics.url.as_deref());
    let location = location_text(basics.location.as_ref());
    if email.is_none() && phone.is_none() && url.is_none() && location.is_none() {
        return;
    }

    html.open("address", &[kv("class", "rz-contacts")]);
    html.open("ul", &[kv("class", "rz-contact-list")]);

    if let Some(email) = email {
        let href = format!("mailto:{email}");
        contact_row(html, "email", "Email", Some((&href, Some("email"))), email);
    }
    if let Some(phone) = phone {
        let href = tel_href(phone);
        contact_row(html, "phone", "Phone", Some((&href, None)), phone);
    }
    if let Some(url) = url {
        let href = abs_http_url(url);
        let host = hostname(&href);
        contact_row(html, "url", "Website", Some((&href, Some("url"))), &host);
    }
    if let Some(loc) = location {
        contact_row(html, "location", "Location", None, &loc);
    }

    html.close("ul");
    html.close("address");
}

fn contact_row(
    html: &mut Html,
    kind: &str,
    label: &str,
    link: Option<(&str, Option<&str>)>,
    value: &str,
) {
    let class = format!("rz-contact rz-contact--{kind}");
    html.open("li", &[kv("class", &class), kv("data-rz-type", kind)]);
    html.text_el("span", &[kv("class", "rz-contact-label")], label);
    match link {
        Some((href, itemprop)) => {
            let mut attrs = vec![kv("class", "rz-contact-value"), kv("href", href)];
            if let Some(prop) = itemprop {
                attrs.insert(1, kv("itemprop", prop));
            }
            html.text_el("a", &attrs, value);
        }
        None => {
            html.text_el(
                "span",
                &[kv("class", "rz-contact-value"), kv("itemprop", "address")],
                value,
            );
        }
    }
    html.close("li");
}

fn emit_links(html: &mut Html, profiles: &[Profile]) {
    let items: Vec<_> = profiles
        .iter()
        .filter(|p| nonempty(p.url.as_deref()).is_some())
        .collect();
    if items.is_empty() {
        return;
    }

    html.open(
        "nav",
        &[kv("class", "rz-links"), kv("aria-label", "Profiles")],
    );
    html.open("ul", &[kv("class", "rz-link-list")]);
    for profile in items {
        let url = nonempty(profile.url.as_deref()).expect("filtered");
        let href = abs_http_url(url);
        let network = nonempty(profile.network.as_deref()).unwrap_or("");
        let kind = profile_type(network);
        let label = if network.is_empty() { kind } else { network };
        let text =
            nonempty(profile.username.as_deref()).map_or_else(|| hostname(&href), str::to_string);
        let class = format!("rz-link rz-link--{kind}");
        html.open("li", &[kv("class", &class), kv("data-rz-type", kind)]);
        html.text_el("span", &[kv("class", "rz-link-label")], label);
        html.text_el(
            "a",
            &[kv("class", "rz-link-value"), kv("href", &href)],
            &text,
        );
        html.close("li");
    }
    html.close("ul");
    html.close("nav");
}

fn emit_summary(html: &mut Html, basics: Option<&Basics>) {
    let Some(summary) = basics.and_then(|b| nonempty(b.summary.as_deref())) else {
        return;
    };
    open_section(html, "summary", "Summary", false, None);
    emit_prose(html, "rz-prose rz-summary", summary);
    html.close("section");
}

fn emit_experience(html: &mut Html, items: &[Work], slugs: &mut HashSet<String>) {
    let items: Vec<&Work> = items.iter().filter(|w| work_has_content(w)).collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "experience", "Experience", false, None);
    html.open("ol", &[kv("class", "rz-entries")]);
    for work in items {
        let bits = EntryBits {
            kind: "experience",
            primary: nonempty(work.name.as_deref()),
            url: nonempty(work.url.as_deref()),
            secondary: nonempty(work.position.as_deref()).map(str::to_string),
            start: nonempty(work.start_date.as_deref()),
            end: nonempty(work.end_date.as_deref()),
            single_date: None,
            location: nonempty(work.location.as_deref()),
            score: None,
            summary: nonempty(work.summary.as_deref()),
            highlights: nonempty_list(work.highlights.as_deref()),
            tags: &[],
            meta: vec![],
        };
        emit_entry(html, &bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

fn emit_volunteer(html: &mut Html, items: &[Volunteer], slugs: &mut HashSet<String>) {
    let items: Vec<&Volunteer> = items.iter().filter(|v| volunteer_has_content(v)).collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "volunteer", "Volunteer", true, Some("entries"));
    html.open("ol", &[kv("class", "rz-entries")]);
    for item in items {
        let bits = EntryBits {
            kind: "extra",
            primary: nonempty(item.organization.as_deref()),
            url: nonempty(item.url.as_deref()),
            secondary: nonempty(item.position.as_deref()).map(str::to_string),
            start: nonempty(item.start_date.as_deref()),
            end: nonempty(item.end_date.as_deref()),
            single_date: None,
            location: None,
            score: None,
            summary: nonempty(item.summary.as_deref()),
            highlights: nonempty_list(item.highlights.as_deref()),
            tags: &[],
            meta: vec![],
        };
        emit_entry(html, &bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

fn emit_education(html: &mut Html, items: &[Education], slugs: &mut HashSet<String>) {
    let items: Vec<&Education> = items.iter().filter(|e| education_has_content(e)).collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "education", "Education", false, None);
    html.open("ol", &[kv("class", "rz-entries")]);
    for item in items {
        let bits = EntryBits {
            kind: "education",
            primary: nonempty(item.institution.as_deref()),
            url: nonempty(item.url.as_deref()),
            secondary: education_secondary(item),
            start: nonempty(item.start_date.as_deref()),
            end: nonempty(item.end_date.as_deref()),
            single_date: None,
            location: None,
            score: nonempty(item.score.as_deref()).map(format_score),
            summary: None,
            highlights: &[],
            tags: nonempty_list(item.courses.as_deref()),
            meta: vec![],
        };
        emit_entry(html, &bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

fn emit_awards(html: &mut Html, items: &[Award], slugs: &mut HashSet<String>) {
    let items: Vec<&Award> = items.iter().filter(|a| award_has_content(a)).collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "awards", "Awards", true, Some("entries"));
    html.open("ol", &[kv("class", "rz-entries")]);
    for item in items {
        let bits = EntryBits {
            kind: "extra",
            primary: nonempty(item.title.as_deref()),
            url: None,
            secondary: nonempty(item.awarder.as_deref()).map(str::to_string),
            start: None,
            end: None,
            single_date: nonempty(item.date.as_deref()),
            location: None,
            score: None,
            summary: nonempty(item.summary.as_deref()),
            highlights: &[],
            tags: &[],
            meta: vec![],
        };
        emit_entry(html, &bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

fn emit_certificates(html: &mut Html, items: &[Certificate], slugs: &mut HashSet<String>) {
    let items: Vec<&Certificate> = items
        .iter()
        .filter(|c| certificate_has_content(c))
        .collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "certificates", "Certificates", true, Some("entries"));
    html.open("ol", &[kv("class", "rz-entries")]);
    for item in items {
        let bits = EntryBits {
            kind: "extra",
            primary: nonempty(item.name.as_deref()),
            url: nonempty(item.url.as_deref()),
            secondary: nonempty(item.issuer.as_deref()).map(str::to_string),
            start: None,
            end: None,
            single_date: nonempty(item.date.as_deref()),
            location: None,
            score: None,
            summary: None,
            highlights: &[],
            tags: &[],
            meta: vec![],
        };
        emit_entry(html, &bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

fn emit_publications(html: &mut Html, items: &[Publication], slugs: &mut HashSet<String>) {
    let items: Vec<&Publication> = items
        .iter()
        .filter(|p| publication_has_content(p))
        .collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "publications", "Publications", true, Some("entries"));
    html.open("ol", &[kv("class", "rz-entries")]);
    for item in items {
        let bits = EntryBits {
            kind: "extra",
            primary: nonempty(item.name.as_deref()),
            url: nonempty(item.url.as_deref()),
            secondary: nonempty(item.publisher.as_deref()).map(str::to_string),
            start: None,
            end: None,
            single_date: nonempty(item.release_date.as_deref()),
            location: None,
            score: None,
            summary: nonempty(item.summary.as_deref()),
            highlights: &[],
            tags: &[],
            meta: vec![],
        };
        emit_entry(html, &bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

fn emit_skills(html: &mut Html, items: &[Skill]) {
    let items: Vec<&Skill> = items.iter().filter(|s| skill_has_content(s)).collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "skills", "Skills", false, None);
    html.open("ul", &[kv("class", "rz-skill-groups")]);
    let mut group_slugs = HashSet::new();
    for skill in items {
        let name = nonempty(skill.name.as_deref());
        let slug_src = name.unwrap_or("skill");
        let slug = uniquify(slugify(slug_src), &mut group_slugs);
        html.open(
            "li",
            &[
                kv("class", "rz-skill-group"),
                kv("data-rz-skill-group", &slug),
            ],
        );
        if let Some(name) = name {
            html.text_el("h3", &[kv("class", "rz-skill-group-name")], name);
        }
        if let Some(level) = nonempty(skill.level.as_deref()) {
            html.text_el("p", &[kv("class", "rz-skill-level")], level);
        }
        let keywords: Vec<&str> = nonempty_list(skill.keywords.as_deref())
            .iter()
            .map(|s| s.trim())
            .filter(|s| !s.is_empty())
            .collect();
        if !keywords.is_empty() {
            html.open("ul", &[kv("class", "rz-skill-list")]);
            for keyword in keywords {
                html.text_el("li", &[kv("class", "rz-skill")], keyword);
            }
            html.close("ul");
        }
        html.close("li");
    }
    html.close("ul");
    html.close("section");
}

fn emit_languages(html: &mut Html, items: &[Language]) {
    let items: Vec<&Language> = items
        .iter()
        .filter(|l| nonempty(l.language.as_deref()).is_some())
        .collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "languages", "Languages", true, Some("list"));
    html.open("ul", &[kv("class", "rz-meta-list")]);
    for item in items {
        html.open("li", &[kv("class", "rz-meta")]);
        html.text_el(
            "span",
            &[kv("class", "rz-meta-label")],
            nonempty(item.language.as_deref()).unwrap(),
        );
        if let Some(fluency) = nonempty(item.fluency.as_deref()) {
            html.text_el("span", &[kv("class", "rz-meta-detail")], fluency);
        }
        html.close("li");
    }
    html.close("ul");
    html.close("section");
}

fn emit_interests(html: &mut Html, items: &[Interest], slugs: &mut HashSet<String>) {
    let items: Vec<&Interest> = items
        .iter()
        .filter(|i| nonempty(i.name.as_deref()).is_some())
        .collect();
    if items.is_empty() {
        return;
    }
    let as_entries = items
        .iter()
        .any(|i| !nonempty_list(i.keywords.as_deref()).is_empty());
    if as_entries {
        open_section(html, "interests", "Interests", true, Some("entries"));
        html.open("ol", &[kv("class", "rz-entries")]);
        for item in items {
            let tags = nonempty_list(item.keywords.as_deref());
            let bits = EntryBits {
                kind: "extra",
                primary: nonempty(item.name.as_deref()),
                url: None,
                secondary: None,
                start: None,
                end: None,
                single_date: None,
                location: None,
                score: None,
                summary: None,
                highlights: &[],
                tags,
                meta: vec![],
            };
            emit_entry(html, &bits, slugs);
        }
        html.close("ol");
        html.close("section");
    } else {
        open_section(html, "interests", "Interests", true, Some("tags"));
        html.open("ul", &[kv("class", "rz-tags")]);
        for item in items {
            html.text_el(
                "li",
                &[kv("class", "rz-tag")],
                nonempty(item.name.as_deref()).unwrap(),
            );
        }
        html.close("ul");
        html.close("section");
    }
}

fn emit_references(html: &mut Html, items: &[Reference], slugs: &mut HashSet<String>) {
    let items: Vec<&Reference> = items.iter().filter(|r| reference_has_content(r)).collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "references", "References", true, Some("entries"));
    html.open("ol", &[kv("class", "rz-entries")]);
    for item in items {
        let bits = EntryBits {
            kind: "extra",
            primary: nonempty(item.name.as_deref()),
            url: None,
            secondary: None,
            start: None,
            end: None,
            single_date: None,
            location: None,
            score: None,
            summary: nonempty(item.reference.as_deref()),
            highlights: &[],
            tags: &[],
            meta: vec![],
        };
        emit_entry(html, &bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

fn emit_projects(html: &mut Html, items: &[Project], slugs: &mut HashSet<String>) {
    let items: Vec<&Project> = items.iter().filter(|p| project_has_content(p)).collect();
    if items.is_empty() {
        return;
    }
    open_section(html, "projects", "Projects", false, None);
    html.open("ol", &[kv("class", "rz-entries")]);
    for item in items {
        let mut meta = Vec::new();
        let roles = nonempty_list(item.roles.as_deref());
        if !roles.is_empty() {
            meta.push(("Roles".to_string(), roles.join(", ")));
        }
        if let Some(entity) = nonempty(item.entity.as_deref()) {
            meta.push(("Affiliation".to_string(), entity.to_string()));
        }
        if let Some(kind) = nonempty(item.r#type.as_deref()) {
            meta.push(("Type".to_string(), kind.to_string()));
        }
        let bits = EntryBits {
            kind: "project",
            primary: nonempty(item.name.as_deref()),
            url: nonempty(item.url.as_deref()),
            secondary: nonempty(item.description.as_deref()).map(str::to_string),
            start: nonempty(item.start_date.as_deref()),
            end: nonempty(item.end_date.as_deref()),
            single_date: None,
            location: None,
            score: None,
            summary: None,
            highlights: nonempty_list(item.highlights.as_deref()),
            tags: nonempty_list(item.keywords.as_deref()),
            meta,
        };
        emit_entry(html, &bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

struct EntryBits<'a> {
    kind: &'a str,
    primary: Option<&'a str>,
    url: Option<&'a str>,
    secondary: Option<String>,
    start: Option<&'a str>,
    end: Option<&'a str>,
    single_date: Option<&'a str>,
    location: Option<&'a str>,
    score: Option<String>,
    summary: Option<&'a str>,
    highlights: &'a [String],
    tags: &'a [String],
    meta: Vec<(String, String)>,
}

fn emit_entry(html: &mut Html, bits: &EntryBits<'_>, slugs: &mut HashSet<String>) {
    let year = bits.single_date.or(bits.start).and_then(iso_year);
    let slug = entry_slug(bits.primary.unwrap_or(""), year, slugs);
    let is_current = bits.single_date.is_none() && bits.start.is_some() && bits.end.is_none();
    let mut class = format!("rz-entry rz-entry--{}", bits.kind);
    if is_current {
        class.push_str(" rz-is-current");
    }
    let mut attrs = vec![kv("class", &class), kv("data-rz-entry", &slug)];
    if is_current {
        attrs.push(kv("data-rz-current", "true"));
    }
    html.open("li", &attrs);

    let has_header = bits.primary.is_some()
        || bits.secondary.is_some()
        || bits.start.is_some()
        || bits.end.is_some()
        || bits.single_date.is_some()
        || bits.location.is_some()
        || bits.score.is_some();
    if has_header {
        html.open("div", &[kv("class", "rz-entry-header")]);
        if let Some(primary) = bits.primary {
            if let Some(url) = bits.url {
                let href = abs_http_url(url);
                html.open("h3", &[kv("class", "rz-entry-primary")]);
                html.text_el(
                    "a",
                    &[kv("class", "rz-entry-primary-link"), kv("href", &href)],
                    primary,
                );
                html.close("h3");
            } else {
                html.text_el("h3", &[kv("class", "rz-entry-primary")], primary);
            }
        }
        if let Some(secondary) = bits.secondary.as_deref() {
            html.text_el("p", &[kv("class", "rz-entry-secondary")], secondary);
        }
        emit_dates(html, bits.start, bits.end, bits.single_date);
        if let Some(location) = bits.location {
            html.text_el("p", &[kv("class", "rz-location")], location);
        }
        if let Some(score) = bits.score.as_deref() {
            html.text_el("p", &[kv("class", "rz-score")], score);
        }
        html.close("div");
    }

    if let Some(summary) = bits.summary {
        emit_prose(html, "rz-prose", summary);
    }
    if !bits.meta.is_empty() {
        html.open("ul", &[kv("class", "rz-meta-list")]);
        for (label, detail) in &bits.meta {
            html.open("li", &[kv("class", "rz-meta")]);
            html.text_el("span", &[kv("class", "rz-meta-label")], label);
            html.text_el("span", &[kv("class", "rz-meta-detail")], detail);
            html.close("li");
        }
        html.close("ul");
    }
    emit_tags(html, bits.tags);
    emit_bullets(html, bits.highlights);
    html.close("li");
}

fn emit_dates(html: &mut Html, start: Option<&str>, end: Option<&str>, single: Option<&str>) {
    if let Some(single) = single {
        let Some((dt, visible)) = format_iso_date(single) else {
            return;
        };
        html.open("p", &[kv("class", "rz-dates")]);
        html.text_el(
            "time",
            &[kv("class", "rz-date"), kv("datetime", &dt)],
            &visible,
        );
        html.close("p");
        return;
    }

    let start = start.and_then(format_iso_date);
    let end = end.and_then(format_iso_date);
    if start.is_none() && end.is_none() {
        return;
    }

    html.open("p", &[kv("class", "rz-dates")]);
    match (start, end) {
        (Some((dt, visible)), None) => {
            html.text_el(
                "time",
                &[kv("class", "rz-date rz-date--start"), kv("datetime", &dt)],
                &visible,
            );
            html.text_el(
                "span",
                &[kv("class", "rz-date-sep"), kv("aria-hidden", "true")],
                "–",
            );
            html.text_el(
                "span",
                &[kv("class", "rz-date rz-date--end rz-date--present")],
                "Present",
            );
        }
        (None, Some((dt, visible))) => {
            html.text_el(
                "time",
                &[kv("class", "rz-date"), kv("datetime", &dt)],
                &visible,
            );
        }
        (Some((s_dt, s_vis)), Some((e_dt, e_vis))) => {
            html.text_el(
                "time",
                &[kv("class", "rz-date rz-date--start"), kv("datetime", &s_dt)],
                &s_vis,
            );
            html.text_el(
                "span",
                &[kv("class", "rz-date-sep"), kv("aria-hidden", "true")],
                "–",
            );
            html.text_el(
                "time",
                &[kv("class", "rz-date rz-date--end"), kv("datetime", &e_dt)],
                &e_vis,
            );
        }
        (None, None) => {}
    }
    html.close("p");
}

fn emit_prose(html: &mut Html, class: &str, text: &str) {
    html.open("div", &[kv("class", class)]);
    for para in text.split("\n\n") {
        let para = para.trim();
        if !para.is_empty() {
            html.text_el("p", &[], para);
        }
    }
    html.close("div");
}

fn emit_bullets(html: &mut Html, items: &[String]) {
    let items: Vec<&str> = items
        .iter()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect();
    if items.is_empty() {
        return;
    }
    html.open("ul", &[kv("class", "rz-bullets")]);
    for item in items {
        html.text_el("li", &[kv("class", "rz-bullet")], item);
    }
    html.close("ul");
}

fn emit_tags(html: &mut Html, items: &[String]) {
    let items: Vec<&str> = items
        .iter()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect();
    if items.is_empty() {
        return;
    }
    html.open("ul", &[kv("class", "rz-tags")]);
    for item in items {
        html.text_el("li", &[kv("class", "rz-tag")], item);
    }
    html.close("ul");
}

fn open_section(html: &mut Html, id: &str, title: &str, extra: bool, kind: Option<&str>) {
    let class = if extra {
        format!("rz-section rz-section--extra rz-section--{id}")
    } else {
        format!("rz-section rz-section--{id}")
    };
    let frag = format!("rz-{id}");
    let mut attrs = vec![
        kv("class", &class),
        kv("id", &frag),
        kv("data-rz-section", id),
    ];
    if let Some(kind) = kind {
        attrs.push(kv("data-rz-kind", kind));
    }
    html.open("section", &attrs);
    html.text_el("h2", &[kv("class", "rz-section-title")], title);
}

fn location_text(location: Option<&Location>) -> Option<String> {
    let location = location?;
    let city = nonempty(location.city.as_deref());
    let region = nonempty(location.region.as_deref());
    match (city, region) {
        (Some(c), Some(r)) => Some(format!("{c}, {r}")),
        (Some(c), None) => Some(c.to_string()),
        (None, Some(r)) => Some(r.to_string()),
        (None, None) => nonempty(location.country_code.as_deref()).map(str::to_string),
    }
}

fn education_secondary(item: &Education) -> Option<String> {
    match (
        nonempty(item.study_type.as_deref()),
        nonempty(item.area.as_deref()),
    ) {
        (Some(s), Some(a)) => Some(format!("{s} in {a}")),
        (Some(s), None) => Some(s.to_string()),
        (None, Some(a)) => Some(a.to_string()),
        (None, None) => None,
    }
}

fn format_score(score: &str) -> String {
    if score.parse::<f64>().is_ok() {
        format!("GPA {score}")
    } else {
        score.to_string()
    }
}

fn tel_href(phone: &str) -> String {
    let kept: String = phone
        .chars()
        .filter(|c| c.is_ascii_digit() || *c == '+')
        .collect();
    format!("tel:{kept}")
}

fn abs_http_url(url: &str) -> String {
    let url = url.trim();
    if url.starts_with("https://")
        || url.starts_with("http://")
        || url.starts_with("mailto:")
        || url.starts_with("tel:")
    {
        url.to_string()
    } else if let Some(rest) = url.strip_prefix("//") {
        format!("https://{rest}")
    } else {
        format!("https://{url}")
    }
}

fn hostname(url: &str) -> String {
    let rest = url
        .trim()
        .strip_prefix("https://")
        .or_else(|| url.trim().strip_prefix("http://"))
        .unwrap_or(url.trim());
    rest.split(['/', '?', '#'])
        .next()
        .unwrap_or(rest)
        .to_string()
}

fn profile_type(network: &str) -> &'static str {
    let n = network.trim().to_ascii_lowercase();
    let mapped = match n.as_str() {
        "twitter" | "x" => "x",
        other => other,
    };
    KNOWN_PROFILE_TYPES
        .iter()
        .copied()
        .find(|k| *k == mapped)
        .unwrap_or("other")
}

fn nonempty(value: Option<&str>) -> Option<&str> {
    value.map(str::trim).filter(|s| !s.is_empty())
}

fn nonempty_list(items: Option<&[String]>) -> &[String] {
    items.unwrap_or(&[])
}

fn work_has_content(w: &Work) -> bool {
    nonempty(w.name.as_deref()).is_some()
        || nonempty(w.position.as_deref()).is_some()
        || nonempty(w.start_date.as_deref()).is_some()
        || nonempty(w.end_date.as_deref()).is_some()
        || nonempty(w.location.as_deref()).is_some()
        || nonempty(w.summary.as_deref()).is_some()
        || has_any(w.highlights.as_deref())
}

fn volunteer_has_content(v: &Volunteer) -> bool {
    nonempty(v.organization.as_deref()).is_some()
        || nonempty(v.position.as_deref()).is_some()
        || nonempty(v.start_date.as_deref()).is_some()
        || nonempty(v.end_date.as_deref()).is_some()
        || nonempty(v.summary.as_deref()).is_some()
        || has_any(v.highlights.as_deref())
}

fn education_has_content(e: &Education) -> bool {
    nonempty(e.institution.as_deref()).is_some()
        || nonempty(e.area.as_deref()).is_some()
        || nonempty(e.study_type.as_deref()).is_some()
        || nonempty(e.start_date.as_deref()).is_some()
        || nonempty(e.end_date.as_deref()).is_some()
        || nonempty(e.score.as_deref()).is_some()
        || has_any(e.courses.as_deref())
}

fn award_has_content(a: &Award) -> bool {
    nonempty(a.title.as_deref()).is_some()
        || nonempty(a.awarder.as_deref()).is_some()
        || nonempty(a.date.as_deref()).is_some()
        || nonempty(a.summary.as_deref()).is_some()
}

fn certificate_has_content(c: &Certificate) -> bool {
    nonempty(c.name.as_deref()).is_some()
        || nonempty(c.issuer.as_deref()).is_some()
        || nonempty(c.date.as_deref()).is_some()
        || nonempty(c.url.as_deref()).is_some()
}

fn publication_has_content(p: &Publication) -> bool {
    nonempty(p.name.as_deref()).is_some()
        || nonempty(p.publisher.as_deref()).is_some()
        || nonempty(p.release_date.as_deref()).is_some()
        || nonempty(p.summary.as_deref()).is_some()
        || nonempty(p.url.as_deref()).is_some()
}

fn skill_has_content(s: &Skill) -> bool {
    nonempty(s.name.as_deref()).is_some()
        || nonempty(s.level.as_deref()).is_some()
        || has_any(s.keywords.as_deref())
}

fn reference_has_content(r: &Reference) -> bool {
    nonempty(r.name.as_deref()).is_some() || nonempty(r.reference.as_deref()).is_some()
}

fn project_has_content(p: &Project) -> bool {
    nonempty(p.name.as_deref()).is_some()
        || nonempty(p.description.as_deref()).is_some()
        || nonempty(p.start_date.as_deref()).is_some()
        || nonempty(p.end_date.as_deref()).is_some()
        || nonempty(p.url.as_deref()).is_some()
        || nonempty(p.entity.as_deref()).is_some()
        || nonempty(p.r#type.as_deref()).is_some()
        || has_any(p.highlights.as_deref())
        || has_any(p.keywords.as_deref())
        || has_any(p.roles.as_deref())
}

fn has_any(items: Option<&[String]>) -> bool {
    items.is_some_and(|items| items.iter().any(|s| !s.trim().is_empty()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tel_strips_punctuation_except_plus() {
        assert_eq!(tel_href("+1 503 555 0142"), "tel:+15035550142");
        assert_eq!(tel_href("(503) 555-0142"), "tel:5035550142");
    }

    #[test]
    fn hostname_from_basics_url() {
        assert_eq!(hostname("https://jordanhale.example"), "jordanhale.example");
        assert_eq!(
            hostname("https://www.linkedin.com/in/jordanhale"),
            "www.linkedin.com"
        );
    }

    #[test]
    fn twitter_maps_to_x() {
        assert_eq!(profile_type("Twitter"), "x");
        assert_eq!(profile_type("X"), "x");
        assert_eq!(profile_type("GitHub"), "github");
        assert_eq!(profile_type("UnknownNet"), "other");
    }

    #[test]
    fn location_falls_back_to_country() {
        let loc = Location {
            country_code: Some("US".into()),
            ..Location::default()
        };
        assert_eq!(location_text(Some(&loc)).as_deref(), Some("US"));
        let loc = Location {
            city: Some("Portland".into()),
            region: Some("OR".into()),
            country_code: Some("US".into()),
            address: Some("secret street".into()),
            postal_code: Some("97201".into()),
        };
        assert_eq!(location_text(Some(&loc)).as_deref(), Some("Portland, OR"));
    }

    #[test]
    fn gpa_prefix_only_when_numeric() {
        assert_eq!(format_score("3.8"), "GPA 3.8");
        assert_eq!(format_score("First Class"), "First Class");
    }
}
