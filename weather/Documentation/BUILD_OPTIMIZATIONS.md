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
make analyze-size
# Or manually:
xcrun lipo -info build/weather.xcarchive/Products/Applications/weather.app/weather
```

## 🧪 Testing Optimization

### Test Plan

A comprehensive test plan (`WeatherTestPlan.xctestplan`) includes:

- Parallel test execution
- Code coverage for main target only
- Test retry on failure (up to 3 attempts)
- Test timeouts (60s default, 120s max)
- Multiple configurations (Default, Address Sanitizer, Thread Sanitizer)

Run with test plan:

```bash
make test-plan
```

### Performance Tests

New performance tests measure:

- **Launch Performance**: App startup time
- **Launch to Interactive**: Time until app is responsive
- **Scroll Performance**: UI smoothness
- **Memory Performance**: Memory usage during operations
- **CPU Performance**: CPU utilization

Run performance tests:

```bash
make test-performance
```

## 🚀 Launch Time Optimization

The app uses deferred initialization to improve launch time:

1. **Critical init only in `App.init()`**: Only SwiftData container creation
2. **Deferred init via `.task {}`**: Siri shortcuts registration happens after first frame

This ensures the UI appears as quickly as possible.

## 📊 Build Time Analysis

Identify slow-compiling files:

```bash
make analyze-build-times
```

This script:

- Builds with `-debug-time-function-bodies`
- Reports top 20 slowest functions
- Provides optimization tips

## 🔧 Git Hooks

Pre-commit hook for code quality:

```bash
make install-hooks
```

The hook runs:

- SwiftLint on staged files
- Checks for print statements
- Warns about force unwraps
- Reports TODO/FIXME counts

## 📈 Monitoring Build Times

Track build times in Xcode:

1. Go to **Xcode > Settings > Locations**
2. Click "DerivedData" arrow
3. Use **Product > Perform Action > Build With Timing Summary**

Or in terminal:

```bash
defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES
```

## 🎯 Profiling

Build for Instruments profiling:

```bash
make profile
```

Then open Instruments to analyze:

- Time Profiler (CPU usage)
- Allocations (memory)
- Leaks (memory leaks)
- Core Animation (UI performance)
- Network (API calls)

## 🚀 Quick Start

1. Install build tools: `make setup-tools`
2. Install git hooks: `make install-hooks`
3. Build the app: `make build`
4. Run tests: `make test`
5. Analyze build times: `make analyze-build-times`
6. Create release build: `make build-release`

## 📋 All Available Make Targets

```bash
make help
```

| Target | Description |
|--------|-------------|
| `clean` | Clean build artifacts and DerivedData |
| `build` | Build Debug configuration |
| `build-release` | Build Release configuration |
| `test` | Run unit tests |
| `test-coverage` | Run tests with code coverage |
| `test-plan` | Run tests with test plan |
| `test-performance` | Run performance tests only |
| `archive` | Create release archive |
| `export-ipa` | Export IPA for distribution |
| `lint` | Run SwiftLint |
| `format` | Format code with swift-format |
| `analyze` | Static analysis |
| `analyze-build-times` | Analyze slow compilation units |
| `analyze-size` | Analyze app bundle size |
| `profile` | Build for Instruments profiling |
| `install-hooks` | Install git pre-commit hooks |
| `ci` | Full CI pipeline (clean, build, test) |
| `setup-tools` | Install optional build tools |
