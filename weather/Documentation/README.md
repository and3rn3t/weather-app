# Weather App 🌤️

A beautiful, feature-rich weather application built with SwiftUI, featuring interactive charts, weather animations, favorites management, and comprehensive widgets.

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## ✨ Features

### 🌍 Core Weather Features

- **Real-time Weather Data** - Current conditions, hourly & 14-day forecasts
- **Location-Based** - Automatic GPS location detection
- **Global Search** - Search any location worldwide
- **Detailed Metrics** - Temperature, wind, humidity, pressure, UV index, visibility, and more
- **Sunrise/Sunset Times** - Daily sun & moon information

### ⭐ Favorites & Locations

- **Save Unlimited Locations** - Keep track of multiple places
- **Quick Switching** - Instantly switch between saved locations
- **Drag to Reorder** - Organize your favorites
- **Persistent Storage** - Using SwiftData for reliability
- **One-Tap Favoriting** - Star button on weather view

### 📊 Interactive Charts

- **Temperature Chart** - 24-hour temperature forecast with smooth gradients
- **Precipitation Graph** - Hourly precipitation probability
- **Touch Interaction** - Tap and drag for detailed hourly info
- **Visual Appeal** - Beautiful animations and color coding
- **Daily Range Bars** - High/low temperature visualizations

### 🔔 Smart Notifications

- **Severe Weather Alerts** - Critical warnings for dangerous conditions
- **Daily Forecast** - Morning weather summary at your chosen time
- **Rain Alerts** - Notifications when rain expected within 2 hours
- **Weather Changes** - Alerts for significant condition changes

### 📱 Widgets

- **Home Screen Widgets** - Small, Medium, and Large sizes
- **Lock Screen Widgets** - Circular, Rectangular, and Inline styles
- **Auto-Refresh** - Updates every 30 minutes
- **Location Configuration** - Choose location per widget

### 🎨 Beautiful UI & Animations

- **Liquid Glass Design** - Modern glass morphism effects
- **Weather Particles** - Rain, snow, clouds, lightning, and fog animations
- **Mesh Gradients** - Smooth, dynamic background colors
- **Symbol Effects** - Animated SF Symbols (pulse, breathe, bounce)
- **Dark Mode** - Full dark mode support

### ⚙️ Customization & Settings

- **Units** - Fahrenheit/Celsius, mph/km/h, inches/mm
- **Appearance** - Light/Dark/Auto, animated backgrounds, particle effects
- **Display Options** - 12/24 hour format, show/hide feels-like temp
- **Notifications** - Configure all alert types
- **Auto-Refresh** - Configurable refresh intervals

---

## 📸 Screenshots

| Weather Detail | Hourly Chart | Favorites | Settings |
|---------------|--------------|-----------|----------|
| ![Detail](screenshots/detail.png) | ![Chart](screenshots/chart.png) | ![Favorites](screenshots/favorites.png) | ![Settings](screenshots/settings.png) |

| Widget - Small | Widget - Medium | Widget - Large | Lock Screen |
|----------------|-----------------|----------------|-------------|
| ![Small](screenshots/widget-small.png) | ![Medium](screenshots/widget-medium.png) | ![Large](screenshots/widget-large.png) | ![Lock](screenshots/lock-screen.png) |

---

## 🚀 Getting Started

### Requirements

