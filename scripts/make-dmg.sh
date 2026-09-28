#!/usr/bin/env bash
# Packages an app bundle into a compressed, drag-to-install disk image.
#
# Usage: scripts/make-dmg.sh [path/to/NotchMate.app] [version]
# Output: dist/NotchMate-<version>.dmg and dist/NotchMate-<version>.dmg.sha256
set -euo pipefail

cd "$(dirname "$0")/.."
APP="${1:-build/NotchMate.app}"
VERSION="${2:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")}"
NAME="NotchMate-$VERSION"
OUT="dist/$NAME.dmg"

[[ -d "$APP" ]] || { echo "error: $APP not found (run scripts/build-release.sh first)" >&2; exit 1; }
mkdir -p dist
rm -f "$OUT" "$OUT.sha256"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/NotchMate.app"
ln -s /Applications "$STAGING/Applications"

# hdiutil occasionally fails with "Resource busy" on CI machines; retry a few times.
for attempt in 1 2 3 4 5; do
  if hdiutil create -volname "NotchMate $VERSION" -srcfolder "$STAGING" -fs HFS+ -format UDZO -ov "$OUT"; then
    break
  fi
  [[ $attempt == 5 ]] && { echo "error: hdiutil create failed" >&2; exit 1; }
  echo "hdiutil failed (attempt $attempt), retrying..." >&2
  sleep $((attempt * 3))
done

if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
  codesign --sign "$SIGNING_IDENTITY" --timestamp "$OUT"
fi

hdiutil verify "$OUT"
(cd dist && shasum -a 256 "$NAME.dmg" > "$NAME.dmg.sha256")
echo "Created $OUT"
