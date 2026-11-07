#!/usr/bin/env bash
#
# Tests for bin/doctor-claude-hooks.sh, the `== claude hooks ==` check in
# bin/doctor: every command hook registered in ~/.claude/settings.json must
# name a command that exists.
#
#   bash test/doctor_claude_hooks_test.sh
#
# `make check` runs it. Every fixture lives in a temp dir, and HOME points
# there, so the real ~/.claude is never read or written.

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed; cannot run these tests (brew install jq)"
  exit 1
fi

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT
PASS=0
FAIL=0

pass() { PASS=$((PASS+1)); echo "  ok   $1"; }
fail() { FAIL=$((FAIL+1)); echo "  FAIL $1"; }

# Run the check against a settings file with HOME=$TMPROOT. The reporters are
# stubs that print a level and the message, one line each.
run_check() { # settings [PATH]
  (
    export HOME=$TMPROOT
    [ -n "$2" ] && PATH=$2
    ok()     { echo "OK $1"; }
    warn()   { echo "WARN $1"; }
    bad()    { echo "FAIL $1"; }
    skip()   { echo "SKIP $1"; }
    detail() { while IFS= read -r line; do echo "  $line"; done; }
    . "$ROOT/bin/doctor-claude-hooks.sh"
    check_claude_hooks "$1"
  )
}

# Pass when output has a line starting with level and containing every needle.
expect() { # name output level needle...
  local name=$1 out=$2 level=$3 line needle hit
  shift 3
  while IFS= read -r line; do
    case "$line" in "$level "*) ;; *) continue ;; esac
    hit=1
    for needle in "$@"; do
      case "$line" in *"$needle"*) ;; *) hit= ;; esac
    done
    if [ -n "$hit" ]; then pass "$name"; return; fi
  done <<<"$out"
  fail "$name (no $level line with: $*; got: $out)"
}

# Pass when output has no line at that level.
expect_none() { # name output level
  case $'\n'"$2" in
    *$'\n'"$3 "*) fail "$1 (unexpected $3 in: $2)" ;;
    *) pass "$1" ;;
  esac
}

settings() { # file hooks-json
  printf '{"hooks": %s}\n' "$2" >"$1"
}

hooks="$TMPROOT/.claude/hooks"
mkdir -p "$hooks"
printf '#!/bin/sh\n' >"$hooks/present"
chmod +x "$hooks/present"
printf '#!/bin/sh\n' >"$hooks/not-executable"

echo "== a registered hook file that is gone =="
# The case that motivated the check: worktree-guard renamed away, its
# settings.json entry left behind.
f="$TMPROOT/renamed.json"
settings "$f" '{"PreToolUse": [{"matcher": "Bash", "hooks": [
  {"type": "command", "command": "'"$hooks"'/worktree-guard"}]}]}'
out=$(run_check "$f")
expect "FAILs naming the event and the path" "$out" FAIL PreToolUse "$hooks/worktree-guard"

echo "== absolute paths =="
f="$TMPROOT/abs.json"
settings "$f" '{"PreToolUse": [{"hooks": [
  {"type": "command", "command": "'"$hooks"'/not-executable --flag"}]}],
  "SessionStart": [{"hooks": [
  {"type": "command", "command": "'"$hooks"'/present --source claude"}]}],
  "Stop": [{"hooks": [
  {"type": "command", "command": "'"$hooks"'/present --source claude"}]}]}'
out=$(run_check "$f")
expect "FAILs on a file that is not executable" "$out" FAIL PreToolUse "$hooks/not-executable"
expect "a present executable is ok" "$out" OK "$hooks/present"
expect "one line lists every event that runs a command" "$out" OK "SessionStart, Stop"
f="$TMPROOT/dir.json"
settings "$f" '{"Stop": [{"hooks": [{"type": "command", "command": "'"$hooks"'"}]}]}'
expect "FAILs on a directory" "$(run_check "$f")" FAIL "$hooks"

echo "== home-relative paths =="
f="$TMPROOT/home.json"
settings "$f" '{"Stop": [{"hooks": [
  {"type": "command", "command": "~/.claude/hooks/present"},
  {"type": "command", "command": "$HOME/.claude/hooks/gone-a"},
  {"type": "command", "command": "${HOME}/.claude/hooks/gone-b"},
  {"type": "command", "command": "\"$HOME/.claude/hooks/gone-d\" arg"},
  {"type": "command", "command": "DEBUG=1 ~/.claude/hooks/gone-c"},
  {"type": "command", "command": "$OTHER/bin/thing"}]}]}'
out=$(run_check "$f")
expect "~/ expands to HOME" "$out" OK "$hooks/present"
expect "\$HOME/ expands" "$out" FAIL "$hooks/gone-a"
expect "\${HOME}/ expands" "$out" FAIL "$hooks/gone-b"
expect "a quoted path is unquoted, then expanded" "$out" FAIL "$hooks/gone-d is"
expect "a leading VAR=value is skipped" "$out" FAIL "$hooks/gone-c"
expect "any other variable WARNs as unverifiable" "$out" WARN '$OTHER/bin/thing'

