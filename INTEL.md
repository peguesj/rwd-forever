# rwd-forever Intelligence Report

## Kill Switch Mechanism

### Primary Kill Switch: Hardcoded Cutoff Date
The app checks a cutoff date at multiple points in its recording pipeline. The date is NOT stored in
LaunchDarkly feature flags, NOT in UserDefaults, and NOT as a simple numeric constant in the binary.
It is most likely constructed dynamically using `DateComponents` in Swift source code, e.g.:
```swift
let cutoffDate = Calendar.current.date(from: DateComponents(year: 2025, month: X, day: Y))!
```

**Check points identified (from log analysis):**
| Location | Line | Message |
|----------|------|---------|
| `RecordingController.toggle()` | ~750 | "Recording disabled due to cutoff date - not toggling" |
| `RecordingController.start()` | ~750 | "Recording disabled due to cutoff date - not starting" |
| `RecordingController.resume(forceResume:)` | ~763 | "Recording disabled due to cutoff date - not resuming" |
| `ResourceUsageMonitor` | - | "Recording cutoff date reached - stopping all recording" |
| `AudioRecordingController.startAudioRecording()` | ~414 | "Recording disabled due to cutoff date - not starting audio recording" |
| `AudioRecordingController` | - | "Recording cutoff date reached - stopping audio recording" |
| `MeetingCoordinator.start()` | ~82 | "Recording disabled due to cutoff date - skipping meeting detection setup" |

**UI Message:** "Recording is disabled because Rewind has been shut down"
**Alert Flag:** `hasSeenRecordingCutoffAlert` in UserDefaults

### Secondary Systems
- **Sparkle Auto-Update**: Checks `https://updates.rewind.ai/appcasts/main.xml` (dead server, fails gracefully)
- **LaunchDarkly**: SDK key `mob-86e6b951-4478-46d0-8b95-9df56361224e`, currently in "offline" mode
- **Analytics/Sentry**: Sends analytics data to now-dead endpoints (fails gracefully)

## LaunchDarkly Feature Flags (Cached)

These are the ACTUAL cached flag values from the LD disk cache:
```
accelerate-audioprocessing: true
accelerate-conversion: false
askrewind-2.0: true
audio-transcription: true
client-query-connection: false
cloud-multi-device: false
cloud-storage: false
daily-recap: true
enable-user-authentication: false
ios-foreground-data: true
media-encryption: false
metrics-reporting-enabled: false
metrics-reporting-interval: 300
metrics-sample-interval: 5
open-summary-in-recap: true
pay-gate-and-trial: false
perform-batch-updates-fix: true
pixel-buffer-memory-fix: false
segments-filter-facets: false
sentry-sample-rate: 0.001
sync: false
sync-data-migration: false
user-referrals: false
whisper-coreml: true
whisper-text-context-tokens: 0
```

**Note**: There is NO cutoff-date flag in LD. The cutoff is hardcoded in the binary.

## LD Cache Locations
```
~/Library/Preferences/com.launchdarkly.client.Ktz4m22IY00pHXyEwvSf/
~/Library/Preferences/com.launchdarkly.client.WQBZF7dMqIxEgRueKcccQP0BBYLlWqHxAfpw6oE3iTI=.DphO/
```

## App Architecture

### Source Structure (from debug symbols)
```
/Users/runner/work/rewind/rewind/
├── MemoryVault/
│   ├── AppDelegate.swift
│   ├── AppDelegateController.swift
│   ├── RecordingController.swift          <-- PRIMARY TARGET
│   ├── Transcription/
│   │   └── AudioRecordingController.swift <-- SECONDARY TARGET
│   ├── Browsers/
│   │   └── ChromeUIBrowser.swift
│   └── ...
├── apple/
│   ├── RWCore/Sources/
│   │   ├── RWFeatureFlags/
│   │   │   ├── RWFeatureFlags.swift
│   │   │   └── RWFeatureFlagLogger.swift
│   │   ├── RWAnalytics/
│   │   ├── RWNetworking/
│   │   └── RWCore/Settings/Settings_macos.swift
│   ├── RWTranscription/Sources/
│   │   └── Helpers/RecordingControllerHelpers.swift
│   ├── RWAskRewindFeature/
│   └── RWLanguageModel/
└── Libraries/Sources/Database/
```

### Key Swift Classes
- `RecordingController` - Screen capture pipeline, cutoff checks
- `AudioRecordingController` - Microphone/audio capture, cutoff checks
- `MeetingCoordinator` - Meeting detection, cutoff checks
- `AppDelegateController` - App lifecycle
- `RWFeatureFlags` - LaunchDarkly feature flag wrapper
- `StorageController` - Data retention/purge
- `ResourceUsageMonitor` - System resource monitoring, recording health checks

