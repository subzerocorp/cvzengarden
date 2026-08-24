# AVRIL round 1 — QA Architect review (cycle 6b)

**Role:** `qa-architect-agent` (second adversary) · **Date:** 2026-08-24 · **Cycle:** 6b (fresh review of the two Visionary CTO cycle-2 REJECTs after the Generator's cycle-6 revise and the PO's cycle-6b BLESS)
**Scope:** ZG-19 and ZG-21 only. My cycle-5 BLESS on each lapsed with the body edit; both are judged from scratch — the new material is run against its stated rule by hand, and the rest of the body is re-read to confirm no existing AC was broken by it. ZG-22 was read because it consumes ZG-21's delete and error-body semantics; it receives no verdict. ZG-11, ZG-12 and ZG-20 are a separate revise and are not touched.
**Inputs read in full:** `docs/plans/round-1-avril-qa-round5.md` (my prior verdicts and the three ZG-21 folds I offered), `round-1-avril-cto-round2.md` (the two exact sentences), `round-1-avril-generator-round6.md` (the claimed changes), `round-1-avril-po-round6b.md`, the three current bodies (`pinto show ZG-19 ZG-21 ZG-22 --plain`), `skeleton/CLASS-CONTRACT.md` §8–§9 (lines 556–576; the file is 576 lines and §9 is the last section), `skeleton/example.html` line 21, and the git history of the tracked board files (`git show 11ae2ec -- .pinto/tasks/ZG-19.md .pinto/tasks/ZG-21.md .pinto/tasks/ZG-22.md`).

Mandate: *BLESS only PBIs whose acceptance criteria are complete, falsifiable, and hostile to happy-path theater; otherwise REJECT with the missing cases.*

I judge testability only. I do not author bodies, touch the board, or reopen product scope. Cycle-1 conventions stand unchanged.

## Facts I verified before judging

| Fact | How | Affects |
| --- | --- | --- |
| `## 9. Versioning` is line 570, the only `^## 9\.` heading, and the last section (file is 576 lines). §9 today has five bullets: "Additive `rz-*` classes require an HTML contract bump (`data-rz-schema`) and a renderer release.", "Renames and removals are breaking. Don't.", the theme-target bullet ("It does not bump `data-rz-schema`."), `resume-schema`, bridge dialects. | `grep -n '^## '`, `awk` over §8–§9 | ZG-19 §9 AC bounds and replacement targets |
| Today's counts for every token in the §9 AC: `documented in §5 and does not bump` in §9 → **0**; bare `does not bump` in §9 → **1** (the theme-target bullet, which stays); `minor bump\|major bump` before §9 → **0** and anywhere in the file → **0**; `Additive .rz-\*. classes require` → **1**; `Renames and removals are breaking` → **1**; `data-rz-schema="1.0"` in `example.html` → line 21. | the AC's own commands, run verbatim | every §9 grep is a real change; the "only in §9" negative holds today; the Generator's longer token was necessary (a bare `does not bump` would count 2 on a correct edit) |
| BRE semantics of the AC patterns: in `grep -c "minor bump (1.0 → 1.1)"` the parentheses are literals and `.` is a wildcard (matches `1.0`); in `"Additive .rz-\*. classes require"` `\*` is a literal asterisk and the two `.` match the backticks. Both match the CTO's sentence / today's line as written. | run by hand | ZG-19 AC is executable as written, no `-E` needed |
| The new §9 sentence contains none of the other ZG-19 grep tokens (`never only in`, `any https origin`, `JavaScript loaders forbidden`, `dark ink on white`, `unless you mean to`), and §9 lies outside the `## 6.`–`## 7.` window the node test reads. | read | no existing ZG-19 AC changes count because of the §9 edit |
| Board history: commit `11ae2ec` ("generator revise 6, PO cycle 6") changed `.pinto/tasks/ZG-19.md` by +2 content lines (one `Scope in` bullet, one AC) and `.pinto/tasks/ZG-21.md` by 7 altered lines (Store, PUT/DELETE/GET, Validation, Error body, `delete_then_gone`, `rejects_bad_input`, `error_body_shape`) with no line added or removed; `.pinto/tasks/ZG-22.md` untouched; working tree clean against HEAD. | `git show --stat`, `git diff HEAD` | the Generator's "nothing else moved" claims are true; my cycle-5 reading of every untouched AC carries |
| ZG-22's `delete` probe asserts 410 + body containing `taken down`; its `api-errors` stub shapes are 413, 422 `{"error":"name"}`, 500; it `updated` at `18:13:24-07:00`, before the revise. | `pinto show ZG-22` | ZG-21's tombstone and seventh code need no ZG-22 edit |

