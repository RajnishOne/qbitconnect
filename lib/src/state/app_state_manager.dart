import 'dart:async';

import 'package:flutter/foundation.dart';
import '../api/qbittorrent_api.dart';
import '../models/torrent.dart';
import '../models/transfer_info.dart';
import '../models/torrent_details.dart';
import '../models/torrent_add_options.dart';
import '../theme/theme_variants.dart';
import 'connection_state.dart';
import 'torrent_state.dart';
import 'settings_state.dart';
import 'realtime_state.dart';

/// Main app state manager that coordinates between all specialized state classes
/// This class acts as a facade, delegating to focused state managers while
/// maintaining the same public API for backward compatibility
class AppState extends ChangeNotifier {
  // Specialized state managers
  final ConnectionState _connectionState = ConnectionState();
  final TorrentState _torrentState = TorrentState();
  final SettingsState _settingsState = SettingsState();
  final RealTimeState _realtimeState = RealTimeState();

  // Initialize the app state
  AppState() {
    // Listen to changes in specialized states and forward them
    _connectionState.addListener(_onConnectionStateChanged);
    _torrentState.addListener(_onTorrentStateChanged);
    _settingsState.addListener(_onSettingsStateChanged);
    _realtimeState.addListener(_onRealtimeStateChanged);
  }

  // Connection state delegates
  bool get isAuthenticated => _connectionState.isAuthenticated;
  bool get isInitializing => _connectionState.isInitializing;
  QbittorrentApiClient? get client => _connectionState.client;
  String? get serverName => _connectionState.serverName;
  String? get baseUrl => _connectionState.baseUrl;
  String? get qbittorrentVersion => _connectionState.qbittorrentVersion;

  // Torrent state delegates
  List<Torrent> get torrents => _torrentState.torrents;
  TransferInfo? get transferInfo => _torrentState.transferInfo;
  Map<String, int> get filterCounts => _torrentState.filterCounts;
  Map<String, int> get categoryCounts => _torrentState.categoryCounts;
  List<String> get allCategories => _torrentState.allCategories;
  bool get isRefreshing => _torrentState.isRefreshing;
  bool get hasLoadedOnce => _torrentState.hasLoadedOnce;
  bool isLoadingTorrent(String hash) => _torrentState.isLoadingTorrent(hash);

  // Settings state delegates
  String get activeFilter => _settingsState.activeFilter;
  String get activeCategory => _settingsState.activeCategory;
  String get activeSort => _settingsState.activeSort;
  String get sortDirection => _settingsState.sortDirection;
  bool get pollingEnabled => _settingsState.pollingEnabled;
  int get pollingInterval => _settingsState.pollingInterval;
  AppThemeVariant get currentTheme => _settingsState.currentTheme;

  // Real-time state delegates
  bool isRealTimeUpdatesActive(String hash) =>
      _realtimeState.isRealTimeUpdatesActive(hash);
  int getActiveRealTimeUpdatesCount() =>
      _realtimeState.getActiveRealTimeUpdatesCount();

  /// Initialize app and load settings
  Future<void> loadAndAutoConnect() async {
    try {
      // Load settings first
      await _settingsState.loadSettings();

      // Initialize connection (includes auto-connect)
      // The connection state change handler will automatically start polling if successful
      await _connectionState.initialize();
    } catch (e) {
      // Handle initialization errors
    }
  }

  // Connection methods
  Future<void> connect({
    required String baseUrl,
    required String username,
    required String password,
    String? serverName,
    Map<String, String>? customHeaders,
    bool allowNoAuth = false,
  }) async {
    await _connectionState.connect(
      baseUrl: baseUrl,
      username: username,
      password: password,
      serverName: serverName,
      customHeaders: customHeaders,
      allowNoAuth: allowNoAuth,
    );
    // The connection state change handler will automatically start polling if successful
  }

  Future<void> disconnect() async {
    _stopPolling();
    _realtimeState.stopAllRealTimeUpdates();
    _torrentState.clearData();
    await _connectionState.disconnect();
  }

