import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/torrent.dart';
import '../models/torrent_details.dart';
import '../utils/error_handler.dart';

class TorrentDetailsScreen extends StatefulWidget {
  final Torrent torrent;

  const TorrentDetailsScreen({super.key, required this.torrent});

  @override
  State<TorrentDetailsScreen> createState() => _TorrentDetailsScreenState();
}

class _TorrentDetailsScreenState extends State<TorrentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TorrentDetails? _details;
  List<TorrentFile> _files = [];
  List<TorrentTracker> _trackers = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  AppState? _appState; // Store reference to AppState

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();

    // Start real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _appState = context.read<AppState>(); // Store reference here
      print('Starting real-time updates for torrent: ${widget.torrent.hash}');
      _appState!.startRealTimeUpdates(widget.torrent.hash, _onDataUpdate);
    });
  }

  @override
  void dispose() {
    // Stop real-time updates using stored reference
    print(
      'Disposing torrent details screen for torrent: ${widget.torrent.hash}',
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load torrent details: ${ErrorHandler.getShortErrorMessage(e)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to refresh torrent details: ${ErrorHandler.getShortErrorMessage(e)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to refresh torrent files: ${ErrorHandler.getShortErrorMessage(e)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to refresh torrent trackers: ${ErrorHandler.getShortErrorMessage(e)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.torrent.name,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: _handleAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pause',
                  child: Row(
                    children: [
                      Icon(Icons.pause),
                      SizedBox(width: 8),
                      Text('Pause'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'resume',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('Resume'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'recheck',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text('Recheck'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'location',
                  child: Row(
                    children: [
                      Icon(Icons.folder),
                      SizedBox(width: 8),
                      Text('Change Location'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'move_up',
                  child: Row(
                    children: [
                      Icon(Icons.keyboard_arrow_up),
                      SizedBox(width: 8),
                      Text('Move Up'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'move_down',
                  child: Row(
                    children: [
                      Icon(Icons.keyboard_arrow_down),
                      SizedBox(width: 8),
                      Text('Move Down'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'move_top',
                  child: Row(
                    children: [
                      Icon(Icons.vertical_align_top),
                      SizedBox(width: 8),
                      Text('Move to Top'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'move_bottom',
                  child: Row(
                    children: [
                      Icon(Icons.vertical_align_bottom),
                      SizedBox(width: 8),
                      Text('Move to Bottom'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Info', icon: Icon(Icons.info)),
              Tab(text: 'Files', icon: Icon(Icons.folder)),
              Tab(text: 'Trackers', icon: Icon(Icons.link)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: _refreshInfoTab,
                    child: _buildInfoTab(),
                  ),
                  RefreshIndicator(
                    onRefresh: _refreshFilesTab,
                    child: _buildFilesTab(),
                  ),
                  RefreshIndicator(
                    onRefresh: _refreshTrackersTab,
                    child: _buildTrackersTab(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoTab() {
    if (_details == null) {
      return const Center(child: Text('No details available'));
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
                ? '0.0%'
                : '${(details.progress * 100).toStringAsFixed(1)}%',
          ),
          _buildInfoRow('Save Path', details.savePath),
          _buildInfoRow('Creation Date', _formatDate(details.creationDate)),
          _buildInfoRow(
            'Comment',
            details.comment.isNotEmpty ? details.comment : 'N/A',
          ),
          _buildInfoRow(
            'Created By',
            details.createdBy.isNotEmpty ? details.createdBy : 'N/A',
          ),
        ]),

        const SizedBox(height: 16),

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

        const SizedBox(height: 16),

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

        const SizedBox(height: 16),

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
                'Total: ${_formatBytes(_files.fold<int>(0, (sum, file) => sum + file.size))}',
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
                _getFileIcon(file.name),
                color: _getFileColor(file.name),
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
                  Text('Status: ${tracker.statusText}'),
                  if (tracker.msg.isNotEmpty) Text('Message: ${tracker.msg}'),
                  Text('Tier: ${tracker.tier}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${tracker.numPeers} peers'),
                  Text('${tracker.numSeeds} seeds'),
                  Text('${tracker.numLeeches} leeches'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 0) return '0 B'; // Handle negative values
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    if (i < 0 || i >= suffixes.length) return '$bytes B';
    final result = bytes / pow(1024, i);
    if (result.isNaN || result.isInfinite) return '0 B';
    return '${result.toStringAsFixed(2)} ${suffixes[i]}';
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Colors.red;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'pdf':
        return Colors.red;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _showFilePriorityDialog(TorrentFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Priority for ${file.name.split('/').last}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Do not download'),
              leading: Radio<int>(
                value: 0,
                groupValue: file.priority,
                onChanged: (value) => _setFilePriority(file, value!),
              ),
            ),
            ListTile(
              title: const Text('Normal'),
              leading: Radio<int>(
                value: 1,
                groupValue: file.priority,
                onChanged: (value) => _setFilePriority(file, value!),
              ),
            ),
            ListTile(
              title: const Text('High'),
              leading: Radio<int>(
                value: 6,
                groupValue: file.priority,
                onChanged: (value) => _setFilePriority(file, value!),
              ),
            ),
            ListTile(
              title: const Text('Maximum'),
              leading: Radio<int>(
                value: 7,
                groupValue: file.priority,
                onChanged: (value) => _setFilePriority(file, value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Torrent recheck started'),
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
        case 'move_up':
          await _appState!.increaseTorrentPriority([widget.torrent.hash]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Torrent moved up in queue'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case 'move_down':
          await _appState!.decreaseTorrentPriority([widget.torrent.hash]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Torrent moved down in queue'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case 'move_top':
          await _appState!.moveTorrentToTop([widget.torrent.hash]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Torrent moved to top of queue'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case 'move_bottom':
          await _appState!.moveTorrentToBottom([widget.torrent.hash]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Torrent moved to bottom of queue'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case 'delete':
          _showDeleteDialog();
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
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
        title: const Text('Rename Torrent'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Name',
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
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Torrent renamed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to rename: ${ErrorHandler.getShortErrorMessage(e)}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog() {
    final controller = TextEditingController(text: _details?.savePath ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Save Location'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Location',
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
                await appState.setTorrentLocation(
                  widget.torrent.hash,
                  controller.text,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Torrent location changed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to change location: ${ErrorHandler.getShortErrorMessage(e)}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
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
                    const SnackBar(
                      content: Text('Torrent deleted successfully'),
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
                    const SnackBar(
                      content: Text('Torrent and files deleted successfully'),
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
