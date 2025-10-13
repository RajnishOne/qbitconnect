import 'package:shared_preferences/shared_preferences.dart';
import '../models/torrent.dart';
import '../api/qbittorrent_api.dart';

/// Service to manage directory history for torrent relocation
/// Collects directories from existing torrents and API preferences
class DirectoryHistoryService {
  static final DirectoryHistoryService _instance =
      DirectoryHistoryService._internal();
  factory DirectoryHistoryService() => _instance;
  DirectoryHistoryService._internal();

  static const String _recentDirectoriesKey = 'recent_torrent_directories';
  static const int _maxRecentDirectories = 50;

  /// Get all unique directories from torrents and add recently used ones
  Future<List<String>> getAllDirectories({
    required List<Torrent> torrents,
    QbittorrentApiClient? client,
  }) async {
    final Set<String> allDirectories = {};

    // 1. Get directories from all existing torrents
    for (final torrent in torrents) {
      if (torrent.savePath.isNotEmpty) {
        allDirectories.add(torrent.savePath);
      }
    }

    // 2. Try to get default save path from API preferences
    if (client != null) {
      try {
        final preferences = await client.fetchAppPreferences();
        final defaultSavePath = preferences['save_path'];
        if (defaultSavePath != null && defaultSavePath.toString().isNotEmpty) {
          allDirectories.add(defaultSavePath.toString());
        }

        // Also check temp_path if available
        final tempPath = preferences['temp_path'];
        if (tempPath != null && tempPath.toString().isNotEmpty) {
          allDirectories.add(tempPath.toString());
        }
      } catch (e) {
        // Silently ignore API errors
      }
    }

    // 3. Add recently manually entered directories
    final recentDirs = await _getRecentDirectories();
    allDirectories.addAll(recentDirs);

    // Convert to list and sort alphabetically
    final sortedList = allDirectories.toList()..sort();

    return sortedList;
  }

  /// Save a directory to recent history (when user manually enters one)
  Future<void> addDirectoryToHistory(String directory) async {
    if (directory.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final recentDirs = await _getRecentDirectories();

      // Remove if already exists (to move it to front)
      recentDirs.remove(directory);

      // Add to beginning
      recentDirs.insert(0, directory);

      // Keep only max number of recent directories
      if (recentDirs.length > _maxRecentDirectories) {
        recentDirs.removeRange(_maxRecentDirectories, recentDirs.length);
      }

      // Save back to preferences
      await prefs.setStringList(_recentDirectoriesKey, recentDirs);
    } catch (e) {
      // Silently handle storage errors
    }
  }

  /// Get recently manually entered directories
  Future<List<String>> _getRecentDirectories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentDirectoriesKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Clear all recent directory history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentDirectoriesKey);
    } catch (e) {
      // Silently handle errors
    }
  }
}
