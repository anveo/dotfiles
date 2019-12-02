# 1password

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_OP_SHOW="${SPACESHIP_OP_SHOW=true}"
SPACESHIP_OP_PREFIX="${SPACESHIP_OP_PREFIX=""}"
SPACESHIP_OP_SUFFIX="${SPACESHIP_OP_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX "}"
SPACESHIP_OP_SYMBOL="${SPACESHIP_OP_SYMBOL=" "}"
SPACESHIP_OP_COLOR="${SPACESHIP_OP_COLOR="blue"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Shows selected AWS-cli profile.
spaceship_op() {
  [[ $SPACESHIP_OP_SHOW == false ]] && return

  op_session=`env | grep '^OP_SESSION_' | cut -d'=' -f1 | sed -e's/OP_SESSION_//g' | tr -d '\n'`

  # Check to see if we're in an AWS VAULT section
  [[ -z $op_session ]] && return

  # Show prompt section
  spaceship::section \
    "$SPACESHIP_OP_COLOR" \
    "$SPACESHIP_OP_PREFIX" \
    "${SPACESHIP_OP_SYMBOL}$op_session" \
    "$SPACESHIP_OP_SUFFIX"
}

