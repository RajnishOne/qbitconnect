import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/server_config.dart';
import '../constants/locale_keys.dart';

/// Bottom sheet for selecting replacement auto-connect server before deletion
class AutoConnectReplacementSheet extends StatefulWidget {
  final ServerConfig serverToDelete;
  final List<ServerConfig> availableServers;
  final Function(ServerConfig) onDelete;

  const AutoConnectReplacementSheet({
    super.key,
    required this.serverToDelete,
    required this.availableServers,
    required this.onDelete,
  });

  @override
  State<AutoConnectReplacementSheet> createState() =>
      _AutoConnectReplacementSheetState();
}

class _AutoConnectReplacementSheetState
    extends State<AutoConnectReplacementSheet> {
  ServerConfig? _selectedReplacement;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Auto-select if only one server available
    if (widget.availableServers.length == 1) {
      _selectedReplacement = widget.availableServers[0];
    }
  }

  Future<void> _handleDelete() async {
    if (_selectedReplacement == null) return;

    setState(() => _isDeleting = true);

    try {
      await widget.onDelete(_selectedReplacement!);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    LocaleKeys.selectReplacementServer.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Explanation
            Text(
              '"${widget.serverToDelete.name}" ${LocaleKeys.serverSetAsAutoConnect.tr()}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),

            // Server list
            if (widget.availableServers.length == 1)
              // Only one server - auto-select it
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.dns, color: Colors.white),
                ),
                title: Text(
                  widget.availableServers[0].name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  widget.availableServers[0].baseUrl,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.check, color: Colors.green),
                tileColor: Colors.green.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () {
                  setState(() {
                    _selectedReplacement = widget.availableServers[0];
                  });
                },
              )
            else
              // Multiple servers - show radio list
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableServers.length,
                  itemBuilder: (context, index) {
                    final server = widget.availableServers[index];
                    final isSelected = _selectedReplacement?.id == server.id;

                    return RadioListTile<ServerConfig>(
                      value: server,
                      groupValue: _selectedReplacement,
                      onChanged: (value) {
                        setState(() {
                          _selectedReplacement = value;
                        });
                      },
                      title: Text(server.name),
                      subtitle: Text(
                        server.baseUrl,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.pop(context),
                    child: Text(LocaleKeys.skip.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeleting
                        ? null
                        : (_selectedReplacement != null ||
                              widget.availableServers.length == 1)
                        ? _handleDelete
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(LocaleKeys.delete.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
