# Features Guide

Detailed documentation for the Weather App's core features.

---

## Location Services

### GPS Location Detection

The app automatically detects your location using CoreLocation:

- **City and State Display**: Shows formatted location (e.g., "San Francisco, CA")
- **Reverse Geocoding**: Converts coordinates to readable names using `CLGeocoder`
- **Last Updated Time**: Shows when weather data was last refreshed

### Location Search

Search for any location worldwide:

1. **Tap the search button** (🔍) in the location header
2. **Type a location name** (city, state, or country)
3. **See results instantly** as you type
4. **Tap a result** to load weather for that location

**Implementation**: Uses `MKLocalSearch` for location queries with native iOS search UI.

---

## Timezone-Aware Display

Times are displayed in the **location's actual timezone**, not your device timezone.

### How It Works

- **Los Angeles sunrise**: 6:45 AM PST ✅
- **Tokyo sunset**: 5:30 PM JST ✅
- **London hourly forecast**: 3PM GMT ✅

The Open-Meteo API provides timezone information automatically with `timezone=auto`.

### Visual Indicator

A timezone badge shows the abbreviation (PST, EST, GMT) on the Sunrise/Sunset card.

---

## Pull-to-Refresh

Refresh weather data with a native iOS gesture:

1. **Pull down** on the weather view
2. **Release** when the refresh indicator appears
3. **Data refreshes** automatically
4. **Timestamp updates** with new information

---

## Interactive Charts

### Temperature Chart

- 24-hour temperature visualization using Swift Charts
- Color-coded by temperature (blue=cold, red=hot)
- Tap hours to highlight with point markers
- Gradient area fills for visual appeal

### Precipitation Chart

- Hourly precipitation probability bars
- Interactive touch and drag
- Real-time feedback on selected hour

---

## Weather Recommendations

Intelligent analysis provides context-aware suggestions:

| Recommendation | Condition | Color |
| -------------- | --------- | ----- |
| ☀️ Sun Protection | UV Index ≥ 6 | Orange |
| ☂️ Bring Umbrella | Rain > 30% in 6h | Blue |
| 🧥 Dress Warm | Feels like < 32°F | Cyan |
| 🌡️ Stay Cool | Feels like > 90°F | Red |
| 💨 Windy | Wind > 20 mph | Gray |
| 👁️ Low Visibility | < 3.1 miles | Purple |
| ✅ Pleasant | No alerts | Green |

---

## Temperature Trend

Shows warming/cooling trend in next 6 hours:

- ⬆️ **Warming** (orange): Rising > 2°
- ⬇️ **Cooling** (blue): Falling > 2°
- ➖ **Steady** (gray): Stable

---

## Favorite Locations

Save and manage multiple locations:

- **Save Unlimited Locations**: Add any location worldwide
- **Quick Switching**: Tap to switch between saved locations
- **Drag to Reorder**: Organize your favorites
- **Swipe to Delete**: Remove locations easily
- **Star Button**: Quick favorite from weather view

**Storage**: Uses SwiftData for persistent storage across app launches.

---

## Notifications

### Alert Types

| Type | Description |
| ---- | ----------- |
| Severe Weather | Critical warnings for dangerous conditions |
| Daily Forecast | Morning weather summary at chosen time |
| Rain Alerts | Notification when rain expected within 2 hours |
| Weather Changes | Alerts for significant condition changes |

### Configuration

Go to **Settings → Notifications** to:

- Enable/disable notifications
- Set daily forecast time
- Toggle individual alert types

---

## Widgets

### Home Screen Widgets

| Size | Content |
| ---- | ------- |
| Small | Current temp and conditions |
| Medium | Current weather + key stats |
| Large | Current weather + hourly forecast |

### Lock Screen Widgets

| Style | Content |
| ----- | ------- |
| Circular | Temperature gauge |
| Rectangular | Detailed weather info |
| Inline | Text summary |

### Configuration

1. Long press home screen → Tap + button
2. Search for "Weather"
3. Choose size and add
4. Tap "Edit Widget" to configure location

---

## Glass UI Design

The app uses modern glass morphism effects:

- **Ultra-thin material** backgrounds
- **Subtle borders** at 30% opacity
- **Corner radius**: 16-24pt
- **Shadows**: 10pt blur, 5pt offset

### Weather Animations

- **Rain**: Falling raindrops with varying speeds
- **Snow**: Gentle snowflakes drifting down
- **Clouds**: Floating cloud particles
- **Lightning**: Random flash effects
- **Fog**: Misty atmosphere effect
