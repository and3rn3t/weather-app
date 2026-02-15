#!/bin/bash

# Development Environment Setup Script for Andernet Weather App
# Sets up complete development environment for new contributors

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Andernet Weather App Development Environment${NC}"
echo "================================================================"

# Change to project root
cd "$(dirname "$0")/.."

# Track what was installed
INSTALLED_TOOLS=()
SETUP_LOG="setup-log.txt"

# Function to log setup steps
log_step() {
    local message=$1
    echo -e "${CYAN}→ $message${NC}"
    echo "$(date): $message" >> "$SETUP_LOG"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install via Homebrew
install_with_brew() {
    local tool=$1
    local package=${2:-$1}
    
    if command_exists "$tool"; then
        echo -e "${GREEN}✅ $tool already installed${NC}"
    else
        log_step "Installing $tool via Homebrew"
        if command_exists brew; then
            brew install "$package"
            INSTALLED_TOOLS+=("$tool")
            echo -e "${GREEN}✅ $tool installed successfully${NC}"
        else
            echo -e "${RED}❌ Homebrew not found. Please install Homebrew first.${NC}"
            return 1
        fi
    fi
}

# Initialize setup log
echo "Development Environment Setup - $(date)" > "$SETUP_LOG"
echo "===========================================" >> "$SETUP_LOG"

echo -e "${YELLOW}Checking system requirements...${NC}"

# 1. Check macOS version
echo -e "\n${YELLOW}1. System Requirements${NC}"
MACOS_VERSION=$(sw_vers -productVersion)
log_step "macOS Version: $MACOS_VERSION"

if [[ $(echo "$MACOS_VERSION >= 13.0" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
    echo -e "${GREEN}✅ macOS version compatible${NC}"
else
    echo -e "${RED}❌ macOS 13.0+ required for iOS 17 development${NC}"
fi

# 2. Check Xcode
echo -e "\n${YELLOW}2. Xcode Setup${NC}"
if command_exists xcodebuild; then
    XCODE_VERSION=$(xcodebuild -version | head -n1 | awk '{print $2}')
    log_step "Xcode Version: $XCODE_VERSION"
    echo -e "${GREEN}✅ Xcode installed: $XCODE_VERSION${NC}"
    
    # Accept Xcode license
    if xcodebuild -checkFirstLaunchStatus 2>/dev/null; then
        echo -e "${GREEN}✅ Xcode license accepted${NC}"
    else
        log_step "Accepting Xcode license"
        echo -e "${YELLOW}⚠️ Xcode license needs acceptance${NC}"
        sudo xcodebuild -license accept
    fi
    
    # Install additional components
    log_step "Installing Xcode additional components"
    xcodebuild -runFirstLaunch
    
else
    echo -e "${RED}❌ Xcode not found. Please install from Mac App Store.${NC}"
    echo -e "${CYAN}💡 Download: https://apps.apple.com/app/xcode/id497799835${NC}"
    exit 1
fi

# 3. Check iOS Simulators
echo -e "\n${YELLOW}3. iOS Simulators${NC}"
log_step "Checking available iOS simulators"
SIMULATORS=$(xcrun simctl list devices available | grep "iPhone" | head -3)
if [ -n "$SIMULATORS" ]; then
    echo -e "${GREEN}✅ iOS Simulators available${NC}"
    echo "$SIMULATORS"
else
    echo -e "${YELLOW}⚠️ No iOS simulators found. Installing...${NC}"
    # This would require more complex simulator management
    echo -e "${CYAN}💡 Install simulators via Xcode → Settings → Platforms${NC}"
fi

# 4. Install Homebrew (if not present)
echo -e "\n${YELLOW}4. Package Manager (Homebrew)${NC}"
if command_exists brew; then
    BREW_VERSION=$(brew --version | head -n1)
    log_step "Homebrew Version: $BREW_VERSION"
    echo -e "${GREEN}✅ Homebrew installed${NC}"
else
    log_step "Installing Homebrew"
    echo -e "${YELLOW}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    INSTALLED_TOOLS+=("homebrew")
    echo -e "${GREEN}✅ Homebrew installed successfully${NC}"
fi

# Update Homebrew
log_step "Updating Homebrew"
brew update

# 5. Install development tools
echo -e "\n${YELLOW}5. Development Tools${NC}"

# Install essential build tools
install_with_brew "xcbeautify" "xcbeautify"
install_with_brew "swiftlint" "swiftlint"
install_with_brew "swift-format" "swift-format"

# Install optional but useful tools
echo -e "\n${CYAN}Installing additional developer tools...${NC}"
install_with_brew "gh" "gh"  # GitHub CLI
install_with_brew "jq" "jq"  # JSON processor
install_with_brew "tree" "tree"  # Directory tree viewer

# 6. Git configuration
echo -e "\n${YELLOW}6. Git Setup${NC}"
if command_exists git; then
    GIT_VERSION=$(git --version)
    log_step "Git Version: $GIT_VERSION"
    echo -e "${GREEN}✅ Git installed${NC}"
    
    # Check git config
    if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
        GIT_USER=$(git config --global user.name)
        GIT_EMAIL=$(git config --global user.email)
        echo -e "${GREEN}✅ Git configured for: $GIT_USER <$GIT_EMAIL>${NC}"
    else
        echo -e "${YELLOW}⚠️ Git not configured globally${NC}"
        echo -e "${CYAN}💡 Run: git config --global user.name 'Your Name'${NC}"
        echo -e "${CYAN}💡 Run: git config --global user.email 'you@example.com'${NC}"
    fi
else
    install_with_brew "git" "git"
fi

# 7. Install Git hooks
echo -e "\n${YELLOW}7. Git Hooks Setup${NC}"
if [ -f "scripts/pre-commit" ]; then
    log_step "Installing Git pre-commit hooks"
    mkdir -p .git/hooks
    cp scripts/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo -e "${GREEN}✅ Git hooks installed${NC}"
else
    echo -e "${YELLOW}⚠️ Pre-commit hook script not found${NC}"
fi

# 8. Verify project can build
echo -e "\n${YELLOW}8. Project Build Verification${NC}"
log_step "Testing project build"

if [ -f "Makefile" ]; then
    echo -e "${CYAN}Testing build system...${NC}"
    if make clean >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Make clean successful${NC}"
    else
        echo -e "${RED}❌ Make clean failed${NC}"
    fi
    
    # Try a quick build test (but don't fail setup if it fails)
    echo -e "${CYAN}Attempting test build (this may take a moment)...${NC}"
    if timeout 60 make build >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Test build successful${NC}"
    else
        echo -e "${YELLOW}⚠️ Test build timed out or failed (this is OK for first run)${NC}"
        echo -e "${CYAN}💡 Try running 'make build' manually after setup${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Makefile not found${NC}"
fi

# 9. SwiftLint configuration
echo -e "\n${YELLOW}9. Code Quality Tools${NC}"
if [ -f ".swiftlint.yml" ]; then
    log_step "SwiftLint configuration found"
    if command_exists swiftlint; then
        echo -e "${CYAN}Testing SwiftLint...${NC}"
        if swiftlint version >/dev/null 2>&1; then
            SWIFTLINT_VERSION=$(swiftlint version)
            echo -e "${GREEN}✅ SwiftLint ready: $SWIFTLINT_VERSION${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️ .swiftlint.yml not found${NC}"
fi

# 10. Environment variables and paths
echo -e "\n${YELLOW}10. Environment Setup${NC}"

# Check if developer tools path is set correctly
DEVELOPER_DIR=$(xcode-select -p)
log_step "Developer Tools Path: $DEVELOPER_DIR"

if [[ "$DEVELOPER_DIR" == *"/Applications/Xcode.app"* ]]; then
    echo -e "${GREEN}✅ Xcode command line tools path correct${NC}"
else
    echo -e "${YELLOW}⚠️ Setting Xcode command line tools path${NC}"
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
fi

# 11. Create useful aliases
echo -e "\n${YELLOW}11. Shell Aliases${NC}"
SHELL_RC=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    log_step "Adding helpful aliases to $SHELL_RC"
    
    # Create backup
    if [ -f "$SHELL_RC" ]; then
        cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%s)"
    fi
    
    # Add weather app aliases
    cat >> "$SHELL_RC" << 'EOF'

# Andernet Weather App aliases
alias wbuild='make build'
alias wtest='make test'
alias wclean='make clean'
alias wlint='make lint'
alias wsim='open -a Simulator'
EOF
    echo -e "${GREEN}✅ Shell aliases added${NC}"
    echo -e "${CYAN}💡 Reload shell or run: source $SHELL_RC${NC}"
fi

# Summary
echo -e "\n${BLUE}================================================================"
echo "🎉 Development Environment Setup Complete!"
echo "================================================================"

# Show what was installed
if [ ${#INSTALLED_TOOLS[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ Newly installed tools:${NC}"
    for tool in "${INSTALLED_TOOLS[@]}"; do
        echo -e "  • $tool"
    done
else
    echo -e "${GREEN}✅ All required tools were already installed${NC}"
fi

echo -e "\n${CYAN}📋 Next Steps:${NC}"
echo -e "  1. Reload your shell: ${YELLOW}source ~/.zshrc${NC}"
echo -e "  2. Test the build: ${YELLOW}make build${NC}"
echo -e "  3. Run tests: ${YELLOW}make test${NC}"
echo -e "  4. Start developing! 🚀"

echo -e "\n${CYAN}💡 Useful Commands:${NC}"
echo -e "  • ${YELLOW}wbuild${NC}     - Quick build"
echo -e "  • ${YELLOW}wtest${NC}      - Run tests"
echo -e "  • ${YELLOW}wlint${NC}      - Code linting"
echo -e "  • ${YELLOW}wsim${NC}       - Open simulator"
echo -e "  • ${YELLOW}make help${NC}  - All available commands"

echo -e "\n${BLUE}📖 Documentation:${NC}"
echo -e "  • README.md - Project overview"
echo -e "  • docs/development/QUICK_START.md - Development guide"
echo -e "  • docs/TESTING_GUIDE.md - Testing information"

echo -e "\n${BLUE}🔧 Setup log saved to: $SETUP_LOG${NC}"

echo -e "${GREEN}Happy coding! 🎉${NC}"