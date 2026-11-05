#!/usr/bin/env bash
# Render Snapr branding PNGs from assets/branding/*.svg and build AppIcon.icns.
# Needs only macOS built-ins: swiftc (AppKit SVG rendering, macOS 13+), iconutil.
# Outputs: assets/branding/AppIcon.icns, assets/branding/MenuBarIconTemplate{,@2x}.png,
#          assets/branding/png/{app-icon-1024,logo-512,favicon-32,favicon-180}.png
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=assets/branding
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

swiftc -O scripts/render-svg.swift -o "$TMP/render"
render() { "$TMP/render" "$@"; }   # render in.svg out.png size

# --- AppIcon.icns ------------------------------------------------------------
SET="$TMP/AppIcon.iconset"
mkdir -p "$SET"
for s in 16 32 128 256 512; do
  render "$SRC/app-icon.svg" "$SET/icon_${s}x${s}.png" "$s"
  render "$SRC/app-icon.svg" "$SET/icon_${s}x${s}@2x.png" "$((s * 2))"
done
iconutil -c icns "$SET" -o "$SRC/AppIcon.icns"

# --- Menu bar template image (black + alpha; macOS tints it) -----------------
render "$SRC/menubar-glyph.svg" "$SRC/MenuBarIconTemplate.png" 18
render "$SRC/menubar-glyph.svg" "$SRC/MenuBarIconTemplate@2x.png" 36

# --- Web PNGs ----------------------------------------------------------------
mkdir -p "$SRC/png"
render "$SRC/app-icon.svg" "$SRC/png/app-icon-1024.png" 1024
render "$SRC/logo.svg" "$SRC/png/logo-512.png" 512
render "$SRC/favicon.svg" "$SRC/png/favicon-32.png" 32
render "$SRC/favicon.svg" "$SRC/png/favicon-180.png" 180

echo "Wrote $SRC/AppIcon.icns, MenuBarIconTemplate(.png|@2x.png), png/*"
