# Screenshot Guide for App Store

This guide explains how to capture the required screenshots for the App Store and TestFlight.

## Required Sizes

### iPhone 6.9" (iPhone 17 Pro Max)

- **Resolution:** 1320 × 2868 pixels
- **Device:** iPhone 17 Pro Max
- **Required:** Yes (minimum for App Store submission)
- **Quantity:** 3-10 screenshots

### iPhone 6.3" (iPhone 17 Pro)

- **Resolution:** 1206 × 2622 pixels
- **Device:** iPhone 17 Pro
- **Required:** Yes (highly recommended)
- **Quantity:** 3-10 screenshots

### iPad Pro 13"

- **Resolution:** 2064 × 2752 pixels (portrait)
- **Device:** iPad Pro 13-inch (M5)
- **Required:** No (but recommended if app looks good on iPad)
- **Quantity:** 3-10 screenshots

## Screenshot Sequence

Present screenshots in this order to tell the app's story:

### 1. Main Weather View

**Show:** Current weather with Liquid Glass design

- Large temperature display
- Current conditions icon
- "Feels like" temperature
- Key weather metrics (humidity, wind, etc.)
- Beautiful gradient background
- Glass-styled cards

**Caption:** "Beautiful Liquid Glass weather forecasts"

### 2. Hourly Forecast Charts

**Show:** Interactive charts view

- Temperature chart with hourly data
- Precipitation probability chart
- Smooth animations
- Clean, readable design

**Caption:** "Interactive hourly forecasts with smooth charts"

### 3. Weather Maps

**Show:** Map view with weather overlay

- Satellite or temperature overlay
- Location markers
- Map controls
- Glass-styled map interface

**Caption:** "Detailed weather maps with multiple overlays"

### 4. Widgets Showcase

**Show:** Home Screen or Lock Screen with widgets

- Multiple widget sizes displayed
- Clean widget design
- Accurate weather data shown
- Optional: show different widget configurations

**Caption:** "Beautiful widgets for Home and Lock Screen"

### 5. Live Activities

**Show:** Lock Screen with Live Activity

- Dynamic Island showing weather (on Pro models)
- Lock Screen Live Activity
- Real-time updates visible

**Caption:** "Stay updated with Live Activities"

### 6. Settings & Themes

**Show:** Settings screen or theme selector

- Multiple theme options visible
- Clean settings interface
- Temperature unit toggle
- Customization options

**Caption:** "Customize themes and preferences"

### 7. Favorites

**Show:** Saved locations list

- Multiple favorite locations
- Easy-to-scan list view
- Quick access to saved cities

**Caption:** "Save your favorite locations"

### 8. Air Quality Index

**Show:** AQI details view

- AQI value and status
- Pollutant breakdown
- Color-coded indicators
- Health recommendations

**Caption:** "Monitor air quality with detailed insights"

## How to Capture Screenshots

### Method 1: Using Xcode Simulator

1. **Launch Simulator**

   ```bash
   # iPhone 17 Pro Max
   open -a Simulator --args -CurrentDeviceUDID 703ACBAC-D10E-42D0-A6BD-B39A20041011
   
   # iPhone 17 Pro
   open -a Simulator --args -CurrentDeviceUDID F6B26AA5-50CE-4FD9-8E1A-B49BC35178C5
   
   # iPad Pro 13-inch
   open -a Simulator --args -CurrentDeviceUDID B241516D-DA67-46DE-8B67-356E95F090C9
   ```

2. **Run the App**

   ```bash
   make build-release
   # Or run from Xcode with Release configuration
   ```

3. **Capture Screenshots**
   - **Simulator Method:** `Cmd + S` saves to Desktop
   - **macOS Screenshot:** `Cmd + Shift + 4` then select simulator window

4. **Remove Status Bar** (if needed)
   - Simulator → Features → Toggle Status Bar

### Method 2: Using Physical Device

1. **Connect Device**
   - Use iPhone 17 Pro Max or iPhone 17 Pro for best results

2. **Run App in Release Mode**
   - Select your device in Xcode
   - Choose "Release" configuration (Product → Scheme → Edit Scheme → Run → Release)
   - Run app

3. **Capture Screenshots**
   - Physical buttons: Volume Up + Side Button
   - Screenshots appear in Photos app

4. **Transfer to Mac**
   - AirDrop to Mac
   - Or sync via Photos/iCloud

### Method 3: Using Screenshot Automation (Advanced)

Create UI test that captures screens automatically:

```swift
// In weatherUITests
func testCaptureAppStoreScreenshots() {
    let app = XCUIApplication()
    app.launch()
    
    // Main weather view
    sleep(2)
    let screenshot1 = app.screenshot()
    let attachment1 = XCTAttachment(screenshot: screenshot1)
    attachment1.name = "01-main-weather-view"
    attachment1.lifetime = .keepAlways
    add(attachment1)
    
    // Navigate to charts
    app.buttons["Charts"].tap()
    sleep(1)
    let screenshot2 = app.screenshot()
    let attachment2 = XCTAttachment(screenshot: screenshot2)
    attachment2.name = "02-hourly-charts"
    attachment2.lifetime = .keepAlways
    add(attachment2)
    
    // Continue for each view...
}
```

