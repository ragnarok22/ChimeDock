#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
APP_NAME="ChimeDock"
SCHEME="ChimeDock"
CONFIGURATION="Release"
TEAM_ID="3M2F6CPXXK"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# ── Required environment variables ─────────────────────────────────────────────
: "${APPLE_ID:?Set APPLE_ID to your Apple Developer email}"
: "${APPLE_TEAM_ID:=$TEAM_ID}"
: "${APP_PASSWORD:?Set APP_PASSWORD to an app-specific password}"

# ── Helpers ────────────────────────────────────────────────────────────────────
step() { echo "==> $1"; }

# ── Clean ──────────────────────────────────────────────────────────────────────
step "Cleaning build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── Archive ────────────────────────────────────────────────────────────────────
step "Archiving $APP_NAME"
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -quiet

# ── Export ──────────────────────────────────────────────────────────────────────
step "Exporting with Developer ID signing"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -quiet

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: $APP_PATH not found after export" >&2
  exit 1
fi

# ── Verify signature ──────────────────────────────────────────────────────────
step "Verifying code signature"
codesign --verify --deep --strict "$APP_PATH"
echo "Signature OK"

# ── Create DMG ─────────────────────────────────────────────────────────────────
step "Creating DMG"
DMG_STAGING="$BUILD_DIR/dmg-staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDRW \
  "$BUILD_DIR/$APP_NAME-rw.dmg"

# Set DMG window appearance
MOUNT_DIR="/Volumes/$APP_NAME"
hdiutil attach "$BUILD_DIR/$APP_NAME-rw.dmg" -mountpoint "$MOUNT_DIR"
osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$APP_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {400, 200, 880, 520}
    set theViewOptions to icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 80
    set position of item "$APP_NAME.app" of container window to {120, 160}
    set position of item "Applications" of container window to {360, 160}
    close
  end tell
end tell
APPLESCRIPT
sync
hdiutil detach "$MOUNT_DIR"

# Convert to compressed read-only DMG
hdiutil convert \
  "$BUILD_DIR/$APP_NAME-rw.dmg" \
  -format UDZO \
  -o "$DMG_PATH"
rm -f "$BUILD_DIR/$APP_NAME-rw.dmg"

# ── Notarize ───────────────────────────────────────────────────────────────────
step "Submitting DMG for notarization (this may take a few minutes)"
xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APP_PASSWORD" \
  --wait

# ── Staple ─────────────────────────────────────────────────────────────────────
step "Stapling notarization ticket to DMG"
xcrun stapler staple "$DMG_PATH"

# ── Done ───────────────────────────────────────────────────────────────────────
step "Build complete!"
echo "  DMG: $DMG_PATH"
echo ""
echo "Verify with:"
echo "  spctl --assess --type open --context context:primary-signature --verbose $DMG_PATH"
