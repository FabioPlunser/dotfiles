#!/bin/sh
# Called by sleepwatcher on system wake / display wake.
# Waits until the screen is unlocked, then restarts GlazeWM + Zebar with windows restored.
BIN="$HOME/.glzr/zebar/bin"
LOCK=/tmp/zebar-on-wake.lock
# Testing switch: touch $BIN/.no-wake-restart to skip the restart workaround.
[ -e "$BIN/.no-wake-restart" ] && { echo "$(date '+%F %T') wake restart skipped (.no-wake-restart)" >> "$BIN/on-wake.log"; exit 0; }
mkdir "$LOCK" 2>/dev/null || exit 0          # already running
trap 'rmdir "$LOCK"' EXIT
i=0
while "$BIN/screenlocked" && [ $i -lt 7200 ]; do sleep 0.25; i=$((i+1)); done
sleep 0.5
pgrep -x glazewm >/dev/null || exit 0
# Restarting GlazeWM re-arms its dead keybinding listener (glazewm#1419) and,
# through its startup/shutdown commands, also restarts Zebar (zebar#324).
# Windows are put back on their workspaces.
/usr/bin/python3 "$BIN/restart-glazewm.py"
echo "$(date '+%F %T') restarted glazewm+zebar after wake" >> "$BIN/on-wake.log"