Then run:

```bash
xcodebuild test \
  -project weather.xcodeproj \
  -scheme weather \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -resultBundlePath ./AppStoreScreenshots.xcresult
```

Screenshots are saved in the result bundle.

## Screenshot Best Practices

### Content

- ✅ Show real, realistic weather data
- ✅ Use visually appealing locations (San Francisco, Tokyo, Paris)
- ✅ Show variety of weather conditions (sunny, rainy, snowy)
- ✅ Ensure text is readable at small sizes
- ❌ Don't use placeholder or fake data
- ❌ Don't show bugs or incomplete features

### Design

- ✅ Clean status bar (full battery, strong signal)
- ✅ Consistent time across screenshots (e.g., 9:41 AM)
- ✅ Use Light mode or Dark mode consistently
- ✅ Show the app at its best visual state
- ❌ Don't include device frames (App Store adds them)
- ❌ Don't add text overlays (use captions field instead)

### Technical

- ✅ Exact pixel dimensions required
- ✅ PNG format (best quality)
- ✅ sRGB color space
- ✅ File size under 10MB each
- ❌ No transparency/alpha channel
- ❌ No borders or device frames added

## Editing Screenshots

### Recommended Tools

- **Photoshop/Sketch:** Professional editing
- **Pixelmator Pro:** Mac-native image editor
- **Preview:** Built-in Mac app (basic editing)
- **Figma:** Design mockups if needed

### Editing Tips

1. **Crop to Exact Size**
   - Use the exact pixel dimensions listed above
   - Maintain aspect ratio

2. **Clean Up Status Bar** (if needed)
   - Set time to 9:41 AM (Apple's standard)
   - Full battery icon
   - Full cellular/WiFi signal

3. **Optimize File Size**
   - Export as PNG-24
   - Quality: 100%
   - No compression artifacts

4. **Color Correction** (optional)
   - Adjust brightness/contrast slightly if needed
   - Ensure colors look vibrant but natural
   - Maintain consistency across all screenshots

## Screenshot Captions

App Store allows text captions for each screenshot. Keep them short and compelling:

### Examples

- "Beautiful Liquid Glass design for iOS 26"
- "Hourly forecasts with interactive charts"
- "Detailed weather maps and overlays"
- "Widgets for Home and Lock Screen"
- "Live Activities on your Lock Screen"
- "Customize themes to match your style"
- "Save favorite locations worldwide"
- "Air Quality Index with health insights"

## Uploading to App Store Connect

1. **Log in to App Store Connect**
   - <https://appstoreconnect.apple.com>

2. **Navigate to App**
   - My Apps → Andernet Weather → iOS App → Screenshots

3. **Select Device Size**
   - Choose "iPhone 6.9 Display" for Pro Max
   - Choose "iPhone 6.3 Display" for Pro

4. **Upload Screenshots**
   - Drag and drop images
   - Arrange in desired order (can reorder after upload)
   - Add optional captions

5. **Preview**
   - Use the preview tool to see how they'll appear
   - Check on different device sizes

6. **Save**
   - Screenshots apply to all territories unless you create localized versions

## Localization (Optional)

If you plan to localize:

- Create separate screenshot sets for each language
- Translate text in screenshots (if any UI text visible)
- Use location-appropriate locations (e.g., Tokyo for Japanese locale)
- Localized captions in each language

## Quick Checklist

Before submitting:

- [ ] iPhone 6.9" screenshots (3-10 images) ✅
- [ ] iPhone 6.3" screenshots (3-10 images) ✅  
- [ ] iPad Pro screenshots (optional but recommended)
- [ ] All screenshots are exact required dimensions
- [ ] PNG format, sRGB color space
- [ ] No device frames or text overlays
- [ ] Shows real app functionality
- [ ] Visually appealing and professional
- [ ] Uploaded in compelling story order
- [ ] Captions added (optional but helpful)

## Resources

- **Apple Screenshot Guidelines:** <https://developer.apple.com/app-store/product-page/>
- **App Store Connect Help:** <https://help.apple.com/app-store-connect/>
- **Design Resources:** <https://developer.apple.com/design/resources/>

## Sample Screenshot Sizes Reference

```
iPhone 17 Pro Max (6.9"):   1320 × 2868 px
iPhone 17 Pro (6.3"):       1206 × 2622 px
iPad Pro 13" (portrait):    2064 × 2752 px
iPad Pro 13" (landscape):   2752 × 2064 px
```

---

**Pro Tip:** Take screenshots in both Light and Dark mode, then choose the most visually appealing set for submission!
