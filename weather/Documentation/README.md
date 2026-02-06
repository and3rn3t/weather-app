# Andernet Weather - Documentation

Welcome to the Andernet Weather documentation. This folder contains all guides and references for developing and maintaining the app.

## Quick Links

| Document | Purpose |
|----------|---------|
| [QUICK_START.md](QUICK_START.md) | Getting started, build commands, project setup |
| [FEATURES.md](FEATURES.md) | App features and functionality |
| [BUILD_CONFIGURATION.md](BUILD_CONFIGURATION.md) | Xcode settings, schemes, build phases, diagnostics |
| [AI_DEVELOPMENT_GUIDE.md](AI_DEVELOPMENT_GUIDE.md) | Instructions for AI coding assistants |
| [APP_STORE_GUIDE.md](APP_STORE_GUIDE.md) | App Store metadata and screenshots |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

## Also See

- [Main README](../../README.md) - Project overview
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
- [.github/copilot-instructions.md](../../.github/copilot-instructions.md) - GitHub Copilot config
- [.claude/CLAUDE.md](../../.claude/CLAUDE.md) - Claude AI config

## Architecture Overview

```
weather/
├── Sources/
│   ├── App/           # Entry point (weatherApp.swift)
│   ├── Views/         # SwiftUI views
│   ├── Models/        # Data models (Codable structs)
│   ├── Services/      # API services (WeatherService)
│   ├── Managers/      # State managers (@Observable)
│   └── Utilities/     # Helpers (GlassEffects, etc.)
├── Assets.xcassets/   # Images, colors, icons
└── Documentation/     # You are here
```

## Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI 5.0 |
| Data Persistence | SwiftData |
| Charts | Swift Charts |
| Location | CoreLocation, MapKit |
| Widgets | WidgetKit, AppIntents |
| Target | iOS 17.0+ |

## API

**Open-Meteo** - Free weather API, no key required.

- Endpoint: `https://api.open-meteo.com/v1/forecast`
- Rate limit: 60 requests/minute
- Global coverage

## Common Tasks

### Build & Test

```bash
make build              # Debug build
make test               # Run tests
make lint               # SwiftLint check
```

### Release

```bash
make build-release      # Optimized build
make archive            # Create archive
make export-ipa         # Export for App Store
```

### Analysis

```bash
make analyze            # Static analysis
make accessibility      # Accessibility audit
make memory-diagnostics # Memory profiling
```

See [BUILD_CONFIGURATION.md](BUILD_CONFIGURATION.md) for complete reference.
