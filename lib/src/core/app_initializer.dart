import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/theme_cache.dart';
import '../utils/app_info.dart';
import '../services/firebase_service.dart';

/// Handles all app initialization logic
class AppInitializer {
  /// Initialize the app with all required services
  static Future<void> initialize() async {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize theme cache before running the app (critical for UI)
    await ThemeCache.initialize();

    // Initialize non-critical services in background to reduce splash time
    _initializeBackgroundServices();
  }

  /// Initialize non-critical services in background
  static void _initializeBackgroundServices() {
    // Initialize app info in background
    AppInfo.initialize().catchError((e) {
      // App info initialization failed: $e
    });

    // Initialize Firebase and log app open event in background
    _initializeFirebaseAndLogAppOpen().catchError((e) {
      // Firebase initialization failed: $e
    });

    // Trigger iOS local network permission dialog early in background
    _triggerIOSLocalNetworkPermission().catchError((e) {
      // iOS local network permission trigger failed: $e
    });
  }

  /// Initialize Firebase and log app open event
  static Future<void> _initializeFirebaseAndLogAppOpen() async {
    try {
      // Wait for Firebase to be initialized
      await FirebaseService.instance.initialize();

      // Now log app open event after initialization
      await FirebaseService.instance.logAppOpen();
    } catch (e) {
      // Firebase initialization or app open logging failed: $e
    }
  }

  /// Trigger iOS local network permission dialog early in app lifecycle
  static Future<void> _triggerIOSLocalNetworkPermission() async {
    // Only run on iOS
    if (!Platform.isIOS) return;

    HttpClient? client;
    try {
      // Make a simple network request to a common local network address
      // This will trigger the iOS local network permission dialog
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 1);

      // Try to connect to a common local network address
      // This will fail but will trigger the permission dialog
      final request = await client.getUrl(
        Uri.parse('http://192.168.1.1:8080/'),
      );
      await request.close().timeout(const Duration(milliseconds: 500));
    } catch (e) {
      // Expected to fail - we just want to trigger the permission dialog
      // This is intentional and expected behavior
    } finally {
      client?.close();
    }
  }
}
