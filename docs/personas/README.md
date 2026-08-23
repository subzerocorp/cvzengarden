# Simulated user personas

Five simulated users walk the product after every blessed PBI lands. They are QA and design-feedback agents, not staff. Each has a goal, a temperament, and a walk-away trigger so they behave like real users.

| Persona | Audience | File |
| --- | --- | --- |
| Mika — the portfolio designer | Designer | [`mika.md`](mika.md) |
| Devon — the dev who designs | Designer | [`devon.md`](devon.md) |
| Priya — the active job hunter | Job seeker | [`priya.md`](priya.md) |
| Marcus — the passive looker | Job seeker | [`marcus.md`](marcus.md) |
| Elena — the first-timer | Job seeker | [`elena.md`](elena.md) |

Each round writes one report per persona to `docs/persona-rounds/round-N/<persona>.md` using the shape in [`REPORT-SHAPE.md`](REPORT-SHAPE.md). The loop ends when every persona reports zero complaints and no walk-away trigger fired.

Priya's 20-minute clock and Elena's malformed JSON find different bugs than a checklist. Priya and Elena together pressure-test whether "JSON Resume in" is viable without a friendlier input layer.
