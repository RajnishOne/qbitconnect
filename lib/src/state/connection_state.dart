import 'dart:async';

import 'package:flutter/foundation.dart';
import '../api/qbittorrent_api.dart';
import '../services/prefs.dart';
import '../services/firebase_service.dart';

/// Manages connection state, authentication, and API client lifecycle
class ConnectionState extends ChangeNotifier {
  QbittorrentApiClient? _client;
  bool _isAuthenticated = false;
  bool _attemptedAuto = false;
  bool _isInitializing = true;

  // Server information
  String? _serverName;
  String? _baseUrl;
  String? _qbittorrentVersion;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  bool get attemptedAuto => _attemptedAuto;
  QbittorrentApiClient? get client => _client;
  String? get serverName => _serverName;
  String? get baseUrl => _baseUrl;
  String? get qbittorrentVersion => _qbittorrentVersion;

  /// Connect to qBittorrent server
  Future<void> connect({
    required String baseUrl,
    required String username,
    required String password,
    String? serverName,
    Map<String, String>? customHeaders,
    bool allowNoAuth = false,
  }) async {
    // Prevent multiple simultaneous connection attempts
    if (_isAuthenticated) {
      return;
    }

    try {
      final normalized = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

      _client = QbittorrentApiClient(
        baseUrl: normalized,
        defaultHeaders: customHeaders,
      );

      // Try authentication based on provided credentials and settings
      if (username.isNotEmpty && password.isNotEmpty) {
        // Use provided credentials
        await _client!.login(username: username, password: password);
      } else if (allowNoAuth) {
        // Try to connect without authentication
        await _client!.loginWithoutAuth();
      } else {
        throw Exception(
          'Username and password are required for authentication',
        );
      }

      _isAuthenticated = true;
      _serverName = serverName;
      _baseUrl = normalized;

      // Get qBittorrent version after successful authentication
      try {
        _qbittorrentVersion = await _client!.getVersion();
      } catch (e) {
        _qbittorrentVersion = 'Unknown';
      }

      // Save session credentials for auto-connect convenience
      await Prefs.saveBaseUrl(baseUrl);
      if (username.isNotEmpty) {
        await Prefs.saveUsername(username);
      }
      if (password.isNotEmpty) {
        await Prefs.savePassword(password);
      }
      if (serverName != null) {
        await Prefs.saveServerName(serverName);
      }

      // Save no-auth session flag if connection was made without authentication
      await Prefs.saveNoAuthSession(
        allowNoAuth && (username.isEmpty || password.isEmpty),
      );

      notifyListeners();
    } catch (e, stackTrace) {
      // Clean up on connection failure
      _client = null;
      _isAuthenticated = false;

      // Only log to Crashlytics if it's not a connection timeout (expected behavior)
      if (e.toString().contains('connection timeout') ||
          e.toString().contains('Connection timeout')) {
        // This is expected behavior for inaccessible servers, don't log as crash
      } else {
        // Log unexpected errors to Firebase Crashlytics
        await FirebaseService.instance.recordError(e, stackTrace);
      }

      // Notify listeners of connection failure
      notifyListeners();
      rethrow;
    }
  }

  /// Disconnect from qBittorrent server
  Future<void> disconnect() async {
    try {
      try {
        await _client?.logout();
      } catch (_) {}

      // Only clear password if user hasn't opted to save it
      final savePasswordPreference = await Prefs.loadSavePasswordPreference();
      if (!savePasswordPreference) {
        await Prefs.clearPassword();
      }

      // Clear no-auth session flag on disconnect
      await Prefs.saveNoAuthSession(false);

      _client = null;
      _isAuthenticated = false;
      _serverName = null;
      _baseUrl = null;
      _qbittorrentVersion = null;
      notifyListeners();
    } catch (e, stackTrace) {
      // Log disconnection error to Firebase Crashlytics
      await FirebaseService.instance.recordError(e, stackTrace);
    }
  }

  /// Auto-connect using saved preferences
  Future<void> tryAutoConnect() async {
    if (_attemptedAuto || _isAuthenticated) return;
    _attemptedAuto = true;

    final baseUrl = await Prefs.loadBaseUrl();
    final username = await Prefs.loadUsername();
    final password = await Prefs.loadPassword();
    final serverName = await Prefs.loadServerName();
    final isNoAuthSession = await Prefs.loadNoAuthSession();

    if (baseUrl == null) {
      return;
    }

    // Check if we have a no-auth session saved
    if (isNoAuthSession) {
      try {
        await connect(
          baseUrl: baseUrl,
          username: username ?? '',
          password: password ?? '',
          serverName: serverName,
          allowNoAuth: true,
        );
        return;
      } catch (_) {
        // If no-auth fails, try with credentials if available
        // ignore; will try with credentials below
      }
    }

    // Try with credentials if available
    if (username != null && password != null && password.isNotEmpty) {
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
  }

  /// Initialize connection state and attempt auto-connect
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      await tryAutoConnect();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _client = null;
    super.dispose();
  }
}
