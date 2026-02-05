# Visual Feature Map

A visual guide to where all the new advanced features are located in the app.

---

## 🗺️ App Structure Overview

```
WeatherDetailView
│
├── 📍 Location Header
│   ├── Location name with icon
│   ├── Last updated timestamp
│   └── Search button (with haptics)
│
├── 🌡️ Current Weather Card
│   ├── Large weather icon (with bounce effect)
│   ├── Temperature display (tappable with haptics) ← ENHANCED
│   ├── Condition description
│   └── "Feels like" temperature
│
└── 📦 Glass Effect Container
    │
    ├── 💡 Weather Recommendations Card ← NEW
    │   ├── Card title
    │   ├── Recommendation rows (up to 6)
    │   │   ├── Sun Protection (UV ≥ 6)
    │   │   ├── Bring Umbrella (rain > 30%)
    │   │   ├── Dress Warm (< 32°F)
    │   │   ├── Stay Cool (> 90°F)
    │   │   ├── Windy Conditions (> 20 mph)
    │   │   ├── Low Visibility (< 3.1 mi)
    │   │   └── Pleasant Weather (default)
    │   └── Color-coded badges
    │
    ├── 🌅 Sun & Moon Card
    │   ├── Sunrise time
    │   ├── Sunset time
    │   └── Daylight duration
    │
    ├── 📊 Hourly Forecast Card ← ENHANCED
    │   ├── Header with trend indicator ← NEW
    │   │   ├── "Hourly Forecast" title
    │   │   └── Trend badge (Warming/Cooling/Steady)
    │   │
    │   ├── Temperature Chart ← NEW
    │   │   ├── 24-hour line chart
    │   │   ├── Gradient area fill
    │   │   ├── Color-coded by temperature
    │   │   ├── Point marker for selection
    │   │   └── Temperature annotation
    │   │
    │   ├── Divider
    │   │
    │   └── Hourly Items List ← ENHANCED
    │       └── Each hour item (tappable)
    │           ├── Time label
    │           ├── Weather icon (scales on select)
    │           ├── Temperature
    │           ├── Selection highlight (blue bg)
    │           └── Haptic feedback on tap
    │
    ├── 📅 Daily Forecast Card
    │   └── 7-day forecast rows
    │
    ├── 🌍 Air Quality Card ← NEW
    │   ├── AQI category badge
    │   ├── Circular gauge
    │   │   ├── AQI number in center
    │   │   └── Color-coded progress ring
    │   ├── Pollutant measurements
    │   │   ├── PM2.5
    │   │   ├── PM10
    │   │   └── Ozone (O₃)
    │   └── Health description
    │
    └── 📋 Weather Details Card
        ├── Wind speed & direction
        ├── Humidity
        ├── UV index
        ├── Visibility
        ├── Pressure
        ├── Cloud cover
        ├── Dew point
        └── Precipitation
```

---

## 🎨 Visual Hierarchy

### Card Flow (Top to Bottom)

```
┌─────────────────────────────────────┐
│  📍 Location Header                 │  ← Always visible
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│                                     │
│         🌡️ 72°                     │  ← Tap for bounce
│      Current Weather                │
│                                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  💡 Recommendations          ← NEW  │
│                                     │
│  ☀️ Sun Protection                 │
│  Use sunscreen. UV is high.         │
│                                     │
│  ☂️ Bring Umbrella                 │
│  60% chance of rain later.          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  🌅 Sun & Moon                      │
│                                     │
│  Sunrise: 7:10 AM | Sunset: 5:30 PM │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  📊 Hourly Forecast  ↗️ Warming     │  ← Trend badge
│                                     │
│      Temperature Chart    ← NEW     │
│     ╱╲                              │
│    ╱  ╲      ╱╲                    │
│   ╱    ╲    ╱  ╲                   │
│  ╱      ╲  ╱    ╲                  │
│ ────────────────────                │
│ 9a  12p  3p  6p  9p                │
│                                     │
│ ──────────────────────────          │
│                                     │
│  🕐  🕑  🕒  🕓  🕔  🕕             │  ← Tap to select
│  9a  10  11  12p 1p  2p             │
│  ☀️  ☀️  ⛅  ⛅  ☁️  ☁️           │
│  72° 74° 76° 78° 77° 75°           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  📅 7-Day Forecast                  │
│                                     │
│  Wed  ⛅ 💧30%     L: 65° H: 78°   │
│  Thu  ☀️         L: 68° H: 82°   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  🌍 Air Quality          ← NEW      │
│                                     │
│      ┏━━━━━━┓    PM2.5: 45 μg/m³  │
│      ┃  52  ┃    PM10: 30 μg/m³   │
│      ┃ AQI  ┃    O₃: 42 ppb       │
│      ┗━━━━━━┛                      │
│   🟡 Moderate                       │
│                                     │
│  Air quality is acceptable.         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  📋 Current Conditions              │
│                                     │
│  💨 Wind  💧 Humidity  🌪️ Gusts   │
│  ☀️ UV    👁️ Vis      ⚖️ Press  │
└─────────────────────────────────────┘
```