  // Settings methods
  void setFilter(String filter) {
    _settingsState.setFilter(filter);
    _debouncedRefresh();
  }

  void setCategory(String category) {
    _settingsState.setCategory(category);
    _debouncedRefresh();
  }

  void setSort(String sort) {
    _settingsState.setSort(sort);
    _debouncedRefresh();
  }

  void setSortDirection(String direction) {
    _settingsState.setSortDirection(direction);
    _debouncedRefresh();
  }

  Future<void> setTheme(AppThemeVariant theme) async {
    await _settingsState.setTheme(theme);
  }

  void setPollingEnabled(bool enabled) {
    _settingsState.setPollingEnabled(enabled);

    if (!enabled) {
      _stopPolling();
      _realtimeState.stopAllRealTimeUpdates();
    } else if (isAuthenticated && client != null) {
      _startPolling();
    }
  }

  void setPollingInterval(int seconds) {
    _settingsState.setPollingInterval(seconds);

    if (_settingsState.pollingEnabled && isAuthenticated && client != null) {
      _stopPolling();
      _startPolling();
    }

    _realtimeState.restartAllRealTimeUpdates(
      pollingEnabled: _settingsState.pollingEnabled,
      pollingInterval: _settingsState.pollingInterval,
      updateTorrentDetails: _updateTorrentDetails,
    );
  }

  // Torrent operations
  Future<void> refreshNow() async {
    if (client == null) return;

    await _torrentState.refreshTorrents(
      client!,
      _settingsState.activeSort,
      _settingsState.sortDirection,
      _settingsState.activeFilter,
      _settingsState.activeCategory,
    );
  }

  Future<void> addTorrentFromFile({
    required String fileName,
    required List<int> bytes,
    TorrentAddOptions? options,
  }) async {
    if (client == null) return;

    await _torrentState.addTorrentFromFile(
      client: client!,
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
    if (client == null) return;

    await _torrentState.addTorrentFromUrl(
      client: client!,
      url: url,
      options: options,
    );
    await refreshNow();
  }

  Future<void> pauseTorrents(List<String> hashes) async {
    if (client == null) return;

    await _torrentState.pauseTorrents(client!, hashes);
    await refreshNow();
  }

  Future<void> resumeTorrents(List<String> hashes) async {
    if (client == null) return;

    await _torrentState.resumeTorrents(client!, hashes);
    await refreshNow();
  }

  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    if (client == null) return;

    await _torrentState.deleteTorrents(
      client!,
      hashes,
      deleteFiles: deleteFiles,
    );
    await refreshNow();
  }

  // Torrent details methods
  Future<TorrentDetails?> getTorrentDetails(String hash) async {
    if (client == null) return null;
    return await _torrentState.getTorrentDetails(client!, hash);
  }

  Future<List<TorrentFile>> getTorrentFiles(String hash) async {
    if (client == null) return [];
    return await _torrentState.getTorrentFiles(client!, hash);
  }

  Future<List<TorrentTracker>> getTorrentTrackers(String hash) async {
    if (client == null) return [];
    return await _torrentState.getTorrentTrackers(client!, hash);
  }

  Future<void> recheckTorrent(String hash) async {
    if (client == null) return;

    await _torrentState.recheckTorrent(client!, hash);
    await refreshNow();
  }

  Future<void> setTorrentLocation(String hash, String location) async {
    if (client == null) return;

    await _torrentState.setTorrentLocation(client!, hash, location);
    await refreshNow();
  }

  Future<void> setTorrentName(String hash, String name) async {
    if (client == null) return;

    await _torrentState.setTorrentName(client!, hash, name);
    await refreshNow();
  }

  Future<void> setFilePriority(
    String hash,
    List<String> fileIds,
    int priority,
  ) async {
    if (client == null) return;

    await _torrentState.setFilePriority(client!, hash, fileIds, priority);
    await refreshNow();
  }

  // Queue management methods
  Future<void> increaseTorrentPriority(List<String> hashes) async {
    if (client == null) return;

    await _torrentState.increaseTorrentPriority(client!, hashes);
    await refreshNow();
  }

