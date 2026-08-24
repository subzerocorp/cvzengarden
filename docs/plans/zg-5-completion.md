# PBI Completion — ZG-5
## Title
Paste or open your own JSON Resume and see it in every Theme
## Phases
- phase-1: BLESS reviewer | tester | architect — `32ef15b` (paste panel, classify, humane errors, Wasm swap)
- phase-2: BLESS reviewer | tester | architect — `e33212f` (file/drop, localStorage, Forget)
## AC Evidence
On the PBI (`pinto show ZG-5`). Tester logs: `/tmp/zg5-p2-probes-4430.log`, `/tmp/zg5-p2-verify-4431.log`.
## Verification matrix
- fmt / clippy pedantic / cargo test / node:test 147 / probes (incl. all `ZG-5/*`): PASS (`PROBE_PORT=4431 just verify` exit 0)
## Board
- status: done
## Follow-ups / non-goals honored
- ZG-6 sample buttons: new `Intent`, not `ShowIt` (ShowIt writes storage).
- ZG-22 publishes `accepted` (raw JSON), not the textarea buffer.
- FileOpened does not copy bytes into `#paste-input` (open-json AC); line/column of a bad file vs the box is a follow-up.
- No format essay, no sample buttons, no publish (ZG-6 / ZG-21 / ZG-22).
