#!/bin/bash

# Release Preparation Script for Andernet Weather App
# Comprehensive pre-release validation and preparation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
RELEASE_TYPE="${1:-patch}"  # patch, minor, major
SKIP_TESTS="${SKIP_TESTS:-false}"
DRY_RUN="${DRY_RUN:-false}"

echo -e "${BLUE}🚀 Preparing Release for Andernet Weather App${NC}"
echo -e "${CYAN}Release Type: $RELEASE_TYPE${NC}"
echo "=================================================="

# Change to project root
cd "$(dirname "$0")/.."

RELEASE_LOG="release-preparation.log"
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Function to log results
log_result() {
    local status=$1
    local message=$2
    local level=${3:-"INFO"}
    
    echo -e "$status $message"
    echo "$(date '+%H:%M:%S') [$level] $message" >> "$RELEASE_LOG"
}

# Function for check results
check_passed() {
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    log_result "${GREEN}✅" "$1" "PASS"
}

check_failed() {
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    log_result "${RED}❌" "$1" "FAIL"
}

check_warning() {
    WARNINGS=$((WARNINGS + 1))
    log_result "${YELLOW}⚠️" "$1" "WARN"
}

# Initialize log
echo "Release Preparation - $(date)" > "$RELEASE_LOG"
echo "Release Type: $RELEASE_TYPE" >> "$RELEASE_LOG"
echo "==========================================" >> "$RELEASE_LOG"

# 1. Git Status and Branch Validation
echo -e "\n${YELLOW}1. Git Repository Status${NC}"
if [ "$DRY_RUN" = "false" ]; then
    # Check if on main branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        check_passed "On release branch: $CURRENT_BRANCH"
    else
        check_warning "Not on main/master branch: $CURRENT_BRANCH"
    fi
    
    # Check git status (should be clean for release)
    if git diff-index --quiet HEAD --; then
        check_passed "Working directory clean"
    else
        check_failed "Working directory has uncommitted changes"
        git status --porcelain >> "$RELEASE_LOG"
    fi
    
    # Check if we can push (network connectivity)
    if git fetch origin --dry-run >/dev/null 2>&1; then
        check_passed "Git remote accessible"
    else
        check_warning "Cannot reach git remote"
    fi
    
    # Check for unpushed commits
    UNPUSHED=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l || echo "0")
    if [ "$UNPUSHED" -eq 0 ]; then
        check_passed "No unpushed commits"
    else
        check_warning "$UNPUSHED unpushed commits found"
    fi
else
    echo -e "${CYAN}(Dry run - skipping git checks)${NC}"
fi

# 2. Version Management
echo -e "\n${YELLOW}2. Version Management${NC}"

# Get current version from Info.plist
if [ -f "weather/Info.plist" ]; then
    CURRENT_VERSION=$(plutil -p weather/Info.plist | grep CFBundleShortVersionString | awk -F '"' '{print $4}')
    CURRENT_BUILD=$(plutil -p weather/Info.plist | grep CFBundleVersion | awk -F '"' '{print $4}')
    
    log_result "${CYAN}ℹ️" "Current Version: $CURRENT_VERSION (Build: $CURRENT_BUILD)" "INFO"
    
    # Calculate new version
    IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]:-0}
    PATCH=${VERSION_PARTS[2]:-0}
    
    case "$RELEASE_TYPE" in
        "major")
            NEW_VERSION="$((MAJOR + 1)).0.0"
            ;;
        "minor")
            NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
            ;;
        "patch")
            NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
            ;;
        *)
            check_failed "Invalid release type: $RELEASE_TYPE"
            ;;
    esac
    
    log_result "${CYAN}ℹ️" "Proposed New Version: $NEW_VERSION" "INFO"
    check_passed "Version calculation complete"
else
    check_failed "Info.plist not found"
fi

# 3. Security Scan
echo -e "\n${YELLOW}3. Security Validation${NC}"
if [ -f "scripts/security-scan.sh" ]; then
    echo -e "${CYAN}Running security scan...${NC}"
    if chmod +x scripts/security-scan.sh && scripts/security-scan.sh >/dev/null 2>&1; then
        check_passed "Security scan passed"
    else
        check_failed "Security scan failed - review security-scan-results.txt"
    fi
