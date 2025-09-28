import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qbitconnect/src/state/batch_selection_state.dart';
import '../models/torrent.dart';
import '../models/torrent_card_display_options.dart';
import '../services/display_options_cache.dart';
import '../utils/byte_formatter.dart';

/// Enhanced torrent card with selection capabilities
/// This widget extends the basic torrent card with batch selection features
class TorrentCardWithSelection extends StatefulWidget {
  final Torrent torrent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onSelectionToggle;

  const TorrentCardWithSelection({
    super.key,
    required this.torrent,
    required this.onTap,
    required this.onLongPress,
    this.onSelectionToggle,
  });

  @override
  State<TorrentCardWithSelection> createState() =>
      _TorrentCardWithSelectionState();
}

class _TorrentCardWithSelectionState extends State<TorrentCardWithSelection> {
  List<TorrentCardDisplayOption> _displayOptions =
      TorrentCardDisplayOption.defaultOptions;

  // Cache expensive computations
  static final Map<String, NumberFormat> _percentageFormatters = {};
  static final Map<String, String> _formattedBytesCache = {};
  static final Map<String, String> _formattedSpeedCache = {};
  static final Map<String, String> _formattedPercentageCache = {};
  static final Map<String, String> _formattedRatioCache = {};

  @override
  void initState() {
    super.initState();
    _loadDisplayOptions();
    _setupChangeListener();
  }

  @override
  void dispose() {
    // Remove the change listener when widget is disposed
    DisplayOptionsCache.removeChangeListener(_onOptionsChanged);
    super.dispose();
  }

  void _loadDisplayOptions() {
    // Use cached options if available
    if (DisplayOptionsCache.isCached) {
      _displayOptions = DisplayOptionsCache.getCachedOptions();
      return;
    }

    // Otherwise, add callback to be notified when options are loaded
    DisplayOptionsCache.addLoadCallback(() {
      if (mounted) {
        setState(() {
          _displayOptions = DisplayOptionsCache.getCachedOptions();
        });
      }
    });
  }

  void _setupChangeListener() {
    // Listen for changes to display options
    DisplayOptionsCache.addChangeListener(_onOptionsChanged);
  }

  void _onOptionsChanged() {
    if (mounted) {
      setState(() {
        _displayOptions = DisplayOptionsCache.getCachedOptions();
      });
    }
  }

