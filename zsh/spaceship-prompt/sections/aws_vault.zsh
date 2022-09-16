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

  # Check if aws-vault command is available for execution
  spaceship::exists aws-vault || return

  # Check to see if we're in an AWS VAULT section
  [[ -z $AWS_VAULT ]] && return

  # Check to see if the credentials are expired
  EXPIRED=""
  CURRENT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # `date --iso-8601=ns` does not work by default on MacOS

  if [[ $CURRENT_TIMESTAMP > $AWS_SESSION_EXPIRATION ]]; then
    EXPIRED=" (expired)"
  fi

  # Show prompt section
  spaceship::section::v4 \
    --color "$SPACESHIP_AWSVAULT_COLOR" \
    --prefix "$SPACESHIP_AWSVAULT_PREFIX" \
    --suffix "$SPACESHIP_AWSVAULT_SUFFIX" \
    --symbol "$SPACESHIP_AWSVAULT_SYMBOL" \
    "$AWS_VAULT$EXPIRED"
}
