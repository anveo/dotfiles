# brew install autojump
# https://github.com/joelthelion/autojump
if type brew &>/dev/null; then
  [[ -s `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh
fi

