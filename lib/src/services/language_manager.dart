import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language information model
class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final Locale locale;

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.locale,
  });

  @override
  String toString() => nativeName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageInfo &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Language manager for handling app localization
class LanguageManager {
  static const String _languageKey = 'selected_language';

  /// Default language (English)
  static const String defaultLanguageCode = 'en';

  /// Available languages (must match EasyLocalization supportedLocales)
  static const List<LanguageInfo> availableLanguages = [
    LanguageInfo(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      locale: Locale('en', 'US'),
    ),
    LanguageInfo(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      locale: Locale('es', 'ES'),
    ),
    LanguageInfo(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      locale: Locale('fr', 'FR'),
    ),
    LanguageInfo(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      locale: Locale('de', 'DE'),
    ),
  ];

  /// Get the current selected language
  static Future<LanguageInfo> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? defaultLanguageCode;

    return availableLanguages.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => availableLanguages.first, // Fallback to English
    );
  }

  /// Set the current language
  static Future<void> setLanguage(LanguageInfo language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);

    // EasyLocalization will handle the context automatically
  }

  /// Get language by code
  static LanguageInfo? getLanguageByCode(String code) {
    try {
      return availableLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get default language
  static LanguageInfo getDefaultLanguage() {
    return availableLanguages.first;
  }

  /// Check if a language is available
  static bool isLanguageAvailable(String code) {
    return availableLanguages.any((lang) => lang.code == code);
  }

  /// Get supported locales for the app
  static List<Locale> getSupportedLocales() {
    return availableLanguages.map((lang) => lang.locale).toList();
  }

  /// Get locale from language code
  static Locale getLocaleFromCode(String code) {
    final language = getLanguageByCode(code);
    return language?.locale ?? Locale(defaultLanguageCode);
  }

  /// Get display name for language code
  static String getDisplayName(String code) {
    final language = getLanguageByCode(code);
    return language?.nativeName ?? 'English';
  }

  /// Get language name in English for language code
  static String getEnglishName(String code) {
    final language = getLanguageByCode(code);
    return language?.name ?? 'English';
  }

  /// Reset to default language
  static Future<void> resetToDefault() async {
    await setLanguage(getDefaultLanguage());
  }

  /// Get language info for current system locale
  static LanguageInfo getSystemLanguage() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final systemLanguage = availableLanguages.firstWhere(
      (lang) => lang.code == systemLocale.languageCode,
      orElse: () => getDefaultLanguage(),
    );
    return systemLanguage;
  }

  /// Check if current language is RTL (Right-to-Left)
  static bool isRTL(String languageCode) {
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(languageCode);
  }
}