---

## ZG-19 — Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look

### CTO cycle-2 blocker, checked against the current body

| CTO blocker | Current body | Resolved |
| --- | --- | --- |
| §9 still said "Additive `rz-*` classes require an HTML contract bump …", contradicting ZG-2 / ZG-3's no-bump changes; the compatibility rule lived only in a planning doc | `Scope in` carries the CTO's sentence verbatim and says it replaces the two §9 bullets it subsumes (the "Additive" line the CTO named and the "Renames and removals" line whose content the new last clause restates), leaving the theme-target / `resume-schema` / bridge bullets and `data-rz-schema="1.0"` alone; one AC bounded by `sed -n '/^## 9\./,$p'` | yes |

### The new AC, run against its rule by hand

The AC is six counts and one hit. I ran each against today's file (table above) and against the CTO's sentence:

1. `documented in §5 and does not bump` in §9 → today 0, after a correct edit 1. The token is a substring of the sentence's first clause ("is documented in §5 and does not bump `data-rz-schema`"). Had the Generator used the CTO's suggested bare `does not bump`, a correct edit would count **2** (the theme-target bullet already says "It does not bump `data-rz-schema`") and the AC would fail on success — the Generator caught that and I confirm the longer token is unique.
2. `minor bump (1.0 → 1.1)` → today 0, after 1; substring of "is a minor bump (1.0 → 1.1)". Parentheses are literal in BRE.
3. `major bump and is not done` → today 0, after 1; substring of "is a major bump and is not done".
4. `minor bump|major bump` before `## 9.` → 0 today and after (the `1,/^## 9\./p` range includes the heading line, which contains neither). This is the negative that stops the rule being copied into §1/§2 later and drifting — the same one-wording discipline the item already applies to the `content:` rule.
5. `Additive .rz-\*. classes require` → today **1**, after 0. Real change; a stub that appends the new rule and keeps the old line fails here.
6. `Renames and removals are breaking` → today **1**, after 0. Real change; the new sentence does not contain that phrase, so the count cannot be satisfied by anything except removal.
7. `data-rz-schema="1.0"` in `example.html` → hits (line 21) and must still hit: pins `Scope out`'s "no contract-version change".

Falsifiability: a stub that skips the edit fails 1–3 and 5–6; a stub that appends without replacing fails 5–6; a stub that "fixes" the contradiction by bumping the version fails 7; a stub that moves the heading or renames §9 makes the `sed` range empty and fails 1–3. The only way to pass all seven is the edit the scope describes. A grep AC for prose can only pin tokens, and these three pin the three operative clauses (no-bump condition, minor bump, major bump) — the same standard every other doc AC on this item was blessed under.

### Did the new material break an existing AC?

No. I re-ran every other ZG-19 grep against `CLASS-CONTRACT.md` and `themes/README.md` today and checked the new sentence for each token: none appears in it. The node test's §6 window (`## 6.`–`## 7.`) is unaffected by a §9 edit. `Scope out` ("Changing any `rz-*` class or the HTML contract version") is consistent with AC 7. ZG-20 (dependent) lints CSS, not the contract. The three cycle-5 non-blocking notes (`blank-readable` must inject a `<link>` into ZG-14's served `example.html`; `acceptance.rs` shared with ZG-6; `photo-loads` viewport) stand as non-blocking guidance and are not changed by this revise.

Non-blocking (fold in without re-review): the AC does not pin the two worked examples in the sentence (`dir`, `<span class="rz-date">`). They are what makes the rule legible to a Designer, and `Scope in` quotes them verbatim, so an implementer has no reason to drop them; if the conductor wants belt-and-braces, `grep -c 'for example `dir`'` in §9 → 1 is one more token.

