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
          _error = LocaleKeys.notConnectedToQBittorrent.tr();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '${LocaleKeys.failedToLoadStatistics.tr()}: $e';
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
      title: LocaleKeys.overview.tr(),
      icon: Icons.analytics,
      child: Column(
        children: [
          _buildStatRow(
            LocaleKeys.totalTorrents.tr(),
            '${_statistics!.totalTorrents}',
          ),
          _buildStatRow(
            LocaleKeys.activeTorrents.tr(),
            '${_statistics!.activeTorrents}',
          ),
          _buildStatRow(
            LocaleKeys.completedTorrents.tr(),
            '${_statistics!.completedTorrents}',
          ),
          _buildStatRow(
            LocaleKeys.pausedTorrents.tr(),
            '${_statistics!.pausedTorrents}',
          ),
          _buildStatRow(
            LocaleKeys.erroredTorrents.tr(),
            '${_statistics!.erroredTorrents}',
          ),
        ],
      ),
    );
  }

  Widget _buildTransferStatsCard() {
    return _buildCard(
      title: LocaleKeys.transferStatistics.tr(),
      icon: Icons.swap_horiz,
      child: Column(
        children: [
          _buildStatRow(
            LocaleKeys.allTimeUpload.tr(),
            FormatUtils.formatBytes(_statistics!.totalUploaded),
            icon: Icons.upload,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            LocaleKeys.allTimeDownload.tr(),
            FormatUtils.formatBytes(_statistics!.totalDownloaded),
            icon: Icons.download,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            LocaleKeys.allTimeShareRatio.tr(),
            FormatUtils.formatShareRatio(_statistics!.shareRatio),
            icon: Icons.balance,
            iconColor: Colors.purple,
          ),
          _buildStatRow(
            LocaleKeys.sessionWaste.tr(),
            _statistics!.sessionWaste > 0
                ? FormatUtils.formatBytes(_statistics!.sessionWaste)
                : LocaleKeys.notAvailable.tr(),
            icon: Icons.warning,
            iconColor: Colors.red,
          ),
          _buildStatRow(
            LocaleKeys.totalSize.tr(),
            FormatUtils.formatBytes(_statistics!.totalSize),
            icon: Icons.storage,
            iconColor: Colors.orange,
          ),
          _buildStatRow(
            LocaleKeys.totalWasted.tr(),
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
      title: LocaleKeys.torrentStatus.tr(),
      icon: Icons.list,
      child: Column(
        children: [
          _buildStatRow(
            LocaleKeys.downloading.tr(),
            '${_statistics!.downloadingTorrents}',
            icon: Icons.download,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            LocaleKeys.seeding.tr(),
            '${_statistics!.seedingTorrents}',
            icon: Icons.upload,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            LocaleKeys.peersConnected.tr(),
            '${_statistics!.totalPeersConnected}',
            icon: Icons.people,
            iconColor: Colors.indigo,
          ),
          _buildStatRow(
            LocaleKeys.totalSeeds.tr(),
            '${_statistics!.totalSeeds}',
            icon: Icons.upload_file,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            LocaleKeys.totalLeechers.tr(),
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
      title: LocaleKeys.performanceMetrics.tr(),
      icon: Icons.speed,
      child: Column(
        children: [
          _buildStatRow(
            LocaleKeys.averageDownloadSpeed.tr(),
            FormatUtils.formatBytesPerSecond(_statistics!.averageDownloadSpeed),
            icon: Icons.download,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            LocaleKeys.averageUploadSpeed.tr(),
            FormatUtils.formatBytesPerSecond(_statistics!.averageUploadSpeed),
            icon: Icons.upload,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            LocaleKeys.peakDownloadSpeed.tr(),
            FormatUtils.formatBytesPerSecond(_statistics!.peakDownloadSpeed),
            icon: Icons.trending_up,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            LocaleKeys.peakUploadSpeed.tr(),
            FormatUtils.formatBytesPerSecond(_statistics!.peakUploadSpeed),
            icon: Icons.trending_up,
            iconColor: Colors.green,
          ),
          _buildStatRow(
            LocaleKeys.writeCacheOverload.tr(),
            '${_statistics!.writeCacheOverload.toStringAsFixed(1)}%',
            icon: Icons.storage,
            iconColor: Colors.orange,
          ),
          _buildStatRow(
            LocaleKeys.readCacheOverload.tr(),
            '${_statistics!.readCacheOverload.toStringAsFixed(1)}%',
            icon: Icons.storage,
            iconColor: Colors.orange,
          ),
          _buildStatRow(
            LocaleKeys.queuedIoJobs.tr(),
            '${_statistics!.queuedIoJobs}',
            icon: Icons.queue,
            iconColor: Colors.purple,
          ),
          _buildStatRow(
            LocaleKeys.averageTimeInQueue.tr(),
            '${_statistics!.averageTimeInQueue} ms',
            icon: Icons.timer,
            iconColor: Colors.purple,
          ),
          _buildStatRow(
            LocaleKeys.totalQueuedSize.tr(),
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
      title: LocaleKeys.cacheStatistics.tr(),
      icon: Icons.memory,
      child: Column(
        children: [
          _buildStatRow(
            LocaleKeys.readCacheHits.tr(),
            '${_statistics!.readCacheHits}%',
            icon: Icons.cached,
            iconColor: Colors.blue,
          ),
          _buildStatRow(
            LocaleKeys.totalBufferSize.tr(),
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
      title: LocaleKeys.timeline.tr(),
      icon: Icons.timeline,
      child: Column(
        children: [
          _buildStatRow(
            LocaleKeys.firstTorrentAdded.tr(),
            FormatUtils.formatDate(_statistics!.firstTorrentAdded),
            icon: Icons.history,
            iconColor: Colors.grey,
          ),
          _buildStatRow(
            LocaleKeys.lastTorrentAdded.tr(),
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
