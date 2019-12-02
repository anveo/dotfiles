# subshell indicator

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_SUBSHELL_SHOW="${SPACESHIP_SUBSHELL_SHOW=true}"
SPACESHIP_SUBSHELL_PREFIX="${SPACESHIP_SUBSHELL_PREFIX=""}"
SPACESHIP_SUBSHELL_SUFFIX="${SPACESHIP_SUBSHELL_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_SUBSHELL_SYMBOL="${SPACESHIP_SUBSHELL_SYMBOL="﬌ "}"
SPACESHIP_SUBSHELL_COLOR="${SPACESHIP_SUBSHELL_COLOR="165"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Shows selected AWS-cli profile.
spaceship_subshell() {
  [[ $SPACESHIP_SUBSHELL_SHOW == false ]] && return

  if [[ -n "$TMUX" ]]; then
    local lvl=$(($SHLVL - 1))
  else
    local lvl=$SHLVL
  fi

  # Check to see if we're in a nested subshell
  [[ lvl -le 1 ]] && return

  # Start at 1 since you can never have a subshell level of zero
  for (( i = 1; i < $lvl - 1; i++ )); do
    suffix+="﬌ ";
  done;

  # Show prompt section
  spaceship::section \
    "$SPACESHIP_SUBSHELL_COLOR" \
    "$SPACESHIP_SUBSHELL_PREFIX" \
    "${SPACESHIP_SUBSHELL_SYMBOL}$suffix" \
    "$SPACESHIP_SUBSHELL_SUFFIX"
}

