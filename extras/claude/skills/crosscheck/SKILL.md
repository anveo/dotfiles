---
name: crosscheck
description: Wait for code review on a pull request — from Copilot, Cursor Bugbot, Claude, another bot, or a human — then independently verify every finding against the actual code and report which ones hold up. Use when a PR has been opened and a review is pending or in, or when asked to "wait for Copilot", "check the Bugbot review", "what do you think of the review", or to triage review comments. Verifies claims rather than relaying them.
---

# crosscheck

A cockpit crosscheck is one crew member independently verifying another's work before anyone commits to it. That is the job here. A review is an input to be checked, not a result to be relayed — in practice a meaningful share of findings are real hazards with wrong diagnoses, or confident corrections that are simply wrong. That holds for automated reviewers most of all, but a human's finding gets the same scrutiny.

**The failure mode this skill exists to prevent is relaying a finding you have not verified.** If you cannot check a claim, say so explicitly rather than passing it along with implied endorsement.

## Who reviews

**Do not expect any particular reviewer.** A PR may be reviewed by Copilot, Cursor Bugbot, Claude, some other bot, a human, or any mix — whoever the author chose to ask, or whatever the repo runs on its own. Discover who actually reviewed; do not audit the PR against a list of who might have. A bot that was never part of the plan is not a gap in coverage, and reporting it as one is noise.

Two sources say what to expect, and only these two:

- **The user.** "Wait for Copilot" means wait for Copilot.
- **The repo's `CLAUDE.md`,** if it says how reviews are requested (e.g. "reviews are requested by hand with an `@claude` mention"). Read it once; when it is silent, expect nothing in particular.

### Known bots

The three bots seen most often differ in every mechanical detail — how they are summoned, where their output lands, and what login owns it. This table is a lookup for parsing their output, not a checklist of who should have reviewed. Read it before writing a login-specific query; guessing a login is the single most common way to conclude "no review arrived" when one is sitting on the page.

| | **Copilot** | **Cursor Bugbot** | **Claude** |
|---|---|---|---|
| Summoned by | Requesting it as a reviewer | Runs automatically on push | Commenting `@claude` on the PR |
| Review object | yes, `state: COMMENTED` | yes, `state: COMMENTED` | **none** — `reviews` is `[]` |
| Review author login | `copilot-pull-request-reviewer` | `cursor` | *n/a* |
| Inline comment login | `Copilot` | `cursor[bot]` | `claude[bot]` |
| Findings live in | inline comments | inline comments | the issue comment body |
| Body marker | per-file summary table | `<!-- BUGBOT_REVIEW -->` | `**Claude finished @user's task**` |

**The review author and the inline-comment user are different logins for every bot.** Copilot reviews as `copilot-pull-request-reviewer` but its comments are owned by `Copilot`; Bugbot reviews as `cursor` but comments as `cursor[bot]`. Matching the review login against the comments endpoint returns nothing and looks exactly like a review with no findings.

Humans and unfamiliar bots follow GitHub's ordinary shapes: a review object (`APPROVED`, `CHANGES_REQUESTED`, or `COMMENTED`) with a body, inline comments on the comments endpoint, and sometimes plain PR comments.

## 1. Resolve the PR

Use the number if given. Otherwise find the PR for the current branch:

```bash
gh pr view --json number,title,url,headRefName,baseRefName,additions,deletions
```

If there is no PR for the branch, stop and say so. Capture the repo once for the API calls:

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

## 2. Establish who has reviewed, or is going to

Do this *before* waiting, or you will wait forever on a review that was never coming. Two calls cover every kind of reviewer:

```bash
gh pr view {n} --json author,reviews,comments --jq '{author: .author.login, reviews: [.reviews[] | {author: .author.login, state, at: .submittedAt}], comments: [.comments[] | {author: .author.login, at: .createdAt}]}'
gh api repos/{owner}/{repo}/pulls/{n}/requested_reviewers
```

Anyone other than the PR author who has left a review, an inline comment, or a substantive PR comment is a reviewer. `requested_reviewers` lists who has been asked and has not yet delivered — humans and teams, and Copilot (login `Copilot`, `"type": "Bot"`). A completed review removes the request. Bugbot and Claude never appear there; they are summoned another way, so their absence from that list proves nothing.

