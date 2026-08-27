---
name: takeoff
description: Begin implementation after a preflight briefing — settle the open questions, verify the environment, capture a green test baseline, move the ticket to In Progress, then build to the agreed plan. Use when the briefing is done and it is time to write code, or when asked to "get started", "start coding", "begin implementation", or "cleared for takeoff".
---

# takeoff

Takeoff is the moment the flight commits to the runway. `preflight` ended in a plan and questions; `approach` expects finished work. Between them, work actually starts — and "ok, get started" carries none of the checks that make the start safe. This skill is those checks, then the work.

**The failure mode this skill exists to prevent is starting on assumption** — building on an environment nobody verified, against a plan whose open questions were never answered, on top of a test suite that was already red. Every one of those is checkable in the first five minutes and unattributable after the first hour.

Where this sits in the pattern: `preflight` orients (or `dispatch` does it across several issues at once, worktrees and all), `takeoff` begins the work, `approach` submits it, `crosscheck` verifies the review, `land` merges.

## 1. Line-up check — settle the briefing

Start from preflight's output: the plan and its unresolved questions. Every question that blocks the plan gets an answer from the user or an explicit "deferred — doesn't block" before any code. Do not infer answers from silence; a question preflight thought worth asking is worth an answer.

Then restate the agreed plan as the working todo list, and **name what is out of scope**. The out-of-scope list is the more valuable half: mid-flight scope creep arrives disguised as "while I'm in here", and a written boundary turns it from a silent absorption into a flagged decision.

If there was no preflight — the user is starting cold — say so and run the short form: read the ticket, confirm the intent in two sentences, and get a nod before rolling. Takeoff without any briefing is how the wrong thing gets built efficiently.

## 2. The runup — verify the environment

Every item here is a query, not a guess:

- **Right branch or worktree for the ticket.** The branch name carries the issue key — that is what lets `preflight` and `land` resolve it later. If the work belongs in a fresh worktree, `wta <branch>` creates and provisions it (ports, hostname, database — the repo's `bin/worktree-setup` handles the specifics).
- **Environment loads.** direnv active (`direnv exec .` for commands), dependencies current (`bundle check` or the repo's equivalent), migrations applied. In a worktree: `.envrc.worktree` exists — its absence means setup never ran.
- **A green baseline.** Run the spec subset closest to the planned work — or the repo's designated target (`make claude-test` here) — *before the first edit*, and record the result. This is the item that pays for the whole skill: a failure found now is provably pre-existing; the same failure found mid-work is a debugging detour through code you did not break. A red baseline in the area you are about to change is a stop — report it, do not build on it.

## 3. Open the ticket

Move the Linear issue to In Progress (`save_issue`), and assign it if unassigned. This is the state transition the GitHub integration never covers — it fires on PRs, not on intent — so takeoff is where the board starts telling the truth. `preflight` and `dispatch` deliberately leave the status alone, so this is the only place it happens; do it without asking, since by this point the user has committed to the work.

## 4. Fly the plan

Implement to the todo list, running the relevant specs as you go. Two rules:

- **Do not commit.** The working tree stays uncommitted for `approach`, which reads the whole tree and cuts the logical series at the end. Checkpoint commits along the way hand approach a half-built history it has to fight.
- **Deviations split by size.** When the code contradicts the plan on a detail, note it and continue — the report at the end names every deviation. When it contradicts the plan's *core assumption*, that is a rejected takeoff (below), not a license to improvise.

## 5. Report readiness

Takeoff ends when the todo list is done and the suite is green: summarize what was built against what was planned, name every deviation and anything discovered but deliberately not done, and stop. `approach` is a separate invocation — the pause between them is where the user reads the diff.

## Rejected takeoff

The abort criteria are decided before rolling, which is what makes aborting cheap:

- The plan's core assumption turns out false on first contact with the code.
- The baseline is red in the code being changed.
- A blocking question surfaces mid-work that only the user can answer.

The move is to stop and re-brief: state exactly what invalidated the plan, with the evidence, and go back to preflight territory. Do not silently replan and present the new plan as if it were the old one — a go-around costs one circuit; discovering after merge that the plan changed mid-flight costs trust in every future briefing.