**BLESS ZG-19 — the §9 AC is seven commands I ran by hand against today's contract: three positive counts that are 0 today and become 1 only with the CTO's sentence (the Generator correctly avoided a bare `does not bump`, which would count 2 on a correct edit), two removal counts that are 1 today and must become 0, a "lives only in §9" negative that holds today, and a version pin; none of the existing greps, the §6-bounded node test, or the fixture locks is touched by a §9 edit (verified: the revise commit added exactly two lines).**

## ZG-21 — Publish a résumé to a stable public URL with an unguessable edit link (API)

### CTO cycle-2 blocker and my three cycle-5 folds, checked against the current body

| Blocker / fold | Current body | Resolved |
| --- | --- | --- |
| CTO: "`DELETE` removes the row" vs "410 forever" on a schema with no delete column | "removes the row" is gone (`grep -c` → 0 on the body); the CTO's tombstone-and-erase sentence is in `Scope in` verbatim; the table is `resumes(…, deleted_at NULL)` with "nullable and NULL until DELETE; `edit_key_hash` and `resume_json` are NULL only on a tombstone"; `delete_then_gone` reads the row by SQL after the 204 and asserts row present, `resume_json IS NULL`, `edit_key_hash IS NULL`, `deleted_at IS NOT NULL`, then 410 `taken down`, second DELETE 404, export with old key 404 | yes |
| QA fold: unmatched `/api/` paths and wrong methods answered by Axum's empty `text/plain` fallbacks | Seventh code `method-not-allowed`; scope says the router's fallbacks are included (unmatched path → 404 `not-found`, wrong method on a matched route → 405 `method-not-allowed`, same JSON shape, "never Axum's empty `text/plain` default"); `error_body_shape` gains `GET /api/nope` and `PATCH /api/resumes/{id}` and its allowed-code list gains the seventh code | yes |
| QA fold: `theme` absent had no pinned code | Validation bullet: "`theme` absent or not a catalog id → 422 `unknown-theme` (the message names `theme`)"; `rejects_bad_input` gains the case | yes |
| QA fold: 413 by `Content-Length` could be bypassed | Validation bullet: limit applies to bytes actually received, not `Content-Length`; `rejects_bad_input` gains the 1 MiB + 1 body sent `Transfer-Encoding: chunked` with no `Content-Length` → 413 | yes |

### The new material, run against its rules by hand

