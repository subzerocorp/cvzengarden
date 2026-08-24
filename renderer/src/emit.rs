use std::borrow::Cow;
use std::collections::HashSet;

use crate::date::{parse_iso_date, IsoDate};
use crate::html::{flag, kv, Attr, Html};
use crate::resume::{
    Award, Basics, Certificate, Education, Interest, Language, Location, Profile, Project,
    Publication, Reference, Resume, Skill, Volunteer, Work,
};
use crate::slug::{entry_slug, skill_slug};
use crate::url::{hostname, safe_href};
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
            kv("dir", "auto"),
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

/// One `.rz-contact` row. `href == None` renders the value as a `<span>`.
struct Contact<'a> {
    kind: &'static str,
    label: &'static str,
    itemprop: Option<&'static str>,
    href: Option<String>,
    text: Cow<'a, str>,
}

/// Calculation: the contact rows `basics` yields, in contract order. A
/// `basics.url` without a safe href has no hostname to show and is dropped.
fn contacts(basics: &Basics) -> Vec<Contact<'_>> {
    let email = nonempty(basics.email.as_deref()).map(|email| Contact {
        kind: "email",
        label: "Email",
        itemprop: Some("email"),
        href: Some(format!("mailto:{email}")),
        text: Cow::Borrowed(email),
    });
    let phone = nonempty(basics.phone.as_deref()).map(|phone| Contact {
        kind: "phone",
        label: "Phone",
        itemprop: None,
        href: Some(tel_href(phone)),
        text: Cow::Borrowed(phone),
    });
    let url = nonempty(basics.url.as_deref())
        .and_then(safe_href)
        .map(|href| Contact {
            kind: "url",
            label: "Website",
            itemprop: Some("url"),
            text: Cow::Owned(hostname(&href).to_string()),
            href: Some(href),
        });
    let location = location_text(basics.location.as_ref()).map(|text| Contact {
        kind: "location",
        label: "Location",
        itemprop: Some("address"),
        href: None,
        text: Cow::Owned(text),
    });
    [email, phone, url, location]
        .into_iter()
        .flatten()
        .collect()
}

fn emit_contacts(html: &mut Html, basics: &Basics) {
    let rows = contacts(basics);
    if rows.is_empty() {
        return;
    }
    html.open("address", &[kv("class", "rz-contacts")]);
    html.open("ul", &[kv("class", "rz-contact-list")]);
    for row in &rows {
        emit_contact(html, row);
    }
    html.close("ul");
    html.close("address");
}

fn emit_contact(html: &mut Html, row: &Contact<'_>) {
    let class = format!("rz-contact rz-contact--{}", row.kind);
    html.open("li", &[kv("class", &class), kv("data-rz-type", row.kind)]);
    html.text_el("span", &[kv("class", "rz-contact-label")], row.label);
    let mut attrs = vec![kv("class", "rz-contact-value")];
    attrs.extend(row.itemprop.map(|prop| kv("itemprop", prop)));
    emit_value(html, attrs, row.href.as_deref(), &row.text);
    html.close("li");
}

/// `<a href>` when there is a safe href, otherwise a `<span>` with the same
/// attributes (contract §5.2).
fn emit_value<'a>(html: &mut Html, mut attrs: Vec<Attr<'a>>, href: Option<&'a str>, text: &str) {
    match href {
        Some(href) => {
            attrs.push(kv("href", href));
            html.text_el("a", &attrs, text);
        }
        None => html.text_el("span", &attrs, text),
    }
}

/// One `.rz-link` row. `href == None` renders the username as a `<span>`.
struct Link<'a> {
    kind: &'static str,
    label: &'a str,
    href: Option<String>,
    text: Cow<'a, str>,
}

/// Calculation: the row a profile yields, or `None` when nothing is showable
/// (no username and no safe URL to take a hostname from).
fn profile_link(profile: &Profile) -> Option<Link<'_>> {
    let href = nonempty(profile.url.as_deref()).and_then(safe_href);
    let text = nonempty(profile.username.as_deref())
        .map(Cow::Borrowed)
        .or_else(|| {
            href.as_deref()
                .map(|href| Cow::Owned(hostname(href).to_string()))
        })
        .filter(|text| !text.is_empty())?;
    let network = nonempty(profile.network.as_deref()).unwrap_or("");
    let kind = profile_type(network);
    let label = if network.is_empty() { kind } else { network };
    Some(Link {
        kind,
        label,
        href,
        text,
    })
}

