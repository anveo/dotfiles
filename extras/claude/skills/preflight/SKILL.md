---
name: preflight
description: Orient at the start of work on a ticketed branch — resolve the Linear issue from the branch or worktree name, read it and everything hanging off it, check what the branch has already done, then brief and interrogate before any code is written. Use when starting or resuming work on a branch, or when asked to "get up to speed", "what's this branch about", "read the ticket", "preflight", or "brief me".
---

# preflight

A preflight is the check you run *before* committing to the roll — the point at which finding a problem is still cheap. That is the job here: arrive at a branch, work out what it is supposed to accomplish, work out what is already true, and surface every gap while it still costs a question instead of a rewrite.

**The failure mode this skill exists to prevent is starting work on the ticket you assume you were handed.** A Linear issue is a snapshot of what someone knew when they wrote it. Comments override it, related issues constrain it, and the branch may already contain half of it. Read all of that before deciding anything.

Preflight ends at a plan. It does not write code.

## 1. Resolve the issue

If the user passed an identifier (`/preflight APP-218`), use it and skip ahead.

Otherwise derive it from where you are. Check **both** the branch and the working directory — a worktree directory and its branch usually agree, but not always:

```bash
git rev-parse --abbrev-ref HEAD
pwd
```

Match a three-or-so-letter prefix followed by a number, **case-insensitively**. Branches here appear as both `app-218-…` and `APP-218-…`; Linear identifiers are always uppercase, so normalize before looking anything up.

**Match on the prefix and number only — never the slug.** Linear hands out a `gitBranchName` like `app-218-adopt-default_tags-on-terraform-managed-aws-resources`, and the branch actually in use is routinely a hand-shortened `APP-218-terraform-tags`. Comparing slugs will tell you the branch does not belong to the issue when it plainly does.

If there is no identifier anywhere (you are on `main`, or the branch is named for its content), say so and offer two ways forward: take an identifier as an argument, or list the user's assigned issues that are in progress or selected for development and ask which one. Do not guess from the diff.

## 2. Read the issue and everything hanging off it

The Linear tools are namespaced per workspace — `mcp__linear-monicur__get_issue`, not `mcp__linear__get_issue` — so discover them rather than assuming the name:

```
ToolSearch: "linear get issue comments"
```

Fetch in one round: the issue itself with relations, and its comments.

```
get_issue(id: "APP-218", includeRelations: true)
list_comments(issueId: "APP-218")
```

Three things routinely get missed here, each of which can invalidate the plan you were about to write:

- **`includeRelations` defaults to false.** Blocked-by, blocks, and related issues are where the real constraints live. APP-218's entire scope exists because it was split out of APP-210 and deliberately deferred; the description says so, but the relation is what proves it is now unblocked.
- **Comments are a separate call, and they win.** A decision made in a comment three weeks after the description was written is the current state of the ticket. If a comment contradicts the description, the comment is the ticket.
- **Descriptions embed real links.** Inline `<issue id="…" href="…">APP-210</issue>` markup and attachment URLs point at documents, PRs, and sibling issues. Follow the ones the description leans on. Do not fetch the entire graph — one hop from anything load-bearing.

Note `updatedAt`. An issue that has not been touched in months, against a codebase that has, is a stale-premise risk to raise in step 5 — not a reason to stop.

## 3. Establish what is already true

The issue says what should happen. Git says what has happened. The gap between them is the actual work, and on a resumed branch it can be most of the ticket.

```bash
git log --oneline main..HEAD
git status --short
git log --oneline -1 main
gh pr view --json number,title,url,state,isDraft,reviewDecision
```

What to take from each:

- **Commits on the branch** mean you are resuming. Read them. Half-finished work that you re-do from scratch is worse than no work.
- **Divergence from `main`.** If the branch is well behind, say how far and whether anything it touches has moved underneath it.
- **An open PR** changes the shape of the task from "build it" to "finish it." If the PR has a review pending or in, hand off to the `crosscheck` skill rather than duplicating it.
- A Linear status of *Selected for Development* on a branch with commits is not a contradiction — it just means nobody moved the ticket. Trust git.

## 4. Read the code the issue names

