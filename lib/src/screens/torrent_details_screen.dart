import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state_manager.dart';
import '../models/torrent.dart';
import '../models/torrent_details.dart';
import '../utils/error_handler.dart';
import '../utils/byte_formatter.dart';
import '../utils/file_extension_cache.dart';
import '../widgets/reusable_widgets.dart';
import '../widgets/torrent_stats_tab.dart';
import '../constants/app_strings.dart';

class TorrentDetailsScreen extends StatefulWidget {
  final Torrent torrent;

  const TorrentDetailsScreen({super.key, required this.torrent});

  @override
  State<TorrentDetailsScreen> createState() => _TorrentDetailsScreenState();
}

class _TorrentDetailsScreenState extends State<TorrentDetailsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  TorrentDetails? _details;
  List<TorrentFile> _files = [];
  List<TorrentTracker> _trackers = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  AppState? _appState; // Store reference to AppState

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();

    // Start real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _appState = context.read<AppState>(); // Store reference here
      // Starting real-time updates for torrent: ${widget.torrent.hash}
      _appState!.startRealTimeUpdates(widget.torrent.hash, _onDataUpdate);
    });
  }

  @override
  void dispose() {
    // Stop real-time updates using stored reference
    // Disposing torrent details screen for torrent: ${widget.torrent.hash}
    if (_appState != null) {
      _appState!.stopRealTimeUpdates(widget.torrent.hash);
    }
    _tabController.dispose();
    super.dispose();
  }

  void _onDataUpdate(
    TorrentDetails details,
    List<TorrentFile> files,
    List<TorrentTracker> trackers,
  ) {
    if (mounted) {
      setState(() {
        _details = details;
        _files = files;
        _trackers = trackers;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Get AppState reference if not already stored
    _appState ??= context.read<AppState>();

    try {
      final results = await Future.wait([
        _appState!.getTorrentDetails(widget.torrent.hash),
        _appState!.getTorrentFiles(widget.torrent.hash),
        _appState!.getTorrentTrackers(widget.torrent.hash),
      ]);

      if (mounted) {
        setState(() {
          _details = results[0] as TorrentDetails?;
          _files = results[1] as List<TorrentFile>;
          _trackers = results[2] as List<TorrentTracker>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _loadData();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshInfoTab() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      _appState ??= context.read<AppState>();
      final details = await _appState!.getTorrentDetails(widget.torrent.hash);

      if (mounted) {
        setState(() {
          _details = details;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshFilesTab() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      _appState ??= context.read<AppState>();
      final files = await _appState!.getTorrentFiles(widget.torrent.hash);

      if (mounted) {
        setState(() {
          _files = files;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshTrackersTab() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      _appState ??= context.read<AppState>();
      final trackers = await _appState!.getTorrentTrackers(widget.torrent.hash);

      if (mounted) {
        setState(() {
          _trackers = trackers;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SafeArea(
      bottom: Platform.isAndroid,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.torrent.name,
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: _handleAction,
              itemBuilder: (context) => const [
                ReusableWidgets.pauseMenuItem,
                ReusableWidgets.resumeMenuItem,
                ReusableWidgets.recheckMenuItem,
                ReusableWidgets.renameMenuItem,
                ReusableWidgets.changeLocationMenuItem,
                ReusableWidgets.deleteMenuItem,
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Stats', icon: Icon(Icons.bar_chart)),
              ReusableWidgets.infoTab,
              ReusableWidgets.filesTab,
              ReusableWidgets.trackersTab,
            ],
          ),
        ),
        body: _isLoading
            ? ReusableWidgets.loadingIndicator
            : TabBarView(
                controller: _tabController,
                children: [
                  RepaintBoundary(
                    child: RefreshIndicator(
                      onRefresh: _refreshInfoTab,
                      child: TorrentStatsTab(
                        torrent: widget.torrent,
                        details: _details,
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: RefreshIndicator(
                      onRefresh: _refreshInfoTab,
                      child: _buildInfoTab(),
                    ),
                  ),
                  RepaintBoundary(
                    child: RefreshIndicator(
                      onRefresh: _refreshFilesTab,
                      child: _buildFilesTab(),
                    ),
                  ),
                  RepaintBoundary(
                    child: RefreshIndicator(
                      onRefresh: _refreshTrackersTab,
                      child: _buildTrackersTab(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoTab() {
    if (_details == null) {
      return const Center(child: Text(AppStrings.noDetailsAvailable));
    }

    final details = _details!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('General Information', [
          _buildInfoRow('Name', details.name),
          _buildInfoRow('State', details.state),
          _buildInfoRow(
            'Progress',
            details.progress.isNaN || details.progress.isInfinite
                ? '0%'
                : _formatProgress(details.progress),
          ),
          _buildInfoRow('Save Path', details.savePath),
          _buildInfoRow('Addition Date', _formatDate(details.additionDate)),
          _buildInfoRow(
            'Comment',
            details.comment.isNotEmpty ? details.comment : 'N/A',
          ),
          _buildInfoRow(
            'Created By',
            details.createdBy.isNotEmpty ? details.createdBy : 'N/A',
          ),
        ]),

        ReusableWidgets.mediumSpacing,

        _buildInfoCard('Transfer Information', [
          _buildInfoRow('Downloaded', details.formattedSize),
          _buildInfoRow('Uploaded', details.formattedUploaded),
          _buildInfoRow('Wasted', details.formattedWasted),
          _buildInfoRow('Download Speed', details.formattedDlSpeed),
          _buildInfoRow('Upload Speed', details.formattedUpSpeed),
          _buildInfoRow('Download Speed (Avg)', details.formattedDlSpeedAvg),
          _buildInfoRow('Upload Speed (Avg)', details.formattedUpSpeedAvg),
          _buildInfoRow('ETA', details.formattedEta),
          _buildInfoRow(
            'Share Ratio',
            details.shareRatio.isNaN || details.shareRatio.isInfinite
                ? '0.00'
                : details.shareRatio.toStringAsFixed(2),
          ),
        ]),

        ReusableWidgets.mediumSpacing,

        _buildInfoCard('Connection Information', [
          _buildInfoRow('Seeds', '${details.seeds}'),
          _buildInfoRow('Leeches', '${details.leeches}'),
          _buildInfoRow(
            'Connections',
            '${details.nbConnections}/${details.nbConnectionsLimit}',
          ),
          _buildInfoRow('Time Elapsed', details.formattedTimeElapsed),
          _buildInfoRow('Seeding Time', details.formattedSeedingTime),
        ]),

        ReusableWidgets.mediumSpacing,

        _buildInfoCard('Technical Information', [
          _buildInfoRow('Pieces', '${details.piecesHave}/${details.piecesNum}'),
          _buildInfoRow('Piece Size', details.formattedPieceSize),
          _buildInfoRow(
            'Download Limit',
            details.dlLimit > 0 ? '${details.dlLimit} B/s' : 'Unlimited',
          ),
          _buildInfoRow(
            'Upload Limit',
            details.upLimit > 0 ? '${details.upLimit} B/s' : 'Unlimited',
          ),
          _buildInfoRow('Private', details.isPrivate ? 'Yes' : 'No'),
          _buildInfoRow(
            'Sequential Download',
            details.sequentialDownload ? 'Yes' : 'No',
          ),
          _buildInfoRow('Force Start', details.forceStart ? 'Yes' : 'No'),
          _buildInfoRow('Auto TMM', details.autoTmm ? 'Yes' : 'No'),
        ]),
      ],
    );
  }

  Widget _buildFilesTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Files (${_files.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                'Total: ${ByteFormatter.formatBytes(_files.fold<int>(0, (sum, file) => sum + file.size))}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        ...List.generate(_files.length, (index) {
          final file = _files[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(
                FileExtensionCache.getFileIcon(file.name),
                color: FileExtensionCache.getFileColor(file.name),
              ),
              title: Text(
                file.name.split('/').last,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: file.progress,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(file.formattedProgress),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    file.formattedSize,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    file.priorityText,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              onTap: () => _showFilePriorityDialog(file),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrackersTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Trackers (${_trackers.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        ...List.generate(_trackers.length, (index) {
          final tracker = _trackers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: tracker.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                tracker.url,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${AppStrings.status}: ${tracker.statusText}'),
                  if (tracker.msg.isNotEmpty)
                    Text('${AppStrings.message}: ${tracker.msg}'),
                  Text('${AppStrings.tier}: ${tracker.tier}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${tracker.numPeers} ${AppStrings.peers}'),
                  Text('${tracker.numSeeds} ${AppStrings.seeds}'),
                  Text('${tracker.numLeeches} ${AppStrings.leeches}'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatProgress(double progress) {
    final percentage = progress * 100;
    final formatted = percentage.toStringAsFixed(1);

    // If the decimal part is 0, remove the decimal point and zero
    if (formatted.endsWith('.0')) {
      return '${formatted.substring(0, formatted.length - 2)}%';
    }

    return '$formatted%';
  }

  String _formatDate(DateTime date) {
    // Check if this is a Unix epoch date (January 1, 1970)
    if (date.year == 1970 && date.month == 1 && date.day == 1) {
      return 'Unknown';
    }

    // Check if the date is too far in the past (before 1980)
    if (date.year < 1980) {
      return 'Unknown';
    }

    // Check if the date is in the future (more than 1 year from now)
    final now = DateTime.now();
    if (date.isAfter(now.add(const Duration(days: 365)))) {
      return 'Unknown';
    }

    // Format the date properly
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  void _showFilePriorityDialog(TorrentFile file) {
    Widget buildCustomRadio(
      BuildContext context,
      int value,
      int? selectedValue,
    ) {
      final isSelected = selectedValue == value;
      return GestureDetector(
        onTap: () => _setFilePriority(file, value),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: 2,
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 12,
                  color: Theme.of(context).colorScheme.onPrimary,
                )
              : null,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppStrings.setPriority} ${file.name.split('/').last}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(AppStrings.doNotDownload),
              leading: buildCustomRadio(context, 0, file.priority),
            ),
            ListTile(
              title: const Text(AppStrings.normal),
              leading: buildCustomRadio(context, 1, file.priority),
            ),
            ListTile(
              title: const Text(AppStrings.high),
              leading: buildCustomRadio(context, 6, file.priority),
            ),
            ListTile(
              title: const Text(AppStrings.maximum),
              leading: buildCustomRadio(context, 7, file.priority),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _setFilePriority(TorrentFile file, int priority) {
    // Get AppState reference if not already stored
    _appState ??= context.read<AppState>();
    _appState!.setFilePriority(widget.torrent.hash, [file.name], priority);
    Navigator.of(context).pop();
    _refreshData();
  }

  void _handleAction(String action) async {
    // Get AppState reference if not already stored
    _appState ??= context.read<AppState>();

    // Store context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      switch (action) {
        case 'pause':
          await _appState!.pauseTorrents([widget.torrent.hash]);
          break;
        case 'resume':
          await _appState!.resumeTorrents([widget.torrent.hash]);
          break;
        case 'recheck':
          await _appState!.recheckTorrent(widget.torrent.hash);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text(AppStrings.torrentRecheckStarted),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case 'rename':
          _showRenameDialog();
          break;
        case 'location':
          _showLocationDialog();
          break;
        case 'delete':
          _showDeleteDialog();
          break;
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Action failed: ${ErrorHandler.getShortErrorMessage(e)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: widget.torrent.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.renameTorrent),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: AppStrings.name,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final appState = context.read<AppState>();
                await appState.setTorrentName(
                  widget.torrent.hash,
                  controller.text,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Torrent renamed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to rename: ${ErrorHandler.getShortErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog() async {
    final controller = TextEditingController(text: _details?.savePath ?? '');
    final appState = context.read<AppState>();

    // Fetch all available directories
    final List<String> availableDirectories = await appState
        .getAllDirectories();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Save Location'),
        content: SizedBox(
          width: double.maxFinite,
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: _details?.savePath ?? ''),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return availableDirectories;
              }
              return availableDirectories.where((String option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              controller.text = selection;
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  // Sync the autocomplete controller with our main controller
                  textEditingController.text = controller.text;
                  textEditingController.addListener(() {
                    controller.text = textEditingController.text;
                  });

                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'New Location',
                      border: OutlineInputBorder(),
                      hintText: 'Type or select a directory',
                    ),
                    onSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                  );
                },
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                          maxWidth: 400,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final appState = context.read<AppState>();
                await appState.setTorrentLocation(
                  widget.torrent.hash,
                  controller.text,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Torrent location changed successfully',
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
                        'Failed to change location: ${ErrorHandler.getShortErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Torrent'),
        content: const Text('Choose what to delete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Get AppState reference if not already stored
                _appState ??= context.read<AppState>();
                await _appState!.deleteTorrents([
                  widget.torrent.hash,
                ], deleteFiles: false);
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close details screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Torrent deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete torrent: ${ErrorHandler.getShortErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Torrent only'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Get AppState reference if not already stored
                _appState ??= context.read<AppState>();
                await _appState!.deleteTorrents([
                  widget.torrent.hash,
                ], deleteFiles: true);
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close details screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Torrent and files deleted successfully',
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
                        'Failed to delete torrent: ${ErrorHandler.getShortErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Torrent + files'),
          ),
        ],
      ),
    );
  }
}
