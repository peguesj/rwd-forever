#!/bin/bash
set -euo pipefail
# rwd-forever: Uninstall — restore original Rewind.app binary
# SPDX-License-Identifier: MIT

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

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

fail() {
    if $GUI; then
        osascript -e "display dialog \"$1\" with title \"RWD4EVR — Error\" buttons {\"OK\"} default button \"OK\" with icon stop" 2>/dev/null || true
    else
        echo "  ERROR: $1" >&2
    fi
    exit 1
}

# --- Preflight ---

if ! app_exists; then
    fail "Rewind.app not found at /Applications/Rewind.app."
fi

if ! is_patched; then
    if is_original; then
        dialog "Rewind.app is not patched. Nothing to restore." "note"
        exit 0
    fi
fi

if is_rewind_running; then
    if $GUI; then
        osascript -e 'display dialog "Rewind is currently running.\nIt must be quit before restoring." with title "RWD4EVR" buttons {"Cancel", "Quit Rewind"} default button "Quit Rewind" with icon caution' 2>/dev/null || exit 0
    else
        echo "  Rewind is running."
        read -p "  Quit and continue? [Y/n] " -n 1 -r
        echo ""
        [[ $REPLY =~ ^[Nn]$ ]] && exit 0
    fi
    killall Rewind 2>/dev/null || true
    sleep 1
fi

# --- Find backup ---

LATEST_BACKUP=""
OLD_BACKUP_DIR="$HOME/Developer/rwd-forever/backups"

for dir in "$BACKUP_DIR" "$OLD_BACKUP_DIR"; do
    if [ -d "$dir" ]; then
        candidate=$(ls -t "$dir"/Rewind_* 2>/dev/null | head -1 || true)
        if [ -n "$candidate" ]; then
            LATEST_BACKUP="$candidate"
            break
        fi
    fi
done

if [ -z "$LATEST_BACKUP" ]; then
    fail "No backup found.\\n\\nCannot restore without the original binary."
fi

# --- Confirm ---

if $GUI; then
    osascript -e "display dialog \"Restore original Rewind binary?\\n\\nBackup: $(basename "$LATEST_BACKUP")\" with title \"RWD4EVR Uninstaller\" buttons {\"Cancel\", \"Restore\"} default button \"Restore\" with icon caution" 2>/dev/null || exit 0
else
    echo "  Backup: $LATEST_BACKUP"
    read -p "  Restore original binary? [Y/n] " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Nn]$ ]] && exit 0
fi

# --- Restore ---

$GUI || echo "  [1/3] Restoring binary..."
cp "$LATEST_BACKUP" "$BINARY"

$GUI || echo "  [2/3] Re-signing..."
resign_app

$GUI || echo "  [3/3] Resetting settings..."
defaults write "$BUNDLE_ID" hasSeenRecordingCutoffAlert -bool true
defaults write "$BUNDLE_ID" recordOnLaunch -bool false

# --- Done ---

if $GUI; then
    osascript -e 'display dialog "Original binary restored.\n\nRewind.app is back to its unpatched state." with title "RWD4EVR" buttons {"OK"} default button "OK" with icon note' 2>/dev/null || true
else
    echo ""
    echo "  Original binary restored."
    echo ""
fi
