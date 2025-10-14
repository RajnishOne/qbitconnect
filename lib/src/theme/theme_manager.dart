import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme_variants.dart';
import '../constants/locale_keys.dart';

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
    switch (theme.name) {
      case 'light':
        return LocaleKeys.lightTheme.tr();
      case 'dark':
        return LocaleKeys.darkTheme.tr();
      case 'oled':
        return LocaleKeys.oledTheme.tr();
      case 'system':
        return LocaleKeys.systemTheme.tr();
      case 'high_contrast_light':
        return LocaleKeys.highContrastLightTheme.tr();
      case 'high_contrast_dark':
        return LocaleKeys.highContrastDarkTheme.tr();
      default:
        return theme.displayName;
    }
  }

  /// Get theme description
  static String getThemeDescription(AppThemeVariant theme) {
    switch (theme.name) {
      case 'light':
        return LocaleKeys.lightThemeDescription.tr();
      case 'dark':
        return LocaleKeys.darkThemeDescription.tr();
      case 'oled':
        return LocaleKeys.oledThemeDescription.tr();
      case 'system':
        return LocaleKeys.systemThemeDescription.tr();
      case 'high_contrast_light':
        return LocaleKeys.highContrastLightThemeDescription.tr();
      case 'high_contrast_dark':
        return LocaleKeys.highContrastDarkThemeDescription.tr();
      default:
        return theme.description;
    }
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
