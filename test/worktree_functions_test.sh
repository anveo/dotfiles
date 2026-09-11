#!/usr/bin/env bash
#
# Argument handling for the worktree functions in bash/functions.
#
# wta and wtr hand-roll the same parser, and the only thing keeping them
# identical is that someone checks. That is what this file is for -- the cases
# are deliberately written twice, once per function, rather than factored into
# a loop, so a divergence shows up as a named failing case instead of a
# parameter.
#
# Run under both shells; zsh is the one that matters, since that is what
# actually sources bash/functions:
#
#   bash test/worktree_functions_test.sh
#   zsh  test/worktree_functions_test.sh
#
# `make check` runs both.
#
# No `set -u`: bash/functions is written for interactive shells, which do not
# use it, and the bare "$1" and "$TMUX" tests in both functions would trip it.

FUNCS="${FUNCS:-$(cd "$(dirname "$0")/.." && pwd)/bash/functions}"
if [ ! -r "$FUNCS" ]; then
  echo "cannot read $FUNCS" >&2
  exit 1
fi
# shellcheck disable=SC1090
. "$FUNCS"

unset TMUX              # no window bookkeeping; not what these cover
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT
PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL $1"; }

# Run a command, then assert on its exit status and on one stream's content.
# `rc` rather than `status`, which zsh makes read-only.
expect() { # name want_rc stream needle -- cmd...
  local name=$1 want=$2 stream=$3 needle=$4
  shift 4
  local out err rc text
  out=$("$@" 2>"$TMPROOT/err"); rc=$?
  err=$(cat "$TMPROOT/err")
  text=$out
  [ "$stream" = stderr ] && text=$err
  if [ "$rc" -ne "$want" ]; then
    bad "$name (exit $rc, wanted $want)"
    return
  fi
  case "$text" in
    *"$needle"*) ok "$name" ;;
    *) bad "$name (no '$needle' on $stream; got: $(printf '%s' "$text" | head -c 120))" ;;
  esac
}

# A repo with an optional bin/ hook. `kind` is what the stub does with its
# arguments: "record" writes them down, "reject" refuses any (a script older
# than --db), "none" means no script at all.
make_repo() { # id hook_name kind -> echoes repo path
  local id=$1 hook=$2 kind=$3
  local repo="$TMPROOT/r$id"
  mkdir -p "$repo"
  {
    git -C "$repo" init -q -b main
    git -C "$repo" config user.email test@example.com
    git -C "$repo" config user.name Test
  } >/dev/null 2>&1
  if [ "$kind" != none ]; then
    mkdir -p "$repo/bin"
    if [ "$kind" = reject ]; then
      printf '#!/bin/sh\nif [ $# -gt 0 ]; then echo "%s: unknown argument $1" >&2; exit 1; fi\n' \
        "$hook" > "$repo/bin/$hook"
    else
      # One line per argument, so a relay that collapses "--db drop" into a
      # single word fails on the count rather than sliding through.
      printf '#!/bin/sh\n{ echo "count=$#"; for a in "$@"; do echo "arg=$a"; done; } > "$WT_STUB_LOG"\n' \
        > "$repo/bin/$hook"
      # A real worktree-setup writes .envrc.worktree, and wtinfo -- which wta
      # calls last -- returns non-zero without it. Stub that too, or every wta
      # case fails on an exit status that has nothing to do with the relay.
      if [ "$hook" = worktree-setup ]; then
        printf 'export APP_HOST=stub.example\nexport PORT=9999\n' >> "$repo/bin/$hook.env"
        printf 'cp "$(dirname "$0")/worktree-setup.env" .envrc.worktree\n' >> "$repo/bin/$hook"
      fi
    fi
    chmod +x "$repo/bin/$hook"
  fi
  echo seed > "$repo/README"
  git -C "$repo" add -A >/dev/null 2>&1
  git -C "$repo" commit -qm seed >/dev/null 2>&1
  echo "$repo"
}

stub_log_is() { # name expected-log-body
  local name=$1 want=$2
  local got
  got=$(cat "$WT_STUB_LOG" 2>/dev/null)
  if [ "$got" = "$want" ]; then
    ok "$name"
  else
    bad "$name (stub saw [$(printf '%s' "$got" | tr '\n' ' ')], wanted [$(printf '%s' "$want" | tr '\n' ' ')])"
  fi
}

echo "== wtr: argument parsing =="
expect "wtr --help exits 0, usage on stdout"   0 stdout "usage: wtr [--db keep|drop] <branch>" wtr --help
expect "wtr -h exits 0, usage on stdout"       0 stdout "usage: wtr"                           wtr -h
expect "wtr with no args exits 1"              1 stderr "usage: wtr"                           wtr
expect "wtr rejects an unknown flag"           1 stderr "unknown option --bogus"               wtr --bogus br
expect "wtr rejects --db with no value"        1 stderr "--db needs a value"                   wtr --db
expect "wtr rejects an empty --db="            1 stderr "--db needs a value"                   wtr --db= br
expect "wtr rejects a bad --db value"          1 stderr "--db must be keep or drop (got 'x')"  wtr --db x br
expect "wtr rejects a flag after the branch"   1 stderr "flags go before the branch"           wtr br --db drop

