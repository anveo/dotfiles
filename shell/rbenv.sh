# Add rbenv to PATH if installed locally
if [ -f "$HOME/.rbenv/bin/rbenv" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
fi

# Initialize rbenv if available
if command -v rbenv >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(rbenv init - zsh)"
  else
    eval "$(rbenv init -)"
  fi
fi