- **Xcode**: 15.0 or later
- **iOS**: 17.0 or later
- **Swift**: 5.9 or later

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/weather-app.git
   cd weather-app
   ```

2. **Open in Xcode**

   ```bash
   open weather.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd+R` to build and run

4. **Add Widget Extension** (if not already configured)
   - File → New → Target
   - Select "Widget Extension"
   - Add WeatherWidget.swift to the widget target

### First Run

1. Grant location permission when prompted
2. Grant notification permission (optional)
3. Weather loads automatically for your location

---

## 📚 Documentation

### Getting Started

- **[QUICK_START.md](QUICK_START.md)** - Setup and integration guide
- **[BUILD_FIXES.md](BUILD_FIXES.md)** - Troubleshooting common issues

### Feature Guides

- **[FEATURES.md](FEATURES.md)** - Complete feature documentation
- **[VISUAL_FEATURE_MAP.md](VISUAL_FEATURE_MAP.md)** - UI component reference

### Reference

- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[AI_DEVELOPMENT_GUIDE.md](AI_DEVELOPMENT_GUIDE.md)** - AI assistant instructions

### Project Files (Root)

- **[CONTRIBUTING.md](../../CONTRIBUTING.md)** - Contribution guidelines
- **[.github/copilot-instructions.md](../../.github/copilot-instructions.md)** - GitHub Copilot config
- **[.claude/CLAUDE.md](../../.claude/CLAUDE.md)** - Claude AI config

### AI Development

- **[AI_DEVELOPMENT_GUIDE.md](AI_DEVELOPMENT_GUIDE.md)** - Comprehensive AI agent instructions
- **[../.github/copilot-instructions.md](../../.github/copilot-instructions.md)** - GitHub Copilot configuration
- **[../.claude/CLAUDE.md](../../.claude/CLAUDE.md)** - Claude AI configuration
- **[LOCATION_FEATURE.md](LOCATION_FEATURE.md)** - Location services guide

---

## 🏗️ Architecture

### Tech Stack

- **SwiftUI** - Modern declarative UI
- **SwiftData** - Persistent storage for favorites
- **Swift Charts** - Interactive data visualization
- **WidgetKit** - Home & Lock Screen widgets
- **AppIntents** - Widget configuration
- **UserNotifications** - Local notifications
- **CoreLocation** - GPS & location services
- **MapKit** - Location search

### Design Patterns

- **MVVM** - Model-View-ViewModel architecture
- **Observable** - Reactive state management with @Observable
- **Dependency Injection** - Environment-based dependencies
- **Async/Await** - Modern concurrency
- **Modular Components** - Reusable UI components

### Project Structure

```
weather/
├── App/
│   ├── weatherApp.swift              # App entry point
│   └── ContentView.swift             # Main view coordinator
├── Services/
│   ├── WeatherService.swift          # API integration
│   ├── LocationManager.swift         # Location services
│   ├── SettingsManager.swift         # User preferences
│   ├── NotificationManager.swift     # Notifications
│   └── FavoritesManager.swift        # Saved locations
├── Views/
│   ├── WeatherDetailView.swift       # Main weather display
│   ├── WeatherCards.swift            # Card components & charts
│   ├── LocationSearchView.swift      # Location search
│   ├── SettingsView.swift            # Settings interface
│   └── FavoritesView.swift           # Favorites manager
├── Components/
│   ├── GlassEffects.swift            # Glass UI effects
│   └── WeatherParticleEffects.swift  # Weather animations
├── Models/
│   └── SavedLocation.swift           # SwiftData model
└── Widgets/
    └── WeatherWidget.swift           # Widget bundle
```

---

## 🔧 Configuration

### Info.plist Keys

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show accurate weather information.</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### API Configuration

The app uses [Open-Meteo API](https://open-meteo.com) which:

- ✅ Free to use
- ✅ No API key required
- ✅ No registration needed
- ✅ High rate limits
- ✅ Global coverage

**Endpoint**: `https://api.open-meteo.com/v1/forecast`

---

## 🎯 Key Features Deep Dive

### Weather Particle Effects

Realistic weather animations:

- **Rain** - Falling raindrops with varying speeds
- **Snow** - Floating snowflakes with wobble
- **Lightning** - Random lightning flashes
- **Clouds** - Drifting cloud layers
- **Fog** - Rolling fog effects

Toggle in: Settings → Appearance → Weather Particles

### Interactive Charts

Built with Swift Charts:

- **Temperature Line Chart** - 24-hour forecast with gradient fill
- **Precipitation Bar Chart** - Hourly precipitation probability
- **Touch Interaction** - Drag to see detailed hour info
- **Smooth Animations** - Catmull-Rom interpolation
- **Custom Styling** - Theme-matched colors

### Favorites System

Powered by SwiftData:

- **Automatic Persistence** - Survives app restarts
- **iCloud Sync Ready** - Architecture supports CloudKit
- **Order Management** - Drag to reorder favorites
- **Duplicate Prevention** - Smart coordinate comparison
- **Quick Access** - One tap to switch locations

### Notification System

Smart local notifications:

- **Daily Forecast** - Scheduled at your preferred time
- **Severe Weather** - Critical alerts with `.defaultCritical` sound
- **Rain Alerts** - Checks next 2 hours for precipitation
- **Weather Changes** - Significant condition changes
- **Respect User Settings** - Only enabled notifications fire

---

## 🎨 Design System

### Liquid Glass Effect

Modern glass morphism with:

- Ultra-thin material backgrounds
- Border gradients (white to transparent)
- Soft shadows
- Interactive feedback on touch
- Tint color support

### Color Palette

Dynamic colors based on weather:

