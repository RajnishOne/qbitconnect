import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qbitconnect/src/state/batch_selection_state.dart';
import '../models/torrent.dart';

/// Enhanced torrent card with selection capabilities
/// This widget extends the basic torrent card with batch selection features
class TorrentCardWithSelection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Consumer<BatchSelectionState>(
      builder: (context, batchState, child) {
        final isSelected = batchState.isSelected(torrent.hash);
        final isSelectionMode = batchState.isSelectionMode;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.2)
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.15)
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
                    batchState.toggleSelection(torrent.hash);
                    onSelectionToggle?.call();
                  }
                : onTap,
            borderRadius: BorderRadius.circular(12),
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Selection checkbox (only visible in selection mode)
                  if (isSelectionMode) ...[
                    _buildSelectionCheckbox(context, batchState, isSelected),
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
    );
  }

  Widget _buildSelectionCheckbox(
    BuildContext context,
    BatchSelectionState batchState,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Checkbox(
        value: isSelected,
        onChanged: (value) {
          batchState.toggleSelection(torrent.hash);
          onSelectionToggle?.call();
        },
        activeColor: Theme.of(context).colorScheme.primary,
        checkColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final bool isErrored = torrent.isErrored;
    final String infoLine = _buildInfoLine(torrent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                torrent.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isErrored
                      ? Colors.red
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: torrent.stateColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: torrent.stateColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                torrent.displayState,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: torrent.stateColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: torrent.progress.clamp(0, 1.0)),
        const SizedBox(height: 8),
        if (torrent.category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    torrent.displayCategory,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Flexible(
          child: Text(
            infoLine,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _buildInfoLine(Torrent torrent) {
    final NumberFormat percent = NumberFormat.decimalPercentPattern(
      decimalDigits: 1,
    );

    String size = _formatBytes(torrent.size);
    String dlspeed = '${_formatBytes(torrent.dlspeed)}/s';
    String upspeed = '${_formatBytes(torrent.upspeed)}/s';
    String pct = percent.format(torrent.progress);
    return '$pct • Size $size • DL $dlspeed • UL $upspeed';
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 0) return '0 B'; // Handle negative values
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    int unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    if (value.isNaN || value.isInfinite) return '0 B';
    return '${value.toStringAsFixed(value >= 10 || value.floorToDouble() == value ? 0 : 1)} ${units[unitIndex]}';
  }
}
