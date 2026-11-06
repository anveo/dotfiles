# Initialize completion exactly once. Loaded from zsh/plugins.txt rather than
# .zshrc so it runs after every plugin above it has added to fpath and before
# fzf-tab, which needs compinit to have run already.
autoload -Uz compinit

() {
  local dump=${ZDOTDIR:-$HOME}/.zcompdump
  # The (N.mh+24) glob qualifier matches the dump only when it is older than 24
  # hours. Qualifiers expand in an argument list like this one, but not inside
  # [[ ]] -- that is what broke the old once-a-day test, which then never fired.
  local stale=( $dump(N.mh+24) )

  if [[ ! -s $dump || -n $stale ]]; then
    # Full check: rescan fpath and audit directory permissions. compinit only
    # rewrites the dump when the set of completion files changed, so touch it
    # to restart the 24-hour clock either way.
    compinit -d $dump
    touch $dump
  else
    # Trust the cached dump and skip the permission audit.
    compinit -C -d $dump
  fi

  # Compile the dump so later startups load bytecode instead of parsing it.
  if [[ ! $dump.zwc -nt $dump ]]; then
    zcompile $dump
  fi
}
