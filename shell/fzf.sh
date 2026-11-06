# Use jj as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='jj'
export FZF_CTRL_R_OPTS='--sort --exact'

# Setting rg as the default source for fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'

# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Options to fzf command
export FZF_COMPLETION_OPTS='--color fg:-1,bg:-1,hl:230,fg+:3,bg+:233,hl+:229 --color info:150,prompt:110,spinner:150,pointer:167,marker:174 -x'

alias preview="fzf --preview 'bat --color \"always\" {}'"
# add support for ctrl+o to open selected file in VS Code
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

#_fzf_compgen_path() {
#  ag -g "" "$1"
#}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# Key bindings (Ctrl-R, Ctrl-T, Alt-C) and completion. zsh gets these from the
# Oh My Zsh fzf plugin in zsh/plugins.txt, so only bash is set up here.
# `fzf --bash` needs fzf 0.48+; older installs fall back to the install script's file.
if [ -n "${BASH_VERSION}" ] && command -v fzf >/dev/null 2>&1; then
  if fzf_bash_init=$(fzf --bash 2>/dev/null); then
    eval "$fzf_bash_init"
  elif [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
  fi
  unset fzf_bash_init
fi

