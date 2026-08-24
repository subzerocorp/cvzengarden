# JSON Resume ↔ UniversalResume

- JSON Resume: [spec](https://jsonresume.org/schema), [schema](https://github.com/jsonresume/resume-schema)
- UniversalResume: [org](https://github.com/universal-resume), [json-schema](https://github.com/universal-resume/json-schema), [schema.json](https://raw.githubusercontent.com/universal-resume/json-schema/main/schema.json)
- Also exists (do **not** adopt): [ts-schema](https://github.com/universal-resume/ts-schema), [html-renderer](https://github.com/universal-resume/html-renderer), [pdf-generator](https://github.com/universal-resume/pdf-generator), [json-examples](https://github.com/universal-resume/json-examples)

UniversalResume is a **Bridge** dialect, same class as SchemaResume. Import into a Resume. Export a Resume out to UniversalResume. Never the stored form. Detection: [`DETECT.md`](DETECT.md).

Their HTML/PDF tools are not our Renderer or Themes. We emit `rz-*` from JSON Resume.

**Export is strict.** The schema sets `additionalProperties: false` on the document and on every nested object. Outbound UR JSON must validate as-is. No leftover keys, no root `$schema`, no `work`.

---

## Top-level rename

| UniversalResume | JSON Resume | Notes |
| --- | --- | --- |
| `basics` | `basics` | Different inner keys (below) |
| `employments[]` | `work[]` | Nested `organization`; `type` enum |
| `education[]` | `education[]` | `organization` / `type` / object `courses` |
| `initiatives[]` | `volunteer[]` and/or `projects[]` | Split on `initiatives[].type` |
| `awards[]` | `awards[]` | `issuer` is an Organization |
| `certificates[]` | `certificates[]` | `issuer` is an Organization |
| `publications[]` | `publications[]` | `publisher` is an Organization; `date` not `releaseDate` |
| `skills[]` | `skills[]` | `tags` not `keywords` |
| `languages[]` | `languages[]` | `name` not `language`; fluency enum |
| `interests[]` | `interests[]` | `tags` not `keywords` |
| *(none)* | `references[]` | UR nests references on employments / initiatives |
| *(none)* | `volunteer[]` | Only via `initiatives` of type `volunteering` |
| *(none)* | `projects[]` | Only via other `initiatives` |
| `meta` | `meta` | UR allows only `canonical`, `lastModified`, `schema` |

Location is **always an object** in UniversalResume (`address`, `city`, `countryCode`, `postalCode`, `region`). JSON Resume uses that object on `basics.location` and a **string** on `work[].location`.

---

## `basics`

| UniversalResume | JSON Resume |
| --- | --- |
| `name` | `name` |
| `headline` | `label` |
| `picture` | `image` |
| `website` | `url` |
| `summary` | `summary` |
| `location` (object) | `location` (object) — copy the five known fields only |
| `contact.email` | `email` |
| `contact.phone` | `phone` |
| `contact.linkedin` | a `profiles[]` row: `network` = `LinkedIn`, `url` = the value (skip if a LinkedIn profile already exists) |
| `profiles[]` | `profiles[]` — `network` / `username` / `url` |
| `availability` | park `meta.x-universal-resume.basics.availability` |
| `birth` | park `…basics.birth` |
| `remote` | park `…basics.remote` |
| `nationalities` | park `…basics.nationalities` (UR: country-code strings) |
| `drivingLicenses` | park `…basics.drivingLicenses` |

**Profiles `network` enum** (UR): `LinkedIn`, `Github`, `X`, `Instagram`, `Youtube`, `Twitch`, `Reddit`, `Tiktok`.

On import, keep the UR spelling (`Github`). The Skeleton maps `github` / `Github` the same. On export, map `GitHub` → `Github`, `Twitter` → `X`, `YouTube` → `Youtube`; drop networks that are not in the enum (or put the URL on `basics.website` / a generic profile if you must keep a link — prefer drop + document).

`headline` max length is 50. On export, truncate `basics.label` with an ellipsis if needed.

---

## `employments[]` → `work[]`

| UniversalResume | JSON Resume |
| --- | --- |
| `organization.name` | `name` |
| `url` | `url` |
| `position` | `position` |
| `startDate` / `endDate` | `startDate` / `endDate` (omit end → present) |
| `summary` | `summary` |
| `highlights[]` | `highlights[]` |
| `organization.description` | `description` |
| `organization.location` (object) | flatten to `work[].location` **string** if the employment-level `location` is absent: `[city, region].join(", ")` |
| `location` (object, workplace) | prefer this for the JR string (`"Remote"` from `{ "city": "Remote" }`) |
| `type` | park `meta.x-universal-resume.employments[i].type` (`internal` \| `freelance` \| `agency` \| `contract` \| `apprenticeship` \| `internship`) |
| `tags[]` | park `…employments[i].tags` |
| `organization` (full object) | park `…employments[i].organization` so export can restore |
| `references[]` | flatten into JSON Resume `references[]` (`name` + `testimonial` → `reference`); park the rest on `…employments[i].references` |

**Export.** Default `type` to `internal` if unknown. `location` and `organization.location` must be objects. A JR string `"Remote"` becomes `{ "city": "Remote" }`. `"Portland, OR"` becomes `{ "city": "Portland", "region": "OR" }` when it matches `City, REGION`; otherwise `{ "address": "{string}" }`.

---

## `education[]`

| UniversalResume | JSON Resume |
| --- | --- |
| `organization.name` | `institution` |
| `url` | `url` |
| `area` | `area` |
| `type` | `studyType` |
| `startDate` / `endDate` | `startDate` / `endDate` |
| `score` | `score` |
| `courses[].name` | `courses[]` **strings** (JR has no course objects) |
| `courses[].summary` / `format` | park `meta.x-universal-resume.education[i].courses` |
| `organization` (full) | park `…education[i].organization` |
| `location` (object) | park `…education[i].location` (JR education has no location) |

---

## `initiatives[]` → volunteer / projects

Split on `type`:

| `initiatives[].type` | JSON Resume |
| --- | --- |
| `volunteering` | `volunteer[]` |
| `personal` · `open-source` · `startup` · `civic` · `research` · `education` | `projects[]` |

### → `volunteer[]` (`volunteering`)

| UniversalResume | JSON Resume |
| --- | --- |
| `organization.name` or, if missing, `name` | `organization` |
| `position` | `position` |
| `url` | `url` |
| `startDate` / `endDate` | `startDate` / `endDate` |
| `summary` | `summary` |
| `highlights[]` | `highlights[]` |
| everything else (`tags`, nested `references`, `status`, `location`, initiative `name` when org exists) | park `meta.x-universal-resume.initiatives[i]` |

### → `projects[]` (all other types)

| UniversalResume | JSON Resume |
| --- | --- |
| `name` | `name` |
| `url` | `url` |
| `summary` | `description` |
| `highlights[]` | `highlights[]` |
| `tags[]` | `keywords[]` |
| `startDate` / `endDate` | `startDate` / `endDate` |
| `position` · `organization` · `type` · `status` · `location` · nested `references` | park `…initiatives[i]` |

**Export.** Each `volunteer[]` row becomes an initiative with `type: "volunteering"` (required UR fields: `summary`, `name`, `position`, `startDate`, `type` — use organization name as `name` if needed, `summary` from JR `summary` or first highlight). Each `projects[]` row becomes an initiative; restore parked `type` or default `personal`.

---

## Awards, certificates, publications

| UniversalResume | JSON Resume |
| --- | --- |
| `awards[].title` | `title` |
| `awards[].date` | `date` |
| `awards[].summary` | `summary` |
| `awards[].issuer.name` | `awarder` |
| `certificates[].name` / `date` / `url` | same |
| `certificates[].issuer.name` | `issuer` (string) |
| `publications[].name` / `url` / `summary` | same |
| `publications[].date` | `releaseDate` |
| `publications[].publisher.name` | `publisher` (string) |

Park full Organization objects, plus UR-only `tags`, `location`, `authors`, `doi`, `publications[].type` (enum: `article`, `blog-post`, `book`, …).

---

## Skills, languages, interests

| UniversalResume | JSON Resume |
| --- | --- |
| `skills[].name` | `name` |
| `skills[].level` | `level` (UR enum: `beginner` \| `intermediate` \| `advanced` \| `expert`) |
| `skills[].tags` | `keywords` |
| `skills[].yearsOfExperience` | park |
| `languages[].name` | `language` |
| `languages[].fluency` | `fluency` (keep the enum string) |
| `languages[].certifications` · `countryCode` | park |
| `interests[].name` | `name` |
| `interests[].tags` | `keywords` |
| `interests[].summary` | park |

**Export fluency** (JR free text → UR enum):

| JSON Resume (lowercase contains) | UniversalResume |
| --- | --- |
| `native`, `bilingual` | `bilingual` or `fluent` (`native` / `native speaker` → `fluent`) |
| `fluent`, `full` | `fluent` / `full-professional` |
| `professional` | `professional-working` |
| `conversational`, `limited` | `limited-working` |
| `elementary`, `basic`, `beginner` | `elementary` |
| unknown | omit `fluency` (not required) |

**Export skill level:** lowercase; map `master` → `expert`; unknown → omit.

---

## `meta`

| UniversalResume | JSON Resume |
| --- | --- |
| `canonical` | `canonical` |
| `lastModified` | `lastModified` — UR `Day` (`YYYY` / `YYYY-MM` / `YYYY-MM-DD`); JR often has a datetime. Import: keep JR datetime if already one; export: truncate to a `Day`. |
| `schema` | not `$schema` — UR root forbids extra keys, so the schema URI lives here: `https://raw.githubusercontent.com/universal-resume/json-schema/main/schema.json` |
| *(forbidden)* | `version` — drop on UR export |
| *(forbidden)* | `x-schema-resume` / `x-universal-resume` — never emit on UR `meta` |

---

## `meta.x-universal-resume`

Parked on the **stored JSON Resume** only:

```json
{
  "meta": {
    "x-universal-resume": {
      "schema": "https://raw.githubusercontent.com/universal-resume/json-schema/main/schema.json",
      "basics": { "remote": true, "availability": "ASAP" },
      "employments": {
        "0": {
          "type": "internal",
          "organization": { "name": "Acme Studio", "location": { "city": "Portland", "region": "OR", "countryCode": "US" } },
          "tags": ["CSS"]
        }
      },
      "education": { "0": { "courses": [{ "name": "Studio: Letterpress", "format": "In-person" }] } },
      "initiatives": { "0": { "type": "volunteering" }, "1": { "type": "open-source" } }
    }
  }
}
```

Rules match SchemaResume's extension object: only what cannot live at a JSON Resume path; export reads it then deletes it; the Renderer ignores it.

---

## Export checklist (strict)

A valid UniversalResume file has:

- `basics.name` and `basics.headline`
- No properties other than the documented top-level keys
- No root `$schema`, `@context`, `work`, `volunteer`, `projects`, `references`
- Every `location` an object
- Every `issuer` / `publisher` / employment `organization` an Organization `{ name, location?, description? }`
- `courses[]` as objects with `name`
- `skills[].tags` not `keywords`
- `languages[].name` not `language`
- Profile `network` in the enum
- Fluency / skill level / employment `type` / initiative `type` / publication `type` in their enums when present

If a Resume cannot satisfy a **required** UR field (`education[].type`, `initiatives[].summary`, …), skip that entry rather than emit an invalid document.

---

## Fixture pair

| File | Dialect |
| --- | --- |
| [`fixtures/universal-resume.json`](fixtures/universal-resume.json) | UniversalResume (strict) |
| [`fixtures/jsonresume-universal.json`](fixtures/jsonresume-universal.json) | Same person as stored JSON Resume |

The SchemaResume pair (`jsonresume.json` ↔ `schema-resume.json`) is unchanged.
