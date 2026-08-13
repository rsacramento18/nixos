#!/bin/bash

LID_STATE_FILE="/proc/acpi/button/lid/LID/state"
AC_ONLINE_FILE="/sys/class/power_supply/AC/online"
POLL_INTERVAL=2
INHIBITOR_PID_FILE="${TMPDIR:-/tmp}/lid-handler-inhibit.pid"
INTERNAL_OUTPUT="eDP-1"

inhibitor_pid=""

cleanup() {
    release_inhibitor
}
trap cleanup EXIT INT TERM

take_inhibitor() {
    if [ -z "$inhibitor_pid" ] || ! kill -0 "$inhibitor_pid" 2>/dev/null; then
        loginctl inhibit --what=handle-lid-switch \
            --who="lid-handler" \
            --why="External monitor active on AC power" \
            --mode=block &
        inhibitor_pid=$!
        echo "$inhibitor_pid" > "$INHIBITOR_PID_FILE"
    fi
}

release_inhibitor() {
    if [ -n "$inhibitor_pid" ]; then
        kill "$inhibitor_pid" 2>/dev/null || true
        inhibitor_pid=""
        rm -f "$INHIBITOR_PID_FILE"
    fi
}

has_external_monitor() {
    wlr-randr 2>/dev/null | awk '
        /^[^ ]/ { current = $1 }
        /Enabled: yes/ && current != "eDP-1" { found = 1 }
        END { exit (found ? 0 : 1) }
    '
}

internal_is_on() {
    wlr-randr 2>/dev/null | grep -A 5 "^$INTERNAL_OUTPUT " | grep -q "Enabled: yes"
}

toggle_internal_display() {
    if [ "${1:-on}" = "off" ]; then
        wlr-randr --output "$INTERNAL_OUTPUT" --off
    else
        wlr-randr --output "$INTERNAL_OUTPUT" --on --preferred
    fi
}

read_lid_state() {
    grep -q "closed" "$LID_STATE_FILE" 2>/dev/null && echo "closed" || echo "open"
}

read_ac_state() {
    [ "$(cat "$AC_ONLINE_FILE" 2>/dev/null)" = "1" ] && echo "online" || echo "offline"
}

# Handle initial state (lid may already be closed when script starts)
lid_state=$(read_lid_state)
ac_state=$(read_ac_state)
if [ "$lid_state" = "closed" ] && [ "$ac_state" = "online" ] && has_external_monitor; then
    take_inhibitor
    toggle_internal_display off
fi

while true; do
    lid_state=$(read_lid_state)
    ac_state=$(read_ac_state)

    if [ "$lid_state" = "closed" ]; then
        if [ "$ac_state" = "online" ] && has_external_monitor; then
            take_inhibitor
            internal_is_on && toggle_internal_display off
        else
            release_inhibitor
            internal_is_on || toggle_internal_display on
            zzz || sleep "$POLL_INTERVAL"
        fi
    else
        release_inhibitor
        internal_is_on || toggle_internal_display on
    fi

    sleep "$POLL_INTERVAL"
done