---

## 🎯 Interactive Elements Map

### Tappable Areas

```
WeatherDetailView
├── 🔘 Temperature Display → Bounce animation + haptic
├── 🔘 Search Button → Opens location search + haptic
├── 🔘 Each Hour Item → Selects hour + updates chart + haptic
└── 🔄 Pull to Refresh → Reloads weather data
```

### Visual Feedback

```
Interaction             Animation              Haptic    Duration
──────────────────────────────────────────────────────────────────
Tap Temperature    →   Scale 1.0 → 1.1 → 1.0   Light     0.3s
Tap Hour Item      →   Highlight + Icon Scale  Light     0.3s
Tap Search         →   Button feedback         Light     Instant
Pull to Refresh    →   Spinner rotation        None      Variable
```

---

## 🎨 Color Coding System

### Temperature Chart Colors

```
Temperature Range          Color        Usage
─────────────────────────────────────────────────
Below 32°F (freezing)  →   🔵 Blue      Very cold
32°F - 50°F (cold)     →   🔷 Cyan      Cold
50°F - 70°F (mild)     →   🟢 Green     Comfortable
70°F - 85°F (warm)     →   🟠 Orange    Warm
Above 85°F (hot)       →   🔴 Red       Hot
```

### Recommendation Badge Colors

```
Recommendation Type        Color        Priority
───────────────────────────────────────────────────
Sun Protection         →   🟠 Orange    High
Bring Umbrella         →   🔵 Blue      Medium
Dress Warm             →   🔷 Cyan      High
Stay Cool              →   🔴 Red       High
Windy Conditions       →   ⚫ Gray      Medium
Low Visibility         →   🟣 Purple    High
Pleasant Weather       →   🟢 Green     Low (default)
```

### AQI Category Colors

```
AQI Range     Category                 Color
───────────────────────────────────────────────────
0-50      →   Good                 →   🟢 Green
51-100    →   Moderate             →   🟡 Yellow
101-150   →   Unhealthy (Sensitive)→   🟠 Orange
151-200   →   Unhealthy            →   🔴 Red
201+      →   Very Unhealthy       →   🟣 Purple
```

### UV Index Colors

```
UV Value      Category             Color
─────────────────────────────────────────
0-3       →   Low              →   🟢 Green
3-6       →   Moderate         →   🟡 Yellow
6-8       →   High             →   🟠 Orange
8-11      →   Very High        →   🔴 Red
11+       →   Extreme          →   🟣 Purple
```

---

## 📊 Data Flow Diagram

### Temperature Chart & Selection

```
User Interaction
       ↓
┌──────────────────┐
│  Tap Hour Item   │
└──────────────────┘
       ↓
┌──────────────────┐
│  Haptic Feedback │ ← UIImpactFeedbackGenerator
└──────────────────┘
       ↓
┌──────────────────┐
│ Update @State    │ ← selectedHour: Int?
└──────────────────┘
       ↓
┌──────────────────┐     ┌─────────────────┐
│  Update Chart    │ ←→ │  Update Hour    │
│  - Add Point     │     │  - Highlight    │
│  - Add Rule      │     │  - Scale Icon   │
│  - Annotation    │     │  - Bold Text    │
└──────────────────┘     └─────────────────┘
       ↓
   Spring Animation (0.3s, damping: 0.7)
```

### Recommendations Generation

