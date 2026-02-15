#!/bin/bash

# Weather App Shell Integration
# Advanced shell functions and completions for development workflow

# Colors for output
export WEATHER_APP_RED='\033[0;31m'
export WEATHER_APP_GREEN='\033[0;32m'
export WEATHER_APP_YELLOW='\033[1;33m'
export WEATHER_APP_BLUE='\033[0;34m'
export WEATHER_APP_CYAN='\033[0;36m'
export WEATHER_APP_BOLD='\033[1m'
export WEATHER_APP_NC='\033[0m' # No Color

# Project path detection
weather_detect_project() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/weather.xcodeproj/project.pbxproj" ]] || [[ -f "$dir/weather/weather.xcodeproj/project.pbxproj" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Get project root
weather_project_root() {
    local root
    root=$(weather_detect_project)
    if [[ $? -eq 0 ]]; then
        echo "$root"
    else
        echo -e "${WEATHER_APP_RED}❌ Not in Weather App project directory${WEATHER_APP_NC}" >&2
        return 1
    fi
}

# Enhanced build function with better feedback
wbuild() {
    local project_root
    project_root=$(weather_project_root) || return 1
    
    echo -e "${WEATHER_APP_BLUE}🔨 Building Weather App...${WEATHER_APP_NC}"
    cd "$project_root" || return 1
    
    if [[ -f "weather/Makefile" ]]; then
        cd weather
    fi
    
    # Check if we have xcbeautify for better output
    if command -v xcbeautify >/dev/null 2>&1; then
        make build
    else
        echo -e "${WEATHER_APP_YELLOW}💡 Install xcbeautify for better build output: brew install xcbeautify${WEATHER_APP_NC}"
        make build
    fi
}

# Enhanced test function with options
wtest() {
    local test_type="${1:-unit}"
    local project_root
    project_root=$(weather_project_root) || return 1
    
    cd "$project_root" || return 1
    if [[ -f "weather/Makefile" ]]; then
        cd weather
    fi
    
    case "$test_type" in
        "unit"|"u")
            echo -e "${WEATHER_APP_BLUE}🧪 Running unit tests...${WEATHER_APP_NC}"
            make test
            ;;
        "coverage"|"cov"|"c")
            echo -e "${WEATHER_APP_BLUE}📊 Running tests with coverage...${WEATHER_APP_NC}"
            make test-coverage
            ;;
        "performance"|"perf"|"p")
            echo -e "${WEATHER_APP_BLUE}⚡ Running performance tests...${WEATHER_APP_NC}"
            make test-performance
            ;;
        "all"|"a")
            echo -e "${WEATHER_APP_BLUE}🎯 Running all tests...${WEATHER_APP_NC}"
            make test && make test-coverage
            ;;
        *)
            echo -e "${WEATHER_APP_YELLOW}Usage: wtest [unit|coverage|performance|all]${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  unit (default) - Run unit tests${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  coverage/cov/c - Run with coverage${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  performance/perf/p - Performance tests${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  all/a - Run all test types${WEATHER_APP_NC}"
            ;;
    esac
}

# Enhanced lint function with fix option
wlint() {
    local action="${1:-check}"
    local project_root
    project_root=$(weather_project_root) || return 1
    
    cd "$project_root" || return 1
    if [[ -f "weather/Makefile" ]]; then
        cd weather
    fi
    
    case "$action" in
        "check"|"c"|"")
            echo -e "${WEATHER_APP_BLUE}🔍 Checking code style...${WEATHER_APP_NC}"
            make lint
            ;;
        "fix"|"f")
            echo -e "${WEATHER_APP_BLUE}🔧 Fixing code style...${WEATHER_APP_NC}"
            if command -v swiftlint >/dev/null 2>&1; then
                swiftlint --fix --config .swiftlint.yml
                echo -e "${WEATHER_APP_GREEN}✅ Code style fixes applied${WEATHER_APP_NC}"
            else
                echo -e "${WEATHER_APP_RED}❌ SwiftLint not installed${WEATHER_APP_NC}"
            fi
            ;;
        "format"|"fmt")
            echo -e "${WEATHER_APP_BLUE}📐 Formatting code...${WEATHER_APP_NC}"
            make format
            ;;
        *)
            echo -e "${WEATHER_APP_YELLOW}Usage: wlint [check|fix|format]${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  check (default) - Check code style${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  fix - Auto-fix issues${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  format - Format code${WEATHER_APP_NC}"
            ;;
    esac
}

