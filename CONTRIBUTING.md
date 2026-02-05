# Contributing to Weather App

Thank you for your interest in contributing to the Weather App! This document provides guidelines and information for contributors.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Code Style](#code-style)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [AI Assistance](#ai-assistance)
- [Testing](#testing)
- [Documentation](#documentation)

---

## Getting Started

### Prerequisites

- **macOS**: Ventura 14.0 or later
- **Xcode**: 15.0 or later
- **iOS Device/Simulator**: iOS 17.0 or later
- **Git**: Latest version

### Setup

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/weather-app.git
   cd weather-app
   ```

2. **Open in Xcode**
   ```bash
   open weather.xcodeproj
   ```

3. **Build and run**
   - Select a simulator or device
   - Press `Cmd+R` to build and run

4. **Verify everything works**
   - Grant location permissions when prompted
   - Confirm weather data loads correctly

---

## Development Environment

### Recommended Xcode Settings

- **Editor**: Enable "Show Invisibles" to catch whitespace issues
- **Text Editing**: Set tab width to 4 spaces
- **Source Control**: Enable automatic fetch

### Helpful Extensions

- **SwiftLint**: Project includes `.swiftlint.yml` configuration
- **SF Symbols**: Download SF Symbols app for icon reference

### Project Structure

```
weather/
├── Sources/           # Main source code
│   ├── App/          # App entry point
│   ├── Views/        # SwiftUI views
│   ├── Models/       # Data models
│   ├── Services/     # API services
│   ├── Managers/     # State managers
│   └── Utilities/    # Helpers
├── Documentation/    # Feature docs
├── Assets.xcassets/  # Resources
└── Info.plist        # App configuration
```

---

## Code Style

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

#### Formatting
- **Indentation**: 4 spaces (no tabs)
- **Line length**: Prefer under 120 characters
- **Trailing commas**: Use in multi-line collections
- **Imports**: Alphabetize, separate system from local

#### Naming
```swift
// Types: PascalCase
struct WeatherData { }
class LocationManager { }

// Variables: camelCase
var currentTemperature: Double
let maxRetryCount = 3

// Booleans: is/has/should prefix
var isLoading: Bool
var hasLocationPermission: Bool
```

#### Organization
```swift
struct MyView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var isLoading = false
    
    // MARK: - Properties
    let title: String
    
    // MARK: - Body
    var body: some View { ... }
    
    // MARK: - Private Views
    private var headerView: some View { ... }
    
    // MARK: - Methods
    private func loadData() { ... }
}
```

### SwiftUI Patterns

#### Prefer Composition
```swift
// ✅ Good: Small, reusable components
var body: some View {
    VStack {
        HeaderView(title: title)
        ContentView(data: data)
        FooterView()
    }
}

// ❌ Avoid: Large monolithic views
var body: some View {
    VStack {
        // 200 lines of code...
    }
}
```

#### Use ViewModifiers
```swift
// ✅ Good: Reusable modifier
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(16)
    }
}

// Usage
Text("Hello").modifier(GlassCard())
```

---

## Making Changes

### Branch Naming

```bash
# Features
git checkout -b feature/add-widget-support

# Bug fixes
git checkout -b fix/location-permission-crash

# Documentation
git checkout -b docs/update-readme

# Refactoring
git checkout -b refactor/cleanup-weather-service
```

### Commit Messages

Follow conventional commits format:

```bash
# Format
<type>(<scope>): <description>

# Examples
feat(weather): add hourly precipitation chart
fix(location): handle denied permission state
docs(readme): update installation instructions
style(views): format WeatherDetailView
refactor(api): simplify error handling
test(service): add WeatherService unit tests
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, no logic change
- `refactor`: Code change, no feature/fix
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

---

## Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Run tests**
   ```bash
   # In Xcode: Cmd+U
   ```

3. **Build for release**
   ```bash
   # Product → Build for → Running
   ```

4. **Check for warnings**
   - Fix all compiler warnings
   - Run SwiftLint if available

### PR Requirements

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Tests pass on simulator
- [ ] Documentation updated (if needed)
- [ ] No new compiler warnings
- [ ] Tested on iOS 17 simulator

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How to test these changes

## Screenshots
(if UI changes)

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests pass
- [ ] Documentation updated
```

---

## AI Assistance

This project includes AI agent instructions for development assistance:

### GitHub Copilot

Custom instructions are in `.github/copilot-instructions.md`. These help Copilot:
- Understand project architecture
- Follow our coding patterns
- Generate consistent code

### Claude AI

Instructions are in `.claude/CLAUDE.md`. These provide:
- Project context and structure
- Coding patterns and examples
- Common issues and solutions

### Using AI Effectively

1. **Be specific** in your prompts
2. **Review suggestions** carefully
3. **Test generated code** thoroughly
4. **Maintain consistency** with existing patterns

---

## Testing

### Unit Tests

Located in `weatherTests/`:

```swift
import XCTest
@testable import weather

final class WeatherServiceTests: XCTestCase {
    func testFetchWeather() async throws {
        let service = WeatherService.shared
        let data = try await service.fetchWeather(lat: 37.7749, lon: -122.4194)
        XCTAssertNotNil(data.current)
    }
}
```

### UI Tests

Located in `weatherUITests/`:

```swift
import XCTest

final class WeatherUITests: XCTestCase {
    func testLocationSearch() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Search"].tap()
        app.textFields["Search location"].typeText("London")
        // Assert results appear
    }
}
```

### What to Test

- **Models**: Encoding/decoding, computed properties
- **Services**: API responses, error handling
- **Managers**: State changes, persistence
- **Views**: User interactions, accessibility

---

## Documentation

### When to Document

- New features
- API changes
- Complex logic
- Breaking changes

### Documentation Files

| File | Update When |
|------|-------------|
| `README.md` | Major features, getting started changes |
| `CHANGELOG.md` | Every release |
| `QUICK_START.md` | Setup process changes |
| Feature docs | Specific feature changes |

### Code Comments

```swift
// Use for non-obvious logic
/// Use doc comments for public APIs

/// Fetches weather data for the given coordinates.
/// - Parameters:
///   - latitude: The latitude coordinate
///   - longitude: The longitude coordinate
/// - Returns: Weather data for the location
/// - Throws: NetworkError if the request fails
func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData
```

---

## Questions?

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Be respectful and constructive

Thank you for contributing! 🌤️
