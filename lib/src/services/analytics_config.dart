/// Configuration for Firebase Analytics
///
/// This file allows easy control over analytics features.
/// For open-source users who want to disable analytics:
/// 1. Set `analyticsEnabled` to false
/// 2. Or remove the analytics calls from the codebase
class AnalyticsConfig {
  /// Master switch for analytics
  /// Set to false to disable all analytics tracking
  static const bool analyticsEnabled = true;

  /// Enable/disable specific analytics features
  static const bool enableScreenTracking = true;
  static const bool enableEventTracking = true;
  static const bool enableAppOpenTracking = true;
  static const bool enableUserProperties = true;

  /// Privacy-focused settings
  /// Set to true to anonymize user data
  static const bool anonymizeUserData = true;

  /// Set to true to disable collection of sensitive information
  static const bool disableSensitiveDataCollection = true;
}
