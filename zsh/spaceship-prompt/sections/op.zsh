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

# Shows selected 1password profile.
spaceship_op() {
  [[ $SPACESHIP_OP_SHOW == false ]] && return

  op_session=`env | grep -v '^OP_SESSION_EXPIRATION' | grep '^OP_SESSION_' | cut -d'=' -f1 | sed -e's/OP_SESSION_//g' | tr -d '\n'`

  # Check to see if a 1password session is active
  [[ -z $op_session ]] && return

  # Check to see if the credentials are expired
  OP_EXPIRED=""
  CURRENT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # `date --iso-8601=ns` does not work by default on MacOS

  if [[ $CURRENT_TIMESTAMP > $OP_SESSION_EXPIRATION ]]; then
    OP_EXPIRED=" (expired)"
  fi

  # Show prompt section
  spaceship::section \
    "$SPACESHIP_OP_COLOR" \
    "$SPACESHIP_OP_PREFIX" \
    "${SPACESHIP_OP_SYMBOL}$op_session$OP_EXPIRED" \
    "$SPACESHIP_OP_SUFFIX"
}

