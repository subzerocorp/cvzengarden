# ZG-1 GAN report

## Phase 1 — Reviewer

Mandate: "Make every piece of Rust code so clear, layered, and correct that any experienced developer can understand and safely modify it in under 10 minutes."

### Gates run (all from `renderer/`)

| Gate | Result |
| --- | --- |
| `cargo fmt --all -- --check` | exit 0 |
| `cargo clippy --all-targets -- -D warnings -D clippy::pedantic` (after `touch src/lib.rs`) | exit 0, no diagnostics |
| `cargo test` | 10 + 9 + 0 passed, 0 failed |
| `grep -rn "allow(clippy" src tests` | no matches |
| `git diff --stat skeleton/` | empty |
| `cargo test -- --list` name set, HEAD vs working tree (HEAD built from `git archive` in /tmp) | identical, 19 names |

### Lint-to-edit traceability

Baseline pedantic run on HEAD (`git archive HEAD renderer` → /tmp) reports exactly 11 lib findings: `map().unwrap_or(false)` emit.rs:981, `map().unwrap_or_else` emit.rs:214, `missing_errors_doc` lib.rs:37 + resume.rs:41, `ref_option` emit.rs:900, `doc_markdown` lib.rs:1, `needless_lifetimes` html.rs:12, `needless_pass_by_value` emit.rs:624, `must_use_candidate` lib.rs:19 + :32, `wildcard_imports` emit.rs:5. Because the lib failed, clippy never reached `tests/acceptance.rs` at HEAD. Overlaying the fixed `src/` onto HEAD's `tests/` surfaces 3 more: `needless_lifetimes` acceptance.rs:262, `match_same_arms` :273, `format_push_string` :317. Every hunk in the diff maps to one of these 14 findings; there is no edit without a lint behind it. Scope honoured.

### Correctness of each rewrite

- `nonempty(&Option<String>) -> Option<&str>` → `nonempty(Option<&str>) -> Option<&str>` (emit.rs:905). Old body was `value.as_deref().map(str::trim).filter(..)`; new body is `value.map(str::trim).filter(..)` with `.as_deref()` hoisted to every caller. Identical semantics; elided output lifetime binds to the single input. Sweep audited call-by-call (≈90 sites incl. all `*_has_content` predicates): every site is a mechanical `&x.f` → `x.f.as_deref()`; none dropped, none re-ordered.
- `emit_entry(.., bits: &EntryBits<'_>, ..)` (emit.rs:626). Body unchanged and already borrow-shaped (`bits.secondary.as_deref()`, `bits.score.as_deref()`, `for .. in &bits.meta`, Copy `Option<&str>` fields). No `.clone()` introduced. All 9 call sites pass `&bits`. Correct.
- `map_or_else(|| hostname(&href), str::to_string)` (emit.rs:217–218) ≡ old `.map(str::to_string).unwrap_or_else(|| hostname(&href))`. Same value, same laziness.
- `has_any` → `items.is_some_and(..)` (emit.rs:987) ≡ `.map(..).unwrap_or(false)`. `None` → `false` preserved.
- `flag(key: &str) -> Attr<'_>` (html.rs:12): pure elision, same signature.
- `#[must_use]` on `version`/`render`, `# Errors` sections on `render_json`/`Resume::from_json`: docs only.
- Wildcard import replaced with the 15 named `resume` types (emit.rs:5–8): all are used; nothing else from `resume` is referenced.

### Test-file oracle strength

- `Node::Comment(_) => {}` folded into `_ => {}` (acceptance.rs:274): both arms were no-ops; `significant()` returns the same child set, so the tree-equality lock against `skeleton/example.html` is exactly as strict as before. The replacing comment documents which node kinds are intentionally ignored — an improvement.
- `writeln!(out, ..).expect("String fmt::Write")` (acceptance.rs:319): `fmt::Write for String` is infallible; the `// fmt::Write into a String is infallible.` comment satisfies the "expect only for documented invariants" rule. Test-only code. Output bytes identical.

### Findings

| Loc | Severity | Note |
| --- | --- | --- |
| renderer/src/resume.rs:44 | nit (non-blocking) | "a type the JSON Resume schema does not allow" — serde rejects what the *Rust struct* does not allow (unknown fields are ignored, not rejected). Wording only; lib.rs:41 phrasing ("a field of the wrong type") is accurate and could be reused. Fix at next touch of this file. |
| renderer/tests/acceptance.rs:319 | nit (non-blocking) | `.expect("String fmt::Write")` reads as a label, not a reason. `"writing to a String cannot fail"` would be self-explaining. Comment above already covers it. |
| .pinto/tasks/ZG-1.md | process note | Shows up in `git diff --name-only -- . ':!progress.md' ':!features.json'`; it is `pinto start` board state (status/start_at), not code. Conductor: commit it separately or record it as the harness exception under the last AC. |