Then decide what to wait for:

- **Someone has already reviewed since the last push** — go to step 4.
- **Someone is requested or summoned and has not delivered** — wait for them (step 3).
- **Nobody has reviewed and nobody is pending** — say so and stop. Do not pick a reviewer for the author; offer the options the repo actually uses (per its `CLAUDE.md`, or whatever it has used on past PRs), since summoning one is outward-facing.

**A bot that ran and failed is a gap; a bot that never ran is not.** Bugbot in particular posts a comment on failure rather than staying silent, and the failure reads as ordinary output:

> ### Bugbot couldn't run - usage limit reached

Treat that as *did not review*, never as *found nothing*, and say so in the report — it is the normal state late in a billing week. The same goes for any reviewer that was requested and errored out. But when a bot shows no sign of having been asked, leave it out of the report entirely.

## 3. Wait for the review

One notification when it lands, not a poll that burns context. Background an `until` loop that exits on the condition, with `run_in_background: true` — the completion notification is the wake-up. Do **not** schedule a recurring cron; a one-minute cron re-reads the whole conversation every minute for an event that takes two to five minutes.

By default, wait for *anyone*: a review or comment from someone other than the author, newer than the last push. Get the timestamp first:

```bash
gh pr view {n} --json commits --jq '.commits[-1].committedDate'
```

Then substitute it for `{since}`:

```bash
until gh pr view {n} --json author,reviews,comments --jq '.author.login as $me | ([.reviews[] | select(.submittedAt > "{since}" and .author.login != $me)] + [.comments[] | select(.createdAt > "{since}" and .author.login != $me and (.author.login != "claude" or (.body | contains("Claude finished"))))]) | length > 0' | grep -qx true; do sleep 30; done
```

When the user named a reviewer, or several are pending and you want a specific one, narrow the condition to that login instead (see the table for which login to match). The loop exits on the first arrival; if others are still pending, say so and offer to wait again.

Details that will otherwise cost a debugging cycle:

- **`reviewDecision` stays empty** for all three known bots. Copilot and Bugbot submit as `COMMENTED`, and Claude submits no review at all. Only a human's `APPROVED` or `CHANGES_REQUESTED` sets it, so waiting on `reviewDecision` usually waits forever.
- **`latestReviews` returns an empty `id`.** Use `reviews` when you need the real review ID.
- **Claude posts its tracking comment immediately and edits it in place.** Its presence means *started*, not *finished* — hence the `Claude finished` match above rather than merely checking the author.
- **The PR author's own comments don't count** — that excludes the `@claude` trigger comment and the author's replies.

If the wait exceeds roughly ten minutes, report that rather than continuing silently. A human reviewer can take hours; when the pending reviewer is a person, say so and offer to stop waiting rather than holding a loop open.

## 4. Fetch everything

Fetch all three sources, then filter to the reviewers found in step 2. For the bots that leave a review object, the body is the less useful half.

```bash
# Review bodies (Copilot, Bugbot, humans, other bots)
gh pr view {n} --json reviews --jq '.reviews[] | {author: .author.login, state, body}'

# Inline comments — the actual findings for Copilot, Bugbot, and most humans
gh api repos/{owner}/{repo}/pulls/{n}/comments --jq '.[] | {id, user: .user.login, path, line, original_line, body}'

# PR comments — Claude's findings ARE its comment body; humans sometimes review here too
gh pr view {n} --json comments --jq '.comments[] | {author: .author.login, body}'
```

Keep the comment `id` values — they are what you reply to in step 7.

**`line` is frequently `null`** on Bugbot comments, and on any comment whose anchor has gone stale or spans a range. Fall back to `original_line`, then `start_line`, and if all are null name the file the finding concerns rather than inventing a line number.

**Reconcile the counts.** Bugbot's body states how many issues it found ("found 4 potential issues"); Copilot's states how many comments it generated. If that number does not match what the comments endpoint returns, say so — the gap is usually a finding that was filtered, and it is worth knowing one went missing.

Claude's inline comments, when it produces any, are buffered and posted after its session ends, so they can appear a beat after the comment body is final. A Claude review with no findings produces no inline comments at all, which is correct behavior and not a fetch failure.

