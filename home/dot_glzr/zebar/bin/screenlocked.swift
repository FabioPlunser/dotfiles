import CoreGraphics
// Exit 0 if the screen is locked (or no GUI session), 1 if unlocked.
guard let d = CGSessionCopyCurrentDictionary() as? [String: Any] else { exit(0) }
let locked = (d["CGSSessionScreenIsLocked"] as? Bool) ?? false
let onConsole = (d["kCGSSessionOnConsoleKey"] as? Bool) ?? true
exit(locked || !onConsole ? 0 : 1)
