import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var soundPlayer: SoundPlayer

    var body: some View {
        Form {
            Section("General") {
                Toggle("Enable sound notifications", isOn: $settings.isEnabled)
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("Event Sources") {
                ForEach(DeviceEventSource.allCases, id: \.self) { source in
                    Toggle(source.displayName, isOn: sourceBinding(for: source))
                }
            }

            Section("Sounds") {
                HStack {
                    Picker("Connect sound", selection: $settings.connectSoundRaw) {
                        ForEach(SoundOption.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    Button("Preview") {
                        soundPlayer.play(option: settings.connectSound, volume: Float(settings.volume))
                    }
                }

                HStack {
                    Picker("Disconnect sound", selection: $settings.disconnectSoundRaw) {
                        ForEach(SoundOption.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    Button("Preview") {
                        soundPlayer.play(option: settings.disconnectSound, volume: Float(settings.volume))
                    }
                }
            }

            Section("Volume") {
                Slider(value: $settings.volume, in: 0...1) {
                    Text("Volume")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
    }

    private func sourceBinding(for source: DeviceEventSource) -> Binding<Bool> {
        Binding(
            get: { settings.isSourceEnabled(source) },
            set: { settings.setSource(source, enabled: $0) }
        )
    }
}
