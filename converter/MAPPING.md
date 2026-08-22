# JSON Resume ↔ schema-resume

- JSON Resume: [spec](https://jsonresume.org/schema), [schema](https://github.com/jsonresume/resume-schema)
- schema-resume: [site](https://schema-resume.org/), [repo](https://github.com/tradik/schema-resume), [schema](https://schema-resume.org/schema.json), [context](https://schema-resume.org/context.jsonld)

schema-resume is inspired by JSON Resume. Shared section names (`basics`, `work`, `education`, …) copy across. Extra JSON-LD envelope fields and schema-resume-only keys must not leak into HTML, and must survive a round-trip where possible.

---

## Envelope

| schema-resume | Import (→ JSON Resume) | Export (→ schema-resume) |
| --- | --- | --- |
| `@context` | Strip from the stored document. Remember the inbound value on `meta.x-schema-resume.context` if it is not the default. | Set `@context` to `https://schema-resume.org/context.jsonld` |
| `$schema` | Rewrite to the JSON Resume schema URI (see fixture). Remember inbound on `meta.x-schema-resume.schema`. | Set `$schema` to `https://schema-resume.org/schema.json` |
| `@type` | Not a JSON Resume key. Move to `meta.x-schema-resume.type`. | Restore `@type` (`DigitalDocument` if unset). |
| `additionalType` | Move to `meta.x-schema-resume.additionalType`. | Restore if present. |

Do not store `@context` on the canonical JSON Resume document even though resume-schema `additionalProperties` would allow it. Stored files should look like JSON Resume from the wild.

---

## Shared fields (copy through)

These names and shapes match closely enough to copy:

- `basics.name` · `label` · `image` · `email` · `phone` · `url` · `summary`
- `basics.location` **when it is already** `{ address, postalCode, city, countryCode, region }`
- `basics.profiles[]` (`network`, `username`, `url`)
- `work[]`: `name`, `position`, `url`, `startDate`, `endDate`, `summary`, `highlights`, `description`
- `volunteer[]`: `organization`, `position`, `url`, `startDate`, `endDate`, `summary`, `highlights`
- `education[]`: `institution`, `url`, `area`, `studyType`, `startDate`, `endDate`, `score`, `courses`
- `awards[]`, `certificates[]`, `publications[]`
- `skills[]` (`name`, `level`, `keywords`)
- `languages[]`, `interests[]`, `references[]`, `projects[]`
- `meta.canonical` · `version` · `lastModified`

`endDate` omitted means present on both sides.

---

## Aliases (schema-resume → JSON Resume)

Apply only when the JSON Resume field is missing:

| schema-resume | JSON Resume |
| --- | --- |
| `basics.title` | `basics.label` |
| `basics.location.streetAddress` | `basics.location.address` |
| `work[].workLocation` (string) | `work[].location` (string) |
| `education[].school` | `education[].institution` |
| `education[].degree` | `education[].studyType` |
| `education[].gpa` | `education[].score` |

Keep the original key as well (pass-through `additionalProperties`) so export can put it back.

---

## Type conflict: `work[].location`

| Spec | Type |
| --- | --- |
| JSON Resume | **string** (`"Portland, OR"`) |
| schema-resume | **object** (`{ city, region, countryCode, … }`) plus legacy `workLocation` string |

**Import.**

1. If `workLocation` is a non-empty string, that becomes JSON Resume `location` (this is usually the human workplace line: `"Remote"`, `"Portland, OR"`).
2. Else if `location` is already a string, keep it.
3. Else if `location` is an object, flatten to `[city, region].join(", ")`, else `countryCode`, else `""`.
4. If inbound `location` is an object, store it on `meta.x-schema-resume.work[i].location` so export can restore the structured address.

The fixture pair uses both: schema-resume has a Portland address object plus `workLocation: "Remote"`; JSON Resume stores `"Remote"` and parks the object on `meta.x-schema-resume`.

**Export.** If `meta.x-schema-resume.work[i].location` exists, emit that object. Otherwise emit a string `location` (schema-resume `additionalProperties` / `workLocation` can carry it) or a one-field object `{ "address": "{string}" }` — prefer restoring the stored object.

The fixture pair demonstrates this: schema-resume uses a location object; JSON Resume uses `"Remote"`.

---

## schema-resume-only fields (pass-through)

JSON Resume allows `additionalProperties` on objects and at the root. **Prefer leaving extra keys in place** on the stored document so export is a wrap + envelope restore.

When a key would break JSON Resume validation or collide with a different type, park it on `meta.x-schema-resume` instead.

Known extras (not rendered to `rz-*` HTML):

| Path | Notes |
| --- | --- |
| `basics.age` · `dateOfBirth` · `gender` · `legalNote` | Pass-through on `basics` |
| `basics.keyAchievements` · `coreCompetencies` | Pass-through arrays |
| `basics.nationalities` · `workAuthorization` | Pass-through arrays |
| `work[].industry` · `workType` · `contactDetails` · `positions` · `@type` | Pass-through on the work item |
| `tools[]` | Top-level array; pass-through at root |
| Per-item `@type` | Pass-through; used by JSON-LD |

The renderer **ignores** every key not listed in [`../skeleton/CLASS-CONTRACT.md`](../skeleton/CLASS-CONTRACT.md) §5.

---

## `meta.x-schema-resume`

Documented extension object on the stored JSON Resume file:

```json
{
  "meta": {
    "x-schema-resume": {
      "context": "https://schema-resume.org/context.jsonld",
      "schema": "https://schema-resume.org/schema.json",
      "type": "DigitalDocument",
      "additionalType": null,
      "work": {
        "0": { "location": { "city": "Portland", "region": "OR", "countryCode": "US" } }
      }
    }
  }
}
```

Rules:

- Only store keys we cannot keep at the JSON Resume path.
- Do not put résumé content here that exists as a standard JSON Resume field.
- Export reads this object, then deletes it from the outbound `meta` (it is not a schema-resume property).

---

## Export target

Outbound document **must** include:

```json
{
  "@context": "https://schema-resume.org/context.jsonld",
  "$schema": "https://schema-resume.org/schema.json"
}
```

That `@context` URL is the documented JSON-LD context ([`context.jsonld`](https://schema-resume.org/context.jsonld)). Do not inline the context unless a caller asks for a standalone file.

Optional: `@type` as stored or `DigitalDocument`.

XML export is not in v1.

---

## Losslessness

Best effort, not a guarantee:

- Shared fields: lossless.
- Pass-through extras: lossless if they remain `additionalProperties` on the stored JSON Resume.
- Type conflicts (`work.location` object): lossless via `meta.x-schema-resume`.
- Unknown future schema-resume keys: keep in place when valid JSON Resume; otherwise park under `meta.x-schema-resume.unknown`.
- HTML rendering is lossy by design (see class contract §5 — e.g. `work.description` is stored, not shown).

---

## Implementation notes (later)

- Validate inbound JSON Resume with resume-schema before store.
- Validate inbound schema-resume with `https://schema-resume.org/schema.json` before import.
- Do not implement conversion inside the Elm chrome or the HTML renderer.
- Fixture pair in `fixtures/` is the first test the Rust crate should lock.
