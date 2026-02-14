# CI/CD Setup Guide

This guide explains the GitHub Actions workflows and how to configure secrets for automated builds and deployments.

## 📋 Overview

The project has comprehensive CI/CD pipelines for both iOS and Android:

### iOS Workflows

- **Build & Test** ([`ci.yml`](.github/workflows/ci.yml)) - Runs on every PR/push
- **Code Coverage** ([`coverage.yml`](.github/workflows/coverage.yml)) - Generates coverage reports
- **TestFlight Deployment** ([`deploy-testflight.yml`](.github/workflows/deploy-testflight.yml)) - Manual deployment to TestFlight

### Android Workflows

- **Android Build & Test** ([`android.yml`](.github/workflows/android.yml)) - Runs on every PR/push
- **Play Store Deployment** ([`deploy-playstore.yml`](.github/workflows/deploy-playstore.yml)) - Manual deployment to Google Play

### Automation

- **Dependabot** ([`dependabot.yml`](.github/dependabot.yml)) - Automated dependency updates

## 🔑 Required Secrets

To enable full CI/CD functionality, configure these secrets in GitHub:

**Settings → Secrets and variables → Actions → New repository secret**

### iOS Secrets

#### App Store Connect API (Recommended)

```
ASC_API_KEY_ID=XXXXXXXXXX
ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ASC_API_KEY_CONTENT=<contents of AuthKey_XXXXXXXXXX.p8>
```

