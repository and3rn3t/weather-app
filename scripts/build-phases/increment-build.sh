#!/bin/bash
# Build Number Increment Script
# Automatically increments build number for Release builds
#
# To add as Build Phase:
# 1. Select project → target "weather" → Build Phases
# 2. + → New Run Script Phase
# 3. Name it "Increment Build Number"
# 4. Paste: "${SRCROOT}/scripts/build-phases/increment-build.sh"
# 5. Move it BEFORE "Compile Sources"

set -e

# Only increment for Release/Archive builds
if [ "${CONFIGURATION}" != "Release" ]; then
    echo "Skipping build number increment in ${CONFIGURATION}"
    exit 0
fi

# Get current build number
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [ -f "$PLIST" ]; then
    BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST" 2>/dev/null || echo "1")
else
    # Use Info.plist in source
    PLIST="${SRCROOT}/weather/Info.plist"
    BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST" 2>/dev/null || echo "1")
fi

# Increment
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Update the plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD_NUMBER" "$PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $NEW_BUILD_NUMBER" "$PLIST"

echo "Build number incremented: $BUILD_NUMBER → $NEW_BUILD_NUMBER"
