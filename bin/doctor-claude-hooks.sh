# Sourced by bin/doctor (and test/doctor_claude_hooks_test.sh), not run.
#
# check_claude_hooks <settings.json>
#
# Every command hook registered in a Claude Code settings file must name a
# command that exists. A hook whose file is gone fails on every matching tool
# call, and nothing on disk is left dangling to say so: once the symlink is
# deleted, the stale command string in settings.json is the only trace.
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
# VAR=value assignments. Every pass consumes input, so it always terminates.
_hook_command_words() {
  local cmd=$1 name rest
  _hook_prog=
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
}

# Report on the program a hook runs.
_hook_report() { # events path
  local events=$1 path=$2
  case "$path" in
    '')
      warn "$events: a hook has an empty command" ;;
    *'$'*)
      warn "$events: $path uses a variable, so it could not be checked" ;;
    /*)
      if [ ! -e "$path" ]; then
        bad "$events: $path is missing"
      elif [ ! -f "$path" ]; then
        bad "$events: $path is not a file"
      elif [ ! -x "$path" ]; then
        bad "$events: $path is not executable"
      else
        ok "$path exists ($events)"
      fi ;;
    */*)
      warn "$events: $path is a relative path, so it could not be checked" ;;
    *)
      if command -v "$path" >/dev/null 2>&1; then
        ok "$path is on PATH ($events)"
      else
        warn "$events: $path is not on PATH"
      fi ;;
  esac
}

check_claude_hooks() {
  local settings=$1 rows events cmd
  if [ ! -f "$settings" ]; then
    warn "$settings does not exist, so hook commands were not checked (run make ai)"
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq is not installed, so hook commands in $settings were not checked"
    return 0
  fi
  if ! rows=$(jq -r '
      [ (.hooks // {}) | to_entries[] | .key as $event
        | (.value // [])[] | (.hooks // [])[]
        | select(.type == "command") | {event: $event, command: .command} ]
      | group_by(.command)[]
      | [ (map(.event) | unique | join(", ")), .[0].command ] | @tsv
    ' "$settings" 2>&1); then
    bad "$settings could not be read as Claude settings, so hook commands were not checked:"
    printf '%s\n' "$rows" | detail
    return 0
  fi
  if [ -z "$rows" ]; then
    skip "hook commands (none registered in $settings)"
    return 0
  fi
  while IFS=$'\t' read -r events cmd; do
    _hook_command_words "$cmd"
    _hook_report "$events" "$_hook_prog"
  done <<<"$rows"
}
