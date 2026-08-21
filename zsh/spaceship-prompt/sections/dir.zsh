#
# Working directory (override of spaceship's stock dir section)
#
# Identical to upstream except inside a linked git worktree: our worktrees
# are named after their branch (see gitconfig wta), which the git section
# already displays, so the leading path component just duplicates it. Show
# the main repo's name plus a worktree marker instead, e.g.
#   monicur.worktrees/app-217-foo/.infra/terraform  ->  ⑂/.infra/terraform
#
# Must be sourced after the spaceship theme loads so this definition wins.
#

SPACESHIP_DIR_WORKTREE_SYMBOL="${SPACESHIP_DIR_WORKTREE_SYMBOL="⑂"}"

# Upstream's config defaults must live here too: shadowing the stock section
# means its file (and these assignments) never runs.
SPACESHIP_DIR_SHOW="${SPACESHIP_DIR_SHOW=true}"
SPACESHIP_DIR_PREFIX="${SPACESHIP_DIR_PREFIX="in "}"
# Upstream defaults this to $SPACESHIP_PROMPT_DEFAULT_SUFFIX, but spaceship
# isn't loaded yet when this file is sourced, so hardcode its value (" ")
SPACESHIP_DIR_SUFFIX="${SPACESHIP_DIR_SUFFIX=" "}"
SPACESHIP_DIR_TRUNC="${SPACESHIP_DIR_TRUNC=3}"
SPACESHIP_DIR_TRUNC_PREFIX="${SPACESHIP_DIR_TRUNC_PREFIX=}"
SPACESHIP_DIR_TRUNC_REPO="${SPACESHIP_DIR_TRUNC_REPO=true}"
SPACESHIP_DIR_COLOR="${SPACESHIP_DIR_COLOR="cyan"}"
SPACESHIP_DIR_LOCK_SYMBOL="${SPACESHIP_DIR_LOCK_SYMBOL=" "}"
SPACESHIP_DIR_LOCK_COLOR="${SPACESHIP_DIR_LOCK_COLOR="red"}"

spaceship_dir() {
  [[ $SPACESHIP_DIR_SHOW == false ]] && return

  local dir trunc_prefix

  if [[ $SPACESHIP_DIR_TRUNC_REPO == true ]] && spaceship::is_git; then
    local git_root=$(git rev-parse --show-toplevel)
    local git_dir=$(git rev-parse --path-format=absolute --git-dir)
    local git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir)

    # Check if the parent of the $git_root is "/"
    if [[ $git_root:h == / ]]; then
      trunc_prefix=/
    else
      trunc_prefix=$SPACESHIP_DIR_TRUNC_PREFIX
    fi

    if [[ $git_dir != $git_common_dir ]]; then
      # Linked worktree: --git-dir lives under <main>/.git/worktrees/<name>,
      # so the main repo root is the common dir's parent.
      # No repo name: tmux session / ghostty tab already say which project,
      # and the branch (= worktree name) sits in the git section next door.
      dir="$trunc_prefix$SPACESHIP_DIR_WORKTREE_SYMBOL${${PWD:A}#$~~git_root}"
    else
      dir="$trunc_prefix$git_root:t${${PWD:A}#$~~git_root}"
    fi
  else
    if [[ SPACESHIP_DIR_TRUNC -gt 0 ]]; then
      trunc_prefix="%($((SPACESHIP_DIR_TRUNC + 1))~|$SPACESHIP_DIR_TRUNC_PREFIX|)"
    fi

    dir="$trunc_prefix%${SPACESHIP_DIR_TRUNC}~"
  fi

  local suffix="$SPACESHIP_DIR_SUFFIX"

  if [[ ! -w . ]]; then
    suffix="%F{$SPACESHIP_DIR_LOCK_COLOR}${SPACESHIP_DIR_LOCK_SYMBOL}%f${SPACESHIP_DIR_SUFFIX}"
  fi

  spaceship::section \
    --color "$SPACESHIP_DIR_COLOR" \
    --prefix "$SPACESHIP_DIR_PREFIX" \
    --suffix "$suffix" \
    "$dir"
}

# Hide the verbose kubectl section while inside a linked worktree in tmux,
# same "keep the prompt short in worktrees" idea as the dir override above.
# Runs every precmd (registered before spaceship's own hooks, so it takes
# effect for the prompt being built); note it force-sets KUBECTL_SHOW both
# ways, so a manual toggle won't stick outside worktrees.
_worktree_kubectl_hide() {
  local git_dir git_common_dir
  git_dir=$(git rev-parse --path-format=absolute --git-dir 2>/dev/null)
  git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)

  if [[ -n $TMUX && -n $git_dir && $git_dir != $git_common_dir ]]; then
    SPACESHIP_KUBECTL_SHOW=false
  else
    SPACESHIP_KUBECTL_SHOW=true
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _worktree_kubectl_hide
