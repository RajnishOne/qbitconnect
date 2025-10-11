import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/server_config.dart';
import 'prefs.dart';

/// Service for managing multiple server configurations
class ServerStorage {
  static const String _keyServers = 'servers_v2';
  static const String _keyActiveServerId = 'active_server_id';
  static const String _keyAutoConnectServerId = 'auto_connect_server_id';
  static const String _keyMigrationCompleted = 'server_migration_completed';
  static const String _keyPasswordPrefix = 'server_password_';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  /// Check if migration from single-server to multi-server has been completed
  static Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMigrationCompleted) ?? false;
  }

  /// Mark migration as completed
  static Future<void> markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMigrationCompleted, true);
  }

  /// Migrate from old single-server storage to new multi-server storage
  static Future<ServerConfig?> migrateFromLegacyStorage() async {
    // Check if already migrated
    if (await isMigrationCompleted()) {
      return null;
    }

    // Load legacy server configuration
    final baseUrl = await Prefs.loadBaseUrl();

    // If no legacy config exists, mark migration as complete and return null
    if (baseUrl == null) {
      await markMigrationCompleted();
      return null;
    }

    // Load all legacy data
    final username = await Prefs.loadUsername();
    final password = await Prefs.loadPassword();
    final serverName = await Prefs.loadServerName();
    final customHeadersText = await Prefs.loadCustomHeadersText();
    final noAuthSession = await Prefs.loadNoAuthSession();

    // Generate a unique ID for the migrated server
    final serverId = _generateServerId();

    // Create server config from legacy data
    final serverConfig = ServerConfig(
      id: serverId,
      name: serverName ?? _extractServerNameFromUrl(baseUrl),
      baseUrl: baseUrl,
      username: username ?? '',
      noAuthSession: noAuthSession,
      customHeadersText: customHeadersText,
      createdAt: DateTime.now(),
      lastConnectedAt: DateTime.now(), // Assume it was last connected
    );

    // Save password to new storage location
    if (password != null && password.isNotEmpty) {
      await saveServerPassword(serverId, password);
    }

    // Save the migrated server
    await saveServerConfigs([serverConfig]);

    // Set as active and auto-connect server
    await setActiveServerId(serverId);
    await setAutoConnectServerId(serverId);

    // Mark migration as completed
    await markMigrationCompleted();

    return serverConfig;
  }

  /// Extract a reasonable server name from URL
  static String _extractServerNameFromUrl(String url) {
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

  /// Generate a unique server ID
  static String _generateServerId() {
    return 'server_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Save list of server configurations
  static Future<void> saveServerConfigs(List<ServerConfig> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = servers.map((s) => s.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_keyServers, jsonString);
  }

  /// Load all server configurations
  static Future<List<ServerConfig>> loadServerConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyServers);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ServerConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If decoding fails, return empty list
      return [];
    }
  }

  /// Add a new server configuration
  static Future<void> addServerConfig(ServerConfig server) async {
    final servers = await loadServerConfigs();
    servers.add(server);
    await saveServerConfigs(servers);
  }

  /// Update an existing server configuration
  static Future<void> updateServerConfig(ServerConfig server) async {
    final servers = await loadServerConfigs();
    final index = servers.indexWhere((s) => s.id == server.id);

    if (index != -1) {
      servers[index] = server;
      await saveServerConfigs(servers);
    }
  }

  /// Delete a server configuration
  static Future<void> deleteServerConfig(String serverId) async {
    final servers = await loadServerConfigs();
    servers.removeWhere((s) => s.id == serverId);
    await saveServerConfigs(servers);

    // Also delete the password
    await deleteServerPassword(serverId);

    // Clear active/auto-connect if this was the active server
    final activeId = await getActiveServerId();
    if (activeId == serverId) {
      await setActiveServerId(null);
    }

    final autoConnectId = await getAutoConnectServerId();
    if (autoConnectId == serverId) {
      await setAutoConnectServerId(null);
    }
  }

  /// Get a server configuration by ID
  static Future<ServerConfig?> getServerConfig(String serverId) async {
    final servers = await loadServerConfigs();
    try {
      return servers.firstWhere((s) => s.id == serverId);
    } catch (e) {
      return null;
    }
  }

  /// Save password for a specific server
  static Future<void> saveServerPassword(
    String serverId,
    String password,
  ) async {
    final key = _keyPasswordPrefix + serverId;
    await _secure.write(key: key, value: password);
  }

  /// Load password for a specific server
  static Future<String?> loadServerPassword(String serverId) async {
    final key = _keyPasswordPrefix + serverId;
    return await _secure.read(key: key);
  }

  /// Delete password for a specific server
  static Future<void> deleteServerPassword(String serverId) async {
    final key = _keyPasswordPrefix + serverId;
    await _secure.delete(key: key);
  }

  /// Set the currently active server ID
  static Future<void> setActiveServerId(String? serverId) async {
    final prefs = await SharedPreferences.getInstance();
    if (serverId == null) {
      await prefs.remove(_keyActiveServerId);
    } else {
      await prefs.setString(_keyActiveServerId, serverId);
    }
  }

  /// Get the currently active server ID
  static Future<String?> getActiveServerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveServerId);
  }

  /// Set the server ID to auto-connect to on app start
  static Future<void> setAutoConnectServerId(String? serverId) async {
    final prefs = await SharedPreferences.getInstance();
    if (serverId == null) {
      await prefs.remove(_keyAutoConnectServerId);
    } else {
      await prefs.setString(_keyAutoConnectServerId, serverId);
    }
  }

  /// Get the server ID to auto-connect to on app start
  static Future<String?> getAutoConnectServerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAutoConnectServerId);
  }

  /// Update last connected timestamp for a server
  static Future<void> updateLastConnected(String serverId) async {
    final server = await getServerConfig(serverId);
    if (server != null) {
      final updated = server.copyWith(lastConnectedAt: DateTime.now());
      await updateServerConfig(updated);
    }
  }

  /// Update qBittorrent version for a server
  static Future<void> updateServerVersion(
    String serverId,
    String version,
  ) async {
    final server = await getServerConfig(serverId);
    if (server != null) {
      final updated = server.copyWith(qbittorrentVersion: version);
      await updateServerConfig(updated);
    }
  }

  /// Create a new server configuration
  static ServerConfig createNewServer({
    required String name,
    required String baseUrl,
    required String username,
    String? password,
    String? customHeadersText,
    bool noAuthSession = false,
  }) {
    return ServerConfig(
      id: _generateServerId(),
      name: name,
      baseUrl: baseUrl,
      username: username,
      noAuthSession: noAuthSession,
      customHeadersText: customHeadersText,
      createdAt: DateTime.now(),
    );
  }
}
