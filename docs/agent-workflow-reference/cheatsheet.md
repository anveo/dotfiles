# Agent Workflow Cheatsheet

Quick reference for running coding agents on tracked issues: one issue, one git
worktree, one tmux window. Skills live in `extras/claude/skills/`; the shell
functions in `bash/functions`.

---

## The lifecycle

Six skills, in order. Each is the source of truth for its own step.

| Skill | When | What it does | Writes code? |
|-------|------|--------------|--------------|
| `/dispatch` | Front of everything | Resolves issues, creates + provisions a worktree and tmux window each, runs the read, reports briefs and questions | No |
| `/preflight` | Standing in a branch | Reads the ticket, comments, relations, and the code it names; briefs; interrogates | No |
| `/takeoff` | Questions answered | Verifies env, captures a green baseline, ticket → In Progress, builds to the plan | Yes |
| `/approach` | Work done | Splits the tree into a commit series, pushes, opens a **draft** PR | Commits |
| `/crosscheck` | PR is up | Verifies each bot finding against the code; reports which hold up | Only if asked |
| `/land` | PR approved | Merges preserving the series, deletes branch, syncs main, closes the issue | Merges |

Two invariants worth remembering:

- **Nothing commits before `/approach`.** It reads the whole working tree and cuts
  commits by *reason*. Checkpoint commits hand it a half-built history to fight.
- **`/land` merges, never squashes**, so the series survives on `main`.

`/dispatch` runs `/preflight`'s read internally, minus its plan-mode ending — so
use `/dispatch` to start from an identifier, `/preflight` when you are already on
the branch.

---

## Worktree commands

| Command | Action |
|---------|--------|
| `wta <branch>` | Create worktree, `cd` into it, rename the current window |
| `wta -w <branch>` | Same, but give it its own tmux window and stay put — the `/dispatch` form |
| `wtr <branch>` | Stop overmind, run teardown, remove worktree, close its window |
| `wtinfo` | What setup assigned here: URL, ports (with up/down), database mode |
| `ovls` | Every running overmind, with its directory and whether its socket survives |
| `ovclean` | Kill orphaned overminds and stale overmind tmux servers |
| `killport <port> [sig]` | Kill whatever is listening on a TCP port |

Worktrees live at `<repo>.worktrees/<branch>`. Branch names follow
`KEY-short-slug` (`APP-191-track-llm-tokens`); the skills match on the key and
number only, so the slug is free-form — keep it short, since it drives hostnames
and database names downstream.

---

## The tmux window model

`wta -w` gives each worktree a detached window named for the ticket. The point is
**addressability**, not tidiness:

```bash
tmux capture-pane -t "<session>:=APP-191" -p -S -50   # read an agent's state
tmux send-keys    -t "<session>:=APP-191" wtinfo Enter # nudge it
```

Qualify the target with the session (`monicur:=APP-191`) or use the window id
(`@23`). A bare `=NAME` resolves only within the *current* session, and an agent's
shell is routinely attached to a different one.

Windows get `monitor-silence 60`, so the status bar flags one that has gone quiet
— as close as tmux gets to "that agent finished, or is stuck". `prefix w` lists
every prepared runway with what is running in it.

**Do not nest tmux sessions.** Overmind already runs a private tmux server per
instance (`-L overmind-<title>-<hash>`), invisible to `tmux ls` and prone to
orphaning — that is what `ovls`/`ovclean` exist for. A third layer compounds it
and costs a prefix keystroke. Split panes and zoom instead; a task genuinely
needing many views should get a *sibling* session, not a nested one.

---

## Per-worktree environment

Three env layers, last one wins:

| File | Tracked? | Holds |
|------|----------|-------|
| `.envrc` | Yes | Shared defaults |
| `.envrc.private` | No | Secrets, machine-local overrides (template: `.envrc.example`) |
| `.envrc.worktree` | No | Ports, hostname, database — written by `bin/worktree-setup` |

A repo opts into the workflow by providing two executables, which `wta`/`wtr` run:

- `bin/worktree-setup` — idempotent; assigns ports, hostname, database; writes `.envrc.worktree`
- `bin/worktree-teardown` — removes routes, disposable databases, whatever setup created

**The app URL is `https://$APP_HOST`**, read from the environment. Never assume
`localhost:3000` — in a worktree that belongs to the main checkout.

### Running the app

```bash
prefix -          # stacked split (prefix | for side by side)
overmind start    # foreground, output visible
```

These splits carry `-c "#{pane_current_path}"`, so the new pane starts in the
worktree. tmux's default `"` and `%` are unbound in `.tmux.conf` -- and would
have opened in the session's start directory, i.e. the main checkout.

`overmind start -D` daemonizes (`overmind echo` for logs, `overmind quit` to
stop); `overmind connect <process>` attaches to one process inside overmind's own
tmux — the case `C-\` (send-prefix) exists for. Starting the server is manual and
deliberate: most tickets never need it, and one server per prepared worktree
would burn ports, connections, and CPU on runways you never fly.

---

## Gotchas

**Shell functions reach agents through a snapshot taken at session start**
(`~/.claude/shell-snapshots/`). Editing `bash/functions` does not reach a running
session, and the failure is silent rather than a clean error. Any skill calling
`wta`/`wtr`/`wtinfo` must `source "$HOME/dotfiles/bash/functions"` first; after
changing them, start a fresh session.

**Skills are symlinked one directory at a time** by `bin/install-ai.sh`. A newly
created skill is invisible until linked — re-run the installer or link it by hand.

**The compose stack is a singleton run from the main checkout.** Never
`docker compose up` from a worktree; per-worktree routing happens through files
dropped into the main checkout's watched traefik directory.

**MCP servers: name is the tenant.** OAuth grants key on the server *name*, so
`linear-personal` and `linear-monicur` share a URL while holding different
workspace grants. Project scope (`.mcp.json`, committed) and user scope both
follow you into worktrees; **local scope does not** — never use it.

**Per-project disabling of user-scope MCP servers only works machine-locally**
(`~/.claude.json`, what the `/mcp` toggle writes). A committed
`.claude/settings.json` disable list is silently ignored.

---

## A full pass

```bash
# from the main checkout, inside tmux
git switch main && git pull --ff-only
docker compose up -d                  # infra singleton, if the repo has one
claude
```

```
/dispatch APP-191                     # worktree + window + brief + questions
```

Answer the questions, then in the ticket's window (`prefix w`):

```bash
claude
```

```
/takeoff                              # baseline, In Progress, build
/approach                             # commit series + draft PR
```

Mark the PR ready, then:

```
/crosscheck                           # verify the bot findings
/land                                 # merge, clean up, close the issue
```

```bash
wtr APP-191-track-llm-tokens          # teardown when finished or abandoning
```
