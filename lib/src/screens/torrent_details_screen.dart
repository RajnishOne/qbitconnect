import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../state/app_state_manager.dart';
import '../models/torrent.dart';
import '../models/torrent_details.dart';
import '../models/torrent_peer.dart';
import '../utils/error_handler.dart';
import '../utils/byte_formatter.dart';
import '../utils/file_extension_cache.dart';
import '../widgets/reusable_widgets.dart';
import '../widgets/torrent_stats_tab.dart';

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
  List<TorrentPeer> _peers = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  AppState? _appState; // Store reference to AppState

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        _appState!.getTorrentPeers(widget.torrent.hash),
      ]);

      if (mounted) {
        setState(() {
          _details = results[0] as TorrentDetails?;
          _files = results[1] as List<TorrentFile>;
          _trackers = results[2] as List<TorrentTracker>;
          _peers = results[3] as List<TorrentPeer>;
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

  Future<void> _refreshPeersTab() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      _appState ??= context.read<AppState>();
      final peers = await _appState!.getTorrentPeers(widget.torrent.hash);

      if (mounted) {
        setState(() {
          _peers = peers;
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
              itemBuilder: (context) => [
                ReusableWidgets.pauseMenuItem,
                ReusableWidgets.resumeMenuItem,
                ReusableWidgets.recheckMenuItem,
                ReusableWidgets.renameMenuItem,
                ReusableWidgets.changeLocationMenuItem,
                ReusableWidgets.deleteMenuItem,
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 0,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                indicatorPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                tabs: [
                  Tab(
                    height: 56,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.analytics_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.stats.tr()),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 56,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.info.tr()),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 56,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.files.tr()),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 56,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radar_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.trackers.tr()),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 56,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.peers.tr()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  RepaintBoundary(
                    child: RefreshIndicator(
                      onRefresh: _refreshPeersTab,
                      child: _buildPeersTab(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoTab() {
    if (_details == null) {
      return Center(child: Text(LocaleKeys.noDetailsAvailable.tr()));
    }

    final details = _details!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(LocaleKeys.generalInformation.tr(), [
          _buildInfoRow(LocaleKeys.name.tr(), details.name),
          _buildInfoRow(LocaleKeys.state.tr(), details.state),
          _buildInfoRow(
            LocaleKeys.progress.tr(),
            details.progress.isNaN || details.progress.isInfinite
                ? '0%'
                : _formatProgress(details.progress),
          ),
          _buildInfoRow(LocaleKeys.savePath.tr(), details.savePath),
          _buildInfoRow(
            LocaleKeys.additionDate.tr(),
            _formatDate(details.additionDate),
          ),
          _buildInfoRow(
            LocaleKeys.comment.tr(),
            details.comment.isNotEmpty ? details.comment : 'N/A',
          ),
          _buildInfoRow(
            LocaleKeys.createdBy.tr(),
            details.createdBy.isNotEmpty ? details.createdBy : 'N/A',
          ),
        ]),

        ReusableWidgets.mediumSpacing,

        _buildInfoCard(LocaleKeys.transferInformation.tr(), [
          _buildInfoRow(LocaleKeys.downloaded.tr(), details.formattedSize),
          _buildInfoRow(LocaleKeys.uploaded.tr(), details.formattedUploaded),
          _buildInfoRow(LocaleKeys.wasted.tr(), details.formattedWasted),
          _buildInfoRow(
            LocaleKeys.downloadSpeed.tr(),
            details.formattedDlSpeed,
          ),
          _buildInfoRow(LocaleKeys.uploadSpeed.tr(), details.formattedUpSpeed),
          _buildInfoRow(
            LocaleKeys.downloadSpeedAvg.tr(),
            details.formattedDlSpeedAvg,
          ),
          _buildInfoRow(
            LocaleKeys.uploadSpeedAvg.tr(),
            details.formattedUpSpeedAvg,
          ),
          _buildInfoRow(LocaleKeys.eta.tr(), details.formattedEta),
          _buildInfoRow(
            LocaleKeys.shareRatio.tr(),
            details.shareRatio.isNaN || details.shareRatio.isInfinite
                ? '0.00'
                : details.shareRatio.toStringAsFixed(2),
          ),
        ]),

        ReusableWidgets.mediumSpacing,

        _buildInfoCard(LocaleKeys.connectionInformation.tr(), [
          _buildInfoRow(LocaleKeys.seeds.tr(), '${details.seeds}'),
          _buildInfoRow(LocaleKeys.leeches.tr(), '${details.leeches}'),
          _buildInfoRow(
            LocaleKeys.connections.tr(),
            '${details.nbConnections}/${details.nbConnectionsLimit}',
          ),
          _buildInfoRow(
            LocaleKeys.timeElapsed.tr(),
            details.formattedTimeElapsed,
          ),
          _buildInfoRow(
            LocaleKeys.seedingTime.tr(),
            details.formattedSeedingTime,
          ),
        ]),

        ReusableWidgets.mediumSpacing,

        _buildInfoCard(LocaleKeys.technicalInformation.tr(), [
          _buildInfoRow(
            LocaleKeys.pieces.tr(),
            '${details.piecesHave}/${details.piecesNum}',
          ),
          _buildInfoRow(LocaleKeys.pieceSize.tr(), details.formattedPieceSize),
          _buildInfoRow(
            LocaleKeys.downloadLimit.tr(),
            details.dlLimit > 0
                ? '${details.dlLimit} B/s'
                : LocaleKeys.unlimited.tr(),
          ),
          _buildInfoRow(
            LocaleKeys.uploadLimit.tr(),
            details.upLimit > 0
                ? '${details.upLimit} B/s'
                : LocaleKeys.unlimited.tr(),
          ),
          _buildInfoRow(
            LocaleKeys.private.tr(),
            details.isPrivate ? LocaleKeys.yes.tr() : LocaleKeys.no.tr(),
          ),
          _buildInfoRow(
            LocaleKeys.sequentialDownload.tr(),
            details.sequentialDownload
                ? LocaleKeys.yes.tr()
                : LocaleKeys.no.tr(),
          ),
          _buildInfoRow(
            LocaleKeys.forceStart.tr(),
            details.forceStart ? LocaleKeys.yes.tr() : LocaleKeys.no.tr(),
          ),
          _buildInfoRow(
            LocaleKeys.autoTmm.tr(),
            details.autoTmm ? LocaleKeys.yes.tr() : LocaleKeys.no.tr(),
          ),
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
                '${LocaleKeys.files.tr()} (${_files.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${LocaleKeys.total.tr()}: ${ByteFormatter.formatBytes(_files.fold<int>(0, (sum, file) => sum + file.size))}',
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
                '${LocaleKeys.trackers.tr()} (${_trackers.length})',
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
                  Text('${LocaleKeys.status.tr()}: ${tracker.statusText}'),
                  if (tracker.msg.isNotEmpty)
                    Text('${LocaleKeys.message.tr()}: ${tracker.msg}'),
                  Text('${LocaleKeys.tier.tr()}: ${tracker.tier}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${tracker.numPeers} ${LocaleKeys.peers.tr()}'),
                  Text('${tracker.numSeeds} ${LocaleKeys.seeders.tr()}'),
                  Text('${tracker.numLeeches} ${LocaleKeys.leechers.tr()}'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPeersTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${LocaleKeys.peers.tr()} (${_peers.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        if (_peers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                LocaleKeys.noDataAvailable.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ...List.generate(_peers.length, (index) {
            final peer = _peers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: peer.connectionColor,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  peer.ip,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${LocaleKeys.client.tr()}: ${peer.clientName}'),
                    Text('${LocaleKeys.port.tr()}: ${peer.port}'),
                    Text(
                      '${LocaleKeys.progress.tr()}: ${peer.formattedProgress}',
                    ),
                    if (peer.isSeed)
                      Text(
                        LocaleKeys.seeders.tr(),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      peer.formattedDlSpeed,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      peer.formattedUpSpeed,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      peer.connectionType,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
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
      return LocaleKeys.unknown.tr();
    }

    // Check if the date is too far in the past (before 1980)
    if (date.year < 1980) {
      return LocaleKeys.unknown.tr();
    }

    // Check if the date is in the future (more than 1 year from now)
    final now = DateTime.now();
    if (date.isAfter(now.add(const Duration(days: 365)))) {
      return LocaleKeys.unknown.tr();
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
        title: Text(
          '${LocaleKeys.setPriority.tr()} ${file.name.split('/').last}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(LocaleKeys.doNotDownload.tr()),
              leading: buildCustomRadio(context, 0, file.priority),
            ),
            ListTile(
              title: Text(LocaleKeys.normal.tr()),
              leading: buildCustomRadio(context, 1, file.priority),
            ),
            ListTile(
              title: Text(LocaleKeys.high.tr()),
              leading: buildCustomRadio(context, 6, file.priority),
            ),
            ListTile(
              title: Text(LocaleKeys.maximum.tr()),
              leading: buildCustomRadio(context, 7, file.priority),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.cancel.tr()),
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
              content: Text(LocaleKeys.torrentRecheckStarted.tr()),
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
            '${LocaleKeys.actionFailed.tr()}: ${ErrorHandler.getShortErrorMessage(e)}',
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
        title: Text(LocaleKeys.renameTorrent.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: LocaleKeys.name.tr(),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.cancel.tr()),
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
                      content: Text(LocaleKeys.torrentRenamedSuccessfully.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${LocaleKeys.failedToRename.tr()}: ${ErrorHandler.getShortErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(LocaleKeys.rename.tr()),
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
        title: Text(LocaleKeys.changeSaveLocation.tr()),
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
                    decoration: InputDecoration(
                      labelText: LocaleKeys.newLocation.tr(),
                      border: OutlineInputBorder(),
                      hintText: LocaleKeys.typeOrSelectDirectory.tr(),
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
            child: Text(LocaleKeys.cancel.tr()),
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
                      content: Text(
                        LocaleKeys.torrentLocationChangedSuccessfully.tr(),
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
                        '${LocaleKeys.failedToChangeLocation.tr()}: ${ErrorHandler.getShortErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(LocaleKeys.change.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.deleteTorrent.tr()),
        content: Text(LocaleKeys.chooseWhatToDelete.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.cancel.tr()),
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
                      content: Text(LocaleKeys.torrentDeletedSuccessfully.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${LocaleKeys.failedToDeleteTorrent.tr()}: ${ErrorHandler.getShortErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(LocaleKeys.torrentOnly.tr()),
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
                      content: Text(
                        LocaleKeys.torrentAndFilesDeletedSuccessfully.tr(),
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
                        '${LocaleKeys.failedToDeleteTorrent.tr()}: ${ErrorHandler.getShortErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: Text(LocaleKeys.torrentAndFiles.tr()),
          ),
        ],
      ),
    );
  }
}
