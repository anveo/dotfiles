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

# RTK's global instructions are placed by `rtk install -g`, not by this repo.
# A stale symlink from when they lived here would shadow the real file.
if [ -L "$HOME/.claude/RTK.md" ] && [ ! -e "$HOME/.claude/RTK.md" ]; then
  echo "Removing dangling $HOME/.claude/RTK.md symlink"
  rm -f "$HOME/.claude/RTK.md"
fi

if ! command -v rtk >/dev/null 2>&1; then
  echo "WARNING: rtk not found on PATH -- install it, then run: rtk install -g"
elif [ ! -e "$HOME/.claude/RTK.md" ]; then
  echo "WARNING: $HOME/.claude/RTK.md missing -- run: rtk install -g"
fi
