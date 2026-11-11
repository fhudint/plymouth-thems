#!/usr/bin/env bash
# Preview an installed Plymouth theme for a few seconds, then restore the
# previously active theme.
#
# Usage: sudo ./preview.sh <theme> [seconds]     (default: 5 seconds)
# The theme must already be installed (see ./install.sh --all).
set -euo pipefail

THEME_DIR="/usr/share/plymouth/themes"
THEME="${1:-}"
SECONDS_TO_SHOW="${2:-5}"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "You must run this as root (sudo $0 <theme> [seconds])"
[[ -n $THEME ]] || die "Usage: $0 <theme> [seconds]"
[[ $SECONDS_TO_SHOW =~ ^[0-9]+$ ]] || die "Seconds must be a number."
[[ -f $THEME_DIR/$THEME/$THEME.plymouth ]] || die "Theme '$THEME' is not installed. Run: sudo ./install.sh --all"
command -v plymouthd >/dev/null || die "plymouthd not found."
command -v plymouth-set-default-theme >/dev/null || die "plymouth-set-default-theme not found."
pgrep -x plymouthd >/dev/null && die "plymouthd is already running."

PREVIOUS="$(plymouth-set-default-theme)"
STARTED=0

cleanup() {
  if (( STARTED )); then plymouth quit 2>/dev/null || true; fi
  plymouth-set-default-theme "$PREVIOUS" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

plymouth-set-default-theme "$THEME"   # no -R: initramfs is not touched
plymouthd
STARTED=1
plymouth --show-splash
sleep "$SECONDS_TO_SHOW"
