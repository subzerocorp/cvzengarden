# AVRIL round 1 — Generator revise pass (cycle 6, after Visionary CTO cycle 2)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-23 · **Board:** Pinto `ZG` (labels `avril`, `round-1`)
**Scope:** ZG-19 and ZG-21 — the two CTO cycle-2 REJECTs. ZG-11, ZG-12 and ZG-20 (QA cycle-5 REJECTs) are a separate revise and are not touched here. ZG-13 and ZG-17 carry three fresh BLESS marks and are not touched. ZG-22 was read (it consumes ZG-21's delete and error-body semantics) and needs no edit.
**Inputs read in full:** `docs/plans/round-1-avril-cto-round2.md` (both REJECT sections and their exact sentences), `docs/plans/round-1-avril-qa-round5.md` (the three non-blocking ZG-21 folds the CTO said may ride this revise), `docs/plans/round-1-avril-intent.md`, `pinto show ZG-19 ZG-21 ZG-22 --plain` / `--json`, `skeleton/CLASS-CONTRACT.md` §9 (lines 570–576: the "Additive" bullet, the "Renames and removals" bullet, and the theme-target bullet that already contains the words "does not bump"), `skeleton/example.html` line 21 (`data-rz-schema="1.0"`).

Only the CTO-cited blockers and the three QA folds were applied. Every heading, every other AC, the labels and the dependencies are unchanged. Nothing is BLESSed by this document; both items return to the full PO → QA → CTO chain.

## Cycle 6 — ZG-19

**CTO blocker (cycle 2):** the round's designated contract editor left §9 saying "Additive `rz-*` classes require an HTML contract bump … Renames and removals are breaking", which contradicts the no-bump changes ZG-2 (`<span class="rz-date">`) and ZG-3 (`dir="auto"`, `<span class="rz-link-value">`) already ship under contract 1.0. The meaning of `data-rz-schema` — the only version a Designer sees — was a planning-doc opinion, not a contract rule.

**Change 1 — the blocker (Scope in).** Added one `Scope in` bullet carrying the CTO's sentence verbatim:

> §9 gains the compatibility rule: "A change that adds no class and no `data-rz-*` attribute — a new attribute outside `data-rz-*` (for example `dir`), or a different element type carrying an existing class (for example `<span class="rz-date">` for an unparseable date, as `.rz-date--present` already is) — is documented in §5 and does not bump `data-rz-schema`. A new class or `data-rz-*` attribute is a minor bump (1.0 → 1.1). A rename or removal is a major bump and is not done."

followed by the replacement instruction: the one rule replaces the two existing §9 bullets it subsumes ("Additive `rz-*` classes require an HTML contract bump …" and "Renames and removals are breaking. Don't."), so §9 states the rule once; the §9 bullets on theme target, `resume-schema` and bridge dialects are untouched; `data-rz-schema` stays `1.0`. The CTO named only the "Additive" line; the "Renames and removals" bullet is replaced too because the new sentence's last clause restates it, and keeping both would leave §9 with two wordings of one rule — which is the very condition the CTO's "one rule, not two" forbids.

**Change 2 — the blocker (one bounded grep AC).** Added one AC, bounded to §9 by `sed -n '/^## 9\./,$p'` (`## 9.` to end of file, as the CTO asked):

- `documented in §5 and does not bump` → count `1` in §9. The CTO's suggested token was `does not bump`, but §9's theme-target bullet already contains "It does not bump `data-rz-schema`" (line 574) and stays, so a bare `does not bump` grep would count 2 on a correct edit; the longer fragment is unique to the new rule.
- `minor bump (1.0 → 1.1)` → count `1` in §9; `major bump and is not done` → count `1` in §9.
- `sed -n '1,/^## 9\./p' … | grep -c -E "minor bump|major bump"` → `0` (the rule lives only in §9; verified absent today).
- `grep -c "Additive .rz-\*. classes require" skeleton/CLASS-CONTRACT.md` → `0` and `grep -c "Renames and removals are breaking" …` → `0` (replaced, not kept beside the new rule; both are `1` today).
- `grep -n 'data-rz-schema="1.0"' skeleton/example.html` still hits (no version change — consistent with `Scope out`'s "Changing any `rz-*` class or the HTML contract version").

QA owns the final wording per the CTO; every token above is a verified-real change against today's files.

**Not changed:** `## Why`, `## Covers`, all other `Scope in` bullets, `## Scope out`, all other ACs verbatim, `## Dependencies` (ZG-14, ZG-16, ZG-17), `## Notes`, labels (`avril`, `round-1`, `designer`, `docs`), dependents (ZG-20 — the §9 paragraph does not change what ZG-20 lints). Verified with `pinto show ZG-19 --json` and a line diff against the pre-edit body: exactly two lines added, none removed or altered.

## Cycle 6 — ZG-21

**CTO blocker (cycle 2):** `Scope in` said both "`DELETE` removes the row" and "after DELETE, `GET /r/{id}` is 410 forever", on a schema with no column for a delete state. A removed row cannot answer 410; the cheapest invention (soft-delete flag with `resume_json` kept) would make ZG-22's "kept until you delete it" copy false and cannot be corrected after deployment.

**Change 1 — the blocker (Scope in, delete sentence).** Removed "`DELETE` removes the row;" from the PUT/DELETE/GET bullet and appended the CTO's sentence verbatim in its place:

> `DELETE` erases the résumé and keeps a tombstone: it sets `resume_json` and `edit_key_hash` to NULL and `deleted_at` to now (the table gains a nullable `deleted_at`), leaving the `id` row in place so `GET /r/{id}` answers 410 forever and an id is never reissued; a direct SQL read of the row after DELETE finds no résumé bytes and no key hash.

`grep -c 'removes the row'` on the new body prints `0`.

**Change 2 — the blocker (schema).** The Store bullet's table is now `resumes(id TEXT PK, edit_key_hash TEXT, theme_id TEXT, resume_json TEXT, created_at, updated_at, deleted_at NULL)` with the note that `deleted_at` is nullable and NULL until DELETE, and `edit_key_hash` / `resume_json` are NULL only on a tombstone.

**Change 3 — the blocker (`delete_then_gone` reads the row by SQL).** The AC now reads: DELETE with key → 204; a direct SQL read of the row by id after the 204 finds the row still present with `resume_json IS NULL`, `edit_key_hash IS NULL` and `deleted_at IS NOT NULL` (tombstone: no résumé bytes, no key hash, id reserved); `GET /r/{id}` → 410 with text `taken down`; DELETE again → 404; `GET /api/resumes/{id}` with the old key → 404 (the export path on a tombstone is stated, since the key hash it would compare against is gone). `edit_key_not_stored_plain` is unaffected.

**Change 4 — QA fold (unmatched `/api/` routes and 405 shape).** The error-body bullet's code list gains `method-not-allowed` and states that the router's fallbacks are included: an unmatched path under `/api/` is 404 `not-found` and a wrong method on a matched `/api/` route is 405 `method-not-allowed`, both in the same JSON shape (never Axum's empty `text/plain` default). `error_body_shape` gains `GET /api/nope` (404 `not-found`) and `PATCH /api/resumes/{id}` (405 `method-not-allowed`), and its allowed-code list gains `method-not-allowed`. QA offered "or say 405 is exempt"; a seventh code was chosen because the scope already promised "every non-2xx under `/api/`" and ZG-22's client falls back to `error` — an exemption would have been the first hole in that promise.

**Change 5 — QA fold (`theme` absent).** Validation bullet: "`theme` absent or not a catalog id → 422 `unknown-theme` (the message names `theme`)". `rejects_bad_input` gains: body with `resume` but no `theme` key → 422 `unknown-theme` mentioning `theme`.

**Change 6 — QA fold (413 by bytes received).** Validation bullet: the 1 MiB limit applies to the bytes actually received (the decoded body), not to `Content-Length`, so a chunked request or one without a `Content-Length` cannot bypass it. `rejects_bad_input` gains: the 1 MiB + 1 byte body sent with `Transfer-Encoding: chunked` and no `Content-Length` → 413 `too-large`.

**ZG-22 check (no edit).** Its `delete` probe (410 + `taken down`) is satisfied by the tombstone; its trust copy "Kept until you delete it" and its privacy panel's "what the server stores: the JSON, the theme, timestamps" are now structurally true — after DELETE the JSON and the key hash are gone; what remains on the tombstone is the id, `theme_id` and timestamps, none of which is the user's résumé. Its `api-errors` stub shapes (413, 422 `{"error":"name"}`, 500) are unchanged by the seventh code. `pinto show ZG-22 --json` `updated` is unchanged (`2026-08-23T18:13:24-07:00`).

**Not changed:** `## Why`, `## Covers`, all other `Scope in` bullets (no new endpoint, no CORS, no stored HTML), `## Scope out`, all other ACs verbatim, `## Dependencies` (ZG-2, ZG-3), `## Notes`, labels (`avril`, `round-1`, `backend`), dependents (ZG-22). Verified with `pinto show ZG-21 --json` and a line diff against the pre-edit body: seven lines altered (Store, PUT/DELETE/GET, Validation, Error body, `delete_then_gone`, `rejects_bad_input`, `error_body_shape` — the last three are AC lines), none added or removed.

## Changed ids

- ZG-19
- ZG-21

Both need a fresh PO → QA → CTO chain. ZG-22, ZG-13, ZG-17 and every other item are untouched.
