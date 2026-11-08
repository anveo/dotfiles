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
  # Compile to a per-process temp file and rename it into place: zcompile
  # writing $dump.zwc directly races when several shells start at once (tmux
  # restoring panes), and the loser fails with "can't write zwc file" because
  # the winner's freshly created .zwc is mode 0444. The rename is atomic.
  if [[ ! $dump.zwc -nt $dump ]]; then
    local tmp=$dump.$$.zwc
    if zcompile $tmp $dump; then
      mv -f $tmp $dump.zwc
    else
      rm -f $tmp
    fi
  fi
}
