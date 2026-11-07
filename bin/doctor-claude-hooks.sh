# Sourced by bin/doctor (and test/doctor_claude_hooks_test.sh), not run.
#
# check_claude_hooks <settings.json>
#
# Every command hook registered in a Claude Code settings file must name a
# command that exists. A hook whose file is gone fails on every matching tool
# call, and nothing on disk is left dangling to say so: once the symlink is
# deleted, the stale command string in settings.json is the only trace.
#
# When the command is an interpreter (`python3 ~/hook.py`, `bash x.sh`), the
# script it runs is checked too: the interpreter outliving its script is the
# same stale-string failure. Only the first non-option argument is taken as the
# script, so an option that takes a value (`python3 -W ignore x.py`) is misread
# as the script; that reports a relative path it could not check, not a FAIL.
#
# Bare commands are looked up on doctor's PATH, which is the terminal's. Claude
# Code started from the Dock may run hooks with a shorter PATH.
#
# Reports through the caller's ok / warn / bad / skip / detail. Bash 3.2 safe.

# Split the first shell word off $1: _hw_word gets it, unquoted, and _hw_rest
# gets what follows. A single- or double-quoted word may contain spaces.
_hook_split() {
  local s=$1
  s="${s#"${s%%[![:space:]]*}"}"
  case "$s" in
    \"*) s=${s#\"}; _hw_word=${s%%\"*}; _hw_rest=${s#*\"} ;;
    \'*) s=${s#\'}; _hw_word=${s%%\'*}; _hw_rest=${s#*\'} ;;
    *)   _hw_word=${s%%[[:space:]]*}; _hw_rest=${s#"$_hw_word"} ;;
  esac
  # An unterminated quote: the whole remainder was the word.
  [ "$_hw_rest" = "$s" ] && _hw_rest=
  return 0
}

# ~/, $HOME/ and ${HOME}/ expanded, as the shell running the hook would.
_hook_expand() {
  case "$1" in
    '~/'*)       printf '%s\n' "$HOME/${1:2}" ;;
    '$HOME/'*)   printf '%s\n' "$HOME/${1:6}" ;;
    '${HOME}/'*) printf '%s\n' "$HOME/${1:8}" ;;
    *)           printf '%s\n' "$1" ;;
  esac
}

# Sets _hook_prog to the program a hook command runs, after any leading
# VAR=value assignments, and _hook_script to the script it hands an
# interpreter, if any. Every pass consumes input, so it always terminates.
_hook_command_words() {
  local cmd=$1 name rest
  _hook_prog= _hook_script=
  while :; do
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"
    name=${cmd%%=*}
    # Not an assignment: no `=`, or something other than a shell name before it.
    case "$name" in
      "$cmd"|''|[0-9]*|*[!A-Za-z0-9_]*) break ;;
    esac
    rest=${cmd#*=}
    case "$rest" in
      \"*) rest=${rest#\"}; rest=${rest#*\"} ;;
      \'*) rest=${rest#\'}; rest=${rest#*\'} ;;
    esac
    cmd=${rest#"${rest%%[[:space:]]*}"}
  done
  _hook_split "$cmd"
  _hook_prog=$(_hook_expand "$_hw_word")
  # The options after which there is no script file: inline code, a module.
  # (-e is inline code to perl, node and ruby, but errexit to a shell.)
  local inline
  case "${_hook_prog##*/}" in
    sh|bash|zsh|dash|ksh)  inline=" -c " ;;
    python|python[0-9]*)   inline=" -c -m " ;;
    node|ruby|perl)        inline=" -e -E -p " ;;
    *) return 0 ;;
  esac
  rest=$_hw_rest
  while :; do
    _hook_split "$rest"
    case "$_hw_word" in
      ''|-) break ;;  # end of line, or stdin
      -*)
        case "$inline" in *" $_hw_word "*) break ;; esac
        rest=$_hw_rest ;;
      *) _hook_script=$(_hook_expand "$_hw_word"); break ;;
    esac
  done
}

# Report on one path a hook needs. With a runner, the path is a script that
# runner reads, so it only has to be a file; without one, it is the program.
_hook_report() { # events path [runner]
  local events=$1 path=$2 runner=$3 label=$2
  [ -n "$runner" ] && label="$path (run by ${runner##*/})"
  case "$path" in
    '')
      warn "$events: a hook has an empty command" ;;
    *'$'*)
      warn "$events: $label uses a variable, so it could not be checked" ;;
    /*)
      if [ ! -e "$path" ]; then
        bad "$events: $label is missing"
      elif [ ! -f "$path" ]; then
        bad "$events: $label is not a file"
      elif [ -z "$runner" ] && [ ! -x "$path" ]; then
        bad "$events: $label is not executable"
      else
        ok "$label exists ($events)"
      fi ;;
    */*)
      warn "$events: $label is a relative path, so it could not be checked" ;;
    *)
      if [ -n "$runner" ]; then
        warn "$events: $label is a relative path, so it could not be checked"
      elif command -v "$path" >/dev/null 2>&1; then
        ok "$path is on PATH ($events)"
      else
        warn "$events: $path is not on PATH"
      fi ;;
  esac
}

# Every command hook in the settings, as {event, command} objects.
_HOOKS_JQ='[ (.hooks // {}) | to_entries[] | .key as $event
  | (.value // [])[] | (.hooks // [])[]
  | select(.type == "command") | {event: $event, command: .command} ]'

check_claude_hooks() {
  local settings=$1 count events cmd
  if [ ! -f "$settings" ]; then
    warn "$settings does not exist, so hook commands were not checked (run make ai)"
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq is not installed, so hook commands in $settings were not checked"
    return 0
  fi
  # Two passes. This one validates the file and counts the hooks; its output
  # is a number, so it can go through $(...) and keep jq's error text.
  if ! count=$(jq "$_HOOKS_JQ | length" "$settings" 2>&1); then
    bad "$settings could not be read as Claude settings, so hook commands were not checked:"
    printf '%s\n' "$count" | detail
    return 0
  fi
  if [ "$count" = 0 ]; then
    skip "hook commands (none registered in $settings)"
    return 0
  fi
  # The second streams records as NUL-terminated pairs: the events, then the
  # command. Raw strings, not @tsv, so a backslash, tab or newline in a command
  # arrives as itself. $(...) would drop the NULs, hence the process
  # substitution. A command is prefixed "s" when it is a usable string, or "x"
  # plus its JSON when it is not (not a string, or holding a NUL).
  while IFS= read -r -d '' events && IFS= read -r -d '' cmd; do
    case "$cmd" in
      x*)
        warn "$events: a hook command is not a usable string (${cmd#x}), so it could not be checked"
        continue ;;
    esac
    _hook_command_words "${cmd#s}"
    _hook_report "$events" "$_hook_prog"
    if [ -n "$_hook_script" ]; then
      _hook_report "$events" "$_hook_script" "$_hook_prog"
    fi
  done < <(jq -j "$_HOOKS_JQ"'
      | group_by(.command)[]
      | (map(.event) | unique | join(", ")), "\u0000",
        (.[0].command
         | if type == "string" and (contains("\u0000") | not)
           then "s" + . else "x" + tojson end), "\u0000"
    ' "$settings")
}