fn emit_links(html: &mut Html, profiles: &[Profile]) {
    let rows: Vec<Link<'_>> = profiles.iter().filter_map(profile_link).collect();
    if rows.is_empty() {
        return;
    }
    html.open(
        "nav",
        &[kv("class", "rz-links"), kv("aria-label", "Profiles")],
    );
    html.open("ul", &[kv("class", "rz-link-list")]);
    for row in &rows {
        emit_link(html, row);
    }
    html.close("ul");
    html.close("nav");
}

fn emit_link(html: &mut Html, row: &Link<'_>) {
    let class = format!("rz-link rz-link--{}", row.kind);
    html.open("li", &[kv("class", &class), kv("data-rz-type", row.kind)]);
    html.text_el("span", &[kv("class", "rz-link-label")], row.label);
    let attrs = vec![kv("class", "rz-link-value")];
    emit_value(html, attrs, row.href.as_deref(), &row.text);
    html.close("li");
}

fn emit_summary(html: &mut Html, basics: Option<&Basics>) {
    let Some(summary) = basics.and_then(|b| nonempty(b.summary.as_deref())) else {
        return;
    };
    open_section(html, &SUMMARY);
    emit_prose(html, "rz-prose rz-summary", summary);
    html.close("section");
}

/// A `.rz-section` of `.rz-entries`: id, title, and the `data-rz-kind`
/// extras carry.
struct Section {
    id: &'static str,
    title: &'static str,
    extra: bool,
    kind: Option<&'static str>,
}

const EXPERIENCE: Section = Section {
    id: "experience",
    title: "Experience",
    extra: false,
    kind: None,
};
const VOLUNTEER: Section = Section {
    id: "volunteer",
    title: "Volunteer",
    extra: true,
    kind: Some("entries"),
};
const EDUCATION: Section = Section {
    id: "education",
    title: "Education",
    extra: false,
    kind: None,
};
const AWARDS: Section = Section {
    id: "awards",
    title: "Awards",
    extra: true,
    kind: Some("entries"),
};
const CERTIFICATES: Section = Section {
    id: "certificates",
    title: "Certificates",
    extra: true,
    kind: Some("entries"),
};
const PUBLICATIONS: Section = Section {
    id: "publications",
    title: "Publications",
    extra: true,
    kind: Some("entries"),
};
const INTERESTS_ENTRIES: Section = Section {
    id: "interests",
    title: "Interests",
    extra: true,
    kind: Some("entries"),
};
const INTERESTS_TAGS: Section = Section {
    id: "interests",
    title: "Interests",
    extra: true,
    kind: Some("tags"),
};
const REFERENCES: Section = Section {
    id: "references",
    title: "References",
    extra: true,
    kind: Some("entries"),
};
const PROJECTS: Section = Section {
    id: "projects",
    title: "Projects",
    extra: false,
    kind: None,
};

/// Emit a section of entries, skipping entries with nothing to show and the
/// whole section when none remain (Invariant 5). Every `<li class="rz-entry">`
/// therefore has at least one child node.
fn emit_entry_section(
    html: &mut Html,
    section: &Section,
    entries: Vec<EntryBits<'_>>,
    slugs: &mut HashSet<String>,
) {
    let entries: Vec<EntryBits<'_>> = entries.into_iter().filter(EntryBits::has_content).collect();
    if entries.is_empty() {
        return;
    }
    open_section(html, section);
    html.open("ol", &[kv("class", "rz-entries")]);
    for bits in &entries {
        emit_entry(html, bits, slugs);
    }
    html.close("ol");
    html.close("section");
}

fn emit_experience(html: &mut Html, items: &[Work], slugs: &mut HashSet<String>) {
    let entries = items.iter().map(work_bits).collect();
    emit_entry_section(html, &EXPERIENCE, entries, slugs);
}

fn work_bits(work: &Work) -> EntryBits<'_> {
    EntryBits {
        kind: "experience",
        primary: primary_link(work.name.as_deref(), work.url.as_deref()),
        secondary: nonempty(work.position.as_deref()).map(str::to_string),
        start: date_token(nonempty(work.start_date.as_deref())),
        end: date_token(nonempty(work.end_date.as_deref())),
        location: nonempty(work.location.as_deref()),
        summary: nonempty(work.summary.as_deref()),
        highlights: nonempty_list(work.highlights.as_deref()),
        ..EntryBits::default()
    }
}

