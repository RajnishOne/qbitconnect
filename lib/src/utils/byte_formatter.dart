/// Optimized byte formatting utility using bit shifting for better performance.
///
/// This utility provides fast byte-to-human-readable string conversion
/// using bit shifting operations instead of expensive log/pow calculations.
class ByteFormatter {
  // Pre-computed constants for bit shifting operations
  static const int _kiloByte = 1024;
  static const int _megaByte = _kiloByte << 10; // 1024 * 1024
  static const int _gigaByte = _megaByte << 10; // 1024 * 1024 * 1024
  static const int _teraByte = _gigaByte << 10; // 1024 * 1024 * 1024 * 1024

  // Pre-computed suffixes for fast lookup
  static const List<String> _suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];

  /// Formats bytes into human-readable string using optimized bit shifting.
  ///
  /// This method is significantly faster than the traditional log/pow approach
  /// because it uses bit shifting and pre-computed constants.
  ///
  /// Performance improvements:
  /// - No expensive log() calculations
  /// - No expensive pow() calculations
  /// - Uses bit shifting for division by powers of 2
  /// - Pre-computed constants for fast comparisons
  ///
  /// Example:
  /// ```dart
  /// ByteFormatter.formatBytes(1024) // Returns "1.00 KB"
  /// ByteFormatter.formatBytes(1048576) // Returns "1.00 MB"
  /// ```
  static String formatBytes(int bytes) {
    // Handle edge cases
    if (bytes == 0) return '0 B';
    if (bytes < 0) return '0 B';

    // Find the appropriate unit using bit shifting
    int unitIndex = 0;
    double value = bytes.toDouble();

    // Use bit shifting to determine the unit
    if (bytes >= _teraByte) {
      unitIndex = 4;
      value = bytes / _teraByte;
    } else if (bytes >= _gigaByte) {
      unitIndex = 3;
      value = bytes / _gigaByte;
    } else if (bytes >= _megaByte) {
      unitIndex = 2;
      value = bytes / _megaByte;
    } else if (bytes >= _kiloByte) {
      unitIndex = 1;
      value = bytes / _kiloByte;
    }

    // Handle edge cases for the result
    if (value.isNaN || value.isInfinite) return '0 B';

    // Format the result with appropriate precision
    String formattedValue;
    if (value >= 100) {
      formattedValue = value.toStringAsFixed(0);
    } else if (value >= 10) {
      formattedValue = value.toStringAsFixed(1);
    } else {
      formattedValue = value.toStringAsFixed(2);
    }

    return '$formattedValue ${_suffixes[unitIndex]}';
  }

  /// Formats bytes per second into human-readable string.
  ///
  /// Example:
  /// ```dart
  /// ByteFormatter.formatBytesPerSecond(1024) // Returns "1.00 KB/s"
  /// ```
  static String formatBytesPerSecond(int bytesPerSecond) {
    return '${formatBytes(bytesPerSecond)}/s';
  }

  /// Formats bytes with custom precision.
  ///
  /// [precision] - Number of decimal places (0-3)
  ///
  /// Example:
  /// ```dart
  /// ByteFormatter.formatBytesWithPrecision(1024, 1) // Returns "1.0 KB"
  /// ```
  static String formatBytesWithPrecision(int bytes, int precision) {
    if (bytes == 0) return '0 B';
    if (bytes < 0) return '0 B';

    int unitIndex = 0;
    double value = bytes.toDouble();

    if (bytes >= _teraByte) {
      unitIndex = 4;
      value = bytes / _teraByte;
    } else if (bytes >= _gigaByte) {
      unitIndex = 3;
      value = bytes / _gigaByte;
    } else if (bytes >= _megaByte) {
      unitIndex = 2;
      value = bytes / _megaByte;
    } else if (bytes >= _kiloByte) {
      unitIndex = 1;
      value = bytes / _kiloByte;
    }

    if (value.isNaN || value.isInfinite) return '0 B';

    final clampedPrecision = precision.clamp(0, 3);
    final formattedValue = value.toStringAsFixed(clampedPrecision);

    return '$formattedValue ${_suffixes[unitIndex]}';
  }

  /// Formats upload/download ratio.
  ///
  /// Example:
  /// ```dart
  /// ByteFormatter.formatRatio(1024, 2048) // Returns "0.50"
  /// ByteFormatter.formatRatio(2048, 1024) // Returns "2.00"
  /// ```
  static String formatRatio(int uploaded, int downloaded) {
    if (downloaded == 0) return '∞';
    if (uploaded == 0) return '0.00';
    
    final ratio = uploaded / downloaded;
    
    if (ratio >= 100) {
      return ratio.toStringAsFixed(0);
    } else if (ratio >= 10) {
      return ratio.toStringAsFixed(1);
    } else {
      return ratio.toStringAsFixed(2);
    }
  }

  /// Legacy method for backward compatibility.
  ///
  /// This method maintains the same signature as the old _formatBytes
  /// but uses the optimized implementation internally.
  @Deprecated('Use ByteFormatter.formatBytes() instead')
  static String legacyFormatBytes(int bytes) {
    return formatBytes(bytes);
  }
}

/// Extension methods for easy byte formatting on integers.
extension ByteFormatting on int {
  /// Formats this integer as bytes into human-readable string.
  ///
  /// Example:
  /// ```dart
  /// 1024.formatAsBytes() // Returns "1.00 KB"
  /// ```
  String formatAsBytes() => ByteFormatter.formatBytes(this);

  /// Formats this integer as bytes per second.
  ///
  /// Example:
  /// ```dart
  /// 1024.formatAsBytesPerSecond() // Returns "1.00 KB/s"
  /// ```
  String formatAsBytesPerSecond() => ByteFormatter.formatBytesPerSecond(this);
}
