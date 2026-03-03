# RWD4EVR — Rewind.app Lives Forever
# SPDX-License-Identifier: MIT

.PHONY: all apps dmg checksums clean release verify

all: apps dmg

apps:
	@echo "=== Building App Bundles ==="
	@bash packaging/build-apps.sh

dmg: apps
	@echo "=== Building DMG ==="
	@bash packaging/build-dmg.sh

checksums: dmg
	@echo "=== Generating Checksums ==="
	@cd dist && shasum -a 256 RWD4EVR.dmg > SHA256SUMS
	@echo "  dist/SHA256SUMS"
	@cat dist/SHA256SUMS

release: checksums
	@echo ""
	@echo "=== Release Ready ==="
	@echo "  dist/RWD4EVR.dmg"
	@echo "  dist/SHA256SUMS"
	@echo ""
	@ls -lh dist/

verify:
	@bash src/verify.sh

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/ dist/
	@echo "Done."
