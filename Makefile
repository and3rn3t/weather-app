# Andernet Weather - Build Automation
# Usage: make [target]

SCHEME = weather
PROJECT = weather.xcodeproj
CONFIGURATION_DEBUG = Debug
CONFIGURATION_RELEASE = Release
DESTINATION = platform=iOS Simulator,name=iPhone 17 Pro

.PHONY: clean build test archive lint format

# Clean build artifacts
clean:
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION_DEBUG)
	rm -rf ~/Library/Developer/Xcode/DerivedData/weather-*
	@echo "✅ Clean complete"

# Build for Debug
build:
	@if command -v xcbeautify >/dev/null 2>&1; then \
		xcodebuild build \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-configuration $(CONFIGURATION_DEBUG) \
			-destination "$(DESTINATION)" \
			| xcbeautify; \
	else \
		xcodebuild build \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-configuration $(CONFIGURATION_DEBUG) \
			-destination "$(DESTINATION)"; \
	fi

# Build for Release
build-release:
	@if command -v xcbeautify >/dev/null 2>&1; then \
		xcodebuild build \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-configuration $(CONFIGURATION_RELEASE) \
			-destination "$(DESTINATION)" \
			| xcbeautify; \
	else \
		xcodebuild build \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-configuration $(CONFIGURATION_RELEASE) \
			-destination "$(DESTINATION)"; \
	fi

# Run tests
test:
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-parallel-testing-enabled YES \
		| xcbeautify

# Run tests with code coverage
test-coverage:
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-enableCodeCoverage YES \
		| xcbeautify

# Build archive for App Store
archive:
	@mkdir -p build
	@if command -v xcbeautify >/dev/null 2>&1; then \
		xcodebuild archive \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-configuration $(CONFIGURATION_RELEASE) \
			-archivePath build/weather.xcarchive \
			| xcbeautify; \
	else \
		xcodebuild archive \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-configuration $(CONFIGURATION_RELEASE) \
			-archivePath build/weather.xcarchive; \
	fi
	@echo "✅ Archive created at build/weather.xcarchive"

# Export IPA from archive
export-ipa: archive
	@mkdir -p build/ipa
	@if command -v xcbeautify >/dev/null 2>&1; then \
		xcodebuild -exportArchive \
			-archivePath build/weather.xcarchive \
			-exportPath build/ipa \
			-exportOptionsPlist ExportOptions.plist \
			| xcbeautify; \
	else \
		xcodebuild -exportArchive \
			-archivePath build/weather.xcarchive \
			-exportPath build/ipa \
			-exportOptionsPlist ExportOptions.plist; \
	fi
	@echo "✅ IPA exported to build/ipa/"

# Quick lint check (requires SwiftLint)
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --config .swiftlint.yml; \
	else \
		echo "⚠️  SwiftLint not installed. Run: brew install swiftlint"; \
	fi

# Format code (requires swift-format)
format:
	@if command -v swift-format >/dev/null 2>&1; then \
		find weather/Sources -name "*.swift" -exec swift-format -i {} \;; \
		echo "✅ Code formatted"; \
	else \
		echo "⚠️  swift-format not installed. Run: brew install swift-format"; \
	fi

# Show build settings
show-settings:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -showBuildSettings

# Install xcbeautify for better build output (optional dependency)
setup-tools:
	@if ! command -v xcbeautify >/dev/null 2>&1; then \
		brew install xcbeautify; \
	fi
	@if ! command -v swiftlint >/dev/null 2>&1; then \
		brew install swiftlint; \
	fi
	@echo "✅ Build tools installed"

# Analyze for potential issues
analyze:
	xcodebuild analyze \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		| xcbeautify

# Analyze build times
analyze-build-times:
	@chmod +x scripts/analyze-build-times.sh
	@./scripts/analyze-build-times.sh

# Analyze app size
analyze-size:
	@chmod +x scripts/analyze-app-size.sh
	@./scripts/analyze-app-size.sh

