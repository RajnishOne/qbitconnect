import 'dart:async';

import 'package:flutter/foundation.dart';
import '../api/qbittorrent_api.dart';
import '../services/prefs.dart';
import '../services/firebase_service.dart';
import '../models/torrent.dart';
import '../models/transfer_info.dart';
import '../models/torrent_details.dart';
import '../models/torrent_add_options.dart';
import '../utils/error_handler.dart';
import '../theme/theme_manager.dart';
import '../theme/theme_variants.dart';

// Callback type for real-time updates
typedef TorrentDetailsUpdateCallback =
    void Function(
      TorrentDetails details,
      List<TorrentFile> files,
      List<TorrentTracker> trackers,
    );

class AppState extends ChangeNotifier {
  QbittorrentApiClient? _client;
  bool _isAuthenticated = false;
  Timer? _pollTimer;
  bool _attemptedAuto = false;

  List<Torrent> _torrents = const [];
  TransferInfo? _transferInfo;
  String _activeFilter = 'all';
  String _activeCategory = 'all';
  String _activeSort = 'name';
  String _sortDirection = 'asc';
  Map<String, int> _filterCounts = const {};
  Map<String, int> _categoryCounts = const {};
  List<String> _allCategories = const [];
  String? _serverName;
  String? _baseUrl;
  String? _qbittorrentVersion;

  // App settings
  bool _pollingEnabled = true;
  int _pollingInterval = 4;
  AppThemeVariant _currentTheme = AppThemeVariant.light;

  // Loading states
  final Set<String> _loadingTorrentHashes = {};
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  bool _isInitializing = true;

  // Real-time updates for torrent details
  final Map<String, TorrentDetailsUpdateCallback> _detailsCallbacks = {};
  final Map<String, Timer> _detailsTimers = {};
  final Map<String, Map<String, dynamic>> _cachedDetails = {};

  bool get isAuthenticated => _isAuthenticated;
  String get activeFilter => _activeFilter;
  String get activeCategory => _activeCategory;
  String get activeSort => _activeSort;
  String get sortDirection => _sortDirection;
  List<Torrent> get torrents => _torrents;
  TransferInfo? get transferInfo => _transferInfo;
  Map<String, int> get filterCounts => _filterCounts;
  Map<String, int> get categoryCounts => _categoryCounts;
  List<String> get allCategories => _allCategories;
  bool get pollingEnabled => _pollingEnabled;
  int get pollingInterval => _pollingInterval;
  AppThemeVariant get currentTheme => _currentTheme;
  String? get serverName {
    if (_serverName != null && _serverName!.isNotEmpty) {
      return _serverName;
    }

    // If no server name is set, extract IP and port from base URL
    if (_baseUrl != null) {
      try {
        final uri = Uri.parse(_baseUrl!);
        return '${uri.host}:${uri.port}';
      } catch (e) {
        // If parsing fails, return null
        return null;
      }
    }

    return null;
  }

  String? get qbittorrentVersion => _qbittorrentVersion;
  QbittorrentApiClient? get client => _client;

  // Loading state getters
  bool get isRefreshing => _isRefreshing;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get isInitializing => _isInitializing;
  bool isLoadingTorrent(String hash) => _loadingTorrentHashes.contains(hash);

  // Real-time update methods
  void startRealTimeUpdates(
    String hash,
    TorrentDetailsUpdateCallback callback,
  ) {
    // If polling is disabled, don't start real-time updates
    if (!_pollingEnabled) {
      print('Real-time updates disabled, not starting for $hash');
      return;
    }

    // If there's already a timer for this hash, stop it first
    if (_detailsTimers.containsKey(hash)) {
      print(
        'Stopping existing real-time updates for $hash before starting new ones',
      );
      stopRealTimeUpdates(hash);
    }

    _detailsCallbacks[hash] = callback;

    // Start polling for this specific torrent with configurable interval
    _detailsTimers[hash] = Timer.periodic(Duration(seconds: _pollingInterval), (
      _,
    ) {
      _updateTorrentDetails(hash);
    });

    // Initial load
    _updateTorrentDetails(hash);

    print(
      'Started real-time updates for torrent: $hash with ${_pollingInterval}s interval',
    );
  }

  void stopRealTimeUpdates(String hash) {
    // Remove the callback first
    _detailsCallbacks.remove(hash);

    // Cancel and remove the timer
    final timer = _detailsTimers[hash];
    if (timer != null) {
      timer.cancel();
      _detailsTimers.remove(hash);
    }

    // Clear cached data
    _cachedDetails.remove(hash);

    // Debug logging
    print('Stopped real-time updates for torrent: $hash');
  }

