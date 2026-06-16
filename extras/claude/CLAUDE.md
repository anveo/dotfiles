# Global Configuration

Criticism is welcome.

* Please tell me when I am wrong or mistaken, or even when you think I might be wrong or mistaken.
* Please tell me if there is a better approach than the one I am taking.
* Please tell me if there is a relevant standard or convention that I appear to be unaware of.
* Feel free to ask many questions. If you are in doubt of my intent, don't guess. Ask.

## Plans

At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

## Inclusive Terminology

Use: allowlist/blocklist, primary/replica, placeholder/example, main branch, conflict-free, concurrent/parallel

## Environment

- Node version manager: **fnm** (not nvm). Use `fnm use <version>` to switch Node versions.

## Shell Commands (keep them auto-allowable)

I auto-allow commands by **stable prefix**, so run them in a form that can be allowlisted. Chained or wrapped commands defeat this and force a manual approval each time.

- **One command per Bash call.** Don't join steps with `;`, `&&`, or `||`. Separate steps = separate tool calls.
- **Don't wrap in pipes to trim output** (`| tail`, `| head`, `| grep`). Let output return raw; pipe only when the filtering is the actual goal.
- **Prefer dedicated tools over the shell** for reading/searching: Read / Grep / Glob instead of `cat` / `grep` / `find` / `ls` / `sed` / `head` / `tail`. If Grep/Glob aren't available, run a single bare `grep`/`rg`.
- **Use canonical, stable prefixes.** Don't insert inline env assignments mid-prefix (`env RAILS_ENV=test bundle …`). RSpec already runs in the test env; isolate the rare runner-in-test case.
- **No `echo` separators** between steps, and **no heredocs** (`cat <<EOF`) — create scratch files with the Write tool, then run them in one command.

@RTK.md
