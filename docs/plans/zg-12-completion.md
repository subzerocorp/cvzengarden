# PBI Completion — ZG-12
## Title
Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks
## Phases
- phase-1: BLESS reviewer | tester | architect — commit (git log "ZG-12:")
## AC Evidence
On the PBI body (`pinto show ZG-12`): name-fits 296/296 & 355/355 px; rise only inside @supports with fill forwards; painted with/without support (opacity 1, 25830 px); reduced-motion clean; pre-line 3.0× ×3; anti-vacuity FAILs on 72596c7 recorded.
## Verification matrix
- fmt / clippy pedantic / cargo test / node:test 106 / Playwright probes (90 PASS): PASS
## Board
- status: done
## Follow-ups / non-goals honored
- css-structure scanner hardening (string literals, no-colon chunk) before ZG-20 reuses it; split rise policy into rise-structure.mjs then.
