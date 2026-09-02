---
name: crosscheck
description: Wait for automated code review on a pull request — Copilot, Cursor Bugbot, or Claude — then independently verify every finding against the actual code and report which ones hold up. Use when a PR has been opened and a review is pending or in, or when asked to "wait for Copilot", "check the Bugbot review", "what do you think of the review", or to triage automated review comments. Verifies claims rather than relaying them.
---

# crosscheck

A cockpit crosscheck is one crew member independently verifying another's work before anyone commits to it. That is the job here. An automated review is an input to be checked, not a result to be relayed — in practice a meaningful share of findings are real hazards with wrong diagnoses, or confident corrections that are simply wrong.

**The failure mode this skill exists to prevent is relaying a finding you have not verified.** If you cannot check a claim, say so explicitly rather than passing it along with implied endorsement.

## The three reviewers

They differ in every mechanical detail — how they are summoned, where their output lands, and what login owns it. Read this table before writing any query; guessing a login is the single most common way to conclude "no review arrived" when one is sitting on the page.

| | **Copilot** | **Cursor Bugbot** | **Claude** |
|---|---|---|---|
| Summoned by | Requesting it as a reviewer | Runs automatically on push | Commenting `@claude` on the PR |
| Review object | yes, `state: COMMENTED` | yes, `state: COMMENTED` | **none** — `reviews` is `[]` |
| Review author login | `copilot-pull-request-reviewer` | `cursor` | *n/a* |
| Inline comment login | `Copilot` | `cursor[bot]` | `claude[bot]` |
| Findings live in | inline comments | inline comments | the issue comment body |
| Body marker | per-file summary table | `<!-- BUGBOT_REVIEW -->` | `**Claude finished @user's task**` |

**The review author and the inline-comment user are different logins for every bot.** Copilot reviews as `copilot-pull-request-reviewer` but its comments are owned by `Copilot`; Bugbot reviews as `cursor` but comments as `cursor[bot]`. Matching the review login against the comments endpoint returns nothing and looks exactly like a review with no findings.

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

Do this *before* waiting, or you will wait forever on a review that was never coming. Two calls cover all three:

```bash
gh pr view {n} --json reviews,comments --jq '{reviews: [.reviews[] | {author: .author.login, state}], comments: [.comments[] | {author: .author.login, at: .createdAt}]}'
gh api repos/{owner}/{repo}/pulls/{n}/requested_reviewers
```

Copilot appears in `requested_reviewers` as login `Copilot`, `"type": "Bot"`. A completed review removes the request, so absent-and-not-reviewed means it was never asked — stop and offer to request it. Bugbot and Claude never appear there at all; their absence proves nothing.

**Check Bugbot actually ran.** It posts a comment on failure rather than staying silent, and the failure reads as ordinary output:

> ### Bugbot couldn't run - usage limit reached

Treat that as *did not review*, never as *found nothing*. Say so in the report — a quota-exhausted Bugbot is a gap in coverage the author should know about, and it is the normal state late in a billing week. If Bugbot is out and Copilot is absent, a Claude review is the remaining option, but summoning one is outward-facing: offer, do not do it unasked.

## 3. Wait for the review

One notification when it lands, not a poll that burns context. Background an `until` loop that exits on the condition, matching whichever reviewer you are actually waiting for:

```bash
# Copilot or Bugbot — both produce a review object
until [ "$(gh pr view {n} --json reviews --jq '[.reviews[] | select(.author.login == "copilot-pull-request-reviewer" or .author.login == "cursor")] | length')" -gt 0 ]; do sleep 30; done

# Claude — no review object; watch for its comment instead
until gh pr view {n} --json comments --jq '.comments[] | select(.author.login == "claude") | .body' | grep -q "Claude finished"; do sleep 30; done
```

Run with `run_in_background: true` — the completion notification is the wake-up. Do **not** schedule a recurring cron; a one-minute cron re-reads the whole conversation every minute for an event that takes two to five minutes.

Details that will otherwise cost a debugging cycle:

- **`reviewDecision` stays empty** for all three. Copilot and Bugbot submit as `COMMENTED`, and Claude submits no review at all. Waiting on `reviewDecision` waits forever.
- **`latestReviews` returns an empty `id`.** Use `reviews` when you need the real review ID.
- **Claude posts its tracking comment immediately and edits it in place.** Its presence means *started*, not *finished* — hence the `Claude finished` match above rather than merely checking the author.

If the wait exceeds roughly ten minutes, report that rather than continuing silently.

## 4. Fetch everything

Where the findings live differs by reviewer, and for Copilot and Bugbot the body is the less useful half.

