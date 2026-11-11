#!/bin/sh
# Launch Zebar from GlazeWM startup. Waits for any exiting instance first,
# otherwise `open -a` just re-activates the dying process and no bar appears.
i=0
while pgrep -x zebar >/dev/null && [ $i -lt 20 ]; do sleep 0.25; i=$((i+1)); done
pkill -9 -x zebar 2>/dev/null
APP=/Applications/Zebar.app; [ -d "$HOME/Applications/Zebar-Dev.app" ] && APP="$HOME/Applications/Zebar-Dev.app"
open "$APP"
