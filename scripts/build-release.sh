#!/usr/bin/env bash
# Builds a universal (Apple silicon + Intel) Release NotchMate.app into build/NotchMate.app.
#
# Usage: scripts/build-release.sh [version]
#   version            Marketing version, e.g. 1.2.0 (defaults to the project's value).
# Environment:
#   BUILD_NUMBER       CFBundleVersion (default: 1).
#   SIGNING_IDENTITY   e.g. "Developer ID Application: Jane Doe (TEAMID)". Ad-hoc signed when unset.
#   DEVELOPMENT_TEAM   Team ID, required with SIGNING_IDENTITY.
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="${1:-}"
DERIVED_DATA="build/DerivedData"

settings=()
if [[ -n "$VERSION" ]]; then
  settings+=("MARKETING_VERSION=$VERSION" "CURRENT_PROJECT_VERSION=${BUILD_NUMBER:-1}")
fi
if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
  settings+=(
    "CODE_SIGN_STYLE=Manual"
    "CODE_SIGN_IDENTITY=$SIGNING_IDENTITY"
    "DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM:?DEVELOPMENT_TEAM is required with SIGNING_IDENTITY}"
    "OTHER_CODE_SIGN_FLAGS=--timestamp"
  )
fi

xcodebuild \
  -project NotchMate.xcodeproj \
  -scheme NotchMate \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  ${settings[@]+"${settings[@]}"} \
  build

rm -rf build/NotchMate.app
cp -R "$DERIVED_DATA/Build/Products/Release/NotchMate.app" build/NotchMate.app
codesign --verify --deep --strict build/NotchMate.app
echo "Built build/NotchMate.app ($(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/NotchMate.app/Contents/Info.plist))"
lipo -archs build/NotchMate.app/Contents/MacOS/NotchMate
