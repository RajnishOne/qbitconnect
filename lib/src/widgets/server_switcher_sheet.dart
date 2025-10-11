import 'package:flutter/material.dart';
import '../models/server_config.dart';
import '../services/server_storage.dart';

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

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? Colors.green
                          : Colors.grey.shade400,
                      radius: 20,
                      child: Icon(
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
                      server.baseUrl,
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
                        : null,
                    onTap: isActive
                        ? null
                        : () => widget.onServerSelected(server),
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
