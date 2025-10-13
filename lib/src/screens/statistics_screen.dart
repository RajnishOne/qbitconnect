import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../state/app_state_manager.dart';
import '../models/statistics.dart';
import '../models/sync_data.dart';
import '../utils/format_utils.dart';
import '../widgets/animated_reload_button.dart';
import '../constants/app_strings.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with AutomaticKeepAliveClientMixin {
  Statistics? _statistics;
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      if (appState.client != null) {
        // Get torrents data, server state, and transfer info to calculate comprehensive statistics
        final results = await Future.wait([
          appState.client!.torrents.fetchTorrents(),
          appState.client!.statistics.fetchMainData(),
          appState.client!.torrents.fetchTransferInfo(),
        ]);

        final torrents = results[0] as List;
        final syncData = results[1] as SyncData;
        final transferInfo = results[2];
        final torrentsData = torrents
            .cast<dynamic>()
            .map((t) => t.toMap() as Map<String, dynamic>)
            .toList();

        setState(() {
          _statistics = Statistics.fromTorrentsAndServerState(
            torrentsData,
            syncData.serverState,
            (transferInfo as dynamic).toMap(),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Not connected to qBittorrent';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load statistics: $e';
        _isLoading = false;
      });
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
          title: Text(LocaleKeys.analytics.tr()),
          actions: [
            AnimatedReloadButton(
              onPressed: _loadStatistics,
              tooltip: LocaleKeys.refreshTorrents.tr(),
              iconSize: 22,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: Text(LocaleKeys.retry.tr()),
            ),
          ],
        ),
      );
    }

    if (_statistics == null) {
      return Center(child: Text(LocaleKeys.noDataAvailable.tr()));
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(child: _buildOverviewCard()),
            const SizedBox(height: 16),
            RepaintBoundary(child: _buildTransferStatsCard()),
            const SizedBox(height: 16),
            RepaintBoundary(child: _buildTorrentStatusCard()),
            const SizedBox(height: 16),
            RepaintBoundary(child: _buildPerformanceCard()),
            const SizedBox(height: 16),
            RepaintBoundary(child: _buildCacheStatsCard()),
            const SizedBox(height: 16),
            RepaintBoundary(child: _buildTimelineCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return _buildCard(
      title: 'Overview',
      icon: Icons.analytics,
      child: Column(
        children: [
          _buildStatRow('Total Torrents', '${_statistics!.totalTorrents}'),
          _buildStatRow('Active Torrents', '${_statistics!.activeTorrents}'),
          _buildStatRow(
            'Completed Torrents',
            '${_statistics!.completedTorrents}',
          ),
          _buildStatRow('Paused Torrents', '${_statistics!.pausedTorrents}'),
          _buildStatRow('Errored Torrents', '${_statistics!.erroredTorrents}'),
        ],
      ),
    );
  }

  Widget _buildTransferStatsCard() {
    return _buildCard(
      title: 'Transfer Statistics',
      icon: Icons.swap_horiz,
      child: Column(
        children: [
          _buildStatRow(
            'All-time Upload',
            FormatUtils.formatBytes(_statistics!.totalUploaded),
            icon: Icons.upload,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            'All-time Download',
            FormatUtils.formatBytes(_statistics!.totalDownloaded),
            icon: Icons.download,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            'All-time Share Ratio',
            FormatUtils.formatShareRatio(_statistics!.shareRatio),
            icon: Icons.balance,
            iconColor: Colors.purple,
          ),
          _buildStatRow(
            'Session Waste',
            _statistics!.sessionWaste > 0
                ? FormatUtils.formatBytes(_statistics!.sessionWaste)
                : 'Not available',
            icon: Icons.warning,
            iconColor: Colors.red,
          ),
          _buildStatRow(
            'Total Size',
            FormatUtils.formatBytes(_statistics!.totalSize),
            icon: Icons.storage,
            iconColor: Colors.orange,
          ),
          _buildStatRow(
            'Total Wasted',
            FormatUtils.formatBytes(_statistics!.totalWastedSize),
            icon: Icons.warning,
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTorrentStatusCard() {
    return _buildCard(
      title: 'Torrent Status',
      icon: Icons.list,
      child: Column(
        children: [
          _buildStatRow(
            'Downloading',
            '${_statistics!.downloadingTorrents}',
            icon: Icons.download,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            'Seeding',
            '${_statistics!.seedingTorrents}',
            icon: Icons.upload,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            'Peers Connected',
            '${_statistics!.totalPeersConnected}',
            icon: Icons.people,
            iconColor: Colors.indigo,
          ),
          _buildStatRow(
            'Total Seeds',
            '${_statistics!.totalSeeds}',
            icon: Icons.upload_file,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            'Total Leechers',
            '${_statistics!.totalLeeches}',
            icon: Icons.download,
            iconColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return _buildCard(
      title: 'Performance Metrics',
      icon: Icons.speed,
      child: Column(
        children: [
          _buildStatRow(
            'Average Download Speed',
            FormatUtils.formatBytesPerSecond(_statistics!.averageDownloadSpeed),
            icon: Icons.download,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            'Average Upload Speed',
            FormatUtils.formatBytesPerSecond(_statistics!.averageUploadSpeed),
            icon: Icons.upload,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            'Peak Download Speed',
            FormatUtils.formatBytesPerSecond(_statistics!.peakDownloadSpeed),
            icon: Icons.trending_up,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            'Peak Upload Speed',
            FormatUtils.formatBytesPerSecond(_statistics!.peakUploadSpeed),
            icon: Icons.trending_up,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            'Write Cache Overload',
            '${_statistics!.writeCacheOverload.toStringAsFixed(1)}%',
            icon: Icons.storage,
            iconColor: Colors.orange,
          ),
          _buildStatRow(
            'Read Cache Overload',
            '${_statistics!.readCacheOverload.toStringAsFixed(1)}%',
            icon: Icons.storage,
            iconColor: Colors.orange,
          ),
          _buildStatRow(
            'Queued I/O Jobs',
            '${_statistics!.queuedIoJobs}',
            icon: Icons.queue,
            iconColor: Colors.purple,
          ),
          _buildStatRow(
            'Average Time in Queue',
            '${_statistics!.averageTimeInQueue} ms',
            icon: Icons.timer,
            iconColor: Colors.purple,
          ),
          _buildStatRow(
            'Total Queued Size',
            FormatUtils.formatBytes(_statistics!.totalQueuedSize),
            icon: Icons.data_usage,
            iconColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    return _buildCard(
      title: 'Cache Statistics',
      icon: Icons.memory,
      child: Column(
        children: [
          _buildStatRow(
            'Read Cache Hits',
            '${_statistics!.readCacheHits}%',
            icon: Icons.cached,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            'Total Buffer Size',
            FormatUtils.formatBytes(_statistics!.totalBufferSize),
            icon: Icons.storage,
            iconColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return _buildCard(
      title: 'Timeline',
      icon: Icons.timeline,
      child: Column(
        children: [
          _buildStatRow(
            'First Torrent Added',
            FormatUtils.formatDate(_statistics!.firstTorrentAdded),
            icon: Icons.history,
            iconColor: Colors.grey,
          ),
          _buildStatRow(
            'Last Torrent Added',
            FormatUtils.formatDate(_statistics!.lastTorrentAdded),
            icon: Icons.update,
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