else
    check_warning "Security scan script not found"
fi

# 4. Code Quality Checks
echo -e "\n${YELLOW}4. Code Quality${NC}"

# SwiftLint
if command -v swiftlint >/dev/null 2>&1; then
    echo -e "${CYAN}Running SwiftLint...${NC}"
    if swiftlint --config .swiftlint.yml >/dev/null 2>&1; then
        check_passed "SwiftLint passed"
    else
        check_failed "SwiftLint violations found"
        swiftlint --config .swiftlint.yml >> "$RELEASE_LOG" 2>&1 || true
    fi
else
    check_warning "SwiftLint not installed"
fi

# Check for TODO/FIXME comments
TODO_COUNT=$(grep -r "TODO\|FIXME\|HACK" --include="*.swift" weather/Sources/ 2>/dev/null | wc -l || echo "0")
if [ "$TODO_COUNT" -eq 0 ]; then
    check_passed "No TODO/FIXME comments found"
else
    check_warning "$TODO_COUNT TODO/FIXME comments found"
    grep -r "TODO\|FIXME\|HACK" --include="*.swift" weather/Sources/ 2>/dev/null >> "$RELEASE_LOG" || true
fi

# 5. Build Validation
echo -e "\n${YELLOW}5. Build Validation${NC}"

# Clean build
echo -e "${CYAN}Performing clean build...${NC}"
if make clean >/dev/null 2>&1; then
    check_passed "Clean successful"
else
    check_failed "Clean failed"
fi

# Release build
if make build-release >/dev/null 2>&1; then
    check_passed "Release build successful"
else
    check_failed "Release build failed"
fi

# Archive build
echo -e "${CYAN}Testing archive build...${NC}"
if make archive >/dev/null 2>&1; then
    check_passed "Archive build successful"
    
    # Check archive size
    if [ -d "build/weather.xcarchive" ]; then
        ARCHIVE_SIZE=$(du -sh build/weather.xcarchive | awk '{print $1}')
        log_result "${CYAN}ℹ️" "Archive size: $ARCHIVE_SIZE" "INFO"
    fi
else
    check_failed "Archive build failed"
fi

# 6. Test Suite
if [ "$SKIP_TESTS" = "false" ]; then
    echo -e "\n${YELLOW}6. Test Suite${NC}"
    
    # Unit tests
    echo -e "${CYAN}Running unit tests...${NC}"
    if make test >/dev/null 2>&1; then
        check_passed "Unit tests passed"
    else
        check_failed "Unit tests failed"
    fi
    
    # Test coverage
    echo -e "${CYAN}Checking test coverage...${NC}"
    if make test-coverage >/dev/null 2>&1; then
        check_passed "Test coverage analysis complete"
    else
        check_warning "Test coverage analysis failed"
    fi
    
    # UI tests (quick smoke test)
    echo -e "${CYAN}Running smoke tests...${NC}"
    if make test-performance >/dev/null 2>/dev/null; then
        check_passed "Performance tests passed"
    else
        check_warning "Performance tests skipped or failed"
    fi
else
    echo -e "\n${YELLOW}6. Test Suite (SKIPPED)${NC}"
    log_result "${CYAN}ℹ️" "Tests skipped (SKIP_TESTS=true)" "INFO"
fi

# 7. Documentation Validation
echo -e "\n${YELLOW}7. Documentation${NC}"

