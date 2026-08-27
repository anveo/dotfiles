---
name: dispatch
description: Prepare one or more Linear issues for work — create and provision a worktree for each, read the ticket and the code it names, and report a brief plus the questions that need answering. Stops before any code is written. Use when starting work on an issue by identifier, or when asked to "dispatch DOT-26", "set up these issues", "prepare a worktree for", or "get these ready to work on".
---

# dispatch

A dispatcher plans the flight and issues its release; nothing rolls without one. That is this skill: turn an issue identifier into a provisioned worktree with a briefed pilot, then hand over. It is the front half of the lifecycle run end to end, and it is built to do several at once.

**The failure mode this skill exists to prevent is the half-prepared runway** — work that begins in a worktree nobody provisioned, on a ticket nobody read past the title, because the setup was tedious and done by hand. That failure compounds with parallelism: by the third worktree you have forgotten what the first one was for.

Dispatch writes no code and moves no tickets. It ends at a brief and a question list, which is exactly where `takeoff` begins.

Where this sits: **dispatch** prepares → `takeoff` builds → `approach` submits → `crosscheck` verifies the review → `land` merges. `preflight` is the reading half of dispatch, and stays useful on its own when you are already standing in a branch.

## 1. Resolve the target

The identifier says *what*; the working directory says *where*. A `DOT-` issue may be work in the dotfiles repo or in an application repo — the ticket prefix will not tell you, so dispatch operates on the repo you invoke it from.

```bash
git rev-parse --show-toplevel
```

Stop if that fails, or if the current directory is a linked worktree — dispatch creates worktrees and should run from the main checkout. Take one or more identifiers (`/dispatch DOT-26`, `/dispatch DOT-26 DOT-31 DOT-33`); with none, list the user's assigned issues in progress or selected for development and ask which.

## 2. Name the branch

Fetch each issue (the Linear tools are namespaced per workspace — `ToolSearch: "linear get issue"` rather than assuming) and derive a branch as `<KEY>-<short-slug>`: the uppercase identifier, then two to four words from the title.

Use Linear's `gitBranchName` as raw material, **not verbatim** — it is a long, user-prefixed slug (`anveo/dot-26-start-issue-compose-the-lifecycle-skills-into-…`) and the convention here is the hand-shortened form (`DOT-26-dispatch-skill`). This is safe because `preflight` matches on the key and number only, never the slug, so a shortened branch still resolves to its issue. Keep it short for a second reason: the worktree slug drives hostnames and database names downstream.

If the branch or its worktree already exists, reuse it and say so. Dispatch is idempotent; a re-run on a prepared issue re-briefs rather than failing.

## 3. Build the runway

```bash
source "$HOME/dotfiles/bash/functions"   # see below — do not skip this
wta -w <branch>
```

**The `source` is load-bearing.** Claude Code's Bash tool loads shell functions from a snapshot taken when the session started, so a session that began before the last dotfiles change is holding a stale `wta` — and the failure is silent rather than loud: an older copy has no `-w`, so it either errors or treats the flag as a branch name. Sourcing the file first guarantees the current definitions of `wta`, `wtr`, and `wtinfo` regardless of session age.

`wta` creates `<repo>.worktrees/<branch>`, copies the gitignored files a bare `git worktree add` leaves behind, runs `direnv allow`, and — this is the part that matters — runs the repo's `bin/worktree-setup` when it exists, which is what assigns ports, hostname, and database.

**The `-w` is not optional here.** Bare `wta` is the interactive one-at-a-time form: it `cd`s the current shell into the worktree and renames the window. Run that once per issue and you rename the window you are standing in N times, ending up in whichever worktree came last. `-w` instead gives each worktree its own detached tmux window named for the ticket, and leaves your shell where it is. Outside tmux it just prepares the worktree and says so.

That window is what makes parallel work supervisable: it is addressable by name, so `tmux capture-pane -t =DOT-26 -p` reads an agent's state without switching to it, `bind w` lists every prepared runway, and every pane opened there inherits the right directory (and therefore the right `.envrc.worktree`). Each window opens on `wtinfo`, which prints what provisioning assigned.

Do **not** substitute the Agent tool's own worktree isolation for this. It creates a bare worktree and skips the repo's provisioning entirely, which produces a checkout that looks fine and cannot serve a request.

Report what provisioning chose (the app URL, the ports, the database mode) — it is the first thing anyone needs and the last thing they will think to ask for.

## 4. Read the ticket

Run `preflight` for the issue, from inside its worktree, with two changes:

- **Pass the identifier explicitly.** Dispatch already resolved it; do not make preflight re-derive it from the branch.
- **Stop after the interrogation.** Preflight normally ends in plan mode; here the brief and the questions *are* the artifact, and a plan-mode gate would park every parallel runway on an approval prompt. Skip it.

Everything else about preflight applies and is the reason this step is not hand-rolled: relations and comments override the description, the code it names gets read rather than inferred, and the enriched context gets written back to the issue so it outlives the session.

**Several issues at once:** fan the reading out, one subagent per issue, each returning its brief and questions. The worktrees are already isolated, so the reads do not interfere. Create the worktrees first, in sequence — `wta` and `bin/worktree-setup` touch shared state (the traefik config directory, the port scan, the database server) and racing them invites collisions.

## 5. Report the batch

One block per issue, in the order given:

- **Where it is** — worktree path, branch, tmux window name, and what provisioning assigned (`wtinfo`'s output: URL, ports, database mode).
- **The brief** — preflight's, unedited: what the issue asks, what is already done, where the code disagrees with the ticket, what success looks like.
- **The questions**, numbered, ranked by how much the answer changes the work.
- **Anything already blocking** — a stale premise, an unmet dependency, a red baseline noticed in passing.

Then stop. Say plainly that no code has been written and no tickets have moved, and that answering the questions is what releases each flight.

## 6. Handoff

Work begins with `takeoff` in the chosen worktree, which is where the questions get folded in, the environment gets verified, the baseline gets captured, and the ticket moves to In Progress. Dispatch deliberately leaves all four alone: a prepared runway is not a commitment to fly, and half of these worktrees may be torn down unused.

That teardown is `wtr <branch>` — it runs the repo's `bin/worktree-teardown` first, so routes and cloned databases go with it, and closes the ticket's tmux window. Mention it when a dispatched issue turns out to be a non-starter; an abandoned worktree is cheap to remove and expensive to rediscover in a month.
