# Weather App - Android

A modern Android weather application built with Kotlin and Jetpack Compose, featuring current weather conditions, hourly and daily forecasts, location search, and saved favorites.

## Features ✨

### MVP Features (Implemented)

- **Current Weather Display** - Real-time weather with temperature, feels-like, conditions, humidity, wind, pressure, UV index, and visibility
- **Forecasts**
  - 24-hour hourly forecast with temperature and precipitation probability
  - 14-day daily forecast with high/low temperatures
- **Location Services**
  - GPS-based automatic location detection
  - Location search by city name
  - Reverse geocoding for city/state/country names
- **Saved Favorites** - Save and manage multiple locations with Room database
- **Settings** - Customizable units (temperature, wind speed, precipitation) and preferences
- **Offline Mode** - Cached data display when network is unavailable
- **Material Design 3** - Modern UI with dynamic colors and dark theme support

### Coming Soon (Post-MVP)

- Weather radar maps with RainViewer integration
- App widgets for home screen
- Push notifications for daily forecasts and rain alerts
- Weather sharing with styled cards
- Advanced theming system

## Technical Stack 🛠️

- **Language:** Kotlin
- **UI Framework:** Jetpack Compose with Material 3
- **Architecture:** MVVM with Clean Architecture principles
- **Dependency Injection:** Hilt
- **Networking:** Retrofit + OkHttp + Moshi
- **Database:** Room
- **Preferences:** DataStore
- **Location:** Google Play Services (Fused Location Provider)
- **Async:** Kotlin Coroutines + Flow
- **Minimum SDK:** 26 (Android 8.0)
- **Target SDK:** 34 (Android 14)

## Data Sources 📡

### Free APIs (No Authentication Required)

- **Open-Meteo API** - Weather data (current, hourly, daily forecasts)
  - Endpoint: `https://api.open-meteo.com/v1/forecast`
  - Rate Limit: 60 requests/minute
  - No API key needed

## Project Structure 📁

```
app/src/main/java/com/andernet/weather/
├── data/
│   ├── local/               # Room database entities and DAOs
│   │   ├── SavedLocation.kt
│   │   ├── SavedLocationDao.kt
│   │   └── WeatherDatabase.kt
│   ├── model/               # Data models and DTOs
│   │   ├── WeatherModels.kt
│   │   ├── Models.kt
│   │   └── WeatherError.kt
│   ├── remote/              # API service interfaces
│   │   └── WeatherApiService.kt
│   └── repository/          # Data repositories
│       ├── WeatherRepository.kt
│       ├── LocationRepository.kt
│       ├── FavoritesRepository.kt
│       └── SettingsRepository.kt
├── di/                      # Hilt dependency injection modules
│   ├── AppModule.kt
│   └── DatabaseModule.kt
├── ui/
│   ├── components/          # Reusable UI components
│   │   ├── WeatherCards.kt
│   │   └── ForecastComponents.kt
│   ├── screen/              # Screen composables
│   │   ├── HomeScreen.kt
│   │   ├── SearchScreen.kt
│   │   ├── FavoritesScreen.kt
│   │   └── SettingsScreen.kt
│   ├── theme/               # Material 3 theming
│   │   ├── Color.kt
│   │   ├── Theme.kt
│   │   └── Type.kt
│   └── viewmodel/           # ViewModels for state management
│       ├── MainViewModel.kt
│       ├── SearchViewModel.kt
│       ├── FavoritesViewModel.kt
│       └── SettingsViewModel.kt
├── MainActivity.kt          # Entry point
├── WeatherApp.kt            # Navigation setup
└── WeatherApplication.kt    # Application class (Hilt)
```

## Getting Started 🚀

### Prerequisites

- Android Studio Hedgehog (2023.1.1) or later
- JDK 17 or later
- Android SDK with API 34

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/and3rn3t/weather-app.git
   cd weather-app/android-app
   ```

2. **Open in Android Studio**
   - Open Android Studio
   - Select "Open an Existing Project"
   - Navigate to the `android-app/` directory
   - Wait for Gradle sync to complete

3. **Run the app**
   - Connect an Android device or start an emulator
   - Click the "Run" button or press Shift+F10
   - Grant location permission when prompted

### Build from Command Line

```bash
# Debug build
./gradlew assembleDebug

# Release build
./gradlew assembleRelease

# Run tests
./gradlew test

