import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_variants.dart';

/// Theme manager for handling multiple theme options
class ThemeManager {
  static const String _themeKey = 'selected_theme';

  // Available themes
  static const List<AppThemeVariant> availableThemes = [
    AppThemeVariant.light,
    AppThemeVariant.dark,
    AppThemeVariant.oled,
    AppThemeVariant.highContrastLight,
    AppThemeVariant.highContrastDark,
    AppThemeVariant.system,
  ];

  /// Get the current theme variant
  static Future<AppThemeVariant> getCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? AppThemeVariant.system.name;

    return availableThemes.firstWhere(
      (theme) => theme.name == themeName,
      orElse: () => AppThemeVariant.system,
    );
  }

  /// Set the current theme variant
  static Future<void> setTheme(AppThemeVariant theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }

  /// Get theme data for the current theme variant
  static Future<ThemeData> getThemeData({required bool isDarkMode}) async {
    final currentTheme = await getCurrentTheme();
    return currentTheme.getThemeData(isDarkMode: isDarkMode);
  }

  /// Get light theme data for the current theme variant
  static Future<ThemeData> getLightTheme() async {
    return getThemeData(isDarkMode: false);
  }

  /// Get dark theme data for the current theme variant
  static Future<ThemeData> getDarkTheme() async {
    return getThemeData(isDarkMode: true);
  }

  /// Get theme display name
  static String getThemeDisplayName(AppThemeVariant theme) {
    return theme.displayName;
  }

  /// Get theme description
  static String getThemeDescription(AppThemeVariant theme) {
    return theme.description;
  }

  /// Get theme preview colors
  static List<Color> getThemePreviewColors(
    AppThemeVariant theme, {
    required bool isDarkMode,
  }) {
    final colorScheme = theme.getColorScheme(isDarkMode: isDarkMode);
    return [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.surface,
      colorScheme.background,
    ];
  }
}