The issue names files, resources, or functions. Read them — actually read them, do not infer from the name. The single most common preflight failure is briefing confidently on code that does not say what the ticket claims it says.

If the repo has a skill covering the issue's area, load it now rather than rediscovering the domain by grep.

## 5. Brief

Short, and in this order:

1. **What the issue asks for**, in a sentence or two of your own words — not a paraphrase of the description, a statement of the goal.
2. **What is already done**, from step 3. Explicitly "nothing yet" when that is the answer.
3. **What the code actually looks like** where it disagrees with, or adds detail to, the ticket.
4. **What the issue says success looks like.** Most well-written tickets state a verification step; quote it, because it is the definition of done and it is easy to skim past.

Lead with the verdict — starting fresh, or resuming at what point.

## 6. Interrogate

This is the point of the skill. Ask what would **change the work**, and nothing else.

Do not ask what the repository can answer — go read it. Do not ask the user to confirm a decision any careful engineer would make the same way. Both are ways of returning the work to the person who delegated it.

Do ask about:

- **Assumptions the issue makes but does not state** — a value, a naming choice, an environment, an ordering.
- **Stale premises** — the ticket was written against a world that has since moved.
- **Scope boundaries** — what is deliberately out, especially where a related issue owns the adjacent piece.
- **Behavior changes** hiding inside something framed as cleanup.
- **Verification**, when the ticket does not say how anyone will know it worked.

Format: plain `1.` `2.` `3.`, no circled numerals. Terse — sacrifice grammar for concision. Three to six questions, ranked by how much the answer changes what you build. If a question has an obvious default, state the default in it so it can be answered by silence.

**If you genuinely have no questions, say so.** A manufactured question is worse than none; it trains the user to skim.

## 7. Write the preflight back to the issue

The preflight just produced the context the ticket was missing. That context currently exists only in a terminal session nobody else can open, and it evaporates when the session ends. Put it on the issue.

**Always offer this. Do it without asking only when the description is empty** — there is nothing to overwrite, so the only risk is that the issue becomes more useful. When a description already exists, say what you would change and wait; the wording may be deliberate, and rewriting someone's ticket under them is not yours to decide.

What belongs in the updated description:

- **The goal**, stated plainly — what "done" means, not a transcript of how you worked it out.
- **What the code actually turned out to be**, where step 4 disagreed with or added detail to the ticket. This is usually the highest-value part: it is the finding that cost the most to establish and is cheapest to lose.
- **The decisions from step 6** — the question and the answer, folded into prose. "Surgical lockfile edit rather than blanket `yarn upgrade`, because there is no CI to catch churn" is worth more in six months than either half alone.
- **Scope boundaries**, explicitly, including anything deliberately carded off into another issue. Link the issue you cut.
- **Verification** — how anyone will know it worked.

Write it per the user's shared-artifact style: flowing prose for humans, load-bearing specifics (exact commands, versions, file paths, identifiers) kept explicit for agents. Self-contained — the author should be able to read it cold six months later without this conversation. Do not paste the Q&A as a numbered list, and do not include the parts of the brief that git already records.

Prefer editing the description over adding a comment. A comment is a good place for a decision that arrives *later*; the preflight is the ticket's own premise, and it belongs where someone reads first. `save_issue(id: "APP-225", description: "…")` replaces the description wholesale, so compose the full replacement text rather than a fragment.

If the interrogation also produced work that is out of scope, create those issues now, while the reasoning is still in hand — and link them from the description you just wrote.

## 8. Then, and only then

Once the questions are answered and the issue is current, **enter plan mode** with the answers folded in, using `EnterPlanMode`. The brief plus the answers is the input to the plan; do not restate them at length inside it.

Leave the Linear status alone. `takeoff` moves the issue to In Progress when work actually starts — a briefing is not a commitment to build, and two skills offering the same outward-facing change trains the user to skim the prompt. (When `dispatch` is driving, it also asks you to skip plan mode: the brief and the questions are the handoff artifact, and a plan-mode gate would park every parallel runway on an approval prompt.)

Do not begin implementing from within preflight, even when the work looks trivial. The whole value of the checklist is that it finishes before the roll starts.
