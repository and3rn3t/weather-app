# Weather App Setup

This is a modern iOS 18 weather app using the OpenMeteo API for comprehensive weather data.

## 🚀 Features

### Current Weather
- Real-time temperature with "feels like" temperature
- Weather condition with animated SF Symbols
- Adaptive background gradients based on weather conditions

### Detailed Weather Information
- **Wind Details**: Speed, direction (N/S/E/W), and gusts
- **UV Index**: Color-coded UV levels (Low/Moderate/High/Very High/Extreme)
- **Visibility**: Current visibility in miles
- **Atmospheric Pressure**: Surface pressure in hPa
- **Cloud Cover**: Percentage of cloud coverage
- **Dew Point**: Current dew point temperature
- **Precipitation**: Current precipitation amount
- **Humidity**: Relative humidity percentage

### Sun & Moon Information
- Sunrise and sunset times
- Total daylight duration
- Day/night indicator

### Forecasts
- **24-hour hourly forecast** with temperatures and conditions
- **7-day daily forecast** with:
  - High and low temperatures
  - Precipitation probability
  - UV index (color-coded)
  - Wind speed
  - Weather icons

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
- `WeatherDetailView.swift` - Detailed weather display with multiple cards
- `WeatherModels.swift` - Comprehensive data models for OpenMeteo API
- `WeatherService.swift` - Network service using async/await
- `LocationManager.swift` - Location handling with CoreLocation
- `weatherApp.swift` - App entry point

## 📱 How It Works

1. App requests location permission on first launch
2. Gets user's current location using CoreLocation
3. Fetches comprehensive weather data from OpenMeteo API
4. Displays weather in beautiful, organized cards:
   - Current conditions card
   - Sun/Moon times card
   - Hourly forecast (24 hours)
   - Daily forecast (7 days)
   - Detailed conditions grid (9 metrics)

## 🎨 Modern iOS Features Used

- **@Observable** macro for state management
- **async/await** for network requests
- **Swift Concurrency** throughout
- **SF Symbols** for weather icons with multicolor rendering
- **Material backgrounds** for glassmorphic effects
- **Adaptive gradients** based on weather conditions
- **Color-coded indicators** for UV index
- **Wind direction calculation** (compass directions)

## 🌐 OpenMeteo API

This app uses the free OpenMeteo API which requires **no API key**. The API provides:

### Current Weather Parameters
- Temperature & apparent temperature
- Weather code & conditions
- Wind speed, direction & gusts
- Humidity & dew point
- Surface pressure
- Cloud cover
- Visibility
- UV index
- Day/night indicator
- Precipitation

### Daily Forecast Parameters
- High & low temperatures
- Weather conditions
- Precipitation probability
- Sunrise & sunset times
- Maximum UV index
- Maximum wind speed & gusts

API Documentation: https://open-meteo.com/

## 📊 Weather Metrics Explained

### UV Index Scale
- **0-2 (Green)**: Low - Safe to be outside
- **3-5 (Yellow)**: Moderate - Use sun protection
- **6-7 (Orange)**: High - Protection essential
- **8-10 (Red)**: Very High - Extra precaution needed
- **11+ (Purple)**: Extreme - Avoid sun exposure

### Wind Direction
Displays compass directions: N, NE, E, SE, S, SW, W, NW

### Visibility
Measured in miles - important for driving and outdoor activities

### Dew Point
Temperature at which air becomes saturated - affects comfort level

## 🔧 Optional Enhancements

You can further enhance this app by:
- Adding search for other locations
- Saving favorite locations
- Adding weather alerts and warnings
- Implementing home screen widgets
- Adding more weather details (air quality, moon phases)
- Supporting multiple units (Celsius/Fahrenheit toggle)
- Adding weather radar
- Implementing weather notifications
- Adding historical weather data
## 🐛 Troubleshooting

If you see CoreLocation errors:
1. Make sure you've added the location permission to Info.plist
2. Ensure all files have been added to your target
3. Clean build folder (Cmd+Shift+K)
4. Rebuild the project

