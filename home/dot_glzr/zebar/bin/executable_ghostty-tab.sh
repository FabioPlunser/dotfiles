#!/bin/sh
# Open a new tab in the running Ghostty (front window); start Ghostty if it isn't running.
osascript <<'AS'
if application "Ghostty" is running then
  tell application "Ghostty"
    if (count of windows) > 0 then
      new tab in front window
    else
      new window
    end if
    activate
  end tell
else
  tell application "Ghostty" to activate
end if
AS
