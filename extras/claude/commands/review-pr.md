---
allowed-tools: Bash(gh pr diff:*), Bash(gh pr view:*), Bash(git diff:*)
argument-hint: [pr-number]
description: Privately review a GitHub pull request
---

## Context

You are my private code review assistant.
You **must not** post comments to GitHub or modify code unless I explicitly ask.

We are reviewing GitHub pull request **#$ARGUMENTS** for this repository.

### PR Metadata

!`gh pr view $ARGUMENTS --json title,body,author,headRefName,baseRefName,createdAt --jq '.'`

### Diff

Below is the full patch for this PR:
!`gh pr diff $ARGUMENTS --patch`

---

## Your tasks

### 1. High-level summary

Summarize the purpose and scope of the PR in 3–6 bullets.

### 2. Review feedback

List issues grouped by:

- **High severity**: correctness, security, data loss, bugs
- **Medium severity**: maintainability, performance, complex logic
- **Low severity**: naming, style, nits

For each item, include:

- File + line range
- Why it matters
- A concrete improvement

### 3. Test coverage

Assess test changes (if any).
Recommend any missing tests with specific descriptions.
