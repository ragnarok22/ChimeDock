import Combine
import Foundation
import IOKit
import IOKit.usb

final class IOKitUSBMonitor: ObservableObject, DeviceEventMonitor {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    let events = PassthroughSubject<DeviceEvent, Never>()

    private var notificationPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0

    private nonisolated static let matchCallback: IOServiceMatchingCallback = { refcon, iterator in
        guard let refcon else { return }
        let monitor = Unmanaged<IOKitUSBMonitor>.fromOpaque(refcon).takeUnretainedValue()
        monitor.handleDevices(iterator: iterator, type: .connected)
    }

    private nonisolated static let removeCallback: IOServiceMatchingCallback = { refcon, iterator in
        guard let refcon else { return }
        let monitor = Unmanaged<IOKitUSBMonitor>.fromOpaque(refcon).takeUnretainedValue()
        monitor.handleDevices(iterator: iterator, type: .disconnected)
    }

    func startMonitoring() {
        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let notificationPort else { return }

        let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        // Register for USB device connections
        if let matchingDict = IOServiceMatching("IOUSBHostDevice") {
            let cfDict = matchingDict as CFDictionary
            IOServiceAddMatchingNotification(
                notificationPort,
                kIOFirstMatchNotification,
                cfDict,
                IOKitUSBMonitor.matchCallback,
                selfPtr,
                &addedIterator
            )
            drainIterator(addedIterator)
        }

        // Register for USB device disconnections
        if let matchingDict = IOServiceMatching("IOUSBHostDevice") {
            let cfDict = matchingDict as CFDictionary
            IOServiceAddMatchingNotification(
                notificationPort,
                kIOTerminatedNotification,
                cfDict,
                IOKitUSBMonitor.removeCallback,
                selfPtr,
                &removedIterator
            )
            drainIterator(removedIterator)
        }
    }

    func stopMonitoring() {
        if addedIterator != 0 {
            IOObjectRelease(addedIterator)
            addedIterator = 0
        }
        if removedIterator != 0 {
            IOObjectRelease(removedIterator)
            removedIterator = 0
        }
        if let notificationPort {
            let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue()
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            IONotificationPortDestroy(notificationPort)
            self.notificationPort = nil
        }
    }

    nonisolated private func handleDevices(iterator: io_iterator_t, type: DeviceEventType) {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            let event = createEvent(from: service, type: type)
            events.send(event)
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    nonisolated private func createEvent(from service: io_service_t, type: DeviceEventType) -> DeviceEvent {
        let vendorID = getIntProperty(service, key: "idVendor")
        let productID = getIntProperty(service, key: "idProduct")
        let deviceName = getStringProperty(service, key: "USB Product Name")
            ?? getStringProperty(service, key: "kUSBProductString")
            ?? "Unknown USB Device"

        return DeviceEvent(
            type: type,
            vendorID: vendorID,
            productID: productID,
            deviceName: deviceName
        )
    }

    nonisolated private func getIntProperty(_ service: io_service_t, key: String) -> Int {
        guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
            return 0
        }
        return (value as? NSNumber)?.intValue ?? 0
    }

    nonisolated private func getStringProperty(_ service: io_service_t, key: String) -> String? {
        guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
            return nil
        }
        return value as? String
    }

    nonisolated private func drainIterator(_ iterator: io_iterator_t) {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    deinit {
        stopMonitoring()
    }
}