  void stopAllRealTimeUpdates() {
    print(
      'Stopping all real-time updates for ${_detailsTimers.length} torrents',
    );

    // Cancel all timers
    for (final timer in _detailsTimers.values) {
      timer.cancel();
    }

    // Clear all data
    _detailsTimers.clear();
    _detailsCallbacks.clear();
    _cachedDetails.clear();

    print('All real-time updates stopped');
  }

  bool isRealTimeUpdatesActive(String hash) {
    return _detailsTimers.containsKey(hash) &&
        _detailsCallbacks.containsKey(hash);
  }

  int getActiveRealTimeUpdatesCount() {
    return _detailsTimers.length;
  }

  Future<void> _updateTorrentDetails(String hash) async {
    // Multiple safety checks to prevent API calls after cleanup
    if (_client == null) return;
    if (!_detailsCallbacks.containsKey(hash)) return;
    if (!_detailsTimers.containsKey(hash)) return;

    try {
      final results = await Future.wait([
        getTorrentDetails(hash),
        getTorrentFiles(hash),
        getTorrentTrackers(hash),
      ]);

      // Check again after API calls in case cleanup happened during the calls
      if (!_detailsCallbacks.containsKey(hash)) {
        print('Real-time updates stopped for $hash during API calls');
        return;
      }

      final details = results[0] as TorrentDetails?;
      final files = results[1] as List<TorrentFile>;
      final trackers = results[2] as List<TorrentTracker>;

      if (details != null) {
        // Check if data has changed to avoid unnecessary UI updates
        final currentData = {
          'details': details.toMap(),
          'files': files.map((f) => f.toMap()).toList(),
          'trackers': trackers.map((t) => t.toMap()).toList(),
        };

        final cachedData = _cachedDetails[hash];
        if (cachedData == null || !_mapsEqual(cachedData, currentData)) {
          _cachedDetails[hash] = currentData;
          _detailsCallbacks[hash]?.call(details, files, trackers);
        }
      }
    } catch (e) {
      // Log error but don't stop the timer
      print(
        'Error updating torrent details for $hash: ${ErrorHandler.getShortErrorMessage(e)}',
      );
    }
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;

      final val1 = map1[key];
      final val2 = map2[key];

      if (val1 is Map && val2 is Map) {
        if (!_mapsEqual(
          Map<String, dynamic>.from(val1),
          Map<String, dynamic>.from(val2),
        )) {
          return false;
        }
      } else if (val1 is List && val2 is List) {
        if (val1.length != val2.length) return false;
        for (int i = 0; i < val1.length; i++) {
          if (val1[i] is Map && val2[i] is Map) {
            if (!_mapsEqual(
              Map<String, dynamic>.from(val1[i]),
              Map<String, dynamic>.from(val2[i]),
            )) {
              return false;
            }
          } else if (val1[i] != val2[i]) {
            return false;
          }
        }
      } else if (val1 != val2) {
        return false;
      }
    }
    return true;
  }

  Future<void> connect({
    required String baseUrl,
    required String username,
    required String password,
    String? serverName,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final normalized = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      _client = QbittorrentApiClient(
        baseUrl: normalized,
        defaultHeaders: customHeaders,
      );
      await _client!.login(username: username, password: password);

      _isAuthenticated = true;
      _serverName = serverName;
      _baseUrl = normalized;

      // Get qBittorrent version after successful authentication
      try {
        _qbittorrentVersion = await _client!.getVersion();
        debugPrint('Connected to qBittorrent version: $_qbittorrentVersion');
      } catch (e) {
        debugPrint('Failed to get qBittorrent version: $e');
        _qbittorrentVersion = 'Unknown';
      }

      notifyListeners();
      _startPolling();
      await refreshNow();

      // Save session credentials for auto-connect convenience
      await Prefs.saveBaseUrl(baseUrl);
      await Prefs.saveUsername(username);
      await Prefs.savePassword(password);
      if (serverName != null) {
        await Prefs.saveServerName(serverName);
      }
    } catch (e, stackTrace) {
      // Log connection error to Firebase Crashlytics
      await FirebaseService.instance.recordError(e, stackTrace);

      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      _stopPolling();

      // Stop all real-time updates
      stopAllRealTimeUpdates();

      try {
        await _client?.logout();
      } catch (_) {}
      await Prefs.clearPassword();
      _client = null;
      _isAuthenticated = false;
      _torrents = const [];
      _transferInfo = null;
      _hasLoadedOnce = false;
      _serverName = null;
      _baseUrl = null;
      _qbittorrentVersion = null;
      notifyListeners();
    } catch (e, stackTrace) {
      // Log disconnection error to Firebase Crashlytics
      await FirebaseService.instance.recordError(e, stackTrace);
    }
  }

  // Auto-connect using saved prefs
  Future<void> tryAutoConnect() async {
    if (_attemptedAuto || _isAuthenticated) return;
    _attemptedAuto = true;
    final baseUrl = await Prefs.loadBaseUrl();
    final username = await Prefs.loadUsername();
    final password = await Prefs.loadPassword();
    final serverName = await Prefs.loadServerName();
    if (baseUrl == null || username == null || password == null) return;
    try {
      await connect(
        baseUrl: baseUrl,
        username: username,
        password: password,
        serverName: serverName,
      );
    } catch (_) {
      // ignore; user can connect manually
    }
  }

  // Load saved data and attempt auto-connect
  Future<void> loadAndAutoConnect() async {
    _isInitializing = true;
    notifyListeners();

    try {
      // Load app settings and try auto-connect in parallel
      await Future.wait([_loadSettings(), tryAutoConnect()]);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Load app settings from preferences
  Future<void> _loadSettings() async {
    try {
      _activeFilter = await Prefs.loadStatusFilter();
      _activeSort = await Prefs.loadSortField();
      _sortDirection = await Prefs.loadSortDirection();
      _pollingEnabled = await Prefs.loadPollingEnabled();
      _pollingInterval = await Prefs.loadPollingInterval();

      // Load theme with migration support
      _currentTheme = await _loadThemeWithMigration();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  /// Load theme with migration from old dark mode setting
  Future<AppThemeVariant> _loadThemeWithMigration() async {
    try {
      // First try to load the current theme
      final currentTheme = await ThemeManager.getCurrentTheme();

      // Check if user had dark mode enabled in previous version
      final wasDarkMode = await Prefs.loadDarkMode();

      // If they had dark mode enabled and are still on default theme, migrate to dark theme
      if (wasDarkMode && currentTheme.name == 'light') {
        await ThemeManager.setTheme(AppThemeVariant.dark);
        return AppThemeVariant.dark;
      }

      return currentTheme;
    } catch (e) {
      print('Error loading theme with migration: $e');
      return AppThemeVariant.light;
    }
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
    refreshNow();
  }

  void setCategory(String category) {
    _activeCategory = category;
    notifyListeners();
    refreshNow();
  }

  void setSort(String sort) {
    _activeSort = sort;
    Prefs.saveSortField(sort);
    notifyListeners();
    refreshNow();
  }

  void setSortDirection(String direction) {
    _sortDirection = direction;
    Prefs.saveSortDirection(direction);
    notifyListeners();
    refreshNow();
  }

  Future<void> setTheme(AppThemeVariant theme) async {
    _currentTheme = theme;
    await ThemeManager.setTheme(theme);
    notifyListeners();
  }

  void setPollingEnabled(bool enabled) {
    _pollingEnabled = enabled;
    notifyListeners();

    // If polling is disabled, stop current polling
    if (!enabled) {
      _stopPolling();
      // Stop all real-time updates when polling is disabled
      stopAllRealTimeUpdates();
    } else if (_isAuthenticated && _client != null) {
      // If polling is enabled and we're connected, start polling
      _startPolling();
    }
  }

  void setPollingInterval(int seconds) {
    _pollingInterval = seconds;
    notifyListeners();

    // If polling is currently active, restart it with new interval
    if (_pollingEnabled && _isAuthenticated && _client != null) {
      _stopPolling();
      _startPolling();
    }

    // Restart all active real-time updates with new interval
    _restartAllRealTimeUpdates();
  }

  Future<void> refreshNow() async {
    if (_client == null) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _client!.fetchTorrents(
          sort: _activeSort,
          sortDirection: _sortDirection,
        ), // fetch all to compute counts locally
        _client!.fetchTransferInfo(),
      ]);
      final allTorrents = results[0] as List<Torrent>;
      _transferInfo = results[1] as TransferInfo;

      // Compute counts for each filter from the full set
      _filterCounts = _computeFilterCounts(allTorrents);
      _categoryCounts = _computeCategoryCounts(allTorrents);
      _allCategories = _computeAllCategories(allTorrents);

      // Apply active filter and category locally for the displayed list
      final filteredTorrents = allTorrents
          .where(
            (t) =>
                _matchesFilter(t, _activeFilter) &&
                _matchesCategory(t, _activeCategory),
          )
          .toList();

      _torrents = filteredTorrents;

      // Mark that we've successfully loaded data at least once
      _hasLoadedOnce = true;
    } catch (e) {
      print('Error during refresh: ${ErrorHandler.getShortErrorMessage(e)}');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void _startPolling() {
    if (!_pollingEnabled) return;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: _pollingInterval), (_) {
      refreshNow();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _restartAllRealTimeUpdates() {
    if (!_pollingEnabled) return;

    // Get all active hashes before stopping
    final activeHashes = _detailsCallbacks.keys.toList();

    // Stop all current real-time updates
    for (final hash in activeHashes) {
      stopRealTimeUpdates(hash);
    }

    // Restart all real-time updates with new interval
    for (final hash in activeHashes) {
      final callback = _detailsCallbacks[hash];
      if (callback != null) {
        startRealTimeUpdates(hash, callback);
      }
    }
  }

  // App lifecycle methods
  Future<void> onAppResumed() async {
    if (_isAuthenticated && _client != null) {
      _startPolling();
      refreshNow(); // Immediate refresh when app comes back to foreground
    }
  }

  void onAppPaused() {
    if (_isAuthenticated) {
      _stopPolling();
      // Note: We don't stop real-time updates when app is paused
      // as they will be automatically stopped when screens are disposed
      // and the user might want to keep the details screen active
    }
  }

  Future<void> addTorrentFromFile({
    required String fileName,
    required List<int> bytes,
    TorrentAddOptions? options,
  }) async {
    await _client?.addTorrentFromFile(
      fileName: fileName,
      bytes: bytes,
      options: options,
    );
    await refreshNow();
  }

  Future<void> addTorrentFromUrl({
    required String url,
    TorrentAddOptions? options,
  }) async {
    await _client?.addTorrentFromUrl(url: url, options: options);
    await refreshNow();
  }

  Future<void> pauseTorrents(List<String> hashes) async {
    _loadingTorrentHashes.addAll(hashes);
    notifyListeners();

    try {
      await _client?.pauseTorrents(hashes);
      await refreshNow();
    } finally {
      _loadingTorrentHashes.removeAll(hashes);
      notifyListeners();
    }
  }

  Future<void> resumeTorrents(List<String> hashes) async {
    _loadingTorrentHashes.addAll(hashes);
    notifyListeners();

    try {
      await _client?.resumeTorrents(hashes);
      await refreshNow();
    } finally {
      _loadingTorrentHashes.removeAll(hashes);
      notifyListeners();
    }
  }

  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    if (_client == null) return;
    try {
      await _client!.deleteTorrents(hashes, deleteFiles: deleteFiles);
      await refreshNow();
    } catch (e) {
      rethrow; // Re-throw to show error to user
    }
  }

  // Torrent Details Methods
  Future<TorrentDetails?> getTorrentDetails(String hash) async {
    if (_client == null) return null;
    try {
      final properties = await _client!.getTorrentProperties(hash);
      return TorrentDetails.fromMap(properties);
    } catch (e) {
      return null;
    }
  }

  Future<List<TorrentFile>> getTorrentFiles(String hash) async {
    if (_client == null) return [];
    try {
      final files = await _client!.getTorrentFiles(hash);
      return files.map((f) => TorrentFile.fromMap(f)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TorrentTracker>> getTorrentTrackers(String hash) async {
    if (_client == null) return [];
    try {
      final trackers = await _client!.getTorrentTrackers(hash);
      return trackers.map((t) => TorrentTracker.fromMap(t)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> recheckTorrent(String hash) async {
    if (_client == null) return;
    try {
      await _client!.recheckTorrent(hash);
      await refreshNow();
    } catch (e) {
      // Log error for debugging but don't show to user
      print('Recheck torrent error: ${ErrorHandler.getShortErrorMessage(e)}');
    }
  }

  Future<void> setTorrentLocation(String hash, String location) async {
    if (_client == null) return;
    try {
      await _client!.setTorrentLocation(hash, location);
      await refreshNow();
    } catch (e) {
      // Log error for debugging but don't show to user
      print(
        'Set torrent location error: ${ErrorHandler.getShortErrorMessage(e)}',
      );
    }
  }

  Future<void> setTorrentName(String hash, String name) async {
    if (_client == null) return;
    try {
      await _client!.setTorrentName(hash, name);
      await refreshNow();
    } catch (e) {
      // Log error for debugging but don't show to user
      print('Set torrent name error: ${ErrorHandler.getShortErrorMessage(e)}');
    }
  }

  Future<void> setFilePriority(
    String hash,
    List<String> fileIds,
    int priority,
  ) async {
    if (_client == null) return;
    try {
      await _client!.setFilePriority(hash, fileIds, priority);
      await refreshNow();
    } catch (e) {
      // Log error for debugging but don't show to user
      print('Set file priority error: ${ErrorHandler.getShortErrorMessage(e)}');
    }
  }

  // Queue management methods
  Future<void> increaseTorrentPriority(List<String> hashes) async {
    if (_client == null) return;
    try {
      await _client!.increaseTorrentPriority(hashes);
      await refreshNow();
    } catch (e) {
      print(
        'Increase torrent priority error: ${ErrorHandler.getShortErrorMessage(e)}',
      );
      rethrow;
    }
  }

  Future<void> decreaseTorrentPriority(List<String> hashes) async {
    if (_client == null) return;
    try {
      await _client!.decreaseTorrentPriority(hashes);
      await refreshNow();
    } catch (e) {
      print(
        'Decrease torrent priority error: ${ErrorHandler.getShortErrorMessage(e)}',
      );
      rethrow;
    }
  }

  Future<void> moveTorrentToTop(List<String> hashes) async {
    if (_client == null) return;
    try {
      await _client!.moveTorrentToTop(hashes);
      await refreshNow();
    } catch (e) {
      print(
        'Move torrent to top error: ${ErrorHandler.getShortErrorMessage(e)}',
      );
      rethrow;
    }
  }

  Future<void> moveTorrentToBottom(List<String> hashes) async {
    if (_client == null) return;
    try {
      await _client!.moveTorrentToBottom(hashes);
      await refreshNow();
    } catch (e) {
      print(
        'Move torrent to bottom error: ${ErrorHandler.getShortErrorMessage(e)}',
      );
      rethrow;
    }
  }
}

extension on AppState {
  Map<String, int> _computeCategoryCounts(List<Torrent> all) {
    final Map<String, int> counts = {};
    counts['all'] = all.length;

    for (final t in all) {
      final category = t.category.isEmpty ? 'Uncategorized' : t.category;
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return counts;
  }

  List<String> _computeAllCategories(List<Torrent> all) {
    final Set<String> categories = {};
    for (final t in all) {
      if (t.category.isNotEmpty) {
        categories.add(t.category);
      } else {
        categories.add('Uncategorized');
      }
    }
    return categories.toList();
  }

  bool _matchesCategory(Torrent t, String category) {
    if (category == 'all') return true;
    final torrentCategory = t.category.isEmpty ? 'Uncategorized' : t.category;
    return torrentCategory == category;
  }

  Map<String, int> _computeFilterCounts(List<Torrent> all) {
    final Map<String, int> counts = {
      'all': all.length,
      'downloading': 0,
      'completed': 0,
      'seeding': 0,
      'paused': 0,
      'stalled': 0,
      'errored': 0,
      'active': 0,
      'inactive': 0,
    };

    for (final t in all) {
      if (_matchesFilter(t, 'downloading')) {
        counts['downloading'] = (counts['downloading'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'completed')) {
        counts['completed'] = (counts['completed'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'seeding')) {
        counts['seeding'] = (counts['seeding'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'paused')) {
        counts['paused'] = (counts['paused'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'stalled')) {
        counts['stalled'] = (counts['stalled'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'errored')) {
        counts['errored'] = (counts['errored'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'active')) {
        counts['active'] = (counts['active'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'inactive')) {
        counts['inactive'] = (counts['inactive'] ?? 0) + 1;
      }
    }
    return counts;
  }

  bool _matchesFilter(Torrent t, String filter) {
    if (filter == 'all') return true;
    final String state = t.state.toLowerCase();
    final double progress = t.progress;
    final int dlspeed = t.dlspeed;
    final int upspeed = t.upspeed;
    final bool isActive = dlspeed > 0 || upspeed > 0;

    switch (filter) {
      case 'downloading':
        return state.contains('down') && !state.contains('paused');
      case 'completed':
        return progress >= 1.0 &&
            !(state.contains('upload') || state.contains('seed'));
      case 'seeding':
        return state.contains('upload') ||
            state.contains('seed') ||
            upspeed > 0;
      case 'paused':
        return state.contains('paused');
      case 'stalled':
        return state.contains('stalled');
      case 'errored':
        return state.contains('error');
      case 'active':
        return isActive;
      case 'inactive':
        return !isActive;
      default:
        return true;
    }
  }
}
