# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build
xcodebuild -scheme ChimeDock -configuration Debug build

# Run tests (unit tests only, uses Swift Testing framework)
xcodebuild test -scheme ChimeDock -destination 'platform=macOS'

# Run a single test
xcodebuild test -scheme ChimeDock -destination 'platform=macOS' -only-testing:ChimeDockTests/ChimeDockTests/settingsStoreDefaults
```

There is no Makefile or SPM — this is a pure Xcode project (`ChimeDock.xcodeproj`).

## Distribution

ChimeDock is distributed via Homebrew using a custom tap (`ragnarok22/homebrew-chimedock`).

- **Cask template**: `HomebrewFormula/chimedock.rb` — kept in this repo as the source of truth.
- **Tap repo**: `ragnarok22/homebrew-chimedock` — the release workflow automatically pushes version and SHA256 updates to `Casks/chimedock.rb` in the tap after each tagged release.
- **Release workflow** (`.github/workflows/release.yml`) computes the DMG SHA256, uploads to GitHub Releases, then updates the tap repo using the `HOMEBREW_TAP_TOKEN` secret.

## Architecture

ChimeDock is a macOS menu bar app (SwiftUI `MenuBarExtra`) that plays chime sounds when USB devices are connected/disconnected.

### Core Flow

`ChimeDockApp` → `EventCoordinator` → `IOKitUSBMonitor` (IOKit notifications) → `SoundPlayer` (NSSound)

- **EventCoordinator** — central orchestrator. Owns `SettingsStore`, `SoundPlayer`, and `IOKitUSBMonitor`. Subscribes to USB events via Combine, debounces them (300ms), and routes to `SoundPlayer` based on current settings.
- **IOKitUSBMonitor** — implements `DeviceEventMonitor` protocol. Uses IOKit C callbacks (`IOServiceMatchingCallback`) via `Unmanaged` pointers to detect `IOUSBHostDevice` match/termination events on the main run loop.
- **SoundPlayer** — plays `NSSound` from either bundled MP3s (`Resources/Sounds/`) or system `.aiff` files (`/System/Library/Sounds/`).
- **SettingsStore** — `UserDefaults`-backed `@Published` properties. Also manages launch-at-login via `SMAppService`.
- **SoundOption** — enum mapping sound choices to file URLs. Custom sounds use bundle resources; system sounds reference `/System/Library/Sounds/<name>.aiff`.

### UI

- **StatusMenuView** — menu bar dropdown: enable toggle, test sound buttons, settings link, quit.
- **SettingsView** — settings window: enable/launch-at-login toggles, connect/disconnect sound pickers with preview, volume slider.

Both views receive `SettingsStore` and `SoundPlayer` as `@EnvironmentObject`.

### Testing

Tests use Swift Testing (`@Test`, `#expect`). A `MockDeviceEventMonitor` in the test file implements `DeviceEventMonitor` for event simulation without IOKit.

### Key Constraints

- App sandbox is enabled (`com.apple.security.app-sandbox`).
- IOKit USB monitoring uses C-style callbacks with `Unmanaged` pointer bridging — be careful with memory management when modifying `IOKitUSBMonitor`.
