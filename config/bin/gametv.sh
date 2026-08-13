#!/usr/bin/env bash
# ~/.local/bin/gametv.sh
# Toggle between desktop and TV "console mode" using gamescope
# Gives a Steam Deck-like experience on the TV via nested gamescope
#
# Usage: gametv.sh          (toggle)
#        gametv.sh on       (force TV mode)
#        gametv.sh off      (force desktop mode)

set -euo pipefail

# ───── CONFIG ─────
MONITOR="DP-1"
TV="HDMI-A-1"
TV_RES_W=3840
TV_RES_H=2160
TV_REFRESH=60
TV_POSITION="2560x0"       # position relative to main monitor in Hyprland

# Internal render resolution (gamescope upscales to TV_RES)
# Set equal to TV_RES for native 4K, or lower for FSR upscaling
RENDER_W=3840
RENDER_H=2160

AUDIO_SINK_TV="NAVI"       # grep pattern for TV audio sink (GPU HDMI)
AUDIO_SINK_DESK="HyperX"   # grep pattern for desktop audio sink

# Sony Bravia IP Control
TV_IP="192.168.1.220"
TV_PSK="Luke1991!"
TV_HDMI_PORT=4             # Which HDMI port is connected to PC

GAME_WORKSPACE=5
STATE_FILE="/tmp/gametv-active"
LOG="/tmp/gametv.log"
GAMESCOPE_PID_FILE="/tmp/gamescope-tv.pid"

# ───── LOGGING ─────
exec > >(tee -i "$LOG") 2>&1
echo "[$(date)] gametv.sh started"

# ───── HELPERS ─────
find_sink() {
    local pattern="$1"
    wpctl status | awk '/Sinks:/, /Sources:/ {print}' \
        | grep -i "$pattern" \
        | sed -E 's/[^0-9]*([0-9]+).*/\1/' \
        | head -1 \
        | xargs
}

switch_audio() {
    local sink="$1"
    local label="$2"
    if [[ -n "$sink" ]]; then
        wpctl set-default "$sink" && echo "Audio -> $label (sink $sink)"
    else
        echo "WARNING: Could not find audio sink for $label"
    fi
}

wait_for_monitor() {
    local monitor="$1"
    local retries=20
    while ! mmsg get all-monitors | jq -e --arg m "$monitor" '.monitors[] | select(.name == $m) | .active' > /dev/null; do
        ((retries--)) || { echo "ERROR: $monitor did not appear or is not active"; return 1; }
        sleep 0.25
    done
    echo "$monitor is active"
}

