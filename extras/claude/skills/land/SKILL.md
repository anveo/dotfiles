---
name: land
description: Merge an approved pull request and clean up after it — verify checks and review state, merge preserving the commit series, delete the branch, sync the default branch, and close out the Linear issue. Use when a PR is approved and ready to merge, or when asked to "merge it", "land it", "merge the PR", or "close this out".
---

# land

Touchdown. Everything up to this point could be undone — a branch force-pushed, a PR closed, an approach abandoned. This is the step that cannot, so it is the one that gets checked before it is committed to.

**The failure mode this skill exists to prevent is merging on assumption** — that checks passed, that the review was addressed, that this branch was even meant to go to `main`. Every one of those is a query away, and the cost of being wrong is a revert on a shared branch.

The second failure mode, quieter and more common: **squashing away the commit series** that `approach` was careful to build. GitHub's UI remembers whichever button was used last, and one absent-minded squash turns five reasoned commits into "Merge pull request #42". See step 3.

Where this sits: `preflight` orients before the work, `approach` submits it, `crosscheck` verifies the review, `land` merges.

## 1. Resolve the PR

Use the number if given, otherwise the current branch's PR:

```bash
gh pr view --json number,title,url,state,isDraft,baseRefName,headRefName,mergeable,mergeStateStatus,reviewDecision,mergedAt,commits
git rev-parse --git-dir --git-common-dir
```

Stop and say so if there is no PR (the work has not been through `approach`), if it is `CLOSED`, or if it is still a **draft** — a draft PR is an explicit signal the author was not finished, and marking it ready is their call, not yours.

**`MERGED` is not a dead end.** A PR merged from the GitHub UI, by automerge, or by someone else is routine, and the cleanup half of this skill still applies and is still the useful part. Say the merge already happened, name the merge commit and time from `mergedAt`, and **skip to step 4**. Do not re-merge and do not run step 2 — there is nothing left to gate.

**Detect a worktree here, not in step 4.** The two paths differ from `git rev-parse`: in a linked worktree `--git-dir` and `--git-common-dir` disagree (`…/.git/worktrees/<name>` versus `…/.git`), while in a normal checkout they are the same. This has to be known before step 3, because a worktree changes what steps 3 and 4 can attempt at all — `gh pr merge --delete-branch` only half-works, and step 4's `git switch` cannot run. `git worktree list` gives the fuller picture when you need the paths.

## 2. Check before committing to it

Four questions, all answerable without guessing. Report and stop on any adverse answer rather than merging past it.

```bash
gh pr checks                     # CI
gh pr view --json reviewDecision,mergeStateStatus,mergeable
```

- **Are the checks green?** `gh pr checks` exits non-zero when any fail. Pending is not passing — a merge that races CI is how a red default branch happens. If checks are still running, offer to wait rather than merging blind.
- **Is the review resolved?** `reviewDecision` of `CHANGES_REQUESTED` is a hard stop. `APPROVED` is the clear case. **Empty is the ambiguous one** and it is common: Copilot submits as `COMMENTED`, which leaves `reviewDecision` unset, so an unreviewed PR and a Copilot-reviewed PR look identical here. If `crosscheck` has not been run on a PR with review comments, say so before merging.
- **Is it mergeable?** `mergeable: CONFLICTING` means rebase or merge `main` in first — that is the author's decision about how to resolve, so report it and stop. `mergeStateStatus` of `BLOCKED` means a branch protection rule is unsatisfied; name which one.
- **Is the base right?** If `baseRefName` is not the default branch, this is a **stacked PR** and its parent must merge first. Merging a stacked branch early drags the parent's unreviewed commits into `main` and makes the parent PR's diff nonsense. Check the parent's state and stop if it is still open.

## 3. Merge, preserving the series

**Default to `--merge`.** A merge commit keeps the individual commits on the default branch, which is the entire point of the grouping `approach` did. `--squash` discards it.

```bash
gh pr merge <n> --merge --delete-branch
```

Use another method only when the repo says so — a squash-only repo setting, or a stated convention in `CLAUDE.md`. Confirm what the repo actually allows and what it has been doing, rather than trusting the UI default:

```bash
gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed,deleteBranchOnMerge
git log --merges --oneline -5 origin/main
```

