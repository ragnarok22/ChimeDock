import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var soundPlayer: SoundPlayer
    @Environment(\.openWindow) private var openWindow

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

        Button("Settings...") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }

        Button("About ChimeDock") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "about")
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
