#!/usr/bin/env bash
#
# Install or remove the AWDL guard: a root LaunchDaemon that keeps awdl0 down
# so Wi-Fi stops stuttering under Synergy. See extras/awdl-guard/awdl-guard.
#
#   make awdl            (or bin/install-awdl-guard.sh)
#   make awdl-uninstall  (or bin/install-awdl-guard.sh uninstall)
#
# Separate from `make install` because it needs sudo and changes system state.
# Re-running is safe: when the installed copies match the repo and the daemon
# is running, it does nothing and asks for no password.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
LABEL=local.dotfiles.awdl-guard
SRC_BIN="$ROOT/extras/awdl-guard/awdl-guard"
SRC_PLIST="$ROOT/extras/awdl-guard/$LABEL.plist"
# Root-owned locations only: the daemon runs this as root, so a copy the user
# account could edit would be a privilege escalation.
BIN=/Library/PrivilegedHelperTools/$LABEL
PLIST=/Library/LaunchDaemons/$LABEL.plist

if [ "$(uname -s)" != Darwin ]; then
  echo "awdl-guard: macOS only" >&2
  exit 1
fi

running() {
  launchctl print "system/$LABEL" 2>/dev/null | grep -q 'state = running'
}

# bootout returns before the service is fully gone, and bootstrapping too soon
# fails with "Bootstrap failed: 5: Input/output error". Wait for it to go.
bootout() {
  sudo launchctl bootout "system/$LABEL" 2>/dev/null || true
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    launchctl print "system/$LABEL" >/dev/null 2>&1 || return 0
    sleep 0.5
  done
  echo "awdl-guard: $LABEL did not unload" >&2
  return 1
}

case "${1:-install}" in
  install)
    if cmp -s "$SRC_BIN" "$BIN" && cmp -s "$SRC_PLIST" "$PLIST" && running; then
      echo "awdl-guard: already installed and running"
      exit 0
    fi
    plutil -lint -s "$SRC_PLIST"
    bash -n "$SRC_BIN"
    sudo install -o root -g wheel -m 755 "$SRC_BIN" "$BIN"
    sudo install -o root -g wheel -m 644 "$SRC_PLIST" "$PLIST"
    # Reload so a changed script or plist takes effect.
    bootout
    sudo launchctl bootstrap system "$PLIST"
    if running; then
      echo "awdl-guard: installed and running (awdl status to check, awdl on to pause)"
    else
      echo "awdl-guard: loaded but not running -- see: launchctl print system/$LABEL" >&2
      exit 1
    fi
    ;;
  uninstall)
    bootout
    sudo rm -f "$BIN" "$PLIST"
    echo "awdl-guard: removed (AWDL comes back the next time macOS wants it)"
    ;;
  *)
    echo "usage: $0 [install|uninstall]" >&2
    exit 1
    ;;
esac
