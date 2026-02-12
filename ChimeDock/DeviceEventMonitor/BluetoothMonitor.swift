import Combine
import Foundation
import IOBluetooth

final class BluetoothMonitor: NSObject, DeviceEventMonitor {
    let events = PassthroughSubject<DeviceEvent, Never>()

    private var connectNotification: IOBluetoothUserNotification?

    func startMonitoring() {
        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(deviceConnected(_:device:))
        )
    }

    func stopMonitoring() {
        connectNotification?.unregister()
        connectNotification = nil
    }

    @objc private func deviceConnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        let name = device.name ?? "Bluetooth Device"
        let event = DeviceEvent(type: .connected, source: .bluetooth, deviceName: name)
        events.send(event)

        device.register(
            forDisconnectNotification: self,
            selector: #selector(deviceDisconnected(_:device:))
        )
    }

    @objc private func deviceDisconnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        let name = device.name ?? "Bluetooth Device"
        let event = DeviceEvent(type: .disconnected, source: .bluetooth, deviceName: name)
        events.send(event)
        notification.unregister()
    }

    deinit {
        stopMonitoring()
    }
}
