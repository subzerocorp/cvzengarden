# Detect / import / export

Chrome paste accepts three JSON dialects. **Only JSON Resume is stored.** SchemaResume and UniversalResume are Bridge dialects: detect → import → store a Resume. Export is opt-in and strict per target.

Do not run UniversalResume's [html-renderer](https://github.com/universal-resume/html-renderer) or [pdf-generator](https://github.com/universal-resume/pdf-generator). Our Renderer emits `rz-*`. Themes are our CSS.

```
paste JSON
    │
    ├─ detect dialect
    │
    ├─ JSON Resume ──────────────► store as-is (validate resume-schema)
    ├─ SchemaResume ─ import ───► store JSON Resume
    └─ UniversalResume ─ import ► store JSON Resume
                 │
                 ▼
            Renderer (rz-*)
```

---

## Detection (first match wins)

Inspect the parsed object. Do not guess from the filename.

| Order | Signal | Dialect |
| --- | --- | --- |
| 1 | `$schema` or `@context` (string or array) contains `schema-resume.org` | **SchemaResume** |
| 2 | `$schema` or `meta.schema` contains `universal-resume` | **UniversalResume** |
| 3 | `$schema` contains `jsonresume` or `resume-schema` | **JSON Resume** |
| 4 | Has `employments` **and** does not have `work` | **UniversalResume** |
| 5 | Has `initiatives` **and** does not have `volunteer` / `projects` as JSON Resume arrays of the usual shape | **UniversalResume** |
| 6 | `basics.contact` is an **object**, or `basics.headline` is set and `basics.label` is absent | **UniversalResume** |
| 7 | Has `@context` or `@type` (JSON-LD envelope) | **SchemaResume** |
| 8 | Has `work` or `basics.label` or `basics.email` as a string | **JSON Resume** |
| 9 | Validate in order: resume-schema → schema-resume → universal-resume | First schema that validates |

Notes:

- SchemaResume is a JSON Resume–shaped superset. A SchemaResume file that lost its `@context` still stores cleanly as JSON Resume (extras pass through).
- UniversalResume sets `additionalProperties: false`. A valid UR document **cannot** also have `work`, `volunteer`, `projects`, or a root `$schema`. Prefer `meta.schema` on UR files.
- If `employments` **and** `work` both exist, treat as **JSON Resume** (additionalProperties junk) unless a schema URI already decided.

Chrome should show the detected dialect before import (“This looks like UniversalResume — we will store JSON Resume”). The Author can override.

---

## Import

| Dialect | Action |
| --- | --- |
| JSON Resume | Validate. Store. |
| SchemaResume | [`MAPPING.md`](MAPPING.md) → JSON Resume. Park envelope / type conflicts on `meta.x-schema-resume`. |
| UniversalResume | [`UNIVERSAL-RESUME.md`](UNIVERSAL-RESUME.md) → JSON Resume. Park unrepresentable fields on `meta.x-universal-resume`. |

After import, the stored document must validate against [resume-schema](https://github.com/jsonresume/resume-schema). The Renderer reads only the JSON Resume field map in [`../skeleton/CLASS-CONTRACT.md`](../skeleton/CLASS-CONTRACT.md).

---

## Export

| Target | Rules |
| --- | --- |
| JSON Resume | The stored document (strip `meta.x-schema-resume` / `meta.x-universal-resume` only if the caller wants a “plain” file). |
| SchemaResume | JSON-LD envelope. See [`MAPPING.md`](MAPPING.md). |
| UniversalResume | **Strict.** `additionalProperties: false` on every object. No root `$schema`, no `work`, no leftover keys. See [`UNIVERSAL-RESUME.md`](UNIVERSAL-RESUME.md). |

Export to UniversalResume is lossy when the Resume has data that has no UR slot (e.g. top-level `references[]` with no employment to hang them on, `meta.version`, schema-resume `tools[]`). Document the drop. Do not emit invalid UR JSON to “keep” extras.

---

## Implementation notes (later)

- Detection and conversion live in the converter crate, not Elm and not the HTML renderer.
- Chrome calls detect → import, then hands JSON Resume to the Renderer.
- Lock the fixture pairs in `fixtures/` as the first tests. Do not implement that crate in this PR.