# Sony Bravia IP Control functions
bravia_send_ircc() {
    local ircc_code="$1"
    local response
    response=$(curl -s -X POST "http://$TV_IP/sony/IRCC" \
        -H "Content-Type: application/xml" \
        -H "SOAPAction: \"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"" \
        -H "X-Auth-PSK: $TV_PSK" \
        -d '<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1"><IRCCCode>'"$ircc_code"'</IRCCCode></u:X_SendIRCC></s:Body></s:Envelope>' \
        2>&1)
    if echo "$response" | grep -q "Fault"; then
        echo "Bravia IRCC error: $response"
    else
        echo "Bravia command sent"
    fi
}

bravia_power_on() {
    # Wait for network to be ready after resume (curl may not connect immediately)
    local status
    local retries=10
    while ((retries--)); do
        status=$(curl -s --connect-timeout 2 -X POST "http://$TV_IP/sony/system" \
            -H "Content-Type: application/json" \
            -H "X-Auth-PSK: $TV_PSK" \
            -d '{"method":"getPowerStatus","id":1,"params":[],"version":"1.0"}' 2>/dev/null) && break
        sleep 1
    done
    
    if (( retries < 0 )) && [[ -z "$status" ]]; then
        echo "WARNING: TV $TV_IP unreachable after resume, skipping"
        return 1
    fi
    
    if echo "$status" | grep -q '"status":"active"'; then
        echo "Bravia already on"
        return
    fi
    
    curl -s -X POST "http://$TV_IP/sony/system" \
        -H "Content-Type: application/json" \
        -H "X-Auth-PSK: $TV_PSK" \
        -d '{"method":"setPowerStatus","id":1,"params":[{"status":true}],"version":"1.0"}' > /dev/null || true
    echo "Bravia power on sent"
    
    sleep 3
    status=$(curl -s --connect-timeout 2 -X POST "http://$TV_IP/sony/system" \
        -H "Content-Type: application/json" \
        -H "X-Auth-PSK: $TV_PSK" \
        -d '{"method":"getPowerStatus","id":1,"params":[],"version":"1.0"}' 2>/dev/null)
    
    if ! echo "$status" | grep -q '"status":"active"'; then
        local ircc_code="AAAAAQAAAAEAAAAuAw=="
        bravia_send_ircc "$ircc_code"
        echo "Bravia wake up sent via IRCC"
    fi
}

bravia_power_off() {
    local ircc_code="AAAAAQAAAAEAAAAvAw=="  # PowerOff
    bravia_send_ircc "$ircc_code"
    echo "Bravia power off sent"
}

bravia_switch_hdmi() {
    local hdmi_num="$1"
    local ircc_code
    case "$hdmi_num" in
        1) ircc_code="AAAAAgAAABoAAABaAw==" ;;
        2) ircc_code="AAAAAgAAABoAAABbAw==" ;;
        3) ircc_code="AAAAAgAAABoAAABcAw==" ;;
        4) ircc_code="AAAAAgAAABoAAABdAw==" ;;
        *) echo "Invalid HDMI port: $hdmi_num"; return 1 ;;
    esac
    bravia_send_ircc "$ircc_code"
    echo "Bravia switched to HDMI $hdmi_num"
}

# ───── DETERMINE MODE ─────
if [[ "${1:-}" == "on" ]]; then
    MODE="tv"
elif [[ "${1:-}" == "off" ]]; then
    MODE="desktop"
elif [[ -f "$STATE_FILE" ]]; then
    MODE="desktop"
else
    MODE="tv"
fi

echo "Mode: $MODE"

