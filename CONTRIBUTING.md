# Contributing

Contributions are welcome. This is a small, focused project — keep changes
minimal and well-documented.

## Requirements

- macOS 12.3+ on Apple Silicon
- Xcode Command Line Tools (`xcode-select --install`)
- Rewind.app v1.5607 (for testing)

## Building from Source

```bash
git clone <repo-url>
cd rwd-forever
make release
```

This produces:
- `dist/RWD4EVR.dmg` — distributable disk image
- `dist/SHA256SUMS` — checksum file

## Project Structure

```
src/          Core scripts (install, uninstall, verify, shared functions)
packaging/    Build tooling (app bundles, DMG creation, icon/background generators)
assets/       Static assets (entitlements plist)
INTEL.md      Reverse engineering notes and analysis
```

## Code Style

- Shell scripts: `set -euo pipefail`, functions over repetition, POSIX where practical
- Swift scripts: used only for macOS-native image generation during build
- Comments explain *why*, not *what*

## Testing

Before submitting changes:

1. `make clean && make release` — full clean build
2. `make verify` — check patch verification on your binary
3. Test the installer and uninstaller from the built DMG
4. Verify the DMG checksum matches `dist/SHA256SUMS`

## Scope

This project patches **one specific version** of Rewind.app (v1.5607, build 15607.1).
PRs that add support for other versions are welcome if they maintain the same
minimal-patch approach.

Out of scope:
- Feature additions to Rewind itself
- Cracking subscription/payment checks (there are none — Rewind was free)
- Network interception or proxy setups
