# Weather App Setup

This is a modern iOS 18 weather app using the OpenMeteo API for weather data.

## 🚀 Features

- Real-time weather data using OpenMeteo API (no API key required!)
- Current weather conditions with temperature and weather icons
- 24-hour hourly forecast
- 7-day daily forecast
- Weather details (wind speed, humidity)
- Beautiful, adaptive UI with weather-based background gradients
- Location-based weather using CoreLocation

## ⚙️ Required Configuration

### Add Location Permission to Info.plist

You **must** add location permissions to your app's Info.plist file:

1. In Xcode, open your project navigator
2. Find and select `Info.plist`
3. Add the following key-value pair:
   - **Key**: `NSLocationWhenInUseUsageDescription`
   - **Type**: String
   - **Value**: "We need your location to show weather for your area"

Alternatively, in the **Info** tab of your target settings:
1. Click the **+** button under "Custom iOS Target Properties"
2. Add: **Privacy - Location When In Use Usage Description**
3. Set the value to: "We need your location to show weather for your area"

### Project Structure

- `ContentView.swift` - Main view with loading, error, and welcome states
- `WeatherDetailView.swift` - Detailed weather display with cards
- `WeatherModels.swift` - Data models for OpenMeteo API responses
- `WeatherService.swift` - Network service using async/await
- `LocationManager.swift` - Location handling with CoreLocation
- `weatherApp.swift` - App entry point

## 📱 How It Works

1. App requests location permission on first launch
2. Gets user's current location using CoreLocation
3. Fetches weather data from OpenMeteo API
4. Displays current weather, hourly forecast, and 7-day forecast
5. Updates UI with weather-appropriate background colors

## 🎨 Modern iOS Features Used

- **@Observable** macro for state management
- **async/await** for network requests
- **Swift Concurrency** throughout
- **SF Symbols** for weather icons with multicolor rendering
- **Material backgrounds** for glassmorphic effects
- **Adaptive gradients** based on weather conditions

## 🌐 OpenMeteo API

This app uses the free OpenMeteo API which requires **no API key**. The API provides:
- Current weather conditions
- Hourly forecasts
- Daily forecasts
- Various weather parameters

API Documentation: https://open-meteo.com/

## 🔧 Optional Enhancements

You can further enhance this app by:
- Adding search for other locations
- Saving favorite locations
- Adding weather alerts
- Implementing widgets
- Adding more weather details (UV index, sunrise/sunset)
- Supporting multiple units (Celsius/Fahrenheit)
