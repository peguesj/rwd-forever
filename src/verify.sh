#!/bin/bash
set -euo pipefail
# rwd-forever: Verify patch status
# SPDX-License-Identifier: MIT

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "RWD4EVR — Patch Verification"
echo ""

if ! app_exists; then
    echo "  Rewind.app: NOT FOUND"
    exit 1
fi

echo "  Rewind.app:  $(get_app_version)"
echo "  Architecture: $(uname -m)"
echo "  Bytes at patch offset: $(get_current_bytes)"
echo ""

if is_patched; then
    echo "  Status: PATCHED"
    echo "  The cutoff check is bypassed."
elif is_original; then
    echo "  Status: ORIGINAL (unpatched)"
    echo "  The cutoff check is active."
else
    echo "  Status: UNKNOWN"
    echo "  Bytes don't match original or patched signatures."
fi

echo ""

# Check signing
echo "  Code signature:"
codesign -v "$APP_PATH" 2>&1 && echo "    Valid" || echo "    Invalid or unsigned"
echo ""

# Check settings
echo "  Settings:"
echo "    recordOnLaunch: $(defaults read "$BUNDLE_ID" recordOnLaunch 2>/dev/null || echo 'not set')"
echo "    hasSeenRecordingCutoffAlert: $(defaults read "$BUNDLE_ID" hasSeenRecordingCutoffAlert 2>/dev/null || echo 'not set')"
echo "    SUAutomaticallyUpdate: $(defaults read "$BUNDLE_ID" SUAutomaticallyUpdate 2>/dev/null || echo 'not set')"
echo ""

# Check for backups
BACKUP_COUNT=0
for dir in "$BACKUP_DIR" "$HOME/Developer/rwd-forever/backups"; do
    if [ -d "$dir" ]; then
        count=$(ls "$dir"/Rewind_* 2>/dev/null | wc -l | tr -d ' ')
        BACKUP_COUNT=$((BACKUP_COUNT + count))
    fi
done
echo "  Backups found: $BACKUP_COUNT"
echo ""
