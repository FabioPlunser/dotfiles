#!/bin/sh
# Detached launcher so it survives GlazeWM exiting (needed when run from a GlazeWM hotkey).
nohup /usr/bin/python3 "$HOME"/.glzr/zebar/bin/restart-glazewm.py >/dev/null 2>&1 &
