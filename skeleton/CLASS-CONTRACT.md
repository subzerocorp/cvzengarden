# ResumeZen HTML class contract

**Version:** `1.0`  
**Status:** stable interface — treat class names as a public API  
**Namespace:** `rz-`  
**Companion files:** [`example.html`](example.html), [`resume.json`](resume.json)

This document is the agreement between:

- the **Rust renderer** (JSON → this HTML),
- **theme authors** (pure CSS targeting these classes),
- **product chrome** (must never use `rz-*`),
- **AI theme prompts** (must emit CSS against this list).

A designer should be able to write a complete theme from this spec and `example.html` alone.

---

## 1. Invariants

1. **One tree.** Every résumé is the same tags, in the same structural order, with the same class vocabulary. Themes restyle. They do not rearrange the DOM.
2. **Semantic first.** Real `<article>`, `<header>`, `<section>`, `<h1>`–`<h3>`, `<ol>`/`<ul>`, `<a href>`, `<time datetime>`. No layout tables. No text-as-image. No important content injected via `content:`.
3. **ATS-friendly.** Parsers and humans read the same words. Dates have machine `datetime` values. Contacts are real `mailto:`, `tel:`, and `https:` links. Heading rank is honest (`h1` name, `h2` section, `h3` entry).
4. **Namespaced classes.** Every contract class starts with `rz-`. Product chrome will never use that prefix. Theme CSS must not target chrome classes.
5. **Omit empties.** The renderer drops a section, contact, link, entry, or bullet when it has no content. Themes must not require any optional node to exist.
6. **Labels stay in the DOM.** Section titles, contact labels, and link labels are real text nodes. A theme may hide them visually; it must not rely on replacing them with CSS `content` if the words matter to ATS.
7. **Standalone vs. gallery.** In a standalone/export document, a theme may style `html` and `body`. In the gallery, the résumé is sandboxed (iframe or equivalent) so theme CSS cannot leak into product chrome.

### What themes may style

| Selector | Allowed? |
| --- | --- |
| `html`, `body` (of the résumé document) | Yes |
| `.rz-resume` and any `.rz-*` descendant | Yes |
| `[data-rz-*]` attributes on contract nodes | Yes |
| Product chrome (gallery, buttons, dialogs, nav) | **No** |
| `skeleton/preview.css` helpers | **No** — not part of the contract |

### What themes must not do

- Add or require extra HTML, scripts, webfont loader JS, or build tools.
- Depend on Tailwind, CSS-in-JS, or a preprocessor at ship time. Ship a single `.css` file.
- Assume a section is present, or assume a photo, pronouns, end date, or extras block exists.
- Use class names that collide with chrome. Stay in `rz-*`.

Custom properties are fine. Prefer `--rz-*` inside a theme so they cannot collide with chrome tokens (`--background`, `--primary`, …).

---

## 2. Document shell

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{name} — {label}</title>
    <!-- theme stylesheet linked here in standalone / iframe documents -->
  </head>
  <body>
    <article class="rz-resume"
             data-rz-schema="1.0"
             itemscope
             itemtype="https://schema.org/Person">
      <!-- header, then sections in canonical order -->
    </article>
  </body>
</html>
```

| Class / attr | On | Meaning |
| --- | --- | --- |
| `.rz-resume` | `<article>` | Root of the résumé. The theme's canvas. |
| `data-rz-schema="1.0"` | `.rz-resume` | Contract version the renderer emitted. |
| `lang` | `<html>` | From `meta.locale` (BCP 47). Default `en`. |

Schema.org microdata is optional sugar on identity fields (`itemprop="name"`, `jobTitle`, `email`, `url`, `address`). Themes should ignore it.

---

## 3. Canonical section order

The renderer emits this order. Missing sections are skipped, not left blank.

1. **Identity header** — always present (at least a name)
2. **Summary** — `basics.summary`
3. **Experience**
4. **Education**
5. **Skills**
6. **Projects**
7. **Extras** — zero or more, in JSON array order (awards, languages, certifications, volunteer, publications, interests, references, custom, …)

Each body section is:

```html
<section class="rz-section rz-section--{id}"
         id="rz-{id}"
         data-rz-section="{id}">
  <h2 class="rz-section-title">{title}</h2>
  <!-- section body -->