```bash
# Copilot / Bugbot: body for the summary, comments endpoint for the actual findings
gh pr view {n} --json reviews --jq '.reviews[] | select(.author.login == "copilot-pull-request-reviewer" or .author.login == "cursor") | .body'
gh api repos/{owner}/{repo}/pulls/{n}/comments --jq '.[] | {id, user: .user.login, path, line, original_line, body}'

# Claude: the findings ARE the comment body
gh pr view {n} --json comments --jq '.comments[] | select(.author.login == "claude") | .body'
```

Keep the comment `id` values — they are what you reply to in step 7.

**`line` is frequently `null`** on Bugbot comments, and on any comment whose anchor has gone stale or spans a range. Fall back to `original_line`, then `start_line`, and if all are null name the file the finding concerns rather than inventing a line number.

**Reconcile the counts.** Bugbot's body states how many issues it found ("found 4 potential issues"); Copilot's states how many comments it generated. If that number does not match what the comments endpoint returns, say so — the gap is usually a finding that was filtered, and it is worth knowing one went missing.

Claude's inline comments, when it produces any, are buffered and posted after its session ends, so they can appear a beat after the comment body is final. A Claude review with no findings produces no inline comments at all, which is correct behavior and not a fetch failure.

## 5. Verify each finding — the actual work

For every finding, read the real code at that path and line. Then separate three questions that automated reviewers tend to conflate, because a single finding can get any subset of them wrong:

1. **Is the hazard real?**
2. **Is the diagnosis right?** A correct smell with a wrong mechanism is common.
3. **Would the proposed fix work?** Sometimes the suggested change is a no-op against the actual failure mode.

**Test claims that are testable.** A three-line script settles a language-behaviour claim faster and more reliably than reasoning about it. If the claim is "type X isn't orderable" or "this raises on empty input", run it.

**Establish reachability.** A hazard that no current input can trigger is worth hardening but is not a bug, and conflating the two wastes the author's time. Try to construct a failing input. If you cannot, say that plainly and say what future change would make it reachable.

**Watch for context-blind pattern matches.** Automated reviewers correct domain vocabulary that merely resembles a mistake — a URI *scheme* flagged as a misspelling of *schema* in a file full of JSON Schema, a deliberate shadowing read as an accident. Check what the word means in context before accepting the correction.

**Weigh the severity label, do not adopt it.** Bugbot stamps every finding Low/Medium/High. That label is its opinion about a claim you have not yet checked, and a Medium that turns out to be unreachable is not a Medium.

**Then ask what it missed.** Silence from an automated reviewer is not a clean bill of health. Against the diff, look for the things it structurally cannot see: unverified assumptions, behaviour that was never executed, config that will collide with something outside the diff, missing tests, whether the change actually does what the PR claims. This section is usually more valuable to the author than the findings themselves — and when a review returns zero findings it is the *only* thing of value, so do not skip it on a clean report.

**Note what the reviewer could not do.** Claude reports its own limits in its comment — it will say when it could not run the test suite or a linter because the sandbox denied the command. A review that is a static read is worth less than one backed by a run, and the author should be told which they got.

## 6. Report

Lead with the verdict — who reviewed, how many findings, how many survive scrutiny. Name any reviewer that did not run and why, since coverage the author thinks they had is worse than coverage they know they lack.

Then per finding, state the verdict and the evidence for it, quoting the specific check you ran when there was one. Be direct about wrong findings; hedging on a false positive costs the author real time.

Close with what the review missed, ranked by what would actually hurt.

## 7. Follow-through — only when asked

Do not fix or reply unprompted. Posting to a PR is outward-facing and needs to be requested.

When asked to reply, address the finding's *substance*: what is right, what is wrong, and what you changed and why. Taking a fix while rejecting its reasoning is a legitimate and useful outcome — say both.

```bash
# Copilot / Bugbot: reply in the inline thread
gh api repos/{owner}/{repo}/pulls/{n}/comments/{comment_id}/replies -F body=@/tmp/reply.md

# Claude: no inline thread to reply into — post a PR comment
gh pr comment {n} --body-file /tmp/reply.md
```

The PR number is required. `repos/{owner}/{repo}/pulls/comments/{comment_id}` is a valid path for *reading* a single review comment, so it looks plausible, but the `/replies` sub-resource only exists under the numbered form and the short version 404s.

Write the body with a file rather than inline shell quoting; review replies contain backticks and code fences that will not survive `-f body='...'`.

**Beware of re-triggering Claude.** A reply containing the literal at-mention of Claude, on a PR wired to a comment-triggered review workflow, starts another review. Refer to it as "the Claude review" in prose rather than mentioning it.

**State the push status.** If a fix is committed but not pushed, say so in the reply — otherwise it reads as a claim about code the reviewer cannot see.
