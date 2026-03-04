## NTFSMount — Makefile
## Author: KECHANKRISNA
##
## Targets:
##   make build      Build debug binary
##   make release    Build release binary
##   make app        Build NTFSMount.app (universal)
##   make dmg        Build NTFSMount.app + NTFSMount.dmg
##   make clean      Remove build artefacts
##   make version    Print current version from Info.plist
##   make tag        Create a git tag and push (triggers GitHub release)

VERSION := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
             Sources/NTFSMount/Info.plist 2>/dev/null || echo "1.0.0")

.PHONY: build release app dmg clean version tag help

help:
	@echo ""
	@echo "NTFSMount v$(VERSION) — build targets"
	@echo ""
	@echo "  make build    — swift build (debug)"
	@echo "  make release  — swift build -c release"
	@echo "  make app      — build universal NTFSMount.app"
	@echo "  make dmg      — build NTFSMount-v$(VERSION).dmg  ← distribute this"
	@echo "  make clean    — remove all build artefacts"
	@echo "  make version  — show current version"
	@echo "  make tag      — tag + push → triggers GitHub Actions release"
	@echo ""

build:
	swift build

release:
	swift build -c release

app:
	bash scripts/build-app.sh $(VERSION)
	@echo "App built: NTFSMount.app"

dmg: app
	@echo "DMG ready: NTFSMount-v$(VERSION).dmg"

clean:
	rm -rf .build NTFSMount.app NTFSMount-*.dmg dmg_staging NTFSMount-universal
	@echo "Cleaned."

version:
	@echo "$(VERSION)"

tag:
	@echo "Tagging v$(VERSION) and pushing to GitHub..."
	git tag -a "v$(VERSION)" -m "Release v$(VERSION)"
	git push origin "v$(VERSION)"
	@echo ""
	@echo "✓ Tag pushed. GitHub Actions will build and publish the release."
	@echo "  Track progress at: https://github.com/kechankrisna/NTFSMount/actions"