</section>
```

| Class / attr | Meaning |
| --- | --- |
| `.rz-section` | Any body section. |
| `.rz-section--summary`, `--experience`, `--education`, `--skills`, `--projects` | Built-in section kinds. |
| `.rz-section--extra` | Plus `.rz-section--{id}` for a custom extra (`--awards`, `--languages`, …). |
| `.rz-section-title` | Visible `h2` heading. |
| `id="rz-{id}"` | Fragment target (`#rz-experience`). |
| `data-rz-section="{id}"` | Stable machine id. Built-ins: `summary`, `experience`, `education`, `skills`, `projects`. Extras use their JSON `id`. |
| `data-rz-kind` | Extra sections only: `entries` \| `list` \| `prose` \| `tags`. |

---

## 4. Identity (header)

```html
<header class="rz-header">
  <div class="rz-identity">
    <h1 class="rz-name" itemprop="name">Jordan Hale</h1>
    <p class="rz-title" itemprop="jobTitle">Design Engineer</p>
    <p class="rz-pronouns">they/them</p>
  </div>

  <figure class="rz-photo">
    <img class="rz-photo-img" src="…" alt="Portrait of Jordan Hale" width="160" height="160">
  </figure>

  <address class="rz-contacts">
    <ul class="rz-contact-list">
      <li class="rz-contact rz-contact--email" data-rz-type="email">
        <span class="rz-contact-label">Email</span>
        <a class="rz-contact-value" itemprop="email" href="mailto:jordan@example.com">jordan@example.com</a>
      </li>
      <!-- phone, location, url, other -->
    </ul>
  </address>

  <nav class="rz-links" aria-label="Profiles">
    <ul class="rz-link-list">
      <li class="rz-link rz-link--github" data-rz-type="github">
        <span class="rz-link-label">GitHub</span>
        <a class="rz-link-value" itemprop="url" href="https://github.com/jordanhale">jordanhale</a>
      </li>
    </ul>
  </nav>
</header>
```

### Identity classes

| Class | Element | Required | Notes |
| --- | --- | --- | --- |
| `.rz-header` | `<header>` | yes | Identity block. |
| `.rz-identity` | `<div>` | yes | Name cluster. |
| `.rz-name` | `<h1>` | yes | Only `h1` in the document. |
| `.rz-title` | `<p>` | if `basics.label` | Professional headline, not a heading. |
| `.rz-pronouns` | `<p>` | if `basics.pronouns` | |
| `.rz-photo` | `<figure>` | if `basics.image` | Omitted when null. Optional; ATS export may drop it later. |
| `.rz-photo-img` | `<img>` | with photo | Meaningful `alt`. |
| `.rz-contacts` | `<address>` | if any contacts | Contact info, not a mailing-street requirement. |
| `.rz-contact-list` | `<ul>` | with contacts | |
| `.rz-contact` | `<li>` | each | Modifier `.rz-contact--{type}`. |
| `.rz-contact-label` | `<span>` | each | Human label (`Email`, `Phone`). |
| `.rz-contact-value` | `<a>` or `<span>` | each | `<a>` when `href` exists; `<span>` for plain location text. |
| `.rz-links` | `<nav>` | if any links | Profiles / portfolio. |
| `.rz-link-list` | `<ul>` | with links | |
| `.rz-link` | `<li>` | each | Modifier `.rz-link--{type}`. |
| `.rz-link-label` | `<span>` | each | `GitHub`, `Portfolio`. |
| `.rz-link-value` | `<a>` | each | Visible text is `value` or hostname. |

### Contact `type` values

`email` · `phone` · `location` · `url` · `other`

Unknown types render as `.rz-contact--other` with `data-rz-type` preserved.

### Link `type` values

`website` · `github` · `gitlab` · `linkedin` · `mastodon` · `bluesky` · `dribbble` · `behance` · `twitter` · `x` · `other`

Same fallback rule as contacts.

---

## 5. Summary