# If already in game mode, just ensure TV is on and exit
if [[ "$MODE" == "tv" && -f "$STATE_FILE" ]]; then
    echo "Game mode already active, ensuring TV is on..."
    bravia_power_on || true
    sleep 1
    bravia_switch_hdmi "$TV_HDMI_PORT" || true
    exit 0
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  DESKTOP MODE — tear down TV, restore desktop
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [[ "$MODE" == "desktop" ]]; then
    echo "Returning to desktop..."

    # Kill gamescope (this also closes Steam inside it)
    if [[ -f "$GAMESCOPE_PID_FILE" ]]; then
        GPID=$(cat "$GAMESCOPE_PID_FILE")
        if kill -0 "$GPID" 2>/dev/null; then
            echo "Stopping gamescope (PID $GPID)..."
            kill "$GPID" 2>/dev/null || true
            # Wait for it to actually die
            for i in {1..20}; do
                kill -0 "$GPID" 2>/dev/null || break
                sleep 0.25
            done
        fi
        rm -f "$GAMESCOPE_PID_FILE"
    fi

    # Also catch any stray gamescope
    pkill -f "gamescope.*--steam" 2>/dev/null || true
    sleep 0.5

    # Disable TV output
    hyprctl keyword monitor "$TV,disable" && echo "TV disabled"

    # Switch audio back to desk
    DESK_SINK=$(find_sink "$AUDIO_SINK_DESK")
    switch_audio "$DESK_SINK" "desktop"

    # Focus back to main monitor
    hyprctl dispatch focusmonitor "$MONITOR" 2>/dev/null || true

    # Restart Steam normally in the background (optional)
    if ! pgrep -x steam >/dev/null 2>&1; then
        echo "Restarting Steam in desktop mode..."
        steam -silent &
        disown
    fi

    rm -f "$STATE_FILE"
    notify-send "Game Mode" "Back to desktop" -i display
    echo "Desktop mode active."

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  TV MODE — enable TV, launch gamescope + Steam Deck UI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
else
    echo "Switching to TV + Console Mode..."

    # Kill any existing desktop Steam first — gamescope will launch its own
    if pgrep -x steam >/dev/null 2>&1; then
        echo "Closing desktop Steam..."
        pkill -x steam || true
        # Wait for Steam to fully exit
        for i in {1..30}; do
            pgrep -x steam >/dev/null 2>&1 || break
            sleep 0.5
        done
        sleep 1
    fi

    # Enable TV output in Hyprland
    hyprctl keyword monitor "$TV,${TV_RES_W}x${TV_RES_H}@${TV_REFRESH},${TV_POSITION},1,vrr,2"
    wait_for_monitor "$TV"

    # Turn on TV and switch to correct HDMI input via IP control
    bravia_power_on || true
    sleep 1
    bravia_switch_hdmi "$TV_HDMI_PORT" || true

    # Switch audio to TV
    TV_SINK=$(find_sink "$AUDIO_SINK_TV")
    switch_audio "$TV_SINK" "TV" || true

    # Move focus to TV workspace
    hyprctl dispatch focusmonitor "$TV" || true
    hyprctl dispatch workspace "$GAME_WORKSPACE" || true

    # Launch gamescope with Steam Deck UI
    # -W/-H = output resolution (what the TV shows)
    # -w/-h = internal render resolution (what games render at)
    # -r    = refresh rate
    # -f    = fullscreen
    # -e    = enable Steam overlay integration
    # --adaptive-sync = VRR
    # --force-grab-cursor = keeps cursor inside gamescope
    # --steam = Steam integration mode
    # --xwayland-count 2 = Steam needs 2 xwayland servers
    # Steam flags: -gamepadui = new Deck UI, -steamos3 -steampal = console behavior
    echo "Launching gamescope..."
    # Disable Vulkan layers that interfere with gamescope
    export MANGOHUD=0
    unset LD_PRELOAD
    # Prevent any Vulkan layers from loading
    unset VK_LAYER_PATH
    export VK_INSTANCE_LAYERS=""
    export VK_DEVICE_LAYERS=""
    # Help gamescope handle overlay surfaces better
    export GAMESCOPE_ENABLE_FOSSILIZE_DUMP=0
    gamescope \
        -W "$TV_RES_W" -H "$TV_RES_H" \
        -w "$RENDER_W" -h "$RENDER_H" \
        -r "$TV_REFRESH" \
        -f \
        -e \
        --adaptive-sync \
        --force-grab-cursor \
        --mangoapp \
        --xwayland-count 2 \
        --backend wayland \
        --force-composition \
        --steam \
        -- steam -gamepadui -steamos3 -steampal -steamdeck &

    GAMESCOPE_PID=$!
    echo "$GAMESCOPE_PID" > "$GAMESCOPE_PID_FILE"
    echo "Gamescope PID: $GAMESCOPE_PID"

    # Wait a moment for gamescope window to appear, then fullscreen it on TV
    sleep 3
    hyprctl dispatch focusmonitor "$TV" || true
    hyprctl dispatch workspace "$GAME_WORKSPACE" || true

    # Move gamescope window to TV workspace if it ended up elsewhere
    # Gamescope shows up as class "gamescope" — move it to the TV workspace
    hyprctl dispatch movetoworkspacesilent "$GAME_WORKSPACE,class:gamescope" 2>/dev/null || true
    hyprctl dispatch fullscreen 0 2>/dev/null || true

    touch "$STATE_FILE"
    notify-send "Game Mode" "TV + Console Mode active" -i steam

    # # Monitor gamescope — when it exits, auto-switch back to desktop
    # (
    #     wait "$GAMESCOPE_PID" 2>/dev/null || true
    #     echo "[$(date)] Gamescope exited, auto-switching to desktop..."
    #     rm -f "$GAMESCOPE_PID_FILE"
    #     "$0" off
    # ) &
    # disown

    # echo "Console mode active. Exit Steam/gamescope to return to desktop."
fi

echo "[$(date)] gametv.sh finished"