```
Weather Data Input
       ↓
┌─────────────────────┐
│  Check Conditions   │
│  - UV Index         │
│  - Rain Probability │
│  - Temperature      │
│  - Wind Speed       │
│  - Visibility       │
└─────────────────────┘
       ↓
┌─────────────────────┐
│  Generate Array of  │
│  Recommendations    │
└─────────────────────┘
       ↓
┌─────────────────────┐
│  Sort by Priority   │
│  - Safety first     │
│  - Comfort second   │
└─────────────────────┘
       ↓
┌─────────────────────┐
│  Display in Card    │
│  with Color Badges  │
└─────────────────────┘
```

### Trend Calculation

```
Hourly Temperature Array
       ↓
┌──────────────────────┐
│  Take First 3 Hours  │ → Calculate Average
└──────────────────────┘
       ↓
┌──────────────────────┐
│  Take Next 3 Hours   │ → Calculate Average
└──────────────────────┘
       ↓
┌──────────────────────┐
│  Calculate Difference│
└──────────────────────┘
       ↓
    Is diff > 2?
    ┌──Yes──→ "Warming" (🟠 Orange)
    │
    └──No──→ Is diff < -2?
            ┌──Yes──→ "Cooling" (🔵 Blue)
            │
            └──No──→ "Steady" (⚫ Gray)
```

---

## 🔧 Component Relationships

### Parent-Child View Hierarchy

```
WeatherDetailView (Parent)
│
├── LocationHeader
│   └── Button → onSearchTapped()
│
├── CurrentWeatherCard
│   ├── @EnvironmentObject settings
│   └── Button → haptic + animation
│
├── GlassEffectContainer
│   │
│   ├── WeatherRecommendationsCard
│   │   ├── receives: current, hourly
│   │   └── computed: recommendations
│   │
│   ├── SunMoonCard
│   │   └── receives: daily, isDay, timezone
│   │
│   ├── HourlyForecastCard
│   │   ├── @State selectedHour
│   │   ├── TemperatureChart
│   │   │   ├── @Binding selectedHour
│   │   │   └── @EnvironmentObject settings
│   │   │
│   │   ├── HourlyWeatherItem (×24)
│   │   │   ├── receives: isSelected
│   │   │   ├── @EnvironmentObject settings
│   │   │   └── onTapGesture → update selectedHour
│   │   │
│   │   └── computed: temperatureTrend
│   │
│   ├── DailyForecastCard
│   │   ├── DailyWeatherRow (×7)
│   │   └── @EnvironmentObject settings
│   │
│   ├── AirQualityCard
│   │   ├── receives: current
│   │   ├── InfoRow (×3)
│   │   └── computed: mockAQI, aqiCategory
│   │
│   └── WeatherDetailsCard
│       ├── WeatherDetailItem (×9)
│       └── @EnvironmentObject settings
```

### State Management Flow

```
ContentView (Root)
    │
    ├── @StateObject locationManager
    ├── @StateObject weatherService
    └── @StateObject settings
        │
        └── .environmentObject(settings)
                │
                ├─→ CurrentWeatherCard
                ├─→ HourlyForecastCard
                │    └─→ TemperatureChart
                │    └─→ HourlyWeatherItem
                ├─→ DailyForecastCard
                └─→ WeatherDetailsCard
```

---

## 🎬 Animation Sequence

### Hour Selection Animation

```
Frame 0ms: User taps hour item
    │
    ├─→ Haptic feedback fires (instant)
    │
    └─→ State change: selectedHour = tappedIndex

Frame 0-300ms: Spring animation
    │
    ├─→ Hour Item
    │   ├─→ Background: clear → blue (fade in)
    │   ├─→ Text: regular → bold
    │   ├─→ Icon: scale 1.0 → 1.2
    │   └─→ Symbol effect: bounce
    │
    └─→ Temperature Chart
        ├─→ Point mark appears (fade in)
        ├─→ Rule line appears (fade in)
        └─→ Annotation appears (slide up)

Frame 300ms: Animation complete
    │
    └─→ Resting state (selected)
```

### Temperature Tap Animation

```
Frame 0ms: User taps temperature
    │
    ├─→ Haptic feedback fires (instant)
    │
    └─→ State change: isTapped = true

Frame 0-300ms: Spring animation
    │
    └─→ Temperature text
        └─→ Scale: 1.0 → 1.1

Frame 300ms: State reset
    │
    └─→ isTapped = false

Frame 300-600ms: Return animation
    │
    └─→ Temperature text
        └─→ Scale: 1.1 → 1.0

Frame 600ms: Animation complete
```

---

## 📐 Layout Measurements

### Card Spacing

