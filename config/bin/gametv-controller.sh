#!/usr/bin/env bash
# ~/.local/bin/gametv-controller.sh
# Monitors Steam Controller Puck via hidraw for wireless controller connection.
# Fires ONCE per controller power-on, even if the controller stays on.

set -euo pipefail

USER="rsacramento"
SCRIPT="/home/$USER/.local/bin/gametv.sh"
LOG="/tmp/gametv-controller.log"
TRIGGERED_FILE="/tmp/steam-controller-triggered"
RESUME_FLAG="/home/$USER/.cache/gametv-resume-flag"
LAST_HIDRAW_FILE="/tmp/steam-controller-hidraw"

exec >> "$LOG" 2>&1
echo "[$(date)] Controller monitor started"
rm -f "$RESUME_FLAG"

find_hidraw() {
    local h
    # 1) Try last known device path first (fast)
    if [[ -f "$LAST_HIDRAW_FILE" ]]; then
        h=$(cat "$LAST_HIDRAW_FILE")
        if [[ -e "$h" ]] && udevadm info "$h" 2>/dev/null | grep -q "E: ID_VENDOR_ID=28de"; then
            echo "$h"
            return 0
        fi
    fi
    # 2) Scan for a live 28de device, lowest number first (hidraw9 < hidraw10)
    for h in $(ls -v /dev/hidraw* 2>/dev/null); do
        [[ -e "$h" ]] || continue
        if udevadm info "$h" 2>/dev/null | grep -q "E: ID_VENDOR_ID=28de"; then
            echo "$h"
            return 0
        fi
    done
    return 1
}

is_controller_connected() {
    local HIDRAW=$1
    python3 -c "
import os, select, sys
try:
    fd = os.open('$HIDRAW', os.O_RDONLY)
except OSError:
    sys.exit(1)
r, _, _ = select.select([fd], [], [], 3.0)
if r:
    try:
        os.read(fd, 64)
        os.close(fd)
        sys.exit(0)
    except OSError:
        os.close(fd)
        sys.exit(1)
else:
    os.close(fd)
    sys.exit(1)
"
}

while true; do
    HIDRAW=$(find_hidraw) || true

    if [[ -z "$HIDRAW" ]]; then
        sleep 2
        continue
    fi

    # If game mode is active, check for resume to turn on TV/input, then wait
    if [[ -f /tmp/gametv-active ]]; then
        if [[ -s $RESUME_FLAG ]]; then
            echo "[$(date)] Game mode active, resume detected — turning on TV and switching input"
            > "$RESUME_FLAG"
            XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")"
            HYPRLAND_INSTANCE_SIGNATURE=$(ls "$XDG_RUNTIME_DIR/hypr/" 2>/dev/null | head -1)
            if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
                export HYPRLAND_INSTANCE_SIGNATURE XDG_RUNTIME_DIR
                export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
                export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
                echo "[$(date)] Running: $SCRIPT on (game mode already active)"
                "$SCRIPT" on || true
            fi
        fi
        sleep 5
        continue
    fi

    # If we already fired for this controller session, wait for
    # disconnect or a fresh resume flag (user suspended again).
    if [[ -f "$TRIGGERED_FILE" ]]; then
        if [[ -s $RESUME_FLAG ]]; then
            echo "[$(date)] Resume flag detected while triggered"
            rm -f "$TRIGGERED_FILE"
            > "$RESUME_FLAG"
            XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")"
            HYPRLAND_INSTANCE_SIGNATURE=$(ls "$XDG_RUNTIME_DIR/hypr/" 2>/dev/null | head -1)
            if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
                export HYPRLAND_INSTANCE_SIGNATURE XDG_RUNTIME_DIR
                export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
                export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
                echo "[$(date)] Running: $SCRIPT on (resume while triggered)"
                "$SCRIPT" on || true
            fi
            sleep 5
            continue
        elif is_controller_connected "$HIDRAW"; then
            sleep 10
            continue
        else
            echo "[$(date)] Controller disconnect detected (hidraw timeout)"
            rm -f "$TRIGGERED_FILE"
            echo "[$(date)] Ready for next trigger"
            sleep 1
            continue
        fi
    fi

    # Clear stale resume flag so only fresh wake events are considered
    > "$RESUME_FLAG"

    # Poll: wait for controller HID data
    if is_controller_connected "$HIDRAW"; then
        echo "[$(date)] Controller detected on $HIDRAW"
        echo "$HIDRAW" > "$LAST_HIDRAW_FILE"

        # Guard: Hyprland must be running
        XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")"
        HYPRLAND_INSTANCE_SIGNATURE=$(ls "$XDG_RUNTIME_DIR/hypr/" 2>/dev/null | head -1)
        if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
            echo "Hyprland not running, skipping"
            sleep 2
            continue
        fi

        # Only trigger game mode if system just woke from sleep.
        # If flag not present immediately, wait briefly — sleep hook
        # may not have run yet if the service PID survived suspend.
        if [[ ! -s $RESUME_FLAG ]]; then
            for _ in {1..4}; do
                sleep 0.5
                [[ -s $RESUME_FLAG ]] && break
            done
        fi

        if [[ ! -s $RESUME_FLAG ]]; then
            echo "[$(date)] Controller detected but PC was already running — doing nothing"
            > "$RESUME_FLAG"
            touch "$TRIGGERED_FILE"
            sleep 1
            continue
        fi
        echo "[$(date)] Wake-from-sleep detected"
        > "$RESUME_FLAG"

        # Mark as triggered BEFORE running gametv, so re-triggers are blocked
        # even if gametv.sh fails partway through.
        touch "$TRIGGERED_FILE"

        sleep 0.5

        export HYPRLAND_INSTANCE_SIGNATURE
        export XDG_RUNTIME_DIR
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
        export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"

        echo "[$(date)] Running: $SCRIPT on"
        "$SCRIPT" on && RC=0 || RC=$?
        echo "[$(date)] $SCRIPT exited with code $RC"
        ls /tmp/gametv-active >/dev/null 2>&1 && echo "[$(date)] State file exists" || echo "[$(date)] State file MISSING"

        # Wait for game mode to end
        while [[ -f /tmp/gametv-active ]]; do
            echo "[$(date)] Waiting for game mode to end..."
            sleep 5
        done

        echo "[$(date)] Game mode ended, cooldown 30s before allowing re-trigger"
        sleep 30
    fi
done
