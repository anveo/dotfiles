SPACESHIP_CHAR_SYMBOL="∴"
SPACESHIP_CHAR_SUFFIX=" "
# SPACESHIP_PROMPT_DEFAULT_PREFIX=""
SPACESHIP_PROMPT_PREFIXES_SHOW="false"
SPACESHIP_DIR_PREFIX=""
SPACESHIP_DIR_TRUNC="8"
SPACESHIP_DIR_LOCK_SYMBOL="${SPACESHIP_DIR_LOCK_SYMBOL=" "}"
SPACESHIP_GIT_PREFIX=""
SPACESHIP_NODE_SYMBOL=" "
SPACESHIP_PACKAGE_SHOW="false"
SPACESHIP_PYTHON_SYMBOL=" "
# SPACESHIP_VENV_SYMBOL=" "
# SPACESHIP_VENV_SYMBOL="v:"
SPACESHIP_VENV_COLOR="green"
SPACESHIP_RUBY_SYMBOL="  "
SPACESHIP_EXIT_CODE_SHOW="true"
SPACESHIP_RUST_SYMBOL=" "
SPACESHIP_RUST_VERBOSE_VERSION="true"

SPACESHIP_BATTERY_SYMBOL_DISCHARGING="⇣   "
SPACESHIP_BATTERY_SYMBOL_CHARGING="⇡   "
SPACESHIP_BATTERY_THRESHOLD="20"

SPACESHIP_KUBECTL_SHOW="true"
SPACESHIP_KUBECTL_SYMBOL="k8s:"
SPACESHIP_KUBECTL_COLOR="025"
SPACESHIP_KUBECTL_CONTEXT_COLOR_GROUPS=(
  # red if namespace is "kube-system"
  red    '\(kube-system)$'
  # else, green if "dev-01" is anywhere in the context or namespace
  green  dev
  # else, red if context name ends with ".k8s.local" _and_ namespace is "system"
  red    '\.k8s\.local \(system)$'
  red    'prod'
  # else, yellow if the entire content is "test-" followed by digits, and no namespace is displayed
  yellow '^test-[0-9]+$'
)

SPACESHIP_PROMPT_ORDER=(
  subshell
  # time          # Time stamps section
  # user          # Username section
  dir           # Current directory section
  # host          # Hostname section
  git           # Git section (git_branch + git_status)
  # hg            # Mercurial section (hg_branch  + hg_status)
  # package       # Package version
  node          # Node.js section
  ruby          # Ruby section
  elixir        # Elixir section
  # xcode         # Xcode section
  # swift         # Swift section
  golang        # Go section
  # php           # PHP section
  rust          # Rust section
  # haskell       # Haskell Stack section
  # julia         # Julia section
  # docker        # Docker section
  # aws           # Amazon Web Services section
  # pyenv         # Pyenv section
  venv          # virtualenv section
  conda         # conda virtualenv section
  # dotnet        # .NET section
  # ember         # Ember.js section
  # k8s
  # kubectl_context   # Kubectl context section
  # kubectl_version
  kubectl
  terraform     # Terraform workspace section
  # exec_time     # Execution time
  line_sep      # Line break
  battery       # Battery level and status
  # vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  # exit_code     # Exit code section
  char          # Prompt character
)

SPACESHIP_RPROMPT_ORDER=(
  exit_code     # Exit code section
  exec_time     # Execution time
  awsvault
  op
  time          # Time stamps section
)