# Install git hooks
install-hooks:
	@mkdir -p .git/hooks
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Git hooks installed"

# Setup development environment
setup-dev:
	@chmod +x scripts/setup-dev-environment.sh
	@./scripts/setup-dev-environment.sh

# Run security scan
security-scan:
	@chmod +x scripts/security-scan.sh
	@./scripts/security-scan.sh

# Update dependencies
update-deps:
	@chmod +x scripts/update-dependencies.sh
	@./scripts/update-dependencies.sh check

update-deps-minor:
	@chmod +x scripts/update-dependencies.sh
	@./scripts/update-dependencies.sh minor

update-deps-tools:
	@chmod +x scripts/update-dependencies.sh
	@./scripts/update-dependencies.sh tools

# Prepare release
prepare-release:
	@chmod +x scripts/prepare-release.sh
	@./scripts/prepare-release.sh patch

prepare-release-minor:
	@chmod +x scripts/prepare-release.sh
	@./scripts/prepare-release.sh minor

prepare-release-major:
	@chmod +x scripts/prepare-release.sh
	@./scripts/prepare-release.sh major

# Generate release notes
release-notes:
	@chmod +x scripts/generate-release-notes.sh
	@./scripts/generate-release-notes.sh

# Shell Integration
shell-integration:
	@chmod +x scripts/weather-shell-integration.sh
	@echo "🌤️ Loading Weather App shell integration..."
	@source scripts/weather-shell-integration.sh && echo "✅ Shell functions loaded"

shell-setup:
	@echo "🔧 Setting up advanced shell integration..."
	@chmod +x scripts/weather-directory-hook.sh scripts/weather-terminal-optimization.sh
	@if [[ -n "$$ZSH_VERSION" ]]; then chmod +x scripts/weather-zsh-completions.zsh; fi
	@echo "✅ Shell integration files prepared"
	@echo "💡 Add the following to your ~/.zshrc or ~/.bashrc:"
	@echo "source $(PWD)/scripts/weather-shell-integration.sh"
	@echo "source $(PWD)/scripts/weather-directory-hook.sh"
	@echo "source $(PWD)/scripts/weather-terminal-optimization.sh"

shell-status:
	@echo "📊 Shell Integration Status:"
	@command -v wbuild >/dev/null && echo "✅ Weather functions loaded" || echo "❌ Weather functions not loaded"
	@[[ -n "$$WEATHER_PROJECT_LOADED" ]] && echo "✅ Directory hooks active" || echo "❌ Directory hooks not active"
	@[[ "$$WEATHER_TERMINAL_OPTIMIZED" == "true" ]] && echo "✅ Terminal optimized" || echo "❌ Terminal not optimized"

shell-test:
	@echo "🧪 Testing shell integration..."
	@command -v whelp >/dev/null && whelp || echo "❌ Shell functions not loaded - run 'make shell-setup'"

# Run tests with test plan
test-plan:
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-testPlan WeatherTestPlan \
		| xcbeautify

# Run performance tests only
test-performance:
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-only-testing:weatherUITests/PerformanceTests \
		-only-testing:weatherUITests/weatherUITests/testLaunchPerformance \
		-only-testing:weatherUITests/weatherUITests/testScrollPerformance \
		-only-testing:weatherUITests/weatherUITests/testMemoryPerformance \
		-only-testing:weatherTests/ServicePerformanceTests \
		| xcbeautify

# Run comprehensive performance suite
test-performance-full:
	@echo "🚀 Running comprehensive performance test suite..."
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-only-testing:weatherUITests/PerformanceTests \
		-only-testing:weatherTests/ServicePerformanceTests \
		| xcbeautify
	@echo "✅ Performance tests completed"

