# PBI Completion — ZG-3
## Title
Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs
## Phases
- phase-1: BLESS reviewer | tester | architect — commit `84d2a91`
## AC Evidence
On the PBI (`pinto show ZG-3`): 28 wild tests, sweeps over 19 fixtures, locks regenerated for dir="auto"; just verify exit 0.
## Verification matrix
- fmt / clippy pedantic / cargo test 27+9+2+28 / node:test 106 / probes 90: PASS
## Board
- status: done
## Follow-ups / non-goals honored
- url.rs: case-insensitive HTTP(S) scheme; host:port bare form; mailto:/tel: as entry primary text decision; uppercase JavaScript: fixture in wild.rs. work[].description stays unrendered (contract 1.0). ZG-4: rust-version pin; split emit.rs model/write on first second-backend commit.
