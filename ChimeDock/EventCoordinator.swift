import Combine
import Foundation

final class EventCoordinator: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    let settingsStore = SettingsStore()
    let soundPlayer = SoundPlayer()

    private var monitors: [DeviceEventSource: any DeviceEventMonitor] = [:]
    private var cancellables = Set<AnyCancellable>()

    init() {
        monitors = [
            .usb: IOKitUSBMonitor(),
            .audio: AudioDeviceMonitor(),
            .bluetooth: BluetoothMonitor(),
            .wifi: WiFiMonitor(),
        ]

        for (_, monitor) in monitors {
            monitor.events
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .sink { [weak self] event in
                    self?.handleEvent(event)
                }
                .store(in: &cancellables)
        }

        syncMonitorStates()

        settingsStore.$enabledSources
            .dropFirst()
            .sink { [weak self] _ in
                self?.syncMonitorStates()
            }
            .store(in: &cancellables)
    }

    private func syncMonitorStates() {
        for (source, monitor) in monitors {
            if settingsStore.isSourceEnabled(source) {
                monitor.startMonitoring()
            } else {
                monitor.stopMonitoring()
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
