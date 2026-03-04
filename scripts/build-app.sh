#!/usr/bin/env bash
# =============================================================================
# build-app.sh — Build NTFSMount.app + NTFSMount.dmg locally on macOS
# Usage:  bash scripts/build-app.sh [version]
# Example: bash scripts/build-app.sh 1.0.0
# =============================================================================
set -euo pipefail

# Resolve to repo root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

# Confirm Package.swift is here
if [[ ! -f "Package.swift" ]]; then
  echo "Error: Package.swift not found in $PROJECT_DIR" >&2
  exit 1
fi

VERSION="${1:-1.0.0}"
APP="NTFSMount.app"
DMG="NTFSMount-v${VERSION}.dmg"
STAGING="dmg_staging"

echo "=================================================="
echo " NTFSMount build script"
echo " Version : $VERSION"
echo " Output  : $PROJECT_DIR/$DMG"
echo "=================================================="

# ── Require macOS ────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This script must be run on macOS." >&2
  exit 1
fi

# ── Clean previous build artifacts ────────────────────────────────────────────
echo ""
echo "► Cleaning previous build..."
rm -rf "$APP" "$DMG" "$STAGING"

# ── Build universal binary ────────────────────────────────────────────────────
echo ""
echo "► Building arm64..."
swift build -c release --arch arm64

echo ""
echo "► Building x86_64..."
swift build -c release --arch x86_64

echo ""
echo "► Linking universal binary with lipo..."
lipo -create -output NTFSMount-universal \
  .build/arm64-apple-macosx/release/NTFSMount \
  .build/x86_64-apple-macosx/release/NTFSMount

echo "  $(file NTFSMount-universal)"

# ── Assemble .app bundle ───────────────────────────────────────────────────────
echo ""
echo "► Assembling $APP..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp NTFSMount-universal "$APP/Contents/MacOS/NTFSMount"
chmod +x "$APP/Contents/MacOS/NTFSMount"

# Patch version into Info.plist
sed "s/<string>1\.0\.0<\/string>/<string>${VERSION}<\/string>/g; \
     s/<string>1<\/string>/<string>${VERSION}<\/string>/g" \
  Sources/NTFSMount/Info.plist > "$APP/Contents/Info.plist"

rm -f NTFSMount-universal
echo "  $APP assembled"

# ── Ad-hoc code sign ──────────────────────────────────────────────────────────
echo ""
echo "► Signing $APP (ad-hoc)..."
codesign --force --deep --sign - \
         --options runtime \
         --entitlements scripts/entitlements.plist \
         "$APP"
echo "  Signed: $(codesign -dv "$APP" 2>&1 | head -1)"

# ── Create DMG ────────────────────────────────────────────────────────────────
echo ""
echo "► Creating $DMG..."
mkdir -p "$STAGING"
cp -r "$APP" "$STAGING/"
ln -sf /Applications "$STAGING/Applications"

hdiutil create \
  -volname  "NTFSMount $VERSION" \
  -srcfolder "$STAGING" \
  -ov \
  -format   UDZO \
  -fs       HFS+ \
  "$DMG"

rm -rf "$STAGING"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo " ✓ Done!"
echo "   App : $PROJECT_DIR/$APP"
echo "   DMG : $PROJECT_DIR/$DMG"
echo ""
CHECKSUM="$(shasum -a 256 "$DMG" | awk '{print $1}')"
echo "   SHA-256: $CHECKSUM"
echo "=================================================="
echo ""
echo "To install: open $DMG and drag NTFSMount.app to Applications."
echo "First launch: right-click → Open (bypasses Gatekeeper for unsigned builds)."