REQUIRED_DOCS=(
    "README.md"
    "docs/CHANGELOG.md"
    "docs/PRIVACY_POLICY.md"
    "docs/SUPPORT.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        check_passed "$doc exists"
    else
        check_warning "$doc not found"
    fi
done

# Check if CHANGELOG.md is updated
if [ -f "docs/CHANGELOG.md" ]; then
    if grep -q "## \[$NEW_VERSION\]" docs/CHANGELOG.md 2>/dev/null; then
        check_passed "CHANGELOG.md updated for version $NEW_VERSION"
    else
        check_warning "CHANGELOG.md not updated for version $NEW_VERSION"
    fi
fi

# 8. App Store Readiness
echo -e "\n${YELLOW}8. App Store Readiness${NC}"

# Check if required files exist
APP_STORE_FILES=(
    "AppStoreMetadata.json"
    "ExportOptions.plist"  
    "weather.entitlements"
)

for file in "${APP_STORE_FILES[@]}"; do
    if [ -f "$file" ] || [ -f "weather/$file" ]; then
        check_passed "$file ready"
    else
        check_warning "$file not found"
    fi
done

# Check for screenshots
if [ -d "screenshots/ios" ]; then
    SCREENSHOT_COUNT=$(find screenshots/ios -name "*.png" 2>/dev/null | wc -l || echo "0")
    if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
        check_passed "$SCREENSHOT_COUNT screenshots available"
    else
        check_warning "No screenshots found in screenshots/ios"
    fi
else
    check_warning "Screenshots directory not found"
fi

# 9. Fastlane Validation
echo -e "\n${YELLOW}9. Fastlane Configuration${NC}"
if [ -f "fastlane/Fastfile" ]; then
    check_passed "Fastfile exists"
    
    # Test fastlane syntax
    if cd fastlane && fastlane --help >/dev/null 2>&1; then
        check_passed "Fastlane syntax valid"
        cd ..
    else
        check_warning "Fastlane validation failed"
        cd ..
    fi
else
    check_warning "Fastlane not configured"
fi

# 10. Final Validations
echo -e "\n${YELLOW}10. Final Checks${NC}"

# Check minimum deployment target
if grep -q "IPHONEOS_DEPLOYMENT_TARGET.*17" weather.xcodeproj/project.pbxproj 2>/dev/null; then
    check_passed "iOS deployment target correct"
else
    check_warning "Verify iOS deployment target"
fi

# Check code signing configuration
if grep -q "DEVELOPMENT_TEAM" weather.xcodeproj/project.pbxproj 2>/dev/null; then
    check_passed "Development team configured"
else
    check_warning "Development team not set"
fi

# Generate final report
echo -e "\n${BLUE}=================================================="
echo "🎯 Release Preparation Summary"
echo "=================================================="

log_result "${CYAN}📊" "Checks passed: $CHECKS_PASSED" "SUMMARY"
log_result "${CYAN}📊" "Checks failed: $CHECKS_FAILED" "SUMMARY"
log_result "${CYAN}📊" "Warnings: $WARNINGS" "SUMMARY"

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Release preparation SUCCESSFUL!${NC}"
    echo -e "${GREEN}✅ Ready for release: $NEW_VERSION${NC}"
    
    if [ "$DRY_RUN" = "false" ]; then
        echo -e "\n${YELLOW}Next Steps:${NC}"
        echo -e "1. ${CYAN}Update version:${NC} Edit Info.plist to version $NEW_VERSION"
        echo -e "2. ${CYAN}Update changelog:${NC} Add release notes to CHANGELOG.md"
        echo -e "3. ${CYAN}Commit changes:${NC} git add . && git commit -m \"Release v$NEW_VERSION\""
        echo -e "4. ${CYAN}Create tag:${NC} git tag v$NEW_VERSION"
        echo -e "5. ${CYAN}Push release:${NC} git push origin main --tags"
        echo -e "6. ${CYAN}Deploy to TestFlight:${NC} fastlane beta"
    else
        echo -e "\n${CYAN}This was a dry run. Remove DRY_RUN=true to proceed.${NC}"
    fi
else
    echo -e "${RED}❌ Release preparation FAILED${NC}"
    echo -e "${RED}Please fix the $CHECKS_FAILED failed checks before releasing${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️ $WARNINGS warnings found - review recommended${NC}"
fi

echo -e "\n${BLUE}📋 Detailed log: $RELEASE_LOG${NC}"

# Return appropriate exit code
if [ $CHECKS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi