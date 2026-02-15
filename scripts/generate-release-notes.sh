#!/bin/bash

# Release Notes Generator for Andernet Weather App
# Automatically generates release notes from git history

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
FROM_TAG="${1:-""}"
TO_TAG="${2:-HEAD}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-markdown}"  # markdown, json, text
INCLUDE_UNRELEASED="${INCLUDE_UNRELEASED:-true}"

echo -e "${BLUE}📝 Generating Release Notes for Andernet Weather App${NC}"
echo "======================================================"

# Change to project root
cd "$(dirname "$0")/.."

OUTPUT_FILE="release-notes.md"
JSON_OUTPUT="release-notes.json"

# Function to get the latest tag if FROM_TAG is empty
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

# Function to get next version
get_next_version() {
    local current_tag=$1
    if [ -z "$current_tag" ]; then
        echo "v1.0.0"
        return
    fi
    
    # Remove 'v' prefix and split version
    local version=${current_tag#v}
    IFS='.' read -r -a VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]}
    local minor=${VERSION_PARTS[1]:-0}
    local patch=${VERSION_PARTS[2]:-0}
    
    echo "v$major.$minor.$((patch + 1))"
}

# Function to categorize commits
categorize_commit() {
    local commit_msg="$1"
    local msg_lower
    msg_lower=$(echo "$commit_msg" | tr '[:upper:]' '[:lower:]')
    
    case "$msg_lower" in
        *"feat:"*|*"feature:"*|*"add:"*|*"new:"*)
            echo "features"
            ;;
        *"fix:"*|*"bug:"*|*"patch:"*|*"resolve:"*)
            echo "bugfixes"
            ;;
        *"perf:"*|*"performance:"*|*"optimize:"*|*"speed:"*)
            echo "performance"
            ;;
        *"security:"*|*"sec:"*|*"vulnerability:"*)
            echo "security"
            ;;
        *"ui:"*|*"ux:"*|*"design:"*|*"interface:"*)
            echo "ui"
            ;;
        *"test:"*|*"tests:"*|*"testing:"*)
            echo "testing"
            ;;
        *"doc:"*|*"docs:"*|*"documentation:"*)
            echo "documentation"
            ;;
        *"refactor:"*|*"cleanup:"*|*"improve:"*)
            echo "improvements"
            ;;
        *"build:"*|*"ci:"*|*"cd:"*|*"deploy:"*)
            echo "build"
            ;;
        *"breaking:"*|*"breaking change"*)
            echo "breaking"
            ;;
        *)
            echo "other"
            ;;
    esac
}

# Function to extract issue numbers
extract_issues() {
    local commit_msg="$1"
    echo "$commit_msg" | grep -oE "#[0-9]+" | sort -u | tr '\n' ' '
}

# Function to clean commit message
clean_commit_message() {
    local msg="$1"
    # Remove conventional commit prefixes and clean up
    msg=$(echo "$msg" | sed -E 's/^(feat|fix|perf|security|ui|ux|test|doc|docs|refactor|build|ci|cd|breaking)(\([^)]*\))?:\s*//')
    # Remove issue references from the end
    msg=$(echo "$msg" | sed -E 's/\s*(#[0-9]+\s*)+$//')
    # Capitalize first letter
    msg=$(echo "$msg" | sed 's/^\(.\)/\U\1/')
    echo "$msg"
}

# Initialize variables
if [ -z "$FROM_TAG" ]; then
    FROM_TAG=$(get_latest_tag)
    if [ -z "$FROM_TAG" ]; then
        echo -e "${YELLOW}No previous tags found, showing all commits${NC}"
        FROM_TAG=""
    else
        echo -e "${CYAN}Generating notes from: $FROM_TAG${NC}"
    fi
else
    echo -e "${CYAN}Generating notes from: $FROM_TAG${NC}"
fi

echo -e "${CYAN}Generating notes to: $TO_TAG${NC}"

# Get git log range
if [ -n "$FROM_TAG" ]; then
    if [ "$TO_TAG" = "HEAD" ]; then
        GIT_RANGE="${FROM_TAG}..HEAD"
        NEXT_VERSION=$(get_next_version "$FROM_TAG")
    else
        GIT_RANGE="${FROM_TAG}..${TO_TAG}"
        NEXT_VERSION="$TO_TAG"
    fi
else
    GIT_RANGE="HEAD"
    NEXT_VERSION="v1.0.0"
fi

echo -e "${CYAN}Proposed version: $NEXT_VERSION${NC}"

# Get commits
echo -e "${YELLOW}Analyzing commits...${NC}"

