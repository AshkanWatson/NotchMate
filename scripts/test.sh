#!/usr/bin/env bash
# Runs the same checks as CI.
#
# Usage: scripts/test.sh [--no-ui]
#   --no-ui   Skip UI tests (they move the real mouse pointer).
set -euo pipefail

cd "$(dirname "$0")/.."
RUN_UI=1
[[ "${1:-}" == "--no-ui" ]] && RUN_UI=0
DERIVED_DATA="build/DerivedData-tests"
COMMON=(-project NotchMate.xcodeproj -scheme NotchMate -destination 'platform=macOS' -derivedDataPath "$DERIVED_DATA")

if command -v swiftlint >/dev/null; then
  echo "▸ SwiftLint"
  swiftlint lint --strict --quiet
else
  echo "▸ SwiftLint not installed (brew install swiftlint); skipping"
fi

echo "▸ NotchMateKit unit tests"
swift test --package-path Packages/NotchMateKit

echo "▸ Build (warnings are errors)"
xcodebuild "${COMMON[@]}" SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build-for-testing -quiet

echo "▸ App unit tests"
xcodebuild "${COMMON[@]}" test-without-building -only-testing:NotchMateTests -quiet

if [[ $RUN_UI == 1 ]]; then
  echo "▸ UI tests (don't touch the mouse)"
  xcodebuild "${COMMON[@]}" test-without-building -only-testing:NotchMateUITests -quiet
fi
echo "✓ All checks passed"
