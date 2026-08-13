#!/usr/bin/env bash
# ~/.local/bin/gametv-server.sh
# Tiny HTTP server that listens for game mode toggle requests.
# Allows triggering gametv.sh from your phone (NFC tag, Shortcuts, Tasker, etc.)
#
# Usage:
#   gametv-server.sh            # start listening on port 9876
#
# Trigger from phone:
#   curl http://<your-pc-ip>:9876/toggle
#   curl http://<your-pc-ip>:9876/on
#   curl http://<your-pc-ip>:9876/off
#   curl http://<your-pc-ip>:9876/status
#
# For NFC: program your NFC tag with a URL/shortcut that calls one of the above.
# iOS: Use Shortcuts app -> "Get Contents of URL"
# Android: Use Tasker or NFC Tools -> "HTTP GET"

PORT="${GAMETV_PORT:-9876}"
SCRIPT="$HOME/.local/bin/gametv.sh"
USER="rsacramento"

LOG="/tmp/gametv-server.log"

echo "Game Mode HTTP trigger listening on port $PORT"
echo "Endpoints: /toggle, /on, /off, /status"

# Requires socat (pacman -S socat)
# Each connection is handled by spawning a handler

handle_request() {
    read -r REQUEST_LINE
    PATH_REQ=$(echo "$REQUEST_LINE" | awk '{print $2}')

    while read -r header; do
        [[ "$header" == $'\r' || -z "$header" ]] && break
    done

    ARG=""
    case "$PATH_REQ" in
        /toggle)
            ARG=""
            HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/$(id -u "$USER")/hypr/ 2>/dev/null | head -1)
            export HYPRLAND_INSTANCE_SIGNATURE
            export XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")"
            export HOME="/home/$USER"
            export USER
            echo "[$(date)] toggle: running gametv.sh" >> "$LOG"
            "$SCRIPT" $ARG >> "$LOG" 2>&1 &
            BODY='{"action":"toggle","status":"ok"}'
            ;;
        /on)
            ARG="on"
            HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/$(id -u "$USER")/hypr/ 2>/dev/null | head -1)
            export HYPRLAND_INSTANCE_SIGNATURE
            export XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")"
            export HOME="/home/$USER"
            export USER
            echo "[$(date)] on: running gametv.sh on" >> "$LOG"
            "$SCRIPT" $ARG >> "$LOG" 2>&1 &
            BODY='{"action":"on","status":"ok"}'
            ;;
        /off)
            ARG="off"
            HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/$(id -u "$USER")/hypr/ 2>/dev/null | head -1)
            export HYPRLAND_INSTANCE_SIGNATURE
            export XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")"
            export HOME="/home/$USER"
            export USER
            echo "[$(date)] off: running gametv.sh off" >> "$LOG"
            "$SCRIPT" $ARG >> "$LOG" 2>&1 &
            BODY='{"action":"off","status":"ok"}'
            ;;
        /status)
            if [[ -f /tmp/gametv-active ]]; then
                BODY='{"mode":"tv"}'
            else
                BODY='{"mode":"desktop"}'
            fi
            ;;
        *)
            BODY='{"error":"unknown endpoint","endpoints":["/toggle","/on","/off","/status"]}'
            ;;
    esac

    LEN=${#BODY}
    printf "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n%s" "$LEN" "$BODY"
}

export -f handle_request
export SCRIPT USER LOG

while true; do
    socat TCP-LISTEN:"$PORT",reuseaddr,fork SYSTEM:"handle_request"
done
