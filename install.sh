#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_BASE="https://raw.githubusercontent.com/iliya-Developer/Backhaul-script/main"
INSTALL_PATH="/usr/local/bin/backhaul-menu"

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    echo "Please run as root (sudo)." >&2
    exit 1
  fi
}

ensure_dep() {
  local dep="$1"
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "Missing dependency: $dep" >&2
    exit 1
  fi
}

install_script() {
  echo "Downloading backhaul-menu.sh..."
  curl -fsSL "${REPO_RAW_BASE}/backhaul-menu.sh" -o "$INSTALL_PATH"
  chmod +x "$INSTALL_PATH"
  echo "Installed to $INSTALL_PATH"
}

main() {
  require_root
  ensure_dep curl
  install_script
  echo "Launching menu..."
  "$INSTALL_PATH"
}

main "$@"