```html
<section class="rz-section rz-section--summary" id="rz-summary" data-rz-section="summary">
  <h2 class="rz-section-title">Summary</h2>
  <div class="rz-prose rz-summary">
    <p>…</p>
  </div>
</section>
```

| Class | Meaning |
| --- | --- |
| `.rz-summary` | Summary body. One or more `<p>`. |
| `.rz-prose` | Shared prose wrapper (summary and `kind: "prose"` extras). |

Plain text in JSON becomes a single `<p>`. A JSON array of strings becomes multiple `<p>`s. No markdown in v1.

---

## 6. Dated entries (experience, education, projects, extra `entries`)

Shared entry chrome:

```html
<li class="rz-entry rz-entry--experience rz-is-current" data-rz-entry="acme-2022">
  <div class="rz-entry-header">
    <h3 class="rz-entry-primary">
      <a class="rz-entry-primary-link" href="https://acme.example">Acme Studio</a>
    </h3>
    <p class="rz-entry-secondary">Staff Design Engineer</p>
    <p class="rz-dates">
      <time class="rz-date rz-date--start" datetime="2022-03">March 2022</time>
      <span class="rz-date-sep" aria-hidden="true">–</span>
      <span class="rz-date rz-date--end rz-date--present">Present</span>
    </p>
    <p class="rz-location">Remote</p>
  </div>
  <ul class="rz-bullets">
    <li class="rz-bullet">Shipped the design-system documentation site.</li>
  </ul>
</li>
```

When the primary has no URL, `.rz-entry-primary` is plain text (no `<a>`).

| Class / attr | Meaning |
| --- | --- |
| `.rz-entries` | `<ol>` of entries. Document order = JSON order. |
| `.rz-entry` | One job, school, project, or extra entry. |
| `.rz-entry--experience` · `--education` · `--project` · `--extra` | Kind modifier. |
| `.rz-is-current` | Present role / in-progress study. Also `data-rz-current="true"`. |
| `data-rz-entry` | Stable id from JSON (slug). |
| `.rz-entry-header` | Primary / secondary / dates / location cluster. |
| `.rz-entry-primary` | `h3`: organization, institution, or project name. |
| `.rz-entry-primary-link` | Optional link wrapping the primary text. |
| `.rz-entry-secondary` | Role, degree + area, or project tagline. |
| `.rz-dates` | Date range container. Omitted if no dates. |
| `.rz-date` | A date token. |
| `.rz-date--start` / `--end` | Start vs end. |
| `.rz-date--present` | End is current (`Present`). This is a `<span>`, not `<time>`. |
| `.rz-date-sep` | Separator (`–`). Decorative; `aria-hidden`. |
| `.rz-location` | City / remote / campus. |
| `.rz-bullets` | Highlight list. Omitted if empty. |
| `.rz-bullet` | One highlight. Plain text. |

### Field mapping

| Slot | Experience | Education | Project | Extra entry |
| --- | --- | --- | --- | --- |
| `.rz-entry-primary` | `organization` | `institution` | `name` | `title` |
| `.rz-entry-secondary` | `role` | `{studyType} in {area}` (parts that exist) | `description` (short) or omitted if only bullets | `subtitle` |
| `.rz-location` | `location` | `location` | `location` | `location` |
| `.rz-dates` | `start` / `end` / `current` | same | same | `date` (single) or `start`/`end` |

A single extra date uses one `.rz-date` without a separator.

### Date format

JSON dates are ISO-8601 prefixes: `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`.  
Visible text is locale-formatted (`March 2022`). `datetime` keeps the raw ISO value.

`end: null` plus `current: true` → `.rz-date--present` with the word `Present` (localized later).  
`end: null` and not current → omit the end date and the separator.

---

## 7. Experience

```html
<section class="rz-section rz-section--experience" id="rz-experience" data-rz-section="experience">
  <h2 class="rz-section-title">Experience</h2>
  <ol class="rz-entries">
    <li class="rz-entry rz-entry--experience">…</li>
  </ol>
</section>
```

---

## 8. Education

Same entry pattern. `.rz-entry--education`.

If `score` is present it is a final line in the header:

```html
<p class="rz-score">GPA 3.8</p>
```

| Class | Meaning |
| --- | --- |
| `.rz-score` | Optional GPA / honors / result. |

---

## 9. Skills

Skills are **groups** of keywords. A flat list is one group with no name.

```html
<section class="rz-section rz-section--skills" id="rz-skills" data-rz-section="skills">
  <h2 class="rz-section-title">Skills</h2>
  <ul class="rz-skill-groups">
    <li class="rz-skill-group" data-rz-skill-group="engineering">
      <h3 class="rz-skill-group-name">Engineering</h3>
      <ul class="rz-skill-list">
        <li class="rz-skill">Rust</li>
        <li class="rz-skill">CSS</li>
      </ul>
    </li>
  </ul>
</section>
```

| Class | Meaning |
| --- | --- |
| `.rz-skill-groups` | List of groups. |
| `.rz-skill-group` | One named (or anonymous) group. |
| `.rz-skill-group-name` | Group heading. Omitted when `name` is empty. |
| `.rz-skill-list` | Keywords in that group. |
| `.rz-skill` | One keyword. Text only — no links in v1. |

---

## 10. Projects

Same dated-entry pattern. `.rz-entry--project`.

Optional keyword row under the header, before bullets:

```html
<ul class="rz-tags">
  <li class="rz-tag">CSS</li>
  <li class="rz-tag">Type</li>
</ul>
```

| Class | Meaning |
| --- | --- |
| `.rz-tags` | Inline keyword list (projects and `kind: "tags"` extras). |
| `.rz-tag` | One keyword. |

A long `description` that is not used as `.rz-entry-secondary` may instead appear as `.rz-prose` inside the entry. The sample uses secondary for the one-line pitch and bullets for outcomes. The renderer should prefer: secondary = `description` if it is a single short string; bullets = `highlights`.

---

## 11. Extras (optional sections)

Each extra is a `.rz-section.rz-section--extra.rz-section--{id}` with `data-rz-kind`.

### `kind: "entries"`

An `.rz-entries` list of `.rz-entry.rz-entry--extra` (awards, volunteer, publications, certifications).

### `kind: "list"`

Labeled items (languages, references):

```html
<ul class="rz-meta-list">
  <li class="rz-meta">
    <span class="rz-meta-label">English</span>
    <span class="rz-meta-detail">Native</span>
  </li>
</ul>
```

| Class | Meaning |
| --- | --- |
| `.rz-meta-list` | Pair list. |
| `.rz-meta` | One pair. |
| `.rz-meta-label` | Term. |
| `.rz-meta-detail` | Optional qualifier. Omitted if empty. |

### `kind: "prose"`

```html
<div class="rz-prose">
  <p>…</p>
</div>
```

### `kind: "tags"`

A `.rz-tags` list of `.rz-tag` (interests, tools dump).

Unknown `kind` values must not appear. The renderer rejects or skips them.

---

## 12. Class inventory (quick list)

Themes can treat this as the complete selector surface.

**Root:** `rz-resume`

**Header:** `rz-header` · `rz-identity` · `rz-name` · `rz-title` · `rz-pronouns` · `rz-photo` · `rz-photo-img` · `rz-contacts` · `rz-contact-list` · `rz-contact` · `rz-contact--{type}` · `rz-contact-label` · `rz-contact-value` · `rz-links` · `rz-link-list` · `rz-link` · `rz-link--{type}` · `rz-link-label` · `rz-link-value`

**Sections:** `rz-section` · `rz-section--summary` · `rz-section--experience` · `rz-section--education` · `rz-section--skills` · `rz-section--projects` · `rz-section--extra` · `rz-section--{extra-id}` · `rz-section-title`

**Prose:** `rz-prose` · `rz-summary`

**Entries:** `rz-entries` · `rz-entry` · `rz-entry--experience` · `rz-entry--education` · `rz-entry--project` · `rz-entry--extra` · `rz-is-current` · `rz-entry-header` · `rz-entry-primary` · `rz-entry-primary-link` · `rz-entry-secondary` · `rz-dates` · `rz-date` · `rz-date--start` · `rz-date--end` · `rz-date--present` · `rz-date-sep` · `rz-location` · `rz-score` · `rz-bullets` · `rz-bullet`

