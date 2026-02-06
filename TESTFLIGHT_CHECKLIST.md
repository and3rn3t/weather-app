# TestFlight Distribution Checklist

**App:** Andernet Weather v1.0 (Build 1)  
**Date:** February 6, 2026  
**Status:** Ready for TestFlight Distribution

## ✅ Completed Tasks

### Technical Preparation

- [x] **Release build successful** - Archive created at `build/weather.xcarchive`
- [x] **Code signing configured** - Using Apple Development certificate
- [x] **Bundle ID set** - `dev.andernet.weather`
- [x] **Team ID configured** - C8U3P6AJ6L
- [x] **Export options ready** - `ExportOptions.plist` configured for App Store Connect
- [x] **Version info set** - v1.0, build 1
- [x] **Privacy manifest included** - `PrivacyInfo.xcprivacy`
- [x] **Entitlements configured** - Location, Siri, Background modes

### Documentation Created

- [x] **Privacy Policy** - `PRIVACY_POLICY.md`
- [x] **Support Documentation** - `SUPPORT.md`
- [x] **App Store Metadata** - `AppStoreMetadata.json`
- [x] **Screenshot Guide** - `SCREENSHOTS.md`
- [x] **Build updated** - Makefile fixed for missing tools

## 🎯 Next Steps to Complete

### 1. Upload to App Store Connect

**Option A: Using Transporter App (Recommended)**

1. Export IPA:

   ```bash
   make export-ipa
   ```

2. Open Transporter app (from Mac App Store)
3. Sign in with Apple ID
4. Drag `build/ipa/weather.ipa` into Transporter
5. Click "Deliver"

**Option B: Using Xcode Organizer**

1. Open Xcode → Window → Organizer
2. Select Archives tab
3. Find "weather" archive (created today)
4. Click "Distribute App"
5. Choose "App Store Connect"
6. Follow prompts:
   - Distribution: Upload
   - Signing: Automatic
   - Upload to App Store Connect

**Option C: Using Command Line**

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ipa/weather.ipa \
  --username your@appleid.com \
  --password @keychain:AC_PASSWORD
```

### 2. Create App in App Store Connect

1. Go to <https://appstoreconnect.apple.com>
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform:** iOS
   - **Name:** Andernet Weather
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** dev.andernet.weather
   - **SKU:** andernet-weather-001
   - **User Access:** Full Access

### 3. Complete App Information

#### General Information

- **App Name:** Andernet Weather
- **Subtitle:** Liquid Glass Forecasts
- **Privacy Policy URL:** `https://andernet.dev/weather/privacy` (host PRIVACY_POLICY.md)
- **Category:** Primary - Weather, Secondary - Utilities
- **Content Rights:** No third-party content
- **Age Rating:** 4+ (complete questionnaire)

#### App Privacy

Configure Privacy Nutrition Label:

- **Data Used to Track You:** None
- **Data Linked to You:** None
- **Data Not Linked to You:**
  - Location (Precise Location)
    - Purpose: App Functionality
    - Not used for tracking

#### Pricing and Availability

- **Price:** Free
- **Availability:** All countries

### 4. Prepare Screenshots

**Required:** (See SCREENSHOTS.md for details)

- [ ] iPhone 6.9" (1320 × 2868) - 3-10 screenshots
- [ ] iPhone 6.3" (1206 × 2622) - 3-10 screenshots

**Recommended:**

- [ ] iPad Pro 13" (2064 × 2752) - 3-10 screenshots

**How to capture:**

```bash
# Open iPhone 17 Pro Max simulator
open -a Simulator --args -CurrentDeviceUDID 703ACBAC-D10E-42D0-A6BD-B39A20041011

# Run app in Release mode
make build-release

# Take screenshots (Cmd+S in Simulator)
```

Upload to App Store Connect → App Information → iPhone 6.9 Display

### 5. Upload App Icon

- [ ] Extract 1024×1024 icon from `weather/Assets.xcassets/AppIcon.appiconset/`
- [ ] Upload to App Store Connect
- [ ] Ensure no alpha channel, no rounded corners

### 6. Set Up TestFlight

#### Internal Testing (Instant)

1. Go to TestFlight tab in App Store Connect
2. Select uploaded build (processing takes ~10 min after upload)
3. Add internal testers:
   - Go to "Internal Testing" → "App Store Connect Users"
   - Add team members
4. Enable automatic distribution

#### External Testing (Optional)

1. Create external test group:
   - Name: "Public Beta"
   - Public Link: Enable
2. Add beta app description (copy from `AppStoreMetadata.json`)
3. Add what to test notes
4. Submit for Beta App Review (~24 hours)

### 7. Complete App Store Listing

Fill in all metadata from `AppStoreMetadata.json`:

- [ ] **Description** (4000 chars) - Copy from `app_store_listing.description`
- [ ] **Keywords** (100 chars) - `weather,forecast,temperature,rain,snow,humidity,air quality,widgets,live activities,ios26`
- [ ] **Promotional Text** (170 chars) - Can update without review
- [ ] **Support URL** - `https://andernet.dev/weather/support` (host SUPPORT.md)
- [ ] **Marketing URL** - `https://andernet.dev/weather` (optional)

### 8. Add App Review Information

- [ ] **First Name:** Matt
- [ ] **Last Name:** Anderson
- [ ] **Phone:** Your phone number
- [ ] **Email:** support@andernet.dev
- [ ] **Demo Account:** Not required (app works without login)
- [ ] **Notes:** Copy from `AppStoreMetadata.json` → `review_notes.notes`
- [ ] **Attachments:** None needed

### 9. Version Release

Choose release option:

- **Manual release:** You control when it goes live (recommended)
- **Automatic release:** Live immediately after approval
- **Scheduled release:** Choose future date/time

### 10. Submit for Review (When Ready)

Before submitting:

- [ ] All screenshots uploaded
- [ ] App icon uploaded
- [ ] All metadata complete
- [ ] Privacy policy URL live
- [ ] Support URL live
- [ ] TestFlight tested on real device
- [ ] No crashes or critical bugs

Click "Submit for Review"

## 📊 Build Information

```
App Name:        Andernet Weather
Bundle ID:       dev.andernet.weather
Version:         1.0
Build Number:    1
Team ID:         C8U3P6AJ6L
Min iOS:         17.0
Archive Path:    build/weather.xcarchive
Signing:         Automatic (Apple Development)
Export Method:   App Store Connect
```

## 📝 Important URLs to Set Up

Before submitting, host these files publicly:

1. **Privacy Policy URL:** `https://andernet.dev/weather/privacy`
   - Host content from `PRIVACY_POLICY.md`
   - Required for App Store submission

2. **Support URL:** `https://andernet.dev/weather/support`
   - Host content from `SUPPORT.md`
   - Required for App Store submission

3. **Marketing URL** (optional): `https://andernet.dev/weather`
   - Landing page for the app
   - Can be added later

## 🚀 Quick Commands Reference

```bash
# Build Release
make build-release

# Create Archive
make archive

# Export IPA
make export-ipa

# All quality checks
make quality-gate

# Clean build
make clean

# Analyze app size
make analyze-size
```

## 📱 TestFlight Testing Checklist

Once uploaded, test these on physical device:

- [ ] Location permission flow
- [ ] Current weather displays correctly
- [ ] Search for cities works
- [ ] Favorites save/load properly
- [ ] Hourly forecast charts work
- [ ] 7-day forecast displays
- [ ] Weather maps load
- [ ] Widgets update (Home Screen)
- [ ] Lock Screen widgets work
- [ ] Live Activities start/stop
- [ ] Settings persist correctly
- [ ] Theme changes apply
- [ ] Notifications work (if enabled)
- [ ] Siri Shortcuts work
- [ ] Dark/Light mode switching
- [ ] VoiceOver accessibility
- [ ] Dynamic Type scaling

## ⏱️ Expected Timeline

| Step | Time |
|------|------|
| Upload to App Store Connect | 5-15 minutes |
| Processing build | 10-20 minutes |
| Internal TestFlight available | Immediately after processing |
| Beta App Review (external) | 24-48 hours |
| App Store Review | 1-3 days |

## 🆘 Troubleshooting

### Upload Fails

- Check code signing: `make show-settings | grep CODE_SIGN`
- Verify team ID in ExportOptions.plist matches
- Try Organizer method instead of command line

### Processing Stuck

- Wait 30 minutes, usually resolves
- Check email for rejection notice
- Verify Info.plist has all required keys

### Missing Compliance

If asked about export compliance:

- Uses Encryption: Yes (HTTPS only)
- Exempt from regulations: Yes
- Exemption: Standard encryption only

## 📞 Support Contacts

- **Apple Developer Support:** <https://developer.apple.com/contact/>
- **App Store Connect Help:** <https://help.apple.com/app-store-connect/>
- **TestFlight Guide:** <https://developer.apple.com/testflight/>

## ✅ Final Pre-Upload Checklist

- [x] Archive built successfully
- [x] Privacy policy written
- [x] Support documentation ready
- [x] Metadata prepared
- [x] Export options configured
- [ ] Screenshots captured
- [ ] App icon extracted
- [ ] Privacy policy hosted online
- [ ] Support page hosted online
- [ ] Tested on physical device (recommended)

---

**You're ready to upload to TestFlight!** 🎉

Start with step 1 (Upload to App Store Connect) and work through the checklist.
