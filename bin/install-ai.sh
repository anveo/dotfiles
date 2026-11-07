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

# rtk was removed from these dotfiles. `rtk init -g` used to write
# ~/.claude/RTK.md (file or, earlier, a symlink into this repo); remove
# whatever is left. Its hook registration is removed from settings.json below.
if [ -e "$HOME/.claude/RTK.md" ] || [ -L "$HOME/.claude/RTK.md" ]; then
  echo "rm $HOME/.claude/RTK.md (rtk removed)"
  rm -f "$HOME/.claude/RTK.md"
fi

# Hooks (the Airboss pair, see docs/airboss.md). The symlink alone would leave a
# hook inert -- settings.json is what actually runs it -- and a guard nobody
# wired up fails exactly the way the thing it guards against fails. So this
# registers them too, and removes retired registrations (worktree-guard, rtk).
# See bin/claude-settings-hooks.py.
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

python3 "$(cd "$(dirname "$0")" && pwd)/claude-settings-hooks.py" \
  "$HOME/.claude/settings.json" "$HOME/.claude/hooks"