# Declare associative arrays for commit categorization
declare -A COMMITS
COMMITS[features]=""
COMMITS[bugfixes]=""
COMMITS[performance]=""
COMMITS[security]=""
COMMITS[ui]=""
COMMITS[testing]=""
COMMITS[documentation]=""
COMMITS[improvements]=""
COMMITS[build]=""
COMMITS[breaking]=""
COMMITS[other]=""

declare -A COMMIT_COUNT
TOTAL_COMMITS=0

# Process each commit
while IFS= read -r line; do
    if [ -n "$line" ]; then
        TOTAL_COMMITS=$((TOTAL_COMMITS + 1))
        
        # Parse commit info (hash|message)
        COMMIT_HASH=$(echo "$line" | cut -d'|' -f1)
        COMMIT_MSG=$(echo "$line" | cut -d'|' -f2-)
        
        # Skip merge commits
        if [[ "$COMMIT_MSG" == "Merge "* ]]; then
            continue
        fi
        
        # Categorize commit
        CATEGORY=$(categorize_commit "$COMMIT_MSG")
        CLEAN_MSG=$(clean_commit_message "$COMMIT_MSG")
        ISSUES=$(extract_issues "$COMMIT_MSG")
        
        # Add to category
        if [ -n "${COMMITS[$CATEGORY]}" ]; then
            COMMITS[$CATEGORY]="${COMMITS[$CATEGORY]}\n"
        fi
        COMMITS[$CATEGORY]="${COMMITS[$CATEGORY]}• $CLEAN_MSG"
        
        if [ -n "$ISSUES" ]; then
            COMMITS[$CATEGORY]="${COMMITS[$CATEGORY]} ($ISSUES)"
        fi
        
        # Add commit hash for reference
        COMMITS[$CATEGORY]="${COMMITS[$CATEGORY]} [\`${COMMIT_HASH:0:7}\`]"
        
        # Update count
        COMMIT_COUNT[$CATEGORY]=$((${COMMIT_COUNT[$CATEGORY]:-0} + 1))
    fi
done < <(git log --pretty=format:"%H|%s" "$GIT_RANGE" 2>/dev/null)

echo -e "${GREEN}✅ Analyzed $TOTAL_COMMITS commits${NC}"

# Generate current date
CURRENT_DATE=$(date '+%Y-%m-%d')

# Generate Markdown output
generate_markdown() {
    local output_file="$1"
    
    cat > "$output_file" << EOF
# Release Notes - $NEXT_VERSION

**Release Date:** $CURRENT_DATE  
**Commits:** $TOTAL_COMMITS changes

EOF

    # Add breaking changes first (most important)
    if [ -n "${COMMITS[breaking]}" ] && [ "${COMMITS[breaking]}" != "" ]; then
        cat >> "$output_file" << EOF
## 🚨 Breaking Changes

${COMMITS[breaking]}

EOF
    fi

    # Add new features
    if [ -n "${COMMITS[features]}" ] && [ "${COMMITS[features]}" != "" ]; then
        cat >> "$output_file" << EOF
## ✨ New Features

${COMMITS[features]}

EOF
    fi

    # Add bug fixes
    if [ -n "${COMMITS[bugfixes]}" ] && [ "${COMMITS[bugfixes]}" != "" ]; then
        cat >> "$output_file" << EOF
## 🐛 Bug Fixes

${COMMITS[bugfixes]}

EOF
    fi

    # Add security improvements
    if [ -n "${COMMITS[security]}" ] && [ "${COMMITS[security]}" != "" ]; then
        cat >> "$output_file" << EOF
## 🔒 Security

${COMMITS[security]}

EOF
    fi

    # Add performance improvements
    if [ -n "${COMMITS[performance]}" ] && [ "${COMMITS[performance]}" != "" ]; then
        cat >> "$output_file" << EOF
## ⚡ Performance

${COMMITS[performance]}

EOF
    fi

    # Add UI/UX improvements
    if [ -n "${COMMITS[ui]}" ] && [ "${COMMITS[ui]}" != "" ]; then
        cat >> "$output_file" << EOF
## 🎨 UI/UX Improvements

${COMMITS[ui]}

EOF
    fi

    # Add other improvements
    if [ -n "${COMMITS[improvements]}" ] && [ "${COMMITS[improvements]}" != "" ]; then
        cat >> "$output_file" << EOF
## 🔧 Improvements

${COMMITS[improvements]}

EOF
    fi

    # Add testing improvements
    if [ -n "${COMMITS[testing]}" ] && [ "${COMMITS[testing]}" != "" ]; then
        cat >> "$output_file" << EOF
## 🧪 Testing

${COMMITS[testing]}

EOF
    fi

    # Add documentation updates
    if [ -n "${COMMITS[documentation]}" ] && [ "${COMMITS[documentation]}" != "" ]; then
        cat >> "$output_file" << EOF
## 📚 Documentation

${COMMITS[documentation]}

EOF
    fi

    # Add build/CI changes
    if [ -n "${COMMITS[build]}" ] && [ "${COMMITS[build]}" != "" ]; then
        cat >> "$output_file" << EOF
## 🔨 Build & CI

${COMMITS[build]}

EOF
    fi

    # Add other changes
    if [ -n "${COMMITS[other]}" ] && [ "${COMMITS[other]}" != "" ]; then
        cat >> "$output_file" << EOF
## 📦 Other Changes

${COMMITS[other]}

EOF
    fi

    # Add contributors section
    cat >> "$output_file" << EOF
## 👥 Contributors

$(git log --pretty=format:"%an" "$GIT_RANGE" 2>/dev/null | sort -u | sed 's/^/• /')

---

**Full Changelog:** https://github.com/and3rn3t/weather-app/compare/$FROM_TAG...$NEXT_VERSION
EOF
}

