# https://github.com/ajeetdsouza/zoxide
# z <query> jumps to the best-ranked match; zi <query> picks interactively via fzf.
# Sourced by .zshrc's shell/*.sh loop and explicitly from .bashrc (after
# bash/prompt, since zoxide appends its hook to PROMPT_COMMAND).

if command -v zoxide >/dev/null 2>&1; then
  if [[ -n "${ZSH_VERSION}" ]]; then
    eval "$(zoxide init zsh)"
  elif [[ -n "${BASH_VERSION}" ]]; then
    eval "$(zoxide init bash)"
  fi
fi
