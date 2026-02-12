import Combine
import Foundation

final class EventCoordinator: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    let settingsStore = SettingsStore()
    let soundPlayer = SoundPlayer()

    private var monitors: [DeviceEventSource: any DeviceEventMonitor] = [:]
    private var cancellables = Set<AnyCancellable>()

    init() {
        syncMonitorStates()

        settingsStore.$enabledSources
            .dropFirst()
            .sink { [weak self] _ in
                self?.syncMonitorStates()
            }
            .store(in: &cancellables)
    }

    private func createMonitor(for source: DeviceEventSource) -> any DeviceEventMonitor {
        switch source {
        case .usb: return IOKitUSBMonitor()
        case .audio: return AudioDeviceMonitor()
        case .bluetooth: return BluetoothMonitor()
        case .wifi: return WiFiMonitor()
        }
    }

    private func subscribe(to monitor: any DeviceEventMonitor) {
        monitor.events
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }

    private func syncMonitorStates() {
        for source in DeviceEventSource.allCases {
            if settingsStore.isSourceEnabled(source) {
                if monitors[source] == nil {
                    let monitor = createMonitor(for: source)
                    monitors[source] = monitor
                    subscribe(to: monitor)
                    monitor.startMonitoring()
                }
            } else {
                if let monitor = monitors[source] {
                    monitor.stopMonitoring()
                    monitors[source] = nil
                }
            }
        }
    }

    private func handleEvent(_ event: DeviceEvent) {
        guard settingsStore.isEnabled else { return }
        guard settingsStore.isSourceEnabled(event.source) else { return }

        let soundOption: SoundOption
        switch event.type {
        case .connected:
            soundOption = settingsStore.connectSound
        case .disconnected:
            soundOption = settingsStore.disconnectSound
        }

        soundPlayer.play(option: soundOption, volume: Float(settingsStore.volume))
    }

    deinit {
        for (_, monitor) in monitors {
            monitor.stopMonitoring()
        }
    }
}
