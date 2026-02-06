# Andernet Weather - Build Automation
# Usage: make [target]

SCHEME = weather
PROJECT = weather.xcodeproj
CONFIGURATION_DEBUG = Debug
CONFIGURATION_RELEASE = Release
DESTINATION = platform=iOS Simulator,name=iPhone 16 Pro

.PHONY: clean build test archive lint format

# Clean build artifacts
clean:
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION_DEBUG)
	rm -rf ~/Library/Developer/Xcode/DerivedData/weather-*
	@echo "✅ Clean complete"

# Build for Debug
build:
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION_DEBUG) \
		-destination "$(DESTINATION)" \
		| xcbeautify

# Build for Release
build-release:
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION_RELEASE) \
		-destination "$(DESTINATION)" \
		| xcbeautify

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
	xcodebuild archive \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION_RELEASE) \
		-archivePath build/weather.xcarchive \
		| xcbeautify

# Export IPA from archive
export-ipa: archive
	xcodebuild -exportArchive \
		-archivePath build/weather.xcarchive \
		-exportPath build/ipa \
		-exportOptionsPlist ExportOptions.plist \
		| xcbeautify
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
		-only-testing:weatherUITests/weatherUITests/testLaunchPerformance \
		-only-testing:weatherUITests/weatherUITests/testScrollPerformance \
		-only-testing:weatherUITests/weatherUITests/testMemoryPerformance \
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

# Full CI pipeline
ci: clean build test

# Help
help:
	@echo "Available targets:"
	@echo "  clean              - Clean build artifacts and DerivedData"
	@echo "  build              - Build Debug configuration"
	@echo "  build-release      - Build Release configuration"
	@echo "  test               - Run unit tests"
	@echo "  test-coverage      - Run tests with code coverage"
	@echo "  test-plan          - Run tests with test plan"
	@echo "  test-performance   - Run performance tests only"
	@echo "  archive            - Create release archive"
	@echo "  export-ipa         - Export IPA for distribution"
	@echo "  lint               - Run SwiftLint"
	@echo "  format             - Format code with swift-format"
	@echo "  analyze            - Static analysis"
	@echo "  analyze-build-times - Analyze slow compilation units"
	@echo "  analyze-size       - Analyze app bundle size"
	@echo "  profile            - Build for Instruments profiling"
	@echo "  install-hooks      - Install git pre-commit hooks"
	@echo "  ci                 - Full CI pipeline (clean, build, test)"
	@echo "  setup-tools        - Install optional build tools"
