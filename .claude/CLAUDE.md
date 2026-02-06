# Claude AI Instructions for Weather App

## Project Identity

**Weather App** - A feature-rich iOS weather application built with SwiftUI for iOS 17+. Uses Open-Meteo API for weather data (no API key required).

## Quick Reference

| Aspect | Details |
|--------|---------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI 5.0 |
| iOS Target | 17.0+ |
| Architecture | MVVM + Observable |
| Data Storage | SwiftData |
| Charts | Swift Charts |
| Weather API | Open-Meteo (free) |

## Directory Structure

```
weather/
├── Sources/
│   ├── App/weatherApp.swift          # Entry point
│   ├── Views/                         # SwiftUI views
│   │   ├── ContentView.swift          # Main coordinator
│   │   ├── WeatherDetailView.swift    # Weather display
│   │   ├── FavoritesView.swift        # Saved locations
│   │   ├── SettingsView.swift         # App settings
│   │   ├── LocationSearchView.swift   # Location search
│   │   └── WeatherWidget.swift        # Widget definitions
│   ├── Models/
│   │   ├── WeatherModels.swift        # API response types
│   │   └── Models.swift               # App domain models
│   ├── Services/
│   │   └── WeatherService.swift       # API integration
│   ├── Managers/
│   │   ├── LocationManager.swift      # GPS/location
│   │   ├── FavoritesManager.swift     # Saved locations
│   │   ├── SettingsManager.swift      # User preferences
│   │   └── NotificationManager.swift  # Alerts
│   └── Utilities/
│       ├── GlassEffects.swift         # Visual effects
│       └── WeatherParticleEffects.swift # Animations
├── Documentation/                      # Feature docs
└── Assets.xcassets/                   # Resources
```

## Coding Patterns

### Observable Manager Pattern

```swift
@Observable
final class ExampleManager {
    private(set) var data: [Item] = []
    var isLoading = false
    
    func fetch() async throws {
        isLoading = true
        defer { isLoading = false }
        data = try await service.getData()
    }
}
```

### SwiftUI View Pattern

```swift
struct ExampleView: View {
    @Environment(LocationManager.self) private var locationManager
    @State private var showSheet = false
    
    var body: some View {
        content
            .sheet(isPresented: $showSheet) { SheetView() }
    }
    
    private var content: some View {
        // View implementation
    }
}
```

### API Service Pattern

```swift
final class WeatherService {
    static let shared = WeatherService()
    private let baseURL = "https://api.open-meteo.com/v1"
    
    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherData {
        let url = URL(string: "\(baseURL)/forecast?latitude=\(lat)&longitude=\(lon)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WeatherData.self, from: data)
    }
}
```

## Key Implementation Details

### Weather Data Flow

1. `LocationManager` provides coordinates
2. `WeatherService.fetchWeather()` calls Open-Meteo API
3. Response decoded into `WeatherData` model
4. Views observe and display data

### Glass Morphism UI

- Cards use `.ultraThinMaterial` background
- Subtle white borders at 30% opacity
- Corner radius: 16-24pt
- Shadow: 10pt blur, 5pt offset

### Temperature Formatting

```swift
// Fahrenheit (default)
"\(Int(temp))°F"

// Celsius conversion
"\(Int((temp - 32) * 5/9))°C"
```

## When Making Changes

### Adding New Features

1. Check if related manager exists in `Sources/Managers/`
2. Add models to `Sources/Models/` if needed
3. Create views in `Sources/Views/`
4. Update navigation in `ContentView.swift`
5. Document in `Documentation/CHANGELOG.md`

### Modifying Existing Features

1. Read the relevant documentation first
2. Check for environment dependencies
3. Maintain existing accessibility labels
4. Test both light and dark modes
5. Verify on multiple device sizes

### API Changes

1. All API code lives in `WeatherService.swift`
2. Response models in `WeatherModels.swift`
3. Use `async throws` pattern
4. Handle errors with user-friendly messages

## Build Process

### Makefile Commands

Always use the Makefile for consistent builds:

```bash
# Building
make build              # Debug build
make build-release      # Release build (optimized)
make clean              # Clean DerivedData and build artifacts

# Testing
make test               # Run all tests
make test-coverage      # Tests with code coverage
make test-plan          # Use test plan (parallel, sanitizers)
make test-performance   # Performance tests only

# Code Quality
make lint               # Run SwiftLint
make format             # Format with swift-format
make analyze            # Static analysis

# Release
make archive            # Create release archive
make export-ipa         # Export IPA for App Store

# Analysis
make analyze-build-times  # Identify slow-compiling files
make analyze-size         # Analyze app bundle size
make profile              # Build for Instruments profiling

# Setup
make setup-tools        # Install xcbeautify, swiftlint
make install-hooks      # Install git pre-commit hooks
```

### Performance Optimizations

The codebase follows these performance patterns:

1. **Static Formatters** - Formatters are cached as static properties:

   ```swift
   private static let temperatureFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
       formatter.maximumFractionDigits = 0
       return formatter
   }()
   ```

2. **Cached URLSession** - Network requests use shared session with caching:

   ```swift
   private static let cachedSession: URLSession = {
       let config = URLSessionConfiguration.default
       config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
       return URLSession(configuration: config)
   }()
   ```

3. **Request Debouncing** - API calls have minimum 60-second intervals

4. **Deferred Initialization** - Non-critical init uses `.task {}` after first frame

## Style Guidelines

### Code Formatting

- 4-space indentation
- Line length: prefer < 120 characters
- Use `// MARK: -` for section organization
- Alphabetize imports

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Types | PascalCase | `WeatherCard` |
| Variables | camelCase | `currentTemp` |
| Booleans | is/has/should prefix | `isLoading` |
| Actions | verb phrases | `fetchWeather()` |

### SwiftUI Modifiers Order

1. Size/frame modifiers
2. Padding
3. Background/overlay
4. Border/corners
5. Shadow
6. Animation
7. Accessibility

## Common Issues & Solutions

### Build Errors

- **Missing manager**: Check environment setup in `weatherApp.swift`
- **SwiftData errors**: Ensure `@Model` classes are properly defined
- **Async errors**: Wrap in `Task { }` when called from sync context

### Runtime Issues

- **No weather data**: Check location permissions
- **Blank screen**: Verify environment objects are injected
- **Chart not updating**: Ensure data model conforms to `Identifiable`

## Testing Guidance

### Unit Tests

- Located in `weatherTests/`
- Mock `WeatherService` for network tests
- Test manager state changes

### UI Tests

- Located in `weatherUITests/`
- Test navigation flows
- Verify accessibility labels

## Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview |
| `QUICK_START.md` | Setup guide |
| `CHANGELOG.md` | Version history |
| `BUILD_FIXES.md` | Common build solutions |
| `BUILD_OPTIMIZATIONS.md` | Build & performance optimization |
| `VISUAL_FEATURE_MAP.md` | UI component reference |

## Restrictions

❌ Do not add third-party dependencies
❌ Do not remove accessibility features
❌ Do not hardcode sensitive data
❌ Do not use deprecated APIs
❌ Do not break existing tests
❌ Do not create formatters inside loops or computed properties
❌ Do not skip the Makefile for builds

✅ Do use Apple frameworks only
✅ Do follow existing patterns
✅ Do maintain dark mode support
✅ Do add documentation for new features
✅ Do write tests for new code
✅ Do use cached formatters and sessions
✅ Do use `make build` instead of `xcodebuild` directly
