# Info.plist Configuration Guide

This file contains all the necessary Info.plist configurations for the Weather app to function properly.

---

## Required Privacy Descriptions

### Location Services

Add these keys to request location permissions:

```xml
<!-- Location When In Use -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show accurate weather information for your area.</string>

<!-- Location Always (Optional - for background updates) -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to show accurate weather information and send timely weather alerts even when the app is in the background.</string>

<!-- Location Always Usage -->
<key>NSLocationAlwaysUsageDescription</key>
<string>We need continuous access to your location to provide weather updates and alerts.</string>
```

### Notifications

No explicit permission required in Info.plist, but you should document notification usage:

```xml
<!-- Optional: Document notification usage -->
<key>NSUserNotificationUsageDescription</key>
<string>We send notifications for severe weather alerts, daily forecasts, and rain warnings to keep you informed.</string>
```

---

## Background Modes

To support background refresh and remote notifications:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

Note: `fetch` enables background app refresh for weather updates.

---

## App Transport Security

Open-Meteo API uses HTTPS, so no special ATS configuration needed. However, if you want to be explicit:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Allow all HTTPS connections (recommended) -->
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

---

## Widget Configuration

Ensure your widget extension has proper configuration:

```xml
<!-- In Widget Extension's Info.plist -->
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

---

## Launch Screen

Configure launch screen behavior:

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIImageName</key>
    <string>LaunchImage</string>
    <key>UIColorName</key>
    <string>LaunchBackgroundColor</string>
</dict>
```

---

## Supported Interface Orientations

### iPhone

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

### iPad

```xml
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

---

## App Display Name

```xml
<key>CFBundleDisplayName</key>
<string>Weather</string>

<key>CFBundleName</key>
<string>$(PRODUCT_NAME)</string>
```

---

## Version Information

```xml
<key>CFBundleShortVersionString</key>
<string>1.0</string>

<key>CFBundleVersion</key>
<string>1</string>
```

---

## Deployment Target

Ensure minimum iOS version is set:

```xml
<key>MinimumOSVersion</key>
<string>17.0</string>
```

---

## Required Device Capabilities

```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
</array>
```

---

## Status Bar Configuration

```xml
<!-- Use default status bar style -->
<key>UIStatusBarStyle</key>
<string>UIStatusBarStyleDefault</string>

<!-- Allow status bar to change based on content -->
<key>UIViewControllerBasedStatusBarAppearance</key>
<true/>
```

---

## Complete Info.plist Example

Here's a complete Info.plist with all necessary keys:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Information -->
    <key>CFBundleDisplayName</key>
    <string>Weather</string>
    
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    
    <key>CFBundleVersion</key>
    <string>1</string>
    
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    
    <!-- Minimum iOS Version -->
    <key>MinimumOSVersion</key>
    <string>17.0</string>
    
    <!-- Privacy - Location -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to show accurate weather information for your area.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>We need your location to show accurate weather information and send timely weather alerts.</string>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>
    
    <!-- Supported Interface Orientations - iPhone -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- Supported Interface Orientations - iPad -->
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
    
    <!-- Launch Screen -->
    <key>UILaunchScreen</key>
    <dict/>
    
    <!-- Status Bar -->
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <true/>
    
    <!-- Required Device Capabilities -->
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    
    <!-- Scene Configuration -->
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>
</dict>
</plist>
```

---

## Widget Extension Info.plist

For your widget extension, create a separate Info.plist:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Weather Widget</string>
    
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    
    <key>CFBundleVersion</key>
    <string>1</string>
    
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
    
    <key>MinimumOSVersion</key>
    <string>17.0</string>
</dict>
</plist>
```

---

## How to Edit Info.plist in Xcode

### Method 1: Plist Editor
1. Select your project in Navigator
2. Select your target
3. Go to "Info" tab
4. Add keys using + button
5. Edit values directly

### Method 2: Source Code
1. Right-click Info.plist
2. Select "Open As" → "Source Code"
3. Add XML directly
4. Save file

### Method 3: Project Settings
Many keys can be set in:
- Project Settings → Info
- Target Settings → Info
- Capabilities tab (for background modes)

---

## Testing Privacy Permissions

### Location Permission
```swift
// Test code to verify permission request
import CoreLocation

let manager = CLLocationManager()
manager.requestWhenInUseAuthorization()
```

### Notification Permission
```swift
// Test code to verify notification request
import UserNotifications

UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    print("Notification permission: \(granted)")
}
```

---

## Common Issues

### Issue: "This app has crashed because it attempted to access privacy-sensitive data without a usage description"

**Solution**: Add the appropriate `NS*UsageDescription` key to Info.plist

### Issue: Widget not appearing

**Solution**: 
1. Verify widget Info.plist has `NSExtensionPointIdentifier`
2. Check bundle identifier format: `com.yourapp.widgetextension`
3. Ensure extension target is added to project

### Issue: Background refresh not working

**Solution**: 
1. Add `fetch` to `UIBackgroundModes`
2. Enable "Background fetch" in Capabilities
3. Test on physical device (not reliable in simulator)

---

## Validation

Use these commands to validate your Info.plist:

```bash
# Validate syntax
plutil -lint Info.plist

# Convert to XML format
plutil -convert xml1 Info.plist

# Show contents
plutil -p Info.plist
```

---

## Security Best Practices

1. ✅ Always use HTTPS for API calls
2. ✅ Minimize requested permissions
3. ✅ Provide clear usage descriptions
4. ✅ Don't store sensitive data in Info.plist
5. ✅ Use proper bundle identifiers
6. ✅ Keep minimum OS version as high as reasonable

---

## Localization

To localize permission strings:

1. Create `InfoPlist.strings` file
2. Add localized versions:

```
/* Location permission */
"NSLocationWhenInUseUsageDescription" = "Nous avons besoin de votre position pour afficher la météo.";
```

3. Add to appropriate `.lproj` folders

---

## App Store Requirements

Ensure these are set for App Store submission:

- ✅ `CFBundleDisplayName` - User-facing name
- ✅ `CFBundleShortVersionString` - Version shown in store
- ✅ `CFBundleVersion` - Build number
- ✅ All privacy descriptions - Clear explanations
- ✅ `MinimumOSVersion` - Realistic minimum
- ✅ `UIRequiredDeviceCapabilities` - Only truly required capabilities

---

## Additional Resources

- [Apple Info.plist Documentation](https://developer.apple.com/documentation/bundleresources/information_property_list)
- [Privacy Keys Reference](https://developer.apple.com/documentation/bundleresources/information_property_list/protected_resources)
- [Background Execution](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background)

---

*Last updated: February 5, 2026*
