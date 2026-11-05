#!/usr/bin/env bash
# Generate an EdDSA-signed appcast.xml from a directory of release archives (DMG/zip).
#
# Usage: scripts/make-appcast.sh <releases-dir> [download-url-prefix]
#   download-url-prefix  base URL the archives will be served from, e.g.
#                        https://github.com/OWNER/mac-snapr/releases/download/vX.Y.Z/
#
# The private key is read from the login keychain (created by Sparkle's `generate_keys`), or from the
# file named by SPARKLE_ED_KEY_FILE. It is never read from the repository. Nothing is uploaded.
set -euo pipefail
cd "$(dirname "$0")/.."

DIR="${1:?usage: make-appcast.sh <releases-dir> [download-url-prefix]}"
PREFIX="${2:-}"
[[ -d "$DIR" ]] || { echo "error: $DIR is not a directory" >&2; exit 1; }

TOOL="${GENERATE_APPCAST:-$(find .build/artifacts -type f -name generate_appcast -path '*/bin/*' | head -1)}"
[[ -x "$TOOL" ]] || { echo "error: generate_appcast not found; run 'swift package resolve' or set GENERATE_APPCAST" >&2; exit 1; }

ARGS=()
[[ -n "${SPARKLE_ED_KEY_FILE:-}" ]] && ARGS+=(--ed-key-file "$SPARKLE_ED_KEY_FILE")
[[ -n "$PREFIX" ]] && ARGS+=(--download-url-prefix "$PREFIX")

"$TOOL" ${ARGS[@]+"${ARGS[@]}"} "$DIR"
echo "Wrote $DIR/appcast.xml"
