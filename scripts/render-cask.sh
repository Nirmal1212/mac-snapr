#!/usr/bin/env bash
# Render the Homebrew cask for a release DMG to stdout.
# Usage: scripts/render-cask.sh <path-to-dmg> <version>   (BUNDLE_ID overrides the zap bundle id)
# Copy the output to Casks/snapr.rb in your tap; nothing is published here.
set -euo pipefail
cd "$(dirname "$0")/.."

DMG="${1:?usage: render-cask.sh <dmg> <version>}"
VERSION="${2:?usage: render-cask.sh <dmg> <version>}"
BUNDLE_ID="${BUNDLE_ID:-com.you.snapr}"
[[ -f "$DMG" ]] || { echo "error: $DMG not found" >&2; exit 1; }

SHA256="$(shasum -a 256 "$DMG" | awk '{print $1}')"
sed -e "s|@VERSION@|$VERSION|g" -e "s|@SHA256@|$SHA256|g" -e "s|@BUNDLE_ID@|$BUNDLE_ID|g" \
  packaging/homebrew/snapr.rb.template
