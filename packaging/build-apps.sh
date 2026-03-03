#!/bin/bash
set -euo pipefail
# Build .app bundles for installer and uninstaller
# SPDX-License-Identifier: MIT

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"

build_app() {
    local name="$1"
    local script="$2"
    local bundle_id="$3"
    local app_dir="$BUILD_DIR/${name}.app"

    echo "  Building ${name}.app..."

    rm -rf "$app_dir"
    mkdir -p "$app_dir/Contents/MacOS"
    mkdir -p "$app_dir/Contents/Resources/src"

    # Copy source scripts
    cp "$PROJECT_ROOT/src/common.sh" "$app_dir/Contents/Resources/src/"
    cp "$PROJECT_ROOT/src/${script}" "$app_dir/Contents/Resources/src/"

    # Create main executable
    cat > "$app_dir/Contents/MacOS/${name}" << EXEC
#!/bin/bash
RESOURCES="\$(cd "\$(dirname "\$0")/../Resources" && pwd)"
exec "\$RESOURCES/src/${script}" --gui
EXEC
    chmod +x "$app_dir/Contents/MacOS/${name}"

    # Create Info.plist
    cat > "$app_dir/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${name}</string>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleName</key>
    <string>${name}</string>
    <key>CFBundleDisplayName</key>
    <string>${name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.3</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

    # Copy app icon
    local icns="$PROJECT_ROOT/assets/AppIcon.icns"
    if [ -f "$icns" ]; then
        cp "$icns" "$app_dir/Contents/Resources/AppIcon.icns"
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$app_dir/Contents/Info.plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$app_dir/Contents/Info.plist"
    fi

    echo "    Done: $app_dir"
}

mkdir -p "$BUILD_DIR"

build_app "RWD4EVR Installer" "install.sh" "io.pegues.rwd4evr.installer"
build_app "RWD4EVR Uninstaller" "uninstall.sh" "io.pegues.rwd4evr.uninstaller"

echo ""
echo "  App bundles built in $BUILD_DIR/"
