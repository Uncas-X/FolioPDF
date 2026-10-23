#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export CLANG_MODULE_CACHE_PATH=/private/tmp/FolioPDF-module-cache
export SWIFTPM_MODULECACHE_OVERRIDE=/private/tmp/FolioPDF-module-cache
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' packaging/Info.plist)
mkdir -p "$ROOT/dist"
BUILD_STAGE=$(mktemp -d "$ROOT/dist/.folio-build.XXXXXX")
trap 'rm -rf "$BUILD_STAGE"' EXIT
APP="$BUILD_STAGE/FolioPDF.app"
FINAL_APP="$ROOT/dist/FolioPDF.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [[ "${1:-}" == "--host-only" ]]; then
    ARCHES="$(uname -m)"
else
    ARCHES="arm64 x86_64"
fi
for ARCH in $ARCHES; do
    swift build -c release --arch "$ARCH" --disable-sandbox --cache-path /private/tmp/FolioPDF-swiftpm-cache
done
if [[ "$ARCHES" == *" "* ]]; then
    lipo -create "$ROOT/.build/arm64-apple-macosx/release/FolioPDF" "$ROOT/.build/x86_64-apple-macosx/release/FolioPDF" -output "$APP/Contents/MacOS/FolioPDF"
    RESOURCE_BUILD="$ROOT/.build/arm64-apple-macosx/release"
else
    cp "$ROOT/.build/$ARCHES-apple-macosx/release/FolioPDF" "$APP/Contents/MacOS/FolioPDF"
    RESOURCE_BUILD="$ROOT/.build/$ARCHES-apple-macosx/release"
fi
cp -R "$RESOURCE_BUILD/FolioPDF_FolioPDF.bundle" "$APP/Contents/Resources/"
cp packaging/Info.plist "$APP/Contents/Info.plist"
swift scripts/create-icon.swift "$ROOT/dist/AppIcon.iconset"
iconutil -c icns "$ROOT/dist/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"
# Build a fresh bundle so a running copy is never rewritten in place.
# Retain the previous bundle in a hidden folder for recovery and running processes.
PREVIOUS_APP=""
if [[ -e "$FINAL_APP" ]]; then
    PREVIOUS_APP=$(mktemp -d "$ROOT/dist/.folio-previous.XXXXXX")
    mv "$FINAL_APP" "$PREVIOUS_APP/FolioPDF.app"
fi
if ! mv "$APP" "$FINAL_APP"; then
    if [[ -n "$PREVIOUS_APP" ]]; then mv "$PREVIOUS_APP/FolioPDF.app" "$FINAL_APP"; fi
    exit 1
fi
APP="$FINAL_APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ROOT/dist/FolioPDF-$VERSION-macOS.zip"
echo "Built: $APP"
