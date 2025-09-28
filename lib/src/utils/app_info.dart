import 'package:package_info_plus/package_info_plus.dart';

/// Utility class to get app information dynamically
class AppInfo {
  static PackageInfo? _packageInfo;
  static bool _isInitialized = false;

  /// Initialize the package info (should be called once at app startup)
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _packageInfo = await PackageInfo.fromPlatform();
      _isInitialized = true;
    }
  }

  /// Get the app version (e.g., "1.0.0")
  static String get version {
    if (!_isInitialized || _packageInfo == null) {
      return 'Unknown';
    }
    return _packageInfo!.version;
  }

  /// Get the app build number (e.g., "1")
  static String get buildNumber {
    if (!_isInitialized || _packageInfo == null) {
      return 'Unknown';
    }
    return _packageInfo!.buildNumber;
  }

  /// Get the full version string (e.g., "1.0.0+1")
  static String get fullVersion {
    if (!_isInitialized || _packageInfo == null) {
      return 'Unknown';
    }
    return '${_packageInfo!.version}+${_packageInfo!.buildNumber}';
  }

  /// Get the app name
  static String get appName {
    if (!_isInitialized || _packageInfo == null) {
      return 'qBitConnect';
    }
    return _packageInfo!.appName;
  }

  /// Get the package name
  static String get packageName {
    if (!_isInitialized || _packageInfo == null) {
      return 'com.bluematter.qbitconnect';
    }
    return _packageInfo!.packageName;
  }
}