# Generate JSON output
generate_json() {
    local output_file="$1"
    
    cat > "$output_file" << EOF
{
  "version": "$NEXT_VERSION",
  "date": "$CURRENT_DATE",
  "total_commits": $TOTAL_COMMITS,
  "categories": {
EOF

    local first=true
    for category in features bugfixes security performance ui improvements testing documentation build other; do
        if [ -n "${COMMITS[$category]}" ] && [ "${COMMITS[$category]}" != "" ]; then
            if [ "$first" = false ]; then
                echo "," >> "$output_file"
            fi
            echo -n "    \"$category\": [" >> "$output_file"
            
            # Convert newline-separated items to JSON array
            echo -e "${COMMITS[$category]}" | sed 's/^• //' | sed 's/$/",/' | sed '$s/,$//' | sed 's/^/      "/' >> "$output_file"
            
            echo -n "    ]" >> "$output_file"
            first=false
        fi
    done

    cat >> "$output_file" << EOF

  },
  "contributors": [
$(git log --pretty=format:"%an" "$GIT_RANGE" 2>/dev/null | sort -u | sed 's/^/    "/' | sed 's/$/",/' | sed '$s/,$//')
  ]
}
EOF
}

# Generate output based on format
case "$OUTPUT_FORMAT" in
    "markdown"|"md")
        generate_markdown "$OUTPUT_FILE"
        echo -e "${GREEN}✅ Release notes generated: $OUTPUT_FILE${NC}"
        ;;
    "json")
        generate_json "$JSON_OUTPUT"
        echo -e "${GREEN}✅ Release notes generated: $JSON_OUTPUT${NC}"
        ;;
    "both")
        generate_markdown "$OUTPUT_FILE"
        generate_json "$JSON_OUTPUT"
        echo -e "${GREEN}✅ Release notes generated: $OUTPUT_FILE & $JSON_OUTPUT${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid format: $OUTPUT_FORMAT${NC}"
        echo -e "${CYAN}Valid formats: markdown, json, both${NC}"
        exit 1
        ;;
esac

# Show summary
echo -e "\n${BLUE}📊 Release Notes Summary${NC}"
echo -e "${CYAN}Version:${NC} $NEXT_VERSION"
echo -e "${CYAN}Total Commits:${NC} $TOTAL_COMMITS"
echo -e "${CYAN}Date Range:${NC} ${FROM_TAG:-"(all)"} → $TO_TAG"

# Show category breakdown
echo -e "\n${CYAN}Categories:${NC}"
for category in features bugfixes security performance ui improvements testing documentation build other; do
    local count=${COMMIT_COUNT[$category]:-0}
    if [ $count -gt 0 ]; then
        echo -e "  • $category: $count commits"
    fi
done

# Suggest next steps
echo -e "\n${YELLOW}💡 Next Steps:${NC}"
echo -e "1. Review and edit the generated notes"
echo -e "2. Add the notes to CHANGELOG.md"
echo -e "3. Use in GitHub releases or App Store notes"

if [ "$OUTPUT_FORMAT" = "markdown" ] || [ "$OUTPUT_FORMAT" = "both" ]; then
    echo -e "\n${CYAN}Preview:${NC}"
    echo -e "${YELLOW}$(head -20 "$OUTPUT_FILE")${NC}"
    if [ $(wc -l < "$OUTPUT_FILE") -gt 20 ]; then
        echo -e "${YELLOW}... (truncated, see $OUTPUT_FILE for full notes)${NC}"
    fi
fi

echo -e "${GREEN}🎉 Release notes generation complete!${NC}"