# 🚀 TestFlight Distribution - Ready

Your Andernet Weather app is now ready for TestFlight distribution.

## ✅ What's Been Completed

### 1. Build & Archive ✓

- **Release Archive Created:** `build/weather.xcarchive` (31 MB)
- **Build Configuration:** Release mode with optimizations
- **Code Signing:** Automatic with Apple Development certificate
- **Version:** 1.0 (Build 1)

### 2. Documentation ✓

Created all required documentation:

| Document | Purpose | Location |
|----------|---------|----------|
| **PRIVACY_POLICY.md** | Privacy policy for App Store | Host at: andernet.dev/weather/privacy |
| **SUPPORT.md** | User support & FAQ for beta testers | Host at: andernet.dev/weather/support |
| **AppStoreMetadata.json** | All App Store text content (copy/paste ready) | Reference for filling App Store Connect |
| **SCREENSHOTS.md** | Instructions for capturing required screenshots | Guide for creating store assets |
| **TESTFLIGHT_CHECKLIST.md** | Step-by-step distribution guide | Your roadmap to App Store |

### 3. Configuration ✓

- **Bundle ID:** dev.andernet.weather
- **Team ID:** C8U3P6AJ6L
- **Export Options:** Configured for App Store Connect
- **Privacy Manifest:** Included (PrivacyInfo.xcprivacy)
- **Entitlements:** Location, Siri, Background modes configured

## 🎯 Next Steps (In Order)

### Step 1: Host Documentation Online

Before uploading to App Store, you need to host these publicly:

1. **Privacy Policy** → `https://andernet.dev/weather/privacy`
   - Content in `PRIVACY_POLICY.md`
   - Required by Apple

2. **Support Page** → `https://andernet.dev/weather/support`
   - Content in `SUPPORT.md`
   - Required by Apple

**Quick options:**

- GitHub Pages (free)
- Your existing andernet.dev site
- Netlify/Vercel (free)

### Step 2: Capture Screenshots

You need screenshots in these sizes:

- **iPhone 6.9"** (1320 × 2868) - iPhone 17 Pro Max - **REQUIRED**
- **iPhone 6.3"** (1206 × 2622) - iPhone 17 Pro - **REQUIRED**
- **iPad Pro 13"** (2064 × 2752) - Optional but recommended

**Quick start:**

```bash
# Open simulator
open -a Simulator --args -CurrentDeviceUDID 703ACBAC-D10E-42D0-A6BD-B39A20041011

# Run app
make build-release

# Take screenshots with Cmd+S
```

See **SCREENSHOTS.md** for detailed instructions.

### Step 3: Upload to App Store Connect

**Easiest method (Recommended):**

1. Export the IPA:

   ```bash
   make export-ipa
   ```

2. Download **Transporter** app from Mac App Store

3. Open Transporter, sign in with your Apple ID

4. Drag `build/ipa/weather.ipa` into Transporter

5. Click "Deliver"

**Alternative:** Use Xcode Organizer (Window → Organizer → Archives → Distribute App)

### Step 4: Set Up App in App Store Connect

1. Go to <https://appstoreconnect.apple.com>

2. Create new app:
   - Name: Andernet Weather
   - Bundle ID: dev.andernet.weather
   - Primary Language: English (U.S.)

3. Fill in metadata from **AppStoreMetadata.json**:
   - Description, keywords, promotional text
   - Screenshots (upload after capturing)
   - App icon (1024×1024 from Assets.xcassets)
   - Privacy policy URL
   - Support URL

4. Configure TestFlight:
   - Add internal testers
   - Add beta app description
   - Enable automatic distribution

5. Submit for Beta App Review (for external testing)

## 📋 Complete Checklist

Use **TESTFLIGHT_CHECKLIST.md** for the full step-by-step guide.

## 🔧 Quick Commands

```bash
# Rebuild archive if needed
make archive

# Export IPA for upload
make export-ipa

# Clean and rebuild
make clean && make archive

# Check build settings
make show-settings | grep -E "BUNDLE_ID|TEAM|VERSION"
```

## 📁 Important Files

```
weather/
├── build/
│   └── weather.xcarchive           # ← Ready to upload
├── PRIVACY_POLICY.md               # ← Host online before submitting
├── SUPPORT.md                      # ← Host online before submitting
├── AppStoreMetadata.json           # ← Copy text to App Store Connect
├── SCREENSHOTS.md                  # ← Guide for screenshots
├── TESTFLIGHT_CHECKLIST.md         # ← Your step-by-step guide
└── ExportOptions.plist             # ← Export configuration
```

## ⏱️ Timeline Estimate

| Task | Time |
|------|------|
| Host documentation online | 15-30 minutes |
| Capture screenshots | 30-60 minutes |
| Upload build | 5-15 minutes |
| Build processing | 10-20 minutes |
| Set up App Store Connect | 30-60 minutes |
| **Internal TestFlight ready** | **~2-3 hours total** |
| Beta App Review (external) | 24-48 hours |
| Full App Store review | 1-3 days |

## 🎓 Resources

- **TESTFLIGHT_CHECKLIST.md** - Complete distribution guide
- **SCREENSHOTS.md** - How to capture perfect screenshots
- **AppStoreMetadata.json** - All your App Store text
- **Apple TestFlight Guide:** <https://developer.apple.com/testflight/>
- **App Store Connect Help:** <https://help.apple.com/app-store-connect/>

## 🎉 You're Ready

Everything is prepared. Follow the steps above and you'll have your app in TestFlight within a few hours.

**Start here:** TESTFLIGHT_CHECKLIST.md → Section "Next Steps to Complete"

---

**Questions?** Check SUPPORT.md or reference the documentation files created.
