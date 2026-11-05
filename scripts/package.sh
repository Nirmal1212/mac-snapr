#!/usr/bin/env bash
# Build Snapr.app (universal, with embedded Sparkle) and Snapr.dmg into ./dist
#
# Environment:
#   VERSION           marketing version (default 0.1.0); BUILD_NUMBER defaults to VERSION
#   BUNDLE_ID         bundle identifier (default com.you.snapr)
#   SIGN_IDENTITY     Developer ID for a real signature; defaults to ad-hoc ("-")
#   SU_FEED_URL       https URL of appcast.xml (Sparkle SUFeedURL)
#   SU_PUBLIC_ED_KEY  Sparkle EdDSA public key (from `generate_keys -p`); never the private key
# If SU_FEED_URL or SU_PUBLIC_ED_KEY is unset, the Sparkle keys are omitted and updates are disabled.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$VERSION}"
BUNDLE_ID="${BUNDLE_ID:-com.you.snapr}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
SU_FEED_URL="${SU_FEED_URL:-}"
SU_PUBLIC_ED_KEY="${SU_PUBLIC_ED_KEY:-}"
APP="dist/Snapr.app"
ARCHS=(--arch arm64 --arch x86_64)

# Developer ID: hardened runtime + secure timestamp (required for notarization). Library validation then
# accepts Sparkle because every component carries the same Team ID.
# Ad-hoc: hardened runtime would make dyld reject Sparkle (no Team ID to match), so it is left off.
# Ad-hoc builds are for local/tester use only and cannot be notarized.
sign() {
  local args=(--force --sign "$SIGN_IDENTITY")
  [[ "$SIGN_IDENTITY" != "-" ]] && args+=(--options runtime --timestamp)
  codesign "${args[@]}" "$@"
}

rm -rf dist && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"

swift build -c release "${ARCHS[@]}"
BIN_PATH="$(swift build -c release "${ARCHS[@]}" --show-bin-path)"
cp "$BIN_PATH/Snapr" "$APP/Contents/MacOS/Snapr"

# --- Sparkle.framework -------------------------------------------------------
# SwiftPM leaves the framework next to the product when it links an xcframework; fall back to the artifact.
SPARKLE_SRC="$BIN_PATH/Sparkle.framework"
[[ -d "$SPARKLE_SRC" ]] || SPARKLE_SRC="$(find .build/artifacts -type d -name Sparkle.framework -path '*macos*' | head -1)"
[[ -d "$SPARKLE_SRC" ]] || { echo "error: Sparkle.framework not found; run 'swift package resolve'" >&2; exit 1; }
ditto "$SPARKLE_SRC" "$APP/Contents/Frameworks/Sparkle.framework"  # ditto keeps the Versions symlinks

# The app is not sandboxed, so Sparkle's sandbox-only XPC services are dead weight.
rm -rf "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices" \
       "$APP/Contents/Frameworks/Sparkle.framework/XPCServices"

# SwiftPM only sets @loader_path; the framework lives in Contents/Frameworks.
RPATH="@executable_path/../Frameworks"
if ! otool -l "$APP/Contents/MacOS/Snapr" | grep -qF "path $RPATH "; then
  install_name_tool -add_rpath "$RPATH" "$APP/Contents/MacOS/Snapr"
fi

# --- Info.plist (must be final before signing) -------------------------------
SPARKLE_KEYS=""
if [[ -n "$SU_FEED_URL" && -n "$SU_PUBLIC_ED_KEY" ]]; then
  SPARKLE_KEYS="  <key>SUFeedURL</key><string>$SU_FEED_URL</string>
  <key>SUPublicEDKey</key><string>$SU_PUBLIC_ED_KEY</string>
  <key>SUEnableAutomaticChecks</key><true/>
  <key>SUEnableSystemProfiling</key><false/>"
else
  echo "warning: SU_FEED_URL / SU_PUBLIC_ED_KEY not both set; building with updates disabled" >&2
fi

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
  <key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
$SPARKLE_KEYS
</dict></plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# --- Sign inside-out (no --deep): helpers, framework, then the app -----------
FW="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
sign "$FW/Autoupdate"
sign "$FW/Updater.app"
sign "$APP/Contents/Frameworks/Sparkle.framework"
sign "$APP"
codesign --verify --strict --verbose=2 "$APP"

# --- DMG ---------------------------------------------------------------------
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/" && ln -s /Applications "$STAGE/Applications"
hdiutil create -volname Snapr -srcfolder "$STAGE" -ov -format UDZO "dist/Snapr-$VERSION.dmg" >/dev/null
echo "Built dist/Snapr-$VERSION.dmg"
