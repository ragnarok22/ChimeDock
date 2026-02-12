import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("ChimeDock")
                .font(.title)
                .fontWeight(.bold)

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("A macOS menu bar app that plays chime sounds for device events.")
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            Link("GitHub Repository", destination: URL(string: "https://github.com/ragnarok22/ChimeDock")!)
                .font(.body)

            Text("\u{00A9} 2025 Reinier Hernandez")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(width: 360)
    }
}
