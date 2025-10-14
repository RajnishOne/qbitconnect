import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../state/app_state_manager.dart';
import '../models/statistics.dart';
import '../models/sync_data.dart';
import '../models/torrent.dart';
import '../models/transfer_info.dart';
import '../utils/format_utils.dart';
import '../widgets/animated_reload_button.dart';
import '../services/firebase_service.dart';

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

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
  }

  /// Categorize error and return user-friendly message
  String _getUserFriendlyErrorMessage(dynamic error, String context) {
    final errorString = error.toString().toLowerCase();

    // Log technical error to Crashlytics
    FirebaseService.instance.recordError(error, StackTrace.current);

    // Categorize error and return friendly message
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return LocaleKeys.statisticsTimeoutError.tr();
    } else if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unreachable') ||
        errorString.contains('refused')) {
      return LocaleKeys.statisticsNetworkError.tr();
    } else if (errorString.contains('parse') ||
        errorString.contains('format') ||
        errorString.contains('unexpected data')) {
      return LocaleKeys.statisticsDataError.tr();
    } else if (errorString.contains('partial') ||
        errorString.contains('incomplete')) {
      return LocaleKeys.statisticsPartialDataError.tr();
    } else {
      return LocaleKeys.statisticsLoadError.tr();
    }
  }

  /// Log error with context for debugging
  void _logError(dynamic error, String context, [StackTrace? stackTrace]) {
    FirebaseService.instance.recordError(
      'Statistics Screen - $context: $error',
      stackTrace ?? StackTrace.current,
    );

    // Log analytics event for error tracking
    FirebaseService.instance.logEvent(
      name: 'statistics_error',
      parameters: {
        'error_context': context,
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
      },
    );

    debugPrint('Statistics Screen Error [$context]: $error');
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
        // Handle each API call separately to avoid complete failure if one fails
        List<Torrent>? torrents;
        SyncData? syncData;
        TransferInfo? transferInfo;

        // Try to fetch torrents data with timeout
        try {
          torrents = await appState.client!.torrents.fetchTorrents().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Torrents fetch timed out after 30 seconds');
            },
          );
        } catch (torrentError) {
          _logError(torrentError, 'Torrents Fetch');
          // Continue without torrents data - will use empty list
        }

        // Try to fetch sync data with timeout
        try {
          syncData = await appState.client!.statistics.fetchMainData().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Sync data fetch timed out after 30 seconds');
            },
          );
        } catch (syncError) {
          _logError(syncError, 'Sync Data Fetch');
          // Continue without sync data - will use null
        }

        // Try to fetch transfer info with timeout
        try {
          transferInfo = await appState.client!.torrents
              .fetchTransferInfo()
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw Exception(
                    'Transfer info fetch timed out after 30 seconds',
                  );
                },
              );
        } catch (transferError) {
          _logError(transferError, 'Transfer Info Fetch');
          // Continue without transfer info - will use null
        }

        // Check if we have at least some data to work with
        if (torrents == null && syncData == null && transferInfo == null) {
          _logError('All API calls failed', 'Data Availability Check');
          throw Exception(
            'All API calls failed - unable to load any statistics data',
          );
        }

        if (!mounted) return; // Check if widget is still mounted

        try {
          // Safely convert torrents to maps, handling potential null values
          // Limit processing to prevent memory issues with very large torrent lists
          final maxTorrents =
              10000; // Reasonable limit for statistics calculation
          final torrentsToProcess =
              torrents?.take(maxTorrents).toList() ?? <Torrent>[];

          if (torrents != null && torrents.length > maxTorrents) {
            debugPrint(
              'Warning: Limiting statistics to first $maxTorrents torrents out of ${torrents.length}',
            );
          }

          final torrentsData = torrentsToProcess.map((t) {
            try {
              return t.toMap();
            } catch (e) {
              _logError(e, 'Torrent Map Conversion');
              return <String, dynamic>{}; // Return empty map as fallback
            }
          }).toList();

          // Validate that we have some meaningful data
          if (torrentsData.isEmpty &&
              syncData == null &&
              transferInfo == null) {
            _logError(
              'No data available to generate statistics',
              'Data Validation',
            );
            throw Exception('No data available to generate statistics');
          }

          setState(() {
            try {
              _statistics = Statistics.fromTorrentsAndServerState(
                torrentsData,
                syncData?.serverState,
                transferInfo?.toMap(),
              );

              // Log successful statistics load
              FirebaseService.instance.logEvent(
                name: 'statistics_loaded',
                parameters: {
                  'torrents_count': torrentsData.length,
                  'has_sync_data': syncData != null,
                  'has_transfer_info': transferInfo != null,
                },
              );
            } catch (statsError) {
              _logError(statsError, 'Statistics Object Creation');
              // Fall back to empty statistics
              _statistics = Statistics.empty();
            }
            _isLoading = false;
          });
        } catch (parseError) {
          if (!mounted) return;
          _logError(parseError, 'Data Processing');
          setState(() {
            _error = _getUserFriendlyErrorMessage(
              parseError,
              'Data Processing',
            );
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _error = LocaleKeys.notConnectedToQBittorrent.tr();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _logError(e, 'Main Statistics Load');
      setState(() {
        _error = _getUserFriendlyErrorMessage(e, 'Main Statistics Load');
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
