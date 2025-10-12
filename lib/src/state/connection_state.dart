import 'dart:async';

import 'package:flutter/foundation.dart';
import '../api/qbittorrent_api.dart';
import '../services/prefs.dart';
import '../services/firebase_service.dart';
import '../services/server_storage.dart';
import '../models/server_config.dart';

/// Manages connection state, authentication, and API client lifecycle
class ConnectionState extends ChangeNotifier {
  QbittorrentApiClient? _client;
  bool _isAuthenticated = false;
  bool _attemptedAuto = false;
  bool _isInitializing = true;
  bool _autoConnectFailed = false;

  // Server information
  String? _serverName;
  String? _baseUrl;
  String? _qbittorrentVersion;
  String? _activeServerId;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  bool get attemptedAuto => _attemptedAuto;
  bool get autoConnectFailed => _autoConnectFailed;
  QbittorrentApiClient? get client => _client;
  String? get serverName => _serverName;
  String? get baseUrl => _baseUrl;
  String? get qbittorrentVersion => _qbittorrentVersion;
  String? get activeServerId => _activeServerId;

  /// Get the active server configuration
  Future<ServerConfig?> getActiveServer() async {
    if (_activeServerId == null) return null;
    return await ServerStorage.getServerConfig(_activeServerId!);
  }

  /// Get all saved servers
  Future<List<ServerConfig>> getAllServers() async {
    return await ServerStorage.loadServerConfigs();
  }

  /// Connect to a saved server configuration
  Future<void> connectToServer(ServerConfig server) async {
    // Load password from secure storage
    final password = await ServerStorage.loadServerPassword(server.id);

    // Parse custom headers
    final customHeaders = server.parseCustomHeaders();

    // Connect using the server configuration
    await _performConnection(
      serverId: server.id,
      baseUrl: server.baseUrl,
      username: server.username,
      password: password ?? '',
      serverName: server.name,
      customHeaders: customHeaders,
      allowNoAuth: server.noAuthSession,
    );

    // Update last connected timestamp and version
    await ServerStorage.updateLastConnected(server.id);
    if (_qbittorrentVersion != null) {
      await ServerStorage.updateServerVersion(server.id, _qbittorrentVersion!);
    }

    // Set as active server and auto-connect server
    await ServerStorage.setActiveServerId(server.id);
    await ServerStorage.setAutoConnectServerId(server.id);
    _activeServerId = server.id;

    // Clear auto-connect failure flag on successful connection
    _autoConnectFailed = false;
  }

  /// Connect to a server by ID
  Future<void> connectToServerId(String serverId) async {
    final server = await ServerStorage.getServerConfig(serverId);
    if (server == null) {
      throw Exception('Server configuration not found');
    }
    await connectToServer(server);
  }

  /// Connect to qBittorrent server (legacy method - creates/updates server config)
  Future<void> connect({
    required String baseUrl,
    required String username,
    required String password,
    String? serverName,
    Map<String, String>? customHeaders,
    bool allowNoAuth = false,
    bool saveAsNewServer = true,
  }) async {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // Create or update server configuration if requested
    String? serverId;
    if (saveAsNewServer) {
      // Format custom headers as text
      final customHeadersText =
          customHeaders != null && customHeaders.isNotEmpty
          ? customHeaders.entries.map((e) => '${e.key}: ${e.value}').join('\n')
          : null;

      // Check if a server with this URL already exists
      final existingServers = await ServerStorage.loadServerConfigs();
      final existingServer = existingServers
          .where((s) => s.baseUrl == normalized)
          .firstOrNull;

      if (existingServer != null) {
        // Update existing server
        serverId = existingServer.id;
        final updated = existingServer.copyWith(
          name: serverName ?? existingServer.name,
          username: username.isNotEmpty ? username : existingServer.username,
          noAuthSession: allowNoAuth && (username.isEmpty || password.isEmpty),
          customHeadersText:
              customHeadersText ?? existingServer.customHeadersText,
        );
        await ServerStorage.updateServerConfig(updated);
      } else {
        // Create new server
        final newServer = ServerStorage.createNewServer(
          name: serverName ?? _extractServerNameFromUrl(normalized),
          baseUrl: normalized,
          username: username,
          customHeadersText: customHeadersText,
          noAuthSession: allowNoAuth && (username.isEmpty || password.isEmpty),
        );
        serverId = newServer.id;
        await ServerStorage.addServerConfig(newServer);
      }

      // Save password if provided
      if (password.isNotEmpty) {
        await ServerStorage.saveServerPassword(serverId, password);
      }
    }

    // Perform the actual connection
    await _performConnection(
      serverId: serverId,
      baseUrl: normalized,
      username: username,
      password: password,
      serverName: serverName,
      customHeaders: customHeaders,
      allowNoAuth: allowNoAuth,
    );

    // Update server metadata if saved
    if (serverId != null) {
      await ServerStorage.updateLastConnected(serverId);
      if (_qbittorrentVersion != null) {
        await ServerStorage.updateServerVersion(serverId, _qbittorrentVersion!);
      }
      await ServerStorage.setActiveServerId(serverId);
      _activeServerId = serverId;
    }

    // Also save to legacy storage for backward compatibility
    await _saveLegacyPreferences(
      baseUrl: normalized,
      username: username,
      password: password,
      serverName: serverName,
      customHeaders: customHeaders,
      allowNoAuth: allowNoAuth,
    );
  }