No violations of the Ruthless Review Checklist introduced by this diff: no nesting added, no `#[allow]`, no `anyhow`, no new dependencies, no `dbg!`/`println!`, no commented-out code, all public items documented, ≤5 params everywhere touched.

### Pre-existing, out of scope (follow-ups, not blockers)

- renderer/src/emit.rs:212 `.expect("filtered")`, :480 `.unwrap()`, :533 `.unwrap()` — filter-then-unwrap on `nonempty(..)`. The diff neither introduced nor worsened them. Follow-up: `filter_map` into `(item, name)` pairs (or `(&Profile, &str)`) so the second lookup and the panic path disappear. Clippy pedantic does not flag these; `clippy::unwrap_used`/`expect_used` are restriction lints.
- Call-site noise: `nonempty(x.f.as_deref())` is now the crate-wide idiom. Idiomatic and minimal for `ref_option`; no action.
- `progress.md` / `features.json` not yet updated — DoD item for the conductor at commit time, not a code finding.

BLESS ZG-1 phase-1 — all 14 pedantic findings (11 lib + 3 test) fixed at source with byte-identical HTML, identical 19-test oracle, no `#[allow]`, and every rewrite verified semantics-preserving; only wording nits remain.

## Phase 1 — Tester

Mandate: "Ensure every calculation and public item has complete, layered, deterministic tests following Arrange-Act-Assert with exhaustive error-path coverage so the codebase stays reliably maintainable, verifiable, and handover-clean — zero tolerance, delegate all fixes."

### Gates run (from `renderer/` unless noted)

| Gate | Result |
| --- | --- |
| `cargo fmt --all -- --check` | exit 0 |
| `touch src/lib.rs && cargo clippy --all-targets -- -D warnings -D clippy::pedantic` | exit 0, no diagnostics |
| `cargo test` | 10 + 9 + 0 passed, 0 failed |
| `cargo test -- --list \| grep -c ': test$'` | 19 (AC floor is 19) |
| Name set vs HEAD (`git archive HEAD renderer skeleton` → /tmp, `cargo test -- --list`, `diff`) | empty diff, 19 = 19 |
| `grep -rn "allow(clippy" src tests` | no matches |
| `git diff --stat -- skeleton/` | empty |
| `PROBE_PORT=4310 just verify` (run alone) | exit 0; 61 PASS, 0 FAIL |
| `git diff --name-only -- . ':!progress.md' ':!features.json'` | 5 paths under `renderer/` + `.pinto/tasks/ZG-1.md` (board state, see Reviewer) |

### AC → falsifying command

| AC | Falsifier | Evidence |
| --- | --- | --- |
| clippy pedantic exit 0 | the clippy line above; HEAD fails it with 11 lib findings | exit 0 |
| `just verify` exit 0 | `PROBE_PORT=4310 just verify` | exit 0 when run alone (caveat below) |
| no `allow(clippy` | grep above | exit 1 (no match) |
| 0 failed, no test removed, ≥ 19, skeleton unchanged | `cargo test`; `--list` name diff against a HEAD build; `git diff --stat skeleton/` | 0 failed; identical names; 19; empty |
| only `renderer/` paths | `git diff --name-only` above | renderer/ only, plus `.pinto` board state |

### `just verify` caveat (harness, not renderer)

The first three `just test-frontend` runs failed exactly one probe, `S1 cold load FOUC: 1 unstyled committed frame(s)`, every time; each run overlapped with concurrent `cargo test` builds in /tmp. Run alone it passes (two clean runs, then the full `just verify` above). `frontend/`, `themes/`, `skeleton/` are byte-identical to HEAD (`git status --porcelain` empty) and nothing under `frontend/` imports the renderer, so this cannot be caused by the diff. The sampler is 36 frames at 20 ms on a cold page (`frontend/scripts/probes.mjs:620-631`); under CPU load the first committed frame is unstyled. Load-sensitive, not renderer-related — recorded as a follow-up for the harness, not a ZG-1 blocker. Conductor: run `just verify` with nothing else compiling when recording AC-2 evidence.

### Tree-equality oracle after the `match_same_arms` fold (acceptance.rs:274)

`scraper::Node` is `Document | Fragment | Doctype | Comment | Text | Element | ProcessingInstruction`. Before: `Text` (non-blank) → pushed, `Element` → pushed, `Comment` → dropped, `_` → dropped. After: `Text`/`Element` identical, everything else → dropped. The ignored set is the same five variants; `significant()` returns the same `Vec<Kid>` for every input, so `nodes_eq` compares exactly the same nodes as at HEAD. Not weakened.