echo "== VAR=value prefixes =="
# A quoted assignment once looped forever; every case here has to return.
f="$TMPROOT/assign.json"
settings "$f" '{"Stop": [{"hooks": [
  {"type": "command", "command": "\"A=1\" ~/.claude/hooks/gone-e"},
  {"type": "command", "command": "FOO=\"a b\" ~/.claude/hooks/gone-f"},
  {"type": "command", "command": "X='"'"'c d'"'"' Y=2 ~/.claude/hooks/gone-g"},
  {"type": "command", "command": "a/b=c ~/.claude/hooks/present"}]}]}'
out=$(run_check "$f")
expect "a quoted assignment is the program, not a prefix" "$out" WARN "A=1 is not on PATH"
expect "a double-quoted value with a space is skipped whole" "$out" FAIL "$hooks/gone-f"
expect "several assignments, single-quoted, are skipped" "$out" FAIL "$hooks/gone-g"
expect "a word that is not a shell name is not an assignment" "$out" WARN "a/b=c is a relative path"

echo "== scripts run by an interpreter =="
f="$TMPROOT/interp.json"
settings "$f" '{"PreToolUse": [{"hooks": [
  {"type": "command", "command": "/bin/sh -e ~/.claude/hooks/gone.sh --flag"},
  {"type": "command", "command": "sh ~/.claude/hooks/not-executable"},
  {"type": "command", "command": "sh -c \"exit 0\""},
  {"type": "command", "command": "sh hook.sh"}]}]}'
out=$(run_check "$f")
expect "a missing script FAILs, naming the event and runner" "$out" FAIL PreToolUse "$hooks/gone.sh (run by sh) is missing"
expect "the interpreter itself is still checked" "$out" OK "/bin/sh exists"
expect "a script need not be executable" "$out" OK "$hooks/not-executable (run by sh) exists"
expect "a relative script WARNs as unverifiable" "$out" WARN "hook.sh (run by sh) is a relative path"
expect_none "inline code (-c) has no script to check" "$(printf '%s\n' "$out" | grep 'exit')" WARN

echo "== bare commands =="
f="$TMPROOT/bare.json"
settings "$f" '{"PreToolUse": [{"matcher": "Bash", "hooks": [
  {"type": "command", "command": "sh -c true"},
  {"type": "command", "command": "doctor-test-no-such-command hook claude"}]}]}'
out=$(run_check "$f")
expect "a command on PATH is ok" "$out" OK "sh is on PATH"
expect "a command not on PATH WARNs, naming the event" "$out" WARN PreToolUse doctor-test-no-such-command
expect_none "a missing bare command does not FAIL" "$out" FAIL

echo "== commands are read raw, not @tsv-escaped =="
printf '#!/bin/sh\n' >"$hooks/back\\slash"
chmod +x "$hooks/back\\slash"
f="$TMPROOT/raw.json"
settings "$f" '{"PreToolUse": [{"hooks": [
  {"type": "command", "command": "'"$hooks"'/back\\slash"}]}],
  "Stop": [{"hooks": [
  {"type": "command", "command": "'"$hooks"'/present\t--tab"}]}],
  "Notification": [{"hooks": [
  {"type": "command", "command": "'"$hooks"'/present\n--newline"}]}]}'
out=$(run_check "$f")
expect "a backslash in an existing path is ok" "$out" OK "$hooks/back\\slash exists"
expect "a tab ends the program word" "$out" OK "$hooks/present exists" Stop
expect "a newline ends the program word" "$out" OK "$hooks/present exists" Notification
expect_none "none of them FAILs" "$out" FAIL

echo "== commands that are not strings =="
f="$TMPROOT/nonstring.json"
settings "$f" '{"Stop": [{"hooks": [
  {"type": "command", "command": null},
  {"type": "command", "command": 42},
  {"type": "command", "command": {"a": 1}},
  {"type": "command", "command": "'"$hooks"'/present"}]}]}'
out=$(run_check "$f")
expect "null WARNs" "$out" WARN "not a usable string (null)"
expect "a number WARNs" "$out" WARN "not a usable string (42)"
expect "an object WARNs" "$out" WARN 'not a usable string ({"a":1})'
expect "the other hooks are still checked" "$out" OK "$hooks/present exists"
expect_none "a non-string is not a FAIL" "$out" FAIL

echo "== nothing to check is never ok =="
out=$(run_check "$TMPROOT/absent.json")
expect "a missing settings file WARNs" "$out" WARN "absent.json"
f="$TMPROOT/invalid.json"
printf '{"hooks": \n' >"$f"
out=$(run_check "$f")
expect "invalid JSON FAILs" "$out" FAIL "invalid.json"
f="$TMPROOT/empty.json"
printf '{}\n' >"$f"
out=$(run_check "$f")
expect "no hooks skips" "$out" SKIP "none registered"
expect_none "no hooks is not ok" "$out" OK
f="$TMPROOT/prompt-only.json"
settings "$f" '{"Stop": [{"hooks": [{"type": "prompt", "prompt": "check"}]}]}'
expect "only non-command hooks skips" "$(run_check "$f")" SKIP "none registered"
out=$(run_check "$TMPROOT/renamed.json" "$TMPROOT/no-bin")
expect "without jq it WARNs" "$out" WARN "jq is not installed"
expect_none "without jq it is not ok" "$out" OK

echo "passed $PASS, failed $FAIL"
[ "$FAIL" -eq 0 ]
