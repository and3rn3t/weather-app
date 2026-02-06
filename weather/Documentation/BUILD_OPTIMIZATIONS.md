# Build Process & Performance Optimizations

This document outlines all build process improvements and performance optimizations implemented in the Andernet Weather app.

## 🏗️ Build Process Improvements

### 1. Makefile Automation

A `Makefile` has been added with common build tasks:

```bash
# Available commands
make build          # Build Debug configuration
make build-release  # Build Release configuration
make test           # Run unit tests
make test-coverage  # Run tests with code coverage
make clean          # Clean build artifacts and DerivedData
make lint           # Run SwiftLint
make format         # Format code with swift-format
make analyze        # Static analysis
make archive        # Create release archive
make export-ipa     # Export IPA for distribution
make ci             # Full CI pipeline (clean, build, test)
```

### 2. GitHub Actions CI/CD

Automated CI/CD pipeline (`.github/workflows/ci.yml`) includes:

- **Build & Test**: Runs on every PR and push to main
- **SwiftLint**: Code quality checks
- **Release Build**: Builds release configuration on main branch
- **Build Size Analysis**: Reports app bundle size
- **DerivedData Caching**: Speeds up subsequent builds

### 3. Build Configuration (weather.xcconfig)

Optional build configuration file with:

- Dead code stripping (`DEAD_CODE_STRIPPING = YES`)
- Asset catalog optimization (`ASSETCATALOG_COMPILER_OPTIMIZATION = space`)
- Documentation for LTO (Link-Time Optimization)

## ⚡ Performance Optimizations

### 1. Network Layer Optimizations

**WeatherService.swift**:

- **Cached URLSession**: Shared session with 10MB memory / 50MB disk cache
- **Static JSONDecoder**: Reuses a single decoder instance (creating decoders is expensive)
- **Request Debouncing**: 60-second minimum interval between API calls
- **Force Refresh Option**: `forceRefresh: true` bypasses debounce when needed

```swift
// Cached session configuration
config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
config.requestCachePolicy = .returnCacheDataElseLoad
config.timeoutIntervalForRequest = 15
config.timeoutIntervalForResource = 30
```

### 2. Formatter Caching

**SettingsManager.swift**:

- Static cached `NumberFormatter` instances for temperature, wind speed, precipitation
- Static cached `ISO8601DateFormatter` for date parsing
- Avoids creating new formatters on every view update

```swift
private static let temperatureFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter
}()
```

### 3. Existing Build Settings (Already Configured)

Your project already has these optimizations:

- ✅ `BuildIndependentTargetsInParallel = 1` - Parallel target builds
- ✅ `SWIFT_COMPILATION_MODE = wholemodule` (Release) - Whole module optimization
- ✅ `ONLY_ACTIVE_ARCH = YES` (Debug) - Faster debug builds
- ✅ `SWIFT_OPTIMIZATION_LEVEL = -Onone` (Debug) - No optimization for faster builds
- ✅ `DEBUG_INFORMATION_FORMAT = dwarf` (Debug) - Faster than dwarf-with-dsym
- ✅ `MTL_FAST_MATH = YES` - Metal shader optimizations

## 📊 Recommended Additional Optimizations

### For Production Release

Add these settings in Xcode's Build Settings for Release:

1. **Enable Link-Time Optimization (LTO)**:

   ```
   LLVM_LTO = YES (or Thin)
   ```

   *Note: Increases build time but produces smaller, faster binaries*

2. **Strip Debug Symbols**:

   ```
   STRIP_INSTALLED_PRODUCT = YES
   STRIP_STYLE = non-global
   ```

3. **Bitcode** (if targeting App Store):

   ```
   ENABLE_BITCODE = YES
   ```

### SwiftUI View Performance

Best practices already in use:

- ✅ Breaking views into small components
- ✅ Using `@State` for local state
- ✅ Using `@Environment` for shared managers
- ✅ `.id()` modifier for controlled re-renders
- ✅ `LazyVStack`/`LazyHStack` for large lists (where applicable)

### Additional View Optimization Tips

1. **Use `.equatable()` on views that don't need frequent updates**:

   ```swift
   MyStaticCard()
       .equatable()
   ```

2. **Mark body as `@ViewBuilder` when returning multiple view types**:
   Already implemented in many views.

3. **Use `.drawingGroup()` for complex graphics**:
   For views with many layers, mesh gradients, or custom drawing.

## 🔧 Development Tools

Install recommended tools:

```bash
make setup-tools
```

This installs:

- `xcbeautify` - Better Xcode build output
- `swiftlint` - Swift code linting

## 📱 App Size Optimization

Current size optimizations:

- Asset catalog compression
- Dead code stripping
- No external dependencies (pure Apple frameworks)

To analyze app size:

```bash
# After archive
xcrun lipo -info build/weather.xcarchive/Products/Applications/weather.app/weather
```

## 🧪 Testing Performance

Run tests with timing:

```bash
xcodebuild test -project weather.xcodeproj -scheme weather \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -parallel-testing-enabled YES 2>&1 | xcbeautify
```

## 📈 Monitoring Build Times

Track build times in Xcode:

1. Go to **Xcode > Settings > Locations**
2. Click "DerivedData" arrow
3. Use **Product > Perform Action > Build With Timing Summary**

Or in terminal:

```bash
defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES
```

## 🚀 Quick Start

1. Install build tools: `make setup-tools`
2. Build the app: `make build`
3. Run tests: `make test`
4. Create release build: `make build-release`
