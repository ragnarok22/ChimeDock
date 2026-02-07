import Foundation

enum DeviceEventType: Sendable {
    case connected
    case disconnected
}

struct DeviceEvent: Sendable {
    let type: DeviceEventType
    let vendorID: Int
    let productID: Int
    let deviceName: String
    let timestamp: Date

    nonisolated init(type: DeviceEventType, vendorID: Int = 0, productID: Int = 0, deviceName: String = "Unknown", timestamp: Date = Date()) {
        self.type = type
        self.vendorID = vendorID
        self.productID = productID
        self.deviceName = deviceName
        self.timestamp = timestamp
    }
}
