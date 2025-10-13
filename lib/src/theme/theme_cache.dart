import 'package:flutter/material.dart';
import 'theme_manager.dart';
import 'theme_variants.dart';

/// Theme cache for optimizing theme loading and avoiding nested FutureBuilders
class ThemeCache {
  static ThemeData? _lightTheme;
  static ThemeData? _darkTheme;
  static AppThemeVariant? _currentThemeVariant;
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// Initialize the theme cache
  static Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Load current theme variant
      _currentThemeVariant = await ThemeManager.getCurrentTheme();

      // Load both light and dark themes in parallel
      final futures = await Future.wait([
        ThemeManager.getLightTheme(),
        ThemeManager.getDarkTheme(),
      ]);

      _lightTheme = futures[0];
      _darkTheme = futures[1];
      _isInitialized = true;
    } catch (e) {
      // Fallback to default themes if loading fails
      _lightTheme = ThemeData.light();
      _darkTheme = ThemeData.dark();
      _currentThemeVariant = AppThemeVariant.system;
      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  /// Get the cached light theme
  static ThemeData get lightTheme {
    if (!_isInitialized) {
      throw StateError('ThemeCache not initialized. Call initialize() first.');
    }
    return _lightTheme!;
  }

  /// Get the cached dark theme
  static ThemeData get darkTheme {
    if (!_isInitialized) {
      throw StateError('ThemeCache not initialized. Call initialize() first.');
    }
    return _darkTheme!;
  }

  /// Get the current theme variant
  static AppThemeVariant get currentThemeVariant {
    if (!_isInitialized) {
      throw StateError('ThemeCache not initialized. Call initialize() first.');
    }
    return _currentThemeVariant!;
  }

  /// Check if the cache is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if the cache is currently initializing
  static bool get isInitializing => _isInitializing;

  /// Update the current theme and refresh the cache
  static Future<void> updateTheme(AppThemeVariant newTheme) async {
    if (!_isInitialized) {
      await initialize();
    }

    _currentThemeVariant = newTheme;

    // Refresh both themes with the new variant
    final futures = await Future.wait([
      ThemeManager.getLightTheme(),
      ThemeManager.getDarkTheme(),
    ]);

    _lightTheme = futures[0];
    _darkTheme = futures[1];
  }

  /// Clear the cache (useful for testing or theme reset)
  static void clear() {
    _lightTheme = null;
    _darkTheme = null;
    _currentThemeVariant = null;
    _isInitialized = false;
    _isInitializing = false;
  }

  /// Get theme mode based on current theme variant
  static ThemeMode getThemeMode() {
    if (!_isInitialized) {
      return ThemeMode.system;
    }

    switch (_currentThemeVariant!.name) {
      case 'light':
      case 'high_contrast_light':
        return ThemeMode.light;
      case 'dark':
      case 'oled':
      case 'high_contrast_dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
