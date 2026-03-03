# Security

## What This Tool Does

RWD4EVR modifies 8 bytes of the Rewind.app binary to bypass the post-acquisition
shutdown kill switch. Here is exactly what changes:

| Property | Value |
|----------|-------|
| File modified | `/Applications/Rewind.app/Contents/MacOS/Rewind` |
| Offset (fat binary) | `0x1533c7c` (arm64 slice) |
| Original bytes | `fa 67 bb a9 f8 5f 01 a9` |
| Patched bytes | `00 00 80 52 c0 03 5f d6` |
| Original instructions | `STP x26,x25,[sp,#-80]!` / `STP x24,x31,[sp,16]` |
| Patched instructions | `MOVZ w0, #0` / `RET` |
| Effect | Cutoff date check always returns false |

The patch also:
- Re-signs the app with an ad-hoc code signature (original Developer ID signature is invalidated)
- Preserves entitlements: microphone access, calendar access
- Sets UserDefaults to enable recording on launch and suppress the cutoff alert

## What This Tool Does NOT Do

- Does not transmit any data
- Does not install any background processes, daemons, or launch agents
- Does not modify any files outside of `/Applications/Rewind.app` and `~/Library/Preferences/`
- Does not require or use network access
- Does not escalate privileges beyond what the user already has

## Verifying the Patch

Run `make verify` or `src/verify.sh` to inspect the current state of your binary,
including the exact bytes at the patch offset and code signature status.

## Verifying the Release

Every release includes a `SHA256SUMS` file. Verify:

```bash
shasum -a 256 -c SHA256SUMS
```

## Reporting Issues

If you find a security issue, please open an issue on the repository.

## Disclaimer

This software is provided as-is under the MIT license. Use at your own risk.
You are responsible for ensuring your use complies with applicable laws and
any license agreements you may have with the original software vendor.