# Install on connected device
./gradlew installDebug
```

## Architecture Details 🏗️

### MVVM Pattern

- **Model:** Data classes, repositories, and data sources
- **View:** Jetpack Compose UI components
- **ViewModel:** State management with StateFlow

### Data Flow

1. **UI Layer** - Compose screens observe ViewModel StateFlows
2. **ViewModel Layer** - Manages UI state, handles user interactions
3. **Repository Layer** - Single source of truth, coordinates data sources
4. **Data Sources** - Remote API (Retrofit) and Local storage (Room/DataStore)

### Caching Strategy

- **Synchronous Cache Loading** - Instant startup with cached data (~2ms load time)
- **HTTP Caching** - OkHttp cache for network responses (10MB)
- **File Cache** - WeatherData persisted to disk for offline access
- **Debouncing** - 1-minute minimum interval between API calls
- **Retry Logic** - Exponential backoff (100ms, 400ms, 1600ms)

### State Management

- **StateFlow** - Reactive state updates (similar to iOS @Published)
- **@HiltViewModel** - ViewModel injection with Hilt
- **collectAsStateWithLifecycle** - Lifecycle-aware state collection

## Key Features Explained 🔍

### Location Services

- **Fused Location Provider** - Battery-efficient GPS with balanced accuracy
- **Geocoding** - Reverse geocode coordinates to city/state names
- **Search** - Forward geocode city names to coordinates
- **Permission Handling** - Runtime permission requests with Accompanist

### Saved Favorites

- **Room Database** - SQLite wrapper with type-safe queries
- **Duplicate Detection** - 0.01° coordinate tolerance (like iOS)
- **Reactive Updates** - Flow-based updates for instant UI refresh
- **CRUD Operations** - Add, delete, and view saved locations

### Settings & Preferences

- **DataStore** - Modern replacement for SharedPreferences
- **Locale-Aware Defaults** - US uses Fahrenheit, rest of world uses Celsius
- **Reactive Settings** - Changes propagate immediately to all screens
- **Persistent Storage** - Settings survive app restarts

## API Integration 🌐

### Open-Meteo Weather API

```kotlin
// Example request parameters
latitude: 37.7749
longitude: -122.4194
current: temperature_2m,apparent_temperature,weather_code,...
hourly: temperature_2m,weather_code,precipitation_probability,...
daily: weather_code,temperature_2m_max,temperature_2m_min,...
temperature_unit: celsius | fahrenheit
wind_speed_unit: kmh | mph | ms | kn
forecast_days: 14
```

### Weather Code Mapping

- 0-1: Clear
- 2: Partly Cloudy
- 3: Cloudy
- 45-48: Fog
- 51-57: Drizzle
- 61-67: Rain
- 71-77: Snow
- 80-82: Rain Showers
- 85-86: Snow Showers
- 95-99: Thunderstorm

## Comparison with iOS Version 📱

### Implemented Features (Parity)

✅ Current weather display  
✅ 24-hour hourly forecast  
✅ 14-day daily forecast  
✅ GPS location detection  
✅ Location search  
✅ Saved favorites  
✅ Unit preferences (temperature, wind, precipitation)  
✅ Offline mode with caching  
✅ Error handling with retry logic  

### Not Yet Implemented (Post-MVP)

⬜ Weather radar maps (RainViewer)  
⬜ App widgets (Jetpack Glance)  
⬜ Push notifications (WorkManager)  
⬜ Adaptive themes (8 themes in iOS)  
⬜ Weather sharing / social features  
⬜ Siri Shortcuts equivalent (Google Assistant)  
⬜ Live Activities equivalent (persistent notifications)  
⬜ Weather recommendations (umbrella, sunscreen, etc.)  

## Performance Optimizations ⚡

- **Instant Startup** - Synchronous cache loading shows weather in <10ms
- **Lazy Loading** - Compose recomposition only for changed state
- **Background Refresh** - Coroutines for non-blocking network calls
- **HTTP Caching** - Reduce redundant API calls
- **Image Loading** - Coil for efficient bitmap handling (future feature)

## Testing 🧪

```bash
# Unit tests (ViewModels, Repositories)
./gradlew test

# Instrumented tests (UI, Database)
./gradlew connectedAndroidTest

# Test coverage report
./gradlew jacocoTestReport
```

## Troubleshooting 🔧

### Common Issues

**Location not working?**

- Ensure location permission is granted in app settings
- Check that device location services are enabled
- Try restarting the app

**Network errors?**

- Verify internet connection
- Check that Open-Meteo API is accessible (no firewall)
- App will show cached data if available

**Build errors?**

- Clean project: `./gradlew clean`
- Invalidate caches in Android Studio
- Update Gradle wrapper: `./gradlew wrapper --gradle-version=8.2`

## Contributing 🤝

This is a Portfolio project demonstrating modern Android development practices. Feel free to:

- Report bugs via GitHub Issues
- Suggest new features
- Submit pull requests

## License 📄

See LICENSE file in the parent directory.

## Acknowledgments 🙏

- **Open-Meteo** - Free weather API with no authentication
- **Material Design 3** - Google's design system
- **Jetpack Compose** - Modern Android UI toolkit
- **iOS Weather App** - Original design and feature inspiration

## Roadmap 🗺️

### Phase 2 (Next Features)

- [ ] Weather radar maps with RainViewer
- [ ] Home screen widgets (Jetpack Glance)
- [ ] Daily forecast notifications
- [ ] Rain alerts (2-hour forecast check)

### Phase 3 (Advanced Features)

- [ ] Adaptive theme system (8 themes)
- [ ] Weather sharing with styled cards
- [ ] Weather recommendations engine
- [ ] Google Assistant integration
- [ ] Moon phase calculations
- [ ] Sunrise/sunset visualization

## Contact 📧

For questions or feedback, please open an issue on GitHub.
