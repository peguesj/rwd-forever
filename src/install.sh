#!/bin/bash
set -euo pipefail
# rwd-forever: Install — patch Rewind.app cutoff check
# SPDX-License-Identifier: MIT

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# --- GUI mode (called from .app bundle) ---
GUI=false
if [ "${1:-}" = "--gui" ]; then
    GUI=true
    shift
fi

dialog() {
    if $GUI; then
        osascript -e "display dialog \"$1\" with title \"RWD4EVR\" buttons {\"OK\"} default button \"OK\" with icon $2" 2>/dev/null || true
    else
        echo "  $1"
    fi
}

dialog_yesno() {
    if $GUI; then
        osascript -e "display dialog \"$1\" with title \"RWD4EVR\" buttons {\"Cancel\", \"$2\"} default button \"$2\" with icon caution" 2>/dev/null
        return $?
    else
        read -p "  $1 [Y/n] " -n 1 -r
        echo ""
        [[ ! $REPLY =~ ^[Nn]$ ]]
    fi
}

fail() {
    if $GUI; then
        osascript -e "display dialog \"$1\" with title \"RWD4EVR — Error\" buttons {\"OK\"} default button \"OK\" with icon stop" 2>/dev/null || true
    else
        echo "  ERROR: $1" >&2
    fi
    exit 1
}

# --- Preflight ---

if ! is_arm64; then
    fail "This patch targets Apple Silicon (arm64).\\nDetected: $(uname -m)"
fi

if ! app_exists; then
    fail "Rewind.app not found at /Applications/Rewind.app.\\nInstall Rewind first."
fi

VERSION=$(get_app_version)
if [ "$VERSION" != "$SUPPORTED_VERSION" ]; then
    dialog_yesno "This patch was built for Rewind v${SUPPORTED_VERSION}.\\nYou have v${VERSION}.\\n\\nThe patch may not work on this version." "Continue Anyway" || exit 0
fi

if is_patched; then
    dialog "Rewind.app is already patched. Nothing to do." "note"
    exit 0
fi

if is_rewind_running; then
    dialog_yesno "Rewind is currently running.\\nIt must be quit before patching." "Quit Rewind" || exit 0
    killall Rewind 2>/dev/null || true
    sleep 1
    if is_rewind_running; then
        fail "Could not quit Rewind. Please quit it manually and try again."
    fi
fi

if ! is_original; then
    CURRENT=$(get_current_bytes)
    dialog_yesno "Unexpected bytes at patch location: ${CURRENT}\\n\\nThis binary may be modified or a different version." "Patch Anyway" || exit 0
fi

# --- Confirm ---

if $GUI; then
    osascript -e 'display dialog "RWD4EVR will:\n\n• Back up your original Rewind binary\n• Patch the cutoff date check (8 bytes)\n• Re-sign the app with ad-hoc signature\n• Configure settings for recording\n\nYour data and recordings are not affected." with title "RWD4EVR Installer" buttons {"Cancel", "Install"} default button "Install" with icon caution' 2>/dev/null || exit 0
else
    echo ""
    echo "  This will:"
    echo "    1. Back up your original Rewind binary"
    echo "    2. Patch the cutoff date check (8 bytes)"
    echo "    3. Re-sign the app with ad-hoc signature"
    echo "    4. Configure settings for recording"
    echo ""
    dialog_yesno "Ready to install?" "Install" || exit 0
fi

# --- Backup ---

$GUI || echo "  [1/4] Backing up original binary..."
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/Rewind_${TIMESTAMP}"
cp "$BINARY" "$BACKUP_FILE"
$GUI || echo "         $BACKUP_FILE"

# --- Patch ---

$GUI || echo "  [2/4] Patching cutoff check..."
printf '\x00\x00\x80\x52\xc0\x03\x5f\xd6' | dd of="$BINARY" bs=1 seek=$ARM64_PATCH_OFFSET conv=notrunc 2>/dev/null

if ! is_patched; then
    cp "$BACKUP_FILE" "$BINARY"
    fail "Patch verification failed. Original binary restored."
fi
$GUI || echo "         Verified."

# --- Re-sign ---

$GUI || echo "  [3/4] Re-signing..."
resign_app
$GUI || echo "         Done."

# --- Configure ---

$GUI || echo "  [4/4] Configuring..."
defaults write "$BUNDLE_ID" hasSeenRecordingCutoffAlert -bool false
defaults write "$BUNDLE_ID" recordOnLaunch -bool true
defaults write "$BUNDLE_ID" SUAutomaticallyUpdate -bool false
defaults write "$BUNDLE_ID" SUEnableAutomaticChecks -bool false
$GUI || echo "         Done."

# --- Done ---

if $GUI; then
    RESULT=$(osascript -e 'display dialog "Installation complete!\n\nRewind.app has been patched and is ready to record.\n\nBackup saved to:\n~/Library/Application Support/RWD4EVR/backups/" with title "RWD4EVR" buttons {"Done", "Launch Rewind"} default button "Launch Rewind" with icon note' 2>/dev/null || echo "button returned:Done")
    if echo "$RESULT" | grep -q "Launch Rewind"; then
        open /Applications/Rewind.app
    fi
else
    echo ""
    echo "  Installation complete."
    echo "  Backup: $BACKUP_FILE"
    echo ""
    echo "  Launch Rewind:"
    echo "    open /Applications/Rewind.app"
    echo ""
    echo "  If macOS blocks the app:"
    echo "    xattr -cr /Applications/Rewind.app"
    echo ""
fi
