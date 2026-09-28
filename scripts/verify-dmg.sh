#!/usr/bin/env bash
# Mounts a DMG and checks that it contains a valid, correctly versioned NotchMate.app.
# Usage: scripts/verify-dmg.sh dist/NotchMate-1.2.0.dmg [expected-version]
set -euo pipefail

DMG="$1"
EXPECTED="${2:-}"
MOUNT="$(mktemp -d)"
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MOUNT" >/dev/null
trap 'hdiutil detach "$MOUNT" -quiet || true' EXIT

APP="$MOUNT/NotchMate.app"
[[ -d "$APP" ]] || { echo "error: NotchMate.app missing from DMG" >&2; exit 1; }
[[ -L "$MOUNT/Applications" ]] || { echo "error: Applications link missing from DMG" >&2; exit 1; }
codesign --verify --deep --strict "$APP"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
if [[ -n "$EXPECTED" && "$VERSION" != "$EXPECTED" ]]; then
  echo "error: app version $VERSION does not match $EXPECTED" >&2
  exit 1
fi
[[ -f "$APP/Contents/Resources/AppIcon.icns" || -f "$APP/Contents/Resources/Assets.car" ]] || { echo "error: app icon missing" >&2; exit 1; }
echo "OK: $DMG contains NotchMate $VERSION"
