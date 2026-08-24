# PBI Completion — ZG-2
## Title
Never panic on a wild date: tolerate timestamps, drop unparseable dates
## Phases
- phase-1: BLESS reviewer | tester | architect — commit `696ef18` (one Tester REJECT: surviving days_in_month mutant → test added)
## AC Evidence
On the PBI (`pinto show ZG-2`). 40 renderer tests + 13 wild; locks unchanged; just verify exit 0.
## Verification matrix
- fmt / clippy pedantic / cargo test / node:test / probes: PASS
## Board
- status: done
## Follow-ups / non-goals honored
- ZG-4: `rust-version = "1.87"` first. ZG-3: lock `"2020 (approx)"` and endDate-without-start; serde `[]`→default quirk handed over. §1/§8 parenthetical on datetime for parseable dates only.
