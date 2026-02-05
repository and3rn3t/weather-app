# Weather App 🌤️

A beautiful, feature-rich weather application built with SwiftUI for iOS 17+.

## 📁 Project Structure

```
weather/
├── weather/                          # Main app target
│   ├── Sources/
│   │   ├── App/                      # App entry point
│   │   │   └── weatherApp.swift
│   │   ├── Views/                    # SwiftUI Views
│   │   │   ├── ContentView.swift
│   │   │   ├── WeatherDetailView.swift
│   │   │   ├── WeatherCards.swift
│   │   │   ├── FavoritesView.swift
│   │   │   ├── SettingsView.swift
│   │   │   ├── LocationSearchView.swift
│   │   │   └── WeatherWidget.swift
│   │   ├── Models/                   # Data models
│   │   │   ├── WeatherModels.swift   # API response models
│   │   │   └── Models.swift          # App models & enums
│   │   ├── Services/                 # API & network services
│   │   │   └── WeatherService.swift
│   │   ├── Managers/                 # State & data managers
│   │   │   ├── LocationManager.swift
│   │   │   ├── FavoritesManager.swift
│   │   │   ├── NotificationManager.swift
│   │   │   └── SettingsManager.swift
│   │   └── Utilities/                # Helpers & effects
│   │       ├── GlassEffects.swift
│   │       └── WeatherParticleEffects.swift
│   ├── Assets.xcassets/              # App icons & colors
│   ├── Documentation/                # Feature docs & guides
│   ├── Info.plist
│   └── weather.entitlements
├── weather.xcodeproj/                # Xcode project file
├── weatherTests/                     # Unit tests
├── weatherUITests/                   # UI tests
├── .gitignore
└── .swiftlint.yml                    # SwiftLint configuration
```

## 🚀 Getting Started

1. Open `weather.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build and run (⌘+R)

### Requirements
- **Xcode**: 15.0+
- **iOS**: 17.0+
- **Swift**: 5.9+

## ✨ Features

- 🌍 Real-time weather data with hourly & 7-day forecasts
- 📍 GPS location detection & global search
- ⭐ Favorites management with SwiftData
- 📊 Interactive temperature & precipitation charts
- 🔔 Smart weather notifications
- 📱 Home screen & lock screen widgets
- 🎨 Glass morphism UI with weather animations

## 📚 Documentation

See the [Documentation](weather/Documentation/) folder for detailed guides:
- [README.md](weather/Documentation/README.md) - Full feature documentation
- [QUICK_START.md](weather/Documentation/QUICK_START.md) - Setup guide
- [CHANGELOG.md](weather/Documentation/CHANGELOG.md) - Version history

## 🔧 Configuration

### Location Permissions
Add to `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show weather for your area</string>
```

## 📄 License

MIT License - See LICENSE for details
