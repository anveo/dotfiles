---
name: dispatch
description: Prepare one or more Linear issues for work — create a branch for each (in a provisioned worktree where the repo asks for one, or where --worktree forces it), read the ticket and the code it names, and report a brief plus the questions that need answering. Stops before any code is written. Use when starting work on an issue by identifier, or when asked to "dispatch DOT-26", "set up these issues", "prepare a worktree for", or "get these ready to work on". Accepts --worktree / --branch to override the repo's default mode, and --db reuse|clone to pick the worktree's database.
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

Then ask the repo whether it wants a worktree at all:

```bash
test -x bin/worktree-setup && echo worktree || echo branch
```

That script is what assigns ports, hostname, and database to a new checkout, so its presence is the repo's own statement that parallel checkouts buy something here. Without it — a dotfiles repo, a docs repo, anything with no per-checkout state to isolate — dispatch runs in **branch mode**: the branch gets created in place and step 3 is skipped entirely. The test is `-x` rather than `-f` because `wta` runs the script only when it is executable; keying on the same bit keeps the two from ever disagreeing about which mode a repo is in. A repo that wants isolated checkouts but has nothing to provision opts in with an executable empty file.

Branch mode is not merely worktrees-being-unnecessary. Where a repo's files are symlinked into a live environment — an editor config into `~/.config`, a shell rc into `$HOME` — a worktree is actively wrong: edits land in a copy nothing is reading, and the change appears to have no effect.

It is also single-issue by construction, since one checkout holds one branch. Given several identifiers in branch mode, say so and ask which one to take.

**Overriding the default.** `--worktree` and `--branch` force a mode for the whole invocation and beat the `bin/worktree-setup` test. Both at once is an error — ask which was meant. The flags are positional-agnostic (`/dispatch --worktree DOT-30` and `/dispatch DOT-30 --worktree` are the same), and anything that is not a flag is an identifier.

`--worktree` on a repo that would auto-detect branch mode is the one that earns its keep. Branch mode assumes the live checkout is free, and sometimes it is not: a long-running branch mid-test, a bisect, a config you are actively living in and do not want disturbed. Forcing a worktree buys a second issue somewhere to happen that cannot perturb any of it.

In a symlinked repo that inverts the warning above rather than contradicting it. Edits in the forced worktree are inert — nothing is reading them, because the symlinks still point at the live checkout — and here that is the point, not the bug: it is what lets a config change be eyeballed, diffed, and approved before it takes effect anywhere. **Say this in the report.** Someone who forgets is going to edit a shell rc, open a new shell, see no change, and lose an hour to it. Nothing about the change reaches the live environment until the branch is merged into the checkout the symlinks point at.

`--branch` on a provisioning repo is the cheaper direction: skip ports, hostname, and database for a change that needs none of them — a README line, a comment fix, a version bump. It inherits branch mode's single-issue rule.

**Choosing the database.** `--db reuse|clone` relays straight through to the repo's `bin/worktree-setup`, which is what makes the choice without stopping to ask. Non-interactive setup defaults to `reuse` — the right answer nearly always, since a worktree that only reads the dev database wants the data that is already in it. Reach for `--db clone` when the branch will *write*: a destructive migration, a backfill, a seed rewrite — anything you would not want landing in the database the main checkout is pointed at. It applies to every issue in the invocation, and it is ignored on a re-run, where the mode already recorded in `.envrc.worktree` wins. In branch mode there is no provisioning to configure, so passing it there is an error worth naming rather than dropping.

## 2. Name the branch

Fetch each issue (the Linear tools are namespaced per workspace — `ToolSearch: "linear get issue"` rather than assuming) and derive a branch as `<KEY>-<short-slug>`: the uppercase identifier, then two to four words from the title.

Use Linear's `gitBranchName` as raw material, **not verbatim** — it is a long, user-prefixed slug (`anveo/dot-26-start-issue-compose-the-lifecycle-skills-into-…`) and the convention here is the hand-shortened form (`DOT-26-dispatch-skill`). This is safe because `preflight` matches on the key and number only, never the slug, so a shortened branch still resolves to its issue. Keep it short for a second reason: the worktree slug drives hostnames and database names downstream.

If the branch or its worktree already exists, reuse it and say so. Dispatch is idempotent; a re-run on a prepared issue re-briefs rather than failing.

## 3. Build the runway

**Worktree mode only.** In branch mode this whole step is `git switch -c <branch>` from the checkout you are standing in — no window, no provisioning, nothing to report. Go to step 4.

```bash
source "$HOME/dotfiles/bash/functions"   # see below — do not skip this
wta -w <branch>                          # add --db clone when the ticket asked for it
```

**The `source` is load-bearing.** Claude Code's Bash tool loads shell functions from a snapshot taken when the session started, so a session that began before the last dotfiles change is holding a stale `wta` — and the failure is silent rather than loud: an older copy has no `-w`, so it either errors or treats the flag as a branch name. Sourcing the file first guarantees the current definitions of `wta`, `wtr`, and `wtinfo` regardless of session age.