fn emit_volunteer(html: &mut Html, items: &[Volunteer], slugs: &mut HashSet<String>) {
    let entries = items.iter().map(volunteer_bits).collect();
    emit_entry_section(html, &VOLUNTEER, entries, slugs);
}

fn volunteer_bits(item: &Volunteer) -> EntryBits<'_> {
    EntryBits {
        kind: "extra",
        primary: primary_link(item.organization.as_deref(), item.url.as_deref()),
        secondary: nonempty(item.position.as_deref()).map(str::to_string),
        start: date_token(nonempty(item.start_date.as_deref())),
        end: date_token(nonempty(item.end_date.as_deref())),
        summary: nonempty(item.summary.as_deref()),
        highlights: nonempty_list(item.highlights.as_deref()),
        ..EntryBits::default()
    }
}

fn emit_education(html: &mut Html, items: &[Education], slugs: &mut HashSet<String>) {
    let entries = items.iter().map(education_bits).collect();
    emit_entry_section(html, &EDUCATION, entries, slugs);
}

fn education_bits(item: &Education) -> EntryBits<'_> {
    EntryBits {
        kind: "education",
        primary: primary_link(item.institution.as_deref(), item.url.as_deref()),
        secondary: education_secondary(item),
        start: date_token(nonempty(item.start_date.as_deref())),
        end: date_token(nonempty(item.end_date.as_deref())),
        score: nonempty(item.score.as_deref()).map(format_score),
        tags: nonempty_list(item.courses.as_deref()),
        ..EntryBits::default()
    }
}

fn emit_awards(html: &mut Html, items: &[Award], slugs: &mut HashSet<String>) {
    let entries = items.iter().map(award_bits).collect();
    emit_entry_section(html, &AWARDS, entries, slugs);
}

fn award_bits(item: &Award) -> EntryBits<'_> {
    EntryBits {
        kind: "extra",
        primary: primary_link(item.title.as_deref(), None),
        secondary: nonempty(item.awarder.as_deref()).map(str::to_string),
        single_date: date_token(nonempty(item.date.as_deref())),
        summary: nonempty(item.summary.as_deref()),
        ..EntryBits::default()
    }
}

fn emit_certificates(html: &mut Html, items: &[Certificate], slugs: &mut HashSet<String>) {
    let entries = items.iter().map(certificate_bits).collect();
    emit_entry_section(html, &CERTIFICATES, entries, slugs);
}

fn certificate_bits(item: &Certificate) -> EntryBits<'_> {
    EntryBits {
        kind: "extra",
        primary: primary_link(item.name.as_deref(), item.url.as_deref()),
        secondary: nonempty(item.issuer.as_deref()).map(str::to_string),
        single_date: date_token(nonempty(item.date.as_deref())),
        ..EntryBits::default()
    }
}

fn emit_publications(html: &mut Html, items: &[Publication], slugs: &mut HashSet<String>) {
    let entries = items.iter().map(publication_bits).collect();
    emit_entry_section(html, &PUBLICATIONS, entries, slugs);
}

fn publication_bits(item: &Publication) -> EntryBits<'_> {
    EntryBits {
        kind: "extra",
        primary: primary_link(item.name.as_deref(), item.url.as_deref()),
        secondary: nonempty(item.publisher.as_deref()).map(str::to_string),
        single_date: date_token(nonempty(item.release_date.as_deref())),
        summary: nonempty(item.summary.as_deref()),
        ..EntryBits::default()
    }
}

fn emit_skills(html: &mut Html, items: &[Skill]) {
    let items: Vec<&Skill> = items.iter().filter(|s| skill_has_content(s)).collect();
    if items.is_empty() {
        return;
    }
    open_section(html, &SKILLS);
    html.open("ul", &[kv("class", "rz-skill-groups")]);
    let mut group_slugs = HashSet::new();
    for skill in items {
        emit_skill_group(html, skill, &mut group_slugs);
    }
    html.close("ul");
    html.close("section");
}

const SKILLS: Section = Section {
    id: "skills",
    title: "Skills",
    extra: false,
    kind: None,
};
const LANGUAGES: Section = Section {
    id: "languages",
    title: "Languages",
    extra: true,
    kind: Some("list"),
};
const SUMMARY: Section = Section {
    id: "summary",
    title: "Summary",
    extra: false,
    kind: None,
};

