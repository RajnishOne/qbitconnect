import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/batch_selection_state.dart';
import '../state/app_state_manager.dart';
import '../services/batch_operations_service.dart';

/// Floating action bar for batch operations
/// This widget appears when torrents are selected and provides
/// quick access to common batch operations
class BatchActionsBar extends StatefulWidget {
  const BatchActionsBar({super.key});

  @override
  State<BatchActionsBar> createState() => _BatchActionsBarState();
}

class _BatchActionsBarState extends State<BatchActionsBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<BatchSelectionState, bool>(
      selector: (context, batchState) => batchState.hasSelection,
      builder: (context, hasSelection, child) {
        if (!hasSelection) {
          _animationController.reverse();
          return const SizedBox.shrink();
        }

        // Start animation when selection appears
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasSelection && !_animationController.isCompleted) {
            _animationController.forward();
          }
        });

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildActionsBar(context),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionsBar(BuildContext context) {
    final batchState = context.read<BatchSelectionState>();
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selection summary
          _buildSelectionSummary(context, batchState),
          const Divider(height: 1),
          // Action buttons
          _buildActionButtons(context, batchState),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary(
    BuildContext context,
    BatchSelectionState batchState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              batchState.getSelectionSummary(),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () => batchState.clearSelection(),
            icon: const Icon(Icons.close),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BatchSelectionState batchState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context,
            icon: Icons.pause,
            label: 'Pause',
            color: Colors.orange,
            onPressed: () => _performBatchOperation(context, 'pause'),
          ),
          _buildActionButton(
            context,
            icon: Icons.play_arrow,
            label: 'Resume',
            color: Colors.green,
            onPressed: () => _performBatchOperation(context, 'resume'),
          ),
          _buildActionButton(
            context,
            icon: Icons.delete,
            label: 'Delete',
            color: Colors.red,
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performBatchOperation(
    BuildContext context,
    String operation,
  ) async {
    final batchState = context.read<BatchSelectionState>();
    final appState = context.read<AppState>();
    final selectedHashes = batchState.selectedHashes.toList();

    if (selectedHashes.isEmpty) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Performing $operation operation...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final batchService = BatchOperationsService(appState.client!);
      BatchOperationResult result;

      switch (operation) {
        case 'pause':
          result = await batchService.pauseTorrents(selectedHashes);
          break;
        case 'resume':
          result = await batchService.resumeTorrents(selectedHashes);
          break;
        default:
          return;
      }

      // Show result
      if (result.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully ${operation}d ${result.affectedCount} torrents',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear selection
        batchState.clearSelection();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Operation failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Do nothing
    }
  }

  void _showDeleteDialog(BuildContext context) {
    final batchState = context.read<BatchSelectionState>();
    final selectedHashes = batchState.selectedHashes.toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Torrents'),
        content: Text(
          'Are you sure you want to delete ${selectedHashes.length} torrent(s)?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteOptionsDialog(context, selectedHashes);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteOptionsDialog(
    BuildContext context,
    List<String> selectedHashes,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Options'),
        content: const Text('Choose what to delete:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteOperation(context, selectedHashes, false);
            },
            child: const Text('Torrent Only'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteOperation(context, selectedHashes, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Torrent + Files'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteOperation(
    BuildContext context,
    List<String> selectedHashes,
    bool deleteFiles,
  ) async {
    final batchState = context.read<BatchSelectionState>();
    final appState = context.read<AppState>();

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Deleting torrents...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final batchService = BatchOperationsService(appState.client!);
      final result = await batchService.deleteTorrents(
        selectedHashes,
        deleteFiles: deleteFiles,
      );

      if (result.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully deleted ${result.affectedCount} torrents'
                '${deleteFiles ? ' and files' : ''}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear selection
        batchState.clearSelection();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete operation failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Do nothing
    }
  }
}
