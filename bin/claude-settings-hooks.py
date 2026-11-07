#!/usr/bin/env python3
"""Register this repo's Claude hooks in ~/.claude/settings.json, and remove
retired ones.

    python3 bin/claude-settings-hooks.py SETTINGS_PATH HOOKS_DIR

Run by bin/install-ai.sh. settings.json is untracked and machine-local; this
is the one place the repo writes to it. The edit is idempotent and keyed on
the command string, so a second run changes nothing and leaves the file
untouched.

Retired commands:
  - worktree-guard, the old name of runway-write-guard. Left in place it
    would point at a dangling symlink and run on every Bash and Edit call.
"""

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


def retired(command):
    return command in RETIRED


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
        inner = []
        for hook in entry.get("hooks", []):
            if retired(hook.get("command")):
                changed = True
                print(f"removed retired hook from {event}: {hook.get('command')}")
            else:
                inner.append(hook)
        if len(inner) != len(entry.get("hooks", [])):
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