fn emit_skill_group(html: &mut Html, skill: &Skill, group_slugs: &mut HashSet<String>) {
    let name = nonempty(skill.name.as_deref());
    let slug = skill_slug(name.unwrap_or(""), group_slugs);
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
    let keywords = trimmed(nonempty_list(skill.keywords.as_deref()));
    if !keywords.is_empty() {
        html.open("ul", &[kv("class", "rz-skill-list")]);
        for keyword in keywords {
            html.text_el("li", &[kv("class", "rz-skill")], keyword);
        }
        html.close("ul");
    }
    html.close("li");
}

fn emit_languages(html: &mut Html, items: &[Language]) {
    let rows: Vec<(&str, Option<&str>)> = items
        .iter()
        .filter_map(|l| {
            nonempty(l.language.as_deref()).map(|name| (name, nonempty(l.fluency.as_deref())))
        })
        .collect();
    if rows.is_empty() {
        return;
    }
    open_section(html, &LANGUAGES);
    html.open("ul", &[kv("class", "rz-meta-list")]);
    for (name, fluency) in rows {
        html.open("li", &[kv("class", "rz-meta")]);
        html.text_el("span", &[kv("class", "rz-meta-label")], name);
        if let Some(fluency) = fluency {
            html.text_el("span", &[kv("class", "rz-meta-detail")], fluency);
        }
        html.close("li");
    }
    html.close("ul");
    html.close("section");
}

fn emit_interests(html: &mut Html, items: &[Interest], slugs: &mut HashSet<String>) {
    let items: Vec<(&str, &Interest)> = items
        .iter()
        .filter_map(|i| nonempty(i.name.as_deref()).map(|name| (name, i)))
        .collect();
    if items.is_empty() {
        return;
    }
    let as_entries = items.iter().any(|(_, i)| has_any(i.keywords.as_deref()));
    if as_entries {
        let entries = items
            .iter()
            .map(|(name, item)| EntryBits {
                kind: "extra",
                primary: primary_link(Some(name), None),
                tags: nonempty_list(item.keywords.as_deref()),
                ..EntryBits::default()
            })
            .collect();
        emit_entry_section(html, &INTERESTS_ENTRIES, entries, slugs);
    } else {
        open_section(html, &INTERESTS_TAGS);
        html.open("ul", &[kv("class", "rz-tags")]);
        for (name, _) in items {
            html.text_el("li", &[kv("class", "rz-tag")], name);
        }
        html.close("ul");
        html.close("section");
    }
}

fn emit_references(html: &mut Html, items: &[Reference], slugs: &mut HashSet<String>) {
    let entries = items
        .iter()
        .map(|item| EntryBits {
            kind: "extra",
            primary: primary_link(item.name.as_deref(), None),
            summary: nonempty(item.reference.as_deref()),
            ..EntryBits::default()
        })
        .collect();
    emit_entry_section(html, &REFERENCES, entries, slugs);
}

fn emit_projects(html: &mut Html, items: &[Project], slugs: &mut HashSet<String>) {
    let entries = items.iter().map(project_bits).collect();
    emit_entry_section(html, &PROJECTS, entries, slugs);
}

fn project_bits(item: &Project) -> EntryBits<'_> {
    EntryBits {
        kind: "project",
        primary: primary_link(item.name.as_deref(), item.url.as_deref()),
        secondary: nonempty(item.description.as_deref()).map(str::to_string),
        start: date_token(nonempty(item.start_date.as_deref())),
        end: date_token(nonempty(item.end_date.as_deref())),
        highlights: nonempty_list(item.highlights.as_deref()),
        tags: nonempty_list(item.keywords.as_deref()),
        meta: project_meta(item),
        ..EntryBits::default()
    }
}

fn project_meta(item: &Project) -> Vec<(String, String)> {
    let roles = trimmed(nonempty_list(item.roles.as_deref()));
    let roles = (!roles.is_empty()).then(|| ("Roles".to_string(), roles.join(", ")));
    let entity =
        nonempty(item.entity.as_deref()).map(|e| ("Affiliation".to_string(), e.to_string()));
    let kind = nonempty(item.r#type.as_deref()).map(|k| ("Type".to_string(), k.to_string()));
    [roles, entity, kind].into_iter().flatten().collect()
}

/// The entry's headline: the name, or the hostname when only a safe URL was
/// given, so a link always has text and an entry always has a headline when
/// it has a URL.
struct Primary<'a> {
    text: Cow<'a, str>,
    href: Option<String>,
}

