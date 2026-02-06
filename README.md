# Weather App 🌤️

A beautiful, feature-rich weather application built with SwiftUI for iOS 17+. Features real-time weather data, interactive charts, location services, favorites management, and widgets.

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## ✨ Features

| Feature | Description |
| ------- | ----------- |
| 🌍 Real-time Weather | Current conditions, hourly & 14-day forecasts via Open-Meteo API |
| 📍 Location Services | GPS detection and global city search |
| ⭐ Favorites | Save unlimited locations with SwiftData persistence |
| 📊 Interactive Charts | Temperature & precipitation graphs with touch interaction |
| 🔔 Notifications | Severe weather alerts, daily forecasts, rain warnings |
| 📱 Widgets | Home screen (S/M/L) and lock screen widgets |
| 🎨 Glass UI | Modern glass morphism design with weather animations |

---

## 🚀 Quick Start

### Requirements

- **macOS**: Ventura 14.0+
- **Xcode**: 15.0+
- **iOS**: 17.0+
- **Swift**: 5.9+

### Installation

```bash
# Clone the repository
git clone https://github.com/and3rn3t/weather-app.git
cd weather-app

# Open in Xcode
open weather.xcodeproj
```

1. Select your target device/simulator
2. Press `Cmd+R` to build and run
3. Grant location permission when prompted

---

## 📁 Project Structure

```text
weather/
├── Sources/
│   ├── App/                    # App entry point
│   ├── Views/                  # SwiftUI views
│   ├── Models/                 # Data models (Codable)
│   ├── Services/               # API integration
│   ├── Managers/               # State managers (@Observable)
│   └── Utilities/              # Visual effects & helpers
├── Assets.xcassets/            # App icons & colors
├── Documentation/              # Feature documentation
├── Info.plist                  # App configuration
└── weather.entitlements        # App capabilities
```

---

## 🤖 AI Development Assistance

This project includes custom instructions for AI coding assistants:

| Assistant | Instructions File | Purpose |
| --------- | ----------------- | ------- |
| **GitHub Copilot** | [.github/copilot-instructions.md](.github/copilot-instructions.md) | Code generation, patterns, standards |
| **Claude** | [.claude/CLAUDE.md](.claude/CLAUDE.md) | Architecture, troubleshooting, context |

These files help AI assistants understand the project's architecture, coding patterns, and conventions for more accurate suggestions.

---

## 📚 Documentation

### Core Guides

| Document | Description |
| -------- | ----------- |
| [QUICK_START.md](weather/Documentation/QUICK_START.md) | Setup and integration guide |
| [FEATURES.md](weather/Documentation/FEATURES.md) | Complete feature documentation |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |

### Reference

| Document | Description |
| -------- | ----------- |
| [CHANGELOG.md](weather/Documentation/CHANGELOG.md) | Version history |
| [BUILD_FIXES.md](weather/Documentation/BUILD_FIXES.md) | Troubleshooting |
| [BUILD_OPTIMIZATIONS.md](weather/Documentation/BUILD_OPTIMIZATIONS.md) | Build & performance optimization |
| [VISUAL_FEATURE_MAP.md](weather/Documentation/VISUAL_FEATURE_MAP.md) | UI component reference |

---

## 🏗️ Architecture

### Tech Stack

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Persistent storage
- **Swift Charts** - Data visualization
- **WidgetKit** - Home & lock screen widgets
- **CoreLocation** - GPS and location services
- **MapKit** - Location search

### Design Patterns

- **MVVM** - Model-View-ViewModel architecture
- **@Observable** - Modern reactive state management
- **async/await** - Swift concurrency
- **Environment injection** - Dependency management

---

## 🔧 Configuration

### Required Info.plist Keys

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show weather for your area</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to show weather and send alerts</string>
```

---

## 🧪 Testing

Run tests in Xcode with `Cmd+U` or use the Makefile:

```bash
# Run all tests
make test

# Run tests with code coverage
make test-coverage

# Run with test plan (parallel, sanitizers)
make test-plan

# Run performance tests only
make test-performance
```

- Unit tests: `weatherTests/`
- UI tests: `weatherUITests/`
- Test plan: `weather.xcodeproj/xcshareddata/TestPlans/WeatherTestPlan.xctestplan`

---

## 🏗️ Build & Development

### Makefile Commands

The project includes a Makefile for common development tasks:

```bash
# Build
make build              # Debug build
make build-release      # Release build
make clean              # Clean DerivedData

# Testing
make test               # Run all tests
make test-coverage      # Tests with coverage
make test-plan          # Use test plan
make test-performance   # Performance tests only

# Code Quality
make lint               # Run SwiftLint
make format             # Format with swift-format
make analyze            # Static analysis

# Release
make archive            # Create archive
make export-ipa         # Export for App Store

# Analysis
make analyze-build-times  # Find slow compilation
make analyze-size         # App bundle size analysis
make profile              # Build for Instruments

# Setup
make setup-tools        # Install build tools
make install-hooks      # Install git hooks
```

### Performance Optimizations

The app includes several performance optimizations:

- **Cached URLSession**: Network requests use a shared session with 10MB memory / 50MB disk cache
- **Static Formatters**: Number and date formatters are cached to avoid repeated allocations
- **Request Debouncing**: API calls are debounced to prevent excessive requests
- **Deferred Initialization**: Non-critical init (Siri shortcuts) is deferred after first frame

See [BUILD_OPTIMIZATIONS.md](weather/Documentation/BUILD_OPTIMIZATIONS.md) for details.

---

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) for:

- Development environment setup
- Code style guidelines
- Pull request process
- Testing requirements

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details

---

## 🙏 Acknowledgments

- Weather data provided by [Open-Meteo](https://open-meteo.com/) (free, no API key required)
- Icons from SF Symbols
