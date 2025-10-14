import '../api/qbittorrent_api.dart';
import '../models/torrent.dart';
import '../utils/error_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';

/// Batch operation result
class BatchOperationResult {
  final bool success;
  final int affectedCount;
  final String? errorMessage;
  final List<String>? failedHashes;

  BatchOperationResult({
    required this.success,
    required this.affectedCount,
    this.errorMessage,
    this.failedHashes,
  });

  factory BatchOperationResult.success(int count) {
    return BatchOperationResult(success: true, affectedCount: count);
  }

  factory BatchOperationResult.failure(
    String message, {
    List<String>? failedHashes,
  }) {
    return BatchOperationResult(
      success: false,
      affectedCount: 0,
      errorMessage: message,
      failedHashes: failedHashes,
    );
  }
}

/// Service for handling batch operations on torrents
/// This service provides a clean interface for performing bulk operations
/// and can be easily extended for future batch features
class BatchOperationsService {
  final QbittorrentApiClient _apiClient;

  BatchOperationsService(this._apiClient);

  /// Pause multiple torrents
  Future<BatchOperationResult> pauseTorrents(List<String> hashes) async {
    if (hashes.isEmpty) {
      return BatchOperationResult.failure(LocaleKeys.noTorrentsSelected.tr());
    }

    try {
      await _apiClient.pauseTorrents(hashes);
      return BatchOperationResult.success(hashes.length);
    } catch (e) {
      final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      return BatchOperationResult.failure(
        'Failed to pause torrents: $errorMessage',
        failedHashes: hashes,
      );
    }
  }

  /// Resume multiple torrents
  Future<BatchOperationResult> resumeTorrents(List<String> hashes) async {
    if (hashes.isEmpty) {
      return BatchOperationResult.failure(LocaleKeys.noTorrentsSelected.tr());
    }

    try {
      await _apiClient.resumeTorrents(hashes);
      return BatchOperationResult.success(hashes.length);
    } catch (e) {
      final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      return BatchOperationResult.failure(
        'Failed to resume torrents: $errorMessage',
        failedHashes: hashes,
      );
    }
  }

  /// Delete multiple torrents
  Future<BatchOperationResult> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    if (hashes.isEmpty) {
      return BatchOperationResult.failure(LocaleKeys.noTorrentsSelected.tr());
    }

    try {
      await _apiClient.deleteTorrents(hashes, deleteFiles: deleteFiles);
      return BatchOperationResult.success(hashes.length);
    } catch (e) {
      final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      return BatchOperationResult.failure(
        'Failed to delete torrents: $errorMessage',
        failedHashes: hashes,
      );
    }
  }

  /// Get statistics for selected torrents
  Map<String, dynamic> getSelectionStats(
    List<String> selectedHashes,
    List<Torrent> allTorrents,
  ) {
    if (selectedHashes.isEmpty) {
      return {
        'count': 0,
        'totalSize': 0,
        'totalDownloaded': 0,
        'totalUploaded': 0,
        'states': <String, int>{},
        'categories': <String, int>{},
      };
    }

    final selectedTorrents = allTorrents
        .where((torrent) => selectedHashes.contains(torrent.hash))
        .toList();

    final states = <String, int>{};
    final categories = <String, int>{};
    int totalSize = 0;
    int totalDownloaded = 0;
    int totalUploaded = 0;

    for (final torrent in selectedTorrents) {
      // Count states
      states[torrent.state] = (states[torrent.state] ?? 0) + 1;

      // Count categories
      final category = torrent.category.isEmpty
          ? LocaleKeys.uncategorized.tr()
          : torrent.category;
      categories[category] = (categories[category] ?? 0) + 1;

      // Sum sizes
      totalSize += torrent.size;
      totalDownloaded += torrent.downloaded;
      totalUploaded += torrent.uploaded;
    }

    return {
      'count': selectedTorrents.length,
      'totalSize': totalSize,
      'totalDownloaded': totalDownloaded,
      'totalUploaded': totalUploaded,
      'states': states,
      'categories': categories,
    };
  }

  /// Validate if an operation can be performed on selected torrents
  Map<String, dynamic> validateOperation(
    String operation,
    List<String> selectedHashes,
    List<Torrent> allTorrents,
  ) {
    if (selectedHashes.isEmpty) {
      return {'valid': false, 'message': LocaleKeys.noTorrentsSelected.tr()};
    }

    final selectedTorrents = allTorrents
        .where((torrent) => selectedHashes.contains(torrent.hash))
        .toList();

    switch (operation) {
      case 'pause':
        final canPause = selectedTorrents.any(
          (t) => !t.isPaused && !t.isStopped,
        );
        return {
          'valid': canPause,
          'message': canPause ? null : LocaleKeys.noTorrentsCanBePaused.tr(),
          'count': selectedTorrents
              .where((t) => !t.isPaused && !t.isStopped)
              .length,
        };

      case 'resume':
        final canResume = selectedTorrents.any(
          (t) => t.isPaused || t.isStopped,
        );
        return {
          'valid': canResume,
          'message': canResume ? null : LocaleKeys.noTorrentsCanBeResumed.tr(),
          'count': selectedTorrents
              .where((t) => t.isPaused || t.isStopped)
              .length,
        };

      case 'delete':
        return {
          'valid': true,
          'message': null,
          'count': selectedTorrents.length,
        };

      default:
        return {
          'valid': true,
          'message': null,
          'count': selectedTorrents.length,
        };
    }
  }
}
