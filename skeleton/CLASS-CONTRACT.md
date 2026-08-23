# ResumeZen HTML class contract

**HTML contract version:** `1.0` (`data-rz-schema` on `.rz-resume`)  
**Data interface:** [JSON Resume](https://jsonresume.org/schema)  
**Schema:** [`jsonresume/resume-schema`](https://github.com/jsonresume/resume-schema) (`schema.json`)  
**Namespace:** `rz-`  
**Companion files:** [`example.html`](example.html), [`resume.json`](resume.json)

Two interfaces, one product:

| Interface | What it is | Who consumes it |
| --- | --- | --- |
| **JSON Resume** | Paste / import / store format | Renderer, converter, paste UI |
| **`rz-*` HTML** | Fixed semantic skeleton | Theme CSS, ATS, gallery iframe |

Themes never see JSON. They only target documented `rz-*` classes. JSON Resume theme templates are **not** used.

**Bridge dialects** — [SchemaResume](https://schema-resume.org/) and [UniversalResume](https://github.com/universal-resume) — are **import/export only**. They are not stored and they do not change `rz-*` or JSON Resume keys. See [`../converter/`](../converter/). Do not use UniversalResume's html-renderer or pdf-generator.

There is no `resumezen.v1` JSON dialect. `data-rz-schema` is the **HTML contract version**, not a JSON schema id.

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
8. **JSON Resume in, HTML out.** The renderer consumes a document that validates against [resume-schema](https://github.com/jsonresume/resume-schema). Unknown `additionalProperties` are preserved in storage and ignored by the HTML emitter unless listed in the field map below.

### What themes may style

| Selector | Allowed? |
| --- | --- |
| `html`, `body` (of the résumé document) | Yes |
| `.rz-resume` and any `.rz-*` descendant | Yes |
| `[data-rz-*]` attributes on contract nodes | Yes |
| Product chrome (gallery, buttons, dialogs, nav) | **No** |
| `skeleton/preview.css` helpers | **No** — not part of the contract |

### What themes must not do

- Add or require extra HTML, `<script>`, webfont-loader JavaScript, or a JS build step.
- Depend on Tailwind, CSS-in-JS, or a preprocessor at ship time. Ship a single `.css` file.
- Assume a section is present, or assume a photo, end date, or extras block exists.
- Use class names that collide with chrome. Stay in `rz-*`.
- Target JSON Resume field names. There are no `.basics` / `.work` classes.

Custom properties are fine. Prefer `--rz-*` inside a theme so they cannot collide with chrome tokens (`--background`, `--primary`, …). `@font-face` is allowed (see §2).

---

## 2. Designer themes

This is the locked theme rule set. A designer writes **one** `.css` file. Target lives on that file, not on the HTML. Do not add a `data-` attribute for web/print. `data-rz-schema` stays the HTML contract version.

### One file, one tree

A theme is one pure `.css` file against `html`, `body`, `.rz-*`, and `[data-rz-*]` of the résumé document. It restyles the existing Skeleton. It does not add a second tree.

Two-column and sidebar layouts are a **CSS Grid** (or flex) job on `.rz-header` and `.rz-section` in that tree. Reorder visually with `grid-template-areas` / `order` if you must; do not ask the renderer for a sidebar skeleton.

### Target: `web` | `print` | `both`

Declare the target in a file-header comment. That is enough:

```css
/* rz-target: both */
```

| Target | Intent |
| --- | --- |
| `web` | May be loud on screen. On paper, fall back to the readable unstyled/minimally-styled Skeleton (do not fight `@media print` unless you mean to). |
| `print` | May be quiet on screen. Obsessive about `@page`, page breaks, widows/orphans, and ink. |
| `both` | Same file owns `@media screen` and `@media print`. |

Chrome and the gallery may later filter by this comment. The Skeleton HTML does not change.

### Advanced CSS is allowed

Use the platform: `@keyframes`, transitions, animations, `@font-face`, Grid, container queries, `@page`, `@layer`, `@property`, scroll-driven effects, and whatever else ships in a `.css` file.

`@import` is **discouraged** (supply chain). Prefer one self-contained file. Fonts go through `@font-face` pointing at a hosted or allowlisted face — not a JavaScript webfont loader. We do **not** forbid `@font-face` or webfonts as such.

### JavaScript is forbidden

No `<script`. No webfont-loader JS. No Tailwind. No CSS-in-JS. No extra HTML. If it is not CSS, it is not a Theme.

### Words stay in HTML

Resume words — name, titles, dates, section labels, contact values, bullets — must remain HTML text nodes. `content:` must not be the only place those words live. Decorative `content:` that does not replace ATS-relevant text is a designer choice.

Do not emit pronouns. Do not invent fields the JSON Resume map does not have. A theme cannot create a `.rz-pronouns` node; the renderer will not either.

### Motion is for screens

Animate on screen if you want. In `@media print`, animation and transition must be off or harmless (`animation: none`, `transition: none`, or a print stylesheet that never starts them). Honor `prefers-reduced-motion: reduce` the same way: snap to the end state, no required motion on ordinary reading.

---

## 3. Document shell

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{basics.name} — {basics.label}</title>
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
| `data-rz-schema="1.0"` | `.rz-resume` | **HTML** contract version the renderer emitted. Not a JSON dialect. |
| `lang` | `<html>` | Default `en`. JSON Resume has no locale field. |

Schema.org microdata is optional sugar on identity fields (`itemprop="name"`, `jobTitle`, `email`, `url`, `address`). Themes should ignore it.

JSON Resume `meta` (`canonical`, `version`, `lastModified`) is **not** rendered.

---

## 4. Canonical section order

The renderer emits this order — JSON Resume's top-level property order, with `basics.summary` lifted into its own section. Missing sections are skipped, not left blank.

1. **Identity header** — `basics` (always present if `basics.name` exists)
2. **Summary** — `basics.summary`
3. **Experience** — `work`
4. **Volunteer** — `volunteer`
5. **Education** — `education`
6. **Awards** — `awards`
7. **Certificates** — `certificates`
8. **Publications** — `publications`
9. **Skills** — `skills`
10. **Languages** — `languages`
11. **Interests** — `interests`
12. **References** — `references`
13. **Projects** — `projects`

`$schema` and `meta` are data-only.

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
| `.rz-section--summary` · `--experience` · `--education` · `--skills` · `--projects` | Built-in section kinds. |
| `.rz-section--extra` | Plus `.rz-section--{id}` for JSON Resume sections that share the extras patterns: `--volunteer`, `--awards`, `--certificates`, `--publications`, `--languages`, `--interests`, `--references`. |
| `.rz-section-title` | Visible `h2` heading. |
| `id="rz-{id}"` | Fragment target (`#rz-experience`). |
| `data-rz-section="{id}"` | Stable machine id (see table below). |
| `data-rz-kind` | Extra-pattern sections: `entries` \| `list` \| `prose` \| `tags`. |

| `data-rz-section` | JSON Resume key | Kind | Heading |
| --- | --- | --- | --- |
| `summary` | `basics.summary` | prose | Summary |
| `experience` | `work` | entries (built-in) | Experience |
| `volunteer` | `volunteer` | entries | Volunteer |
| `education` | `education` | entries (built-in) | Education |
| `awards` | `awards` | entries | Awards |
| `certificates` | `certificates` | entries | Certificates |
| `publications` | `publications` | entries | Publications |
| `skills` | `skills` | skill groups | Skills |
| `languages` | `languages` | list | Languages |
| `interests` | `interests` | tags *or* entries | Interests |
| `references` | `references` | entries | References |
| `projects` | `projects` | entries (built-in) | Projects |

`interests`: if every item is name-only (no `keywords`), emit one `.rz-tags` list (`data-rz-kind="tags"`). If any item has `keywords`, emit entries (`data-rz-kind="entries"`) with `.rz-entry-primary` = `name` and `.rz-tags` = `keywords`.

---

## 5. Field map (JSON Resume → `rz-*`)

This is the renderer contract. Paths are JSON Resume. Slots are HTML classes.

### 5.1 `$schema`

| JSON Resume | HTML |
| --- | --- |
| `$schema` | Not rendered. Must be a URI that identifies resume-schema when present. |

### 5.2 `basics`

| JSON Resume | HTML |
| --- | --- |
| `basics.name` | `.rz-name` (`<h1>`, only one in the document) |
| `basics.label` | `.rz-title` (`<p>`, not a heading) |
| `basics.image` | `.rz-photo` / `.rz-photo-img` (`<img alt="Portrait of {name}">`). Omitted when missing or `""`. |
| `basics.email` | `.rz-contact.rz-contact--email` · value is `<a href="mailto:{email}">` |
| `basics.phone` | `.rz-contact.rz-contact--phone` · `<a href="tel:{digits}">` (href strips spaces / punctuation that is not `+`) |
| `basics.url` | `.rz-contact.rz-contact--url` · `<a href="{url}">` · visible text is the hostname |
| `basics.location` | `.rz-contact.rz-contact--location` · visible text = `[city, region].join(", ")`, falling back to `countryCode` if both city and region are empty |
| `basics.location.address` · `postalCode` | Stored, not rendered in v1 (header clutter / privacy) |
| `basics.summary` | `.rz-section--summary` · `.rz-prose.rz-summary` · split on blank lines (`\n\n`) into `<p>` |
| `basics.profiles[]` | `.rz-link` (see below) |

JSON Resume has **no** pronouns field. Do not emit a pronouns node.

```html
<header class="rz-header">
  <div class="rz-identity">
    <h1 class="rz-name" itemprop="name">Jordan Hale</h1>
    <p class="rz-title" itemprop="jobTitle">Design Engineer</p>
  </div>
  <address class="rz-contacts">…</address>
  <nav class="rz-links" aria-label="Profiles">…</nav>
</header>
```

| Class | Element | When |
| --- | --- | --- |
| `.rz-header` | `<header>` | always (if a name exists) |
| `.rz-identity` | `<div>` | always |
| `.rz-name` | `<h1>` | `basics.name` |
| `.rz-title` | `<p>` | `basics.label` |
| `.rz-photo` | `<figure>` | `basics.image` is a non-empty URL |
| `.rz-photo-img` | `<img>` | with photo |
| `.rz-contacts` | `<address>` | any of email / phone / url / location |
| `.rz-contact-list` | `<ul>` | with contacts |
| `.rz-contact` | `<li>` | plus `.rz-contact--{type}` |
| `.rz-contact-label` | `<span>` | `Email` / `Phone` / `Website` / `Location` |
| `.rz-contact-value` | `<a>` or `<span>` | `<a>` when an href exists |
| `.rz-links` | `<nav>` | any `basics.profiles` |
| `.rz-link-list` | `<ul>` | with profiles |
| `.rz-link` | `<li>` | plus `.rz-link--{type}` |
| `.rz-link-label` | `<span>` | `profiles[].network` |
| `.rz-link-value` | `<a>` | visible text = `username`, else hostname |

**Profile type.** Lowercase `network`, then map aliases: `twitter` and `x` → `x`; unknown → `other`. Known modifiers: `website` · `github` · `gitlab` · `linkedin` · `mastodon` · `bluesky` · `dribbble` · `behance` · `twitter` · `x` · `other`. `data-rz-type` keeps the mapped token.

Contact types: `email` · `phone` · `location` · `url` · `other`.

### 5.3 Shared dated-entry chrome

Used by `work`, `volunteer`, `education`, `projects`, and extras that are `entries`.

```html
<li class="rz-entry rz-entry--experience rz-is-current" data-rz-entry="acme-studio-2022">
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
  <div class="rz-prose"><p>…</p></div>
  <ul class="rz-bullets">
    <li class="rz-bullet">…</li>
  </ul>
</li>
```

When the primary has no URL, `.rz-entry-primary` is plain text (no `<a>`).

| Class / attr | Meaning |
| --- | --- |
| `.rz-entries` | `<ol>` of entries. Document order = JSON array order. |
| `.rz-entry` | One job, school, project, or extra entry. |
| `.rz-entry--experience` · `--education` · `--project` · `--extra` | Kind modifier. |
| `.rz-is-current` | `startDate` present and `endDate` omitted. Also `data-rz-current="true"`. |
| `data-rz-entry` | Renderer slug (JSON Resume has no ids): `slugify(primary + "-" + startYear)`. Collisions append `-2`, `-3`. |
| `.rz-entry-header` | Primary / secondary / dates / location cluster. |
| `.rz-entry-primary` | `h3` |
| `.rz-entry-primary-link` | Optional link wrapping the primary text. |
| `.rz-entry-secondary` | Role, degree + area, project description, awarder, issuer, publisher. |
| `.rz-dates` | Date range or single date. Omitted if no dates. |
| `.rz-date` | A date token. |
| `.rz-date--start` / `--end` | Start vs end (ranges). |
| `.rz-date--present` | End omitted → the word `Present` (`<span>`, not `<time>`). |
| `.rz-date-sep` | Separator (`–`). Decorative; `aria-hidden`. |
| `.rz-location` | `work[].location` (string). |
| `.rz-score` | `education[].score`. |
| `.rz-prose` | `summary` / `reference` / other long strings. |
| `.rz-bullets` / `.rz-bullet` | `highlights[]`. |
| `.rz-tags` / `.rz-tag` | `keywords[]`, `courses[]`, name-only interests. |
| `.rz-meta-list` / `.rz-meta` / `.rz-meta-label` / `.rz-meta-detail` | Languages; project `roles` / `entity` / `type`. |

**Dates.** JSON Resume `iso8601`: `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`. `datetime` is the raw value. Visible text is locale-formatted (`March 2022`, `2020`). A single date (awards, certificates, publications) uses one `.rz-date` and no separator.

**Present.** JSON Resume has no `current` boolean. Omit `endDate` to mean present.

### 5.4 `work[]` → experience

`.rz-section--experience` · `.rz-entry--experience`

| JSON Resume | HTML |
| --- | --- |
| `name` | `.rz-entry-primary` |
| `url` | `.rz-entry-primary-link` |
| `position` | `.rz-entry-secondary` |
| `startDate` / `endDate` | `.rz-dates` (omit `endDate` → Present) |
| `location` | `.rz-location` (string) |
| `summary` | `.rz-prose` inside the entry |
| `highlights[]` | `.rz-bullets` |
| `description` | Not rendered in v1 (company tagline; stored only) |

### 5.5 `volunteer[]`

`.rz-section--extra.rz-section--volunteer` · `data-rz-kind="entries"` · `.rz-entry--extra`

| JSON Resume | HTML |
| --- | --- |
| `organization` | `.rz-entry-primary` |
| `url` | `.rz-entry-primary-link` |
| `position` | `.rz-entry-secondary` |
| `startDate` / `endDate` | `.rz-dates` |
| `summary` | `.rz-prose` |
| `highlights[]` | `.rz-bullets` |

### 5.6 `education[]`

`.rz-section--education` · `.rz-entry--education`

| JSON Resume | HTML |
| --- | --- |
| `institution` | `.rz-entry-primary` |
| `url` | `.rz-entry-primary-link` |
| `studyType` + `area` | `.rz-entry-secondary` as `{studyType} in {area}` (whichever parts exist) |
| `startDate` / `endDate` | `.rz-dates` |
| `score` | `.rz-score` (prefixed `GPA ` only if the value looks numeric; otherwise emit as-is) |
| `courses[]` | `.rz-tags` / `.rz-tag` (**tags, not bullets** — courses are keywords) |

JSON Resume education has no `location` or `highlights`.

### 5.7 `awards[]`

`.rz-section--extra.rz-section--awards` · `data-rz-kind="entries"`

| JSON Resume | HTML |
| --- | --- |
| `title` | `.rz-entry-primary` (no URL in the schema) |
| `awarder` | `.rz-entry-secondary` |
| `date` | single `.rz-date` |
| `summary` | `.rz-prose` |

### 5.8 `certificates[]`

`.rz-section--extra.rz-section--certificates` · `data-rz-kind="entries"`

| JSON Resume | HTML |
| --- | --- |
| `name` | `.rz-entry-primary` |
| `url` | `.rz-entry-primary-link` |
| `issuer` | `.rz-entry-secondary` |
| `date` | single `.rz-date` |

### 5.9 `publications[]`

`.rz-section--extra.rz-section--publications` · `data-rz-kind="entries"`

| JSON Resume | HTML |
| --- | --- |
| `name` | `.rz-entry-primary` |
| `url` | `.rz-entry-primary-link` |
| `publisher` | `.rz-entry-secondary` |
| `releaseDate` | single `.rz-date` |
| `summary` | `.rz-prose` |

### 5.10 `skills[]`

`.rz-section--skills`

```html
<li class="rz-skill-group" data-rz-skill-group="engineering">
  <h3 class="rz-skill-group-name">Engineering</h3>
  <p class="rz-skill-level">Advanced</p>
  <ul class="rz-skill-list">
    <li class="rz-skill">Rust</li>
  </ul>
</li>
```

| JSON Resume | HTML |
| --- | --- |
| `name` | `.rz-skill-group-name` (omit the heading if empty) |
| `level` | `.rz-skill-level` (omit if empty) |
| `keywords[]` | `.rz-skill` items |
| `data-rz-skill-group` | `slugify(name)` |

### 5.11 `languages[]`

`.rz-section--extra.rz-section--languages` · `data-rz-kind="list"`

| JSON Resume | HTML |
| --- | --- |
| `language` | `.rz-meta-label` |
| `fluency` | `.rz-meta-detail` (omit if empty) |

### 5.12 `interests[]`

`.rz-section--extra.rz-section--interests`

| JSON Resume | HTML |
| --- | --- |
| name-only items | `.rz-tags` / `.rz-tag` (`data-rz-kind="tags"`) |
| `name` + `keywords[]` | extra entries: primary = `name`, tags = `keywords` (`data-rz-kind="entries"`) |

### 5.13 `references[]`

`.rz-section--extra.rz-section--references` · `data-rz-kind="entries"`

| JSON Resume | HTML |
| --- | --- |
| `name` | `.rz-entry-primary` |
| `reference` | `.rz-prose` |

### 5.14 `projects[]`

`.rz-section--projects` · `.rz-entry--project`

| JSON Resume | HTML |
| --- | --- |
| `name` | `.rz-entry-primary` |
| `url` | `.rz-entry-primary-link` |
| `description` | `.rz-entry-secondary` |
| `startDate` / `endDate` | `.rz-dates` |
| `highlights[]` | `.rz-bullets` |
| `keywords[]` | `.rz-tags` |
| `roles[]` | one `.rz-meta` labeled `Roles`, detail joined with `", "` |
| `entity` | `.rz-meta` labeled `Affiliation` |
| `type` | `.rz-meta` labeled `Type` |

### 5.15 `meta`

| JSON Resume | HTML |
| --- | --- |
| `meta.canonical` | Not rendered |
| `meta.version` | Not rendered |
| `meta.lastModified` | Not rendered |

`meta` may hold tooling keys (`additionalProperties`). The converter may write `meta.x-schema-resume` for lossless schema-resume round-trips. The renderer ignores it.

---

## 6. Class inventory (quick list)

Themes can treat this as the complete selector surface.

**Root:** `rz-resume`

**Header:** `rz-header` · `rz-identity` · `rz-name` · `rz-title` · `rz-photo` · `rz-photo-img` · `rz-contacts` · `rz-contact-list` · `rz-contact` · `rz-contact--{type}` · `rz-contact-label` · `rz-contact-value` · `rz-links` · `rz-link-list` · `rz-link` · `rz-link--{type}` · `rz-link-label` · `rz-link-value`

**Sections:** `rz-section` · `rz-section--summary` · `rz-section--experience` · `rz-section--education` · `rz-section--skills` · `rz-section--projects` · `rz-section--extra` · `rz-section--volunteer` · `rz-section--awards` · `rz-section--certificates` · `rz-section--publications` · `rz-section--languages` · `rz-section--interests` · `rz-section--references` · `rz-section-title`

**Prose:** `rz-prose` · `rz-summary`

**Entries:** `rz-entries` · `rz-entry` · `rz-entry--experience` · `rz-entry--education` · `rz-entry--project` · `rz-entry--extra` · `rz-is-current` · `rz-entry-header` · `rz-entry-primary` · `rz-entry-primary-link` · `rz-entry-secondary` · `rz-dates` · `rz-date` · `rz-date--start` · `rz-date--end` · `rz-date--present` · `rz-date-sep` · `rz-location` · `rz-score` · `rz-bullets` · `rz-bullet`

**Skills:** `rz-skill-groups` · `rz-skill-group` · `rz-skill-group-name` · `rz-skill-level` · `rz-skill-list` · `rz-skill`

**Tags / meta:** `rz-tags` · `rz-tag` · `rz-meta-list` · `rz-meta` · `rz-meta-label` · `rz-meta-detail`

**State / data:** `data-rz-schema` · `data-rz-section` · `data-rz-kind` · `data-rz-type` · `data-rz-entry` · `data-rz-skill-group` · `data-rz-current`

No other `rz-*` classes exist in HTML contract `1.0`. If you need a new one, bump `data-rz-schema` — do not invent it in a single theme.

---

## 7. JSON Resume shape (storage)

The renderer consumes a document that validates against [resume-schema](https://github.com/jsonresume/resume-schema/blob/master/schema.json). Official sample: [`sample.resume.json`](https://github.com/jsonresume/resume-schema/blob/master/sample.resume.json).

Top-level keys (all optional except that a usable résumé has `basics.name`):

```json
{
  "$schema": "https://raw.githubusercontent.com/jsonresume/resume-schema/master/schema.json",
  "basics": {
    "name": "",
    "label": "",
    "image": "",
    "email": "",
    "phone": "",
    "url": "",
    "summary": "",
    "location": {
      "address": "",
      "postalCode": "",
      "city": "",
      "countryCode": "",
      "region": ""
    },
    "profiles": [{ "network": "", "username": "", "url": "" }]
  },
  "work": [{
    "name": "", "location": "", "description": "", "position": "",
    "url": "", "startDate": "YYYY-MM", "endDate": "YYYY-MM",
    "summary": "", "highlights": [""]
  }],
  "volunteer": [{
    "organization": "", "position": "", "url": "",
    "startDate": "", "endDate": "", "summary": "", "highlights": [""]
  }],
  "education": [{
    "institution": "", "url": "", "area": "", "studyType": "",
    "startDate": "", "endDate": "", "score": "", "courses": [""]
  }],
  "awards": [{ "title": "", "date": "", "awarder": "", "summary": "" }],
  "certificates": [{ "name": "", "date": "", "url": "", "issuer": "" }],
  "publications": [{
    "name": "", "publisher": "", "releaseDate": "", "url": "", "summary": ""
  }],
  "skills": [{ "name": "", "level": "", "keywords": [""] }],
  "languages": [{ "language": "", "fluency": "" }],
  "interests": [{ "name": "", "keywords": [""] }],
  "references": [{ "name": "", "reference": "" }],
  "projects": [{
    "name": "", "description": "", "highlights": [""], "keywords": [""],
    "startDate": "", "endDate": "", "url": "",
    "roles": [""], "entity": "", "type": ""
  }],
  "meta": { "canonical": "", "version": "", "lastModified": "" }
}
```

See [`resume.json`](resume.json) for a complete, valid example. [`example.html`](example.html) is the HTML that example must compile to.

Wild JSON Resume files are valid input. Do not require ResumeZen-only keys.

---

## 8. ATS and accessibility checklist

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

## 9. Versioning

- Additive `rz-*` classes require an HTML contract bump (`data-rz-schema`) and a renderer release.
- Renames and removals are breaking. Don't.
- Theme **target** (`web` / `print` / `both`) lives in the CSS file header, not on the HTML. It does not bump `data-rz-schema`.
- JSON Resume is versioned upstream. We track `resume-schema`; we do not fork it.
- Bridge dialect changes (SchemaResume, UniversalResume) belong in [`../converter/`](../converter/), not here.
