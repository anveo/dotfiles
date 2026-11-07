# Airboss

Airboss is the name for the worktree workflow in these dotfiles: `dispatch` → `preflight` → `takeoff` → `approach` → `crosscheck` → `land`. It is named after the officer who runs a carrier's whole flight deck. The skills, hooks and shell functions all use the vocabulary below, and they mean the same thing by each term.

## Vocabulary

**Tower.** The coordinating Claude session, sitting in the main checkout. It dispatches tickets, answers questions, and hands work off. It does not build on a runway.

**Runway.** A worktree that `wta` (or its alias `taxi`) prepared: `<repo>.worktrees/<branch>`, with the gitignored files copied in and the repo's `bin/worktree-setup` run. Under `wta -w` it also gets its own tmux window. A plain `git worktree add` checkout is *not* a runway. What makes one is the callsign marker.

**Pilot.** The Claude session working on a runway. Its working directory is the runway, so it picks up that runway's `.envrc.worktree`.

**Callsign.** The runway's identity, normally the ticket identifier (`DOT-99`). It is the tmux window name, the pilot's session name, and the address other sessions use with `SendMessage(to: "DOT-99")`. A branch with no ticket number in it is its own callsign (`scratch`).

**Sortie.** One ticket's run from `/dispatch` to `/land`.

**Handoff.** The tower passing a brief, and any answered questions, to a pilot.

## How the pieces connect

**The marker.** `wta` writes `callsign=<ID>` to `<repo>/.git/worktrees/<name>/callsign`, the worktree's private git directory. Its format is `key=value` lines, and readers ignore keys they don't recognise. Because it sits outside the working tree, it never shows in `git status`, and `git worktree remove` (which `wtr`/`park` runs) deletes it along with the worktree. To find it from a worktree, run `$(git rev-parse --absolute-git-dir)/callsign`. Every other tool reads the callsign from the marker; none of them works it out from the branch name.

**Branch base.** `git wta` fetches `origin` and branches from `origin/HEAD`, or from `origin/main` when that isn't set. In a repo with no `origin`, it branches from HEAD. The new branch doesn't track `origin/main`. Use `wta --base <ref>` to start from somewhere else.

**Naming the pilot.** `wta -w` starts the window's session with `claude --name <callsign>`. A session started by hand on a runway is named by the `runway-callsign` SessionStart hook, which sets `sessionTitle` to the callsign. It only does this when the session has no custom name yet; a name set with `--name` or `/rename` is kept. Two limits: `EnterWorktree` partway through a session does not fire SessionStart, and two sessions on one runway end up with the same name (ListAgents tells them apart with a short ID).

**The write guard.** The `runway-write-guard` PreToolUse hook denies writes and command runs (Edit, Write, NotebookEdit, and Bash commands that write or run project tooling) against a runway from any session whose working directory is outside it. The denial names the runway's session and window by callsign. Reads are always allowed, so the tower can brief from the main checkout. Worktrees without a marker are not guarded.

**The handoff.** After briefing, `/dispatch` checks that the runway's session appears in `ListAgents` under its callsign, then sends it the brief with `SendMessage`. The Linear comment remains the durable record, and dispatch falls back to the comment alone when the session isn't listed.

## Commands

```bash
taxi -w DOT-99-short-slug    # = wta -w: prepare a runway in its own window
park DOT-99-short-slug       # = wtr: tear it down
park                         # no branch: pick a runway with fzf
wtinfo                       # what provisioning assigned, from inside a runway
```

The hooks live in `extras/claude/hooks/`. `bin/install-ai.sh` (`make ai`) symlinks them into `~/.claude/hooks/` and registers them in `~/.claude/settings.json`. `make check` tests both hooks by feeding them sample events, and tests the marker in `test/worktree_functions_test.sh`.

The dotfiles are symlinked into the live environment from the main checkout. A change made on a runway therefore has no effect until it is merged.
