import Foundation

enum DeviceEventSource: String, CaseIterable, Sendable {
    case usb
    case audio
    case bluetooth
    case wifi

    var displayName: String {
        switch self {
        case .usb: return "USB"
        case .audio: return "Audio"
        case .bluetooth: return "Bluetooth"
        case .wifi: return "WiFi"
        }
    }

    var settingsKey: String {
        return "source_\(rawValue)_enabled"
    }

    var defaultEnabled: Bool {
        return self == .usb
    }
}

enum DeviceEventType: Sendable {
    case connected
    case disconnected
}

struct DeviceEvent: Sendable {
    let type: DeviceEventType
    let source: DeviceEventSource
    let vendorID: Int
    let productID: Int
    let deviceName: String
    let timestamp: Date

    nonisolated init(type: DeviceEventType, source: DeviceEventSource = .usb, vendorID: Int = 0, productID: Int = 0, deviceName: String = "Unknown", timestamp: Date = Date()) {
        self.type = type
        self.source = source
        self.vendorID = vendorID
        self.productID = productID
        self.deviceName = deviceName
        self.timestamp = timestamp
    }
}