**Tombstone.** The SQL read is the assertion that distinguishes the three implementations the CTO worried about: hard delete (row absent → FAIL on "row still present"), soft-delete flag with bytes kept (`resume_json` non-NULL → FAIL), and the specified erase (PASS). Every downstream observable in the same test follows from the tombstone by construction: `GET /r/{id}` 410 (row present, `deleted_at` set), second DELETE 404 and export with the old key 404 (the hash it would compare against is NULL, so no key can ever match — 404, existence not revealed, consistent with `put_and_delete_require_key`'s "PUT on a deleted id with the old key → 404"). `public_page_headers_and_purity`'s "after DELETE the 410 carries the same two headers" is unchanged and still satisfiable. `edit_key_not_stored_plain` reads a live row and is unaffected. ZG-22's `delete` probe (410 + `taken down`) is satisfied without edit.

**405 / 404 fallback shape.** `PATCH /api/resumes/{id}` hits a matched path with an unregistered method, so Axum answers 405 before any handler runs (store call count stays 0, consistent with `malformed_ids_are_404`). Axum's default 405 and its unmatched-path 404 are empty `text/plain`; `error_body_shape` demands `application/json`, exactly `{error, message}`, a listed code, and a non-empty clean `message` — so the default fails on content type alone, and a stub that JSON-wraps only handler errors fails on both new cases. `no_cors`'s `OPTIONS /api/resumes` (no OPTIONS handler → 405 by the same fallback) remains consistent: the AC there checks only the absence of `Access-Control-Allow-*`, which a JSON 405 satisfies.

**`theme` absent.** Run in the stated order: ≤ 1 MiB → valid JSON → theme check. Absent is "not a catalog id", so `unknown-theme` before the shape check; the example in `rejects_bad_input` ("body with `resume` but no `theme` key") therefore reaches the theme check regardless of what `resume` contains. Rule and example agree.

**413 by bytes received.** Sending 1 MiB + 1 with `Transfer-Encoding: chunked` and no `Content-Length` is the one request that separates "limit on the header" (would read the body and answer 201/400/422 — FAIL) from "limit on the stream" (413 — PASS). The existing pair (1 MiB + 1 → 413, exactly 1 MiB → 201) still pins the boundary from both sides. Axum's `DefaultBodyLimit` counts received bytes, so the AC is satisfiable; its default rejection is `text/plain`, which `error_body_shape` already fails as intended.

### Did the new material break an existing AC?

No. The revise commit altered seven lines and added or removed none; I re-read each altered line against its unaltered neighbours. Codes: the six-code list in cycle 5 is now seven everywhere it appears (scope, `error_body_shape`, README AC "code list"); no AC still names "six". Status matrix after DELETE is consistent across `delete_then_gone`, `put_and_delete_require_key` and `public_page_headers_and_purity` (API paths 404, `/r/` 410). The Store bullet's "`resume_json` is stored verbatim" and `unknown_keys_round_trip` are unchanged. Dependencies (ZG-2, ZG-3) and ZG-22's stubs are unchanged and compatible.

Non-blocking (fold in without re-review; none changes an outcome):

- **`:memory:` and the SQL read.** `delete_then_gone` and `edit_key_not_stored_plain` read the row "by SQL". With libSQL `:memory:` a fresh connection may see its own empty database; the read must go through the same connection / `Database` the store uses (or the test store wrapper exposes it). If a tester gets this wrong the read finds no row and the AC **fails** — it cannot pass by accident — so this is executability, not falsifiability. Say "through the store's connection" once.
- **"An id is never reissued."** The scope makes this promise; the ACs make it structurally true (PK + row kept) but no test exercises an insert onto an existing id. A plain `INSERT` errors on the PK and the CTO's AXEL guidance retries the draw; an `INSERT OR REPLACE` would silently overwrite a tombstone and no AC would notice (a random collision is 2⁻⁵⁰ per draw, so a black-box test cannot provoke it). One store-level unit case — inserting a row whose id already exists (live or tombstone) is refused and leaves the existing row unchanged — makes the sentence falsifiable for the cost of one test. Recommended, not required: the AXEL architect judges the store insert under guidance 13 and 15, and the observable promise to an Author (`/r/{id}` never shows another person's page) is already covered by the tombstone read.
- **`OPTIONS` in `no_cors`.** With the seventh code, `OPTIONS /api/resumes` will be a JSON 405; the AC only asserts header absence. Fine as written; a tester should not read the 405 as a defect.

**BLESS ZG-21 — the tombstone is now the one delete semantic and `delete_then_gone`'s SQL read is the assertion that fails a hard delete (row absent) and a soft-delete flag (bytes kept) alike, with every downstream 404/410 in the body following from it consistently; the three folds each add one request that the naive implementation answers wrongly (Axum's `text/plain` 405/404, `theme` absent falling into the shape check, a chunked body slipping past a `Content-Length` check); nothing else moved (verified by the revise diff) and ZG-22's probes and stubs are satisfied without edit.**

---

## Summary

| id | PO c6b | QA c5 | QA c6b | one-line reason |
| --- | --- | --- | --- | --- |
| ZG-19 | BLESS | BLESS (lapsed) | **BLESS** | §9 AC run by hand against today's file: three positives 0→1 with a token that is unique (bare `does not bump` would count 2), two removals 1→0, "only in §9" negative holds today, version pin; two lines added, no existing AC touched |
| ZG-21 | BLESS | BLESS (lapsed) | **BLESS** | tombstone SQL read fails both hard delete and soft-delete-with-bytes; 405/404 fallback, `theme`-absent and chunked-413 cases each fail the naive implementation; seven altered lines, none added/removed; ZG-22 unchanged and compatible |

2 BLESS, 0 REJECT. Both proceed to the Visionary CTO for a fresh cycle-3 mark.

## Set-level notes for the Generator (non-blocking)

- **Grep tokens must be unique on the finished file, not just absent today.** ZG-19's §9 AC is the model: the Generator checked that the suggested token already occurred once in the target section and lengthened it. Do this for every count-based grep AC in the ZG-11/12/20 revise.
- **"By SQL" reads in `:memory:` tests go through the store's connection.** Applies to both ZG-21 SQL-read ACs; one clause in scope would save the execution team a false FAIL.
- **Promises in scope should have one test each.** "Never reissued" is the only sentence in ZG-21's scope without a matching assertion; a store-level insert-on-existing-id case closes it.
