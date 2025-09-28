import 'package:flutter/foundation.dart';
import '../models/torrent.dart';
import '../models/transfer_info.dart';
import '../models/torrent_details.dart';
import '../models/torrent_add_options.dart';
import '../api/qbittorrent_api.dart';

/// Manages torrent data, operations, and filtering logic
class TorrentState extends ChangeNotifier {
  List<Torrent> _torrents = const [];
  TransferInfo? _transferInfo;
  Map<String, int> _filterCounts = const {};
  Map<String, int> _categoryCounts = const {};
  List<String> _allCategories = const [];

  // Loading states
  final Set<String> _loadingTorrentHashes = {};
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;

  // Getters
  List<Torrent> get torrents => _torrents;
  TransferInfo? get transferInfo => _transferInfo;
  Map<String, int> get filterCounts => _filterCounts;
  Map<String, int> get categoryCounts => _categoryCounts;
  List<String> get allCategories => _allCategories;
  bool get isRefreshing => _isRefreshing;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool isLoadingTorrent(String hash) => _loadingTorrentHashes.contains(hash);

  /// Refresh torrent data from API
  Future<void> refreshTorrents(
    QbittorrentApiClient? client,
    String activeSort,
    String sortDirection,
    String activeFilter,
    String activeCategory,
  ) async {
    if (client == null) {
      // Clear data if no client available
      _torrents = const [];
      _transferInfo = null;
      _filterCounts = const {};
      _categoryCounts = const {};
      _allCategories = const [];
      notifyListeners();
      return;
    }

    _isRefreshing = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        client.fetchTorrents(
          sort: activeSort,
          sortDirection: sortDirection,
        ), // fetch all to compute counts locally
        client.fetchTransferInfo(),
      ]);
      final allTorrents = results[0] as List<Torrent>;
      _transferInfo = results[1] as TransferInfo;

      // Compute counts for each filter from the full set
      _filterCounts = _computeFilterCounts(allTorrents);
      _categoryCounts = _computeCategoryCounts(allTorrents);
      _allCategories = _computeAllCategories(allTorrents);

      // Apply active filter and category locally for the displayed list
      final filteredTorrents = allTorrents
          .where(
            (t) =>
                _matchesFilter(t, activeFilter) &&
                _matchesCategory(t, activeCategory),
          )
          .toList();

      _torrents = filteredTorrents;

      // Mark that we've successfully loaded data at least once
      _hasLoadedOnce = true;
    } catch (e) {
      // Error during refresh: ${ErrorHandler.getShortErrorMessage(e)}
      // Don't clear existing data on error, just log it
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Add torrent from file
  Future<void> addTorrentFromFile({
    required QbittorrentApiClient client,
    required String fileName,
    required List<int> bytes,
    TorrentAddOptions? options,
  }) async {
    await client.addTorrentFromFile(
      fileName: fileName,
      bytes: bytes,
      options: options,
    );
  }

  /// Add torrent from URL
  Future<void> addTorrentFromUrl({
    required QbittorrentApiClient client,
    required String url,
    TorrentAddOptions? options,
  }) async {
    await client.addTorrentFromUrl(url: url, options: options);
  }

  /// Pause torrents
  Future<void> pauseTorrents(
    QbittorrentApiClient client,
    List<String> hashes,
  ) async {
    _loadingTorrentHashes.addAll(hashes);
    notifyListeners();

    try {
      await client.pauseTorrents(hashes);
    } finally {
      _loadingTorrentHashes.removeAll(hashes);
      notifyListeners();
    }
  }

  /// Resume torrents
  Future<void> resumeTorrents(
    QbittorrentApiClient client,
    List<String> hashes,
  ) async {
    _loadingTorrentHashes.addAll(hashes);
    notifyListeners();

    try {
      await client.resumeTorrents(hashes);
    } finally {
      _loadingTorrentHashes.removeAll(hashes);
      notifyListeners();
    }
  }

  /// Delete torrents
  Future<void> deleteTorrents(
    QbittorrentApiClient client,
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    await client.deleteTorrents(hashes, deleteFiles: deleteFiles);
  }

  /// Get torrent details
  Future<TorrentDetails?> getTorrentDetails(
    QbittorrentApiClient client,
    String hash,
  ) async {
    try {
      final properties = await client.getTorrentProperties(hash);
      return TorrentDetails.fromMap(properties);
    } catch (e) {
      return null;
    }
  }

  /// Get torrent files
  Future<List<TorrentFile>> getTorrentFiles(
    QbittorrentApiClient client,
    String hash,
  ) async {
    try {
      final files = await client.getTorrentFiles(hash);
      return files.map((f) => TorrentFile.fromMap(f)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get torrent trackers
  Future<List<TorrentTracker>> getTorrentTrackers(
    QbittorrentApiClient client,
    String hash,
  ) async {
    try {
      final trackers = await client.getTorrentTrackers(hash);
      return trackers.map((t) => TorrentTracker.fromMap(t)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Recheck torrent
  Future<void> recheckTorrent(QbittorrentApiClient client, String hash) async {
    try {
      await client.recheckTorrent(hash);
    } catch (e) {
      // Log error for debugging but don't show to user
      // Recheck torrent error: ${ErrorHandler.getShortErrorMessage(e)}
    }
  }

  /// Set torrent location
  Future<void> setTorrentLocation(
    QbittorrentApiClient client,
    String hash,
    String location,
  ) async {
    try {
      await client.setTorrentLocation(hash, location);
    } catch (e) {
      // Log error for debugging but don't show to user
      // Set torrent location error: ${ErrorHandler.getShortErrorMessage(e)}
    }
  }

  /// Set torrent name
  Future<void> setTorrentName(
    QbittorrentApiClient client,
    String hash,
    String name,
  ) async {
    try {
      await client.setTorrentName(hash, name);
    } catch (e) {
      // Log error for debugging but don't show to user
      // Set torrent name error: ${ErrorHandler.getShortErrorMessage(e)}
    }
  }

  /// Set file priority
  Future<void> setFilePriority(
    QbittorrentApiClient client,
    String hash,
    List<String> fileIds,
    int priority,
  ) async {
    try {
      await client.setFilePriority(hash, fileIds, priority);
    } catch (e) {
      // Log error for debugging but don't show to user
      // Set file priority error: ${ErrorHandler.getShortErrorMessage(e)}
    }
  }

  /// Increase torrent priority
  Future<void> increaseTorrentPriority(
    QbittorrentApiClient client,
    List<String> hashes,
  ) async {
    try {
      await client.increaseTorrentPriority(hashes);
    } catch (e) {
      // Increase torrent priority error: ${ErrorHandler.getShortErrorMessage(e)}
      rethrow;
    }
  }

  /// Decrease torrent priority
  Future<void> decreaseTorrentPriority(
    QbittorrentApiClient client,
    List<String> hashes,
  ) async {
    try {
      await client.decreaseTorrentPriority(hashes);
    } catch (e) {
      // Decrease torrent priority error: ${ErrorHandler.getShortErrorMessage(e)}
      rethrow;
    }
  }

  /// Move torrent to top
  Future<void> moveTorrentToTop(
    QbittorrentApiClient client,
    List<String> hashes,
  ) async {
    try {
      await client.moveTorrentToTop(hashes);
    } catch (e) {
      // Move torrent to top error: ${ErrorHandler.getShortErrorMessage(e)}
      rethrow;
    }
  }

  /// Move torrent to bottom
  Future<void> moveTorrentToBottom(
    QbittorrentApiClient client,
    List<String> hashes,
  ) async {
    try {
      await client.moveTorrentToBottom(hashes);
    } catch (e) {
      // Move torrent to bottom error: ${ErrorHandler.getShortErrorMessage(e)}
      rethrow;
    }
  }

  /// Clear torrent data (used on disconnect)
  void clearData() {
    _torrents = const [];
    _transferInfo = null;
    _hasLoadedOnce = false;
    _filterCounts = const {};
    _categoryCounts = const {};
    _allCategories = const [];
    _loadingTorrentHashes.clear();
    _isRefreshing = false;
    notifyListeners();
  }

  // Private helper methods for filter logic
  Map<String, int> _computeCategoryCounts(List<Torrent> all) {
    final Map<String, int> counts = {};
    counts['all'] = all.length;

    for (final t in all) {
      final category = t.category.isEmpty ? 'Uncategorized' : t.category;
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return counts;
  }

  Map<String, int> _computeFilterCounts(List<Torrent> all) {
    final Map<String, int> counts = {
      'all': all.length,
      'downloading': 0,
      'completed': 0,
      'seeding': 0,
      'paused': 0,
      'stalled': 0,
      'errored': 0,
      'active': 0,
      'inactive': 0,
    };

    for (final t in all) {
      if (_matchesFilter(t, 'downloading')) {
        counts['downloading'] = (counts['downloading'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'completed')) {
        counts['completed'] = (counts['completed'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'seeding')) {
        counts['seeding'] = (counts['seeding'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'paused')) {
        counts['paused'] = (counts['paused'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'stalled')) {
        counts['stalled'] = (counts['stalled'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'errored')) {
        counts['errored'] = (counts['errored'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'active')) {
        counts['active'] = (counts['active'] ?? 0) + 1;
      }
      if (_matchesFilter(t, 'inactive')) {
        counts['inactive'] = (counts['inactive'] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<String> _computeAllCategories(List<Torrent> all) {
    final Set<String> categories = {};
    for (final t in all) {
      if (t.category.isNotEmpty) {
        categories.add(t.category);
      } else {
        categories.add('Uncategorized');
      }
    }
    return categories.toList();
  }

  bool _matchesCategory(Torrent t, String category) {
    if (category == 'all') return true;
    final torrentCategory = t.category.isEmpty ? 'Uncategorized' : t.category;
    return torrentCategory == category;
  }

  bool _matchesFilter(Torrent t, String filter) {
    if (filter == 'all') return true;
    final String state = t.state.toLowerCase();
    final double progress = t.progress;
    final int dlspeed = t.dlspeed;
    final int upspeed = t.upspeed;
    final bool isActive = dlspeed > 0 || upspeed > 0;

    switch (filter) {
      case 'downloading':
        return state.contains('down') && !state.contains('paused');
      case 'completed':
        return progress >= 1.0 &&
            !(state.contains('upload') || state.contains('seed'));
      case 'seeding':
        return state.contains('upload') ||
            state.contains('seed') ||
            state.contains('up') ||
            upspeed > 0;
      case 'paused':
        return state.contains('paused');
      case 'stalled':
        return state.contains('stalled');
      case 'errored':
        return state.contains('error');
      case 'active':
        return isActive;
      case 'inactive':
        return !isActive;
      default:
        return true;
    }
  }
}
