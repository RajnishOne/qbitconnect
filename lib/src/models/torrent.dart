import 'package:flutter/material.dart';

class Torrent {
  final String hash;
  final String name;
  final String state;
  final double progress;
  final int size;
  final int downloaded;
  final int uploaded;
  final int dlspeed;
  final int upspeed;
  final int numSeeds;
  final int numLeechs;
  final int numComplete;
  final int numIncomplete;
  final int ratio;
  final int eta;
  final String savePath;
  final DateTime addedOn;
  final DateTime? completionOn;
  final bool isPrivate;
  final bool isSequential;
  final bool isFirstLastPiecePriority;
  final bool autoTmm;
  final bool forceStart;
  final bool isPaused;
  final bool isStopped;
  final bool isErrored;
  final String category;

  const Torrent({
    required this.hash,
    required this.name,
    required this.state,
    required this.progress,
    required this.size,
    required this.downloaded,
    required this.uploaded,
    required this.dlspeed,
    required this.upspeed,
    required this.numSeeds,
    required this.numLeechs,
    required this.numComplete,
    required this.numIncomplete,
    required this.ratio,
    required this.eta,
    required this.savePath,
    required this.addedOn,
    this.completionOn,
    required this.isPrivate,
    required this.isSequential,
    required this.isFirstLastPiecePriority,
    required this.autoTmm,
    required this.forceStart,
    required this.isPaused,
    required this.isStopped,
    required this.isErrored,
    required this.category,
  });

