#!/bin/bash

# Dependency Update Script for Andernet Weather App
# Safely updates all project dependencies with validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

UPDATE_TYPE="${1:-check}"  # check, minor, major, all
FORCE_UPDATE="${FORCE_UPDATE:-false}"
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"

echo -e "${BLUE}📦 Dependency Update Manager for Andernet Weather App${NC}"
echo -e "${CYAN}Update Type: $UPDATE_TYPE${NC}"
echo "============================================================="

# Change to project root
cd "$(dirname "$0")/.."

UPDATE_LOG="dependency-update.log"
BACKUP_DIR="backups/dependencies-$(date +%s)"

# Function to log results
log_step() {
    local message=$1
    echo -e "${CYAN}→ $message${NC}"
    echo "$(date): $message" >> "$UPDATE_LOG"
}

log_result() {
    local status=$1
    local message=$2
    echo -e "$status $message"
    echo "$(date): $message" >> "$UPDATE_LOG"
}

# Function to create backup
create_backup() {
    if [ "$BACKUP_ENABLED" = "true" ]; then
        log_step "Creating backup of current state"
        mkdir -p "$BACKUP_DIR"
        
        # Backup package files
        [ -f "weather.xcodeproj/project.pbxproj" ] && cp "weather.xcodeproj/project.pbxproj" "$BACKUP_DIR/"
        [ -f "Podfile" ] && cp "Podfile" "$BACKUP_DIR/"
        [ -f "Podfile.lock" ] && cp "Podfile.lock" "$BACKUP_DIR/"
        [ -f "Package.swift" ] && cp "Package.swift" "$BACKUP_DIR/"
        [ -f "Package.resolved" ] && cp "Package.resolved" "$BACKUP_DIR/"
        
        log_result "${GREEN}✅" "Backup created at: $BACKUP_DIR"
    fi
}

# Function to restore backup
restore_backup() {
    if [ "$BACKUP_ENABLED" = "true" ] && [ -d "$BACKUP_DIR" ]; then
        log_step "Restoring from backup due to failure"
        
        [ -f "$BACKUP_DIR/project.pbxproj" ] && cp "$BACKUP_DIR/project.pbxproj" "weather.xcodeproj/"
        [ -f "$BACKUP_DIR/Podfile" ] && cp "$BACKUP_DIR/Podfile" "."
        [ -f "$BACKUP_DIR/Podfile.lock" ] && cp "$BACKUP_DIR/Podfile.lock" "."
        [ -f "$BACKUP_DIR/Package.swift" ] && cp "$BACKUP_DIR/Package.swift" "."
        [ -f "$BACKUP_DIR/Package.resolved" ] && cp "$BACKUP_DIR/Package.resolved" "."
        
        log_result "${GREEN}✅" "Restored from backup"
    fi
}

# Function to test build after updates
test_build() {
    log_step "Testing build after dependency updates"
    
    if make clean >/dev/null 2>&1 && make build >/dev/null 2>&1; then
        log_result "${GREEN}✅" "Build test passed"
        return 0
    else
        log_result "${RED}❌" "Build test failed"
        return 1
    fi
}

# Function to run tests after updates
test_suite() {
    log_step "Running test suite after dependency updates"
    
    if make test >/dev/null 2>&1; then
        log_result "${GREEN}✅" "Test suite passed"
        return 0
    else
        log_result "${RED}❌" "Test suite failed"
        return 1
    fi
}

# Initialize log
echo "Dependency Update - $(date)" > "$UPDATE_LOG"
echo "Update Type: $UPDATE_TYPE" >> "$UPDATE_LOG"
echo "===============================" >> "$UPDATE_LOG"

# Show current status
echo -e "\n${YELLOW}Current Dependency Status${NC}"

# 1. Check for Swift Package Manager
echo -e "\n${YELLOW}1. Swift Package Manager${NC}"
if [ -f "Package.swift" ]; then
    log_result "${CYAN}ℹ️" "Package.swift found"
    
    if [ -f "Package.resolved" ]; then
        log_step "Current package versions:"
        if command -v jq >/dev/null 2>&1; then
            jq -r '.pins[] | "\(.identity): \(.state.version // .state.revision[0:8])"' Package.resolved 2>/dev/null >> "$UPDATE_LOG" || true
        else
            cat Package.resolved >> "$UPDATE_LOG"
        fi
    fi
    
    HAS_SPM=true
else
    log_result "${CYAN}ℹ️" "No Package.swift found"
    HAS_SPM=false