# Quick simulator launcher with device selection
wsim() {
    local device="${1:-iPhone 15 Pro}"
    
    echo -e "${WEATHER_APP_BLUE}📱 Launching iOS Simulator: $device${WEATHER_APP_NC}"
    
    # Try to boot specific device
    if xcrun simctl list devices | grep -q "$device"; then
        xcrun simctl boot "$device" 2>/dev/null || true
    fi
    
    # Open Simulator app
    open -a Simulator
    
    # Show available devices for future reference
    if [[ "${2}" == "--list" ]] || [[ "${1}" == "--list" ]]; then
        echo -e "\n${WEATHER_APP_CYAN}Available devices:${WEATHER_APP_NC}"
        xcrun simctl list devices available | grep -E "iPhone|iPad" | grep -v "unavailable" | head -10
    fi
}

# Development workflow functions
wdev() {
    local action="${1}"
    local project_root
    project_root=$(weather_project_root) || return 1
    
    case "$action" in
        "start"|"s")
            echo -e "${WEATHER_APP_BLUE}🚀 Starting development session...${WEATHER_APP_NC}"
            wclean && wbuild && wsim &
            echo -e "${WEATHER_APP_GREEN}✅ Development environment ready!${WEATHER_APP_NC}"
            ;;
        "status"|"st")
            wstatus
            ;;
        "clean"|"c")
            wclean
            ;;
        "reset"|"r")
            echo -e "${WEATHER_APP_YELLOW}🔄 Resetting development environment...${WEATHER_APP_NC}"
            cd "$project_root" || return 1
            if [[ -f "weather/Makefile" ]]; then cd weather; fi
            make clean
            rm -rf ~/Library/Developer/Xcode/DerivedData/weather-*
            echo -e "${WEATHER_APP_GREEN}✅ Environment reset complete${WEATHER_APP_NC}"
            ;;
        "deps"|"d")
            echo -e "${WEATHER_APP_BLUE}📦 Checking dependencies...${WEATHER_APP_NC}"
            cd "$project_root" || return 1
            if [[ -f "weather/Makefile" ]]; then cd weather; fi
            make update-deps
            ;;
        *)
            echo -e "${WEATHER_APP_YELLOW}Usage: wdev [start|status|clean|reset|deps]${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  start/s - Clean, build, and launch simulator${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  status/st - Show project status${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  clean/c - Clean build artifacts${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  reset/r - Full environment reset${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  deps/d - Check dependencies${WEATHER_APP_NC}"
            ;;
    esac
}

# Project status function
wstatus() {
    local project_root
    project_root=$(weather_project_root) || return 1
    
    echo -e "${WEATHER_APP_BOLD}📊 Weather App Status${WEATHER_APP_NC}"
    echo "================================="
    
    cd "$project_root" || return 1
    
    # Git status
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch
        branch=$(git rev-parse --abbrev-ref HEAD)
        local status
        if git diff-index --quiet HEAD --; then
            status="${WEATHER_APP_GREEN}Clean${WEATHER_APP_NC}"
        else
            status="${WEATHER_APP_YELLOW}Modified files${WEATHER_APP_NC}"
        fi
        echo -e "${WEATHER_APP_CYAN}Git Branch:${WEATHER_APP_NC} $branch ($status)"
        
        # Show unpushed commits
        local unpushed
        unpushed=$(git log origin/"$branch"..HEAD --oneline 2>/dev/null | wc -l || echo "0")
        if [[ "$unpushed" -gt 0 ]]; then
            echo -e "${WEATHER_APP_YELLOW}Unpushed commits:${WEATHER_APP_NC} $unpushed"
        fi
    fi
    
    # Project info
    if [[ -f "weather/Info.plist" ]]; then
        local version
        version=$(plutil -p weather/Info.plist 2>/dev/null | grep CFBundleShortVersionString | awk -F '"' '{print $4}' || echo "Unknown")
        echo -e "${WEATHER_APP_CYAN}App Version:${WEATHER_APP_NC} $version"
    fi
    
    # Build tools status
    echo -e "\n${WEATHER_APP_CYAN}Build Tools:${WEATHER_APP_NC}"
    
    local tools=("swiftlint" "swift-format" "xcbeautify")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo -e "  ✅ $tool"
        else
            echo -e "  ❌ $tool (not installed)"
        fi
    done
    
    # Simulators
    local sim_count
    sim_count=$(xcrun simctl list devices available | grep -c "iPhone\|iPad" || echo "0")
    echo -e "${WEATHER_APP_CYAN}Available Simulators:${WEATHER_APP_NC} $sim_count"
}

