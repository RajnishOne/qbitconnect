import 'package:flutter/material.dart';
import '../utils/format_utils.dart';
import '../utils/byte_formatter.dart';

class TorrentDetails {
  final String hash;
  final String name;
  final String savePath;
  final DateTime creationDate;
  final String comment;
  final int totalWasted;
  final int totalUploaded;
  final int totalDownloaded;
  final int upLimit;
  final int dlLimit;
  final int timeElapsed;
  final int seedingTime;
  final int nbConnections;
  final int nbConnectionsLimit;
  final double shareRatio;
  final DateTime additionDate;
  final DateTime completionDate;
  final String createdBy;
  final int dlSpeedAvg;
  final int dlSpeed;
  final int upSpeedAvg;
  final int upSpeed;
  final int eta;
  final String lastSeen;

  final int seeds;
  final int leeches;
  final int piecesHave;
  final int piecesNum;
  final int pieceSize;
  final double progress;
  final String state;
  final bool forceStart;
  final bool autoTmm;
  final bool sequentialDownload;
  final bool firstLastPiecePriority;
  final bool isPrivate;
  final bool isPaused;
  final bool isStopped;
  final bool isErrored;

  const TorrentDetails({
    required this.hash,
    required this.name,
    required this.savePath,
    required this.creationDate,
    required this.comment,
    required this.totalWasted,
    required this.totalUploaded,
    required this.totalDownloaded,
    required this.upLimit,
    required this.dlLimit,
    required this.timeElapsed,
    required this.seedingTime,
    required this.nbConnections,
    required this.nbConnectionsLimit,
    required this.shareRatio,
    required this.additionDate,
    required this.completionDate,
    required this.createdBy,
    required this.dlSpeedAvg,
    required this.dlSpeed,
    required this.upSpeedAvg,
    required this.upSpeed,
    required this.eta,
    required this.lastSeen,

    required this.seeds,
    required this.leeches,
    required this.piecesHave,
    required this.piecesNum,
    required this.pieceSize,
    required this.progress,
    required this.state,
    required this.forceStart,
    required this.autoTmm,
    required this.sequentialDownload,
    required this.firstLastPiecePriority,
    required this.isPrivate,
    required this.isPaused,
    required this.isStopped,
    required this.isErrored,
  });

  factory TorrentDetails.fromMap(Map<String, dynamic> map) {
    return TorrentDetails(
      hash: (map['hash'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      savePath: (map['save_path'] ?? '').toString(),
      creationDate: DateTime.fromMillisecondsSinceEpoch(
        (map['creation_date'] ?? 0) * 1000,
      ),
      comment: (map['comment'] ?? '').toString(),
      totalWasted: map['total_wasted'] ?? 0,
      totalUploaded: map['total_uploaded'] ?? 0,
      totalDownloaded: map['total_downloaded'] ?? 0,
      upLimit: map['up_limit'] ?? 0,
      dlLimit: map['dl_limit'] ?? 0,
      timeElapsed: map['time_elapsed'] ?? 0,
      seedingTime: map['seeding_time'] ?? 0,
      nbConnections: map['nb_connections'] ?? 0,
      nbConnectionsLimit: map['nb_connections_limit'] ?? 0,
      shareRatio: (map['share_ratio'] ?? 0.0).toDouble(),
      additionDate: FormatUtils.parseQbittorrentTimestamp(map['addition_date']),
      completionDate: FormatUtils.parseQbittorrentTimestamp(
        map['completion_date'],
      ),
      createdBy: (map['created_by'] ?? '').toString(),
      dlSpeedAvg: _safeIntConversion(map['dl_speed_avg']),
      dlSpeed: _safeIntConversion(map['dl_speed']),
      upSpeedAvg: _safeIntConversion(map['up_speed_avg']),
      upSpeed: _safeIntConversion(map['up_speed']),
      eta: map['eta'] ?? 0,
      lastSeen: (map['last_seen'] ?? '').toString(),

      seeds: map['seeds'] ?? 0,
      leeches: map['leeches'] ?? 0,
      piecesHave: map['pieces_have'] ?? 0,
      piecesNum: map['pieces_num'] ?? 0,
      pieceSize: map['piece_size'] ?? 0,
      progress: (map['progress'] ?? 0.0).toDouble(),
      state: (map['state'] ?? '').toString(),
      forceStart: map['force_start'] ?? false,
      autoTmm: map['auto_tmm'] ?? false,
      sequentialDownload: map['sequential_download'] ?? false,
      firstLastPiecePriority: map['first_last_piece_priority'] ?? false,
      isPrivate: map['is_private'] ?? false,
      isPaused: map['is_paused'] ?? false,
      isStopped: map['is_stopped'] ?? false,
      isErrored: map['is_errored'] ?? false,
    );
  }

  String get formattedSize => ByteFormatter.formatBytes(totalDownloaded);
  String get formattedUploaded => ByteFormatter.formatBytes(totalUploaded);
  String get formattedWasted => ByteFormatter.formatBytes(totalWasted);
  String get formattedDlSpeed => ByteFormatter.formatBytesPerSecond(dlSpeed);
  String get formattedUpSpeed => ByteFormatter.formatBytesPerSecond(upSpeed);
  String get formattedDlSpeedAvg =>
      ByteFormatter.formatBytesPerSecond(dlSpeedAvg);
  String get formattedUpSpeedAvg =>
      ByteFormatter.formatBytesPerSecond(upSpeedAvg);
  String get formattedEta => _formatDuration(eta);
  String get formattedTimeElapsed => _formatDuration(timeElapsed);
  String get formattedSeedingTime => _formatDuration(seedingTime);
  String get formattedPieceSize => ByteFormatter.formatBytes(pieceSize);

  static int _safeIntConversion(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return 0;
      return value.toInt();
    }
    try {
      final intValue = int.parse(value.toString());
      return intValue;
    } catch (e) {
      return 0;
    }
  }

  static String _formatDuration(int seconds) {
    if (seconds < 0) return '∞';
    if (seconds == 0) return '0s';

    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'hash': hash,
      'name': name,
      'save_path': savePath,
      'creation_date': creationDate.millisecondsSinceEpoch ~/ 1000,
      'comment': comment,
      'total_wasted': totalWasted,
      'total_uploaded': totalUploaded,
      'total_downloaded': totalDownloaded,
      'up_limit': upLimit,
      'dl_limit': dlLimit,
      'time_elapsed': timeElapsed,
      'seeding_time': seedingTime,
      'nb_connections': nbConnections,
      'nb_connections_limit': nbConnectionsLimit,
      'share_ratio': shareRatio,
      'addition_date': additionDate.millisecondsSinceEpoch ~/ 1000,
      'completion_date': completionDate.millisecondsSinceEpoch ~/ 1000,
      'created_by': createdBy,
      'dl_speed_avg': dlSpeedAvg,
      'dl_speed': dlSpeed,
      'up_speed_avg': upSpeedAvg,
      'up_speed': upSpeed,
      'eta': eta,
      'last_seen': lastSeen,

      'seeds': seeds,
      'leeches': leeches,
      'pieces_have': piecesHave,
      'pieces_num': piecesNum,
      'piece_size': pieceSize,
      'progress': progress,
      'state': state,
      'force_start': forceStart,
      'auto_tmm': autoTmm,
      'sequential_download': sequentialDownload,
      'first_last_piece_priority': firstLastPiecePriority,
      'is_private': isPrivate,
      'is_paused': isPaused,
      'is_stopped': isStopped,
      'is_errored': isErrored,
    };
  }
}

