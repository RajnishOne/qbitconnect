import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle torrent file operations
class TorrentFileHandler {
  static final TorrentFileHandler _instance = TorrentFileHandler._internal();
  factory TorrentFileHandler() => _instance;
  TorrentFileHandler._internal();

  static const String _lastTorrentFileKey = 'last_torrent_file_path';

  /// Process a torrent file and return its path
  Future<String?> processTorrentFile(String filePath) async {
    try {
      // Handle different URI schemes
      String? actualFilePath;

      if (filePath.startsWith('file://')) {
        // Remove file:// prefix
        actualFilePath = filePath.substring(7);
      } else if (filePath.startsWith('content://')) {
        // For content URIs, we need to copy the file to our app directory
        actualFilePath = await _copyContentUriToAppDirectory(filePath);
      } else {
        // Assume it's already a direct file path
        actualFilePath = filePath;
      }

      if (actualFilePath == null) {
        return null;
      }

      // Verify the file exists and is readable
      final file = File(actualFilePath);
      if (!await file.exists()) {
        return null;
      }

      // Check if it's a valid torrent file by reading the first few bytes
      if (!await _isValidTorrentFile(file)) {
        return null;
      }

      // Store the file path for later use
      await _storeLastTorrentFilePath(actualFilePath);

      return actualFilePath;
    } catch (e) {
      return null;
    }
  }

  /// Copy content URI to app directory
  Future<String?> _copyContentUriToAppDirectory(String contentUri) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final torrentDir = Directory('${directory.path}/torrents');

      // Create torrents directory if it doesn't exist
      if (!await torrentDir.exists()) {
        await torrentDir.create(recursive: true);
      }

      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'torrent_$timestamp.torrent';
      final destinationPath = '${torrentDir.path}/$fileName';

      // For now, we'll return the content URI as-is
      // In a real implementation, you'd need to use a plugin like file_picker
      // or platform-specific code to copy the content URI to the app directory
      // Return the content URI for now - the app will need to handle this
      return contentUri;
    } catch (e) {
      // Silently handle copy errors
      return null;
    }
  }

  /// Check if the file is a valid torrent file
  Future<bool> _isValidTorrentFile(File file) async {
    try {
      // Read first 1024 bytes to check for torrent file signature
      final bytes = await file.openRead(0, 1024).first;

      // Torrent files start with 'd' (dictionary) in Bencode format
      // or contain 'announce' key
      final content = String.fromCharCodes(bytes);

      // Basic checks for torrent file format
      return content.startsWith('d') && content.contains('announce');
    } catch (e) {
      return false;
    }
  }

  /// Store the last torrent file path
  Future<void> _storeLastTorrentFilePath(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastTorrentFileKey, filePath);
    } catch (e) {
      // Silently handle storage errors
    }
  }

  /// Get the last torrent file path
  Future<String?> getLastTorrentFilePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastTorrentFileKey);
    } catch (e) {
      return null;
    }
  }

  /// Clear the stored torrent file path
  Future<void> clearLastTorrentFilePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastTorrentFileKey);
    } catch (e) {
      // Silently handle clear errors
    }
  }

  /// Get torrent file info (basic metadata)
  Future<Map<String, dynamic>?> getTorrentFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();

      return {
        'path': filePath,
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
        'exists': true,
      };
    } catch (e) {
      return null;
    }
  }

  /// Test method to simulate processing a torrent file
  void testTorrentFile(String filePath) {
    processTorrentFile(filePath);
  }
}
