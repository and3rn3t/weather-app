# Multi-Platform Weather App

This repository contains **two native weather applications** that share the same free weather APIs but are built with modern platform-specific frameworks.

## 📱 Platforms

### iOS App (Swift + SwiftUI)

**Location:** `/weather/`  
**Status:** ✅ Production-ready with full features  

**Tech Stack:**

- Swift 5.9+ with SwiftUI
- SwiftData for persistence
- Observation framework for state management
- WidgetKit for home screen widgets
- Live Activities for Dynamic Island
- App Intents for Siri integration

**Features:**

- Current weather + forecasts (hourly, daily)
- Weather radar maps with animation
- 8 adaptive themes
- Location search and favorites
- Weather sharing
- Siri Shortcuts
- Push notifications
- Weather recommendations

### Android App (Kotlin + Jetpack Compose)

**Location:** `/android/`  
**Status:** ✅ MVP complete, ready for development  

**Tech Stack:**

- Kotlin 1.9+ with Jetpack Compose
- Room for persistence
- StateFlow + Coroutines for state management
- Hilt for dependency injection
- Material Design 3 with dynamic colors

**Features (MVP):**

- Current weather + forecasts (hourly, daily)
- Location search and favorites with Room
- Customizable units (temperature, wind, precipitation)
- Offline mode with intelligent caching
- Settings with DataStore
- Error handling with retry logic

## 🌐 Shared Infrastructure

Both apps use the same **free, open-source weather APIs**:

### Open-Meteo Weather API

- **Endpoint:** `https://api.open-meteo.com/v1/forecast`
- **Rate Limit:** 60 requests/minute
- **Authentication:** None required (completely free)
- **Data:** Current conditions, hourly forecast (168 hours), daily forecast (16 days)

### RainViewer Radar API (iOS only, Android planned)

- **Endpoint:** `https://api.rainviewer.com/public/weather-maps.json`
- **Authentication:** None required
- **Data:** Precipitation radar tiles for map overlay

## 📊 Feature Comparison

| Feature | iOS | Android |
|---------|-----|---------|
| Current Weather | ✅ | ✅ |
| 24-hour Hourly Forecast | ✅ | ✅ |
| 14-day Daily Forecast | ✅ | ✅ |
| GPS Location | ✅ | ✅ |
| Location Search | ✅ | ✅ |
| Saved Favorites | ✅ SwiftData | ✅ Room |
| Unit Preferences | ✅ | ✅ |
| Offline Mode | ✅ | ✅ |
| Weather Radar Maps | ✅ RainViewer | ⬜ Planned |
| Home Screen Widgets | ✅ WidgetKit | ⬜ Planned (Glance) |
| Push Notifications | ✅ UNNotification | ⬜ Planned |
| Adaptive Themes | ✅ 8 themes | ⬜ Planned |
| Weather Sharing | ✅ | ⬜ Planned |
| Voice Assistant | ✅ Siri | ⬜ Planned (Assistant) |
| Live Activities | ✅ Dynamic Island | N/A (no equivalent) |

## 🚀 Getting Started

### iOS App

```bash
cd weather
open weather.xcodeproj
# Build and run (⌘R)
```

**Requirements:**

- Xcode 15+
- iOS 17+ deployment target
- macOS Sonoma or later

### Android App

```bash
cd android
# Open in Android Studio, or:
./gradlew assembleDebug
./gradlew installDebug
```

**Requirements:**

- Android Studio Hedgehog (2023.1.1)+
- JDK 17+
- Android SDK 34

## 🏗️ Architecture Comparison

### iOS: MVVM with Observation

```
SwiftUI Views
    ↓ @StateObject
ViewModels (@Observable)
    ↓ @Published
Managers (LocationManager, WeatherService)
    ↓
APIs + SwiftData
```

### Android: MVVM with StateFlow

```
Compose Screens
    ↓ collectAsStateWithLifecycle
ViewModels (@HiltViewModel)
    ↓ StateFlow
Repositories
    ↓ Hilt DI
APIs (Retrofit) + Room Database
```

## 📁 Project Structure

```
weather2/
├── weather/                    # iOS app (Swift/SwiftUI)
│   ├── weather/
│   │   ├── Sources/
│   │   │   ├── App/           # Entry point
│   │   │   ├── Views/         # SwiftUI screens
│   │   │   ├── Models/        # Data models
│   │   │   ├── Services/      # API clients
│   │   │   ├── Managers/      # State management
│   │   │   ├── Utilities/     # Helpers
│   │   │   └── Intents/       # Siri shortcuts
│   │   └── Assets.xcassets/
│   ├── Andernet Weather Widget/ # Widget extension
│   └── Documentation/
│
└── android/                    # Android app (Kotlin/Compose)
    ├── app/src/main/java/com/andernet/weather/
    │   ├── data/
    │   │   ├── local/         # Room database
    │   │   ├── model/         # Data models
    │   │   ├── remote/        # Retrofit APIs
    │   │   └── repository/    # Data repositories
    │   ├── di/                # Hilt modules
    │   ├── ui/
    │   │   ├── components/    # Reusable UI
    │   │   ├── screen/        # Compose screens
    │   │   ├── theme/         # Material 3 theme
    │   │   └── viewmodel/     # State management
    │   ├── MainActivity.kt
    │   ├── WeatherApp.kt      # Navigation
    │   └── WeatherApplication.kt
    └── README.md              # Android-specific docs
```

## 🎯 Development Roadmap

### Android App - Phase 2

- [ ] Weather radar maps (RainViewer integration)
- [ ] Home screen widgets (Jetpack Glance)
- [ ] Push notifications (WorkManager)
- [ ] Rain alerts (forecast checking)

### Android App - Phase 3

- [ ] Adaptive themes (8 themes like iOS)
- [ ] Weather sharing with styled cards
- [ ] Google Assistant integration
- [ ] Weather recommendations
- [ ] Advanced animations

### iOS App - Enhancements

- [ ] Enhanced accessibility features
- [ ] Apple Watch companion app
- [ ] macOS Catalyst version
- [ ] Additional weather data sources

## 🔧 Key Technologies

### iOS

- **SwiftUI** - Declarative UI framework
- **Swift Charts** - Native charting
- **MapKit** - Interactive maps
- **CoreLocation** - GPS services
- **SwiftData** - Modern persistence
- **WidgetKit** - Home screen widgets
- **App Intents** - Siri integration

### Android

- **Jetpack Compose** - Modern declarative UI
- **Material Design 3** - Design system with dynamic colors
- **Hilt** - Compile-time dependency injection
- **Retrofit** - Type-safe HTTP client
- **Room** - SQLite ORM
- **Coroutines + Flow** - Async programming
- **DataStore** - Modern preferences
- **Fused Location Provider** - Battery-efficient GPS

## 📝 License

See LICENSE file for details.

## 🙏 Acknowledgments

- **Open-Meteo** - Free weather data API (<https://open-meteo.com>)
- **RainViewer** - Free precipitation radar tiles (<https://rainviewer.com>)
- **Material Design** - Google's design system
- **SF Symbols** - Apple's icon system

## 📧 Support

For bugs or feature requests:

- iOS: Check `/weather/Documentation/`
- Android: Check `/android/README.md`
- Open GitHub Issues for this repository

---

**Built with ❤️ using modern native frameworks**  
iOS: SwiftUI • Android: Jetpack Compose