Generate at: [App Store Connect → Users and Access → Keys](https://appstoreconnect.apple.com/access/api)

#### Code Signing

```
APPLE_CERTIFICATE_P12=<base64 encoded .p12 certificate>
APPLE_CERTIFICATE_PASSWORD=<certificate password>
KEYCHAIN_PASSWORD=<temporary keychain password for CI>
```

**To encode certificate:**

```bash
base64 -i certificate.p12 | pbcopy
```

### Android Secrets

#### Signing Key

```
ANDROID_KEYSTORE_BASE64=<base64 encoded keystore file>
ANDROID_KEY_ALIAS=<key alias>
ANDROID_KEY_PASSWORD=<key password>
ANDROID_STORE_PASSWORD=<keystore password>
```

**To encode keystore:**

```bash
base64 -i release.keystore | pbcopy
```

#### Google Play Publishing

```
GOOGLE_PLAY_JSON_KEY=<contents of Google Play service account JSON>
```

Create at: [Google Play Console → Settings → API access](https://play.google.com/console/developers/api-access)

#### Google Maps API

```
GOOGLE_MAPS_API_KEY=<your Google Maps API key>
```

### Optional Secrets

#### Code Coverage (Codecov)

```
CODECOV_TOKEN=<your codecov token>
```

Get from: [codecov.io](https://codecov.io/)

## 🚀 Workflows in Detail

### 1. iOS Build & Test (`ci.yml`)

**Triggers:** Every push/PR to `main` (iOS files only)

**What it does:**

- ✅ Builds on 3 simulators (iPhone 16 Pro, iPhone SE, iPad Pro)
- ✅ Runs unit tests in parallel
- ✅ SwiftLint code quality checks
- ✅ Security scanning for hardcoded secrets
- ✅ Build size analysis
- ✅ Test result artifacts

**Matrix testing:** Ensures compatibility across different device sizes and types.

**Performance optimizations:**

- Caches DerivedData and Homebrew
- Only runs on iOS file changes
- Parallel test execution

### 2. Android Build & Test (`android.yml`)

**Triggers:** Every push/PR to `main` (Android files only)

**What it does:**

- ✅ Lint checks
- ✅ Unit tests
- ✅ Builds debug APK
- ✅ Builds release AAB (main branch only)
- ✅ Instrumented tests on emulator (PRs only)
- ✅ Test result artifacts

**Jobs:**

1. `lint` - Code quality
2. `test` - Unit tests
3. `build-debug` - Debug APK
4. `build-release` - Signed release AAB
5. `instrumented-tests` - UI tests on emulator

**Performance optimizations:**

- Gradle build cache
- AVD cache for faster emulator startup
- KVM acceleration for faster tests

### 3. TestFlight Deployment (`deploy-testflight.yml`)

**Trigger:** Manual (workflow_dispatch)

**Inputs:**

- `version` - Version number (optional, auto-increments if empty)
- `skip_tests` - Skip tests before deployment (default: false)

**What it does:**

1. Runs tests (unless skipped)
2. Sets up code signing certificates
3. Increments build number
4. Archives and exports IPA
5. Uploads to TestFlight
6. Creates git tag
7. Uploads build artifacts

**Requirements:**

- All iOS secrets configured
- Valid App Store Connect API key
- Valid distribution certificate

### 4. Play Store Deployment (`deploy-playstore.yml`)

**Trigger:** Manual (workflow_dispatch)

**Inputs:**

- `track` - Release track (internal/alpha/beta/production)
- `rollout_percentage` - For production (1-100%)
- `skip_tests` - Skip tests before deployment

**What it does:**

1. Runs tests (unless skipped)
2. Builds signed release AAB
3. Uploads to specified track
4. Creates git tag (for production)
5. Uploads build artifacts

**Tracks:**

- `internal` - Instant, unlimited testers
- `alpha` - Closed testing
- `beta` - Beta testing
- `production` - Public release

### 5. Code Coverage (`coverage.yml`)

**Triggers:** Every push/PR to `main`

**What it does:**

- ✅ Generates coverage reports for iOS and Android
- ✅ Uploads to Codecov
- ✅ Comments coverage on PRs (Android)
- ✅ Reports as build artifacts

**Coverage requirements:**

- Overall: 40% minimum
- Changed files: 60% minimum

## 🔄 Dependabot Configuration

**Update schedule:** Weekly on Mondays at 9 AM

**Monitored dependencies:**

- GitHub Actions
- Swift Package Manager (iOS)
- Gradle (Android)
- Bundler (Fastlane)

**Grouping:**

- Minor/patch updates grouped together
- Separate PRs for major version updates

## 🎯 Best Practices

### For Contributors

1. **Always run tests locally** before pushing

   ```bash
   # iOS
   cd weather && make build
   
   # Android
   cd android-app && ./gradlew test
   ```

2. **Keep PRs focused** - Smaller PRs are easier to review and test

3. **Update tests** - Add tests for new features and bug fixes

4. **Check CI status** - Don't merge until all checks pass

### For Maintainers

1. **TestFlight releases:**

   ```
   Actions → Deploy to TestFlight → Run workflow → Select branch
   ```

2. **Play Store releases:**

   ```
   Actions → Deploy to Play Store → Run workflow → Select track
   ```

3. **Secret rotation:**
   - Rotate signing keys annually
   - Update API keys when compromised
   - Use short-lived tokens when possible

4. **Monitor Dependabot:**
   - Review and merge security updates ASAP
   - Test dependency updates before merging

## 🐛 Troubleshooting

### iOS Build Failures

**Error:** Code signing failed

- **Fix:** Check certificates are valid and not expired
- **Check:** Settings → Secrets → `APPLE_CERTIFICATE_P12`

**Error:** Tests failed

- **Fix:** Run tests locally on same simulator
- **Check:** Test logs in artifacts

### Android Build Failures

**Error:** Signing failed

- **Fix:** Verify keystore and passwords are correct
- **Check:** Settings → Secrets → `ANDROID_*` secrets

**Error:** Emulator startup failed

- **Fix:** Usually a transient issue, re-run workflow
- **Alternative:** Skip instrumented tests on retry

### Deployment Failures

**TestFlight upload failed:**

- Check App Store Connect API key is valid
- Ensure app bundle ID matches
- Verify provisioning profiles

**Play Store upload failed:**

- Check service account has proper permissions
- Verify version code is incremented
- Ensure AAB is signed correctly

## 📊 Monitoring

### Build Status

Check workflow status in:

- **README badges** (if configured)
- **Actions tab** in GitHub
- **Commit status checks** on PRs

### Coverage Reports

View coverage at:

- **Codecov dashboard** (if configured)
- **PR comments** (Android)
- **Workflow artifacts**

### Dependencies

Monitor updates in:

- **Dependabot alerts** tab
- **Pull requests** from Dependabot
- **Security** tab for vulnerabilities

## 🔗 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode)
- [Android Gradle Plugin](https://developer.android.com/build)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Google Play Developer API](https://developers.google.com/android-publisher)

## 📝 Workflow Diagram

```
┌─────────────────────────────────────────────────────┐
│  Code Push / Pull Request                           │
└────────────────┬────────────────────────────────────┘
                 │
                 ├─────────────────┬──────────────────┐
                 ▼                 ▼                  ▼
         ┌───────────────┐ ┌──────────────┐ ┌────────────────┐
         │  iOS CI       │ │ Android CI   │ │ Code Coverage  │
         │  - Build      │ │ - Lint       │ │ - iOS          │
         │  - Test       │ │ - Test       │ │ - Android      │
         │  - Lint       │ │ - Build APK  │ │ - Upload       │
         │  - Security   │ │ - Build AAB  │ │ - Report       │
         └───────┬───────┘ └──────┬───────┘ └────────┬───────┘
                 │                │                   │
                 └────────┬───────┴───────────────────┘
                          ▼
                 ┌─────────────────┐
                 │  All Checks     │
                 │  Pass ✅        │
                 └────────┬────────┘
                          │
                 ┌────────┴───────┐
                 │   Merge PR     │
                 └────────┬───────┘
                          │
              ┌───────────┴──────────┐
              │  Manual Deployment   │
              ├──────────────────────┤
              │  - TestFlight (iOS)  │
              │  - Play Store (And.) │
              └──────────────────────┘
```