### Data Storage
- **Main DB**: `~/Library/Application Support/com.memoryvault.MemoryVault/db-enc.sqlite3` (19.7 GB, encrypted)
- **Chunks**: `~/Library/Application Support/com.memoryvault.MemoryVault/chunks/` (organized by YYYYMM/DD)
- **Audio Snippets**: `~/Library/Application Support/com.memoryvault.MemoryVault/snippets/`
- **Logs**: `~/Library/Logs/Rewind/`
- **Preferences**: `com.memoryvault.MemoryVault` (UserDefaults domain)

### Binary Details
- **Format**: Mach-O universal (x86_64 + arm64), fat binary
- **x86_64 slice**: offset 0x4000, size ~21.5 MB
- **arm64 slice**: offset 0x1498000, size ~20.7 MB
- **Code Signing**: Developer ID (Rewind AI Inc.), hardened runtime, notarized
- **Symbols**: Stripped (no nm output)
- **Provisioning Profile**: Expires 2041-08-05 (not an issue)

### Frameworks
- `Sparkle.framework` - Auto-update (tries updates.rewind.ai, fails gracefully)

### Resource Bundles
- `CocoaLumberjack_CocoaLumberjack.bundle` - Logging
- `Highlightr_Highlightr.bundle` - Syntax highlighting
- `KeyboardShortcuts_KeyboardShortcuts.bundle` - Hotkeys
- `Libraries_RewindMeetings.bundle` - Meeting features
- `RWCore_RWCoreUI.bundle` - Core UI
- `RWLanguageModel_RWLanguageModel.bundle` - AI/LLM features
- `RWTranscription_RWTranscription.bundle` - Audio transcription
- `swift-composable-architecture_ComposableArchitecture.bundle` - TCA framework
- `swift-sharing_Sharing.bundle` - State sharing

### Key UserDefaults
```
hasSeenRecordingCutoffAlert: true    <-- cutoff alert shown
recordOnLaunch: false                <-- recording toggle (currently off due to cutoff)
recordAudioOnLaunch: true            <-- audio recording preference
launchAtLogin: true
email: jeremiah.pegues@gmail.com
hasCompletedOnboarding: true
```

### Encrypted Data Blobs (UserDefaults)
- `ai.rewind.data-account` (170 bytes) - Encrypted account data
- `ai.rewind.data-trial` (176 bytes) - Encrypted trial/subscription data

## Attack Vectors

### Vector 1: Binary Patch (NOP the cutoff check) -- RECOMMENDED
**Approach**: Find the conditional branch instruction(s) that check `Date() > cutoffDate` and
patch them to always fall through (NOP or unconditional branch to the "continue recording" path).

**Pros**: Clean, permanent, no external dependencies
**Cons**: Need to find exact instruction offsets, must re-sign binary (loses notarization)

**Steps**:
1. Copy binary to work directory
2. Use disassembler to find cutoff comparison functions
3. Patch conditional branches to unconditional (or NOP)
4. Strip existing code signature
5. Re-sign with ad-hoc signature + same entitlements
6. Replace original binary

### Vector 2: DYLD Injection (override cutoff function)
**Approach**: Create a dylib that intercepts the cutoff date check and returns false/nil.

**Pros**: Non-destructive to original binary, easy to update
**Cons**: Requires `com.apple.security.cs.disable-library-validation` entitlement + re-sign,
         or using DYLD_INSERT_LIBRARIES which requires re-signing anyway

### Vector 3: System Clock Manipulation
**Approach**: Use a virtual clock or intercept `gettimeofday`/`clock_gettime` for just this process.

**Pros**: Zero binary modification
**Cons**: Affects all date/time in the app, recordings would have wrong timestamps

### Vector 4: LaunchDarkly Cache Injection
**Approach**: Add a fake "recording-cutoff-date" flag to the LD cache with a far-future date.

**Pros**: Uses existing infrastructure
**Cons**: The cutoff is NOT from LD flags - it's hardcoded. Won't work.

### Vector 5: UserDefaults + Environment Manipulation
**Approach**: Reset `hasSeenRecordingCutoffAlert`, set `recordOnLaunch: true`, and block network
access to prevent LD from updating flags.

**Pros**: Easy to implement
**Cons**: The cutoff check happens in the recording pipeline itself, not just at the UI level.
         Setting recordOnLaunch=true would try to start recording but the cutoff check would
         still block it at RecordingController.start():750.

## Recommended Strategy

**Primary**: Vector 1 (Binary Patch) - the cutoff is a simple date comparison in the code.
We need to:
1. Find the comparison function using disassembly (Hopper/Ghidra/radare2)
2. Identify the conditional branch instruction(s)
3. Patch to NOP or unconditional jump
4. Re-sign the binary with ad-hoc + entitlements
5. Test that recording resumes

**Secondary**: After patching recording, also:
- Disable Sparkle auto-update checks (already failing gracefully)
- Block/disable analytics/Sentry (already failing gracefully)
- Consider blocking LD network calls to prevent future flag changes if servers come back
