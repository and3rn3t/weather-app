# Quick Start Guide

Get the Andernet Weather app running in minutes.

## Prerequisites

```bash
# Install build tools
make setup-tools

# Install git hooks (optional but recommended)
make install-hooks
```

## Build & Run

```bash
# Clone and open
git clone https://github.com/and3rn3t/weather-app.git
cd weather-app
open weather.xcodeproj

# Or build from command line
make build
```

### In Xcode

1. Select target device/simulator
2. Press **Cmd+R** to build and run
3. Grant location permission when prompted
4. Grant notification permission (optional)

## Build Commands

| Command | Description |
|---------|-------------|
| `make build` | Debug build |
| `make build-release` | Release build (optimized) |
| `make test` | Run all tests |
| `make test-coverage` | Tests with code coverage |
| `make lint` | Run SwiftLint |
| `make clean` | Clean build artifacts |

## Project Structure

```
weather/
├── Sources/
│   ├── App/weatherApp.swift       # Entry point
│   ├── Views/                     # SwiftUI views
│   ├── Models/                    # Data models
│   ├── Services/WeatherService.swift
│   ├── Managers/                  # @Observable managers
│   └── Utilities/                 # Helpers
├── Assets.xcassets/               # Images & colors
└── Documentation/                 # Docs
```

## Key Files

| File | Purpose |
|------|---------|
| `weatherApp.swift` | App entry, dependency injection |
| `ContentView.swift` | Main navigation |
| `WeatherDetailView.swift` | Weather display |
| `WeatherService.swift` | API integration |
| `LocationManager.swift` | GPS services |
| `SettingsManager.swift` | User preferences |

## Configuration

### Info.plist (already configured)

- Location usage descriptions
- Background modes (fetch, notifications)
- Siri integration
- Live Activities support

### API

Uses [Open-Meteo](https://open-meteo.com) - free, no API key needed.

## Verify Installation

Run through this checklist:

- [ ] App launches
- [ ] Location permission works
- [ ] Weather data loads
- [ ] Search finds locations
- [ ] Pull-to-refresh updates data
- [ ] Settings persist

## Common Issues

### Build Errors

```bash
make clean
make build
```

### SwiftData Issues

Ensure iOS deployment target is 17.0+.

### Widget Not Appearing

1. Run widget target specifically
2. Restart simulator

## Next Steps

- See [FEATURES.md](FEATURES.md) for feature details
- See [BUILD_CONFIGURATION.md](BUILD_CONFIGURATION.md) for Xcode settings
- See [AI_DEVELOPMENT_GUIDE.md](AI_DEVELOPMENT_GUIDE.md) for coding patterns

## AI Assistance

This project includes instructions for AI coding assistants:

- **GitHub Copilot**: [.github/copilot-instructions.md](../../.github/copilot-instructions.md)
- **Claude**: [.claude/CLAUDE.md](../../.claude/CLAUDE.md)

Enable these for better code suggestions that follow project conventions.
