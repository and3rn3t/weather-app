# GitHub Copilot Instructions — Weather App

SwiftUI weather app for iOS 26+ with an Android companion (`android-app/`). Full conventions, patterns and restrictions live in [`.claude/CLAUDE.md`](../.claude/CLAUDE.md); this file is the short version.

## Stack

Swift, SwiftUI, SwiftData, Swift Charts, WidgetKit, App Intents, CoreLocation/MapKit. MVVM with `@Observable`. Data from Open-Meteo (no key), NWS alerts (US), Tomorrow.io pollen (optional key in gitignored `APIConfig.swift`).

## Layout

```text
weather/Sources/
├── App/  Views/ (Cards, Components, Loading)  Models/  Services/  Managers/  Intents/  Utilities/
weatherTests/  weatherUITests/  android-app/  docs/  scripts/
```

## Conventions

- `@Observable` managers, never `ObservableObject`/`@Published`; `async/await` for all async work
- `@State` for local state, `@Environment` for shared managers
- Use `any Error`, not bare `Error`; user-friendly error messages
- All Open-Meteo calls go through `WeatherService.swift`; models in `WeatherModels.swift`
- Types `PascalCase`, members `camelCase`, booleans prefixed `is`/`has`/`should`; `// MARK: -` sections; 4-space indent, ~120 col lines
- Glass cards: `.ultraThinMaterial`, 30%-opacity white border, 16-24pt radius
- Cache formatters as `static let`; never create them in loops or computed properties; reuse the cached `URLSession`
- Keep accessibility labels and dark mode support
- Apple frameworks only — no third-party dependencies

## Build and test

Use the Makefile, not `xcodebuild`: `make build`, `make test`, `make lint`, `make format`, `make quality-gate` (`make help` for all).

## Do not

- Break existing tests or remove accessibility features
- Hardcode keys or secrets
- Use deprecated APIs

For features that exist on both platforms, consider the Android implementation too. CI/CD details: [`CI_CD_GUIDE.md`](CI_CD_GUIDE.md).
