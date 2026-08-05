---
name: crosscheck
description: Wait for GitHub Copilot's review on a pull request, independently verify every finding against the actual code, and report which ones hold up. Use when a PR has been opened and Copilot's review is pending or in, or when asked to "wait for Copilot", "check the Copilot review", "what do you think of the review", or to triage automated review comments. Verifies claims rather than relaying them.
---

# crosscheck

A cockpit crosscheck is one crew member independently verifying another's work before anyone commits to it. That is the job here. Copilot's review is an input to be checked, not a result to be relayed — in practice a meaningful share of its findings are real hazards with wrong diagnoses, or confident corrections that are simply wrong.

**The failure mode this skill exists to prevent is relaying a finding you have not verified.** If you cannot check a claim, say so explicitly rather than passing it along with implied endorsement.

## 1. Resolve the PR

Use the number if given. Otherwise find the PR for the current branch:

```bash
gh pr view --json number,title,url,headRefName,baseRefName,additions,deletions
```

If there is no PR for the branch, stop and say so. Capture the repo once for the API calls:

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

## 2. Confirm Copilot was actually requested

Do this *before* waiting, or you will wait forever on a review that was never coming:

```bash
gh api repos/{owner}/{repo}/pulls/{n}/requested_reviewers
```

Copilot appears here as a user with login `Copilot` and `"type": "Bot"`. If it is absent, check whether it already reviewed (step 4) — a completed review removes the request. If it neither reviewed nor is pending, stop and offer to request it. Do not request a review without being asked; it is an outward-facing action.

## 3. Wait for the review

One notification when it lands, not a poll that burns context. Background an `until` loop that exits on the condition:

```bash
until [ "$(gh pr view {n} --json reviews --jq '[.reviews[] | select(.author.login == "copilot-pull-request-reviewer")] | length')" -gt 0 ]; do sleep 30; done
```

Run this with `run_in_background: true` — the completion notification is the wake-up. Do **not** schedule a recurring cron for this; a one-minute cron re-reads the whole conversation every minute for an event that typically takes two to five minutes.

Three details that will otherwise cost you a debugging cycle:

- The review author login is **`copilot-pull-request-reviewer`**, even though the *requested reviewer* is listed as `Copilot`. Matching on `Copilot` finds nothing.
- Copilot submits with `state: COMMENTED`, so **`reviewDecision` stays empty**. Waiting on `reviewDecision` waits forever.
- `latestReviews` returns an empty `id`. Use `reviews` when you need the real review ID.

If the wait exceeds roughly ten minutes, report that rather than continuing silently.

## 4. Fetch everything

The review body and the inline comments come from different places, and the body is the less useful half — it is mostly a per-file summary table. The actual findings are inline:

```bash
gh pr view {n} --json reviews --jq '.reviews[] | select(.author.login == "copilot-pull-request-reviewer") | .body'
gh api repos/{owner}/{repo}/pulls/{n}/comments --jq '.[] | {id, path, line, body}'
```

Keep the comment `id` values — they are what you reply to in step 7. The review body states how many comments it generated; if that count does not match what the comments endpoint returns, say so.

## 5. Verify each finding — the actual work

For every finding, read the real code at that path and line. Then separate three questions that Copilot tends to conflate, because a single finding can get any subset of them wrong:

1. **Is the hazard real?**
2. **Is the diagnosis right?** A correct smell with a wrong mechanism is common.
3. **Would the proposed fix work?** Sometimes the suggested change is a no-op against the actual failure mode.

**Test claims that are testable.** A three-line script settles a language-behaviour claim faster and more reliably than reasoning about it. If the claim is "type X isn't orderable" or "this raises on empty input", run it.

**Establish reachability.** A hazard that no current input can trigger is worth hardening but is not a bug, and conflating the two wastes the author's time. Try to construct a failing input. If you cannot, say that plainly and say what future change would make it reachable.

**Watch for context-blind pattern matches.** Automated reviewers correct domain vocabulary that merely resembles a mistake — a URI *scheme* flagged as a misspelling of *schema* in a file full of JSON Schema, a deliberate shadowing read as an accident. Check what the word means in context before accepting the correction.

**Then ask what it missed.** Silence from an automated reviewer is not a clean bill of health. Against the diff, look for the things it structurally cannot see: unverified assumptions, behaviour that was never executed, config that will collide with something outside the diff, missing tests, whether the change actually does what the PR claims. This section is usually more valuable to the author than the findings themselves.

## 6. Report

Lead with the verdict — how many findings, how many survive scrutiny. Then per finding, state the verdict and the evidence for it, quoting the specific check you ran when there was one. Be direct about wrong findings; hedging on a false positive costs the author real time.

Close with what the review missed, ranked by what would actually hurt.

## 7. Follow-through — only when asked

Do not fix or reply unprompted. Posting to a PR is outward-facing and needs to be requested.

When asked to reply, address the finding's *substance*: what is right, what is wrong, and what you changed and why. Taking a fix while rejecting its reasoning is a legitimate and useful outcome — say both. Reply to the specific thread:

```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies -F body=@/tmp/reply.md
```

Write the body with a file rather than inline shell quoting; review replies contain backticks and code fences that will not survive `-f body='...'`.

**State the push status.** If a fix is committed but not pushed, say so in the reply — otherwise it reads as a claim about code the reviewer cannot see.
