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

# Hooks. The symlink alone would leave the guard inert -- settings.json is what
# actually runs it -- and a guard nobody wired up fails exactly the way the
# thing it guards against fails. So this registers it too, after `rtk init -g`
# so that rtk's own edit to the same file cannot clobber it.
#
# This is the one place this repo writes to ~/.claude/settings.json, which is
# untracked and machine-local. The edit is additive, idempotent, and keyed on
# the command string, so re-running changes nothing.
echo "Setting up Claude hooks..."
mkdir -p $HOME/.claude/hooks
echo "ln -nfs $HOME/dotfiles/extras/claude/hooks/worktree-guard $HOME/.claude/hooks/worktree-guard"
ln -nfs $HOME/dotfiles/extras/claude/hooks/worktree-guard $HOME/.claude/hooks/worktree-guard

python3 - "$HOME/.claude/settings.json" "$HOME/.claude/hooks/worktree-guard" <<'PY'
import json
import os
import sys

settings_path, hook_command = sys.argv[1], sys.argv[2]
# The absolute path, not "$HOME/...": settings.json is generated and
# machine-local, and a literal that depends on shell expansion fails silently
# if the runner does not do it.
entry = {
    "matcher": "Bash|Edit|Write|NotebookEdit",
    "hooks": [{"type": "command", "command": hook_command}],
}

try:
    with open(settings_path) as handle:
        settings = json.load(handle)
except FileNotFoundError:
    settings = {}
except (json.JSONDecodeError, ValueError) as error:
    sys.exit(f"WARNING: {settings_path} is not valid JSON ({error}); "
             "leaving it alone. Register worktree-guard by hand.")

pre = settings.setdefault("hooks", {}).setdefault("PreToolUse", [])
if any(h.get("command") == hook_command
       for existing in pre for h in existing.get("hooks", [])):
    print(f"worktree-guard already registered in {settings_path}")
    sys.exit(0)

pre.append(entry)
tmp = settings_path + ".tmp"
with open(tmp, "w") as handle:
    json.dump(settings, handle, indent=2)
    handle.write("\n")
os.replace(tmp, settings_path)
print(f"registered worktree-guard in {settings_path}")
PY
