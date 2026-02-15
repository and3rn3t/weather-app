#!/bin/bash

# Security Scan Script for Andernet Weather App
# Performs comprehensive security analysis

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 Starting Security Scan for Andernet Weather App${NC}"
echo "=================================================="

# Change to project root
cd "$(dirname "$0")/.."

SCAN_RESULTS="security-scan-results.txt"
ISSUES_FOUND=0

# Function to log results
log_result() {
    local status=$1
    local message=$2
    echo -e "$status $message"
    echo "$(date): $message" >> "$SCAN_RESULTS"
}

# Function to check for issues
check_issue() {
    local check_name=$1
    local command=$2
    local pattern=$3
    
    echo -e "\n${YELLOW}Checking: $check_name${NC}"
    
    if eval "$command" | grep -q "$pattern"; then
        log_result "${RED}❌" "$check_name: Issues found"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        eval "$command" | grep "$pattern" >> "$SCAN_RESULTS"
    else
        log_result "${GREEN}✅" "$check_name: No issues found"
    fi
}

# Initialize results file
echo "Security Scan Results - $(date)" > "$SCAN_RESULTS"
echo "======================================" >> "$SCAN_RESULTS"

# 1. Check for hardcoded secrets/API keys
echo -e "\n${YELLOW}1. Scanning for hardcoded secrets...${NC}"
SECRET_PATTERNS=(
    "api[_-]?key"
    "secret[_-]?key"
    "password"
    "token"
    "private[_-]?key"
    "access[_-]?key"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -ri "$pattern" --include="*.swift" --include="*.plist" --include="*.json" weather/Sources/ weather/*.plist 2>/dev/null | grep -v "// TODO\|// MARK\|comment" | grep -q .; then
        log_result "${RED}❌" "Potential hardcoded secrets found (pattern: $pattern)"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        grep -ri "$pattern" --include="*.swift" --include="*.plist" --include="*.json" weather/Sources/ weather/*.plist 2>/dev/null | grep -v "// TODO\|// MARK\|comment" >> "$SCAN_RESULTS"
    fi
done

if [ $ISSUES_FOUND -eq 0 ]; then
    log_result "${GREEN}✅" "No hardcoded secrets detected"
fi

# 2. Check Info.plist security configurations
echo -e "\n${YELLOW}2. Checking Info.plist security settings...${NC}"
INFO_PLIST="weather/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    # Check for App Transport Security
    if ! grep -q "NSAppTransportSecurity" "$INFO_PLIST"; then
        log_result "${YELLOW}⚠️" "App Transport Security not explicitly configured"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        log_result "${GREEN}✅" "App Transport Security configured"
    fi
    
    # Check for arbitrary loads (security risk)
    if grep -q "NSAllowsArbitraryLoads.*true" "$INFO_PLIST"; then
        log_result "${RED}❌" "Arbitrary loads allowed - security risk"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        log_result "${GREEN}✅" "Arbitrary loads properly restricted"
    fi
else
    log_result "${RED}❌" "Info.plist not found"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 3. Check entitlements for unnecessary permissions
echo -e "\n${YELLOW}3. Checking entitlements...${NC}"
ENTITLEMENTS_FILE="weather/weather.entitlements"

if [ -f "$ENTITLEMENTS_FILE" ]; then
    RISKY_ENTITLEMENTS=(
        "com.apple.security.app-sandbox"
        "com.apple.developer.networking.networkextension"
        "com.apple.developer.healthkit"
        "com.apple.developer.contacts"
    )
    
    for entitlement in "${RISKY_ENTITLEMENTS[@]}"; do
        if grep -q "$entitlement" "$ENTITLEMENTS_FILE"; then
            log_result "${YELLOW}⚠️" "Review entitlement: $entitlement"
        fi
    done
    
    log_result "${GREEN}✅" "Entitlements file reviewed"
else
    log_result "${YELLOW}⚠️" "No entitlements file found"
fi

# 4. Check for debug code in release builds
echo -e "\n${YELLOW}4. Checking for debug code...${NC}"
DEBUG_PATTERNS=(
    "print("
    "NSLog("
    "debugPrint("
    "#if DEBUG"
    "TODO:"
    "FIXME:"
    "HACK:"
)

DEBUG_FOUND=0
for pattern in "${DEBUG_PATTERNS[@]}"; do
    if grep -r "$pattern" --include="*.swift" weather/Sources/ 2>/dev/null | grep -q .; then
        DEBUG_FOUND=1
        echo "Found debug code: $pattern" >> "$SCAN_RESULTS"
    fi
done

if [ $DEBUG_FOUND -eq 1 ]; then
    log_result "${YELLOW}⚠️" "Debug code found - review before release"
else
    log_result "${GREEN}✅" "No debug code detected"
fi

# 5. Check Swift code for common security issues
echo -e "\n${YELLOW}5. Checking Swift code security patterns...${NC}"

# Check for force unwrapping (can cause crashes)
if grep -r "!" --include="*.swift" weather/Sources/ 2>/dev/null | grep -v "// swiftlint:disable\|!=" | grep -q "!"; then
    FORCE_UNWRAP_COUNT=$(grep -r "!" --include="*.swift" weather/Sources/ 2>/dev/null | grep -v "// swiftlint:disable\|!=" | grep "!" | wc -l)
    log_result "${YELLOW}⚠️" "Force unwrapping detected ($FORCE_UNWRAP_COUNT occurrences) - review for crash safety"
else
    log_result "${GREEN}✅" "No excessive force unwrapping detected"
fi

# 6. Check for proper error handling
echo -e "\n${YELLOW}6. Checking error handling patterns...${NC}"
if grep -r "try!" --include="*.swift" weather/Sources/ 2>/dev/null | grep -q .; then
    log_result "${YELLOW}⚠️" "Force try detected - ensure proper error handling"
    grep -r "try!" --include="*.swift" weather/Sources/ 2>/dev/null >> "$SCAN_RESULTS"
else
    log_result "${GREEN}✅" "No force try patterns detected"
fi

# 7. Check for URL scheme security
echo -e "\n${YELLOW}7. Checking URL schemes...${NC}"
if grep -q "CFBundleURLSchemes" "$INFO_PLIST" 2>/dev/null; then
    log_result "${YELLOW}⚠️" "Custom URL schemes detected - ensure proper validation"
    grep -A 5 "CFBundleURLSchemes" "$INFO_PLIST" >> "$SCAN_RESULTS"
else
    log_result "${GREEN}✅" "No custom URL schemes detected"
fi

# 8. Check file permissions on sensitive files
echo -e "\n${YELLOW}8. Checking file permissions...${NC}"
SENSITIVE_FILES=(
    "weather.xcconfig"
    "ExportOptions.plist"
    "weather.entitlements"
)

for file in "${SENSITIVE_FILES[@]}"; do
    if [ -f "$file" ]; then
        PERMS=$(ls -la "$file" | awk '{print $1}')
        if [[ "$PERMS" == *"rw-rw-rw-"* ]] || [[ "$PERMS" == *"rwxrwxrwx"* ]]; then
            log_result "${RED}❌" "$file has overly permissive permissions: $PERMS"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        else
            log_result "${GREEN}✅" "$file permissions OK: $PERMS"
        fi
    fi
done

echo -e "\n${BLUE}=================================================="
echo "Security Scan Complete"
echo "=================================================="

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No critical security issues found!${NC}"
    echo -e "${GREEN}Your app follows good security practices.${NC}"
else
    echo -e "${RED}⚠️  $ISSUES_FOUND potential security issues found.${NC}"
    echo -e "${YELLOW}Please review the issues above and the detailed log: $SCAN_RESULTS${NC}"
fi

echo -e "\n${BLUE}📋 Detailed results saved to: $SCAN_RESULTS${NC}"
echo -e "${BLUE}🔒 Run this scan regularly before releases${NC}"

# Return appropriate exit code
if [ $ISSUES_FOUND -gt 0 ]; then
    exit 1
else
    exit 0
fi