# AI Agent Development Guide

This document provides detailed instructions for AI coding assistants (Claude, GitHub Copilot, ChatGPT, etc.) working with the Weather App codebase.

## Project Context

**Weather App** is an iOS weather application built with SwiftUI for iOS 17+. It uses the Open-Meteo API for weather data (free, no API key required).

### Key Technologies

| Technology | Version | Purpose |
| ---------- | ------- | ------- |
| Swift | 5.9+ | Programming language |
| SwiftUI | 5.0 | UI framework |
| iOS | 17.0+ | Target platform |
| SwiftData | - | Data persistence |
| Swift Charts | - | Data visualization |
| WidgetKit | - | Home/lock screen widgets |
| CoreLocation | - | GPS services |
| MapKit | - | Location search |

---

## Architecture Overview

### MVVM + Observable Pattern

```text
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Views     │ ←── │  Managers   │ ←── │  Services   │
│  (SwiftUI)  │     │ (@Observable)│     │ (API calls) │
└─────────────┘     └─────────────┘     └─────────────┘
       ↑                   ↑                   ↑
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌─────────────┐
                    │   Models    │
                    │  (Codable)  │
                    └─────────────┘
```

### File Organization

| Directory | Contents | Pattern |
| --------- | -------- | ------- |
| `Sources/App/` | Entry point | `@main` App struct |
| `Sources/Views/` | UI components | SwiftUI View structs |
| `Sources/Models/` | Data types | Codable structs |
| `Sources/Services/` | API layer | Singleton classes |
| `Sources/Managers/` | State management | @Observable classes |
| `Sources/Utilities/` | Helpers | ViewModifiers, extensions |

---

## Code Patterns

### Manager Pattern (State Management)

```swift
import Foundation

@Observable
final class ExampleManager {
    // MARK: - Properties
    
    private(set) var items: [Item] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Public Methods
    
    func fetch() async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await service.fetchItems()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private let service = ItemService.shared
}
```

### View Pattern

```swift
import SwiftUI

struct ExampleView: View {
    // MARK: - Environment
    
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var isLoading = false
    @State private var showSheet = false
    
    // MARK: - Properties
    
    let title: String
    
    // MARK: - Body
    
    var body: some View {
        content
            .navigationTitle(title)
            .sheet(isPresented: $showSheet) {
                SheetView()
            }
    }
    
    // MARK: - Private Views
    
    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    ItemRow(item: item)
                }
            }
            .padding()
        }
    }
}
```

### Service Pattern (API Layer)

```swift
import Foundation

final class WeatherService {
    // MARK: - Singleton
    
    static let shared = WeatherService()
    private init() {}
    
    // MARK: - Properties
    
    private let baseURL = "https://api.open-meteo.com/v1"
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    // MARK: - Public Methods
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        var components = URLComponents(string: "\(baseURL)/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try decoder.decode(WeatherData.self, from: data)
    }
}
```

### Model Pattern

```swift
import Foundation

struct WeatherData: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let current: CurrentWeather
    let hourly: HourlyForecast
    
    struct CurrentWeather: Codable, Sendable {
        let temperature2m: Double
        let weatherCode: Int
        
        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }
    
    struct HourlyForecast: Codable, Sendable {
        let time: [String]
        let temperature2m: [Double]
        let precipitationProbability: [Int]
        
        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case precipitationProbability = "precipitation_probability"
        }
    }
}
```

---

## SwiftUI Conventions

### Modifier Order

Apply modifiers in this order for consistency:

1. **Content modifiers** (font, foregroundStyle)
2. **Layout modifiers** (frame, padding)
3. **Background/overlay**
4. **Shape modifiers** (cornerRadius, clipShape)
5. **Shadow/border**
6. **Animation**
7. **Accessibility**
8. **Gestures**

```swift
Text("Weather")
    .font(.headline)                    // 1. Content
    .foregroundStyle(.primary)
    .frame(maxWidth: .infinity)         // 2. Layout
    .padding()
    .background(.ultraThinMaterial)     // 3. Background
    .clipShape(RoundedRectangle(cornerRadius: 16))  // 4. Shape
    .shadow(radius: 8)                  // 5. Shadow
    .animation(.spring, value: isSelected)  // 6. Animation
    .accessibilityLabel("Weather heading")  // 7. Accessibility
    .onTapGesture { }                   // 8. Gestures
```

### Glass Morphism Style

```swift
// Standard glass card effect
content
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .stroke(.white.opacity(0.3), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
```

### Animation Standards

