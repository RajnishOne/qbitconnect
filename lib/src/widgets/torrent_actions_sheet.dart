import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../models/torrent.dart';
import '../state/app_state_manager.dart';
import '../state/batch_selection_state.dart';
import '../constants/locale_keys.dart';

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
                  ListTile(
                    leading: const Icon(Icons.check_box_outlined),
                    title: Text(LocaleKeys.select.tr()),
                    onTap: () {
                      Navigator.pop(context);
                      final batchState = context.read<BatchSelectionState>();
                      batchState.enterSelectionMode();
                      batchState.toggleSelection(torrent.hash);
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
                    title: Text(LocaleKeys.pause.tr()),
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
                    title: Text(LocaleKeys.resume.tr()),
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
                    title: Text(LocaleKeys.moveUp.tr()),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await context.read<AppState>().increaseTorrentPriority([
                          torrent.hash,
                        ]);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleKeys.torrentMovedUpInQueue.tr(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleKeys.failedToMoveTorrent.tr(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.keyboard_arrow_down),
                    title: Text(LocaleKeys.moveDown.tr()),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await context.read<AppState>().decreaseTorrentPriority([
                          torrent.hash,
                        ]);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleKeys.torrentMovedDownInQueue.tr(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleKeys.failedToMoveTorrent.tr(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.vertical_align_top),
                    title: Text(LocaleKeys.moveToTop.tr()),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await context.read<AppState>().moveTorrentToTop([
                          torrent.hash,
                        ]);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleKeys.torrentMovedToTopOfQueue.tr(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleKeys.failedToMoveTorrent.tr(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.vertical_align_bottom),
                    title: Text(LocaleKeys.moveToBottom.tr()),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await context.read<AppState>().moveTorrentToBottom([
                          torrent.hash,
                        ]);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleKeys.torrentMovedToBottomOfQueue.tr(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleKeys.failedToMoveTorrent.tr(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: Text(
                      LocaleKeys.delete.tr(),
                      style: const TextStyle(color: Colors.red),
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
        title: Text(LocaleKeys.deleteTorrent.tr()),
        content: Text(LocaleKeys.chooseWhatToDelete.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, DeleteChoice.torrentOnly);
            },
            child: Text(LocaleKeys.torrentOnly.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, DeleteChoice.withFiles);
            },
            child: Text(LocaleKeys.torrentAndFiles.tr()),
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
            content: Text(LocaleKeys.torrentDeletedSuccessfully.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Find a scaffold context to show the error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.failedToDeleteTorrent.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
