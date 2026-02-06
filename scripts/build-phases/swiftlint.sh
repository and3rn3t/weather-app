#!/bin/bash
# SwiftLint Build Phase Script
# Add this as a Run Script Build Phase in Xcode
#
# To add:
# 1. Select project in Xcode
# 2. Select target "weather"
# 3. Build Phases tab
# 4. + → New Run Script Phase
# 5. Paste this script or reference it: "${SRCROOT}/scripts/build-phases/swiftlint.sh"

set -e

# Only run in Debug to speed up Release builds
if [ "${CONFIGURATION}" = "Release" ]; then
    echo "Skipping SwiftLint in Release build"
    exit 0
fi

if which swiftlint > /dev/null; then
    cd "${SRCROOT}"
    swiftlint --config .swiftlint.yml --fix --format
    swiftlint --config .swiftlint.yml
else
    echo "warning: SwiftLint not installed. Install with: brew install swiftlint"
fi
