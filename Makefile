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

# Full CI pipeline
ci: clean build test

# Help
help:
	@echo "Available targets:"
	@echo "  clean          - Clean build artifacts and DerivedData"
	@echo "  build          - Build Debug configuration"
	@echo "  build-release  - Build Release configuration"
	@echo "  test           - Run unit tests"
	@echo "  test-coverage  - Run tests with code coverage"
	@echo "  archive        - Create release archive"
	@echo "  export-ipa     - Export IPA for distribution"
	@echo "  lint           - Run SwiftLint"
	@echo "  format         - Format code with swift-format"
	@echo "  analyze        - Static analysis"
	@echo "  ci             - Full CI pipeline (clean, build, test)"
	@echo "  setup-tools    - Install optional build tools"