### Oracle strength — mutation runs on a /tmp copy of the working tree (repo untouched)

| Mutant | Result |
| --- | --- |
| `emit_links`: username fallback replaced by `hostname(&href)` (the `map_or_else` rewrite site) | KILLED by `fixture_rz_resume_tree_matches_example` |
| `emit_entry`: `bits.secondary.as_deref()` → `None` (the `&EntryBits` borrow site) | KILLED by `fixture_rz_resume_tree_matches_example` |
| `emit_entry`: `for .. in &bits.meta` → empty slice | KILLED by `fixture_rz_resume_tree_matches_example` |
| `nonempty`: drop `str::trim` | SURVIVED — fixture has no whitespace-padded values (pre-existing gap; trim existed at HEAD) |
| `has_any`: `is_some_and` → `is_none_or` | SURVIVED — no test has an entry with all-empty scalars and a missing list (pre-existing gap; `is_some_and` ≡ old `.map().unwrap_or(false)`) |

The oracle is text- and structure-sensitive at the rewritten sites; the diff created no new branch. The two survivors are HEAD-era holes, not introduced by this PBI.

### `.expect("String fmt::Write")` (acceptance.rs:319)

`impl fmt::Write for String` is `write_str = push_str; Ok(())`. `write_fmt` can only return `Err` if a `Display`/`Debug` impl among the arguments returns `Err`; the arguments are `pad: String` (`Display`) and `t: String` (`Debug`), both of which only forward to `write_str`. Infallible; the comment above the line documents the invariant. Test-only code. Acceptable.

### Error-path tests

`grep -n 'is_err\|unwrap_err' tests src` is empty at HEAD and in the working tree: there has never been an invalid-JSON or empty-input test. `empty_string_stub_would_fail_ada_and_fixture` asserts on a constant-`""` *output* stub, not on `""` *input*. The diff removed nothing, but it added `# Errors` sections to `render_json` and `Resume::from_json`, which now document a contract no test locks. Not a branch this diff created, so not a ZG-1 blocker; it is the first follow-up below.

### Checklist

- Every name printed at HEAD is printed now: yes (19/19, diff empty).
- 0 failed in every binary: yes.
- Pedantic clippy + fmt clean: yes.
- No production code in test modules, no `dbg!`/`println!`, no commented-out tests: yes.
- New untested branch created by the diff: none (all rewrites are semantic identities, three of them mutation-verified).

```
TEST VERDICT: PASSED

All four AC gates have a falsifying command and pass; the 19-name test set is identical to a HEAD build; the tree-equality oracle compares the same node set as before and kills mutants at every rewritten site. No new branch was introduced, so no new test is owed. Two HEAD-era coverage holes and one load-sensitive frontend probe are recorded as follow-ups, not blockers.

Missing tests (pre-existing, follow-up):
- render_json / Resume::from_json lack any Err-path test (`""`, `"{"`, `{"basics":[]}` → is_err)
- nonempty lacks a trim test (`"  x  "` → Some("x"), `"   "` → None)
- has_any(None) → false untested
```

BLESS ZG-1 phase-1 — every AC has a falsifying command and passes, the 19 test names are byte-identical to a HEAD build, the tree oracle is unweakened and mutation-verified at all rewritten sites, and the diff introduces no untested branch; remaining gaps predate this PBI.

## Phase 1 — Architect

Mandate: "Guard the entire Rust system architecture with Torvalds-level ruthlessness; reject every piece of garbage that would degrade stratification or coherence; bless nothing until the design is pristine and future-proof."

### Gates re-run (from `renderer/`, `touch src/lib.rs` first)

| Gate | Result |
| --- | --- |
| `cargo clippy --all-targets -- -D warnings -D clippy::pedantic` | exit 0, no diagnostics |
| `cargo test` | 10 + 9 + 0 passed, 0 failed |
| `grep -nE 'std::(fs\|env\|io\|net\|time\|process\|thread)\|SystemTime\|Instant\|println!\|dbg!\|unsafe\|#\[allow' src/*.rs` | no matches |

### System shape after the diff

Strata, bottom to top, with the only `use crate::` edges that exist:

1. **Data** — `resume.rs` (serde structs + one parse calc). Depends on `serde` only.
2. **Primitive calcs** — `date.rs`, `slug.rs`. Depend on `std` only. No crate edges.
3. **Builder** — `html.rs`. `std` only. Mutation is confined to a `String` buffer that `finish()` hands back; from the outside it is `() → String`.
4. **Emit** — `emit.rs`. Imports `date`, `html`, `resume`, `slug`, `CONTRACT_VERSION`. Single `pub fn render(&Resume) -> String`.
5. **Façade** — `lib.rs`. Re-exports the data types, exposes `version`, `CONTRACT_VERSION`, `render`, `render_json`.