class TorrentFile {
  final String name;
  final int size;
  final double progress;
  final int priority;
  final bool isSeed;
  final int pieceRangeStart;
  final int pieceRangeEnd;

  const TorrentFile({
    required this.name,
    required this.size,
    required this.progress,
    required this.priority,
    required this.isSeed,
    required this.pieceRangeStart,
    required this.pieceRangeEnd,
  });

  factory TorrentFile.fromMap(Map<String, dynamic> map) {
    return TorrentFile(
      name: (map['name'] ?? '').toString(),
      size: map['size'] ?? 0,
      progress: (map['progress'] ?? 0.0).toDouble(),
      priority: map['priority'] ?? 0,
      isSeed: map['is_seed'] ?? false,
      pieceRangeStart: map['piece_range_start'] ?? 0,
      pieceRangeEnd: map['piece_range_end'] ?? 0,
    );
  }

  String get formattedSize => ByteFormatter.formatBytes(size);
  String get formattedProgress {
    if (progress.isNaN || progress.isInfinite) return '0.0%';
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  String get priorityText {
    switch (priority) {
      case 0:
        return 'Do not download';
      case 1:
        return 'Normal';
      case 6:
        return 'High';
      case 7:
        return 'Maximum';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'size': size,
      'progress': progress,
      'priority': priority,
      'is_seed': isSeed,
      'piece_range_start': pieceRangeStart,
      'piece_range_end': pieceRangeEnd,
    };
  }
}

class TorrentTracker {
  final String url;
  final String status;
  final int tier;
  final int numPeers;
  final int numSeeds;
  final int numLeeches;
  final int numDownloaded;
  final String msg;

  const TorrentTracker({
    required this.url,
    required this.status,
    required this.tier,
    required this.numPeers,
    required this.numSeeds,
    required this.numLeeches,
    required this.numDownloaded,
    required this.msg,
  });

  factory TorrentTracker.fromMap(Map<String, dynamic> map) {
    return TorrentTracker(
      url: (map['url'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      tier: map['tier'] ?? 0,
      numPeers: map['num_peers'] ?? 0,
      numSeeds: map['num_seeds'] ?? 0,
      numLeeches: map['num_leeches'] ?? 0,
      numDownloaded: map['num_downloaded'] ?? 0,
      msg: (map['msg'] ?? '').toString(),
    );
  }

  String get statusText {
    // qBittorrent returns numeric status codes
    switch (status) {
      case '0':
        return 'Disabled';
      case '1':
        return 'Not contacted';
      case '2':
        return 'Working';
      case '3':
        return 'Updating';
      case '4':
        return 'Error';
      default:
        return status; // Return original if unknown
    }
  }

  Color get statusColor {
    switch (status) {
      case '0':
        return Colors.grey;
      case '1':
        return Colors.orange;
      case '2':
        return Colors.green;
      case '3':
        return Colors.blue;
      case '4':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'status': status,
      'tier': tier,
      'num_peers': numPeers,
      'num_seeds': numSeeds,
      'num_leeches': numLeeches,
      'num_downloaded': numDownloaded,
      'msg': msg,
    };
  }
}
