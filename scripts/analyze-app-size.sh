#!/bin/bash
# Andernet Weather - App Size Analyzer
# Analyzes the app bundle to identify size contributors
#
# Usage: ./scripts/analyze-app-size.sh

set -e

PROJECT="weather.xcodeproj"
SCHEME="weather"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/weather.xcarchive"

echo "📦 Andernet Weather - App Size Analysis"
echo "========================================"
echo ""

# Build archive
echo "🏗️  Creating Release archive..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

APP_PATH="$ARCHIVE_PATH/Products/Applications/weather.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App bundle not found at $APP_PATH"
    exit 1
fi

echo ""
echo "📊 App Bundle Analysis"
echo "======================"

# Total size
TOTAL_SIZE=$(du -sh "$APP_PATH" | awk '{print $1}')
echo "Total App Size: $TOTAL_SIZE"
echo ""

# Breakdown by component
echo "Size Breakdown:"
echo "---------------"

# Executable
if [ -f "$APP_PATH/weather" ]; then
    EXE_SIZE=$(du -sh "$APP_PATH/weather" | awk '{print $1}')
    echo "  Executable:        $EXE_SIZE"
fi

# Assets
if [ -d "$APP_PATH/Assets.car" ]; then
    ASSETS_SIZE=$(du -sh "$APP_PATH/Assets.car" | awk '{print $1}')
    echo "  Assets (compiled): $ASSETS_SIZE"
fi

# Frameworks
if [ -d "$APP_PATH/Frameworks" ]; then
    FRAMEWORKS_SIZE=$(du -sh "$APP_PATH/Frameworks" | awk '{print $1}')
    echo "  Frameworks:        $FRAMEWORKS_SIZE"
fi

# Extensions
if [ -d "$APP_PATH/PlugIns" ]; then
    PLUGINS_SIZE=$(du -sh "$APP_PATH/PlugIns" | awk '{print $1}')
    echo "  Extensions:        $PLUGINS_SIZE"
    
    echo ""
    echo "  Extension Details:"
    for ext in "$APP_PATH/PlugIns"/*; do
        if [ -d "$ext" ]; then
            EXT_NAME=$(basename "$ext")
            EXT_SIZE=$(du -sh "$ext" | awk '{print $1}')
            echo "    - $EXT_NAME: $EXT_SIZE"
        fi
    done
fi

# Other files
echo ""
echo "Other Files:"
for file in "$APP_PATH"/*; do
    if [ -f "$file" ]; then
        FILE_NAME=$(basename "$file")
        FILE_SIZE=$(du -sh "$file" | awk '{print $1}')
        echo "    $FILE_NAME: $FILE_SIZE"
    fi
done

echo ""
echo "🔍 Detailed Executable Analysis"
echo "================================"

# Check architecture
if [ -f "$APP_PATH/weather" ]; then
    echo "Architectures:"
    xcrun lipo -info "$APP_PATH/weather" 2>/dev/null || echo "  Unable to determine"
    
    echo ""
    echo "Linked Frameworks:"
    xcrun otool -L "$APP_PATH/weather" 2>/dev/null | head -20 || echo "  Unable to determine"
fi

echo ""
echo "💡 Size Optimization Tips:"
echo "=========================="
echo "  1. Enable 'Strip Swift Symbols' in build settings"
echo "  2. Use 'Thin for All Variants' in export options"
echo "  3. Optimize asset catalogs (use PDF for vector icons)"
echo "  4. Remove unused code with Dead Code Stripping"
echo "  5. Consider on-demand resources for large assets"
echo ""

# Cleanup
echo "🧹 Cleaning up..."
rm -rf "$BUILD_DIR"

echo "✅ Analysis complete!"