# Run performance tests for CI (faster subset)
test-performance-ci:
	@echo "🏃‍♂️ Running CI performance tests..."
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-only-testing:weatherUITests/PerformanceTests/testColdLaunchPerformance \
		-only-testing:weatherUITests/PerformanceTests/testMemoryUsageDuringNormalUsage \
		-only-testing:weatherUITests/PerformanceTests/testScrollingPerformance \
		-only-testing:weatherTests/ServicePerformanceTests/testCompleteStartupSequencePerformance \
		-only-testing:weatherTests/ServicePerformanceTests/testCacheLoadingPerformance \
		| xcbeautify

# Build for profiling (Instruments)
profile:
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination "$(DESTINATION)" \
		| xcbeautify
	@echo "✅ Ready for profiling with Instruments"
	@echo "   Run: open -a Instruments"

# Run memory diagnostics
memory-diagnostics:
	@chmod +x scripts/memory-diagnostics.sh
	@./scripts/memory-diagnostics.sh all

# Run memory leak detection
memory-leaks:
	@chmod +x scripts/memory-diagnostics.sh
	@./scripts/memory-diagnostics.sh leaks

# Run accessibility audit
accessibility:
	@chmod +x scripts/accessibility-audit.sh
	@./scripts/accessibility-audit.sh

# Build with sanitizers
build-sanitizers:
	xcodebuild build \
		-project $(PROJECT) \
		-scheme "weather (Debug with Sanitizers)" \
		-destination "$(DESTINATION)" \
		| xcbeautify

# Full CI pipeline
ci: clean build test

# Quality gate - run all checks before release
quality-gate: lint test-coverage analyze accessibility
	@echo "✅ All quality checks passed"

# Help
help:
	@echo "Available targets:"
	@echo ""
	@echo "  Building:"
	@echo "  clean              - Clean build artifacts and DerivedData"
	@echo "  build              - Build Debug configuration"
	@echo "  build-release      - Build Release configuration"
	@echo "  build-sanitizers   - Build with Address & Thread Sanitizers"
	@echo ""
	@echo "  Testing:"
	@echo "  test               - Run unit tests"
	@echo "  test-coverage      - Run tests with code coverage"
	@echo "  test-plan          - Run tests with test plan"
	@echo "  test-performance   - Run performance tests only"
	@echo ""
	@echo "  Analysis:"
	@echo "  lint               - Run SwiftLint"
	@echo "  analyze            - Static analysis"
	@echo "  analyze-build-times - Analyze slow compilation units"
	@echo "  analyze-size       - Analyze app bundle size"
	@echo "  accessibility      - Run accessibility audit"
	@echo "  security-scan      - Run comprehensive security scan"
	@echo ""
	@echo "  Memory:"
	@echo "  memory-diagnostics - Run all memory diagnostics"
	@echo "  memory-leaks       - Detect memory leaks with Instruments"
	@echo ""
	@echo "  Release:"
	@echo "  archive            - Create release archive"
	@echo "  export-ipa         - Export IPA for distribution"
	@echo "  profile            - Build for Instruments profiling"
	@echo "  quality-gate       - Run all checks before release"
	@echo "  prepare-release    - Prepare patch release"
	@echo "  prepare-release-minor - Prepare minor release"
	@echo "  prepare-release-major - Prepare major release"
	@echo "  release-notes      - Generate release notes from git history"
	@echo ""
	@echo "  Dependencies:"
	@echo "  update-deps        - Check dependency status"
	@echo "  update-deps-minor  - Update to latest minor versions"
	@echo "  update-deps-tools  - Update build tools only"
	@echo ""
	@echo "  Shell Integration:"
	@echo "  shell-integration  - Load weather shell functions"
	@echo "  shell-setup        - Setup advanced shell integration"
	@echo "  shell-status       - Check shell integration status"
	@echo "  shell-test         - Test shell functions"
	@echo ""
	@echo "  Setup:"
	@echo "  format             - Format code with swift-format"
	@echo "  install-hooks      - Install git pre-commit hooks"
	@echo "  setup-tools        - Install optional build tools"
	@echo "  setup-dev          - Complete development environment setup"
	@echo "  ci                 - Full CI pipeline (clean, build, test)"