# Clean function
wclean() {
    local project_root
    project_root=$(weather_project_root) || return 1
    
    echo -e "${WEATHER_APP_BLUE}🧹 Cleaning Weather App...${WEATHER_APP_NC}"
    cd "$project_root" || return 1
    if [[ -f "weather/Makefile" ]]; then
        cd weather
    fi
    make clean
}

# Quick archive function
warchive() {
    local project_root
    project_root=$(weather_project_root) || return 1
    
    echo -e "${WEATHER_APP_BLUE}📦 Creating archive...${WEATHER_APP_NC}"
    cd "$project_root" || return 1
    if [[ -f "weather/Makefile" ]]; then
        cd weather
    fi
    make archive
    
    if [[ -d "build/weather.xcarchive" ]]; then
        local size
        size=$(du -sh build/weather.xcarchive | awk '{print $1}')
        echo -e "${WEATHER_APP_GREEN}✅ Archive created: $size${WEATHER_APP_NC}"
    fi
}

# Navigate to project directories
wcd() {
    local target="${1:-root}"
    local project_root
    project_root=$(weather_project_root) || return 1
    
    case "$target" in
        "root"|"r"|"")
            cd "$project_root"
            ;;
        "sources"|"src"|"s")
            cd "$project_root/weather/Sources" || cd "$project_root/weather/weather/Sources"
            ;;
        "tests"|"test"|"t")
            cd "$project_root/weatherTests" || cd "$project_root/weather/weatherTests"
            ;;
        "docs"|"doc"|"d")
            cd "$project_root/docs"
            ;;
        "scripts"|"sc")
            cd "$project_root/scripts" || cd "$project_root/weather/scripts"
            ;;
        "build"|"b")
            cd "$project_root/build" || cd "$project_root/weather/build"
            ;;
        *)
            echo -e "${WEATHER_APP_YELLOW}Usage: wcd [root|sources|tests|docs|scripts|build]${WEATHER_APP_NC}"
            ;;
    esac
    
    pwd
}

# Release management functions
wrelease() {
    local action="${1:-status}"
    local project_root
    project_root=$(weather_project_root) || return 1
    
    cd "$project_root" || return 1
    if [[ -f "weather/Makefile" ]]; then
        cd weather
    fi
    
    case "$action" in
        "prepare"|"prep"|"p")
            local type="${2:-patch}"
            echo -e "${WEATHER_APP_BLUE}🚀 Preparing $type release...${WEATHER_APP_NC}"
            make "prepare-release-$type" 2>/dev/null || make prepare-release
            ;;
        "notes"|"n")
            echo -e "${WEATHER_APP_BLUE}📝 Generating release notes...${WEATHER_APP_NC}"
            make release-notes
            ;;
        "security"|"sec"|"s")
            echo -e "${WEATHER_APP_BLUE}🔒 Running security scan...${WEATHER_APP_NC}"
            make security-scan
            ;;
        "quality"|"qual"|"q")
            echo -e "${WEATHER_APP_BLUE}✨ Running quality checks...${WEATHER_APP_NC}"
            make quality-gate
            ;;
        *)
            echo -e "${WEATHER_APP_YELLOW}Usage: wrelease [prepare|notes|security|quality]${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  prepare/prep/p [patch|minor|major] - Prepare release${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  notes/n - Generate release notes${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  security/sec/s - Security scan${WEATHER_APP_NC}"
            echo -e "${WEATHER_APP_CYAN}  quality/qual/q - Quality gate${WEATHER_APP_NC}"
            ;;
    esac
}

