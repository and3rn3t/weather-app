# CI/CD Guide

Single reference for this repo's GitHub Actions workflows, secrets and release process.
Workflow files live in [`.github/workflows/`](workflows/); shared jobs come from `and3rn3t/.github`.

## Workflows

### Build, test, release

| Workflow | File | Trigger | Purpose |
| -------- | ---- | ------- | ------- |
| Build & Test | `ci.yml` | push / PR, `weather/**` | iOS build and unit tests |
| Enhanced CI | `enhanced-ci.yml` | push / PR | Release build size analysis (main only) |
| iOS Build (Reusable) | `ios-build-reusable.yml` | `workflow_call` | Shared iOS build steps |
| Android Build & Test | `android.yml` | push / PR | Gradle build, lint, tests |
| Quick CI | `quick-ci.yml` | PR | Change detection, lint, security checks (no builds) |
| Deploy to TestFlight | `deploy-testflight.yml` | manual | Archive, export, upload via `altool` |
| Deploy to Play Store | `deploy-playstore.yml` | manual | Build AAB, upload via `fastlane supply` |

### Security and hygiene

| Workflow | File | Purpose |
| -------- | ---- | ------- |
| Gitleaks | `gitleaks.yml` | Secret scan on push/PR |
| Dependency Review | `dependency-review.yml` | Flag vulnerable dependency changes in PRs |
| Actionlint | `actionlint.yml` | Validate workflow YAML |
| Consistency | `consistency.yml` | Warn when baseline files drift from `ai-template-repo` |
| Stale Management | `stale.yml` | Close inactive issues/PRs (daily) |
| Cache Maintenance | `cache-maintenance.yml` | Warm and prune caches (daily/weekly) |

### Labels and releases

| Workflow | File | Purpose |
| -------- | ---- | ------- |
| PR Labeler / PR Auto-Labeler | `labeler.yml`, `pr-labeler.yml` | Label PRs from changed paths (config: `labeler.yml`) |
| Label Sync | `label-sync.yml` | Sync repo labels to `labels.yml` on push to main |
| Release Drafter | `release-drafter.yml` | Draft release notes from merged PRs (config: `release-drafter.yml`) |
| Changelog | `changelog.yml` | On publish, generate notes only if the release body is empty |
| Lighthouse | `lighthouse.yml` | Disabled placeholder (manual only) |

## Manual runs

```bash
gh workflow run "Deploy to TestFlight" -f version=1.0.1 -f skip_tests=false
gh workflow run "Deploy to Play Store" -f track=internal -f rollout_percentage=100 -f skip_tests=false
```

Play Store `track` is one of `internal`, `alpha`, `beta`, `production`.

## Required secrets

| Used by | Secret |
| ------- | ------ |
| TestFlight | `ASC_API_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_KEY_CONTENT`, `APPLE_CERTIFICATE_P12`, `APPLE_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD` |
| Play Store | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`, `GOOGLE_PLAY_JSON_KEY` |
| Android builds | `GOOGLE_MAPS_API_KEY` |

Set with `gh secret set <NAME>`. Never commit keys; `APIConfig.swift` (Tomorrow.io key) is gitignored.

## Releasing

1. `make prepare-release` (or `-minor` / `-major`) runs pre-release checks.
2. Merge to `main`; Release Drafter keeps the draft release current.
3. Run the deploy workflow(s) above, then publish the draft release. The Changelog workflow runs on publish; it keeps the Release Drafter notes and only generates notes if the release body is empty.

PR titles use conventional commits (`feat:`, `fix:`, `docs:`, ...); Release Drafter derives the version bump and notes from them.

## Dependencies

Dependabot ([`dependabot.yml`](dependabot.yml)) runs weekly for GitHub Actions and Gradle (`/android-app`).

## Troubleshooting

- **iOS build fails in CI only:** run `make build` and `make test` locally; check the Xcode version selected by `setup-xcode` matches yours.
- **Android build fails:** `cd android-app && ./gradlew assembleDebug testDebugUnitTest lint`.
- **Deploy fails on signing:** re-check the certificate / keystore secrets above.
- **Artifacts:** `gh run download <run-id>`.
