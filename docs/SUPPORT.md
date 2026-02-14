# Andernet Weather Support

Welcome to Andernet Weather support! This document provides help for beta testers and users.

## Contact Information

- **Email:** <support@andernet.dev>
- **GitHub Issues:** [github.com/and3rn3t/weather-app/issues](https://github.com/and3rn3t/weather-app/issues)
- **TestFlight Feedback:** Use the built-in TestFlight feedback tool

## Frequently Asked Questions

### General Questions

**Q: Is Andernet Weather free?**
A: Yes, completely free with no ads, in-app purchases, or subscriptions.

**Q: What iOS version is required?**
A: iOS 17.0 or later. The app is designed for iOS 26 with Liquid Glass effects.

**Q: Does it work offline?**
A: Weather data is cached for up to 1 hour, so you can view recent forecasts offline. New data requires an internet connection.

**Q: Where does the weather data come from?**
A: We use Open-Meteo, a free, open-source weather API with accurate global forecasts.

### Location & Privacy

**Q: Why does the app need my location?**
A: To provide accurate weather forecasts for your current area. Location is only used for weather data.

**Q: Is my location tracked or shared?**
A: No. Location is used only to fetch weather from the Open-Meteo API. We don't track, store, or share your location.

**Q: Can I use the app without location services?**
A: Yes! Search for any city manually or save favorite locations.

**Q: What's "Always Allow" location used for?**
A: Optional feature to auto-update widgets and provide location-based notifications. You can use "While Using" instead.

### Features

**Q: How do I add favorite locations?**
A: Search for a city, then tap the star icon to save it as a favorite.

**Q: How do I add widgets?**
A: Long-press your Home Screen → tap "+" → search "Andernet Weather" → choose size → Add Widget.

**Q: Do Live Activities work?**
A: Yes! Start a Live Activity from the main screen to show weather on your Lock Screen and Dynamic Island.

**Q: Can I change temperature units?**
A: Yes, go to Settings → choose Celsius (°C) or Fahrenheit (°F).

**Q: What weather data is shown?**

- Current temperature and "feels like"
- Hourly forecast (24 hours)
- 7-day forecast
- Precipitation probability and amount
- Wind speed and direction
- Humidity percentage
- UV Index
- Air Quality Index (AQI)
- Sunrise/sunset times

### Widgets

**Q: Why isn't my widget updating?**
A: iOS limits widget refresh frequency. Widgets typically update every 15-60 minutes. Open the app to force refresh.

**Q: Can I customize widget appearance?**
A: Widgets adapt to your chosen theme from Settings. More customization options coming soon.

**Q: Widget shows "No Data"?**
A: This means the app hasn't fetched weather yet. Open the app once to initialize data.

### Notifications

**Q: How do I enable weather alerts?**
A: Settings → Notifications → Enable weather alerts. You can customize alert types and timing.

**Q: I'm not receiving notifications.**
A: Check iOS Settings → Andernet Weather → Notifications → ensure "Allow Notifications" is enabled.

### Troubleshooting

**Q: The app won't open or crashes.**

1. Force quit the app (swipe up in App Switcher)
2. Restart your device
3. If issue persists, delete and reinstall
4. Report the issue via TestFlight Feedback

**Q: Weather data seems inaccurate.**
A: Open-Meteo provides accurate forecasts, but weather can be unpredictable. Try refreshing (pull down on main screen).

**Q: Location won't update.**

1. Check iOS Settings → Privacy & Security → Location Services → Andernet Weather
2. Ensure permission is "While Using" or "Always"
3. Try toggling location services off/on
4. Restart the app

**Q: Maps won't load.**

1. Check internet connection
2. Ensure MapKit isn't restricted (Settings → Screen Time → Content & Privacy)
3. Try force-refreshing the map

**Q: Settings aren't saving.**
A: This is a bug! Please report via TestFlight with steps to reproduce.

### Beta Testing (TestFlight)

**Q: How do I provide feedback?**

1. **TestFlight Feedback:** Shake device while in-app → "Send Beta Feedback"
2. **Screenshots:** Take screenshot → "Send to Developer" in TestFlight
3. **Email:** <support@andernet.dev> with device model and iOS version
4. **GitHub:** File an issue at github.com/and3rn3t/weather-app

**Q: What should I test?**

- All major features (search, favorites, maps, widgets)
- Different locations (international cities)
- Widget refresh behavior
- Live Activities
- Accessibility features (VoiceOver, Dynamic Type)
- Dark/Light mode switching
- Different network conditions

**Q: Will my data transfer to the App Store version?**
A: Yes, if you use the same Apple ID. Favorites and settings persist.

**Q: Can I install both TestFlight and App Store versions?**
A: No, they share the same bundle ID. Uninstall beta before installing from App Store.

### Known Issues

**Current Beta Limitations:**

- WeatherParticle effects temporarily disabled (will return in next update)
- Some international locations may need manual search
- Widget refresh timing controlled by iOS (not customizable)

### Accessibility

**Q: Does the app support VoiceOver?**
A: Yes! All interactive elements have accessibility labels. Report any missing labels.

**Q: Can I increase text size?**
A: Yes, the app respects iOS Dynamic Type settings (Settings → Accessibility → Display & Text Size).

**Q: Does it support Reduce Motion?**
A: Yes, animations are simplified when Reduce Motion is enabled.

## Reporting Bugs

When reporting bugs, please include:

1. **Device:** iPhone model (e.g., iPhone 17 Pro)
2. **iOS Version:** (e.g., iOS 26.2)
3. **App Version:** (visible in TestFlight)
4. **Steps to Reproduce:** What you did before the bug occurred
5. **Expected Behavior:** What should have happened
6. **Actual Behavior:** What actually happened
7. **Screenshots/Screen Recordings:** If applicable

## Feature Requests

We'd love to hear your ideas! Submit feature requests via:

- GitHub Discussions: [github.com/and3rn3t/weather-app/discussions](https://github.com/and3rn3t/weather-app/discussions)
- Email: <support@andernet.dev> (subject: "Feature Request")
- TestFlight feedback

## Privacy & Data

**What data is collected?**
See our [Privacy Policy](PRIVACY_POLICY.md) for complete details.

**TLDR:**

- Location used only for weather (not tracked/shared)
- No advertising or analytics
- Data stored locally on your device
- No account required

## Credits

- **Weather Data:** [Open-Meteo](https://open-meteo.com) (CC BY 4.0)
- **Design:** iOS 26 Liquid Glass design language
- **Icons:** SF Symbols by Apple

## Version History

### v1.0 (Current Beta)

- Initial beta release
- Liquid Glass design
- Hourly/daily forecasts
- Widgets & Live Activities
- Air Quality Index
- Weather maps
- Siri Shortcuts

## Thank You

Thank you for beta testing Andernet Weather! Your feedback helps make the app better for everyone. 🌤️

---

**Last Updated:** February 6, 2026
