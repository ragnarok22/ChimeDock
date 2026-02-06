import Foundation

enum SoundEvent {
    case connect
    case disconnect
}

enum SoundOption: String, CaseIterable, Identifiable {
    case yameteIntro = "yameteIntro"
    case yameteOutro = "yameteOutro"
    case ping = "Ping"
    case glass = "Glass"
    case pop = "Pop"
    case hero = "Hero"
    case purr = "Purr"
    case tink = "Tink"
    case basso = "Basso"
    case funk = "Funk"
    case none = "none"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yameteIntro: "Yamete Intro"
        case .yameteOutro: "Yamete Outro"
        case .ping: "Ping"
        case .glass: "Glass"
        case .pop: "Pop"
        case .hero: "Hero"
        case .purr: "Purr"
        case .tink: "Tink"
        case .basso: "Basso"
        case .funk: "Funk"
        case .none: "None"
        }
    }

    var url: URL? {
        switch self {
        case .yameteIntro:
            Bundle.main.url(forResource: "yamete-intro", withExtension: "mp3", subdirectory: "Resources/Sounds")
        case .yameteOutro:
            Bundle.main.url(forResource: "yamete-outro", withExtension: "mp3", subdirectory: "Resources/Sounds")
        case .none:
            nil
        default:
            URL(fileURLWithPath: "/System/Library/Sounds/\(rawValue).aiff")
        }
    }

    static let defaultConnect: SoundOption = .yameteIntro
    static let defaultDisconnect: SoundOption = .yameteOutro
}
