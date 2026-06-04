#!/usr/bin/env bash
set -euo pipefail

ios_destination="${PICKO_IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
ios_derived_data="${PICKO_IOS_DERIVED_DATA:-/private/tmp/picko-derived-data}"
mac_derived_data="${PICKO_MAC_DERIVED_DATA:-/private/tmp/picko-mac-derived-data}"

echo "== iOS simulator build =="
xcodebuild \
  -project Picko.xcodeproj \
  -scheme Picko \
  -configuration Debug \
  -destination "$ios_destination" \
  -derivedDataPath "$ios_derived_data" \
  build \
  -quiet

echo "== iOS app and UI tests =="
xcodebuild \
  -project Picko.xcodeproj \
  -scheme Picko \
  -configuration Debug \
  -destination "$ios_destination" \
  -derivedDataPath "$ios_derived_data" \
  test \
  -only-testing:PickoTests \
  -only-testing:PickoUITests \
  -quiet

echo "== macOS app target tests =="
xcodebuild \
  -project Picko.xcodeproj \
  -scheme PickoMac \
  -configuration Debug \
  -derivedDataPath "$mac_derived_data" \
  test \
  -quiet

echo "Phase 5 platform verification passed."
