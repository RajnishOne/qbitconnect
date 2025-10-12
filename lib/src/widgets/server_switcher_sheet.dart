import 'package:flutter/material.dart';
import '../models/server_config.dart';
import '../services/server_storage.dart';
import '../api/qbittorrent_api.dart';

/// Server switcher bottom sheet widget
class ServerSwitcherSheet extends StatefulWidget {
  final String? currentServerId;
  final Function(ServerConfig) onServerSelected;
  final VoidCallback onManageServers;

  const ServerSwitcherSheet({
    super.key,
    required this.currentServerId,
    required this.onServerSelected,
    required this.onManageServers,
  });

  @override
  State<ServerSwitcherSheet> createState() => _ServerSwitcherSheetState();
}

class _ServerSwitcherSheetState extends State<ServerSwitcherSheet> {
  List<ServerConfig> _servers = [];
  bool _isLoading = true;
  String? _checkingServerId; // Track which server is being tested
  Set<String> _failedServerIds =
      {}; // Track servers that failed connection test

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    try {
      final servers = await ServerStorage.loadServerConfigs();
      if (mounted) {
        setState(() {
          _servers = servers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Check if server is alive before switching
  Future<void> _handleServerSelection(ServerConfig server) async {
    // Set checking state
    setState(() {
      _checkingServerId = server.id;
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

      // If we reach here, server is alive - proceed with selection
      if (mounted) {
        setState(() {
          _checkingServerId = null;
        });
        widget.onServerSelected(server);
      }
    } catch (e) {
      // Server is not alive or connection failed
      if (mounted) {
        setState(() {
          _checkingServerId = null;
          _failedServerIds.add(server.id); // Mark server as failed
        });
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.dns, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Switch Server',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Server list
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_servers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No servers available',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _servers.length,
                itemBuilder: (context, index) {
                  final server = _servers[index];
                  final isActive = server.id == widget.currentServerId;

                  final isChecking = _checkingServerId == server.id;
                  final hasFailed = _failedServerIds.contains(server.id);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? Colors.green
                          : Colors.grey.shade400,
                      radius: 20,
                      child: isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isActive ? Icons.check : Icons.dns,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                    title: Text(
                      server.name,
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      isChecking ? 'Checking connection...' : server.baseUrl,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isActive
                        ? Chip(
                            label: const Text(
                              'Active',
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.2,
                            ),
                            side: BorderSide.none,
                          )
                        : hasFailed
                        ? const Icon(Icons.warning, color: Colors.red, size: 28)
                        : null,
                    onTap: isActive || isChecking
                        ? null
                        : () => _handleServerSelection(server),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // Manage servers button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onManageServers,
                icon: const Icon(Icons.settings),
                label: const Text('Manage Servers'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