```
Vertical spacing between cards:
├── LocationHeader        : 20pt padding
├── CurrentWeatherCard    : 20pt spacing
├── GlassEffectContainer  : 20pt spacing
    ├── Card spacing      : 20pt each
    └── Container spacing : 30pt (enhanced)
```

### Corner Radii

```
Component                  Radius
────────────────────────────────────
LocationHeader         →   16pt
CurrentWeatherCard     →   24pt
HourlyItem highlight   →   12pt
Recommendation row     →   12pt
Standard cards         →   20pt
Badge/Capsule          →   Full (Capsule())
Search button          →   Full (Circle())
```

### Touch Targets

```
Element                   Size
───────────────────────────────────
Search button         →   44×44pt ✅
Temperature button    →   Large (>44pt) ✅
Hour item             →   60×~80pt ✅
Recommendation row    →   Full width ✅
```

---

## 🎯 Accessibility Tree

### VoiceOver Navigation Order

```
1. Location Header
   ├─ "Location: San Francisco"
   └─ "Search" button (activatable)

2. Current Weather Card
   ├─ "Weather condition: Partly cloudy"
   ├─ "Current temperature" → "72 degrees"
   └─ "Feels like temperature: 70 degrees"

3. Weather Recommendations
   ├─ "Recommendations"
   ├─ "Sun Protection. UV index is high..."
   └─ "Bring Umbrella. 60% chance of rain..."

4. Sun & Moon
   ├─ "Daylight"
   ├─ "Sunrise: 7:10 AM"
   └─ "Sunset: 5:30 PM"

5. Hourly Forecast
   ├─ "Hourly Forecast. Temperature trend: Warming"
   ├─ "Temperature chart" (chart elements)
   └─ Hour items (each):
       "9 AM, Sunny, 72 degrees" (activatable)

6. Daily Forecast
   └─ Each day row with full info

7. Air Quality
   ├─ "Air Quality: Moderate"
   └─ Pollutant readings

8. Weather Details
   └─ Each detail with label and value
```

---

## 🎨 Dark Mode Variations

### Color Adaptations

```
Element                Light Mode          Dark Mode
──────────────────────────────────────────────────────
Backgrounds        →  Light glass      → Dark glass
Text               →  Black/Gray       → White/Gray
Accent colors      →  Vibrant          → Slightly muted
Chart gradients    →  Full opacity     → Reduced opacity
Glass effects      →  Light blur       → Dark blur
Selections         →  Blue.opacity(15%)→ Blue.opacity(20%)
```

---

## 📱 Responsive Breakpoints

### iPhone Size Adaptations

```
iPhone SE (375pt width)
├─→ Chart: Full width
├─→ Hour items: 60pt width (scrollable)
└─→ Cards: Single column

iPhone Pro Max (430pt width)
├─→ Chart: Full width (more room)
├─→ Hour items: 60pt width (more visible)
└─→ Cards: Single column (wider)

iPad (768pt+ width)
├─→ Could use multi-column layout
├─→ Larger chart with more detail
└─→ Side-by-side cards possible
```

---

## 🎯 Quick Reference

### Finding Specific Features in Code

```
Feature                      Location in File
─────────────────────────────────────────────────────
Interactive Chart        →   Line 416: TemperatureChart
Recommendations          →   Line 497: WeatherRecommendationsCard
Temperature Trend        →   Line 406: temperatureTrend property
Hour Selection           →   Line 417: @State selectedHour
AQI Card                 →   Line 572: AirQualityCard
Haptic Feedback          →   Line 388: UIImpactFeedbackGenerator
Accessibility Labels     →   Line 157: .accessibilityLabel()
Color Mapping            →   Line 449: temperatureColor()
Spring Animations        →   Line 394: .spring(response:damping:)
```

---

## 🔍 Debug Views

### Testing Specific Features

```swift
// Test chart with custom data
TemperatureChart(
    hourly: mockHourlyData,
    timezone: "America/Los_Angeles",
    selectedHour: .constant(5)
)
.environmentObject(settings)

// Test recommendations with extreme conditions
WeatherRecommendationsCard(
    current: extremeWeatherData,
    hourly: hourlyWithHighRain
)

// Test AQI with different values
AirQualityCard(current: weatherData)
// Edit mockAQI computed property to test categories
```

---

This visual map helps you understand where everything is and how it all fits together! 🗺️✨