echo "== wta: argument parsing (the same cases, deliberately repeated) =="
expect "wta --help exits 0, usage on stdout"   0 stdout "usage: wta [-w] [--db reuse|clone] <branch>" wta --help
expect "wta -h exits 0, usage on stdout"       0 stdout "usage: wta"                                  wta -h
expect "wta with no args exits 1"              1 stderr "usage: wta"                                  wta
expect "wta rejects an unknown flag"           1 stderr "unknown option --bogus"                      wta --bogus br
expect "wta rejects --db with no value"        1 stderr "--db needs a value"                          wta --db
expect "wta rejects an empty --db="            1 stderr "--db needs a value"                          wta --db= br
expect "wta rejects a bad --db value"          1 stderr "--db must be reuse or clone (got 'x')"       wta --db x br
expect "wta rejects a flag after the branch"   1 stderr "flags go before the branch"                  wta br --db clone

echo "== wtr: relay to bin/worktree-teardown =="
wtr_relay() { # name id expected-log flag...
  local name=$1 id=$2 want=$3; shift 3
  local repo branch
  repo=$(make_repo "$id" worktree-teardown record)
  branch="TST-$id-relay"
  export WT_STUB_LOG="$TMPROOT/teardown.$id"
  : > "$WT_STUB_LOG"
  ( cd "$repo" && git wta "$branch" ) >/dev/null 2>&1 || { bad "$name (setup)"; return; }
  ( cd "$repo" && wtr "$@" "$branch" ) >/dev/null 2>&1 || { bad "$name (wtr failed)"; return; }
  stub_log_is "$name" "$want"
  [ -d "$repo.worktrees/$branch" ] && bad "$name (worktree survived)"
  return 0
}

# The count assertion is the load-bearing one: if the array ever becomes a
# string, zsh passes "--db drop" as a single argument and count drops to 1.
wtr_relay "--db drop arrives as two arguments" tr1 "count=2
arg=--db
arg=drop" --db drop
wtr_relay "--db=keep arrives as two arguments" tr2 "count=2
arg=--db
arg=keep" --db=keep
wtr_relay "no flag passes no arguments" tr3 "count=0"

echo "== wta: relay to bin/worktree-setup =="
wta_relay() { # name id expected-log flag...
  local name=$1 id=$2 want=$3; shift 3
  local repo branch
  repo=$(make_repo "$id" worktree-setup record)
  branch="TST-$id-relay"
  export WT_STUB_LOG="$TMPROOT/setup.$id"
  : > "$WT_STUB_LOG"
  # -w so the test shell is not cd'd into the worktree; outside tmux this
  # provisions and reports rather than opening a window.
  ( cd "$repo" && wta -w "$@" "$branch" ) >/dev/null 2>&1 || { bad "$name (wta failed)"; return; }
  stub_log_is "$name" "$want"
  return 0
}

wta_relay "--db clone arrives as two arguments" ta1 "count=2
arg=--db
arg=clone" --db clone
wta_relay "--db=reuse arrives as two arguments" ta2 "count=2
arg=--db
arg=reuse" --db=reuse
wta_relay "no flag passes no arguments" ta3 "count=0"

echo "== repos whose bin/ scripts do not take the flag =="

# No script at all: the flag has nothing to act on, so it is ignored and the
# worktree still goes away.
repo=$(make_repo none1 worktree-teardown none)
( cd "$repo" && git wta TST-none ) >/dev/null 2>&1
if ( cd "$repo" && wtr --db drop TST-none ) >/dev/null 2>&1; then
  if [ -d "$repo.worktrees/TST-none" ]; then
    bad "wtr --db with no teardown script: worktree survived"
  else
    ok "wtr --db with no teardown script is ignored, worktree removed"
  fi
else
  bad "wtr --db with no teardown script should exit 0"
fi

# A script older than the flag: it refuses the unknown argument and wtr stops.
# Pinned because it is the one path --db cannot paper over -- the removal is
# abandoned after overmind is already down. If this ever starts passing, the
# behaviour changed and the comment in bash/functions needs to change with it.
repo=$(make_repo old1 worktree-teardown reject)
( cd "$repo" && git wta TST-old ) >/dev/null 2>&1
if ( cd "$repo" && wtr --db drop TST-old ) >/dev/null 2>&1; then
  bad "wtr --db against an older teardown should fail loudly, not silently succeed"
else
  if [ -d "$repo.worktrees/TST-old" ]; then
    ok "wtr --db against an older teardown stops the removal (worktree left in place)"
  else
    bad "wtr --db against an older teardown removed the worktree anyway"
  fi
fi

# Without the flag, the same older script is called exactly as it always was.
repo=$(make_repo old2 worktree-teardown reject)
( cd "$repo" && git wta TST-old-noflag ) >/dev/null 2>&1
if ( cd "$repo" && wtr TST-old-noflag ) >/dev/null 2>&1; then
  ok "wtr without --db still works against an older teardown"
else
  bad "wtr without --db should not disturb an older teardown"
fi

# A repo with no worktree-setup at all is the `/dispatch --worktree` case:
# the worktree exists for isolation, there is nothing to provision, and that is
# success rather than a half-done job. wta ends by calling wtinfo, which draws
# exactly this distinction -- 0 for "repo has no worktree-setup", 1 for "has one
# and it never ran" -- so wta's exit status inherits it. Worth pinning: it is
# the difference between a quiet no-op and a silent failure.
repo=$(make_repo noprov worktree-setup none)
if ( cd "$repo" && wta -w TST-noprov ) >/dev/null 2>&1; then
  if [ -d "$repo.worktrees/TST-noprov" ]; then
    ok "wta -w in a repo with nothing to provision exits 0 and creates the worktree"
  else
    bad "wta -w exited 0 without creating the worktree"
  fi
else
  bad "wta -w in a repo with nothing to provision should exit 0"
fi

echo
echo "passed $PASS, failed $FAIL"
[ "$FAIL" -eq 0 ]