  Future<void> decreaseTorrentPriority(List<String> hashes) async {
    if (client == null) return;

    await _torrentState.decreaseTorrentPriority(client!, hashes);
    await refreshNow();
  }

  Future<void> moveTorrentToTop(List<String> hashes) async {
    if (client == null) return;

    await _torrentState.moveTorrentToTop(client!, hashes);
    await refreshNow();
  }

  Future<void> moveTorrentToBottom(List<String> hashes) async {
    if (client == null) return;

    await _torrentState.moveTorrentToBottom(client!, hashes);
    await refreshNow();
  }

  // Real-time updates methods
  void startRealTimeUpdates(
    String hash,
    TorrentDetailsUpdateCallback callback,
  ) {
    _realtimeState.startRealTimeUpdates(
      hash,
      callback,
      pollingEnabled: _settingsState.pollingEnabled,
      pollingInterval: _settingsState.pollingInterval,
      updateTorrentDetails: _updateTorrentDetails,
    );
  }

  void stopRealTimeUpdates(String hash) {
    _realtimeState.stopRealTimeUpdates(hash);
  }

  void stopAllRealTimeUpdates() {
    _realtimeState.stopAllRealTimeUpdates();
  }

  Future<void> _updateTorrentDetails(String hash) async {
    if (client == null) return;

    try {
      final results = await Future.wait([
        getTorrentDetails(hash),
        getTorrentFiles(hash),
        getTorrentTrackers(hash),
      ]);

      final details = results[0] as TorrentDetails?;
      final files = results[1] as List<TorrentFile>;
      final trackers = results[2] as List<TorrentTracker>;

      _realtimeState.updateTorrentDetailsData(hash, details, files, trackers);
    } catch (e) {
      // Error updating torrent details for $hash: ${ErrorHandler.getShortErrorMessage(e)}
    }
  }

  // App lifecycle methods
  Future<void> onAppResumed() async {
    if (isAuthenticated && client != null && _settingsState.pollingEnabled) {
      if (!_pollingStarted) {
        _startPolling();
      }
      await refreshNow(); // Immediate refresh when app comes back to foreground
    }
  }

  void onAppPaused() {
    if (isAuthenticated) {
      _stopPolling();
      _realtimeState.clearCaches();
      // Note: We don't stop real-time updates when app is paused
      // as they will be automatically stopped when screens are disposed
      // and the user might want to keep the details screen active
    }
  }

  // Private methods
  Timer? _refreshDebounceTimer;

  void _debouncedRefresh() {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      refreshNow();
    });
  }

  void _startPolling() {
    _realtimeState.startPolling(
      pollingEnabled: _settingsState.pollingEnabled,
      pollingInterval: _settingsState.pollingInterval,
      onRefresh: refreshNow,
    );
  }

  void _stopPolling() {
    _realtimeState.stopPolling();
  }

  // State change handlers
  bool _pollingStarted = false;

  void _onConnectionStateChanged() {
    // If we just got authenticated, start polling and refresh
    if (_connectionState.isAuthenticated &&
        client != null &&
        !_pollingStarted) {
      _pollingStarted = true;
      _startPolling();
      refreshNow().catchError((e) {
        // Background refresh failed, ignore
      });
    } else if (!_connectionState.isAuthenticated && _pollingStarted) {
      // If we got disconnected, stop polling and clear data
      _pollingStarted = false;
      _stopPolling();
      _realtimeState.stopAllRealTimeUpdates();
      _torrentState.clearData();
    }
    notifyListeners();
  }

  void _onTorrentStateChanged() {
    notifyListeners();
  }

  void _onSettingsStateChanged() {
    notifyListeners();
  }

  void _onRealtimeStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionState.removeListener(_onConnectionStateChanged);
    _torrentState.removeListener(_onTorrentStateChanged);
    _settingsState.removeListener(_onSettingsStateChanged);
    _realtimeState.removeListener(_onRealtimeStateChanged);

    _refreshDebounceTimer?.cancel();
    _connectionState.dispose();
    _torrentState.dispose();
    _settingsState.dispose();
    _realtimeState.dispose();

    super.dispose();
  }
}
