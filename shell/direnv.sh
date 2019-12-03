if [ -f $(brew --prefix direnv)/bin/direnv ]; then
  eval "$(direnv hook zsh)"
fi

