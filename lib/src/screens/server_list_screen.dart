import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state_manager.dart';
import '../services/server_storage.dart';
import '../services/prefs.dart';
import '../services/firebase_service.dart';
import '../models/server_config.dart';
import '../utils/format_utils.dart';
import '../utils/error_handler.dart';
import '../widgets/auto_connect_replacement_sheet.dart';
import '../api/qbittorrent_api.dart';
import 'connection_screen.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  List<ServerConfig> _servers = [];
  String? _activeServerId;
  bool _isLoading = true;
  String? _checkingServerId; // Track which server is being tested
  Set<String> _failedServerIds =
      {}; // Track servers that failed connection test

  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'server_list_screen',
      screenClass: 'ServerListScreen',
    );
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() => _isLoading = true);

    try {
      final servers = await ServerStorage.loadServerConfigs();
      final activeId = await ServerStorage.getActiveServerId();

      if (mounted) {
        setState(() {
          _servers = servers;
          _activeServerId = activeId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load servers. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check if server is alive before connecting
  Future<void> _connectToServer(ServerConfig server) async {
    // Set checking state
    setState(() {
      _checkingServerId = server.id;
      _failedServerIds.remove(server.id); // Clear previous failure state
    });

    try {
      // Load password from secure storage
      final password = await ServerStorage.loadServerPassword(server.id);

      // Parse custom headers
      final customHeaders = server.parseCustomHeaders();

      // Create a temporary API client to test the connection
      final tempApiClient = QbittorrentApiClient(
        baseUrl: server.baseUrl,
        defaultHeaders: customHeaders,
        enableLogging: false,
      );

      // Test connection with timeout
      await Future.any([
        _testServerConnection(tempApiClient, server, password ?? ''),
        Future.delayed(const Duration(seconds: 5), () {
          throw Exception('Connection timeout - server did not respond');
        }),
      ]);

      // Server is alive - proceed with connection
      if (!mounted) return;

      // Clear checking state
      setState(() {
        _checkingServerId = null;
      });

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final appState = context.read<AppState>();

      // Connect to selected server
      await appState.connectToServer(server);

      // Fetch initial data from the server
      await appState.refreshNow();

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${server.name}'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the list to update active indicator
        await _loadServers();
      }
    } catch (e) {
      // Server is not alive or connection failed
      if (mounted) {
        setState(() {
          _checkingServerId = null;
          _failedServerIds.add(server.id); // Mark server as failed
        });

        // Show user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot connect to ${server.name}. ${ErrorHandler.getUserFriendlyMessage(e)}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        // Refresh list to show warning icon
        await _loadServers();
      }
    }
  }

  /// Test server connection
  Future<void> _testServerConnection(
    QbittorrentApiClient client,
    ServerConfig server,
    String password,
  ) async {
    if (server.username.isNotEmpty && password.isNotEmpty) {
      // Test login with credentials
      await client.login(username: server.username, password: password);
    } else if (server.noAuthSession) {
      // Try to connect without authentication
      await client.loginWithoutAuth();
    } else {
      throw Exception('No credentials available for server');
    }
  }

  Future<void> _deleteServer(ServerConfig server) async {
    // Check if this is the auto-connect server
    final autoConnectId = await ServerStorage.getAutoConnectServerId();
    final isAutoConnect = autoConnectId == server.id;

    if (isAutoConnect) {
      // For auto-connect servers, show replacement selection first
      await _showAutoConnectReplacementSheet(server);
    } else {
      // For non-auto-connect servers, show simple confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Server'),
          content: Text(
            'Are you sure you want to delete "${server.name}"?\n\n'
            'This will remove the server configuration and saved password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _performDelete(server, null);
      }
    }
  }

  Future<void> _showAutoConnectReplacementSheet(
    ServerConfig serverToDelete,
  ) async {
    final remainingServers = _servers
        .where((s) => s.id != serverToDelete.id)
        .toList();

    if (remainingServers.isEmpty) {
      // No servers remaining, just confirm deletion
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Last Server'),
          content: Text(
            'Are you sure you want to delete "${serverToDelete.name}"?\n\n'
            'This is your last server. You will need to add a new server to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _performDelete(serverToDelete, null);
      }
      return;
    }

    // Show bottom sheet to select replacement
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (context) => AutoConnectReplacementSheet(
        serverToDelete: serverToDelete,
        availableServers: remainingServers,
        onDelete: (replacement) async {
          await _performDelete(serverToDelete, replacement);
        },
      ),
    );
  }

  Future<void> _performDelete(
    ServerConfig server,
    ServerConfig? replacement,
  ) async {
    try {
      // Delete the server
      await ServerStorage.deleteServerConfig(server.id);

      // Set replacement as auto-connect if provided
      if (replacement != null) {
        await ServerStorage.setAutoConnectServerId(replacement.id);
        await _updateLegacyStorage(replacement);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${server.name} deleted. ${replacement.name} set as auto-connect',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${server.name} deleted')));
        }
      }

      // Reload servers
      if (mounted) {
        await _loadServers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete server. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLegacyStorage(ServerConfig server) async {
    // Update legacy storage for backward compatibility
    final password = await ServerStorage.loadServerPassword(server.id);

    await Prefs.saveBaseUrl(server.baseUrl);
    await Prefs.saveUsername(server.username);
    await Prefs.saveServerName(server.name);
    await Prefs.saveNoAuthSession(server.noAuthSession);

    if (server.customHeadersText != null) {
      await Prefs.saveCustomHeadersText(server.customHeadersText!);
    } else {
      await Prefs.saveCustomHeadersText('');
    }

    if (password != null && password.isNotEmpty) {
      await Prefs.savePassword(password);
    }
  }

  Future<void> _setAutoConnect(ServerConfig server) async {
    try {
      await ServerStorage.setAutoConnectServerId(server.id);

      // Update legacy storage for backward compatibility
      await _updateLegacyStorage(server);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${server.name} set as default auto-connect server'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to set auto-connect. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showServerOptions(ServerConfig server) {
    final isActive = server.id == _activeServerId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Connect'),
              onTap: () {
                Navigator.pop(context);
                _connectToServer(server);
              },
            ),
            ListTile(
              leading: const Icon(Icons.autorenew),
              title: const Text('Set as Auto-Connect'),
              onTap: () {
                Navigator.pop(context);
                _setAutoConnect(server);
              },
            ),
            if (isActive)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.grey.shade400),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                subtitle: const Text(
                  'Disconnect first to delete',
                  style: TextStyle(fontSize: 12),
                ),
                enabled: false,
              )
            else
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteServer(server);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(ServerConfig server) {
    final isActive = server.id == _activeServerId;
    final isChecking = _checkingServerId == server.id;
    final hasFailed = _failedServerIds.contains(server.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: isChecking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(isActive ? Icons.check : Icons.dns, color: Colors.white),
        ),
        title: Text(
          server.name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isChecking ? 'Checking connection...' : server.baseUrl,
              style: const TextStyle(fontSize: 12),
            ),
            if (!isChecking && server.lastConnectedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last connected: ${FormatUtils.formatDate(server.lastConnectedAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            if (!isChecking && server.qbittorrentVersion != null) ...[
              const SizedBox(height: 4),
              Text(
                'qBittorrent ${server.qbittorrentVersion}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
        trailing: isActive
            ? Chip(
                label: const Text('Active', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.green.withValues(alpha: 0.2),
                side: BorderSide.none,
              )
            : hasFailed
            ? const Icon(Icons.warning, color: Colors.red, size: 28)
            : const Icon(Icons.chevron_right),
        onTap: isChecking ? null : () => _connectToServer(server),
        onLongPress: isChecking ? null : () => _showServerOptions(server),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid,
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Servers')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConnectionScreen()),
            ).then((_) => _loadServers()); // Reload servers after returning
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Server'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _servers.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Servers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Add Server" below to connect to your first qBittorrent server.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadServers,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Info card
                    Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tap to connect. Long press for options.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Servers list
                    ..._servers.map(_buildServerCard),
                  ],
                ),
              ),
      ),
    );
  }
}
