import 'dart:math';
import 'package:flutter/material.dart';
import '../models/torrent_details.dart';

class AnimatedPiecesWidget extends StatefulWidget {
  final TorrentDetails details;

  const AnimatedPiecesWidget({super.key, required this.details});

  @override
  State<AnimatedPiecesWidget> createState() => _AnimatedPiecesWidgetState();
}

class _AnimatedPiecesWidgetState extends State<AnimatedPiecesWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  // Track previous piece count for animation
  int _previousPiecesHave = 0;
  final List<int> _recentlyAddedPieces = [];

  @override
  void initState() {
    super.initState();
    _previousPiecesHave = widget.details.piecesHave;

    // Shimmer animation for active downloading
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Pulse animation for overall progress
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedPiecesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect newly downloaded pieces
    if (widget.details.piecesHave > _previousPiecesHave) {
      final newPieces = widget.details.piecesHave - _previousPiecesHave;
      for (int i = 0; i < newPieces && i < 20; i++) {
        _recentlyAddedPieces.add(_previousPiecesHave + i);
      }

      // Remove old pieces after animation
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _recentlyAddedPieces.clear();
          });
        }
      });

      _previousPiecesHave = widget.details.piecesHave;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.details.progress.clamp(0.0, 1.0);
    final isDownloading = widget.details.dlSpeed > 0 && progress < 1.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header with title and stats
              _buildHeader(theme, progress),
              const SizedBox(height: 24),

              // Main pieces visualization
              _buildPiecesVisualization(theme, progress, isDownloading),
              const SizedBox(height: 16),

              // Legend
              _buildLegend(theme, progress),
              const SizedBox(height: 20),

              // Footer with download info
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, double progress) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getProgressColor(progress),
                _getProgressColor(progress).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _getProgressColor(progress).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getProgressIcon(progress),
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Download Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.details.piecesHave} / ${widget.details.piecesNum} pieces',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.1);
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getProgressColor(progress).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getProgressColor(progress).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(progress),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPiecesVisualization(
    ThemeData theme,
    double progress,
    bool isDownloading,
  ) {
    // Calculate grid dimensions
    final totalPieces = widget.details.piecesNum;
    final downloadedPieces = widget.details.piecesHave;

    // Smart grouping: show max 300 blocks for performance
    final displayBlocks = min(300, totalPieces);
    final piecesPerBlock = totalPieces / displayBlocks;

    // Calculate grid columns (aim for roughly square grid)
    final columns = sqrt(displayBlocks).ceil();
    final rows = (displayBlocks / columns).ceil();

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final blockWidth =
              (constraints.maxWidth - ((columns - 1) * 2)) / columns;
          final blockHeight = (constraints.maxHeight - ((rows - 1) * 2)) / rows;
          final blockSize = min(blockWidth, blockHeight);

          return Center(
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              children: List.generate(displayBlocks, (index) {
                final startPiece = (index * piecesPerBlock).floor();
                final endPiece = ((index + 1) * piecesPerBlock).floor();
                final isDownloaded = startPiece < downloadedPieces;
                final isPartiallyDownloaded =
                    startPiece < downloadedPieces &&
                    endPiece > downloadedPieces;
                final isRecentlyAdded = _recentlyAddedPieces.any(
                  (piece) => piece >= startPiece && piece < endPiece,
                );

                return AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return _buildPieceBlock(
                      blockSize,
                      isDownloaded,
                      isPartiallyDownloaded,
                      isRecentlyAdded,
                      isDownloading,
                      progress,
                      theme,
                    );
                  },
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieceBlock(
    double size,
    bool isDownloaded,
    bool isPartial,
    bool isNew,
    bool isDownloading,
    double progress,
    ThemeData theme,
  ) {
    Color blockColor;
    BoxDecoration decoration;

    if (isNew) {
      // New piece - bright flash
      blockColor = _getProgressColor(progress);
      decoration = BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: blockColor.withOpacity(0.8),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      );
    } else if (isDownloaded) {
      // Downloaded piece
      blockColor = _getProgressColor(progress).withOpacity(0.8);
      decoration = BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(2),
      );
    } else if (isPartial && isDownloading) {
      // Currently downloading piece - shimmer effect
      final shimmerValue = _shimmerController.value;
      final gradientPosition = (shimmerValue * 2) - 1;

      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment(-1 + gradientPosition, -1 + gradientPosition),
          end: Alignment(1 + gradientPosition, 1 + gradientPosition),
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            _getProgressColor(progress).withOpacity(0.4),
            theme.colorScheme.surfaceContainerHighest,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      );
    } else {
      // Not downloaded yet - make it clearly visible in grey
      blockColor = theme.colorScheme.surfaceContainerHighest;
      decoration = BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 0.5,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: decoration,
    );
  }

  Widget _buildLegend(ThemeData theme, double progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Downloaded', _getProgressColor(progress), theme),
        const SizedBox(width: 16),
        _buildLegendItem(
          'Pending',
          theme.colorScheme.surfaceContainerHighest,
          theme,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoChip(
            'Downloaded',
            widget.details.formattedSize,
            Icons.download_rounded,
            const Color(0xFF2196F3),
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoChip(
            'Piece Size',
            widget.details.formattedPieceSize,
            Icons.apps_rounded,
            const Color(0xFF9C27B0),
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoChip(
            'ETA',
            widget.details.formattedEta,
            Icons.schedule_rounded,
            const Color(0xFF4CAF50),
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return const Color(0xFF4CAF50); // Green
    if (progress >= 0.75) return const Color(0xFF2196F3); // Blue
    if (progress >= 0.5) return const Color(0xFF00BCD4); // Cyan
    if (progress >= 0.25) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFFF5722); // Red
  }

  IconData _getProgressIcon(double progress) {
    if (progress >= 1.0) return Icons.check_circle_rounded;
    if (progress >= 0.75) return Icons.cloud_download_rounded;
    if (progress >= 0.5) return Icons.downloading_rounded;
    if (progress >= 0.25) return Icons.arrow_circle_down_rounded;
    return Icons.play_circle_outline_rounded;
  }
}