/// Calculation: `name` (with a safe `url` as href) or the hostname of a safe
/// `url`; `None` when neither yields text.
fn primary_link<'a>(name: Option<&'a str>, url: Option<&str>) -> Option<Primary<'a>> {
    let href = nonempty(url).and_then(safe_href);
    let text = nonempty(name).map(Cow::Borrowed).or_else(|| {
        href.as_deref()
            .map(|href| Cow::Owned(hostname(href).to_string()))
    })?;
    Some(Primary { text, href })
}

/// View model for one `.rz-entry`. Everything optional; `has_content` says
/// whether emitting it would produce any child node.
#[derive(Default)]
struct EntryBits<'a> {
    kind: &'a str,
    primary: Option<Primary<'a>>,
    secondary: Option<String>,
    start: Option<DateToken<'a>>,
    end: Option<DateToken<'a>>,
    single_date: Option<DateToken<'a>>,
    location: Option<&'a str>,
    score: Option<String>,
    summary: Option<&'a str>,
    highlights: &'a [String],
    tags: &'a [String],
    meta: Vec<(String, String)>,
}

impl EntryBits<'_> {
    fn has_header(&self) -> bool {
        self.primary.is_some()
            || self.secondary.is_some()
            || self.start.is_some()
            || self.end.is_some()
            || self.single_date.is_some()
            || self.location.is_some()
            || self.score.is_some()
    }

    fn has_content(&self) -> bool {
        self.has_header()
            || self.summary.is_some()
            || !self.meta.is_empty()
            || any_nonblank(self.tags)
            || any_nonblank(self.highlights)
    }

    fn slug_year(&self) -> Option<u16> {
        self.single_date
            .or(self.start)
            .and_then(|token| token.parsed)
            .map(|date| date.year)
    }

    fn is_current(&self) -> bool {
        self.single_date.is_none()
            && self.start.is_some_and(|token| token.parsed.is_some())
            && self.end.is_none()
    }
}

fn emit_entry(html: &mut Html, bits: &EntryBits<'_>, slugs: &mut HashSet<String>) {
    let primary_text = bits.primary.as_ref().map_or("", |p| p.text.as_ref());
    let slug = entry_slug(primary_text, bits.slug_year(), slugs);
    let is_current = bits.is_current();
    let mut class = format!("rz-entry rz-entry--{}", bits.kind);
    if is_current {
        class.push_str(" rz-is-current");
    }
    let mut attrs = vec![kv("class", &class), kv("data-rz-entry", &slug)];
    if is_current {
        attrs.push(kv("data-rz-current", "true"));
    }
    html.open("li", &attrs);

    if bits.has_header() {
        emit_entry_header(html, bits);
    }
    if let Some(summary) = bits.summary {
        emit_prose(html, "rz-prose", summary);
    }
    emit_meta(html, &bits.meta);
    emit_tags(html, bits.tags);
    emit_bullets(html, bits.highlights);
    html.close("li");
}

fn emit_entry_header(html: &mut Html, bits: &EntryBits<'_>) {
    html.open("div", &[kv("class", "rz-entry-header")]);
    if let Some(primary) = &bits.primary {
        emit_primary(html, primary);
    }
    if let Some(secondary) = bits.secondary.as_deref() {
        html.text_el("p", &[kv("class", "rz-entry-secondary")], secondary);
    }
    emit_dates(html, bits);
    if let Some(location) = bits.location {
        html.text_el("p", &[kv("class", "rz-location")], location);
    }
    if let Some(score) = bits.score.as_deref() {
        html.text_el("p", &[kv("class", "rz-score")], score);
    }
    html.close("div");
}

fn emit_primary(html: &mut Html, primary: &Primary<'_>) {
    match primary.href.as_deref() {
        Some(href) => {
            html.open("h3", &[kv("class", "rz-entry-primary")]);
            html.text_el(
                "a",
                &[kv("class", "rz-entry-primary-link"), kv("href", href)],
                &primary.text,
            );
            html.close("h3");
        }
        None => html.text_el("h3", &[kv("class", "rz-entry-primary")], &primary.text),
    }
}

fn emit_meta(html: &mut Html, meta: &[(String, String)]) {
    if meta.is_empty() {
        return;
    }
    html.open("ul", &[kv("class", "rz-meta-list")]);
    for (label, detail) in meta {
        html.open("li", &[kv("class", "rz-meta")]);
        html.text_el("span", &[kv("class", "rz-meta-label")], label);
        html.text_el("span", &[kv("class", "rz-meta-detail")], detail);
        html.close("li");
    }
    html.close("ul");
}

