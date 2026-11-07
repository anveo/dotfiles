#!/usr/bin/env bash

# AI tool configs only (Claude Code). Safe to run repeatedly

set -e

echo "Setting up Claude configs..."
mkdir -p $HOME/.claude/{plans,plugins}
echo "ln -nfs $HOME/dotfiles/extras/claude/commands $HOME/.claude/commands"
ln -nfs $HOME/dotfiles/extras/claude/commands $HOME/.claude/commands
echo "ln -nfs $HOME/dotfiles/extras/claude/CLAUDE.md $HOME/.claude/CLAUDE.md"
ln -nfs $HOME/dotfiles/extras/claude/CLAUDE.md $HOME/.claude/CLAUDE.md
echo "ln -nfs $HOME/dotfiles/extras/claude/statusline-command.sh $HOME/.claude/statusline-command.sh"
ln -nfs $HOME/dotfiles/extras/claude/statusline-command.sh $HOME/.claude/statusline-command.sh
mkdir -p $HOME/.claude/skills
for skill in $HOME/dotfiles/extras/claude/skills/*/; do
  echo "ln -nfs ${skill%/} $HOME/.claude/skills/$(basename $skill)"
  ln -nfs "${skill%/}" "$HOME/.claude/skills/$(basename $skill)"
done

# RTK's global instructions (~/.claude/RTK.md) and the hook wiring in
# settings.json are placed by `rtk init -g`, not by this repo. A stale symlink
# from when RTK.md lived here would shadow the real file.
if [ -L "$HOME/.claude/RTK.md" ] && [ ! -e "$HOME/.claude/RTK.md" ]; then
  echo "Removing dangling $HOME/.claude/RTK.md symlink"
  rm -f "$HOME/.claude/RTK.md"
fi

if command -v rtk >/dev/null 2>&1; then
  echo "rtk init -g"
  rtk init -g || echo "WARNING: rtk init -g failed"
else
  echo "WARNING: rtk not found on PATH -- install it, then run: rtk init -g"
fi

# Hooks (the Airboss pair, see docs/airboss.md). The symlink alone would leave a
# hook inert -- settings.json is what actually runs it -- and a guard nobody
# wired up fails exactly the way the thing it guards against fails. So this
# registers them too, after `rtk init -g` so that rtk's own edit to the same
# file cannot clobber them.
#
# This is the one place this repo writes to ~/.claude/settings.json, which is
# untracked and machine-local. The edit is idempotent and keyed on the command
# string, so re-running changes nothing. It also removes the registration of
# `worktree-guard`, the old name of runway-write-guard: left in place, it would
# point at a dangling symlink and run on every Bash and Edit call.
echo "Setting up Claude hooks..."
mkdir -p $HOME/.claude/hooks
for hook in runway-write-guard runway-callsign; do
  echo "ln -nfs $HOME/dotfiles/extras/claude/hooks/$hook $HOME/.claude/hooks/$hook"
  ln -nfs "$HOME/dotfiles/extras/claude/hooks/$hook" "$HOME/.claude/hooks/$hook"
done
if [ -L "$HOME/.claude/hooks/worktree-guard" ]; then
  echo "rm $HOME/.claude/hooks/worktree-guard (renamed runway-write-guard)"
  rm -f "$HOME/.claude/hooks/worktree-guard"
fi

python3 - "$HOME/.claude/settings.json" "$HOME/.claude/hooks" <<'PY'
import json
import os
import sys

settings_path, hooks_dir = sys.argv[1], sys.argv[2]
# Absolute paths, not "$HOME/...": settings.json is generated and machine-local,
# and a literal that depends on shell expansion fails silently if the runner
# does not do it.
WANTED = [
    # (event, matcher or None, hook name)
    ("PreToolUse", "Bash|Edit|Write|NotebookEdit", "runway-write-guard"),
    ("SessionStart", None, "runway-callsign"),
]
RETIRED = [os.path.join(hooks_dir, "worktree-guard")]

try:
    with open(settings_path) as handle:
        settings = json.load(handle)
except FileNotFoundError:
    settings = {}
except (json.JSONDecodeError, ValueError) as error:
    sys.exit(f"WARNING: {settings_path} is not valid JSON ({error}); "
             "leaving it alone. Register the runway hooks by hand.")

hooks = settings.setdefault("hooks", {})
changed = False

# Drop retired commands; drop an entry only when nothing else is left in it.
for event, entries in hooks.items():
    kept = []
    for entry in entries:
        inner = [h for h in entry.get("hooks", []) if h.get("command") not in RETIRED]
        if len(inner) != len(entry.get("hooks", [])):
            changed = True
            print(f"removed retired hook from {event}")
            if not inner:
                continue
            entry["hooks"] = inner
        kept.append(entry)
    hooks[event] = kept

for event, matcher, name in WANTED:
    command = os.path.join(hooks_dir, name)
    entries = hooks.setdefault(event, [])
    if any(h.get("command") == command for e in entries for h in e.get("hooks", [])):
        print(f"{name} already registered in {settings_path}")
        continue
    entry = {"hooks": [{"type": "command", "command": command}]}
    if matcher:
        entry = {"matcher": matcher, **entry}
    entries.append(entry)
    changed = True
    print(f"registered {name} in {settings_path}")

if changed:
    tmp = settings_path + ".tmp"
    with open(tmp, "w") as handle:
        json.dump(settings, handle, indent=2)
        handle.write("\n")
    os.replace(tmp, settings_path)
PY
