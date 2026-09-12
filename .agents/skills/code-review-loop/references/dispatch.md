# Dispatch prompts

Fill the PR URL. Do not add extra duties. The child skill is the law.

## Review Agent

```
Read and follow `.agents/skills/github-pr-review/SKILL.md` in full.

Review <PR url>. Post the review on GitHub.

Return only:
- event (REQUEST_CHANGES | COMMENT | APPROVE)
- review URL
- HEAD sha you reviewed
- findings table: severity | path:line | problem
- count of q findings
- whether the findings table is empty (yes/no)
```

## Fix Agent

```
Read and follow `.agents/skills/github-pr-fix/SKILL.md` in full.

The user asked for `--all` (include nits). Fix every open inline thread
except `q`. Apply nits. Do not invent work outside those threads.

PR: <PR url>

Return only:
- thread table: Thread | Severity | Action | SHA | Resolved
- new HEAD sha
- any human-needed line (check you could not run, cluster left open)
```
