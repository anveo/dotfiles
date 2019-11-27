if [ -f $(brew --prefix direnv)/bin/direnv ]; then
  eval "$(direnv hook bash)"
fi

