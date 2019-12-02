# AWS Vault

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_AWSVAULT_SHOW="${SPACESHIP_AWSVAULT_SHOW=true}"
SPACESHIP_AWSVAULT_PREFIX="${SPACESHIP_AWSVAULT_PREFIX=""}"
SPACESHIP_AWSVAULT_SUFFIX="${SPACESHIP_AWSVAULT_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX "}"
SPACESHIP_AWSVAULT_SYMBOL="${SPACESHIP_AWSVAULT_SYMBOL=" "}"
SPACESHIP_AWSVAULT_COLOR="${SPACESHIP_AWSVAULT_COLOR="208"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Shows selected AWS-cli profile.
spaceship_awsvault() {
  [[ $SPACESHIP_AWSVAULT_SHOW == false ]] && return

  # Check to see if we're in an AWS VAULT section
  [[ -z $AWS_VAULT ]] && return

  # Show prompt section
  spaceship::section \
    "$SPACESHIP_AWSVAULT_COLOR" \
    "$SPACESHIP_AWSVAULT_PREFIX" \
    "${SPACESHIP_AWSVAULT_SYMBOL}$AWS_VAULT" \
    "$SPACESHIP_AWSVAULT_SUFFIX"
}
