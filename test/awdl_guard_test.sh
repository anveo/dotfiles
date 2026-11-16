#!/usr/bin/env bash
#
# Tests for extras/awdl-guard/awdl-guard, the loop that keeps awdl0 down.
#
#   bash test/awdl_guard_test.sh
#
# `make check` runs it, on macOS and Linux alike: ifconfig, route and logger
# are shims on PATH, so no real interface is touched and nothing needs root.
# The fake awdl0's state is a file; the fake `route -n monitor` reads from a
# FIFO the test writes to, so a routing message is a line written on demand.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
GUARD="$ROOT/extras/awdl-guard/awdl-guard"
TMPROOT=$(mktemp -d)
GUARD_PID=
cleanup() {
  [ -n "$GUARD_PID" ] && kill "$GUARD_PID" 2>/dev/null
  rm -rf "$TMPROOT"
}
trap cleanup EXIT
PASS=0
FAIL=0

pass() { PASS=$((PASS+1)); echo "  ok   $1"; }
fail() { FAIL=$((FAIL+1)); echo "  FAIL $1"; }

SHIMS="$TMPROOT/shims"
STATE="$TMPROOT/awdl0"
FIFO="$TMPROOT/routes"
mkdir -p "$SHIMS"

cat >"$SHIMS/ifconfig" <<'EOF'
#!/bin/sh
[ "$1" = awdl0 ] || exit 1
case "$2" in
  down) echo down >"$AWDL_TEST_STATE" ;;
  up) echo up >"$AWDL_TEST_STATE" ;;
  '')
    if [ "$(cat "$AWDL_TEST_STATE")" = up ]; then
      echo "awdl0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 1500"
    else
      echo "awdl0: flags=8802<BROADCAST,SIMPLEX,MULTICAST> mtu 1500"
    fi ;;
esac
EOF
cat >"$SHIMS/route" <<'EOF'
#!/bin/sh
exec cat "$AWDL_TEST_FIFO"
EOF
cat >"$SHIMS/logger" <<'EOF'
#!/bin/sh
EOF
chmod +x "$SHIMS"/*
export AWDL_TEST_STATE="$STATE" AWDL_TEST_FIFO="$FIFO"

# Start the guard against a fresh fake awdl0 in the given state, and hold the
# FIFO's write end open on fd 4 so the fake route monitor stays alive.
start() { # initial-state recheck-seconds
  echo "$1" >"$STATE"
  rm -f "$FIFO"
  mkfifo "$FIFO"
  # /bin/bash, as the plist runs it: bash 3.2 on macOS, not Homebrew's.
  PATH="$SHIMS:$PATH" AWDL_GUARD_RECHECK=$2 /bin/bash "$GUARD" &
  GUARD_PID=$!
  exec 4>"$FIFO"
}

stop() {
  exec 4>&-
  kill "$GUARD_PID" 2>/dev/null
  wait "$GUARD_PID" 2>/dev/null
  GUARD_PID=
}

# Poll until awdl0 is down; true if it gets there within the limit.
goes_down() { # seconds
  local i
  for i in $(seq 1 $(($1 * 10))); do
    [ "$(cat "$STATE")" = down ] && return 0
    sleep 0.1
  done
  return 1
}

echo "== awdl-guard =="

# A 60s recheck rules out the timer: only the startup check or a routing
# message can explain awdl0 going down inside these limits.
start up 60
if goes_down 3; then pass "takes awdl0 down at startup"; else fail "takes awdl0 down at startup"; fi

echo up >"$STATE"
sleep 0.3
echo "RTM_IFINFO: iface status change" >&4
if goes_down 3; then pass "a routing message triggers a check"; else fail "a routing message triggers a check"; fi

echo up >"$STATE"
sleep 0.5
if [ "$(cat "$STATE")" = up ]; then
  pass "with no message, waits for the recheck"
else
  fail "with no message, waits for the recheck"
fi
stop

start down 1
sleep 0.3
echo up >"$STATE"
if goes_down 4; then pass "the recheck timer catches it without a message"; else fail "the recheck timer catches it without a message"; fi

# route monitor ending must end the guard, non-zero, so KeepAlive restarts it.
exec 4>&-
rc=
for _ in $(seq 1 30); do
  if ! kill -0 "$GUARD_PID" 2>/dev/null; then
    wait "$GUARD_PID"
    rc=$?
    break
  fi
  sleep 0.1
done
GUARD_PID=
if [ -n "$rc" ] && [ "$rc" -ne 0 ]; then
  pass "exits non-zero when route monitor ends"
else
  fail "exits non-zero when route monitor ends (rc=${rc:-still running})"
fi

echo "passed $PASS, failed $FAIL"
[ "$FAIL" -eq 0 ]
