---
name: code-review-loop
description: |
  Review–fix loop on a GitHub pull request. Conductor only.
  Review Agent runs github-pr-review (Claude Fable 5.1). Fix Agent runs
  github-pr-fix --all including nits (Kimi K3 Max). Repeat until the review
  posts zero findings — no blockers, should-fix, nits, or questions.
  Use when the user types /code-review-loop or asks to review-and-fix a PR
  until clean. Needs a PR URL or owner/repo#n. Not for a one-shot review
  (github-pr-review) or a one-shot fix (github-pr-fix).
disable-model-invocation: true
metadata:
  short-description: Loop github-pr-review and github-pr-fix until the PR is clean
---

# Code Review Loop

**You are the conductor.** You never review, never fix, never push, never
resolve a thread. You only parse the PR, dispatch the two agents below, and
stop when the stop rule fires.

Recite the One-Sentence Mandate before the first dispatch.

## One-Sentence Mandate

> Dispatch Review then Fix on one PR until Review returns zero findings,
> including questions; never review or fix yourself.

## Intake

PR from `$ARGUMENTS` or the user message: URL or `owner/repo#n`. Missing → stop.

Both child skills must exist as `.agents/skills/github-pr-review/SKILL.md` and
`.agents/skills/github-pr-fix/SKILL.md`. Missing → stop; tell the human to
install those skills first.

## Agents (fixed)

| Role | Skill | Flags | Model |
|---|---|---|---|
| Review Agent | `github-pr-review` | none | Claude Fable 5.1 |
| Fix Agent | `github-pr-fix` | `--all` (nits too) | Kimi K3 Max |

Do not swap skills, flags, or models. Do not run either skill yourself.

### Model slugs (Cursor Task)

Resolve from the session's listed Task slugs. Match on the **name**, not a
cousin:

| Agent | Required name | Slug when listed |
|---|---|---|
| Review | Claude Fable 5.1 | `claude-fable-5-1-thinking-high` (or another `claude-fable-5-1-*` the human named) |
| Fix | Kimi K3 Max | the listed slug whose name is Kimi K3 Max or Kimi K3 |

No matching Fix slug → **stop**. Do not substitute Claude, Grok, GPT, or inherit.

When Cursor Task is available: `subagent_type` `generalPurpose`, `model` the
resolved slug. Prompt text: [references/dispatch.md](references/dispatch.md).
Other harnesses: same roles, same skills, that harness's delegate primitive.

## Loop

Round `k`, starting at 1. Cap **5**.

1. **Review.** Dispatch Review Agent. It must follow `github-pr-review` and
   post the review. Collect: event, review URL, findings table (severity,
   path:line, problem), HEAD sha.
2. **Stop if clean.** Zero findings of every severity (`blocker`,
   `should-fix`, `nit`, `q`) → success. Report and halt.
3. **Stop if only `q`.** Every remaining finding is `q` → stop. Questions
   need a human; Fix must not invent answers. Report the `q` threads.
4. **Fix.** Dispatch Fix Agent. It must follow `github-pr-fix` with
   `--all` / include nits. Collect: thread table, new HEAD sha.
5. **Next round.** `k += 1`. If `k > 5` → stop, report last Review + what
   is still open. Else go to step 1 (Review is now a re-review on the new HEAD).

A Review that only restates old open threads and adds nothing new is still
dirty if any finding remains. Clean means the Review Agent's **new** review
has an empty findings table.

## Do not

- Write, edit, or review code.
- Post a review or reply on a thread.
- Push, resolve, or unresolve.
- Skip nits on the Fix dispatch.
- Treat a `q` as a fix.
- Start a second PR.

## Report

After each round, one line: `Round k — Review: <event> <n> findings (<severities>) — Fix: <fixed|skipped|n/a>`.

On stop:

```
Loop: <clean|stopped-on-q|capped> — <PR url>
Rounds: <k>
Last review: <url>

| Round | Event | Findings | Fix HEAD |
|---|---|---|---|
```

Then at most two lines: why it stopped, and any human decision (`q`, missing
model, missing child skill).
