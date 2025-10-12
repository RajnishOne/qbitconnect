import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/torrent_card_display_options.dart';

class Prefs {
  static const String _keyBaseUrl = 'base_url';
  static const String _keyUsername = 'username';
  static const String _keyServerName = 'server_name';
  static const String _keyCustomHeaders = 'custom_headers_text';
  static const String _keyPassword = 'password';
  static const String _keyNoAuthSession = 'no_auth_session';
  static const String _keyStatusFilter = 'status_filter';
  static const String _keyPollingEnabled = 'polling_enabled';
  static const String _keyPollingInterval = 'polling_interval';
  static const String _keySortField = 'sort_field';
  static const String _keySortDirection = 'sort_direction';
  static const String _keyTorrentCardDisplayOptions =
      'torrent_card_display_options';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<void> saveBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, value);
  }

  static Future<void> saveUsername(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, value);
  }

  static Future<String?> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl);
  }

  static Future<String?> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<void> saveServerName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerName, value);
  }

  static Future<String?> loadServerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerName);
  }

  // Stores the user-entered headers text block (one header per line: "Key: Value").
  static Future<void> saveCustomHeadersText(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomHeaders, value);
  }

  static Future<String?> loadCustomHeadersText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomHeaders);
  }

  // Secure password persistence
  static Future<void> savePassword(String password) async {
    await _secure.write(key: _keyPassword, value: password);
  }

  static Future<String?> loadPassword() async {
    return _secure.read(key: _keyPassword);
  }

  // Status filter settings
  static Future<void> saveStatusFilter(String filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStatusFilter, filter);
  }

  static Future<String> loadStatusFilter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStatusFilter) ?? 'all';
  }

  // No-auth session preference
  static Future<void> saveNoAuthSession(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNoAuthSession, value);
  }

  static Future<bool> loadNoAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNoAuthSession) ?? false;
  }

  // Polling settings
  static Future<void> savePollingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPollingEnabled, enabled);
  }

  static Future<bool> loadPollingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPollingEnabled) ?? true; // Default to enabled
  }

  static Future<void> savePollingInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPollingInterval, seconds);
  }

  static Future<int> loadPollingInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPollingInterval) ?? 4; // Default to 4 seconds
  }

  // Sort settings
  static Future<void> saveSortField(String field) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySortField, field);
  }

  static Future<String> loadSortField() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySortField) ?? 'name'; // Default to name
  }

  static Future<void> saveSortDirection(String direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySortDirection, direction);
  }

  static Future<String> loadSortDirection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySortDirection) ?? 'asc'; // Default to ascending
  }

  // Torrent card display options
  static Future<void> saveTorrentCardDisplayOptions(
    List<TorrentCardDisplayOption> options,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> optionNames = options
        .map((option) => option.name)
        .toList();
    await prefs.setStringList(_keyTorrentCardDisplayOptions, optionNames);
  }

  static Future<List<TorrentCardDisplayOption>>
  loadTorrentCardDisplayOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? optionNames = prefs.getStringList(
      _keyTorrentCardDisplayOptions,
    );

    if (optionNames == null || optionNames.isEmpty) {
      return TorrentCardDisplayOption.defaultOptions;
    }

    final List<TorrentCardDisplayOption> options = [];
    for (final name in optionNames) {
      try {
        final option = TorrentCardDisplayOption.values.firstWhere(
          (opt) => opt.name == name,
        );
        options.add(option);
      } catch (e) {
        // Skip invalid option names
        continue;
      }
    }

    // Ensure we have at least the default options if none are valid
    if (options.isEmpty) {
      return TorrentCardDisplayOption.defaultOptions;
    }

    return options;
  }
}
