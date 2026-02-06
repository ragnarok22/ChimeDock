import Combine
import Foundation

final class EventCoordinator: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    let settingsStore = SettingsStore()
    let soundPlayer = SoundPlayer()
    let deviceMonitor = IOKitUSBMonitor()

    private var cancellables = Set<AnyCancellable>()

    init() {
        deviceMonitor.events
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)

        deviceMonitor.startMonitoring()
    }

    private func handleEvent(_ event: DeviceEvent) {
        guard settingsStore.isEnabled else { return }

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
        deviceMonitor.stopMonitoring()
    }
}