**A human's comment is not always a finding.** Questions, approvals, and "nit:" remarks are all review content. Treat anything that claims something about the code, or asks for a change, as a finding; report questions as questions, with the answer if the code gives one.

## 5. Verify each finding — the actual work

For every finding, whoever wrote it, read the real code at that path and line. Then separate three questions that reviewers tend to conflate, because a single finding can get any subset of them wrong:

1. **Is the hazard real?**
2. **Is the diagnosis right?** A correct smell with a wrong mechanism is common.
3. **Would the proposed fix work?** Sometimes the suggested change is a no-op against the actual failure mode.

**Test claims that are testable.** A three-line script settles a language-behaviour claim faster and more reliably than reasoning about it. If the claim is "type X isn't orderable" or "this raises on empty input", run it.

**Establish reachability.** A hazard that no current input can trigger is worth hardening but is not a bug, and conflating the two wastes the author's time. Try to construct a failing input. If you cannot, say that plainly and say what future change would make it reachable.

**Watch for context-blind pattern matches.** Automated reviewers correct domain vocabulary that merely resembles a mistake — a URI *scheme* flagged as a misspelling of *schema* in a file full of JSON Schema, a deliberate shadowing read as an accident. Check what the word means in context before accepting the correction.

**Weigh the severity label, do not adopt it.** Bugbot stamps every finding Low/Medium/High. That label is its opinion about a claim you have not yet checked, and a Medium that turns out to be unreachable is not a Medium.

**A human's context is evidence too.** A person may know something the diff does not show — a production constraint, a past incident, a plan for this code. When a human finding rests on context you cannot check, say that rather than marking it wrong.

**Then ask what it missed.** Silence from a reviewer is not a clean bill of health. Against the diff, look for the things it structurally cannot see: unverified assumptions, behaviour that was never executed, config that will collide with something outside the diff, missing tests, whether the change actually does what the PR claims. This section is usually more valuable to the author than the findings themselves — and when a review returns zero findings it is the *only* thing of value, so do not skip it on a clean report.

**Note what the reviewer could not do.** Claude reports its own limits in its comment — it will say when it could not run the test suite or a linter because the sandbox denied the command. A review that is a static read is worth less than one backed by a run, and the author should be told which they got.

## 6. Report

Lead with the verdict — who reviewed, how many findings, how many survive scrutiny. Mention a reviewer that did not deliver only when it was expected (asked by the user, named in `CLAUDE.md`, requested on the PR, or summoned) and either failed or is still pending — coverage the author thinks they had is worse than coverage they know they lack. Do not list reviewers nobody asked for.

Then per finding, state the verdict and the evidence for it, quoting the specific check you ran when there was one. This applies to human findings exactly as to bot ones. Be direct about wrong findings; hedging on a false positive costs the author real time.

Close with what the review missed, ranked by what would actually hurt.

## 7. Follow-through — only when asked

Do not fix or reply unprompted. Posting to a PR is outward-facing and needs to be requested.

When asked to reply, address the finding's *substance*: what is right, what is wrong, and what you changed and why. Taking a fix while rejecting its reasoning is a legitimate and useful outcome — say both.

**Reply to a human as a colleague.** The verdict in your report is for the author; the reply is a conversation. Explain what you found and what changed, ask when their context might change the answer, and do not grade them.

```bash
# Inline comment (Copilot, Bugbot, humans): reply in the thread
gh api repos/{owner}/{repo}/pulls/{n}/comments/{comment_id}/replies -F body=@/tmp/reply.md

# PR-level review (Claude, or a human who commented on the PR): post a PR comment
gh pr comment {n} --body-file /tmp/reply.md
```

The PR number is required. `repos/{owner}/{repo}/pulls/comments/{comment_id}` is a valid path for *reading* a single review comment, so it looks plausible, but the `/replies` sub-resource only exists under the numbered form and the short version 404s.

Write the body with a file rather than inline shell quoting; review replies contain backticks and code fences that will not survive `-f body='...'`.

**Beware of re-triggering Claude.** A reply containing the literal at-mention of Claude, on a PR wired to a comment-triggered review workflow, starts another review. Refer to it as "the Claude review" in prose rather than mentioning it.

**State the push status.** If a fix is committed but not pushed, say so in the reply — otherwise it reads as a claim about code the reviewer cannot see.
