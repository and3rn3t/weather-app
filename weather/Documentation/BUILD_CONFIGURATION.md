# Build & Xcode Configuration Guide

This document describes all Xcode settings, build configurations, and optimization strategies for Andernet Weather.

## Table of Contents

1. [Build Configurations](#build-configurations)
2. [xcconfig Files](#xcconfig-files)
3. [Schemes](#schemes)
4. [Performance Optimizations](#performance-optimizations)
5. [Memory Diagnostics](#memory-diagnostics)
6. [Accessibility](#accessibility)
7. [Troubleshooting](#troubleshooting)

---

## Build Configurations

### Debug Configuration

Optimized for fast builds and debugging:

| Setting | Value | Purpose |
|---------|-------|---------|
| `SWIFT_OPTIMIZATION_LEVEL` | `-Onone` | No optimization for debuggability |
| `ONLY_ACTIVE_ARCH` | `YES` | Build only for current device |
| `SWIFT_COMPILATION_MODE` | `singlefile` | Faster incremental builds |
| `GCC_OPTIMIZATION_LEVEL` | `0` | No C/ObjC optimization |

### Release Configuration

Optimized for App Store distribution:

| Setting | Value | Purpose |
|---------|-------|---------|
| `SWIFT_OPTIMIZATION_LEVEL` | `-O` | Size optimization |
| `LLVM_LTO` | `YES_THIN` | Link-Time Optimization |
| `DEAD_CODE_STRIPPING` | `YES` | Remove unused code |
| `STRIP_SWIFT_SYMBOLS` | `YES` | Strip debug symbols |
| `ASSETCATALOG_COMPILER_OPTIMIZATION` | `space` | Optimize asset size |
| `SWIFT_COMPILATION_MODE` | `wholemodule` | Better optimization |

---

## xcconfig Files

Configuration files are located in `Configurations/`:

### Debug.xcconfig

```
// Import shared warnings
#include "Warnings.xcconfig"

// Debug-specific settings
SWIFT_OPTIMIZATION_LEVEL = -Onone
ONLY_ACTIVE_ARCH = YES
GCC_PREPROCESSOR_DEFINITIONS = DEBUG=1
```

### Release.xcconfig

```
// Import shared warnings
#include "Warnings.xcconfig"

// Release optimizations
LLVM_LTO = YES_THIN
DEAD_CODE_STRIPPING = YES
STRIP_SWIFT_SYMBOLS = YES
```

### Warnings.xcconfig

Shared compiler warnings configuration with strict concurrency enabled.

### Linking to Project

To link xcconfig files to your Xcode project:

1. Open project in Xcode
2. Select project in navigator
3. Select project (not target) in editor
4. Go to "Info" tab
5. Under "Configurations", set:
   - Debug → `Configurations/Debug.xcconfig`
   - Release → `Configurations/Release.xcconfig`

---

## Schemes

### Available Schemes

| Scheme | Purpose |
|--------|---------|
| `weather` | Standard development |
| `weather (Debug with Sanitizers)` | Memory/thread debugging |
| `weather (Profile)` | Instruments profiling |
| `Andernet Weather WidgetExtension` | Widget development |

### Debug with Sanitizers Scheme

Enables:

- **Address Sanitizer**: Detects memory corruption
- **Thread Sanitizer**: Detects data races
- **Stack after return**: Extended memory checking

Use for pre-release testing to catch memory issues.

### Profile Scheme

- Builds with Release optimization
- No debugger attached (accurate performance)
- Pre-configured for Instruments Time Profiler

---

## Performance Optimizations

### Code-Level Optimizations

#### 1. Cached URLSession

```swift
private static let cachedSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
    return URLSession(configuration: config)
}()
```

#### 2. Static Formatters

```swift
private static let temperatureFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 0
    return formatter
}()
```

#### 3. Request Debouncing

API requests are debounced with 60-second minimum intervals to prevent excessive calls.

#### 4. Deferred Initialization

Non-critical initialization (Siri shortcuts) is deferred to after first frame with `.task {}`.

### Build-Time Optimizations

#### Analyze Slow Compilation

```bash
make analyze-build-times
```

This identifies functions that take >100ms to compile.

#### Analyze Binary Size

```bash
make analyze-size
```

---

## Memory Diagnostics

### Quick Commands

```bash
# Run all memory diagnostics
make memory-diagnostics

# Detect memory leaks
make memory-leaks
```

### Manual Profiling

1. **Memory Graph**:
   - Run app in Xcode
   - Debug → Capture Memory Graph
   - Analyze object references

2. **Leaks Instrument**:
   - Product → Profile → Leaks
   - Interact with app
   - Review leak reports

3. **Allocations Instrument**:
   - Product → Profile → Allocations
   - Monitor memory growth
   - Identify retain cycles

### Zombie Objects

Enable in scheme's Run settings:

- `NSZombieEnabled = YES`
- `MallocScribble = YES`

---

## Accessibility

### Run Accessibility Audit

```bash
make accessibility
```

### Manual Testing

1. **Accessibility Inspector**:
   - Xcode → Open Developer Tool → Accessibility Inspector
   - Run audit on simulator

2. **VoiceOver Testing**:
   - Enable in Simulator: Settings → Accessibility → VoiceOver
   - Navigate entire app
   - Verify announcements

3. **Environment Overrides**:
   In Xcode debugger:
   - Bold Text
   - Larger Accessibility Sizes
   - Reduce Motion
   - Increase Contrast

### Accessibility Checklist

- [ ] All buttons have `accessibilityLabel`
- [ ] Images have labels or `decorative` role
- [ ] Charts have alternative text
- [ ] Dynamic Type supported
- [ ] Contrast ratios ≥ 4.5:1
- [ ] Touch targets ≥ 44pt

---

## Troubleshooting

### Build Failures

```bash
# Clean and rebuild
make clean
make build
```

### Tests Hanging

Check for:

- Network requests without timeout
- Infinite loops
- Deadlocks (use Thread Sanitizer)

### Performance Issues

1. Profile with Instruments:

   ```bash
   make profile
   ```

2. Check for:
   - Main thread blocking
   - Excessive allocations
   - Retain cycles

### Memory Warnings

1. Run memory diagnostics:

   ```bash
   make memory-leaks
   ```

2. Check for:
   - Unbounded caches
   - Strong reference cycles
   - Large image allocations

---

## Custom Build Phases

Available build phase scripts in `scripts/build-phases/`:

### SwiftLint (`swiftlint.sh`)

Runs SwiftLint on every build to catch style violations early.

**To add in Xcode:**

1. Select project → target "weather" → Build Phases
2. Click + → New Run Script Phase
3. Name it "SwiftLint"
4. Add: `"${SRCROOT}/scripts/build-phases/swiftlint.sh"`
5. Move it AFTER "Compile Sources"

### TODO Warnings (`todo-warnings.sh`)

Converts TODO/FIXME comments to Xcode warnings so they appear in the Issue Navigator.

**Script content:**

```bash
"${SRCROOT}/scripts/build-phases/todo-warnings.sh"
```

### Git Info (`git-info.sh`)

Injects git commit hash and branch into a `BuildInfo.swift` file for debugging.

**Usage in code:**

```swift
Text("Version: \(BuildInfo.description)")
// Output: "main@abc1234 (Debug)"
```

### Increment Build Number (`increment-build.sh`)

Auto-increments build number for Release/Archive builds.

**Position:** BEFORE "Compile Sources" (runs early in build)

### Archive dSYM (`archive-dsym.sh`)

Archives dSYM files for crash report symbolication.

**Settings:**

- Check "Run script only when installing"
- Output: `build/dSYMs/weather-X.X-XXX.dSYM.zip`

---

## Network Link Conditioner

Custom network profiles for testing poor network conditions.

### Available Profiles

Located in `NetworkProfiles/`:

| Profile | Use Case |
|---------|----------|
| `VerySlow2G.nlcprofile` | 50 Kbps, 2s latency, 5% loss - Rural/elevator testing |
| `LossyNetwork.nlcprofile` | 5 Mbps, 100ms latency, 15% loss - WiFi interference |
| `HighLatency.nlcprofile` | 10 Mbps, 800ms latency - Satellite connections |

### Installation

**macOS:**

1. Install Network Link Conditioner from "Additional Tools for Xcode"
2. Double-click any `.nlcprofile` to install
3. Open System Preferences → Network Link Conditioner

**iOS Simulator:**

1. Profiles work automatically when running on Mac
2. Enable in Simulator: Features → Network Link Conditioner

**Physical iOS Device:**

1. Enable Developer Mode in Settings
2. Settings → Developer → Network Link Conditioner
3. Add Profile → select from Files

### Testing Checklist

Test these scenarios with each profile:

- [ ] App launches without hanging
- [ ] Loading indicators appear promptly  
- [ ] Timeout errors show user-friendly messages
- [ ] Cached data displays while loading
- [ ] Pull-to-refresh works correctly
- [ ] No duplicate API requests

---

## Make Targets Reference

| Target | Description |
|--------|-------------|
| `make build` | Debug build |
| `make build-release` | Release build |
| `make build-sanitizers` | Build with sanitizers |
| `make test` | Run unit tests |
| `make test-coverage` | Tests with coverage |
| `make test-plan` | Tests with test plan |
| `make test-performance` | Performance tests |
| `make lint` | Run SwiftLint |
| `make analyze` | Static analysis |
| `make analyze-build-times` | Compilation profiling |
| `make analyze-size` | Binary size analysis |
| `make accessibility` | Accessibility audit |
| `make memory-diagnostics` | Memory analysis |
| `make memory-leaks` | Leak detection |
| `make profile` | Build for Instruments |
| `make archive` | Create archive |
| `make export-ipa` | Export IPA |
| `make quality-gate` | All pre-release checks |
| `make ci` | Full CI pipeline |
| `make install-hooks` | Git hooks |
| `make setup-tools` | Install dependencies |
