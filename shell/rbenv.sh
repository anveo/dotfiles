if [ -f /usr/local/bin/rbenv ]; then
  eval "$(rbenv init -)"
fi

if [ -f $HOME/.rbenv/bin/rbenv ]; then
  export PATH=$HOME/.rbenv/bin:$PATH
  eval "$(rbenv init -)"
fi