  factory Torrent.fromMap(Map<String, dynamic> map) {
    try {
      final state = (map['state'] ?? '').toString();
      final stateLower = state.toLowerCase();

      // Helper function to safely convert to int
      int safeInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) {
          if (value.isNaN || value.isInfinite) return 0;
          return value.toInt();
        }
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      // Helper function to safely convert timestamps
      DateTime safeDateTime(dynamic value) {
        if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
        final timestamp = safeInt(value);
        // qBittorrent API returns timestamps in seconds, not milliseconds
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }

      return Torrent(
        hash: (map['hash'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        state: state,
        progress: (map['progress'] is num)
            ? (map['progress'] as num).toDouble()
            : 0.0,
        size: safeInt(map['size']),
        downloaded: safeInt(map['downloaded']),
        uploaded: safeInt(map['uploaded']),
        dlspeed: safeInt(map['dlspeed']),
        upspeed: safeInt(map['upspeed']),
        numSeeds: safeInt(map['num_seeds']),
        numLeechs: safeInt(map['num_leechs']),
        numComplete: safeInt(map['num_complete']),
        numIncomplete: safeInt(map['num_incomplete']),
        ratio: safeInt(map['ratio']),
        eta: safeInt(map['eta']),
        savePath: (map['save_path'] ?? '').toString(),
        addedOn: safeDateTime(map['added_on']),
        completionOn: map['completion_on'] != null
            ? safeDateTime(map['completion_on'])
            : null,
        isPrivate: (map['is_private'] ?? false) as bool,
        isSequential: (map['is_sequential'] ?? false) as bool,
        isFirstLastPiecePriority:
            (map['is_first_last_piece_priority'] ?? false) as bool,
        autoTmm: (map['auto_tmm'] ?? false) as bool,
        forceStart: (map['force_start'] ?? false) as bool,
        isPaused: stateLower.contains('paused'),
        isStopped: stateLower.contains('stopped'),
        isErrored: stateLower.contains('error'),
        category: (map['category'] ?? '').toString(),
      );
    } catch (e) {
      throw Exception('Failed to parse torrent data: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'hash': hash,
      'name': name,
      'state': state,
      'progress': progress,
      'size': size,
      'downloaded': downloaded,
      'uploaded': uploaded,
      'dlspeed': dlspeed,
      'upspeed': upspeed,
      'num_seeds': numSeeds,
      'num_leechs': numLeechs,
      'num_complete': numComplete,
      'num_incomplete': numIncomplete,
      'ratio': ratio,
      'eta': eta,
      'save_path': savePath,
      'added_on': addedOn.millisecondsSinceEpoch,
      'completion_on': completionOn?.millisecondsSinceEpoch,
      'is_private': isPrivate,
      'is_sequential': isSequential,
      'is_first_last_piece_priority': isFirstLastPiecePriority,
      'auto_tmm': autoTmm,
      'force_start': forceStart,
      'category': category,
    };
  }

  bool get isStoppedOrPaused => isPaused || isStopped;
  bool get isActive => dlspeed > 0 || upspeed > 0;
  bool get isCompleted =>
      progress >= 1.0 && !(state.contains('upload') || state.contains('seed'));
  bool get isSeeding =>
      state.contains('upload') || state.contains('seed') || upspeed > 0;
  bool get isDownloading => state.contains('down') && !isPaused;
  bool get isStalled => state.contains('stalled');

  /// Get color for the torrent state
  Color get stateColor {
    final stateLower = state.toLowerCase();

    if (stateLower.contains('download') && !stateLower.contains('paused')) {
      return const Color(0xFF4CAF50); // Green for downloading
    } else if (stateLower.contains('upload') || stateLower.contains('seed')) {
      return const Color(0xFF2196F3); // Blue for seeding
    } else if (stateLower.contains('paused')) {
      return const Color(0xFF9E9E9E); // Gray for paused
    } else if (stateLower.contains('stalled')) {
      return const Color(0xFFFF9800); // Orange for stalled
    } else if (stateLower.contains('error')) {
      return const Color(0xFFF44336); // Red for error
    } else if (stateLower.contains('check')) {
      return const Color(0xFF9C27B0); // Purple for checking
    } else if (stateLower.contains('queue')) {
      return const Color(0xFF607D8B); // Blue gray for queued
    } else {
      return const Color(0xFF757575); // Default gray
    }
  }

  /// Get user-friendly display name for the category
  String get displayCategory {
    if (category.isEmpty) return 'Uncategorized';
    return category;
  }

  /// Get user-friendly display name for the torrent state
  String get displayState {
    final stateLower = state.toLowerCase();

    // Handle common qBittorrent states
    switch (stateLower) {
      case 'allocating':
        return 'Allocating';
      case 'downloading':
        return 'Downloading';
      case 'metadl':
        return 'Downloading metadata';
      case 'pauseddl':
        return 'Paused';
      case 'queueddl':
        return 'Queued for download';
      case 'stalledDL':
      case 'stalleddl':
        return 'Stalled (no seeds)';
      case 'uploading':
        return 'Seeding';
      case 'stalledUP':
      case 'stalledup':
        return 'Seeding';
      case 'stoppeddl':
        return 'Stopped';
      case 'queuedUP':
      case 'queuedup':
        return 'Queued for seeding';
      case 'pausedup':
      case 'stoppedup':
        return 'Completed';
      case 'checkingUP':
      case 'checkingup':
        return 'Checking';
      case 'checkingdl':
        return 'Checking';
      case 'error':
        return 'Error';
      case 'missingfiles':
        return 'Missing files';
      case 'queuedforechecking':
        return 'Queued for checking';
      case 'checkingresumedata':
        return 'Checking resume data';
      case 'moving':
        return 'Moving';
      case 'unknown':
        return 'Unknown';
      default:
        // For any unknown states, try to make them more readable
        if (stateLower.contains('paused')) return 'Paused';
        if (stateLower.contains('stalled')) return 'Stalled';
        if (stateLower.contains('download')) return 'Downloading';
        if (stateLower.contains('upload')) return 'Seeding';
        if (stateLower.contains('seed')) return 'Seeding';
        if (stateLower.contains('check')) return 'Checking';
        if (stateLower.contains('queue')) return 'Queued';
        if (stateLower.contains('error')) return 'Error';

        // Fallback: capitalize first letter
        return state.isNotEmpty
            ? '${state[0].toUpperCase()}${state.substring(1).toLowerCase()}'
            : 'Unknown';
    }
  }

  Torrent copyWith({
    String? hash,
    String? name,
    String? state,
    double? progress,
    int? size,
    int? downloaded,
    int? uploaded,
    int? dlspeed,
    int? upspeed,
    int? numSeeds,
    int? numLeechs,
    int? numComplete,
    int? numIncomplete,
    int? ratio,
    int? eta,
    String? savePath,
    DateTime? addedOn,
    DateTime? completionOn,
    bool? isPrivate,
    bool? isSequential,
    bool? isFirstLastPiecePriority,
    bool? autoTmm,
    bool? forceStart,
    bool? isPaused,
    bool? isStopped,
    bool? isErrored,
    String? category,
  }) {
    return Torrent(
      hash: hash ?? this.hash,
      name: name ?? this.name,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      size: size ?? this.size,
      downloaded: downloaded ?? this.downloaded,
      uploaded: uploaded ?? this.uploaded,
      dlspeed: dlspeed ?? this.dlspeed,
      upspeed: upspeed ?? this.upspeed,
      numSeeds: numSeeds ?? this.numSeeds,
      numLeechs: numLeechs ?? this.numLeechs,
      numComplete: numComplete ?? this.numComplete,
      numIncomplete: numIncomplete ?? this.numIncomplete,
      ratio: ratio ?? this.ratio,
      eta: eta ?? this.eta,
      savePath: savePath ?? this.savePath,
      addedOn: addedOn ?? this.addedOn,
      completionOn: completionOn ?? this.completionOn,
      isPrivate: isPrivate ?? this.isPrivate,
      isSequential: isSequential ?? this.isSequential,
      isFirstLastPiecePriority:
          isFirstLastPiecePriority ?? this.isFirstLastPiecePriority,
      autoTmm: autoTmm ?? this.autoTmm,
      forceStart: forceStart ?? this.forceStart,
      isPaused: isPaused ?? this.isPaused,
      isStopped: isStopped ?? this.isStopped,
      isErrored: isErrored ?? this.isErrored,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Torrent && other.hash == hash;
  }

  @override
  int get hashCode => hash.hashCode;

  @override
  String toString() {
    return 'Torrent(hash: $hash, name: $name, state: $state, progress: $progress)';
  }
}