```swift
// Default spring animation
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)

// Numeric transitions
.contentTransition(.numericText())

// Symbol effects
.symbolEffect(.bounce, value: trigger)
.symbolEffect(.pulse.byLayer)

// Haptic feedback
UIImpactFeedbackGenerator(style: .light).impactOccurred()
```

---

## Common Tasks

### Adding a New View

1. Create file in `Sources/Views/YourView.swift`
2. Add required environment dependencies
3. Implement using glass morphism styling
4. Add accessibility labels
5. Test in both light and dark modes

### Adding a New API Endpoint

1. Add response model in `Sources/Models/WeatherModels.swift`
2. Add fetch method in `Sources/Services/WeatherService.swift`
3. Use `async throws` pattern
4. Handle errors gracefully

### Adding a New Setting

1. Add `@AppStorage` property in `SettingsManager.swift`
2. Add UI control in `SettingsView.swift`
3. Use the setting where needed via `@Environment`

### Adding Haptic Feedback

```swift
private func triggerHaptic() {
    #if os(iOS)
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    #endif
}
```

---

## Error Handling

### User-Facing Errors

```swift
enum WeatherError: LocalizedError {
    case networkUnavailable
    case locationDenied
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Unable to connect. Please check your internet connection."
        case .locationDenied:
            return "Location access is required. Please enable in Settings."
        case .invalidResponse:
            return "Unable to load weather data. Please try again."
        }
    }
}
```

### Error Display Pattern

```swift
if let error = manager.errorMessage {
    ContentUnavailableView {
        Label("Error", systemImage: "exclamationmark.triangle")
    } description: {
        Text(error)
    } actions: {
        Button("Retry") {
            Task { await manager.fetch() }
        }
    }
}
```

---

## Testing Guidelines

### Unit Tests

```swift
import XCTest
@testable import weather

final class WeatherServiceTests: XCTestCase {
    var sut: WeatherService!
    
    override func setUp() {
        super.setUp()
        sut = WeatherService.shared
    }
    
    func testFetchWeather_ValidCoordinates_ReturnsData() async throws {
        // Given
        let latitude = 37.7749
        let longitude = -122.4194
        
        // When
        let result = try await sut.fetchWeather(latitude: latitude, longitude: longitude)
        
        // Then
        XCTAssertNotNil(result.current)
        XCTAssertFalse(result.hourly.time.isEmpty)
    }
}
```

### UI Tests

```swift
import XCTest

final class WeatherUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testSearchLocation_ShowsResults() {
        // Given
        let searchButton = app.buttons["Search"]
        
        // When
        searchButton.tap()
        app.textFields["Search location"].typeText("London")
        
        // Then
        XCTAssertTrue(app.staticTexts["London"].waitForExistence(timeout: 5))
    }
}
```

---

## Restrictions

### Do NOT

- ❌ Add third-party dependencies (SPM, CocoaPods, etc.)
- ❌ Remove accessibility labels or hints
- ❌ Hardcode API keys or secrets
- ❌ Use deprecated SwiftUI APIs
- ❌ Break existing tests
- ❌ Remove existing functionality without explicit approval
- ❌ Use `@ObservableObject` (prefer `@Observable`)
- ❌ Use completion handlers (prefer async/await)

### DO

- ✅ Use only Apple frameworks
- ✅ Follow existing patterns and conventions
- ✅ Maintain dark mode compatibility
- ✅ Add documentation for new features
- ✅ Write tests for new code
- ✅ Use `@Observable` for state management
- ✅ Use `async/await` for asynchronous code
- ✅ Add `Sendable` conformance where appropriate

---

## Quick Reference

### Weather Codes (Open-Meteo)

| Code | Condition |
| ---- | --------- |
| 0 | Clear sky |
| 1-3 | Partly cloudy |
| 45, 48 | Fog |
| 51-55 | Drizzle |
| 61-65 | Rain |
| 71-75 | Snow |
| 80-82 | Rain showers |
| 95-99 | Thunderstorm |

### SF Symbols Used

| Symbol | Usage |
| ------ | ----- |
| `sun.max.fill` | Clear weather |
| `cloud.fill` | Cloudy |
| `cloud.rain.fill` | Rain |
| `cloud.snow.fill` | Snow |
| `location.fill` | Current location |
| `star.fill` | Favorite |
| `magnifyingglass` | Search |

### Color Scheme

| Purpose | Color |
| ------- | ----- |
| Cold temps | Blue gradient |
| Hot temps | Red/orange gradient |
| Rain | Blue tones |
| UV High | Orange/red |
| Success | Green |
| Warning | Yellow |
| Error | Red |

---

## Useful Resources

- [Open-Meteo API Docs](https://open-meteo.com/en/docs)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Charts](https://developer.apple.com/documentation/charts)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
