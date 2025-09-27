import 'package:flutter/material.dart';

/// Simple file extension utility for optimized icon and color lookups.
///
/// This utility provides efficient file extension processing with basic caching
/// to avoid repeated string operations when displaying file lists.
class FileExtensionCache {
  // Simple cache for file extensions to avoid repeated string splitting
  static final Map<String, String> _extensionCache = {};

  /// Gets the file extension from a filename with basic caching.
  static String _getExtension(String fileName) {
    return _extensionCache.putIfAbsent(fileName, () {
      final parts = fileName.split('.');
      if (parts.length < 2) return '';
      return parts.last.toLowerCase();
    });
  }

  /// Gets the appropriate icon for a file based on its extension.
  static IconData getFileIcon(String fileName) {
    final extension = _getExtension(fileName);

    // Simple switch statement for common file types
    switch (extension) {
      // Video files
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
        return Icons.video_file;

      // Audio files
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
        return Icons.audio_file;

      // Image files
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;

      // Document files
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'doc':
      case 'docx':
        return Icons.description;

      // Archive files
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive;

      // Code files
      case 'dart':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
      case 'json':
      case 'xml':
        return Icons.code;

      // Executable files
      case 'exe':
      case 'msi':
      case 'apk':
        return Icons.settings_applications;

      default:
        return Icons.insert_drive_file;
    }
  }

  /// Gets the appropriate color for a file based on its extension.
  static Color getFileColor(String fileName) {
    final extension = _getExtension(fileName);

    // Simple switch statement for common file types
    switch (extension) {
      // Video files - Red
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
        return Colors.red;

      // Audio files - Orange
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
        return Colors.orange;

      // Image files - Green
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Colors.green;

      // Document files - Blue
      case 'pdf':
      case 'txt':
      case 'doc':
      case 'docx':
        return Colors.blue;

      // Archive files - Purple
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Colors.purple;

      // Code files - Indigo
      case 'dart':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
      case 'json':
      case 'xml':
        return Colors.indigo;

      // Executable files - Brown
      case 'exe':
      case 'msi':
      case 'apk':
        return Colors.brown;

      default:
        return Colors.blue;
    }
  }

  /// Clears the extension cache to free up memory.
  static void clearCache() {
    _extensionCache.clear();
  }
}