fi

# 2. Check for CocoaPods
echo -e "\n${YELLOW}2. CocoaPods${NC}"
if [ -f "Podfile" ]; then
    log_result "${CYAN}ℹ️" "Podfile found"
    
    if [ -f "Podfile.lock" ]; then
        log_step "Current pod versions:"
        grep -A 1000 "PODS:" Podfile.lock | grep -E "^\s*-" | head -20 >> "$UPDATE_LOG" || true
    fi
    
    HAS_COCOAPODS=true
else
    log_result "${CYAN}ℹ️" "No Podfile found"
    HAS_COCOAPODS=false
fi

# 3. Check for Homebrew dependencies (build tools)
echo -e "\n${YELLOW}3. Build Tools${NC}"

BUILD_TOOLS=("swiftlint" "swift-format" "xcbeautify")
OUTDATED_TOOLS=()

for tool in "${BUILD_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        if brew list "$tool" >/dev/null 2>&1 && brew outdated "$tool" >/dev/null 2>&1; then
            OUTDATED_TOOLS+=("$tool")
            log_result "${YELLOW}⚠️" "$tool is outdated"
        else
            log_result "${GREEN}✅" "$tool is up to date"
        fi
    else
        log_result "${CYAN}ℹ️" "$tool not installed via Homebrew"
    fi
done

# 4. Perform updates based on type
case "$UPDATE_TYPE" in
    "check")
        echo -e "\n${BLUE}📋 Dependency Check Complete${NC}"
        echo -e "${CYAN}Use 'minor', 'major', or 'all' to perform updates${NC}"
        ;;
        
    "tools")
        echo -e "\n${YELLOW}Updating Build Tools${NC}"
        create_backup
        
        for tool in "${OUTDATED_TOOLS[@]}"; do
            log_step "Updating $tool"
            if brew upgrade "$tool"; then
                log_result "${GREEN}✅" "$tool updated successfully"
            else
                log_result "${RED}❌" "Failed to update $tool"
            fi
        done
        ;;
        
    "minor"|"patch")
        echo -e "\n${YELLOW}Performing Minor/Patch Updates${NC}"
        create_backup
        
        # Swift Package Manager minor updates
        if [ "$HAS_SPM" = "true" ]; then
            log_step "Updating Swift packages (minor versions)"
            if swift package update >/dev/null 2>&1; then
                log_result "${GREEN}✅" "Swift packages updated"
            else
                log_result "${RED}❌" "Swift package update failed"
            fi
        fi
        
        # CocoaPods minor updates
        if [ "$HAS_COCOAPODS" = "true" ]; then
            log_step "Updating CocoaPods (minor versions)"
            if pod update --no-repo-update >/dev/null 2>&1; then
                log_result "${GREEN}✅" "CocoaPods updated"
            else
                log_result "${RED}❌" "CocoaPods update failed"
            fi
        fi
        ;;
        
    "major")
        echo -e "\n${YELLOW}Performing Major Updates (CAUTION)${NC}"
        
        if [ "$FORCE_UPDATE" != "true" ]; then
            echo -e "${RED}⚠️ Major updates can break compatibility${NC}"
            read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_result "${CYAN}ℹ️" "Major update cancelled by user"
                exit 0
            fi
        fi
        
        create_backup
        
        # Swift Package Manager major updates
        if [ "$HAS_SPM" = "true" ]; then
            log_step "Updating Swift packages (all versions)"
            
            # Remove Package.resolved to allow major updates
            [ -f "Package.resolved" ] && rm "Package.resolved"
            
            if swift package update >/dev/null 2>&1; then
                log_result "${GREEN}✅" "Swift packages updated (major)"
            else
                log_result "${RED}❌" "Swift package major update failed"
                restore_backup
                exit 1
            fi
        fi
        
        # CocoaPods major updates
        if [ "$HAS_COCOAPODS" = "true" ]; then
            log_step "Updating CocoaPods (all versions)"
            if pod update >/dev/null 2>&1; then
                log_result "${GREEN}✅" "CocoaPods updated (major)"
            else
                log_result "${RED}❌" "CocoaPods major update failed"
                restore_backup
                exit 1
            fi
        fi
        ;;
        
    "all")
        echo -e "\n${YELLOW}Updating All Dependencies${NC}"
        
        if [ "$FORCE_UPDATE" != "true" ]; then
            echo -e "${YELLOW}This will update build tools and dependencies${NC}"
            read -p "Continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_result "${CYAN}ℹ️" "Update cancelled by user"
                exit 0
            fi
        fi
        
        create_backup
        
        # Update build tools first
        for tool in "${OUTDATED_TOOLS[@]}"; do
            log_step "Updating $tool"
            brew upgrade "$tool" >/dev/null 2>&1 || log_result "${RED}❌" "Failed to update $tool"
        done
        
        # Update packages
        if [ "$HAS_SPM" = "true" ]; then
            log_step "Updating all Swift packages"
            swift package update >/dev/null 2>&1 || log_result "${RED}❌" "Swift package update failed"
        fi
        
        if [ "$HAS_COCOAPODS" = "true" ]; then
            log_step "Updating all CocoaPods"
            pod update >/dev/null 2>&1 || log_result "${RED}❌" "CocoaPods update failed"
        fi
        ;;
        
    *)
        echo -e "${RED}❌ Invalid update type: $UPDATE_TYPE${NC}"
        echo -e "${CYAN}Valid options: check, tools, minor, major, all${NC}"
        exit 1
        ;;
