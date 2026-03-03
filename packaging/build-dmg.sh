#!/bin/bash
set -euo pipefail
# Build the RWD4EVR DMG with custom background and icon layout
# SPDX-License-Identifier: MIT

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
DMG_NAME="RWD4EVR"
DMG_TEMP="$BUILD_DIR/${DMG_NAME}_temp.dmg"
DMG_FINAL="$DIST_DIR/${DMG_NAME}.dmg"
VOLUME="/Volumes/${DMG_NAME}"
BG_IMAGE="$BUILD_DIR/dmg-background.png"

echo "=== Building ${DMG_NAME}.dmg ==="
echo ""

# Ensure apps are built
if [ ! -d "$BUILD_DIR/RWD4EVR Installer.app" ]; then
    echo "  Building app bundles first..."
    bash "$PROJECT_ROOT/packaging/build-apps.sh"
fi

# Generate background image
echo "  Generating background image..."
swift "$PROJECT_ROOT/packaging/gen-background.swift" "$BG_IMAGE"

# Detach any existing volume with same name
hdiutil detach "$VOLUME" 2>/dev/null || true

# Clean previous builds
rm -f "$DMG_TEMP" "$DMG_FINAL"
mkdir -p "$DIST_DIR"

# Calculate needed size (apps + background + padding)
APPS_SIZE=$(du -sm "$BUILD_DIR/RWD4EVR Installer.app" "$BUILD_DIR/RWD4EVR Uninstaller.app" 2>/dev/null | awk '{sum+=$1} END{print sum}')
DMG_SIZE=$((APPS_SIZE + 5))  # +5MB for background, README, and filesystem overhead

echo "  Creating writable DMG (${DMG_SIZE}MB)..."
hdiutil create -size "${DMG_SIZE}m" -fs HFS+ -volname "$DMG_NAME" "$DMG_TEMP" > /dev/null

echo "  Mounting..."
hdiutil attach "$DMG_TEMP" -readwrite -noverify > /dev/null

# Copy contents
echo "  Copying contents..."
cp -R "$BUILD_DIR/RWD4EVR Installer.app" "$VOLUME/"
cp -R "$BUILD_DIR/RWD4EVR Uninstaller.app" "$VOLUME/"
cp "$PROJECT_ROOT/README.md" "$VOLUME/README.txt"

# Add background
mkdir -p "$VOLUME/.background"
cp "$BG_IMAGE" "$VOLUME/.background/background.png"

# Also copy CLI scripts for advanced users
mkdir -p "$VOLUME/.cli"
cp "$PROJECT_ROOT/src/common.sh" "$VOLUME/.cli/"
cp "$PROJECT_ROOT/src/install.sh" "$VOLUME/.cli/"
cp "$PROJECT_ROOT/src/uninstall.sh" "$VOLUME/.cli/"
cp "$PROJECT_ROOT/src/verify.sh" "$VOLUME/.cli/"
chmod +x "$VOLUME/.cli/"*.sh

# Configure DMG window with AppleScript
echo "  Configuring window layout..."
osascript << 'APPLESCRIPT'
tell application "Finder"
    tell disk "RWD4EVR"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 120, 860, 570}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        set text size of theViewOptions to 12
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "RWD4EVR Installer.app" of container window to {165, 220}
        set position of item "RWD4EVR Uninstaller.app" of container window to {330, 220}
        set position of item "README.txt" of container window to {495, 220}
        close
        open
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Ensure .DS_Store is written
sync

echo "  Unmounting..."
hdiutil detach "$VOLUME" > /dev/null

echo "  Compressing to final DMG..."
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL" > /dev/null

rm -f "$DMG_TEMP"

echo ""
echo "  DMG: $DMG_FINAL"
ls -lh "$DMG_FINAL"
echo ""
