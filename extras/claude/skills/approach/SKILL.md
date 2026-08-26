---
name: approach
description: Put finished work on final approach — read the working tree, split it into a logical series of commits, push the branch, and open a draft GitHub PR for a human to add reviewers and mark ready. Use when work is complete and ready for review, or when asked to "land this", "commit and push", "open a PR", "ship it", or "wrap this up".
---

# approach

Approach is the committed leg of the flight, with the runway in sight and time still to go around. The work is done; this is about getting it into a shape someone else can review — a history that reads as a sequence of decisions, and a pull request that explains itself.

Nothing here is irreversible. A branch can be force-pushed, a PR closed, an approach abandoned. That is why this is separate from `land`, which merges.

**The failure mode this skill exists to prevent is shipping a diff nobody has read** — one commit named after the ticket, carrying whatever happened to be in the working tree. That commit is unreviewable, unrevertable in parts, and it is how scratch files and stray credentials reach a remote.

This skill commits, pushes, and opens a draft PR by design. Invoking it *is* the authorization; do not ask again at each step. It stops short of marking that PR ready for review, deliberately — see step 6.

Where this sits in the pattern: `preflight` orients before the work, `approach` submits it, `crosscheck` verifies the review that comes back, `land` merges.

## 1. Check the approach

```bash
git rev-parse --abbrev-ref HEAD
git status --short
git log --oneline @{u}..HEAD 2>/dev/null || echo "no upstream yet"
gh pr view --json number,url,state 2>/dev/null || echo "no PR yet"
```

Stop and say so, rather than improvising, if:

- **You are on the default branch.** Offer to create a branch from the work instead. Never commit directly to `main`.
- **There is nothing to submit** — clean tree, nothing ahead of upstream. Say it plainly.
- **A PR already exists.** Then this is a follow-up push, not a first approach: commit, push, and report the existing URL. Do not open a second one.

If the tree is clean but commits are unpushed, skip to step 5.

## 2. Read what you are submitting

Read the actual diff. All of it.

```bash
git diff
git diff --staged
git status --porcelain
```

This is not ceremony — the grouping in step 3 is impossible without it, and it is the only point where these get caught:

- **Files that should not ship.** Scratch output, `.env` files, debug logging, a commented-out block left from a bisect, anything with a credential in it. Ask before committing anything you cannot explain; do not silently include it and do not silently drop it.
- **Untracked files that must be included.** `git status --short` marks these `??` and a plain `git commit -a` will miss them entirely — a new module that never got added is a broken build for everyone else.
- **Generated or gitignored paths.** If the change regenerates something ignored on purpose, that is a no-op to commit, not an omission to fix.

For anything large or unfamiliar, `git diff --stat` first to find where the weight is, then read those files closely.

## 3. Group into commits by reason

**Split by reason, not by file, not by directory, and never one commit per ticket.** The test of a good series: someone reading `git log` sees the decisions in the order they were made, and any one commit could be reverted on its own without taking unrelated work with it.

A reason is a *why*. "Update files" and "Address PR feedback" are not reasons. These are:

- fix the bug the ticket is about
- extract the helper the fix needed
- add the regression test
- document the constraint that made it non-obvious
- rename the thing whose old name caused the confusion

Practical rules:

- **A refactor that merely enables the real change is its own commit, and comes first.** Mixed in, it hides the actual fix inside noise.
- **Formatting or mechanical churn goes in a separate commit,** always. A whitespace pass wrapped around a logic change makes the logic change invisible in review.
- **Docs describing the change can ride with it;** docs describing something you merely learned are their own commit.
- **If two changes would be described with "and", they are two commits.**

Stage precisely — `git add <path>`, or `git add -p` when one file carries two reasons. Do not use `git commit -a`.

Announce the planned series before making it. A short list, one line each, in order. It is much cheaper to re-cut the grouping before the commits exist.

This effort is only worth anything if the series survives the merge, so `land` merges rather than squashes. If a repo you are in squash-merges by policy, say so here — the grouping still helps review, but the history will be flattened on the default branch and the commit bodies are the only place the reasoning will survive.

## 4. Commit

**Check the repo's conventions first.** Read `CLAUDE.md` (root and the working subdirectory) for commit rules before writing a single message. Repos in this account genuinely disagree — one of them forbids `Co-Authored-By` and session trailers outright, and adding them there is a real error, not a harmless extra.

Message shape: a concise imperative subject line, then a body only when it earns its place. The body explains **why**, since the diff already shows what. Wrap at 72.

```
fix: keep the splash mark inside the Android icon mask

The adaptive icon crops to a circle on most launchers, and the mark's
corners fell outside it. Inset the artwork rather than shrinking it, so
the optical weight matches iOS.
```

A subject line alone is correct and preferable for a change that is genuinely self-evident. Do not pad.

