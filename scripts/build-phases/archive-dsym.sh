#!/bin/bash
# Crash Report Symbolication Prep
# Copies dSYM files for crash report symbolication
#
# To add as Build Phase:
# 1. Select project → target "weather" → Build Phases
# 2. + → New Run Script Phase
# 3. Name it "Archive dSYM"
# 4. Paste: "${SRCROOT}/scripts/build-phases/archive-dsym.sh"
# 5. Check "Run script only when installing" (for Archive builds only)

set -e

# Only run for Archive builds
if [ "${ACTION}" != "install" ]; then
    exit 0
fi

# Create dSYM archive directory
DSYM_ARCHIVE_DIR="${SRCROOT}/build/dSYMs"
mkdir -p "$DSYM_ARCHIVE_DIR"

# Get app version and build
APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}" 2>/dev/null || echo "unknown")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}" 2>/dev/null || echo "unknown")

# Archive the dSYM
DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
if [ -d "$DSYM_PATH" ]; then
    ARCHIVE_NAME="weather-${APP_VERSION}-${BUILD_NUMBER}-$(date +%Y%m%d%H%M%S).dSYM.zip"
    cd "${DWARF_DSYM_FOLDER_PATH}"
    zip -r "${DSYM_ARCHIVE_DIR}/${ARCHIVE_NAME}" "${DWARF_DSYM_FILE_NAME}"
    echo "dSYM archived: ${ARCHIVE_NAME}"
else
    echo "warning: No dSYM found at ${DSYM_PATH}"
fi