**Skills:** `rz-skill-groups` · `rz-skill-group` · `rz-skill-group-name` · `rz-skill-list` · `rz-skill`

**Tags / meta:** `rz-tags` · `rz-tag` · `rz-meta-list` · `rz-meta` · `rz-meta-label` · `rz-meta-detail`

**State / data:** `data-rz-schema` · `data-rz-section` · `data-rz-kind` · `data-rz-type` · `data-rz-entry` · `data-rz-skill-group` · `data-rz-current`

No other `rz-*` classes exist in v1. If you need a new one, bump the contract — do not invent it in a single theme.

---

## 13. `resume.json` shape

Schema id: `resumezen.v1`. The renderer will consume this document. Unknown fields are ignored. Extra sections use the `extras` array — do not add ad-hoc top-level keys for awards, languages, etc.

```json
{
  "meta": {
    "schema": "resumezen.v1",
    "locale": "en"
  },
  "basics": {
    "name": "string",
    "label": "string?",
    "pronouns": "string?",
    "image": "url?",
    "summary": "string | string[]",
    "contacts": [
      { "type": "email|phone|location|url|other", "label": "string", "value": "string", "href": "string?" }
    ],
    "links": [
      { "type": "website|github|…|other", "label": "string", "value": "string?", "href": "string" }
    ]
  },
  "experience": [
    {
      "id": "slug",
      "organization": "string",
      "url": "url?",
      "role": "string",
      "location": "string?",
      "start": "YYYY[-MM[-DD]]?",
      "end": "YYYY[-MM[-DD]]?",
      "current": false,
      "highlights": ["string"]
    }
  ],
  "education": [
    {
      "id": "slug",
      "institution": "string",
      "url": "url?",
      "area": "string?",
      "studyType": "string?",
      "location": "string?",
      "start": "date?",
      "end": "date?",
      "current": false,
      "score": "string?",
      "highlights": ["string"]
    }
  ],
  "skills": [
    { "id": "slug?", "name": "string?", "keywords": ["string"] }
  ],
  "projects": [
    {
      "id": "slug",
      "name": "string",
      "url": "url?",
      "description": "string?",
      "location": "string?",
      "start": "date?",
      "end": "date?",
      "current": false,
      "highlights": ["string"],
      "keywords": ["string"]
    }
  ],
  "extras": [
    {
      "id": "slug",
      "title": "string",
      "kind": "entries|list|prose|tags",
      "entries": [{ "id": "slug?", "title": "string", "subtitle": "string?", "url": "url?", "location": "string?", "date": "date?", "start": "date?", "end": "date?", "highlights": ["string"] }],
      "items": [{ "label": "string", "detail": "string?" }],
      "prose": "string | string[]",
      "tags": ["string"]
    }
  ]
}
```

Only the property bag that matches `kind` is read (`entries` / `items` / `prose` / `tags`).

See [`resume.json`](resume.json) for a complete, valid example. [`example.html`](example.html) is the HTML that example must compile to.

---

## 14. ATS and accessibility checklist

- [x] One `h1` (the name). Sections are `h2`. Entries and skill groups are `h3`.
- [x] Lists are real lists. Jobs are an ordered list (sequence matters).
- [x] Links have real `href`s. Email and phone use `mailto:` and `tel:`.
- [x] Dates expose ISO `datetime` on `<time>`.
- [x] Contact block is `<address>`. Profile links are `<nav>` with an accessible name.
- [x] Photo, if present, has a textual `alt`.
- [x] No information exists only as a CSS background, icon, or `content:` string.
- [x] Color is a theme concern. The unstyled document remains readable in a browser.
- [x] `lang` is set. Locale-sensitive words (`Present`, month names, section titles) come from the renderer, not the theme.

---

## 15. Versioning

- Additive classes require a contract bump and a renderer release.
- Renames and removals are breaking. Don't.
- `data-rz-schema` tells a theme which generation it was built against. Themes may use it for progressive enhancement; they should still render acceptably on `1.0`.
