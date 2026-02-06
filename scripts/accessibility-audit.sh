#!/bin/bash
# Accessibility Audit Script for Xcode
# Runs accessibility audits on the iOS app

set -e

SCHEME="weather"
PROJECT="weather.xcodeproj"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Accessibility Audit - Andernet Weather${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Create output directory
mkdir -p build/accessibility

# Function to check Swift files for accessibility issues
audit_code() {
    echo -e "${YELLOW}Checking code for accessibility patterns...${NC}"
    echo ""
    
    # Count accessibility labels
    LABEL_COUNT=$(grep -r "accessibilityLabel" weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    HINT_COUNT=$(grep -r "accessibilityHint" weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    HIDDEN_COUNT=$(grep -r "accessibilityHidden" weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    
    echo -e "${BLUE}Accessibility Attributes Found:${NC}"
    echo "  accessibilityLabel:  $LABEL_COUNT occurrences"
    echo "  accessibilityHint:   $HINT_COUNT occurrences"
    echo "  accessibilityHidden: $HIDDEN_COUNT occurrences"
    echo ""
    
    # Check for images without accessibility labels
    echo -e "${YELLOW}Checking for images without accessibility...${NC}"
    IMAGES_TOTAL=$(grep -rE 'Image\(|Image\(' weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    IMAGES_WITH_LABEL=$(grep -rE 'Image\(' weather/Sources --include="*.swift" 2>/dev/null | grep -E 'accessibilityLabel|decorative' | wc -l | xargs)
    
    echo "  Total Image views: $IMAGES_TOTAL"
    echo "  With accessibility: $IMAGES_WITH_LABEL"
    
    IMAGES_MISSING=$((IMAGES_TOTAL - IMAGES_WITH_LABEL))
    if [ "$IMAGES_MISSING" -gt 0 ]; then
        echo -e "  ${RED}Missing accessibility: $IMAGES_MISSING (review recommended)${NC}"
    else
        echo -e "  ${GREEN}✓ All images have accessibility${NC}"
    fi
    echo ""
    
    # Check for buttons without labels
    echo -e "${YELLOW}Checking interactive elements...${NC}"
    BUTTON_COUNT=$(grep -rE 'Button\(' weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    TAPPABLE_COUNT=$(grep -rE '\.onTapGesture' weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    
    echo "  Button views: $BUTTON_COUNT"
    echo "  Tap gestures: $TAPPABLE_COUNT"
    echo ""
    
    # Check for color contrast issues (hardcoded colors)
    echo -e "${YELLOW}Checking for potential color issues...${NC}"
    HARDCODED_COLORS=$(grep -rE 'Color\(red:|Color\(#|UIColor\(red:' weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    
    if [ "$HARDCODED_COLORS" -gt 0 ]; then
        echo -e "  ${YELLOW}Hardcoded colors: $HARDCODED_COLORS (verify contrast ratios)${NC}"
    else
        echo -e "  ${GREEN}✓ Using system colors (good for accessibility)${NC}"
    fi
    echo ""
    
    # Check for dynamic type support
    echo -e "${YELLOW}Checking Dynamic Type support...${NC}"
    FIXED_SIZE=$(grep -r '\.fixedSize()' weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    SCALED_METRIC=$(grep -r '@ScaledMetric' weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    DYNAMIC_TYPE=$(grep -r '.dynamicTypeSize' weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    
    echo "  @ScaledMetric usage: $SCALED_METRIC"
    echo "  .dynamicTypeSize:    $DYNAMIC_TYPE"
    
    if [ "$FIXED_SIZE" -gt 0 ]; then
        echo -e "  ${YELLOW}fixedSize() usage: $FIXED_SIZE (may affect text scaling)${NC}"
    fi
    echo ""
}

# Generate a report
generate_report() {
    REPORT_FILE="build/accessibility/audit-report-$(date +%Y%m%d-%H%M%S).md"
    
    echo "# Accessibility Audit Report" > "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**Generated:** $(date)" >> "$REPORT_FILE"
    echo "**App:** Andernet Weather" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Summary" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Count totals
    LABEL_COUNT=$(grep -r "accessibilityLabel" weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    HINT_COUNT=$(grep -r "accessibilityHint" weather/Sources --include="*.swift" 2>/dev/null | wc -l | xargs)
    
    echo "| Metric | Count |" >> "$REPORT_FILE"
    echo "|--------|-------|" >> "$REPORT_FILE"
    echo "| Accessibility Labels | $LABEL_COUNT |" >> "$REPORT_FILE"
    echo "| Accessibility Hints | $HINT_COUNT |" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Recommendations" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "1. Ensure all interactive elements have accessibility labels" >> "$REPORT_FILE"
    echo "2. Add hints for complex interactions" >> "$REPORT_FILE"
    echo "3. Group related elements with accessibilityElement(children:)" >> "$REPORT_FILE"
    echo "4. Test with VoiceOver enabled" >> "$REPORT_FILE"
    echo "5. Verify color contrast ratios (4.5:1 for text, 3:1 for large text)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## Files with Accessibility" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    grep -rl "accessibilityLabel" weather/Sources --include="*.swift" 2>/dev/null >> "$REPORT_FILE" || echo "None found" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    
    echo ""
    echo -e "${GREEN}✓ Report saved to: $REPORT_FILE${NC}"
}

# Run Xcode accessibility audit
run_xcode_audit() {
    echo -e "${YELLOW}Running Xcode Accessibility Audit...${NC}"
    echo ""
    echo "To run a full accessibility audit in Xcode:"
    echo ""
    echo "1. Open the project in Xcode"
    echo "2. Run the app in Simulator"
    echo "3. Open Accessibility Inspector (Xcode → Open Developer Tool → Accessibility Inspector)"
    echo "4. Click the audit button (checkmark icon)"
    echo "5. Review and fix any issues"
    echo ""
    echo "Or use the Environment Overrides in Xcode to test:"
    echo "  - Bold Text"
    echo "  - Larger Text"
    echo "  - Reduce Motion"
    echo "  - Increase Contrast"
    echo "  - Smart Invert"
    echo ""
}

# VoiceOver testing guide
voiceover_guide() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   VoiceOver Testing Guide${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Enable VoiceOver in Simulator:"
    echo "  Settings → Accessibility → VoiceOver → On"
    echo ""
    echo "Keyboard Shortcuts (with VoiceOver):"
    echo "  Ctrl + Option + → : Next element"
    echo "  Ctrl + Option + ← : Previous element"
    echo "  Ctrl + Option + Space : Activate"
    echo "  Ctrl + Option + U : Rotor"
    echo ""
    echo "Test these scenarios:"
    echo "  □ Navigate entire app using VoiceOver"
    echo "  □ Verify all buttons are announced"
    echo "  □ Check weather values are read correctly"
    echo "  □ Test search functionality"
    echo "  □ Verify charts are accessible"
    echo "  □ Check navigation order makes sense"
    echo ""
}

# Main execution
audit_code
generate_report
echo ""
run_xcode_audit
voiceover_guide

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Audit Complete${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
