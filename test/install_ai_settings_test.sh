#!/usr/bin/env bash
#
# Tests for the ~/.claude cleanup in bin/install-ai.sh and the settings.json
# edit it delegates to bin/claude-settings-hooks.py: retired hooks (rtk,
# worktree-guard) are removed, the runway hooks are registered, and a second
# run changes nothing.
#
#   bash test/install_ai_settings_test.sh
#
# `make check` runs it. install-ai.sh runs with HOME pointing at a temp dir, so
# every link and edit lands there and the real ~/.claude is never touched.

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

check() { # name command...
  local name=$1
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}

# A fresh HOME per scenario. Prints its path.
new_home() {
  local home
  home=$(mktemp -d "$TMPROOT/home.XXXXXX")
  mkdir -p "$home/.claude"
  echo "$home"
}

run_install() { # home
  HOME=$1 bash "$ROOT/bin/install-ai.sh" >"$1/install.out" 2>&1
}

# jq -e against the settings file; true when the filter is truthy.
settings_has() { # home filter
  jq -e "$2" "$1/.claude/settings.json" >/dev/null
}

commands='[.hooks[][].hooks[].command]'

echo "== rtk registrations are removed =="
home=$(new_home)
cat >"$home/.claude/settings.json" <<'JSON'
{
  "model": "opus",
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "rtk hook claude"}]},
      {"matcher": "Bash", "hooks": [
        {"type": "command", "command": "/opt/homebrew/bin/rtk hook claude"},
        {"type": "command", "command": "keep-me --no-rtk"}
      ]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "/Users/x/.claude/hooks/rtk-rewrite.sh"}]}
    ],
    "PostToolUse": [
      {"hooks": [{"type": "command", "command": "echo unrelated"}]}
    ]
  }
}
JSON
echo "rtk instructions" >"$home/.claude/RTK.md"

check "install-ai.sh exits 0" run_install "$home"
check "no rtk command is left" settings_has "$home" \
  "$commands | map(select(test(\"(^|/)rtk( |\$)|rtk-rewrite\\\\.sh\"))) | length == 0"
check "a hook sharing an entry with rtk survives" settings_has "$home" \
  '.hooks.PreToolUse | map(select(.hooks[].command == "keep-me --no-rtk")) | length == 1'
check "an entry left empty is dropped" settings_has "$home" \
  '.hooks.PreToolUse | map(select(.hooks | length == 0)) | length == 0'
check "an unrelated hook survives" settings_has "$home" \
  "$commands | index(\"echo unrelated\") != null"
check "other settings survive" settings_has "$home" '.model == "opus"'
check "runway-write-guard is registered" settings_has "$home" \
  "$commands | index(\"$home/.claude/hooks/runway-write-guard\") != null"
check "runway-callsign is registered" settings_has "$home" \
  "$commands | index(\"$home/.claude/hooks/runway-callsign\") != null"
check "RTK.md is removed" test ! -e "$home/.claude/RTK.md"

echo "== a second run changes nothing =="
cp "$home/.claude/settings.json" "$TMPROOT/first.json"
check "install-ai.sh exits 0 again" run_install "$home"
check "settings.json is byte-identical" cmp -s "$TMPROOT/first.json" "$home/.claude/settings.json"
check "nothing is reported removed" bash -c "! grep -q -e 'removed retired' -e 'rm .*RTK.md' '$home/install.out'"

echo "== RTK.md as a dangling symlink =="
home=$(new_home)
ln -s "$TMPROOT/nowhere/RTK.md" "$home/.claude/RTK.md"
check "install-ai.sh exits 0" run_install "$home"
check "the symlink is removed" test ! -L "$home/.claude/RTK.md"

echo "== no settings.json yet =="
home=$(new_home)
check "install-ai.sh exits 0" run_install "$home"
check "settings.json is created with the runway hooks" settings_has "$home" \
  "$commands | length == 2"

echo "passed $PASS, failed $FAIL"
[ "$FAIL" -eq 0 ]
