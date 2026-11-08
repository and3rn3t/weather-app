# Weather App 🌤️

A SwiftUI weather app for iOS 26 with an Android companion. Forecasts from [Open-Meteo](https://open-meteo.com/) (no API key), US severe-weather alerts from the National Weather Service, optional pollen data from Tomorrow.io, widgets, and a Liquid Glass UI.

![iOS](https://img.shields.io/badge/iOS-26.0%2B-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

| Feature | Description |
| ------- | ----------- |
| 🌍 Weather | Current conditions, hourly and 14-day forecasts, air quality, UV, sun/moon |
| 📍 Locations | GPS detection, global city search, saved favorites (SwiftData) |
| 📊 Charts | Temperature and precipitation graphs (Swift Charts) |
| 🔔 Notifications | Severe weather alerts, daily forecasts, rain warnings |
| 📱 Widgets | Home screen and lock screen widgets, Live Activities, Siri shortcuts |
| 🎨 Glass UI | Liquid Glass design with weather animations |

## 🚀 Getting started

Requirements: macOS 15.6+ (Tahoe 26 recommended), Xcode 26+, iOS 26+ device or simulator.

```bash
git clone https://github.com/and3rn3t/weather-app.git
cd weather-app
make setup-tools                 # installs xcbeautify, swiftlint
open weather.xcodeproj           # Cmd+R to build and run
```

Optional: for pollen data, copy `weather/Sources/Services/APIConfig.swift.template` to `APIConfig.swift` and add a free [Tomorrow.io](https://www.tomorrow.io/weather-api/) key. The file is gitignored.

## 🛠️ Development

Use the Makefile (run `make help` for all targets):

```bash
make build            # debug build
make test             # unit tests
make test-coverage    # tests with coverage
make test-plan        # parallel + sanitizers
make lint             # SwiftLint
make format           # swift-format
make quality-gate     # all pre-release checks
```

Tests live in `weatherTests/` and `weatherUITests/`; the test plan is `weather.xcodeproj/xcshareddata/TestPlans/WeatherTestPlan.xctestplan`.

### Project structure

```text
weather/Sources/
├── App/         # Entry point
├── Views/       # SwiftUI views (Cards/, Components/, Loading/)
├── Models/      # Codable models
├── Services/    # Open-Meteo, NWS alerts, Tomorrow.io
├── Managers/    # @Observable state (location, favorites, settings, cache, ...)
├── Intents/     # App Intents / Siri
└── Utilities/   # Glass effects, helpers
android-app/     # Kotlin + Jetpack Compose companion app
docs/            # GitHub Pages site (privacy, support)
scripts/         # Build, release and analysis scripts
```

Architecture: MVVM with `@Observable`, async/await, SwiftData persistence, environment injection.

## 📚 More documentation

- [Contributing guide](CONTRIBUTING.md)
- [Android app](android-app/README.md)
- [CI/CD guide](.github/CI_CD_GUIDE.md)
- [Security policy](SECURITY.md)
- [Privacy policy](docs/PRIVACY_POLICY.md) · [Support](docs/SUPPORT.md) · [Site](https://and3rn3t.github.io/weather-app/)
- AI assistant context: [.claude/CLAUDE.md](.claude/CLAUDE.md), [.github/copilot-instructions.md](.github/copilot-instructions.md)

## 📄 License

MIT — see [LICENSE](LICENSE). Weather data by [Open-Meteo](https://open-meteo.com/); icons from SF Symbols.
