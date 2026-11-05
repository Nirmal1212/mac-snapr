#!/usr/bin/env bash
# Build Snapr.app (universal) and Snapr.dmg into ./dist
# Set SIGN_IDENTITY to a Developer ID for a real signature; defaults to ad-hoc ("-").
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.1.0}"
BUNDLE_ID="${BUNDLE_ID:-com.you.snapr}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
APP="dist/Snapr.app"

rm -rf dist && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swift build -c release --arch arm64 --arch x86_64
cp "$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Snapr" "$APP/Contents/MacOS/Snapr"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Snapr</string>
  <key>CFBundleDisplayName</key><string>Snapr</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key><string>Snapr</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

codesign --force --options runtime --sign "$SIGN_IDENTITY" "$APP"

STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/" && ln -s /Applications "$STAGE/Applications"
hdiutil create -volname Snapr -srcfolder "$STAGE" -ov -format UDZO "dist/Snapr-$VERSION.dmg" >/dev/null
echo "Built dist/Snapr-$VERSION.dmg"
