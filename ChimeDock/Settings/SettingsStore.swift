import Combine
import Foundation
import ServiceManagement

final class SettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: "isEnabled") }
    }

    @Published var volume: Double {
        didSet { defaults.set(volume, forKey: "volume") }
    }

    @Published var connectSoundRaw: String {
        didSet { defaults.set(connectSoundRaw, forKey: "connectSoundRaw") }
    }

    @Published var disconnectSoundRaw: String {
        didSet { defaults.set(disconnectSoundRaw, forKey: "disconnectSoundRaw") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    @Published var enabledSources: Set<DeviceEventSource> {
        didSet {
            for source in DeviceEventSource.allCases {
                defaults.set(enabledSources.contains(source), forKey: source.settingsKey)
            }
        }
    }

    func isSourceEnabled(_ source: DeviceEventSource) -> Bool {
        enabledSources.contains(source)
    }

    func setSource(_ source: DeviceEventSource, enabled: Bool) {
        if enabled {
            enabledSources.insert(source)
        } else {
            enabledSources.remove(source)
        }
    }

    var connectSound: SoundOption {
        get { SoundOption(rawValue: connectSoundRaw) ?? .yameteIntro }
        set { connectSoundRaw = newValue.rawValue }
    }

    var disconnectSound: SoundOption {
        get { SoundOption(rawValue: disconnectSoundRaw) ?? .yameteOutro }
        set { disconnectSoundRaw = newValue.rawValue }
    }

    init() {
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.object(forKey: "isEnabled") as? Bool ?? true
        self.volume = defaults.object(forKey: "volume") as? Double ?? 0.7
        self.connectSoundRaw = defaults.string(forKey: "connectSoundRaw") ?? SoundOption.defaultConnect.rawValue
        self.disconnectSoundRaw = defaults.string(forKey: "disconnectSoundRaw") ?? SoundOption.defaultDisconnect.rawValue
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        var sources = Set<DeviceEventSource>()
        for source in DeviceEventSource.allCases {
            let enabled = defaults.object(forKey: source.settingsKey) as? Bool ?? source.defaultEnabled
            if enabled {
                sources.insert(source)
            }
        }
        self.enabledSources = sources
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
