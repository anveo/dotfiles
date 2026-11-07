# Sourced by bin/doctor (and test/doctor_claude_hooks_test.sh), not run.
#
# check_claude_hooks <settings.json>
#
# Every command hook registered in a Claude Code settings file must name a
# command that exists. A hook whose file is gone fails on every matching tool
# call, and nothing on disk is left dangling to say so: once the symlink is
# deleted, the stale command string in settings.json is the only trace.
#
# Reports through the caller's ok / warn / bad / skip / detail. Bash 3.2 safe.

# The first word of a hook command, with any leading VAR=value assignments
# skipped, surrounding quotes stripped, and ~/ or $HOME/ expanded. Claude Code
# runs the command through a shell, so those are what the shell would see.
_hook_command_word() {
  local cmd=$1 word
  while :; do
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"
    case "$cmd" in
      \"*) word=${cmd#\"}; word=${word%%\"*} ;;
      \'*) word=${cmd#\'}; word=${word%%\'*} ;;
      *)   word=${cmd%%[[:space:]]*} ;;
    esac
    case "$word" in
      [A-Za-z_]*=*) cmd=${cmd#"$word"} ;;
      *) break ;;
    esac
  done
  case "$word" in
    '~/'*)       word="$HOME/${word:2}" ;;
    '$HOME/'*)   word="$HOME/${word:6}" ;;
    '${HOME}/'*) word="$HOME/${word:8}" ;;
  esac
  printf '%s\n' "$word"
}

check_claude_hooks() {
  local settings=$1 rows events cmd word
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
    word=$(_hook_command_word "$cmd")
    case "$word" in
      '')
        warn "$events: a hook has an empty command" ;;
      *'$'*)
        warn "$events: $word uses a variable, so it could not be checked" ;;
      /*)
        if [ ! -e "$word" ]; then
          bad "$events: $word is missing"
        elif [ ! -f "$word" ] || [ ! -x "$word" ]; then
          bad "$events: $word is not an executable file"
        else
          ok "$word exists ($events)"
        fi ;;
      */*)
        warn "$events: $word is a relative path, so it could not be checked" ;;
      *)
        if command -v "$word" >/dev/null 2>&1; then
          ok "$word is on PATH ($events)"
        else
          warn "$events: $word is not on PATH"
        fi ;;
    esac
  done <<<"$rows"
}
