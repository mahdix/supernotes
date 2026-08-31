#!/usr/bin/env bash
# Build SuperNotes.app for Apple Silicon (arm64).
# Output: dist/SuperNotes.app
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

ARCH="arm64"
CONFIGURATION="Release"
SCHEME="SuperNotes"
PROJECT="SuperNotes.xcodeproj"
DERIVED_DATA="${ROOT}/build_${ARCH}"
OUTPUT_DIR="${ROOT}/dist"
APP_NAME="SuperNotes.app"
PRODUCT="${DERIVED_DATA}/Build/Products/${CONFIGURATION}/${APP_NAME}"
DEST="${OUTPUT_DIR}/${APP_NAME}"

echo "==> Building ${APP_NAME} for Apple Silicon (${ARCH})"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found. Install Xcode from the App Store." >&2
  exit 1
fi

HOST_ARCH="$(uname -m)"
if [[ "$HOST_ARCH" != "arm64" ]]; then
  echo "warning: host architecture is ${HOST_ARCH}, not arm64. Cross-compiling." >&2
fi

if ! command -v swiftformat >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/swiftformat ]]; then
  echo "warning: SwiftFormat not installed (optional). brew install swiftformat"
fi

rm -rf "$DEST"
mkdir -p "$OUTPUT_DIR"

# HTTPS_PROXY/HTTP_PROXY pointing at a local SOCKS port breaks SPM/git clones.
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy 2>/dev/null || true

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  ARCHS="$ARCH" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$PRODUCT" ]]; then
  echo "error: build finished but ${PRODUCT} was not found" >&2
  exit 1
fi

BINARY="${PRODUCT}/Contents/MacOS/SuperNotes"
if [[ -f "$BINARY" ]]; then
  strip "$BINARY" || true
fi

cp -R "$PRODUCT" "$DEST"
xattr -cr "$DEST" 2>/dev/null || true

echo
echo "==> Done"
echo "    ${DEST}"
file "${DEST}/Contents/MacOS/SuperNotes"
ls -lh "${DEST}/Contents/MacOS/SuperNotes"
