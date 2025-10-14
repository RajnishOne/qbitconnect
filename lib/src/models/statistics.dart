class Statistics {
  final int totalUploaded;
  final int totalDownloaded;
  final double shareRatio;
  final int totalPeersConnected;
  final int totalSeeds;
  final int totalLeeches;
  final int totalTorrents;
  final int activeTorrents;
  final int pausedTorrents;
  final int completedTorrents;
  final int downloadingTorrents;
  final int seedingTorrents;
  final int erroredTorrents;
  final int totalSize;
  final int totalDownloadedSize;
  final int totalUploadedSize;
  final int totalWastedSize;
  final DateTime? firstTorrentAdded;
  final DateTime? lastTorrentAdded;
  final int averageDownloadSpeed;
  final int averageUploadSpeed;
  final int peakDownloadSpeed;
  final int peakUploadSpeed;

  // Additional statistics from qBittorrent
  final int sessionWaste;
  final int readCacheHits;
  final int totalBufferSize;
  final double writeCacheOverload;
  final double readCacheOverload;
  final int queuedIoJobs;
  final int averageTimeInQueue;
  final int totalQueuedSize;

  const Statistics({
    required this.totalUploaded,
    required this.totalDownloaded,
    required this.shareRatio,
    required this.totalPeersConnected,
    required this.totalSeeds,
    required this.totalLeeches,
    required this.totalTorrents,
    required this.activeTorrents,
    required this.pausedTorrents,
    required this.completedTorrents,
    required this.downloadingTorrents,
    required this.seedingTorrents,
    required this.erroredTorrents,
    required this.totalSize,
    required this.totalDownloadedSize,
    required this.totalUploadedSize,
    required this.totalWastedSize,
    this.firstTorrentAdded,
    this.lastTorrentAdded,
    required this.averageDownloadSpeed,
    required this.averageUploadSpeed,
    required this.peakDownloadSpeed,
    required this.peakUploadSpeed,
    required this.sessionWaste,
    required this.readCacheHits,
    required this.totalBufferSize,
    required this.writeCacheOverload,
    required this.readCacheOverload,
    required this.queuedIoJobs,
    required this.averageTimeInQueue,
    required this.totalQueuedSize,
  });

  factory Statistics.fromTorrents(List<Map<String, dynamic>> torrents) {
    if (torrents.isEmpty) {
      return Statistics.empty();
    }

    int totalUploaded = 0;
    int totalDownloaded = 0;
    int totalSize = 0;
    int totalDownloadedSize = 0;
    int totalUploadedSize = 0;
    int totalWastedSize = 0;
    int totalPeersConnected = 0;
    int totalSeeds = 0;
    int totalLeeches = 0;
    int activeTorrents = 0;
    int pausedTorrents = 0;
    int completedTorrents = 0;
    int downloadingTorrents = 0;
    int seedingTorrents = 0;
    int erroredTorrents = 0;
    int totalDownloadSpeed = 0;
    int totalUploadSpeed = 0;
    int peakDownloadSpeed = 0;
    int peakUploadSpeed = 0;
    DateTime? firstAdded;
    DateTime? lastAdded;

    for (final torrent in torrents) {
      // Safe type conversion with fallbacks
      final uploaded = _safeToInt(torrent['uploaded']);
      final downloaded = _safeToInt(torrent['downloaded']);
      final size = _safeToInt(torrent['size']);
      final wasted = _safeToInt(torrent['wasted']);
      final dlspeed = _safeToInt(torrent['dlspeed']);
      final upspeed = _safeToInt(torrent['upspeed']);
      final state = (torrent['state'] ?? '').toString().toLowerCase();
      final addedOn = torrent['added_on'];
      final numSeeds = _safeToInt(torrent['num_seeds']);
      final numLeechs = _safeToInt(torrent['num_leechs']);

      totalUploaded += uploaded;
      totalDownloaded += downloaded;
      totalSize += size;
      totalDownloadedSize += downloaded;
      totalUploadedSize += uploaded;
      totalWastedSize += wasted;
      totalDownloadSpeed += dlspeed;
      totalUploadSpeed += upspeed;
      totalSeeds += numSeeds;
      totalLeeches += numLeechs;

      if (dlspeed > peakDownloadSpeed) {
        peakDownloadSpeed = dlspeed;
      }
      if (upspeed > peakUploadSpeed) {
        peakUploadSpeed = upspeed;
      }

      if (state.contains('downloading')) {
        downloadingTorrents++;
      }
      if (state.contains('seeding') ||
          state.contains('upload') ||
          state.contains('up')) {
        seedingTorrents++;
      }
      if (state.contains('paused')) {
        pausedTorrents++;
      }
      if (state.contains('error')) {
        erroredTorrents++;
      }
      if (state.contains('downloading') || state.contains('seeding')) {
        activeTorrents++;
      }
      if (state.contains('complete')) {
        completedTorrents++;
      }

      if (addedOn != null) {
        // torrent.toMap() returns millisecondsSinceEpoch, so no need to multiply by 1000
        final addedDate = DateTime.fromMillisecondsSinceEpoch(
          _safeToInt(addedOn),
        );
        if (firstAdded == null || addedDate.isBefore(firstAdded)) {
          firstAdded = addedDate;
        }
        if (lastAdded == null || addedDate.isAfter(lastAdded)) {
          lastAdded = addedDate;
        }
      }
    }

    totalPeersConnected = totalSeeds + totalLeeches;

    return Statistics(
      totalUploaded: totalUploaded,
      totalDownloaded: totalDownloaded,
      shareRatio: totalDownloaded > 0 ? totalUploaded / totalDownloaded : 0.0,
      totalPeersConnected: totalPeersConnected,
      totalSeeds: totalSeeds,
      totalLeeches: totalLeeches,
      totalTorrents: torrents.length,
      activeTorrents: activeTorrents,
      pausedTorrents: pausedTorrents,
      completedTorrents: completedTorrents,
      downloadingTorrents: downloadingTorrents,
      seedingTorrents: seedingTorrents,
      erroredTorrents: erroredTorrents,
      totalSize: totalSize,
      totalDownloadedSize: totalDownloadedSize,
      totalUploadedSize: totalUploadedSize,
      totalWastedSize: totalWastedSize,
      firstTorrentAdded: firstAdded,
      lastTorrentAdded: lastAdded,
      averageDownloadSpeed: torrents.isNotEmpty
          ? totalDownloadSpeed ~/ torrents.length
          : 0,
      averageUploadSpeed: torrents.isNotEmpty
          ? totalUploadSpeed ~/ torrents.length
          : 0,
      peakDownloadSpeed: peakDownloadSpeed,
      peakUploadSpeed: peakUploadSpeed,
      // Default values for server state statistics (will be updated from sync data)
      sessionWaste: 0,
      readCacheHits: 0,
      totalBufferSize: 0,
      writeCacheOverload: 0.0,
      readCacheOverload: 0.0,
      queuedIoJobs: 0,
      averageTimeInQueue: 0,
      totalQueuedSize: 0,
    );
  }

  /// Create Statistics from torrents, server state, and transfer info data
  factory Statistics.fromTorrentsAndServerState(
    List<Map<String, dynamic>> torrents,
    Map<String, dynamic>? serverState,
    Map<String, dynamic>? transferInfo,
  ) {
    final baseStats = Statistics.fromTorrents(torrents);

    // Extract server state statistics
    final readCacheHits = _safeToInt(serverState?['read_cache_hits']);
    final totalBufferSize = _safeToInt(serverState?['total_buffers_size']);
    final writeCacheOverload = _safeToDouble(
      serverState?['write_cache_overload'],
    );
    final readCacheOverload = _safeToDouble(
      serverState?['read_cache_overload'],
    );
    final queuedIoJobs = _safeToInt(serverState?['queued_io_jobs']);
    final averageTimeInQueue = _safeToInt(serverState?['average_time_queue']);
    final totalQueuedSize = _safeToInt(serverState?['total_queued_size']);

    // All-time statistics should come from server state, not transfer info
    // Transfer info contains session data, server state contains all-time data
    // Try multiple possible field names for different qBittorrent versions
    final allTimeDownloaded = _getAllTimeValue(serverState, [
      'alltime_dl',
      'all_time_dl',
      'total_dl',
    ]);
    final allTimeUploaded = _getAllTimeValue(serverState, [
      'alltime_ul',
      'all_time_ul',
      'total_ul',
    ]);

    // Comprehensive data source prioritization
    // 1. Server state all-time data (most accurate)
    // 2. Transfer info data (session data, but better than base stats)
    // 3. Base stats (calculated from individual torrents - least accurate)
    int finalAllTimeDownloaded;
    int finalAllTimeUploaded;

    // Prioritize server state all-time data - this is the most accurate source
    // Server state contains cumulative all-time statistics from qBittorrent
    // Always use server state data when available, even if values are 0
    if (serverState != null &&
        serverState.containsKey('alltime_dl') &&
        serverState.containsKey('alltime_ul')) {
      // Use server state all-time data (most accurate)
      // This includes cases where alltime_dl or alltime_ul might be 0
      finalAllTimeDownloaded = allTimeDownloaded;
      finalAllTimeUploaded = allTimeUploaded;
    } else if (transferInfo != null) {
      // Fall back to transfer info if server state is not available
      // Transfer info contains session data, not all-time data
      finalAllTimeDownloaded = _safeToInt(transferInfo['dl_info_data']);
      finalAllTimeUploaded = _safeToInt(transferInfo['up_info_data']);
    } else {
      // Last resort: use base stats (calculated from individual torrents)
      // This is the least accurate as it only includes current torrents
      finalAllTimeDownloaded = baseStats.totalDownloaded;
      finalAllTimeUploaded = baseStats.totalUploaded;
    }

    // Session waste - this is the amount of data wasted during the current session
    // Use the total_wasted_session field from server state
    final sessionWaste = _safeToInt(serverState?['total_wasted_session']);

    return Statistics(
      totalUploaded: finalAllTimeUploaded,
      totalDownloaded: finalAllTimeDownloaded,
      shareRatio: finalAllTimeDownloaded > 0
          ? finalAllTimeUploaded / finalAllTimeDownloaded
          : 0.0,
      totalPeersConnected: baseStats.totalPeersConnected,
      totalSeeds: baseStats.totalSeeds,
      totalLeeches: baseStats.totalLeeches,
      totalTorrents: baseStats.totalTorrents,
      activeTorrents: baseStats.activeTorrents,
      pausedTorrents: baseStats.pausedTorrents,
      completedTorrents: baseStats.completedTorrents,
      downloadingTorrents: baseStats.downloadingTorrents,
      seedingTorrents: baseStats.seedingTorrents,
      erroredTorrents: baseStats.erroredTorrents,
      totalSize: baseStats.totalSize,
      totalDownloadedSize: baseStats.totalDownloadedSize,
      totalUploadedSize: baseStats.totalUploadedSize,
      totalWastedSize: baseStats.totalWastedSize,
      firstTorrentAdded: baseStats.firstTorrentAdded,
      lastTorrentAdded: baseStats.lastTorrentAdded,
      averageDownloadSpeed: baseStats.averageDownloadSpeed,
      averageUploadSpeed: baseStats.averageUploadSpeed,
      peakDownloadSpeed: baseStats.peakDownloadSpeed,
      peakUploadSpeed: baseStats.peakUploadSpeed,
      sessionWaste: sessionWaste,
      readCacheHits: readCacheHits,
      totalBufferSize: totalBufferSize,
      writeCacheOverload: writeCacheOverload,
      readCacheOverload: readCacheOverload,
      queuedIoJobs: queuedIoJobs,
      averageTimeInQueue: averageTimeInQueue,
      totalQueuedSize: totalQueuedSize,
    );
  }

  factory Statistics.empty() {
    return const Statistics(
      totalUploaded: 0,
      totalDownloaded: 0,
      shareRatio: 0.0,
      totalPeersConnected: 0,
      totalSeeds: 0,
      totalLeeches: 0,
      totalTorrents: 0,
      activeTorrents: 0,
      pausedTorrents: 0,
      completedTorrents: 0,
      downloadingTorrents: 0,
      seedingTorrents: 0,
      erroredTorrents: 0,
      totalSize: 0,
      totalDownloadedSize: 0,
      totalUploadedSize: 0,
      totalWastedSize: 0,
      averageDownloadSpeed: 0,
      averageUploadSpeed: 0,
      peakDownloadSpeed: 0,
      peakUploadSpeed: 0,
      sessionWaste: 0,
      readCacheHits: 0,
      totalBufferSize: 0,
      writeCacheOverload: 0.0,
      readCacheOverload: 0.0,
      queuedIoJobs: 0,
      averageTimeInQueue: 0,
      totalQueuedSize: 0,
    );
  }

  @override
  String toString() {
    return 'Statistics(totalTorrents: $totalTorrents, shareRatio: $shareRatio)';
  }

  /// Get all-time value from server state, trying multiple field names
  static int _getAllTimeValue(
    Map<String, dynamic>? serverState,
    List<String> fieldNames,
  ) {
    if (serverState == null) return 0;

    for (final fieldName in fieldNames) {
      final value = serverState[fieldName];
      if (value != null) {
        final parsedValue = _safeToInt(value);
        // Return the parsed value even if it's 0, as 0 is a valid all-time value
        return parsedValue;
      }
    }
    return 0;
  }

  /// Safe conversion to int with fallback to 0
  /// Handles large numbers properly for all-time statistics
  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) {
      // Handle potential overflow for very large numbers
      if (value.isInfinite || value.isNaN) return 0;
      return value.toInt();
    }
    if (value is String) {
      // Handle large number strings that might be in scientific notation
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;

      // Try parsing as double first, then convert to int
      final doubleValue = double.tryParse(value);
      if (doubleValue != null &&
          !doubleValue.isInfinite &&
          !doubleValue.isNaN) {
        return doubleValue.toInt();
      }
      return 0;
    }
    return 0;
  }

  /// Safe conversion to double with fallback to 0.0
  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