  /// Perform the actual connection (shared logic)
  Future<void> _performConnection({
    String? serverId,
    required String baseUrl,
    required String username,
    required String password,
    String? serverName,
    Map<String, String>? customHeaders,
    bool allowNoAuth = false,
  }) async {
    // Disconnect from current server if already connected to a different one
    if (_isAuthenticated && _baseUrl != baseUrl) {
      try {
        await _client?.logout();
      } catch (_) {
        // Ignore logout errors
      }
      _client = null;
      _isAuthenticated = false;
    }

    // Prevent multiple simultaneous connection attempts to the same server
    if (_isAuthenticated && _baseUrl == baseUrl) {
      return;
    }

    try {
      _client = QbittorrentApiClient(
        baseUrl: baseUrl,
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
      _serverName = serverName ?? _extractServerNameFromUrl(baseUrl);
      _baseUrl = baseUrl;

      // Get qBittorrent version after successful authentication
      try {
        _qbittorrentVersion = await _client!.getVersion();
      } catch (e) {
        _qbittorrentVersion = 'Unknown';
      }

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

  /// Save to legacy preferences for backward compatibility
  Future<void> _saveLegacyPreferences({
    required String baseUrl,
    required String username,
    required String password,
    String? serverName,
    Map<String, String>? customHeaders,
    bool allowNoAuth = false,
  }) async {
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

    // Save custom headers
    if (customHeaders != null && customHeaders.isNotEmpty) {
      final headersText = customHeaders.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      await Prefs.saveCustomHeadersText(headersText);
    } else {
      await Prefs.saveCustomHeadersText('');
    }

    // Save no-auth session flag
    await Prefs.saveNoAuthSession(
      allowNoAuth && (username.isEmpty || password.isEmpty),
    );
  }

  /// Extract a reasonable server name from URL
  String _extractServerNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;

      // If it's an IP address, use "Server at IP"
      if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
        return 'Server at $host';
      }

      // Otherwise use the hostname
      return host.isNotEmpty ? host : 'My Server';
    } catch (e) {
      return 'My Server';
    }
  }

  /// Auto-connect using saved preferences
  Future<void> tryAutoConnect() async {
    if (_attemptedAuto || _isAuthenticated) return;
    _attemptedAuto = true;
    _autoConnectFailed = false;

    // Step 1: Check if migration from legacy storage is needed
    if (!await ServerStorage.isMigrationCompleted()) {
      final migratedServer = await ServerStorage.migrateFromLegacyStorage();

      // If migration created a server, try to connect to it
      if (migratedServer != null) {
        try {
          await connectToServer(migratedServer);
          return;
        } catch (e) {
          // Migration succeeded but connection failed
          debugPrint('Auto-connect failed after migration: $e');
          _autoConnectFailed = true;
          return;
        }
      }
    }

    // Step 2: Try to connect using auto-connect server ID (new multi-server storage)
    final autoConnectServerId = await ServerStorage.getAutoConnectServerId();
    if (autoConnectServerId != null) {
      try {
        await connectToServerId(autoConnectServerId);
        return;
      } catch (e) {
        // Auto-connect failed
        debugPrint('Auto-connect to saved server failed: $e');
        _autoConnectFailed = true;
        return;
      }
    }

    // Step 3: Fall back to legacy storage for backward compatibility
    // This handles edge cases where migration completed but no auto-connect was set
    final baseUrl = await Prefs.loadBaseUrl();
    if (baseUrl == null) {
      return;
    }

    final username = await Prefs.loadUsername();
    final password = await Prefs.loadPassword();
    final serverName = await Prefs.loadServerName();
    final customHeadersText = await Prefs.loadCustomHeadersText();
    final isNoAuthSession = await Prefs.loadNoAuthSession();

    // Parse custom headers if available
    final customHeaders = _parseCustomHeaders(customHeadersText);

    // Check if we have a no-auth session saved
    if (isNoAuthSession) {
      try {
        await connect(
          baseUrl: baseUrl,
          username: username ?? '',
          password: password ?? '',
          serverName: serverName,
          customHeaders: customHeaders,
          allowNoAuth: true,
          saveAsNewServer: true, // Will save to new storage
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
          customHeaders: customHeaders,
          saveAsNewServer: true, // Will save to new storage
        );
      } catch (e) {
        // Legacy auto-connect failed
        debugPrint('Legacy auto-connect failed: $e');
        _autoConnectFailed = true;
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

  /// Parse custom headers from text format to Map
  /// Format: "Key: Value" per line
  Map<String, String>? _parseCustomHeaders(String? headersText) {
    if (headersText == null || headersText.isEmpty) return null;

    final Map<String, String> headers = {};
    final lines = headersText.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0 && colonIndex < trimmed.length - 1) {
        final key = trimmed.substring(0, colonIndex).trim();
        final value = trimmed.substring(colonIndex + 1).trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          headers[key] = value;
        }
      }
    }

    return headers.isEmpty ? null : headers;
  }

  @override
  void dispose() {
    _client = null;
    super.dispose();
  }
}