The second command is the more honest answer. A history of `Merge pull request #N` means merge commits; a history of squashed subject lines with `(#N)` appended means squash. Follow what the repo does.

`--delete-branch` also deletes the local branch and is worth passing explicitly: `deleteBranchOnMerge` is off by default on GitHub, so without it the remote accumulates every branch ever merged.

**From a linked worktree, `--delete-branch` only does half the job.** `gh` does not recognize a linked worktree as a git repository for local-branch operations and skips that half with a warning that reads like an error about something else entirely:

```
! Skipped deleting the local branch since current directory is not a git repository
```

The remote branch *is* deleted; the local one is not. Do not read that line as a failure, and do not read its absence as success — check with `git branch --list <name>` and hand the deletion over per step 4.

## 4. Sync local state

The merge happened on the remote; the local checkout still thinks it is on a branch that no longer exists.

```bash
git switch <default-branch>
git pull --ff-only
git fetch --prune
```

`--ff-only` is deliberate. A plain `git pull` on a default branch that has diverged will create a merge commit nobody intended; failing loudly is better.

**In a worktree, those first two commands cannot run at all.** The default branch is checked out in the primary repository, and git refuses to check out one branch in two places — `git switch main` fails with `fatal: 'main' is already checked out at '/path/to/repo'`, and `git pull --ff-only` therefore never happens either. (`git fetch origin main:main` fails for the same reason.) From a worktree the sync step is only:

```bash
git fetch --prune
```

Then verify rather than assume: `git log --oneline -1 main` against `origin/main` will often already match, because the primary checkout may have been updated independently. The fast-forward itself belongs to that checkout, not this one.

**Branch and worktree removal have to be handed over.** A worktree cannot remove itself, and the branch cannot be deleted while checked out here. Note also that the repo's own `CLAUDE.md` may forbid `cd`-ing to the primary checkout from a worktree — the monicur repo does — so "move out first" is not available to you. Give the user the two commands to run from the primary checkout and stop:

```bash
git worktree remove <path>
git branch -d <branch>
```

Report the path rather than deleting a worktree that may hold unrelated scratch work.

## 5. Close out the ticket

If the branch carried a Linear identifier, **read the issue's status before saying anything about it.**

```
ToolSearch: "linear get issue save issue"
get_issue(id: "APP-225")
```

A workspace with the Linear↔GitHub integration enabled moves the issue on its own, and this is the common case, not the exception. On a recent run the `stateHistory` showed In Progress → In Review the moment the PR was marked ready → Done the moment it merged, twenty-two seconds later, with no human involved. Offering to set an already-`Done` issue to Done is noise, and offering it twice trains the user to skim.

So: if `statusType` is already `completed`, say so in a clause and move on — no offer. Only when the issue is genuinely still open does the offer apply, and then **offer, do not do it** — it is outward-facing and visible to the whole workspace, and a merged PR does not always mean a finished ticket. One offer; if declined, drop it.

Two things worth mentioning either way, when true: follow-up issues that this work created and left open, and anything the PR body flagged as deliberately deferred. That is the moment those are cheapest to remember.

## 6. Report

Short. What merged, by which method, into which branch, with the PR number and URL — or, when the merge had already happened, that it had, with the commit and time.

Then the cleanup, split honestly into **what you did** and **what is left for the user**. In a normal checkout those are the same list: branch deleted, local synced. From a worktree they are not — the sync was a `fetch --prune`, and the branch and worktree deletions are commands you handed over and cannot confirm. Do not write "worktree removed" when what happened is "here are the two commands to remove it." A handoff reported as a completed action is how a stale worktree survives for a month.

**Name anything left open** — a follow-up issue, a check that was failing and got merged anyway on instruction, a ticket the user declined to close, cleanup that is now waiting on them. The value of this step is that it is the last moment anyone is paying attention to this branch.

## Go-around

Merging is the one step here that cannot be undone cheaply, so prefer stopping to guessing. Red checks, requested changes, a conflict, an unmerged parent, an unreviewed PR — all of these are reasons to report and hold rather than merge.

If the user says merge anyway, merge. They can see what you reported and it is their call. Note in the report exactly what was overridden, so the decision is on the record rather than in someone's memory.