/// A date field as the Author wrote it, plus what the renderer made of it.
/// `parsed == None` means the raw text still renders, as a `<span>`.
#[derive(Clone, Copy)]
struct DateToken<'a> {
    raw: &'a str,
    parsed: Option<IsoDate>,
}

fn date_token(raw: Option<&str>) -> Option<DateToken<'_>> {
    raw.map(|raw| DateToken {
        raw,
        parsed: parse_iso_date(raw),
    })
}

fn emit_dates(html: &mut Html, bits: &EntryBits<'_>) {
    match (bits.single_date, bits.start, bits.end) {
        (Some(date), _, _) | (None, None, Some(date)) => {
            html.open("p", &[kv("class", "rz-dates")]);
            emit_date(html, "rz-date", date);
            html.close("p");
        }
        (None, Some(start), end) => {
            html.open("p", &[kv("class", "rz-dates")]);
            emit_date(html, "rz-date rz-date--start", start);
            html.text_el(
                "span",
                &[kv("class", "rz-date-sep"), kv("aria-hidden", "true")],
                "–",
            );
            emit_range_end(html, end);
            html.close("p");
        }
        (None, None, None) => {}
    }
}

/// `<time datetime>` when the value parsed; otherwise the raw text in a
/// `<span>` with the same class and no `datetime` (contract §5.3).
fn emit_date(html: &mut Html, class: &str, token: DateToken<'_>) {
    match token.parsed {
        Some(date) => html.text_el(
            "time",
            &[kv("class", class), kv("datetime", &date.datetime())],
            &date.visible(),
        ),
        None => html.text_el("span", &[kv("class", class)], token.raw),
    }
}

/// An omitted `endDate` means present; a written one renders as itself.
fn emit_range_end(html: &mut Html, end: Option<DateToken<'_>>) {
    match end {
        Some(end) => emit_date(html, "rz-date rz-date--end", end),
        None => html.text_el(
            "span",
            &[kv("class", "rz-date rz-date--end rz-date--present")],
            "Present",
        ),
    }
}

/// Windows line endings become `\n` so paragraph and bullet splitting sees
/// one newline convention.
fn normalize_newlines(text: &str) -> Cow<'_, str> {
    if text.contains("\r\n") {
        Cow::Owned(text.replace("\r\n", "\n"))
    } else {
        Cow::Borrowed(text)
    }
}

fn emit_prose(html: &mut Html, class: &str, text: &str) {
    let text = normalize_newlines(text);
    html.open("div", &[kv("class", class)]);
    for para in text.split("\n\n").map(str::trim).filter(|p| !p.is_empty()) {
        html.text_el("p", &[], para);
    }
    html.close("div");
}

fn emit_bullets(html: &mut Html, items: &[String]) {
    let items = trimmed(items);
    if items.is_empty() {
        return;
    }
    html.open("ul", &[kv("class", "rz-bullets")]);
    for item in items {
        html.text_el("li", &[kv("class", "rz-bullet")], &normalize_newlines(item));
    }
    html.close("ul");
}

fn emit_tags(html: &mut Html, items: &[String]) {
    let items = trimmed(items);
    if items.is_empty() {
        return;
    }
    html.open("ul", &[kv("class", "rz-tags")]);
    for item in items {
        html.text_el("li", &[kv("class", "rz-tag")], item);
    }
    html.close("ul");
}

/// Trimmed, non-blank items in order.
fn trimmed(items: &[String]) -> Vec<&str> {
    items
        .iter()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect()
}

fn open_section(html: &mut Html, section: &Section) {
    let id = section.id;
    let class = if section.extra {
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
    attrs.extend(section.kind.map(|kind| kv("data-rz-kind", kind)));
    html.open("section", &attrs);
    html.text_el("h2", &[kv("class", "rz-section-title")], section.title);
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

fn skill_has_content(s: &Skill) -> bool {
    nonempty(s.name.as_deref()).is_some()
        || nonempty(s.level.as_deref()).is_some()
        || has_any(s.keywords.as_deref())
}

fn has_any(items: Option<&[String]>) -> bool {
    items.is_some_and(any_nonblank)
}

fn any_nonblank(items: &[String]) -> bool {
    items.iter().any(|s| !s.trim().is_empty())
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
