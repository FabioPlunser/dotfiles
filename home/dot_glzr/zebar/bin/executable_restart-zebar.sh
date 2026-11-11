#!/bin/sh
# Force-restart Zebar (it can get stuck/hidden after sleep or logout).
pkill -9 -x zebar
sleep 1
APP=/Applications/Zebar.app; [ -d "$HOME/Applications/Zebar-Dev.app" ] && APP="$HOME/Applications/Zebar-Dev.app"
open "$APP"
