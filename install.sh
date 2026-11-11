#!/usr/bin/env bash
# Install Plymouth themes from this repo.
#
# Usage:
#   sudo ./install.sh                 # interactive menu
#   sudo ./install.sh <theme>         # install and activate one theme
#   sudo ./install.sh --all           # install all themes (no activation)
#   sudo ./install.sh --list          # list available themes
#   sudo ./install.sh --remove <theme>
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_TARBALL="https://github.com/fhudint/plymouth-thems/archive/refs/heads/main.tar.gz"
DEST_DIR="/usr/share/plymouth/themes"

die() { echo "ERROR: $*" >&2; exit 1; }

# A theme is any top-level folder containing <name>/<name>.plymouth
list_themes() {
  local d
  for d in "$SRC_DIR"/*/; do
    d="${d%/}"
    [[ -f "$d/$(basename "$d").plymouth" ]] && basename "$d"
  done
}

require_root() {
  [[ $EUID -eq 0 ]] || die "Run this as root (e.g. sudo $0 $*)"
}

require_plymouth() {
  [[ -d $DEST_DIR ]] || die "$DEST_DIR not found. Is plymouth installed?"
}

has_theme() { list_themes | grep -qx "$1"; }

install_theme() {
  local t="$1"
  has_theme "$t" || die "Unknown theme '$t'. Available: $(list_themes | tr '\n' ' ')"
  echo "==> Installing '$t' to $DEST_DIR/$t"
  rm -rf "${DEST_DIR:?}/$t"
  mkdir -p "$DEST_DIR/$t"
  cp -r "$SRC_DIR/$t/." "$DEST_DIR/$t/"
  # Files that are not needed at boot time
  rm -rf "$DEST_DIR/$t/assets" "$DEST_DIR/$t/LICENSE"
  find "$DEST_DIR/$t" -name '*~' -delete
}

rebuild_initramfs() {
  echo "==> Rebuilding initramfs (this can take a moment)"
  if command -v plymouth-set-default-theme >/dev/null 2>&1 && [[ -n ${1:-} ]]; then
    # Fedora/RHEL/openSUSE: -R rebuilds initramfs itself
    if plymouth-set-default-theme -R "$1" 2>/dev/null; then return; fi
  fi
  if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -u
  elif command -v dracut >/dev/null 2>&1; then
    dracut -f
  elif command -v mkinitcpio >/dev/null 2>&1; then
    mkinitcpio -P
  else
    echo "WARNING: no known initramfs tool found; rebuild it manually." >&2
  fi
}

activate_theme() {
  local t="$1"
  echo "==> Activating '$t'"
  if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme "$t"
  elif command -v update-alternatives >/dev/null 2>&1; then
    update-alternatives --install "$DEST_DIR/default.plymouth" default.plymouth \
      "$DEST_DIR/$t/$t.plymouth" 100
    update-alternatives --set default.plymouth "$DEST_DIR/$t/$t.plymouth"
  else
    die "Cannot set default theme: plymouth-set-default-theme not found."
  fi
  rebuild_initramfs "$t"
  echo "==> Done. Reboot to see '$t'."
  echo "    Note: Plymouth needs 'splash' in the kernel command line (e.g. GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\")."
}

remove_theme() {
  local t="$1"
  [[ -d $DEST_DIR/$t ]] || die "Theme '$t' is not installed."
  echo "==> Removing '$t'"
  rm -rf "${DEST_DIR:?}/$t"
  echo "    If it was the active theme, pick another one and rebuild the initramfs."
}

menu() {
  local themes=() t choice
  mapfile -t themes < <(list_themes)
  [[ ${#themes[@]} -gt 0 ]] || die "No themes found in $SRC_DIR"
  echo "Available themes:"
  local i=1
  for t in "${themes[@]}"; do echo "  $i) $t"; i=$((i + 1)); done
  read -rp "Choose a theme [1-${#themes[@]}]: " choice </dev/tty
  [[ $choice =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#themes[@]} )) || die "Invalid choice."
  t="${themes[choice-1]}"
  install_theme "$t"
  activate_theme "$t"
}

# Remote mode: when run via `curl ... | sudo bash`, the theme files are not next
# to the script, so download the repo to a temp dir and run the copy from there.
bootstrap_remote() {
  command -v curl >/dev/null || die "curl is required for remote install."
  command -v tar  >/dev/null || die "tar is required for remote install."
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "==> Downloading themes..."
  curl -fsSL "$REPO_TARBALL" | tar -xz -C "$tmp" --strip-components=1
  [[ -f $tmp/install.sh ]] || die "Download failed or archive layout changed."
  bash "$tmp/install.sh" "$@"
  exit $?
}

if [[ -z "$(list_themes)" ]]; then
  bootstrap_remote "$@"
fi

case "${1:-}" in
  -h|--help)
    sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
  -l|--list)
    list_themes ;;
  --all)
    require_root "$@"; require_plymouth
    for t in $(list_themes); do install_theme "$t"; done
    echo "==> All themes installed. Activate one with: sudo $0 <theme>" ;;
  --remove)
    [[ -n ${2:-} ]] || die "Usage: $0 --remove <theme>"
    require_root "$@"; require_plymouth
    remove_theme "$2" ;;
  "")
    require_root "$@"; require_plymouth
    menu ;;
  -*)
    die "Unknown option '$1'. See --help." ;;
  *)
    require_root "$@"; require_plymouth
    install_theme "$1"
    activate_theme "$1" ;;
esac
