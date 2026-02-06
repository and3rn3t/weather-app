#!/bin/bash
# Andernet Weather - Build Time Analyzer
# Analyzes compilation times to identify slow-building files
#
# Usage: ./scripts/analyze-build-times.sh

set -e

PROJECT="weather.xcodeproj"
SCHEME="weather"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"

echo "🔍 Analyzing build times for $SCHEME..."
echo "This may take a few minutes..."
echo ""

# Clean first
echo "🧹 Cleaning build folder..."
xcodebuild clean -project "$PROJECT" -scheme "$SCHEME" -quiet

# Build with timing information
echo "🏗️  Building with timing analysis..."
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Debug \
    OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" \
    2>&1 | tee /tmp/build-timing.log

# Extract and sort compilation times
echo ""
echo "📊 Top 20 Slowest Functions/Methods:"
echo "======================================"
grep -E "^\s*[0-9]+\.[0-9]+ms" /tmp/build-timing.log | \
    sort -rn | \
    head -20 | \
    awk '{printf "%8s ms  %s\n", $1, substr($0, index($0,$2))}'

# Per-file analysis
echo ""
echo "📁 Compilation Time by File:"
echo "=============================="

# Build again with per-file timing
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Debug \
    OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-compilation" \
    2>&1 | grep -E "^\s*[0-9]+\.[0-9]+ms" | sort -rn | head -10

echo ""
echo "✅ Analysis complete!"
echo ""
echo "💡 Tips to reduce build times:"
echo "  1. Break down large files (>500 lines)"
echo "  2. Avoid complex type inference - add explicit types"
echo "  3. Reduce use of + for string concatenation"
echo "  4. Consider using @inlinable for hot paths"
echo "  5. Use incremental builds (don't clean frequently)"
