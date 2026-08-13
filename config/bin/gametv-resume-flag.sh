#!/usr/bin/env bash
# systemd-sleep hook: creates a flag when resuming from suspend
# Install: sudo ln -sf "$HOME/.local/bin/gametv-resume-flag.sh" /usr/lib/systemd/system-sleep/
case $1 in
  post)
    mkdir -p /home/rsacramento/.cache
    echo "1" > /home/rsacramento/.cache/gametv-resume-flag
    chown rsacramento:users /home/rsacramento/.cache/gametv-resume-flag
    ;;
esac
