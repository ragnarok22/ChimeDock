import AppKit
import Combine

final class SoundPlayer: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    private var currentSound: NSSound?

    func play(option: SoundOption, volume: Float) {
        guard option != .none, let url = option.url else { return }

        currentSound?.stop()
        guard let sound = NSSound(contentsOf: url, byReference: true) else { return }
        sound.volume = volume
        sound.play()
        currentSound = sound
    }

    func stop() {
        currentSound?.stop()
        currentSound = nil
    }
}
