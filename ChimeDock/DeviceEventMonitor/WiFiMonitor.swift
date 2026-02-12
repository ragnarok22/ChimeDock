import Combine
import Foundation
import Network

final class WiFiMonitor: DeviceEventMonitor {
    let events = PassthroughSubject<DeviceEvent, Never>()

    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.chimedock.wifimonitor")
    private var lastStatus: NWPath.Status?
    private var isFirstUpdate = true

    func startMonitoring() {
        stopMonitoring()

        isFirstUpdate = true
        lastStatus = nil

        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: monitorQueue)
        pathMonitor = monitor
    }

    func stopMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
        lastStatus = nil
        isFirstUpdate = true
    }

    private func handlePathUpdate(_ path: NWPath) {
        let newStatus = path.status

        if isFirstUpdate {
            isFirstUpdate = false
            lastStatus = newStatus
            return
        }

        guard newStatus != lastStatus else { return }

        let previousStatus = lastStatus
        lastStatus = newStatus

        if newStatus == .satisfied && previousStatus != .satisfied {
            let event = DeviceEvent(type: .connected, source: .wifi, deviceName: "WiFi")
            events.send(event)
        } else if newStatus != .satisfied && previousStatus == .satisfied {
            let event = DeviceEvent(type: .disconnected, source: .wifi, deviceName: "WiFi")
            events.send(event)
        }
    }

    deinit {
        stopMonitoring()
    }
}
