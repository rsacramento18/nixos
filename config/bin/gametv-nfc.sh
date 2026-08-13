#!/usr/bin/env bash
# ~/.local/bin/gametv-nfc.sh
# Called by udev when an NFC tag is scanned on a USB NFC reader (ACR122U etc.)
# udev runs as root, so this script switches to your user and triggers gametv.sh
#
# This script is called by the udev rule at:
#   /etc/udev/rules.d/99-gametv-nfc.rules

USER="rsacramento"
SCRIPT="/home/$USER/.local/bin/gametv.sh"

# Get the user's runtime dir and Hyprland instance
XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")"
HYPRLAND_INSTANCE_SIGNATURE=$(ls /tmp/hypr/ 2>/dev/null | head -1)

# Run the toggle as the user (not root)
sudo -u "$USER" \
    HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_INSTANCE_SIGNATURE" \
    XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus" \
    "$SCRIPT" &

exit 0
