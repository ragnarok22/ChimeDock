import SwiftUI

@main
struct ChimeDockApp: App {
    @StateObject private var coordinator = EventCoordinator()

    var body: some Scene {
        MenuBarExtra("ChimeDock", image: "MenuBarIcon") {
            StatusMenuView()
                .environmentObject(coordinator.settingsStore)
                .environmentObject(coordinator.soundPlayer)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(coordinator.settingsStore)
                .environmentObject(coordinator.soundPlayer)
        }
    }
}
