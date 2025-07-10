#!/bin/bash
set -euo pipefail

# Sanitize environment
PATH="/sbin:/usr/sbin:/bin:/usr/bin"
IFS=$' \t\n'
export PATH IFS

# Absolute paths
readonly WG="/usr/bin/wg"
readonly WG_QUICK="/usr/bin/wg-quick"
readonly WG_DIR="/etc/wireguard/"

# Validation functions
is_valid_conf() {
  local conf="$1"
  # Simple check: alphanumeric, underscore, hyphen, dot, 1-15 chars
  [[ "$conf" =~ ^[a-zA-Z0-9_.-]{1,15}$ ]]
}

# Main command dispatcher
case "$1" in
  "wg-up")
    # Expected: wg-up <conf>
    conf="$2"
    if ! is_valid_conf "$conf"; then
      echo "Error: Invalid WireGuard file name" >&2
      exit 1
    fi
    if [[ ! -f "/etc/wireguard/${conf}.conf" ]]; then
      echo "Error: Config file not found" >&2
      exit 1
    fi
    exec "$WG_QUICK" up "$conf"
    ;;

  "wg-down")
    conf="$2"
    if ! is_valid_conf "$conf"; then
      echo "Error: Invalid WireGuard file name" >&2
      exit 1
    fi
    exec "$WG_QUICK" down "$conf"
    ;;

  "wg-show")
    exec "$WG" show
    ;;

  "wg-list")
    exec ls "$WG_DIR" | grep ".conf"
    ;;

  *)
    echo "Usage: $0 {wg-up|wg-down|wg-show|wg-list} [args...]" >&2
    exit 1
    ;;
esac
