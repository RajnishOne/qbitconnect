import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/torrent.dart';
import '../models/torrent_details.dart';
import '../utils/byte_formatter.dart';

class TorrentStatsTab extends StatefulWidget {
  final Torrent torrent;
  final TorrentDetails? details;

  const TorrentStatsTab({
    super.key,
    required this.torrent,
    required this.details,
  });

  @override
  State<TorrentStatsTab> createState() => _TorrentStatsTabState();
}

class _TorrentStatsTabState extends State<TorrentStatsTab> {
  // Store historical speed data (last 60 data points)
  final List<double> _downloadSpeeds = [];
  final List<double> _uploadSpeeds = [];
  final int _maxDataPoints = 60;

  @override
  void didUpdateWidget(TorrentStatsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update speed history when data changes
    if (widget.details != null) {
      _updateSpeedHistory();
    }
  }

  void _updateSpeedHistory() {
    final details = widget.details!;

    // Add current speeds
    _downloadSpeeds.add(details.dlSpeed.toDouble());
    _uploadSpeeds.add(details.upSpeed.toDouble());

    // Keep only last N data points
    if (_downloadSpeeds.length > _maxDataPoints) {
      _downloadSpeeds.removeAt(0);
    }
    if (_uploadSpeeds.length > _maxDataPoints) {
      _uploadSpeeds.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.details == null) {
      return const Center(child: Text('No stats data available'));
    }

    final details = widget.details!;
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      children: [
        // Big Progress Circle at top
        _buildProgressCircle(details, theme),
        const SizedBox(height: 24),

        // Speed Cards
        _buildSpeedCards(details, theme),
        const SizedBox(height: 20),

        // Speed Graph
        if (_downloadSpeeds.length > 1) _buildSpeedGraph(theme),
        if (_downloadSpeeds.length > 1) const SizedBox(height: 20),

        // Connection Info
        _buildConnectionCards(details, theme),
        const SizedBox(height: 20),

        // Data Transfer Overview
        _buildDataOverview(details, theme),
        const SizedBox(height: 20),

        // Quick Stats
        _buildQuickStats(details, theme),
      ],
    );
  }

  // Big circular progress indicator at the top
  Widget _buildProgressCircle(TorrentDetails details, ThemeData theme) {
    final progress = details.progress.clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 20,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        _getProgressColor(progress),
                      ),
                    ),
                  ),
                  // Center text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(progress),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoPill(
                  'Downloaded',
                  details.formattedSize,
                  Icons.download,
                  theme,
                ),
                _buildInfoPill(
                  'ETA',
                  details.formattedEta,
                  Icons.schedule,
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Real-time speed graph
  Widget _buildSpeedGraph(ThemeData theme) {
    if (_downloadSpeeds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find max value for Y axis
    final allSpeeds = [..._downloadSpeeds, ..._uploadSpeeds];
    final maxSpeed = allSpeeds.isEmpty
        ? 100.0
        : allSpeeds.reduce((a, b) => a > b ? a : b);
    final yMax = maxSpeed > 0 ? maxSpeed * 1.2 : 100.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Speed Over Time',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Legend
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Download', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Upload', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yMax / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            ByteFormatter.formatBytesPerSecond(value.toInt()),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 10 == 0) {
                            return Text(
                              '${value.toInt()}s',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (_downloadSpeeds.length - 1).toDouble(),
                  minY: 0,
                  maxY: yMax,
                  lineBarsData: [
                    // Download speed line
                    LineChartBarData(
                      spots: _downloadSpeeds
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF2196F3),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                      ),
                    ),
                    // Upload speed line
                    LineChartBarData(
                      spots: _uploadSpeeds
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFFFF9800),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFFF9800).withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          theme.colorScheme.inverseSurface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isDownload = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${isDownload ? "DL" : "UP"}: ${ByteFormatter.formatBytesPerSecond(spot.y.toInt())}\n',
                            TextStyle(
                              color: theme.colorScheme.onInverseSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Speed cards showing download and upload
  Widget _buildSpeedCards(TorrentDetails details, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildSpeedCard(
            'Download',
            ByteFormatter.formatBytesPerSecond(details.dlSpeed),
            Icons.download,
            const Color(0xFF2196F3),
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSpeedCard(
            'Upload',
            ByteFormatter.formatBytesPerSecond(details.upSpeed),
            Icons.upload,
            const Color(0xFFFF9800),
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Connection cards
  Widget _buildConnectionCards(TorrentDetails details, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildConnectionCard(
            'Seeds',
            details.seeds.toString(),
            Icons.cloud_upload,
            const Color(0xFF4CAF50),
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildConnectionCard(
            'Peers',
            details.leeches.toString(),
            Icons.people,
            const Color(0xFF9C27B0),
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildConnectionCard(
            'Ratio',
            details.shareRatio.isNaN || details.shareRatio.isInfinite
                ? '0.0'
                : details.shareRatio.toStringAsFixed(1),
            Icons.swap_horiz,
            const Color(0xFFFF5722),
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Data overview with simple bar
  Widget _buildDataOverview(TorrentDetails details, ThemeData theme) {
    final downloaded = details.totalDownloaded.toDouble();
    final uploaded = details.totalUploaded.toDouble();
    final total = downloaded + uploaded;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Transfer',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2196F3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Downloaded', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ByteFormatter.formatBytes(downloaded.toInt()),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Uploaded', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ByteFormatter.formatBytes(uploaded.toInt()),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (downloaded > 0)
                        Expanded(
                          flex: (downloaded / total * 100).round(),
                          child: Container(color: const Color(0xFF2196F3)),
                        ),
                      if (uploaded > 0)
                        Expanded(
                          flex: (uploaded / total * 100).round(),
                          child: Container(color: const Color(0xFF4CAF50)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Quick stats list
  Widget _buildQuickStats(TorrentDetails details, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Time Active',
              details.formattedTimeElapsed,
              Icons.timer_outlined,
              theme,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Seeding Time',
              details.formattedSeedingTime,
              Icons.schedule_outlined,
              theme,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Connections',
              '${details.nbConnections}',
              Icons.link,
              theme,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Pieces',
              '${details.piecesHave} / ${details.piecesNum}',
              Icons.extension_outlined,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPill(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return const Color(0xFF4CAF50);
    if (progress >= 0.75) return const Color(0xFF2196F3);
    if (progress >= 0.5) return const Color(0xFF00BCD4);
    if (progress >= 0.25) return const Color(0xFFFF9800);
    return const Color(0xFFFF5722);
  }
}
