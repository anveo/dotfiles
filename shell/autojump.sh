# brew install autojump
# https://github.com/joelthelion/autojump

if [[ ! -z "${BASH}" ]]; then
  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    [[ -s $HOMEBREW_PREFIX/etc/autojump.sh ]] && . $HOMEBREW_PREFIX/etc/autojump.sh
  fi
fi
