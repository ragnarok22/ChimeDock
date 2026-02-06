# ChimeDock

<p align="center">
  <img src="chime-logo.png" alt="ChimeDock logo" width="128">
</p>

A macOS menu bar app that plays a chime when USB devices are connected or disconnected.

## Features

- Plays configurable sounds on USB connect and disconnect events
- Includes bundled custom sounds and supports built-in macOS system sounds
- Per-event sound selection (different sounds for connect vs disconnect)
- Adjustable volume
- Launch at login
- Quick-toggle and sound test from the menu bar

## Requirements

- macOS 26.2+
- Xcode (Swift 5)

## Building

Open `ChimeDock.xcodeproj` in Xcode and build, or from the command line:

```bash
xcodebuild -scheme ChimeDock -configuration Debug build
```

## Running Tests

```bash
xcodebuild test -scheme ChimeDock -destination 'platform=macOS'
```

## Sound Options

| Sound | Source |
|-------|--------|
| Yamete Intro / Outro | Bundled MP3 (`Resources/Sounds/`) |
| Ping, Glass, Pop, Hero, Purr, Tink, Basso, Funk | macOS system sounds |
| None | Silent |