- **Clear Sky** - Blue → Cyan gradient
- **Partly Cloudy** - Blue → Gray
- **Cloudy** - Gray tones
- **Rain** - Blue → Dark gray
- **Snow** - Cyan → White
- **Thunderstorm** - Indigo → Gray

### Typography

System fonts with:

- **Large Titles** - Weather location names
- **Display** - Current temperature (72pt)
- **Headlines** - Card titles
- **Body** - Details and descriptions
- **Captions** - Timestamps and metadata

### SF Symbols

Native icons with:

- **Multicolor** - Weather conditions
- **Hierarchical** - UI elements
- **Symbol Effects** - Pulse, breathe, bounce
- **Variable Color** - Animated fills

---

## 🧪 Testing

### Unit Tests

Test coverage for:

- Weather service API calls
- Location manager functionality
- Settings persistence
- Favorites management
- Data formatting

### UI Tests

Automated flows:

- Launch and location permission
- Weather data display
- Location search and selection
- Favorite add/remove
- Settings changes

### Manual Testing

Checklist:

- [ ] All widget sizes display correctly
- [ ] Notifications fire at correct times
- [ ] Charts are interactive
- [ ] Particle effects animate
- [ ] Dark mode works throughout
- [ ] Settings persist
- [ ] Favorites sync

---

## 🐛 Known Issues & Limitations

### Current Limitations

- Weather maps not yet implemented (architecture ready)
- Apple Watch app not included (architecture ready)
- Open-Meteo API rate limits apply (60 requests/minute)
- Mesh gradients require iOS 18+ (graceful degradation)

### Planned Fixes

- Add weather radar visualization
- Implement Apple Watch complications
- Add weather map overlays
- Enhance widget interactivity

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftUI for all UI
- Add documentation for public APIs
- Write unit tests for new features
- Maintain existing architecture patterns

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Your Name**

- GitHub: [@yourusername](https://github.com/yourusername)
- Twitter: [@yourusername](https://twitter.com/yourusername)

---

## 🙏 Acknowledgments

### Frameworks & Tools

- **Apple** - SwiftUI, SwiftData, Charts, WidgetKit, CoreLocation
- **Open-Meteo** - Free weather API
- **SF Symbols** - Icon system

### Inspiration

- Apple Weather app
- Modern weather apps
- iOS design guidelines
- Material Design principles

---

## 📊 Stats

- **Lines of Code**: ~4,500
- **Files**: 15+ source files
- **Features**: 10 major enhancements
- **Supported Widgets**: 6 types
- **Chart Types**: 2 (Line + Bar)
- **Particle Effects**: 5 types
- **Settings Options**: 15+

---

## 🗺️ Roadmap

### v1.1 (Future)

- [ ] Weather radar maps
- [ ] Historical data charts
- [ ] Weather comparison view
- [ ] Photo weather sharing

### v1.2 (Future)

- [ ] Apple Watch app
- [ ] Watch complications
- [ ] Handoff support
- [ ] macOS app

### v2.0 (Future)

- [ ] Social features
- [ ] Weather photography
- [ ] Activity suggestions
- [ ] Weather journal

---

## 💬 FAQ

**Q: Does this app collect my location data?**  
A: No, location is only used to fetch weather and is never stored or shared.

**Q: Why don't I see weather particles?**  
A: Check Settings → Appearance → Weather Particles is enabled.

**Q: How often do widgets update?**  
A: Automatically every 30 minutes, or when you manually refresh the app.

**Q: Can I use this app without location services?**  
A: Yes! Use the search feature to manually enter any location.

**Q: Is there a cost to use this app?**  
A: No, the app and weather data are completely free.

**Q: What weather data source is used?**  
A: Open-Meteo, a free and open-source weather API.

---

## 📱 Contact & Support

### Bug Reports

Open an issue on [GitHub Issues](https://github.com/yourusername/weather-app/issues)

### Feature Requests

Use [GitHub Discussions](https://github.com/yourusername/weather-app/discussions)

### Email
<support@weatherapp.com>

---

## ⭐ Show Your Support

If you like this project, please give it a ⭐ on GitHub!

---

## 📅 Changelog

### v1.0.0 (February 2026)

- ✅ Initial release
- ✅ Real-time weather data
- ✅ 14-day forecasts
- ✅ Interactive charts
- ✅ Home & Lock Screen widgets
- ✅ Favorites management
- ✅ Smart notifications
- ✅ Weather animations
- ✅ Comprehensive settings
- ✅ Dark mode support

---

**Built with ❤️ using Swift and SwiftUI**

*Last updated: February 5, 2026*
