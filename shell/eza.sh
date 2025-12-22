if command -v eza >/dev/null 2>&1; then
  # Replace existing ls aliases
  alias ls='eza'
  alias l='eza -lah'
  alias ll='eza -la'
  alias la='eza -a'
  alias sl='eza'

  # New eza-specific aliases
  alias et='eza --tree'
  alias eti='eza --tree --icons'
  alias eli='eza -l --icons'
  alias eg='eza --git'
  alias ell='eza -l --long --git --icons'
fi