The graph is a DAG, every edge points downward except the trivial `emit → crate::CONTRACT_VERSION` constant. There is no I/O, no clock, no env read, no `unsafe`, no platform crate anywhere in `src/`. `env!` is compile-time. The crate is still `Resume → String` and nothing else. That is exactly what an Axum handler (`render_json(&str) -> Result<String, _>`) and a `wasm-bindgen` export both need; nothing in this diff adds a dependency or a signature that either target would have to work around.

### Did the lint fixes improve or blur boundaries?

- **Explicit import list (emit.rs:5–8).** Improvement. The `emit → resume` edge is now enumerated: 15 named types, and the absence of `Meta` in that list makes it visible that the emitter ignores `meta`, which is what the `render` doc already promised. A wildcard hid that contract; the list states it.
- **`nonempty(Option<&str>) -> Option<&str>` (emit.rs:905).** Improvement. The helper no longer knows the storage type of the data layer (`Option<String>`); it is a calc over a borrowed string. The ~90 `.as_deref()` calls are the ownership seam between data and calc made explicit at each call site. The alternative — an extension trait or method on the `resume` types — would push presentation logic down into the data stratum, which is the wrong direction. Noise accepted; the layering is cleaner.
- **`emit_entry(.., &EntryBits<'_>, ..)` (emit.rs:626).** Improvement. `EntryBits` is the per-entry view-model each section emitter builds; the consumer now reads it and cannot consume it. Immutable-data-by-default at the one internal boundary that has a value object.
- **`map_or_else`, `is_some_and`, `flag(&str) -> Attr<'_>`, `#[must_use]`, `# Errors`.** Local; no structural effect. The `# Errors` sections and `#[must_use]` tighten the public contract the two future consumers will read.
- **Test file.** The `_ => {}` fold with a comment naming the ignored node kinds and the `writeln!` with a documented infallibility invariant are test-only and leave the oracle strength unchanged (Tester verified).

Accidental complexity introduced: none. No new type, module, trait, dependency, or feature flag. The diff is fourteen lint-driven identities and every one of them either leaves the strata untouched or makes an existing boundary more explicit.

### Checklist

- Preserves or strengthens layered design: yes (two boundaries made more explicit, none blurred).
- Call graph obvious, zero entanglement: yes (5 modules, one DAG, one public entry point).
- Actions at edges, calcs pure, data immutable: yes (no actions exist in the crate; the diff added a borrow, not a mutation).
- Maintainable and obvious to a new senior dev in 2 years: yes; the crate reads top-down from `lib.rs` in one sitting.
- Compliant with `code-writer` + `rust-code-writer`: yes for everything the diff touched; no `#[allow]`, no `anyhow`, no nesting added.
- Review stayed system-level: yes.

### Pre-existing, out of scope (follow-ups for ZG-4 / ZG-21 planning, not blockers)

- **Public error type is `serde_json::Error`.** The façade leaks a third-party type across the crate boundary. When ZG-4 puts an Axum handler in front of `render_json`, the backend will want a crate-level `thiserror` enum it can `From`/`IntoResponse` without depending on `serde_json` itself. The diff documented this contract; it did not create it.
- **`emit.rs` is three strata in one 1040-line file**: section orchestrators, the `EntryBits` view-model + `emit_entry`, and the `nonempty` / `*_has_content` presence calcs. The diff did not widen it. Splitting the presence calcs out is the obvious next cut when a behaviour PBI (ZG-2/ZG-3) has to touch them anyway.
- **`emit → crate::CONTRACT_VERSION`** is the only upward edge. Trivial; note it so nobody adds a second.
- The three filter-then-unwrap sites (emit.rs:212, :480, :533) are already logged by the Reviewer.

```
ARCHITECTURE VERDICT: BLESSED

The crate remains a strict Resume → String calculation layer with a five-module DAG (data → primitive calcs → builder → emit → façade), no actions, no platform surface, and nothing hostile to an Axum or Wasm consumer. The diff introduces zero new structure and makes two existing boundaries more explicit (the enumerated emit→resume import edge and the storage-agnostic nonempty seam). The remaining debt — a leaked serde_json error type at the façade and an oversized emit.rs — predates this PBI and is the right shape for the next planning round, not this one.
```

BLESS ZG-1 phase-1 — the crate is still a pure Resume → String DAG with no actions or platform surface; the lint fixes add no structure and sharpen two boundaries (explicit emit→resume imports, storage-agnostic `nonempty`); nothing here obstructs the Axum (ZG-4) or Wasm (ZG-21) consumers, and all remaining debt is pre-existing and logged.
