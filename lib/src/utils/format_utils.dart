import 'dart:math';

class FormatUtils {
  /// Parse qBittorrent timestamp consistently across the app
  /// qBittorrent API returns timestamps in seconds, not milliseconds
  static DateTime parseQbittorrentTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.fromMillisecondsSinceEpoch(0);
    
    int timestampInt;
    if (timestamp is int) {
      timestampInt = timestamp;
    } else if (timestamp is double) {
      timestampInt = timestamp.toInt();
    } else if (timestamp is String) {
      timestampInt = int.tryParse(timestamp) ?? 0;
    } else {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    
    // qBittorrent API returns timestamps in seconds, convert to milliseconds
    return DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
  }

  /// Format bytes to human readable format
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = (log(bytes) / log(1024)).floor();

    if (i >= suffixes.length) {
      return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes.last}';
    }

    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Format bytes per second
  static String formatBytesPerSecond(int bytesPerSecond) {
    return '${formatBytes(bytesPerSecond)}/s';
  }

  /// Format ratio as percentage
  static String formatRatio(double ratio) {
    return '${(ratio * 100).toStringAsFixed(1)}%';
  }

  /// Format share ratio
  static String formatShareRatio(double ratio) {
    return ratio.toStringAsFixed(2);
  }

  /// Format date in a readable format
  static String formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Format duration in seconds to human readable format
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0s';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
}
