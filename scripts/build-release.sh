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
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

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
