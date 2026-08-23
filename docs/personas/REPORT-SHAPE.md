# Persona walk report shape

One Markdown file per persona per round: `docs/persona-rounds/round-N/<persona>.md`.

```markdown
# <Persona> — round N

**Walked:** <URL(s) and repo paths actually used>
**Time on task:** <minutes, if the persona has a clock>
**Walk-away:** yes | no — <trigger that fired, or "none">
**Goal reached:** yes | partially | no — <one sentence>

## Complaints

Ordered by severity. Each one is something the persona would say out loud.

| # | Severity | What happened | What I expected | Where |
| --- | --- | --- | --- | --- |
| 1 | blocker | … | … | URL / file / control |
| 2 | major | … | … | … |
| 3 | minor | … | … | … |

Severity: **blocker** = goal impossible or walk-away; **major** = goal reached only with real friction; **minor** = polish.

## What worked

- …

## Evidence

- Screenshot / probe output paths under `/tmp/persona-lab/<persona>/`, quoted DOM, or command output.
```

A round has **zero complaints** for a persona only when the Complaints table is empty and Walk-away is `no`.
