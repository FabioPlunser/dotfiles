import Carbon
// Prints "<lang code>\t<localized name>" for the current keyboard input source.
let src = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
func prop(_ key: CFString) -> AnyObject? {
  guard let p = TISGetInputSourceProperty(src, key) else { return nil }
  return Unmanaged<AnyObject>.fromOpaque(p).takeUnretainedValue()
}
let name = prop(kTISPropertyLocalizedName) as? String ?? "?"
let langs = prop(kTISPropertyInputSourceLanguages) as? [String] ?? []
let code = (langs.first ?? String(name.prefix(2))).prefix(2).uppercased()
print("\(code)\t\(name)")