`wta` creates `<repo>.worktrees/<branch>`, copies the gitignored files a bare `git worktree add` leaves behind, runs `direnv allow`, and — this is the part that matters — runs the repo's `bin/worktree-setup` when it exists, which is what assigns ports, hostname, and database.

**The `-w` is not optional here.** Bare `wta` is the interactive one-at-a-time form: it `cd`s the current shell into the worktree and renames the window. Run that once per issue and you rename the window you are standing in N times, ending up in whichever worktree came last. `-w` instead gives each worktree its own detached tmux window named for the ticket, and leaves your shell where it is. Outside tmux it just prepares the worktree and says so.

That window is what makes parallel work supervisable: it is addressable by name, so `tmux capture-pane -t =DOT-26 -p` reads an agent's state without switching to it, `bind w` lists every prepared runway, and every pane opened there inherits the right directory (and therefore the right `.envrc.worktree`). Each window opens on `wtinfo`, which prints what provisioning assigned.

Do **not** substitute the Agent tool's own worktree isolation for this. It creates a bare worktree and skips the repo's provisioning entirely, which produces a checkout that looks fine and cannot serve a request.

Report what provisioning chose (the app URL, the ports, the database mode) — it is the first thing anyone needs and the last thing they will think to ask for. Under `--worktree` in a repo with no `bin/worktree-setup` there is nothing to report and that is correct; `wtinfo` says as much, and the worktree is doing its whole job by existing.

## 4. Read the ticket

Run `preflight` for the issue — from inside its worktree, or in branch mode right here — with two changes:

- **Pass the identifier explicitly.** Dispatch already resolved it; do not make preflight re-derive it from the branch.
- **Stop after the interrogation.** Preflight normally ends in plan mode; here the brief and the questions *are* the artifact, and a plan-mode gate would park every parallel runway on an approval prompt. Skip it.

Everything else about preflight applies and is the reason this step is not hand-rolled: relations and comments override the description, the code it names gets read rather than inferred, and the enriched context gets written back to the issue so it outlives the session.

**Several issues at once** (worktree mode; branch mode takes one): fan the reading out, one subagent per issue, each returning its brief and questions. The worktrees are already isolated, so the reads do not interfere. Create the worktrees first, in sequence — `wta` and `bin/worktree-setup` touch shared state (the traefik config directory, the port scan, the database server) and racing them invites collisions.

## 5. Report the batch

One block per issue, in the order given:

- **Where it is** — worktree path, branch, tmux window name, and what provisioning assigned (`wtinfo`'s output: URL, ports, database mode). In branch mode: the branch and the checkout it was created in, and nothing else. When a flag overrode the default, say which and why it changes what the reader should expect — above all that a forced worktree in a symlinked repo has no effect on the live environment yet.
- **The brief** — preflight's, unedited: what the issue asks, what is already done, where the code disagrees with the ticket, what success looks like.
- **The questions**, numbered, ranked by how much the answer changes the work.
- **Anything already blocking** — a stale premise, an unmet dependency, a red baseline noticed in passing.

Then stop. Say plainly that no code has been written and no tickets have moved, and that answering the questions is what releases each flight.

## 6. Handoff

Work begins with `takeoff` in the chosen worktree, which is where the questions get folded in, the environment gets verified, the baseline gets captured, and the ticket moves to In Progress. Dispatch deliberately leaves all four alone: a prepared runway is not a commitment to fly, and half of these worktrees may be torn down unused.

**"In the chosen worktree" means a session whose working directory is that worktree — not this one reaching into it.** `wta -w` starts a Claude session in each ticket's tmux window for exactly this reason; the user switches to that window and answers the questions there. A dispatching session that keeps going instead resolves the main checkout's `.envrc` (wrong ports, wrong hostname, wrong database), runs against whatever branch the main checkout has out, and has to re-specify the worktree path on every call — where a single omission puts the edit or the commit in the main checkout. It also cannot be in more than one of these at once, which is the whole point of dispatching several.

So do not run `takeoff` here, and do not start implementing here, however complete the brief in front of you feels. Answering the questions is not the release; it is the input the worktree's own session needs. Hand them over and stop. The `worktree-guard` hook denies writes and test runs against a worktree from outside it, so this is enforced rather than merely asked for — but arriving at that denial means the handoff was already missed. If a single session genuinely should own one worktree, `EnterWorktree({path: …})` moves it there properly instead of prefixing every command.

In branch mode none of this applies: there is no second session to hand to, and `takeoff` continues here once the questions are answered. A `--worktree` dispatch is a worktree like any other, flag or not — it has its own window and its own session, so the handoff above holds in full. Everything dispatch withholds it still withholds — no code, no ticket movement — but the reason is the pause for answers, not the handoff.

That teardown is `wtr <branch>` — it runs the repo's `bin/worktree-teardown` first, so routes and cloned databases go with it, and closes the ticket's tmux window. Mention it when a dispatched issue turns out to be a non-starter; an abandoned worktree is cheap to remove and expensive to rediscover in a month. In branch mode the equivalent is `git switch main` and `git branch -d <branch>`.
