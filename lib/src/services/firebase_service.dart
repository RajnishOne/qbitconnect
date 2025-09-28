import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'analytics_config.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  FirebaseCrashlytics? _crashlytics;
  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  FirebaseCrashlytics get crashlytics {
    if (!_isInitialized) {
      throw StateError(
        'FirebaseService not initialized. Call initialize() first.',
      );
    }
    return _crashlytics!;
  }

  FirebaseAnalytics get analytics {
    if (!_isInitialized) {
      throw StateError(
        'FirebaseService not initialized. Call initialize() first.',
      );
    }
    return _analytics!;
  }

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();

      // Initialize Crashlytics
      _crashlytics = FirebaseCrashlytics.instance;

      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;

      // Set up Crashlytics to catch Flutter errors
      FlutterError.onError = _crashlytics!.recordFlutterFatalError;

      _isInitialized = true;
    } catch (e, stackTrace) {
      _crashlytics?.recordError(e, stackTrace);
    }
  }

  /// Set user ID for Crashlytics
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics?.setUserIdentifier(userId);
    } catch (e, stackTrace) {
      _crashlytics?.recordError(e, stackTrace);
    }
  }

  /// Record a non-fatal error
  Future<void> recordError(dynamic error, StackTrace? stackTrace) async {
    try {
      await _crashlytics?.recordError(error, stackTrace);
    } catch (e) {
      debugPrint('Error recording to Crashlytics: $e');
    }
  }

  /// Log a screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!AnalyticsConfig.analyticsEnabled ||
        !AnalyticsConfig.enableScreenTracking ||
        !_isInitialized) {
      return;
    }

    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!AnalyticsConfig.analyticsEnabled ||
        !AnalyticsConfig.enableEventTracking ||
        !_isInitialized) {
      return;
    }

    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Log app open event
  Future<void> logAppOpen() async {
    if (!AnalyticsConfig.analyticsEnabled ||
        !AnalyticsConfig.enableAppOpenTracking ||
        !_isInitialized) {
      return;
    }

    try {
      await _analytics?.logAppOpen();
    } catch (e) {
      debugPrint('Error logging app open: $e');
    }
  }
}
