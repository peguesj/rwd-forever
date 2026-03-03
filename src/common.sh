#!/bin/bash
# rwd-forever: Shared constants and functions
# SPDX-License-Identifier: MIT

APP_PATH="/Applications/Rewind.app"
BINARY="$APP_PATH/Contents/MacOS/Rewind"
BACKUP_DIR="$HOME/Library/Application Support/RWD4EVR/backups"
BUNDLE_ID="com.memoryvault.MemoryVault"
SUPPORTED_VERSION="1.5607"

# arm64 patch: cutoff check function at VA 0x10009bc7c
# Fat binary: arm64 slice at 0x1498000 + function at 0x9bc7c = 0x1533c7c
ARM64_PATCH_OFFSET=$((0x1533c7c))
ORIGINAL_BYTES="fa67bba9f85f01a9"
PATCH_BYTES="00008052c0035fd6"

get_app_version() {
    /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
        "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "unknown"
}

get_current_bytes() {
    xxd -p -l 8 -s $ARM64_PATCH_OFFSET "$BINARY" | tr -d '\n'
}

is_patched() {
    [ "$(get_current_bytes)" = "$PATCH_BYTES" ]
}

is_original() {
    [ "$(get_current_bytes)" = "$ORIGINAL_BYTES" ]
}

is_rewind_running() {
    pgrep -x Rewind > /dev/null 2>&1
}

is_arm64() {
    # Use sysctl to check actual hardware, not process arch.
    # uname -m can report x86_64 when running under Rosetta.
    local hw
    hw=$(sysctl -n hw.machine 2>/dev/null || uname -m)
    [ "$hw" = "arm64" ]
}

app_exists() {
    [ -f "$BINARY" ]
}

create_entitlements() {
    local tmp
    tmp=$(mktemp /tmp/rwd4evr_ent.XXXXXX.plist)
    cat > "$tmp" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.personal-information.calendars</key>
    <true/>
</dict>
</plist>
EOF
    echo "$tmp"
}

resign_app() {
    local ent
    ent=$(create_entitlements)
    rm -rf "$APP_PATH/Contents/_CodeSignature" 2>/dev/null || true
    rm -f "$APP_PATH/Contents/CodeResources" 2>/dev/null || true
    xattr -cr "$APP_PATH" 2>/dev/null || true
    codesign --force --deep --sign - --entitlements "$ent" "$APP_PATH"
    rm -f "$ent"
}
