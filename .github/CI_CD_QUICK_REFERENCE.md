# CI/CD Quick Reference

Quick commands and tips for working with the CI/CD pipelines.

## 🚀 Manual Workflow Triggers

### Deploy to TestFlight

```
Actions → Deploy to TestFlight → Run workflow
- Branch: main
- Version: 1.0.1 (optional)
- Skip tests: false (recommended)
```

### Deploy to Play Store

```
Actions → Deploy to Play Store → Run workflow
- Branch: main
- Track: internal/alpha/beta/production
- Rollout percentage: 100 (for production)
- Skip tests: false (recommended)
```

### Run Performance Tests

```
Actions → Build Performance → Run workflow
```

### Generate Changelog

```
Actions → Changelog → Run workflow
- From tag: v1.0.0 (optional)
- To tag: v1.1.0 (optional)
```

## 🏷️ PR Labels

Labels are automatically added based on changed files:

### Platform

- `ios` - iOS Swift files changed
- `android` - Android Kotlin files changed

### Components

- `ui` - UI/View files changed
- `networking` - Service/API files changed
- `database` - Model/Entity files changed
- `widget` - Widget files changed
- `tests` - Test files changed

### Type

- `feature` - Source code changes
- `documentation` - Markdown/docs changed
- `ci-cd` - GitHub Actions changed
- `dependencies` - Package files changed
- `configuration` - Config files changed

### Size

- `size/XS` - < 10 lines changed
- `size/S` - 10-100 lines  
- `size/M` - 100-500 lines
- `size/L` - 500-1000 lines
- `size/XL` - > 1000 lines (consider splitting!)

## ⏱️ Workflow Run Times

| Workflow | Avg Time | Runner | Cost |
|----------|----------|--------|------|
| iOS Build & Test | ~15 min | macOS-15 | $1.20 |
| Android Build & Test | ~10 min | ubuntu | $0.08 |
| Code Coverage | ~20 min | mixed | $1.30 |
| Nightly Build | ~45 min | mixed | $4.00 |

## 🔍 Debugging Failed Workflows

### iOS Build Failure

```bash
# Run locally
cd weather
make clean
make build

# Check for Swift errors
xcodebuild build \
  -project weather.xcodeproj \
  -scheme weather \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Android Build Failure

```bash
# Run locally
cd android-app
./gradlew clean
./gradlew assembleDebug

# Check for Kotlin errors
./gradlew compileDebugKotlin --stacktrace
```

### Test Failure

1. Download test results artifact from workflow run
2. Open `.xcresult` (iOS) in Xcode
3. Or check HTML report (Android)

## 📊 Build Artifacts

### What's Uploaded

| Artifact | Retention | Size | When |
|----------|-----------|------|------|
| Test results | 7 days | ~10 MB | Every run |
| Build metrics | 90 days | < 1 KB | Performance workflow |
| Nightly APK | 14 days | ~50 MB | Nightly builds |
| Debug APK | 7 days | ~50 MB | Android CI (main only) |
| Coverage reports | 7 days | ~5 MB | Coverage workflow |

### Downloading Artifacts

```bash
# Using GitHub CLI
gh run download <run-id>

# Or via web UI
Actions → Select workflow run → Scroll to Artifacts
```

## 🔐 Required Secrets

### For TestFlight Deployment

- `ASC_API_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_API_KEY_CONTENT`
- `APPLE_CERTIFICATE_P12`
- `APPLE_CERTIFICATE_PASSWORD`
- `KEYCHAIN_PASSWORD`

### For Play Store Deployment

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`
- `GOOGLE_PLAY_JSON_KEY`
- `GOOGLE_MAPS_API_KEY`

### Optional

- `CODECOV_TOKEN` - For code coverage

## 🛠️ Maintenance Tasks

### Weekly

- ✅ Review and merge Dependabot PRs
- ✅ Check nightly build results
- ✅ Close stale issues

### Monthly

- ✅ Review code coverage trends
- ✅ Analyze build performance metrics
- ✅ Update workflow action versions
- ✅ Clean up old artifacts manually if needed

### Quarterly

- ✅ Rotate signing certificates if expiring
- ✅ Update Xcode version in workflows
- ✅ Review and optimize workflow costs
- ✅ Update this documentation

## 🚨 Common Issues

### Issue: "No space left on device"

**Solution:** Increase runner disk space or clean up artifacts

### Issue: "Code signing failed"

**Solution:** Check certificate expiration and provisioning profiles

### Issue: "Tests taking too long"

**Solution:** Enable parallel testing or reduce test matrix

### Issue: "Workflow not triggering"

**Solution:** Check `paths` filter matches changed files

### Issue: "Secrets not available"

**Solution:** Verify secrets are set in repository settings

## 💡 Tips & Tricks

### Skip CI for Documentation Changes

```bash
git commit -m "Update README [skip ci]"
```

### Re-run Failed Jobs Only

- Go to workflow run
- Click "Re-run failed jobs"
- Saves time and money!

### View Workflow Logs in CLI

```bash
gh run view <run-id> --log
```

### Enable Debug Logging

Add secrets:

- `ACTIONS_RUNNER_DEBUG` = `true`
- `ACTIONS_STEP_DEBUG` = `true`

### Cancel Running Workflow

```bash
gh run cancel <run-id>
```

### List All Workflow Runs

```bash
gh run list --workflow=ci.yml
```

## 📱 Mobile App Testing

### Test on Physical Device (iOS)

1. Download IPA from artifact
2. Install via Xcode: `Window → Devices and Simulators`
3. Or use Apple Configurator

### Test on Physical Device (Android)

1. Download APK from artifact
2. Install via ADB: `adb install app.apk`
3. Or transfer to device and install

### Test on Simulators/Emulators

- iOS: Use .app from artifact with Simulator
- Android: Use APK with Android Emulator

## 🔗 Useful Links

- [CI/CD Setup Guide](.github/CI_CD_GUIDE.md)
- [Pipeline Optimizations](.github/PIPELINE_OPTIMIZATIONS.md)
- [Contributing Guidelines](../CONTRIBUTING.md)
- [Security Policy](../SECURITY.md)

## 📞 Getting Help

**Workflow Issues:**

- Check [GitHub Actions status](https://www.githubstatus.com/)
- Search [GitHub Community](https://github.community/)
- Create issue with `ci-cd` label

**Build Issues:**

- Check workflow logs
- Run builds locally
- Compare with previous successful builds

---

**Pro Tip:** Star this file for quick access! ⭐
