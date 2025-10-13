import '../models/torrent.dart';
import '../api/qbittorrent_api.dart';

/// Service to provide directory suggestions for torrent relocation
/// Collects directories from qBittorrent API preferences and existing torrents
class DirectorySuggestionService {
  static final DirectorySuggestionService _instance =
      DirectorySuggestionService._internal();
  factory DirectorySuggestionService() => _instance;
  DirectorySuggestionService._internal();

  /// Get all existing directories from qBittorrent API preferences and torrents
  Future<List<String>> getAllDirectories({
    required List<Torrent> torrents,
    QbittorrentApiClient? client,
  }) async {
    final Set<String> allDirectories = {};

    // 1. Get directories from qBittorrent API preferences (only existing ones)
    if (client != null) {
      try {
        final preferences = await client.fetchAppPreferences();

        // Default save path (only if it exists)
        final defaultSavePath = preferences['save_path'];
        if (defaultSavePath != null && defaultSavePath.toString().isNotEmpty) {
          allDirectories.add(defaultSavePath.toString());
        }

        // Note: We skip temp_path as it's for incomplete downloads, not final storage

        // Watched folders (scan directories) - these should exist
        final scanDirs = preferences['scan_dirs'];
        if (scanDirs != null && scanDirs is Map) {
          for (final path in scanDirs.keys) {
            if (path.toString().isNotEmpty) {
              allDirectories.add(path.toString());
            }
          }
        }

        // Category save paths (only if they exist)
        final categoryPaths = preferences['category_path'];
        if (categoryPaths != null && categoryPaths is Map) {
          for (final path in categoryPaths.values) {
            if (path != null && path.toString().isNotEmpty) {
              allDirectories.add(path.toString());
            }
          }
        }
      } catch (e) {
        // Silently ignore API errors
      }
    }

    // 2. Get directories from existing torrents (these definitely exist)
    for (final torrent in torrents) {
      if (torrent.savePath.isNotEmpty) {
        allDirectories.add(torrent.savePath);
      }
    }

    // Convert to list and sort alphabetically
    final sortedList = allDirectories.toList()..sort();

    return sortedList;
  }

  /// Get default save path from qBittorrent API
  Future<String?> getDefaultSavePath(QbittorrentApiClient? client) async {
    if (client == null) return null;

    try {
      final preferences = await client.fetchAppPreferences();
      final defaultSavePath = preferences['save_path'];
      if (defaultSavePath != null && defaultSavePath.toString().isNotEmpty) {
        return defaultSavePath.toString();
      }
    } catch (e) {
      // Silently ignore API errors
    }
    return null;
  }
}
