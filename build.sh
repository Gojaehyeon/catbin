#!/bin/bash
# Build Catbin.app without full Xcode (Command Line Tools + swiftc are enough).
set -euo pipefail

cd "$(dirname "$0")"

APP="Catbin.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

echo "==> Cleaning previous build"
rm -rf "$APP"
mkdir -p "$MACOS" "$RES"

echo "==> Compiling Swift"
swiftc -O \
    -target arm64-apple-macos13.0 \
    -framework Cocoa \
    -o "$MACOS/Catbin" \
    Sources/main.swift

echo "==> Installing Info.plist"
cp Info.plist "$CONTENTS/Info.plist"

# Copy user-supplied art if present in ./art (optional).
# Expected: <type>_idle.png / <type>_open.png  (e.g. black_idle.png, white_open.png)
if [ -d art ]; then
    echo "==> Copying art from ./art"
    cp art/*.png "$RES/" 2>/dev/null || true
    [ -f art/AppIcon.icns ] && cp art/AppIcon.icns "$RES/AppIcon.icns" || true
fi

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "   (codesign skipped)"

echo "==> Done: $(pwd)/$APP"
echo "    Run:  open $APP        (or drag it into the Dock)"