# Help function
whelp() {
    echo -e "${WEATHER_APP_BOLD}🌤️ Weather App Shell Functions${WEATHER_APP_NC}"
    echo "=================================="
    echo ""
    echo -e "${WEATHER_APP_CYAN}Core Development:${WEATHER_APP_NC}"
    echo -e "  ${WEATHER_APP_YELLOW}wbuild${WEATHER_APP_NC}              - Build the app"
    echo -e "  ${WEATHER_APP_YELLOW}wtest [type]${WEATHER_APP_NC}        - Run tests (unit/coverage/perf/all)"
    echo -e "  ${WEATHER_APP_YELLOW}wlint [action]${WEATHER_APP_NC}      - Code linting (check/fix/format)"
    echo -e "  ${WEATHER_APP_YELLOW}wclean${WEATHER_APP_NC}              - Clean build artifacts"
    echo -e "  ${WEATHER_APP_YELLOW}wsim [device]${WEATHER_APP_NC}       - Launch simulator"
    echo ""
    echo -e "${WEATHER_APP_CYAN}Workflow:${WEATHER_APP_NC}"
    echo -e "  ${WEATHER_APP_YELLOW}wdev [action]${WEATHER_APP_NC}       - Development workflow (start/status/clean/reset/deps)"
    echo -e "  ${WEATHER_APP_YELLOW}wstatus${WEATHER_APP_NC}             - Show project status"
    echo -e "  ${WEATHER_APP_YELLOW}wcd [target]${WEATHER_APP_NC}        - Navigate project (root/sources/tests/docs/scripts)"
    echo ""
    echo -e "${WEATHER_APP_CYAN}Release:${WEATHER_APP_NC}"
    echo -e "  ${WEATHER_APP_YELLOW}wrelease [action]${WEATHER_APP_NC}    - Release management (prepare/notes/security/quality)"
    echo -e "  ${WEATHER_APP_YELLOW}warchive${WEATHER_APP_NC}            - Create release archive"
    echo ""
    echo -e "${WEATHER_APP_CYAN}Quick Commands:${WEATHER_APP_NC}"
    echo -e "  ${WEATHER_APP_YELLOW}whelp${WEATHER_APP_NC}               - Show this help"
    echo -e "  ${WEATHER_APP_YELLOW}make help${WEATHER_APP_NC}           - Show all make targets"
    echo ""
    echo -e "${WEATHER_APP_CYAN}Examples:${WEATHER_APP_NC}"
    echo -e "  ${WEATHER_APP_GREEN}wdev start${WEATHER_APP_NC}          - Start development session"
    echo -e "  ${WEATHER_APP_GREEN}wtest coverage${WEATHER_APP_NC}      - Run tests with coverage"
    echo -e "  ${WEATHER_APP_GREEN}wrelease prepare minor${WEATHER_APP_NC} - Prepare minor release"
}

# Bash/Zsh completion for weather functions
if [[ -n "${BASH_VERSION:-}" ]]; then
    # Bash completion
    complete -W "unit coverage performance all" wtest
    complete -W "check fix format" wlint
    complete -W "start status clean reset deps" wdev
    complete -W "root sources tests docs scripts build" wcd
    complete -W "prepare notes security quality" wrelease
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    # Zsh completion
    compdef '_arguments "1:test type:(unit coverage performance all)"' wtest
    compdef '_arguments "1:lint action:(check fix format)"' wlint
    compdef '_arguments "1:dev action:(start status clean reset deps)"' wdev
    compdef '_arguments "1:directory:(root sources tests docs scripts build)"' wcd
    compdef '_arguments "1:release action:(prepare notes security quality)"' wrelease
fi

# Project-aware prompt enhancement (optional)
weather_prompt_info() {
    if weather_project_root >/dev/null 2>&1; then
        local branch=""
        if git rev-parse --git-dir > /dev/null 2>&1; then
            branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            if git diff-index --quiet HEAD -- 2>/dev/null; then
                echo " ☀️[$branch]"
            else
                echo " 🌤️[$branch*]"
            fi
        else
            echo " ☀️"
        fi
    fi
}

# Auto-completion for make targets (if make is available)
if command -v make >/dev/null 2>&1; then
    _weather_make_completion() {
        local project_root
        project_root=$(weather_project_root 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            local makefile="$project_root/Makefile"
            [[ -f "$project_root/weather/Makefile" ]] && makefile="$project_root/weather/Makefile"
            
            if [[ -f "$makefile" ]]; then
                grep "^[a-zA-Z][a-zA-Z0-9_-]*:" "$makefile" | cut -d':' -f1 | sort -u
            fi
        fi
    }
    
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        compdef '_weather_make_completion' make
    fi
fi

echo -e "${WEATHER_APP_GREEN}✅ Weather App shell integration loaded${WEATHER_APP_NC}"
echo -e "${WEATHER_APP_CYAN}💡 Type ${WEATHER_APP_YELLOW}whelp${WEATHER_APP_CYAN} for available commands${WEATHER_APP_NC}"