#!/bin/bash
# TODO/FIXME Warning Generator
# Converts TODO and FIXME comments to Xcode warnings
#
# To add as Build Phase:
# 1. Select project → target "weather" → Build Phases
# 2. + → New Run Script Phase
# 3. Name it "TODO Warnings"
# 4. Paste: "${SRCROOT}/scripts/build-phases/todo-warnings.sh"

set -e

# Only show warnings in Debug
if [ "${CONFIGURATION}" = "Release" ]; then
    exit 0
fi

KEYWORDS="TODO|FIXME|HACK|XXX"
SEARCH_PATH="${SRCROOT}/weather/Sources"

# Find all matches and output as Xcode warnings
find "$SEARCH_PATH" -name "*.swift" -print0 | while IFS= read -r -d '' file; do
    grep -nE "//\s*($KEYWORDS)" "$file" 2>/dev/null | while read -r line; do
        LINE_NUM=$(echo "$line" | cut -d: -f1)
        CONTENT=$(echo "$line" | cut -d: -f2-)
        
        if echo "$CONTENT" | grep -qE "FIXME"; then
            echo "$file:$LINE_NUM: warning: $CONTENT"
        elif echo "$CONTENT" | grep -qE "TODO"; then
            echo "$file:$LINE_NUM: warning: $CONTENT"
        elif echo "$CONTENT" | grep -qE "HACK|XXX"; then
            echo "$file:$LINE_NUM: warning: $CONTENT"
        fi
    done
done

exit 0
