# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to **security@andernet.dev**

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information in your report:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Security Best Practices

### API Keys and Secrets

- **Never** commit API keys, passwords, or other secrets to the repository
- Use environment variables or secure secret management systems
- API keys should be stored in:
  - iOS: `local.properties` (gitignored)
  - Android: `local.properties` (gitignored)
  - CI/CD: GitHub Secrets

### Third-Party Dependencies

- We use Dependabot to automatically monitor and update dependencies
- Security patches are prioritized and applied quickly
- Review dependency updates before merging

### Code Signing

- iOS: Uses Apple Developer certificates and provisioning profiles
- Android: Uses keystore files stored securely
- **Never** commit signing certificates or keystores to version control

### Data Handling

- Location data is processed locally on device
- No user data is stored on remote servers
- All network communication uses HTTPS
- See our [Privacy Policy](PRIVACY_POLICY.md) for details

### Security Scanning

Our CI/CD pipeline includes:
- Automated dependency vulnerability scanning (Dependabot)
- Static code analysis (SwiftLint for iOS)
- Secret scanning (GitHub Secret Scanning)
- Code coverage reporting

## Disclosure Policy

- We will confirm receipt of your vulnerability report within 2 business days
- We will provide an initial assessment within 5 business days
- We will work on fixing the vulnerability and keep you informed
- Once the vulnerability is fixed, we will release a security advisory
- We will credit security researchers in our release notes (unless you prefer to remain anonymous)

## Security Updates

Security updates will be released as soon as possible once a vulnerability is confirmed and fixed. Users will be notified through:

- GitHub Security Advisories
- Release notes in the App Store / Play Store
- Email notification to beta testers (if applicable)

## Known Security Considerations

### Location Permissions

- The app requests location permissions for weather forecasts
- Location access is optional - users can manually search for locations
- Background location access is only used for widget updates
- All location usage is disclosed in permission prompts and privacy policy

### Network Communication

- Weather data fetched from public APIs:
  - Open-Meteo (open-source weather API)
  - RainViewer (radar data)
  - National Weather Service (US severe weather alerts)
- All API communication uses HTTPS
- No analytics or tracking SDKs are included

### Local Data Storage

- User preferences stored in UserDefaults (iOS) / DataStore (Android)
- Saved locations stored in SwiftData (iOS) / Room (Android)
- No encryption required as data is non-sensitive
- Data remains on device and is not synced

## Contact

For security-related questions: **security@andernet.dev**

For general support: **support@andernet.dev**
