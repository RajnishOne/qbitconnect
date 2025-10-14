import 'package:flutter/material.dart';
import '../utils/byte_formatter.dart';

class TorrentPeer {
  final String ip;
  final int port;
  final String client;
  final int downloaded;
  final int uploaded;
  final int dlSpeed;
  final int upSpeed;
  final double progress;
  final String flags;
  final bool isSeed;
  final int relevance;
  final int filesCount;

  const TorrentPeer({
    required this.ip,
    required this.port,
    required this.client,
    required this.downloaded,
    required this.uploaded,
    required this.dlSpeed,
    required this.upSpeed,
    required this.progress,
    required this.flags,
    required this.isSeed,
    required this.relevance,
    required this.filesCount,
  });

  factory TorrentPeer.fromMap(String ip, Map<String, dynamic> data) {
    return TorrentPeer(
      ip: ip,
      port: data['port'] ?? 0,
      client: (data['client'] ?? '').toString(),
      downloaded: data['downloaded'] ?? 0,
      uploaded: data['uploaded'] ?? 0,
      dlSpeed: data['dl_speed'] ?? 0,
      upSpeed: data['up_speed'] ?? 0,
      progress: (data['progress'] ?? 0.0).toDouble(),
      flags: (data['flags'] ?? '').toString(),
      isSeed: data['is_seed'] ?? false,
      relevance: data['relevance'] ?? 0,
      filesCount: data['files_count'] ?? 0,
    );
  }

  String get formattedDownloaded => ByteFormatter.formatBytes(downloaded);
  String get formattedUploaded => ByteFormatter.formatBytes(uploaded);
  String get formattedDlSpeed => ByteFormatter.formatBytesPerSecond(dlSpeed);
  String get formattedUpSpeed => ByteFormatter.formatBytesPerSecond(upSpeed);
  String get formattedProgress {
    if (progress.isNaN || progress.isInfinite) return '0.0%';
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  String get connectionType {
    if (flags.contains('U')) return 'Upload';
    if (flags.contains('D')) return 'Download';
    if (flags.contains('I')) return 'Interested';
    if (flags.contains('N')) return 'Not interested';
    return 'Unknown';
  }

  Color get connectionColor {
    if (flags.contains('U')) return Colors.green;
    if (flags.contains('D')) return Colors.blue;
    if (flags.contains('I')) return Colors.orange;
    if (flags.contains('N')) return Colors.grey;
    return Colors.grey;
  }

  String get clientName {
    if (client.isEmpty) return 'Unknown';
    return client;
  }

  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'port': port,
      'client': client,
      'downloaded': downloaded,
      'uploaded': uploaded,
      'dl_speed': dlSpeed,
      'up_speed': upSpeed,
      'progress': progress,
      'flags': flags,
      'is_seed': isSeed,
      'relevance': relevance,
      'files_count': filesCount,
    };
  }
}

class TorrentPeersData {
  final int rid;
  final bool fullUpdate;
  final Map<String, TorrentPeer> peers;

  const TorrentPeersData({
    required this.rid,
    required this.fullUpdate,
    required this.peers,
  });

  factory TorrentPeersData.fromMap(Map<String, dynamic> data) {
    final peersMap = <String, TorrentPeer>{};

    if (data['peers'] != null) {
      final peersData = data['peers'] as Map<String, dynamic>;
      for (final entry in peersData.entries) {
        final ip = entry.key;
        final peerData = entry.value as Map<String, dynamic>;
        peersMap[ip] = TorrentPeer.fromMap(ip, peerData);
      }
    }

    return TorrentPeersData(
      rid: data['rid'] ?? 0,
      fullUpdate: data['full_update'] ?? false,
      peers: peersMap,
    );
  }

  List<TorrentPeer> get peersList => peers.values.toList();

  Map<String, dynamic> toMap() {
    return {
      'rid': rid,
      'full_update': fullUpdate,
      'peers': peers.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
