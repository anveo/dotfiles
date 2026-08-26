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
gh pr view --json number,title,url,state,isDraft,baseRefName,headRefName,mergeable,mergeStateStatus,reviewDecision,commits
```

Stop and say so if there is no PR (the work has not been through `approach`), if it is already `MERGED` or `CLOSED`, or if it is still a **draft** — a draft PR is an explicit signal the author was not finished, and marking it ready is their call, not yours.

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

## 4. Sync local state

The merge happened on the remote; the local checkout still thinks it is on a branch that no longer exists.

```bash
git switch <default-branch>
git pull --ff-only
git fetch --prune
```

`--ff-only` is deliberate. A plain `git pull` on a default branch that has diverged will create a merge commit nobody intended; failing loudly is better.

**If the work was in a worktree**, `gh pr merge --delete-branch` cannot remove the branch while a worktree holds it checked out. Move out first, then `git worktree remove <path>` and `git worktree prune`. Report the path rather than deleting a worktree that may hold unrelated scratch work.

## 5. Close out the ticket

If the branch carried a Linear identifier, offer to move the issue to Done. **Offer, do not do it** — it is outward-facing and visible to the whole workspace, and a merged PR does not always mean a finished ticket. One offer; if declined, drop it.

The Linear tools are namespaced per workspace, so discover rather than assume the name:

```
ToolSearch: "linear save issue"
```

Two things worth mentioning alongside the offer, when true: follow-up issues that this work created and left open, and anything the PR body flagged as deliberately deferred. That is the moment those are cheapest to remember.

## 6. Report

Short. What merged, by which method, into which branch, with the PR number and URL. Then the cleanup: branch deleted, local synced, worktree removed if it was.

**Name anything left open** — a follow-up issue, a check that was failing and got merged anyway on instruction, a ticket the user declined to close. The value of this step is that it is the last moment anyone is paying attention to this branch.

## Go-around

Merging is the one step here that cannot be undone cheaply, so prefer stopping to guessing. Red checks, requested changes, a conflict, an unmerged parent, an unreviewed PR — all of these are reasons to report and hold rather than merge.

If the user says merge anyway, merge. They can see what you reported and it is their call. Note in the report exactly what was overridden, so the decision is on the record rather than in someone's memory.