## 5. Push

```bash
git push -u origin HEAD
```

If the push is rejected as non-fast-forward, **stop and report it.** Do not force-push and do not rebase on the user's behalf — someone else's commits may be involved, and that decision is theirs.

## 6. Open the PR as a draft

Create it through the API as a **draft**, then open it in the browser:

```bash
ghpr --dry-run     # prints Branch / Base / Title, creates nothing
gh pr create --draft --base "<Base>" --title "<Title>" --body-file /tmp/pr-body.md
gh pr view --web
```

Read Branch / Base / Title from the `ghpr` output. Derive them from `ghpr` rather than reimplementing them — it lives in the dotfiles repo's `scripts/` (on `PATH`) and already handles Linear key extraction, title-casing, and the base-branch walk that makes a stacked branch target its parent instead of `main`.

**Always take this path. Do not use `gh pr create --web`,** which prefills the form via URL parameters. It looks appealing because it creates nothing, but **GitHub truncates a long body silently** — a 2,489-byte body became 3,477 characters once percent-encoded and was cut off with no error and no warning, the form simply rendering a short body. Percent-encoding inflates prose about 1.4x and code-heavy text more, since every newline, backtick, and space becomes three characters. Since `gh pr view --web` opens the browser anyway, the URL route buys nothing and risks submitting a PR whose reasoning has been quietly amputated.

A draft preserves what actually matters about a "not submitted" state: **it cannot be reviewed or merged until a human clicks Ready for review**, and reviewers and labels are still chosen by them on the page. The gesture moves from a form button to a PR button.

Three things to get right:

- **Title format is `UPPERCASE-ISSUENUM Brief Description`** — e.g. `LNK-41 Expo Drift`. `ghpr` derives it from the branch slug, so a terse branch yields a terse title. If the result is genuinely uninformative, propose a better description from the Linear issue title, show what `ghpr` would have produced, and let the user choose. Keep the format identical either way and stay under roughly eight words.
- **Use `--body-file`, not `--body`.** PR bodies contain backticks, code fences, and newlines that do not survive inline shell quoting.
- **If `ghpr` is missing** (it is only on `PATH` where the dotfiles repo is checked out), derive the key and base yourself from the branch name and the repo's default branch, and say that you did.

Verify the body survived — a one-line check that would have caught the truncation above:

```bash
gh pr view <n> --json body --jq '.body' | wc -c   # compare against wc -c on the source
```

Note that a draft PR does **not** auto-request Copilot, so `crosscheck` will find nothing until the PR is marked ready for review. Mention that rather than letting it look like a missing review.

### Writing the body

Pitch it at a junior engineer reading it cold, with no access to the conversation that produced it. Flowing prose in tight paragraphs — not a wall of headers, tables, and bullets. Aim for something a reader finishes.

Cover, in about this order and only where there is something to say:

1. **What changed and why**, in a couple of sentences. Lead with the problem, not the solution.
2. **Anything a reviewer would otherwise have to reconstruct** — a non-obvious constraint, a rejected alternative and the reason, a deliberate omission.
3. **How it was verified.** Name the actual command or check and its result. "Tested" on its own is worth nothing.
4. **Why it matters**, in a line, when the business reason is not self-evident from the title.

Keep load-bearing facts explicit — exact commands, versions, identifiers, file paths — because those are the parts a reader cannot infer. Cut everything else. If a fact is already obvious from the diff, leave it out.

Link the Linear issue when there is one, as a real markdown link with its full URL — `[LNK-41](https://linear.app/…)` — not a bare identifier. A reader outside Linear cannot resolve `LNK-41` on its own, and a reviewer should reach the ticket in one click. Link each issue on first mention only, including any follow-ups the work spawned; `get_issue` returns the canonical `url` field. Do not restate the ticket's contents.

## 7. Report

State what happened, briefly: the commits made (subject lines, in order), that the branch is pushed, and the draft PR's number and URL.

**Say clearly that it is a draft and nobody has been asked to review it.** Reporting it as "PR opened" when it is a draft awaiting reviewers is the kind of small inaccuracy that gets a review forgotten for a day — and the author is the only one who can move it, since a draft sends no notifications.

Then stop. Do not wait for review from here — that is `crosscheck`, and it is a separate invocation because the wait is measured in minutes and belongs to the user's attention, not yours.

## Go-around

If a cheap, obvious check exists for the changed code — a type check, a linter, a test script the repo already defines — run it before step 4, and report a failure instead of committing over it. Going around costs one circuit; a broken commit on a shared branch costs everyone else's afternoon.

This does not extend to building the project, running a full suite that takes minutes, or adding checks the repo does not already have. If a check fails and the user tells you to proceed anyway, proceed — and note the failure in the PR body so the reviewer is not the one to discover it.
