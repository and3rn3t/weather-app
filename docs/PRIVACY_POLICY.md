# Privacy Policy for Andernet Weather

**Last Updated:** February 6, 2026

Andernet Weather ("we", "our", or "the app") is committed to protecting your privacy. This privacy policy explains what data we collect, how we use it, and your rights regarding your information.

## Information We Collect

### Location Data

The app collects your device's precise location to provide accurate weather forecasts for your current location.

- **Type:** Precise Location (latitude/longitude)
- **Purpose:** Fetch weather data for your area
- **Collection:** Only when app is in use (foreground and background)
- **Storage:** Stored locally on your device only
- **Sharing:** Not shared with third parties
- **Linked to You:** No - location data is not linked to your identity

### Weather Data

We retrieve weather information from the Open-Meteo API (<https://open-meteo.com>) based on your location coordinates.

- **API Provider:** Open-Meteo (open-source, free weather API)
- **Data Sent:** Only geographic coordinates (latitude/longitude)
- **No Account Required:** The weather API does not require registration or tracking

### Saved Locations (Favorites)

When you save favorite locations, this data is stored locally on your device using SwiftData.

- **Storage:** Local device only via SwiftData
- **Syncing:** Not synced to iCloud or external servers
- **Control:** You can delete favorites anytime

### App Settings

Your preferences (temperature units, theme, notification settings) are stored locally using UserDefaults.

- **Storage:** Local device only
- **Purpose:** Maintain your app preferences
- **Sharing:** Never shared

## Data We Do NOT Collect

- ❌ No personal identifiable information (name, email, phone)
- ❌ No user accounts or authentication
- ❌ No tracking across apps or websites
- ❌ No advertising identifiers
- ❌ No analytics or crash reporting services
- ❌ No cookies or web tracking
- ❌ No payment information (app is free)

## How We Use Your Information

Your location is used solely to:

1. Fetch current weather conditions for your area
2. Provide hourly and daily forecasts
3. Display weather on widgets and Live Activities
4. Send weather notifications (if you enable them)

All data processing happens locally on your device.

## Third-Party Services

### Open-Meteo Weather API

We use Open-Meteo's free weather API to retrieve forecast data.

- **Website:** <https://open-meteo.com>
- **Privacy:** Open-source, no tracking, no API key required
- **Data Sent:** Only coordinates (no personal information)
- **Data Received:** Public weather information

### Apple Services

The app uses standard Apple frameworks:

- **MapKit:** For displaying weather maps
- **CoreLocation:** For determining your location
- **WidgetKit:** For Home/Lock Screen widgets
- **UserNotifications:** For weather alerts (opt-in)

These services follow Apple's Privacy Policy.

## Background Location Usage

If you enable "Always Allow" location access, the app can:

- Update widgets automatically
- Refresh weather when you change locations
- Provide timely weather notifications

**You control this:** Location permission can be changed anytime in iOS Settings.

## Data Retention

- **Location Data:** Not stored permanently; used only to fetch weather
- **Favorites:** Stored until you delete them
- **Settings:** Stored until you delete the app
- **Weather Cache:** Automatically cleared after 1 hour

## Your Rights

You have the right to:

- **Access:** All data is stored locally; you can view it in the app
- **Delete:** Remove favorites, clear cache, or delete the app
- **Control Location:** Change permission in iOS Settings → Andernet Weather
- **Opt-Out of Notifications:** Disable in iOS Settings or within the app

## Children's Privacy

Andernet Weather does not collect personal information from anyone, including children under 13. The app has a 4+ age rating and is safe for all ages.

## Changes to This Policy

We may update this privacy policy to reflect app updates or legal requirements. Changes will be posted in this document with an updated "Last Updated" date.

## Security

All data is stored securely on your device using iOS's built-in security features:

- SwiftData encrypted storage
- Secure UserDefaults
- No data transmission except weather API calls (HTTPS)

## Contact Us

If you have questions about this privacy policy or data practices:

- **Email:** <support@andernet.dev>
- **Website:** <https://andernet.dev/weather>
- **GitHub:** <https://github.com/and3rn3t/weather-app>

## Compliance

This app complies with:

- Apple App Store Review Guidelines
- Apple's Privacy Manifest requirements
- GDPR (General Data Protection Regulation)
- CCPA (California Consumer Privacy Act)

## App Store Privacy Nutrition Labels

As shown in the App Store:

**Data Used to Track You:** None

**Data Linked to You:** None

**Data Not Linked to You:**

- Location (Precise) - for app functionality only