esac

# 5. Post-update validation (only if we actually updated something)
if [[ "$UPDATE_TYPE" =~ ^(tools|minor|patch|major|all)$ ]]; then
    echo -e "\n${YELLOW}Post-Update Validation${NC}"
    
    # Test build
    if ! test_build; then
        echo -e "${RED}❌ Build failed after updates!${NC}"
        restore_backup
        echo -e "${YELLOW}→ Dependencies restored to previous state${NC}"
        exit 1
    fi
    
    # Test suite (optional, can be slow)
    if [ "${RUN_TESTS:-true}" = "true" ]; then
        if ! test_suite; then
            echo -e "${YELLOW}⚠️ Tests failed after updates${NC}"
            echo -e "${CYAN}Consider running tests manually and reviewing failures${NC}"
        fi
    fi
    
    # Generate updated dependency list
    echo -e "\n${CYAN}📋 Updated Dependencies${NC}"
    if [ "$HAS_SPM" = "true" ] && [ -f "Package.resolved" ]; then
        echo -e "${CYAN}Swift Packages:${NC}"
        if command -v jq >/dev/null 2>&1; then
            jq -r '.pins[] | "\(.identity): \(.state.version // .state.revision[0:8])"' Package.resolved | head -10
        fi
    fi
    
    if [ "$HAS_COCOAPODS" = "true" ] && [ -f "Podfile.lock" ]; then
        echo -e "${CYAN}CocoaPods:${NC}"
        grep -A 1000 "PODS:" Podfile.lock | grep -E "^\s*-" | head -10
    fi
fi

# 6. Security check on updated dependencies
if [[ "$UPDATE_TYPE" =~ ^(minor|patch|major|all)$ ]] && [ -f "scripts/security-scan.sh" ]; then
    echo -e "\n${YELLOW}Running Security Scan on Updated Dependencies${NC}"
    if chmod +x scripts/security-scan.sh && scripts/security-scan.sh >/dev/null 2>&1; then
        log_result "${GREEN}✅" "Security scan passed after updates"
    else
        log_result "${YELLOW}⚠️" "Security scan found issues after updates"
    fi
fi

echo -e "\n${BLUE}=================================================="
echo "📦 Dependency Update Summary"
echo "=================================================="

if [[ "$UPDATE_TYPE" =~ ^(tools|minor|patch|major|all)$ ]]; then
    log_result "${GREEN}🎉" "Dependency updates completed successfully!"
    
    echo -e "\n${CYAN}Next Steps:${NC}"
    echo -e "1. ${YELLOW}Test thoroughly:${NC} make test && make test-coverage"
    echo -e "2. ${YELLOW}Check for deprecations:${NC} Review build warnings"
    echo -e "3. ${YELLOW}Update documentation:${NC} If API changes were made"
    echo -e "4. ${YELLOW}Commit changes:${NC} git add . && git commit -m \"Update dependencies\""
    
    if [ "$BACKUP_ENABLED" = "true" ]; then
        echo -e "\n${CYAN}🗂️ Backup available at: $BACKUP_DIR${NC}"
        echo -e "${CYAN}💡 Remove backup when satisfied: rm -rf $BACKUP_DIR${NC}"
    fi
else
    echo -e "${CYAN}ℹ️ Dependency check completed${NC}"
fi

echo -e "\n${BLUE}📋 Detailed log: $UPDATE_LOG${NC}"

echo -e "${GREEN}Happy coding! 🎉${NC}"