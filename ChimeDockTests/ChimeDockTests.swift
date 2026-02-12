import Testing
import Combine
@testable import ChimeDock

struct ChimeDockTests {

    @Test func settingsStoreDefaults() {
        let store = SettingsStore()
        #expect(store.isEnabled == true)
        #expect(store.volume == 0.7)
        #expect(store.connectSound == .yameteIntro)
        #expect(store.disconnectSound == .yameteOutro)
        #expect(store.launchAtLogin == false)
    }

    @Test func soundOptionBundledURLsExist() {
        // System sounds should exist on macOS
        let systemSounds: [SoundOption] = [.ping, .glass, .pop, .hero, .purr, .tink, .basso, .funk]
        for option in systemSounds {
            let url = option.url
            #expect(url != nil, "URL for \(option.displayName) should not be nil")
        }
    }

    @Test func soundOptionNoneHasNoURL() {
        #expect(SoundOption.none.url == nil)
    }

    @Test func deviceEventCreation() {
        let event = DeviceEvent(
            type: .connected,
            vendorID: 0x1234,
            productID: 0x5678,
            deviceName: "Test Device"
        )
        #expect(event.type == .connected)
        #expect(event.vendorID == 0x1234)
        #expect(event.productID == 0x5678)
        #expect(event.deviceName == "Test Device")
    }

    @Test func deviceEventDefaults() {
        let event = DeviceEvent(type: .disconnected)
        #expect(event.type == .disconnected)
        #expect(event.vendorID == 0)
        #expect(event.productID == 0)
        #expect(event.deviceName == "Unknown")
    }

    @Test func soundOptionRawValueRoundTrip() {
        for option in SoundOption.allCases {
            let recovered = SoundOption(rawValue: option.rawValue)
            #expect(recovered == option)
        }
    }

    @Test func deviceEventSourceDefaults() {
        #expect(DeviceEventSource.usb.defaultEnabled == true)
        #expect(DeviceEventSource.audio.defaultEnabled == false)
        #expect(DeviceEventSource.bluetooth.defaultEnabled == false)
        #expect(DeviceEventSource.wifi.defaultEnabled == false)
    }

    @Test func deviceEventSourceDisplayNames() {
        #expect(DeviceEventSource.usb.displayName == "USB")
        #expect(DeviceEventSource.audio.displayName == "Audio")
        #expect(DeviceEventSource.bluetooth.displayName == "Bluetooth")
        #expect(DeviceEventSource.wifi.displayName == "WiFi")
    }

    @Test func deviceEventSourceField() {
        let event = DeviceEvent(type: .connected, source: .audio, deviceName: "Headphones")
        #expect(event.source == .audio)
        #expect(event.deviceName == "Headphones")
    }

    @Test func deviceEventDefaultSourceIsUSB() {
        let event = DeviceEvent(type: .connected)
        #expect(event.source == .usb)
    }

    @Test func settingsStoreSourceDefaults() {
        let store = SettingsStore()
        #expect(store.isSourceEnabled(.usb) == true)
        #expect(store.isSourceEnabled(.audio) == false)
        #expect(store.isSourceEnabled(.bluetooth) == false)
        #expect(store.isSourceEnabled(.wifi) == false)
    }

    @Test func settingsStoreToggleSource() {
        let store = SettingsStore()
        store.setSource(.audio, enabled: true)
        #expect(store.isSourceEnabled(.audio) == true)
        store.setSource(.audio, enabled: false)
        #expect(store.isSourceEnabled(.audio) == false)
    }

    @Test func mockDeviceEventMonitorEmitsEvents() {
        let monitor = MockDeviceEventMonitor()
        var receivedEvents: [DeviceEvent] = []
        let cancellable = monitor.events.sink { event in
            receivedEvents.append(event)
        }

        monitor.startMonitoring()
        let event = DeviceEvent(type: .connected, deviceName: "Mock Device")
        monitor.simulateEvent(event)

        #expect(receivedEvents.count == 1)
        #expect(receivedEvents.first?.deviceName == "Mock Device")

        monitor.stopMonitoring()
        _ = cancellable
    }
}

final class MockDeviceEventMonitor: DeviceEventMonitor {
    let events = PassthroughSubject<DeviceEvent, Never>()
    private(set) var isMonitoring = false

    func startMonitoring() {
        isMonitoring = true
    }

    func stopMonitoring() {
        isMonitoring = false
    }

    func simulateEvent(_ event: DeviceEvent) {
        events.send(event)
    }
}
