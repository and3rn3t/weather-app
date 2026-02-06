#!/bin/bash
# Memory Diagnostics Script for Xcode
# Helps identify memory issues, leaks, and zombies

set -e

SCHEME="weather"
PROJECT="weather.xcodeproj"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Memory Diagnostics - Andernet Weather${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if Instruments is available
if ! command -v xcrun instruments &> /dev/null && ! command -v xctrace &> /dev/null; then
    echo -e "${RED}Error: Instruments not available. Please install Xcode Command Line Tools.${NC}"
    exit 1
fi

usage() {
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  leaks       Run with Leaks instrument (detects memory leaks)"
    echo "  allocations Run with Allocations instrument (track memory usage)"
    echo "  zombies     Run with Zombie Objects enabled"
    echo "  memgraph    Export memory graph for analysis"
    echo "  all         Run all memory diagnostics"
    echo ""
    echo "Examples:"
    echo "  $0 leaks          # Check for memory leaks"
    echo "  $0 allocations    # Profile memory allocations"
    echo "  $0 zombies        # Detect zombie objects"
    echo "  $0 memgraph       # Export memory graph"
    exit 1
}

build_app() {
    echo -e "${YELLOW}Building app for diagnostics...${NC}"
    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -configuration Debug \
        ONLY_ACTIVE_ARCH=YES \
        GCC_PREPROCESSOR_DEFINITIONS='DEBUG=1' \
        -quiet
    echo -e "${GREEN}✓ Build completed${NC}"
}

run_leaks() {
    echo -e "${YELLOW}Running Leaks analysis...${NC}"
    echo -e "This will profile the app for memory leaks."
    echo ""
    
    # Create output directory
    mkdir -p build/diagnostics
    
    # Get the app path
    APP_PATH=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings | grep "^    BUILT_PRODUCTS_DIR" | cut -d'=' -f2 | xargs)
    
    echo "App location: $APP_PATH/weather.app"
    echo ""
    echo -e "${YELLOW}Starting Instruments with Leaks template...${NC}"
    echo "Please interact with the app in the simulator for 30-60 seconds."
    echo "Press Ctrl+C when done to see the report."
    echo ""
    
    # Use xctrace for modern Xcode
    xctrace record \
        --template "Leaks" \
        --device "$DESTINATION" \
        --output "build/diagnostics/leaks-$(date +%Y%m%d-%H%M%S).trace" \
        --launch "$APP_PATH/weather.app" || true
        
    echo ""
    echo -e "${GREEN}✓ Leaks trace saved to build/diagnostics/${NC}"
    echo "Open the .trace file in Instruments to analyze results."
}

run_allocations() {
    echo -e "${YELLOW}Running Allocations analysis...${NC}"
    
    mkdir -p build/diagnostics
    
    APP_PATH=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings | grep "^    BUILT_PRODUCTS_DIR" | cut -d'=' -f2 | xargs)
    
    echo "Starting Instruments with Allocations template..."
    echo "This will track all memory allocations during app usage."
    echo ""
    
    xctrace record \
        --template "Allocations" \
        --device "$DESTINATION" \
        --output "build/diagnostics/allocations-$(date +%Y%m%d-%H%M%S).trace" \
        --launch "$APP_PATH/weather.app" || true
        
    echo ""
    echo -e "${GREEN}✓ Allocations trace saved to build/diagnostics/${NC}"
}

run_zombies() {
    echo -e "${YELLOW}Building with Zombie Objects enabled...${NC}"
    
    # Build with zombies enabled
    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -configuration Debug \
        ONLY_ACTIVE_ARCH=YES \
        GCC_PREPROCESSOR_DEFINITIONS='DEBUG=1 NSZombieEnabled=1' \
        OTHER_CFLAGS='-D NSZombieEnabled=YES' \
        -quiet
    
    echo ""
    echo -e "${GREEN}✓ App built with Zombie Objects enabled${NC}"
    echo ""
    echo "Run the app in Xcode with these environment variables:"
    echo "  - NSZombieEnabled = YES"
    echo "  - MallocScribble = YES"
    echo "  - MallocGuardEdges = YES"
    echo ""
    echo "Or run: make test with MallocStackLogging=1"
}

export_memgraph() {
    echo -e "${YELLOW}Exporting memory graph...${NC}"
    
    mkdir -p build/diagnostics
    
    # Check if simulator is running
    SIMULATOR_PID=$(pgrep -f "weather.app" || echo "")
    
    if [ -z "$SIMULATOR_PID" ]; then
        echo -e "${YELLOW}No running app found. Building and launching...${NC}"
        build_app
        
        # Launch the app in simulator
        xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
        APP_PATH=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings | grep "^    BUILT_PRODUCTS_DIR" | cut -d'=' -f2 | xargs)
        xcrun simctl install "iPhone 16 Pro" "$APP_PATH/weather.app"
        xcrun simctl launch "iPhone 16 Pro" dev.andernet.weather
        
        echo "Waiting for app to start..."
        sleep 5
    fi
    
    # Export memory graph
    MEMGRAPH_FILE="build/diagnostics/memgraph-$(date +%Y%m%d-%H%M%S).memgraph"
    
    echo "Exporting memory graph to: $MEMGRAPH_FILE"
    leaks --outputGraph="$MEMGRAPH_FILE" "weather" 2>/dev/null || echo "Note: Run from Xcode Debug menu for best results"
    
    echo ""
    echo -e "${GREEN}✓ Memory graph export attempted${NC}"
    echo "For best results, use Xcode's Debug → Capture Memory Graph while app is running."
}

run_all() {
    echo "Running all memory diagnostics..."
    echo ""
    build_app
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo "To run comprehensive memory analysis:"
    echo ""
    echo "1. Open Xcode and run the 'weather (Debug with Sanitizers)' scheme"
    echo "2. Use Debug → Capture Memory Graph to see object references"
    echo "3. Run Product → Profile → Leaks to find memory leaks"
    echo "4. Run Product → Profile → Allocations to track memory growth"
    echo ""
    echo "Quick commands:"
    echo "  $0 leaks       - Profile for leaks"
    echo "  $0 allocations - Track memory allocations"
    echo "  $0 zombies     - Build with zombie detection"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
}

case "${1:-}" in
    leaks)
        build_app
        run_leaks
        ;;
    allocations)
        build_app
        run_allocations
        ;;
    zombies)
        run_zombies
        ;;
    memgraph)
        export_memgraph
        ;;
    all)
        run_all
        ;;
    *)
        usage
        ;;
esac
