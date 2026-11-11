import CoreWLAN
if let i = CWWiFiClient.shared().interface(), i.powerOn() {
  let rssi = i.rssiValue()
  print(rssi == 0 ? "off" : "\(rssi)")
} else { print("off") }
