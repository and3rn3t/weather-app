# GitHub Copilot Instructions for Weather App

## Project Overview

This is a SwiftUI weather application for iOS 17+ featuring real-time weather data, interactive charts, location services, favorites management, and widgets. The app uses modern Swift patterns including `@Observable`, async/await, and SwiftData.

## Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI 5.0
- **Minimum iOS**: 17.0
- **Data Persistence**: SwiftData
- **Charts**: Swift Charts
- **Location**: CoreLocation, MapKit
- **Widgets**: WidgetKit, AppIntents
- **Architecture**: MVVM with Observable pattern

## Project Structure

```
weather/
├── Sources/
│   ├── App/           # App entry point (weatherApp.swift)
│   ├── Views/         # SwiftUI views
│   ├── Models/        # Data models (Codable structs)
│   ├── Services/      # API services (WeatherService)
│   ├── Managers/      # State managers (@Observable classes)
│   └── Utilities/     # Helper components (effects, extensions)
├── Assets.xcassets/   # App icons, colors
└── Documentation/     # Feature documentation
```

## Coding Standards

### Swift Conventions

1. **Use Modern Swift Syntax**
   - Prefer `@Observable` over `@ObservableObject`
   - Use `async/await` for all asynchronous operations
   - Prefer `if let` and `guard let` for optionals
   - Use `Result` types for error handling in services

2. **Naming Conventions**
   - Types: `PascalCase` (e.g., `WeatherData`, `LocationManager`)
   - Variables/Functions: `camelCase` (e.g., `currentWeather`, `fetchWeather()`)
   - Constants: `camelCase` (e.g., `maxRetryCount`)
   - Boolean variables: Use `is`, `has`, `should` prefix

3. **File Organization**
   ```swift
   // MARK: - Properties
   // MARK: - Initializers
   // MARK: - Public Methods
   // MARK: - Private Methods
   // MARK: - Computed Properties
   ```

### SwiftUI Best Practices

1. **View Composition**
   - Break views into small, reusable components
   - Use `@ViewBuilder` for conditional content
   - Prefer `private` for helper views within a file

2. **State Management**
   - Use `@State` for local view state
   - Use `@Environment` for shared managers
   - Use `@Binding` for two-way data flow

3. **Modifiers**
   - Apply modifiers in logical order: layout → appearance → interaction
   - Use custom ViewModifiers for reusable styling

### API Integration

- **Weather API**: Open-Meteo (free, no API key required)
- **Base URL**: `https://api.open-meteo.com/v1/forecast`
- All API calls should be in `WeatherService.swift`
- Use `URLSession` with async/await
- Handle errors gracefully with user-friendly messages

## Key Components

### Managers (Observable Classes)

```swift
@Observable
class SomeManager {
    var property: Type = defaultValue
    
    func doSomething() async throws {
        // Implementation
    }
}
```

### Views Pattern

```swift
struct SomeView: View {
    @Environment(LocationManager.self) private var locationManager
    @State private var localState = false
    
    var body: some View {
        // View content
    }
}
```

### Models Pattern

```swift
struct WeatherResponse: Codable {
    let current: CurrentWeather
    let hourly: HourlyForecast
    
    enum CodingKeys: String, CodingKey {
        case current
        case hourly
    }
}
```

## Visual Design Guidelines

### Glass Morphism

- Use `GlassCard` modifier for card backgrounds
- Apply `.ultraThinMaterial` for blur effects
- Use subtle borders with `opacity(0.3)`
- Corner radius: 16-24 points

### Colors

- Primary gradients based on weather conditions
- Temperature colors: Blue (cold) → Red (hot)
- Use SF Symbols with `.symbolEffect()` for animations

### Animations

- Default animation: `.spring(response: 0.3, dampingFraction: 0.7)`
- Use `.contentTransition(.numericText())` for number changes
- Add haptic feedback for interactions: `UIImpactFeedbackGenerator(style: .light)`

## Common Tasks

### Adding a New View

1. Create file in `Sources/Views/`
2. Import SwiftUI and any needed managers
3. Add environment dependencies
4. Implement with glass effect styling

### Adding a New API Endpoint

1. Add response model in `Models/WeatherModels.swift`
2. Add method in `Services/WeatherService.swift`
3. Handle in relevant manager or view

### Adding a New Setting

1. Add property to `SettingsManager.swift`
2. Persist with `@AppStorage`
3. Add UI control in `SettingsView.swift`

## Testing

- Unit tests in `weatherTests/`
- UI tests in `weatherUITests/`
- Test async code with `XCTestExpectation`
- Mock network responses for service tests

### Running Tests

Use the Makefile for consistent test execution:

```bash
make test               # Run all tests
make test-coverage      # Tests with code coverage
make test-plan          # Use test plan (parallel, sanitizers)
make test-performance   # Performance tests only
```

### Test Plan

The project includes `WeatherTestPlan.xctestplan` with:
- Parallel test execution
- Retry on failure (up to 3 attempts)
- Code coverage for main target
- Address Sanitizer and Thread Sanitizer configurations

## Build Process

### Makefile Commands

Always use the Makefile for consistent builds:

```bash
# Building
make build              # Debug build
make build-release      # Release build (optimized)
make clean              # Clean DerivedData and build artifacts

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

When writing code, follow these performance patterns:

1. **Use Static Formatters** - Don't create formatters in loops or computed properties:
   ```swift
   // ✅ Good: Static cached formatter
   private static let temperatureFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
       formatter.maximumFractionDigits = 0
       return formatter
   }()
   
   // ❌ Bad: Creating formatter each time
   func format(_ value: Double) -> String {
       let formatter = NumberFormatter()  // Expensive!
       return formatter.string(from: NSNumber(value: value))
   }
   ```

2. **Use Cached URLSession** - The app uses a shared session with caching:
   ```swift
   private static let cachedSession: URLSession = {
       let config = URLSessionConfiguration.default
       config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
       return URLSession(configuration: config)
   }()
   ```

3. **Debounce API Requests** - Prevent excessive API calls with minimum intervals

4. **Defer Non-Critical Init** - Use `.task {}` for deferred initialization after first frame

### Code Quality Hooks

The project uses a pre-commit hook (`scripts/pre-commit`) that:
- Runs SwiftLint on staged files
- Warns about print statements
- Detects force unwraps
- Reports TODO/FIXME counts

Install with: `make install-hooks`

## Important Notes

1. **No External Dependencies**: App uses only Apple frameworks
2. **Location Privacy**: Always explain why location is needed
3. **Offline Support**: Cache last weather data for offline viewing
4. **Accessibility**: Add labels to all interactive elements
5. **Dark Mode**: All UI should work in both light and dark modes
6. **Performance**: Use cached formatters and sessions, debounce requests

## Debugging Tips

- Check `LocationManager.authorizationStatus` for location issues
- Verify API URL parameters in `WeatherService`
- Use Xcode's View Debugger for layout issues
- Check Console for network errors
- Run `make analyze-build-times` to find slow compilation
- Use `make profile` then Instruments for performance issues

## Do NOT

- Add third-party dependencies without approval
- Remove existing accessibility labels
- Hardcode API keys or secrets
- Use deprecated SwiftUI APIs
- Break existing functionality when adding features
- Create new formatters inside loops or computed properties
- Skip the Makefile for builds (use `make build` not `xcodebuild` directly)
