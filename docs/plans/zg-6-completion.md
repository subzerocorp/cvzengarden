# PBI Completion — ZG-6

## Title
Explain the résumé format in plain words and start from a sample

## Phases
- phase-1 product: BLESS reviewer | tester | architect — `7859ba0` (Sample Intent, embedded bytes, junior lock, vendored schema); `5790337` (Ajv `strict: false` so draft-07 compiles)
- Reviewer REJECT `765a4aa` (`test:unit` unquoted glob dropped the suite to 16) → restore `fa35ea8` (`find` walk, 147) → Reviewer BLESS `8db67f3`
- Tester BLESS `56893b3` — 147 unit, all `ZG-6/*` PASS, junior lock ok, U3 Jordan 2/2/2

## Architecture
Sample is a third `Paste.Intent`. `keep Sample` emits Swap only and does not write `accepted`. `keep Author` still Stores. One key: `resumezen.resume`. JSON Resume remains the only stored Resume. Sample bytes are `Generated.Samples` from `generate.mjs`; a click issues no skeleton/ fetch. ZG-14 still owns `skeleton/samples/*` → `dist/` (`copy-dist.mjs` only gained `clipboard.js`). Chrome classes stay `paste__` / `btn` / `app-*`; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`. Scope stayed ZG-6.

## AC Evidence
On the PBI (`## Execution Evidence`). Tester log: `docs/plans/zg-6-tester.md`. Generator: `docs/plans/zg-6-execution.md`.

## Verification matrix
- fmt / clippy pedantic / cargo test (renderer + renderer-wasm): PASS (Tester)
- `npm run test:unit`: 147 / 0 (18 `*.test.mjs` via `find`)
- Isolated + full `ZG-6/*` probes: PASS
- U3 Jordan print: 2/2/2
- Pre-existing `ZG-11/page-count quarto` 4-vs-3: carved out; theme print CSS and `U3_PRINT_PAGES` untouched

## Board
- status: done (`pinto` CLI absent in this VM; `.pinto/tasks/ZG-6.md` written done with `done_at` + commits)

## QA
- Product walk: PASS on draft host `https://6a90bc39674c4e34c89c8c34--cvzengarden.netlify.app`
- Production was not walked and was not published

## Follow-ups / non-goals honored
- U3 print CSS / `U3_PRINT_PAGES` / HTTPS / DNS / TLS / issue #9 untouched
- No ZG-8 copy-link, no ZG-10 page estimate, no ZG-14 kit publish, no auth/payments/PDF/domains
- `skeleton/resume.json` and `skeleton/example.html` untouched
- PR #22 left open; not merged
