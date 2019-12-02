# vim:filetype=sh:foldmethod=indent:tabstop=4:shiftwidth=4:softtabstop=0:noexpandtab:
# ==============================================================================
# === fzf ===
# ==============================================================================

# @usage Figlet font selector => copy to clipboard
#
# @param string Word or words to make.
fgl() (
  [ $# -eq 0 ] && return
  cd /usr/local/Cellar/figlet/*/share/figlet/fonts
  local font=$(ls *.flf | sort | fzf --no-multi --reverse --preview "figlet -f {} $@") &&
  figlet -f "$font" "$@" | pbcopy
)

#  =============================================================================

# @usage Browse chrome history with FZF
ch() {
  local cols sep
  export cols=$(( COLUMNS / 3 ))
  export sep='{::}'

  cp -f ~/Library/Application\ Support/Google/Chrome/Default/History /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select title, url from urls order by last_visit_time desc" |
  ruby -ne '
    cols = ENV["cols"].to_i
    title, url = $_.split(ENV["sep"])
    len = 0
    puts "\x1b[36m" + title.each_char.take_while { |e|
      if len < cols
        len += e =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/ ? 2 : 1
      end
    }.join + " " * (2 + cols - len) + "\x1b[m" + url' |
  fzf --ansi --multi --no-hscroll --tiebreak=index |
  sed 's#.*\(https*://\)#\1#' | xargs open
}

#  =============================================================================

# fe - fuzzy edit
fe() {
  local files
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-nvim} "${files[@]}"
}

#  =============================================================================

# vf - fuzzy open with vim from anywhere
# ex: vf word1 word2 ... (even part of a file name)
# zsh autoload function
vf() {
  local files

  files=(${(f)"$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1 -m)"})

  if [[ -n $files ]]
  then
     nvim -- $files
     print -l $files[1]
  fi
}

#  =============================================================================

# fuzzy grep open via ag
vg() {
  local file

  file="$(ag --nobreak --noheading $@ | fzf -0 -1 | awk -F: '{print $1 " +" $2}')"

  if [[ -n $file ]]
  then
     nvim $file
  fi
}

#  =============================================================================

# @usage Search command history with FZF.
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

#  =============================================================================

# @description Create new tmux session, or switch to existing one. Works from within tmux too. (@bag-man)
#
# @usage `tm`     will allow you to select your tmux session via fzf.
# @usage `tm irc` will attach to the irc session (if it exists), else it will create it.
tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

#  =============================================================================

# fzkill - kill process
fzkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

#  =============================================================================

# cd_project_widget() {
#   local cmd="ghq list"
#   setopt localoptions pipefail 2> /dev/null
#   local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf +m)"
#   if [[ -z "$dir" ]]; then
#     zle redisplay
#     return 0
#   fi
#   cd $(ghq list --full-path | grep "$dir")
#   local ret=$?
#   zle reset-prompt
#   typeset -f zle-line-init >/dev/null && zle zle-line-init
#   return $ret
# }
# zle -N cd-project-widget
# bindkey '^g' cd-project-widget

#  =============================================================================

# fzf_ghq() {
#     local selected_dir=$(ghq list -p | $(__fzfcmd) --query "$LBUFFER")
#     if [ -n "$selected_dir" ]; then
#         BUFFER="cd ${selected_dir}"
#         zle accept-line
#     fi
# }
#
# ghq_fzf() {
#   local selected_dir=$(ghq list | fzf --query="$LBUFFER")
#
#   if [ -n "$selected_dir" ]; then
#     BUFFER="cd $(ghq root)/${selected_dir}"
#     zle accept-line
#   fi
#
#   zle reset-prompt
# }
# zle -N fzf_ghq
# zle -N ghq_fzf
# bindkey '^g^h' fzf_ghq

