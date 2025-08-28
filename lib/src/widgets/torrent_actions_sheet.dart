import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/torrent.dart';
import '../state/app_state.dart';
import '../state/batch_selection_state.dart';
import '../services/firebase_service.dart';

// Delete dialog choices (must be top-level)
enum DeleteChoice { torrentOnly, withFiles }

class TorrentActionsSheet extends StatelessWidget {
  final Torrent torrent;

  const TorrentActionsSheet({super.key, required this.torrent});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isLoading = appState.isLoadingTorrent(torrent.hash);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              torrent.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                children: [
                  Consumer<BatchSelectionState>(
                    builder: (context, batchState, child) {
                      return ListTile(
                        leading: const Icon(Icons.check_box_outlined),
                        title: const Text('Select'),
                        onTap: () {
                          Navigator.pop(context);
                          batchState.enterSelectionMode();
                          batchState.toggleSelection(torrent.hash);
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.pause),
                    title: const Text('Pause'),
                    onTap: isLoading
                        ? null
                        : () async {
                            Navigator.pop(context);
                            context.read<AppState>().pauseTorrents([
                              torrent.hash,
                            ]);
                          },
                  ),
                  ListTile(
                    leading: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    title: const Text('Resume'),
                    onTap: isLoading
                        ? null
                        : () async {
                            Navigator.pop(context);
                            context.read<AppState>().resumeTorrents([
                              torrent.hash,
                            ]);
                          },
                  ),
                  ListTile(
                    leading: const Icon(Icons.keyboard_arrow_up),
                    title: const Text('Move Up'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await context.read<AppState>().increaseTorrentPriority([
                          torrent.hash,
                        ]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Torrent moved up in queue'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to move torrent: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.keyboard_arrow_down),
                    title: const Text('Move Down'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await context.read<AppState>().decreaseTorrentPriority([
                          torrent.hash,
                        ]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Torrent moved down in queue'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to move torrent: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.vertical_align_top),
                    title: const Text('Move to Top'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await context.read<AppState>().moveTorrentToTop([
                          torrent.hash,
                        ]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Torrent moved to top of queue'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to move torrent: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.vertical_align_bottom),
                    title: const Text('Move to Bottom'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await context.read<AppState>().moveTorrentToBottom([
                          torrent.hash,
                        ]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Torrent moved to bottom of queue'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to move torrent: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      _confirmDelete(context, torrent.hash);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String hash) async {
    // Store AppState reference before showing dialog
    final appState = context.read<AppState>();

    final choice = await showDialog<DeleteChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete torrent?'),
        content: const Text('Choose what to delete.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, DeleteChoice.torrentOnly);
            },
            child: const Text('Torrent only'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, DeleteChoice.withFiles);
            },
            child: const Text('Torrent + files'),
          ),
        ],
      ),
    );

    // Close the bottom sheet first
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (choice == null) {
      return; // Cancel pressed
    }

    final deleteFiles = choice == DeleteChoice.withFiles;

    try {
      await appState.deleteTorrents([hash], deleteFiles: deleteFiles);

      // Find a scaffold context to show the snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Torrent deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Find a scaffold context to show the error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete torrent: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
