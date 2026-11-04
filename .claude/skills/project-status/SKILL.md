---
name: project-status
description: Report CornerTimer's progress toward the v0.1.0 MVP — merged PRs, open issues, CI health, what to work on next, and what's blocked on the owner. Use when asked for status, progress, next steps or a timeline.
argument-hint: "[optional focus, e.g. 'since yesterday']"
---

# CornerTimer status report

## 1. Gather (read-only)
Use the REST API (GraphQL may be unavailable in agent sessions):
```bash
R=repos/AhmosGUC/$(basename "$(git rev-parse --show-toplevel)")   # or the current repo name
gh api "$R" --jq '{full_name, default_branch}'
gh api "$R/issues?state=all&per_page=50" --jq '.[] | select(.pull_request|not) | "#\(.number) \(.state) [\([.labels[].name]|join(","))] \(.title)"'
gh api "$R/pulls?state=all&per_page=30" --jq '.[] | "#\(.number) \(.state) merged=\(.merged_at) \(.head.ref): \(.title)"'
gh api "$R/actions/runs?per_page=15" --jq '.workflow_runs[] | "\(.head_branch) \(.status)/\(.conclusion) \(.created_at)"'
gh api "$R/branches?per_page=50" --jq '.[].name'
gh issue view 1   # epic: roadmap, dependency graph, task list
```
If the repo name has changed, `gh` follows GitHub's redirect.

## 2. Verify, don't trust titles
For each PR merged since the last report, check against its issue's acceptance criteria. Look at the actual files on `master`, test counts, and whether required images or Provenance rows exist. Flag:
- Issues whose PR merged but are still open, or that closed with criteria unmet.
- PRs merged before CI finished, or with failing or cancelled checks.
- Stale branches, wrong default branch, missing `Package.resolved`, unprotected `master`.

## 3. Report (keep it short)
1. **One-line status**: N of 17 MVP issues done; CI on `master` green or red.
2. **Table**: issue · PR · state (✅ done / ⚠️ partial / ⏳ in progress / — not started), with a short note on anything partial.
3. **Problems found**, if any.
4. **Next agent instruction**: a ready-to-paste block naming the next issues that can run in parallel (from the epic's graph, only those whose dependencies are closed), plus any follow-up fixes.
5. **Owner tasks**, split into "blocking now" and "later": GitHub settings, decisions, Mac-only checks such as icon approval, `make install`, and the #17 QA.
6. **Timeline**: remaining waves with who does each (agent / owner) and rough durations.

Don't change anything (closing issues, deleting branches, editing settings) without the owner's OK.
