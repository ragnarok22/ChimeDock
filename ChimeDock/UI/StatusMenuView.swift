import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var soundPlayer: SoundPlayer

    var body: some View {
        Toggle("Enabled", isOn: $settings.isEnabled)

        Divider()

        Button("Test Connect Sound") {
            soundPlayer.play(option: settings.connectSound, volume: Float(settings.volume))
        }

        Button("Test Disconnect Sound") {
            soundPlayer.play(option: settings.disconnectSound, volume: Float(settings.volume))
        }

        Divider()

        SettingsLink {
            Text("Settings...")
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
