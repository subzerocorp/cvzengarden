---
name: crossr-review
description: >
  Conducts a Review Agent then Fix Agent loop on a GitHub pull request until
  the review returns zero issues and zero questions, then stamps APPROVE or
  comments APPROVED. Use only when the user invokes /crossr-review.
disable-model-invocation: true
metadata:
  author: scull7
  short-description: Loop github-pr-review and github-pr-fix until a clean PR
---

# CrossR Review Loop

You are the conductor. You never review the diff and you never edit the PR
branch. You only resolve inputs, launch the two sub-agents, and stamp a clean
result.

## Code Review  Loop

You will review the pull request using the "Review Agent" for the code review, then the "Fix Agent" to fix all issues found during the review.  You will loop this process until the review returns with zero issues and questions found.

### Sub-Agents

  Name: Review Agent
  Skill: /github-pr-review
  Model: Claude Fable 5.1
  ---
  Name: Fix Agent:
  Skill: /github-pr-fix --all (include nits)
  Model: user default

`--all` means nits are in scope. `q` threads are not fixes; they keep the
review dirty and stop the loop for a human.

## Flags

Parse from the invocation. Unknown flags: stop and ask.

| Flag | Default | Meaning |
|---|---|---|
| `--model-review <id>` | `high` | Review Agent model |
| `--model-fix <id>` | user's default | Fix Agent model |
| `--max-rounds <n>` | `8` | Review→Fix cycles before a dirty stop |

A bare PR reference (URL, `owner/repo#N`, `pr 58`, `#91`) is the target, not a flag.

### Model ids

`--model-review` short ids map to Claude Fable 5.1 thinking slugs:

| id | slug |
|---|---|
| `low` / `medium` / `high` / `xhigh` / `max` | `claude-fable-5-1-thinking-<id>` |
| same + `-fast` | `claude-fable-5-1-thinking-<id>-fast` |

Any other token is a raw slug. `--model-fix` has no short map (example:
the Desktop slug for Kimi K3 Max). If a requested slug is not in this
session's model list: Review Agent — stop and ask; Fix Agent — use the
user's default and say so once.

## Resolve the PR

Collect candidates from the invocation and this conversation: GitHub PR URL,
`owner/repo#N`, `pr <n>`, `#<n>`.

- One distinct PR → use it.
- Several distinct PRs → ask which.
- `#<n>` only → take `owner/repo` from `origin`.
- None → request a PR and stop.

## Sibling skills

`github-pr-review` and `github-pr-fix` must be readable before the first
Review Agent launch.

**Found** if the name is in this session's skill list, or a `SKILL.md` exists
under `.agents/skills/`, `.cursor/skills/`, `~/.cursor/skills/`, or
`~/.agents/skills/`.

**Missing:** ask once to load the missing trees from
`https://github.com/sycamore-hq/crossr-skills` (paths
`.agents/skills/github-pr-review/` and `.agents/skills/github-pr-fix/`).
Do not fetch without approval.

On approval, copy each missing tree to `~/.cursor/skills/<name>/`. Copy into
`.agents/skills/<name>/` only when the user wants them committed here. Then
read each `SKILL.md` and pass that path to the sub-agent. Do not wait for
a session restart.

On refusal, stop.

## Loop

```
round = 1
while round <= max_rounds:
  run Review Agent on the PR
  if clean → stamp, report, stop
  if only `q` remain → report questions, no Fix, no stamp, stop
  run Fix Agent on the PR with nits in scope
  round += 1
report dirty, no stamp, stop
```

**Clean** means the Review Agent report has no `blocker`, `should-fix`,
`nit`, or `q` rows (empty findings table, or an `APPROVE` / zero-finding
`COMMENT`). Open questions keep it dirty even when every issue is gone.

**Review Agent** reads `github-pr-review` and the PR. It posts the review.
It does not push.

**Fix Agent** reads `github-pr-fix` with nits in scope and the PR. It
implements, pushes to the PR head, replies, and resolves only threads whose
`Done when` holds. It does not open a new review.

Launch each as a sub-agent. Wait for its report table before the next step.
The conductor does not substitute for a missing report.

## Stamp

After a clean review, the PR must show an approval or the word `APPROVED`:

1. If the last Review Agent event is `APPROVE`, that is the stamp.
2. Else submit an approving review on the PR.
3. If GitHub refuses (author cannot approve their own PR), post a
   conversation-tab comment whose body contains the word `APPROVED`.

Verify one of those exists before claiming done. Do not stamp on a dirty
stop or a questions-only stop.

## Report

One table, then at most two lines.

```
Loop: <clean|questions|dirty> — <PR url> — rounds <n>/<max>

| Round | Review event | Issues | Questions | Fix |
|---|---|---|---|---|
```

`Fix` is `—` on the last clean or questions-only review. The extra line is
the stamp (`APPROVE` / `APPROVED` comment url) or why there is none.

## Do not

- Review or edit the PR yourself.
- Launch Fix when the review is clean or only `q` remains.
- Stamp a dirty or questions-only result.
- Fetch sibling skills without approval.
- Invent a PR, a model slug, or a finding.

## Catalog

Register this conductor in the invoking project's `AGENTS.md` Skills list.
The CrossR capability catalog (`sycamore-hq/crossr-skills`
`docs/public-skills.json`) does not take orchestration skills. The sibling
home for conductors is `sycamore-hq/crossr-loops`.
