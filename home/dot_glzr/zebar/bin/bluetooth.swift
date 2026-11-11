import Foundation
import IOBluetooth

// Preserve the widget's interface: "off", connected names, or no output.
// Do not call IOBluetoothDevice.pairedDevices(): a shell helper launched by
// Zebar lacks the privacy usage description required for that API.
@_silgen_name("IOBluetoothPreferenceGetControllerPowerState") func btGetPower() -> Int32
@_silgen_name("IOBluetoothPreferenceSetControllerPowerState") func btSetPower(_ state: Int32)

let cacheDirectory = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Caches/local.zebar.bluetooth", isDirectory: true)
let cacheFile = cacheDirectory.appendingPathComponent("connected.json")

if CommandLine.arguments.dropFirst().first == "toggle" {
    let target: Int32 = btGetPower() == 0 ? 1 : 0
    for _ in 0..<12 {
        btSetPower(target)
        usleep(500_000)
        if btGetPower() == target { break }
    }
    try? FileManager.default.removeItem(at: cacheFile)
    exit(btGetPower() == target ? 0 : 1)
}
guard btGetPower() != 0 else {
    try? FileManager.default.removeItem(at: cacheFile)
    print("off")
    exit(0)
}

struct DeviceCache: Codable {
    let created: Date
    let names: [String]
}
let cached = (try? Data(contentsOf: cacheFile)).flatMap {
    try? JSONDecoder().decode(DeviceCache.self, from: $0)
}
func printNames(_ names: [String]) {
    for name in names { print(name) }
}
if let cached = cached, Date().timeIntervalSince(cached.created) < 15 {
    printNames(cached.names)
    exit(0)
}

// system_profiler reports Bluetooth status without enumerating protected
// devices directly in this unsigned shell helper. Cache to avoid frequent work.
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
process.arguments = ["-json", "-timeout", "5", "SPBluetoothDataType"]
let output = Pipe()
process.standardOutput = output
process.standardError = FileHandle.nullDevice

do {
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0,
          let report = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let controllers = report["SPBluetoothDataType"] as? [[String: Any]] else {
        throw NSError(domain: "ZebarBluetooth", code: 1)
    }
    var names = [String]()
    for controller in controllers {
        for device in controller["device_connected"] as? [[String: Any]] ?? [] {
            names.append(contentsOf: device.keys)
        }
    }
    names = Array(Set(names)).sorted()
    try FileManager.default.createDirectory(at: cacheDirectory,
        withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    let encoded = try JSONEncoder().encode(DeviceCache(created: Date(), names: names))
    try encoded.write(to: cacheFile, options: .atomic)
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: cacheFile.path)
    printNames(names)
} catch {
    // Keep the last known names if the system status report fails temporarily.
    if let cached = cached { printNames(cached.names) }
    exit(1)
}
