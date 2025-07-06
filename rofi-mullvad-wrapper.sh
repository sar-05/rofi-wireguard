#!/bin/bash
# /usr/local/sbin/rofi-mullvad-wrapper.sh
# Simple, secure wrapper for WireGuard operations
#
# Installation:
#   sudo cp rofi-mullvad-wrapper.sh /usr/local/sbin/
#   sudo chown root:root /usr/local/sbin/rofi-mullvad-wrapper.sh
#   sudo chmod 700 /usr/local/sbin/rofi-mullvad-wrapper.sh
#
# Sudoers entry (/etc/sudoers.d/rofi-mullvad-wrapper):
#   username ALL=(ALL) NOPASSWD: /usr/local/sbin/rofi-mullvad-wrapper.sh

# Security: Sanitize environment
PATH="/sbin:/usr/sbin:/bin:/usr/bin"
IFS=$' \t\n'
export PATH IFS

# Absolute paths only
readonly WG="/usr/bin/wg"
readonly WG_QUICK="/usr/bin/wg-quick"
readonly IP="/sbin/ip"
readonly WG_DIR="/etc/wireguard/"

# Validation functions
is_valid_interface() {
    local interface="$1"
    # Simple check: alphanumeric, underscore, hyphen, dot, 1-15 chars
    [[ "$interface" =~ ^[a-zA-Z0-9_.-]{1,15}$ ]]
}

is_valid_conf() {
    local conf="$1"
    # Simple check: alphanumeric, underscore, hyphen, dot, 1-15 chars
    [[ "$conf" =~ ^[a-zA-Z0-9_.-]{1,15}$ ]]
}

is_private_ip() {
    local ip="$1"
    # Private IP check
    [[ "$ip" =~ ^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]
}

is_valid_cidr() {
    local cidr="$1"
    # Basic CIDR format check (IP/mask)
    [[ "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]
}

case "$1" in
    "wg-up")
        # Expected: wg-up <conf>
        conf="$2"
        if ! is_valid_conf "$conf"; then
            echo "Error: Invalid WireGuard configuration file name" >&2
            exit 1
        fi
        if [[ ! -f "/etc/wireguard/${conf}.conf" ]]; then
            echo "Error: Config file not found" >&2
            exit 1
        fi
        exec "$WG_QUICK" up "$conf"
        ;;
        
    "wg-down")
        # Expected: wg-conf <conf>
        conf="$2"
        if ! is_valid_conf "$conf"; then
            echo "Error: Invalid WireGuard configuration file name" >&2
            exit 1
        fi
        exec "$WG_QUICK" down "$conf"
        ;;
        
    "wg-show")
        exec "$WG" show
        ;;
        
    "wg-list")
        exec ls "$WG_DIR"
        ;;
        
    "route-add")
        # Expected: route-add <network> <gateway> <interface>
        network="$2"
        gateway="$3"
        interface="$4"
        
        if ! is_valid_cidr "$network"; then
            echo "Error: Invalid network format" >&2
            exit 1
        fi
        if ! is_private_ip "$gateway"; then
            echo "Error: Invalid gateway IP" >&2
            exit 1
        fi
        if ! is_valid_interface "$interface"; then
            echo "Error: Invalid interface name" >&2
            exit 1
        fi
        
        exec "$IP" route add "$network" via "$gateway" dev "$interface"
        ;;
        
    "route-del")
        # Expected: route-del <network> <gateway> <interface>
        network="$2"
        gateway="$3" 
        interface="$4"
        
        if ! is_valid_cidr "$network"; then
            echo "Error: Invalid network format" >&2
            exit 1
        fi
        if ! is_private_ip "$gateway"; then
            echo "Error: Invalid gateway IP" >&2
            exit 1
        fi
        if ! is_valid_interface "$interface"; then
            echo "Error: Invalid interface name" >&2
            exit 1
        fi
        
        exec "$IP" route del "$network" via "$gateway" dev "$interface"
        ;;
        
    *)
        echo "Usage: $0 {wg-up|wg-down|wg-show|route-add|route-del} [args...]" >&2
        echo ""
        echo "Examples:"
        echo "  $0 wg-up wg0"
        echo "  $0 wg-show"
        echo "  $0 route-add 192.168.1.0/24 10.0.0.1 wg0"
        echo "  $0 route-del 192.168.1.0/24 10.0.0.1 wg0"
        exit 1
        ;;
esac
