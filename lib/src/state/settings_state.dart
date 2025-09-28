import 'package:flutter/foundation.dart';
import '../services/prefs.dart';
import '../theme/theme_manager.dart';
import '../theme/theme_cache.dart';
import '../theme/theme_variants.dart';
import '../services/display_options_cache.dart';

/// Manages app settings, preferences, and configuration
class SettingsState extends ChangeNotifier {
  // Filter and sort settings
  String _activeFilter = 'all';
  String _activeCategory = 'all';
  String _activeSort = 'name';
  String _sortDirection = 'asc';

  // App settings
  bool _pollingEnabled = true;
  int _pollingInterval = 4;
  AppThemeVariant _currentTheme = AppThemeVariant.light;

  // Getters
  String get activeFilter => _activeFilter;
  String get activeCategory => _activeCategory;
  String get activeSort => _activeSort;
  String get sortDirection => _sortDirection;
  bool get pollingEnabled => _pollingEnabled;
  int get pollingInterval => _pollingInterval;
  AppThemeVariant get currentTheme => _currentTheme;

  /// Load settings from preferences
  Future<void> loadSettings() async {
    try {
      _activeFilter = await Prefs.loadStatusFilter();
      _activeSort = await Prefs.loadSortField();
      _sortDirection = await Prefs.loadSortDirection();
      _pollingEnabled = await Prefs.loadPollingEnabled();
      _pollingInterval = await Prefs.loadPollingInterval();

      // Load theme with migration support
      _currentTheme = await _loadTheme();

      // Initialize display options cache in background
      DisplayOptionsCache.loadOptions();

      notifyListeners();
    } catch (e) {
      // Error loading settings: $e
      // Use default values to ensure app doesn't break
      _activeFilter = 'all';
      _activeSort = 'name';
      _sortDirection = 'asc';
      _pollingEnabled = true;
      _pollingInterval = 4;
      _currentTheme = AppThemeVariant.light;
      notifyListeners();
    }
  }

  /// Load current theme
  Future<AppThemeVariant> _loadTheme() async {
    try {
      return await ThemeManager.getCurrentTheme();
    } catch (e) {
      // Error loading theme: $e
      return AppThemeVariant.light;
    }
  }

  /// Set filter
  void setFilter(String filter) {
    _activeFilter = filter;
    Prefs.saveStatusFilter(filter);
    notifyListeners();
  }

  /// Set category
  void setCategory(String category) {
    _activeCategory = category;
    // Note: Category is not persisted as it's typically session-based
    notifyListeners();
  }

  /// Set sort field
  void setSort(String sort) {
    _activeSort = sort;
    Prefs.saveSortField(sort);
    notifyListeners();
  }

  /// Set sort direction
  void setSortDirection(String direction) {
    _sortDirection = direction;
    Prefs.saveSortDirection(direction);
    notifyListeners();
  }

  /// Set theme
  Future<void> setTheme(AppThemeVariant theme) async {
    _currentTheme = theme;
    await ThemeManager.setTheme(theme);
    // Update the theme cache to reflect the new theme
    await ThemeCache.updateTheme(theme);
    notifyListeners();
  }

  /// Set polling enabled state
  void setPollingEnabled(bool enabled) {
    _pollingEnabled = enabled;
    Prefs.savePollingEnabled(enabled);
    notifyListeners();
  }

  /// Set polling interval
  void setPollingInterval(int seconds) {
    _pollingInterval = seconds;
    Prefs.savePollingInterval(seconds);
    notifyListeners();
  }
}
