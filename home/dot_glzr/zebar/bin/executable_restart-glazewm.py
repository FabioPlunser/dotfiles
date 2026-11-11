#!/usr/bin/python3
"""Restart GlazeWM and put every window back on its workspace.

Workaround for glzr-io/glazewm#1419: on macOS the keybinding event tap gets
disabled around sleep/wake/lock and is never re-enabled, so hotkeys die until
GlazeWM restarts. A restart normally dumps all windows onto workspace 1; this
snapshots the layout first and restores it afterwards.

GlazeWM's startup/shutdown commands also restart Zebar, which fixes the bar
going missing after wake (glzr-io/zebar#324).
"""
import json
import os
import subprocess
import sys
import time

GLAZEWM = os.path.expanduser("~/Applications/GlazeWM-Dev.app/Contents/MacOS/glazewm")
APP = os.path.expanduser("~/Applications/GlazeWM-Dev.app")
LOG = os.path.expanduser("~/.glzr/zebar/bin/restart-glazewm.log")


def log(msg):
    with open(LOG, "a") as f:
        f.write(time.strftime("%F %T ") + msg + "\n")


def gwm(*args):
    r = subprocess.run([GLAZEWM, *args], capture_output=True, text=True, timeout=10)
    try:
        return json.loads(r.stdout)
    except ValueError:
        return None


def snapshot():
    data = gwm("query", "workspaces")
    if not data or not data.get("success"):
        return None
    windows, focused_ws = [], None

    def walk(node, ws):
        if node.get("type") == "window":
            windows.append({
                "handle": node.get("handle"),
                "process": node.get("processName"),
                "title": node.get("title"),
                "workspace": ws,
                "state": node["state"]["type"],
                "focused": node.get("hasFocus", False),
            })
        for child in node.get("children", []):
            walk(child, ws)

    for ws in data["data"]["workspaces"]:
        if ws.get("hasFocus"):
            focused_ws = ws["name"]
        walk(ws, ws["name"])
    return {"windows": windows, "focused_ws": focused_ws}


def current_windows():
    data = gwm("query", "workspaces")
    out = []

    def walk(node, ws):
        if node.get("type") == "window":
            out.append({**node, "_ws": ws})
        for child in node.get("children", []):
            walk(child, ws)

    for ws in (data or {}).get("data", {}).get("workspaces", []):
        walk(ws, ws["name"])
    return out


def match(saved, live, used):
    # 1. same native window handle, 2. same app + title.
    # 3. same app only when exactly one unused window of that app is left;
    #    if it is ambiguous, leave the window where it is rather than guess.
    for key in (
        lambda w: w.get("handle") == saved["handle"],
        lambda w: w.get("processName") == saved["process"] and w.get("title") == saved["title"],
    ):
        hits = [w for w in live if w["id"] not in used and key(w)]
        if len(hits) == 1:
            return hits[0]
    same_app = [w for w in live if w["id"] not in used and w.get("processName") == saved["process"]]
    return same_app[0] if len(same_app) == 1 else None


def main():
    t0 = time.monotonic()
    mark = lambda: f"{time.monotonic() - t0:.1f}s"
    snap = snapshot()
    if snap is None:
        log("GlazeWM not reachable, nothing to restore; starting it")
        subprocess.run(["open", "-g", APP])
        return

    # Stop GlazeWM (its shutdown_commands kill Zebar).
    gwm("command", "wm-exit")
    for _ in range(100):
        if subprocess.run(["pgrep", "-x", "glazewm"], capture_output=True).returncode:
            break
        time.sleep(0.05)
    else:
        subprocess.run(["pkill", "-9", "-x", "glazewm"])
        time.sleep(0.5)
    subprocess.run(["pkill", "-9", "-x", "zebar"])
    t_stop = mark()

    # Start it again (its startup_commands launch Zebar) and wait for IPC.
    subprocess.run(["open", "-g", APP])
    for _ in range(200):
        time.sleep(0.1)
        if gwm("query", "paused"):
            break
    t_ipc = mark()

    # Wait only until GlazeWM has picked the windows up again (instead of a
    # fixed 1.5 s): done once the count reaches the snapshot or stops growing.
    want, live, stable = len(snap["windows"]), [], 0
    for _ in range(30):
        prev = len(live)
        live = current_windows()
        if len(live) >= want:
            break
        stable = stable + 1 if len(live) == prev and live else 0
        if stable >= 3:
            break
        time.sleep(0.1)
    used, moved = set(), 0
    for saved in snap["windows"]:
        w = match(saved, live, used)
        if not w:
            log(f"no match for {saved['process']} | {saved['title']}")
            continue
        used.add(w["id"])
        if w["_ws"] != saved["workspace"]:
            gwm("command", "--id", w["id"], "move", "--workspace", saved["workspace"])
            moved += 1
        if w["state"]["type"] != saved["state"] and saved["state"] in ("tiling", "floating"):
            gwm("command", "--id", w["id"], f"set-{saved['state']}")

    if snap["focused_ws"]:
        gwm("command", "focus", "--workspace", snap["focused_ws"])

    log(f"restarted GlazeWM; restored {len(used)}/{len(snap['windows'])} windows, moved {moved} (stopped {t_stop}, ipc {t_ipc}, total {mark()})")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # never leave the user without a WM silently
        log(f"error: {e!r}")
        if subprocess.run(["pgrep", "-x", "glazewm"], capture_output=True).returncode:
            subprocess.run(["open", "-g", APP])
        sys.exit(1)
