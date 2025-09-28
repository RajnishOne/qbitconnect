# Analytics Implementation

This document explains the Firebase Analytics implementation in QBitConnect.

## Overview

QBitConnect includes basic Firebase Analytics to understand user behavior and app usage patterns. The implementation is designed to be:
- **Privacy-focused**: No personal data or sensitive information is collected
- **Minimal**: Only essential usage data is tracked
- **Configurable**: Easy to disable for open-source users
- **Transparent**: Clear documentation of what is tracked

## What is Tracked

### Screen Views
- `connection_screen`: When users view the connection screen
- `torrents_screen`: When users view the main torrents list
- `settings_screen`: When users access settings

### Events
- `app_open`: When the app is opened
- `connection_success`: Successful connection to qBittorrent server
- `connection_error`: Failed connection attempts (error type only)
- `theme_changed`: When users switch between light/dark themes
- `polling_setting_changed`: When users change polling settings

### User Properties
- `app_version`: Current app version
- `user_type`: Basic user categorization (if implemented)

## What is NOT Tracked

- **Personal Information**: No usernames, passwords, or personal data
- **Torrent Data**: No torrent names, file names, or content information
- **Server Details**: No server IPs, URLs, or connection details
- **Usage Patterns**: No detailed user behavior or navigation patterns

## Configuration

### Disable Analytics

To completely disable analytics, edit `lib/src/services/analytics_config.dart`:

```dart
class AnalyticsConfig {
  static const bool analyticsEnabled = false; // Set to false
  // ... other settings
}
```

### Selective Disabling

You can disable specific features:

```dart
class AnalyticsConfig {
  static const bool analyticsEnabled = true;
  static const bool enableScreenTracking = false;    // Disable screen tracking
  static const bool enableEventTracking = false;     // Disable event tracking
  static const bool enableAppOpenTracking = false;   // Disable app open tracking
  static const bool enableUserProperties = false;    // Disable user properties
}
```

### Privacy Settings

```dart
class AnalyticsConfig {
  static const bool anonymizeUserData = true;           // Anonymize user data
  static const bool disableSensitiveDataCollection = true; // Disable sensitive data
}
```

## Implementation Details

### Files Modified
- `lib/src/services/firebase_service.dart`: Main analytics service
- `lib/src/services/analytics_config.dart`: Configuration file
- `lib/main.dart`: App open tracking
- `lib/src/screens/connection_screen.dart`: Connection events
- `lib/src/screens/torrents_screen.dart`: Screen tracking
- `lib/src/screens/settings_screen.dart`: Settings events

### Dependencies Added
- `firebase_analytics: ^12.0.0`: Firebase Analytics package

## For Open Source Contributors

If you're contributing to this project and want to disable analytics:

1. **Quick Disable**: Set `analyticsEnabled = false` in `analytics_config.dart`
2. **Remove Dependencies**: Remove `firebase_analytics` from `pubspec.yaml`
3. **Remove Code**: Delete analytics-related code from the service files

## Privacy Compliance

This analytics implementation is designed to comply with privacy regulations:
- No personal data collection
- No tracking of sensitive information
- Easy opt-out mechanism
- Transparent data collection practices

## Support

If you have questions about the analytics implementation or need help disabling it, please open an issue on the project repository.