  NumberFormat _getPercentageFormatter() {
    const key = 'percentage';
    return _percentageFormatters[key] ??= NumberFormat.decimalPercentPattern(
      decimalDigits: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child:
          Selector<
            BatchSelectionState,
            ({bool isSelected, bool isSelectionMode})
          >(
            selector: (context, batchState) => (
              isSelected: batchState.isSelected(widget.torrent.hash),
              isSelectionMode: batchState.isSelectionMode,
            ),
            builder: (context, selectionData, child) {
              final isSelected = selectionData.isSelected;
              final isSelectionMode = selectionData.isSelectionMode;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: isSelectionMode
                      ? () {
                          context.read<BatchSelectionState>().toggleSelection(
                            widget.torrent.hash,
                          );
                          widget.onSelectionToggle?.call();
                        }
                      : widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  onLongPress: widget.onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Selection checkbox (only visible in selection mode)
                        if (isSelectionMode) ...[
                          _buildSelectionCheckbox(context, isSelected),
                          const SizedBox(width: 12),
                        ],
                        // Main content
                        Expanded(child: _buildMainContent(context)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildSelectionCheckbox(BuildContext context, bool isSelected) {
    final theme = Theme.of(context).colorScheme;
    return Checkbox(
      value: isSelected,
      onChanged: (value) {
        context.read<BatchSelectionState>().toggleSelection(
          widget.torrent.hash,
        );
        widget.onSelectionToggle?.call();
      },
      activeColor: theme.primary,
      checkColor: theme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildMainContent(BuildContext context) {
    // Cache theme colors to avoid repeated Theme.of(context) calls
    final theme = Theme.of(context).colorScheme;
    final onSurfaceColor = theme.onSurface;
    final onSurface60 = onSurfaceColor.withValues(alpha: 0.6);
    final onSurface70 = onSurfaceColor.withValues(alpha: 0.7);

    final bool isErrored = widget.torrent.isErrored;
    final String infoLine = _buildInfoLine(widget.torrent);
    final stateColor = widget.torrent.stateColor;
    final stateColor10 = stateColor.withValues(alpha: 0.1);
    final stateColor30 = stateColor.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.torrent.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isErrored ? Colors.red : onSurfaceColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stateColor10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stateColor30, width: 1),
              ),
              child: Text(
                widget.torrent.displayState,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: stateColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: widget.torrent.progress.clamp(0, 1.0)),
        const SizedBox(height: 8),
        if (widget.torrent.category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 12, color: onSurface60),
                const SizedBox(width: 4),
                Text(
                  widget.torrent.displayCategory,
                  style: TextStyle(fontSize: 11, color: onSurface60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (widget.torrent.isDownloading && widget.torrent.eta > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 12, color: onSurface60),
                      const SizedBox(width: 4),
                      Text(
                        widget.torrent.formattedEta,
                        style: TextStyle(fontSize: 11, color: onSurface60),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        Text(
          infoLine,
          style: TextStyle(fontSize: 12, color: onSurface70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _buildInfoLine(Torrent torrent) {
    // Get display options from preferences
    final displayOptions = _getDisplayOptions();

    if (displayOptions.isEmpty) {
      // Fallback to default display if no options are set
      return _buildDefaultInfoLine(torrent);
    }

    final List<String> infoParts = [];

    for (final option in displayOptions) {
      final info = _formatDisplayOption(torrent, option);
      if (info.isNotEmpty) {
        infoParts.add(info);
      }
    }

    return infoParts.join(' • ');
  }

  List<TorrentCardDisplayOption> _getDisplayOptions() {
    return _displayOptions;
  }

  String _buildDefaultInfoLine(Torrent torrent) {
    // Cache formatted strings to avoid repeated formatting
    final sizeKey = '${torrent.size}';
    final dlspeedKey = '${torrent.dlspeed}';
    final upspeedKey = '${torrent.upspeed}';
    final progressKey = '${torrent.progress}';

    String size = _formattedBytesCache[sizeKey] ??= ByteFormatter.formatBytes(
      torrent.size,
    );
    String dlspeed = _formattedSpeedCache[dlspeedKey] ??=
        ByteFormatter.formatBytesPerSecond(torrent.dlspeed);
    String upspeed = _formattedSpeedCache[upspeedKey] ??=
        ByteFormatter.formatBytesPerSecond(torrent.upspeed);
    String pct = _formattedPercentageCache[progressKey] ??= _formatPercentage(
      torrent.progress,
    );

    return '$pct • Size $size • DL $dlspeed • UL $upspeed';
  }

  String _formatDisplayOption(
    Torrent torrent,
    TorrentCardDisplayOption option,
  ) {
    switch (option) {
      case TorrentCardDisplayOption.percentage:
        return _getCachedPercentage(torrent.progress);

      case TorrentCardDisplayOption.size:
        return 'Size ${_getCachedBytes(torrent.size)}';

      case TorrentCardDisplayOption.downloadSpeed:
        return 'DL ${_getCachedSpeed(torrent.dlspeed)}';

      case TorrentCardDisplayOption.uploadSpeed:
        return 'UL ${_getCachedSpeed(torrent.upspeed)}';

      case TorrentCardDisplayOption.ratio:
        return 'Ratio ${_getCachedRatio(torrent.uploaded, torrent.downloaded)}';

      case TorrentCardDisplayOption.eta:
        if (torrent.isDownloading && torrent.eta > 0) {
          return 'ETA ${torrent.formattedEta}';
        }
        return '';

      case TorrentCardDisplayOption.seeds:
        return 'Seeds ${torrent.numSeeds}';

      case TorrentCardDisplayOption.leeches:
        return 'Leeches ${torrent.numLeechs}';

      case TorrentCardDisplayOption.uploaded:
        return 'Uploaded ${_getCachedBytes(torrent.uploaded)}';

      case TorrentCardDisplayOption.downloaded:
        return 'Downloaded ${_getCachedBytes(torrent.downloaded)}';
    }
  }

  // Optimized cache access methods
  String _getCachedPercentage(double progress) {
    final key = progress.toString();
    return _formattedPercentageCache[key] ??= _formatPercentage(progress);
  }

  String _getCachedBytes(int bytes) {
    final key = bytes.toString();
    return _formattedBytesCache[key] ??= ByteFormatter.formatBytes(bytes);
  }

  String _getCachedSpeed(int speed) {
    final key = speed.toString();
    return _formattedSpeedCache[key] ??= ByteFormatter.formatBytesPerSecond(
      speed,
    );
  }

  String _getCachedRatio(int uploaded, int downloaded) {
    final key = '${uploaded}_$downloaded';
    return _formattedRatioCache[key] ??= ByteFormatter.formatRatio(
      uploaded,
      downloaded,
    );
  }

  String _formatPercentage(double progress) {
    final percent = _getPercentageFormatter();
    String formatted = percent.format(progress);

    // Remove .0 from the percentage if it exists
    if (formatted.endsWith('.0%')) {
      formatted = formatted.replaceAll('.0%', '%');
    }

    return formatted;
  }

  /// Clear caches when memory usage is high or app is backgrounded
  static void clearCaches() {
    _formattedBytesCache.clear();
    _formattedSpeedCache.clear();
    _formattedPercentageCache.clear();
    _formattedRatioCache.clear();
  }

  /// Limit cache size to prevent memory issues
  static void _limitCacheSize(Map<String, String> cache, int maxSize) {
    if (cache.length > maxSize) {
      final keys = cache.keys.toList();
      // Remove oldest entries (simple FIFO)
      for (int i = 0; i < keys.length - maxSize; i++) {
        cache.remove(keys[i]);
      }
    }
  }

  /// Periodically clean up caches
  static void cleanupCaches() {
    const maxCacheSize = 1000;
    _limitCacheSize(_formattedBytesCache, maxCacheSize);
    _limitCacheSize(_formattedSpeedCache, maxCacheSize);
    _limitCacheSize(_formattedPercentageCache, maxCacheSize);
    _limitCacheSize(_formattedRatioCache, maxCacheSize);
  }
}

/// Static utility class for cache management
class TorrentCardCacheManager {
  /// Clear caches when memory usage is high or app is backgrounded
  static void clearCaches() {
    _TorrentCardWithSelectionState.clearCaches();
  }

  /// Periodically clean up caches
  static void cleanupCaches() {
    _TorrentCardWithSelectionState.cleanupCaches();
  }
}
