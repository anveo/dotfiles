if [ -f $HOME/.pyenv/bin/pyenv ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"

  eval "$(pyenv init --path)"
  # Sonoma fix
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi
