cask "chimedock" do
  version "1.0.3"
  sha256 "21032a12dcaf3ccaab89e5eedc43beace2047d83fbd0f4d23c675b29d845c730"

  url "https://github.com/ragnarok22/ChimeDock/releases/download/v#{version}/ChimeDock.dmg"
  name "ChimeDock"
  desc "macOS menu bar app that plays chime sounds for USB device events"
  homepage "https://github.com/ragnarok22/ChimeDock"

  app "ChimeDock.app"
end
