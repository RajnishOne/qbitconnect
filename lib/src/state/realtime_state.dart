import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/torrent_details.dart';
import '../models/torrent_peer.dart';
import '../widgets/torrent_card_with_selection.dart';

// Callback type for real-time updates
typedef TorrentDetailsUpdateCallback =
    void Function(
      TorrentDetails details,
      List<TorrentFile> files,
      List<TorrentTracker> trackers,
      List<TorrentPeer> peers,
    );

/// Manages real-time updates, polling, and caching
class RealTimeState extends ChangeNotifier {
  Timer? _pollTimer;
  Timer? _cacheCleanupTimer;

  // Real-time updates for torrent details
  final Map<String, TorrentDetailsUpdateCallback> _detailsCallbacks = {};
  final Map<String, Timer> _detailsTimers = {};
  final Map<String, Map<String, dynamic>> _cachedDetails = {};

  // Debouncing for refresh calls
  Timer? _refreshDebounceTimer;

  /// Start polling for torrent list updates
  void startPolling({
    required bool pollingEnabled,
    required int pollingInterval,
    required VoidCallback onRefresh,
  }) {
    if (!pollingEnabled) return;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: pollingInterval), (_) {
      _debouncedRefresh(onRefresh);
    });

    // Start cache cleanup timer (every 5 minutes)
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      TorrentCardCacheManager.cleanupCaches();
    });
  }

  /// Stop polling for torrent list updates
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
  }

  /// Add debouncing to prevent excessive refresh calls
  void _debouncedRefresh(VoidCallback onRefresh) {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 100), onRefresh);
  }

  /// Start real-time updates for a specific torrent
  void startRealTimeUpdates(
    String hash,
    TorrentDetailsUpdateCallback callback, {
    required bool pollingEnabled,
    required int pollingInterval,
    required Future<void> Function(String) updateTorrentDetails,
  }) {
    // If polling is disabled, don't start real-time updates
    if (!pollingEnabled) {
      return;
    }

    // If there's already a timer for this hash, stop it first
    if (_detailsTimers.containsKey(hash)) {
      stopRealTimeUpdates(hash);
    }

    _detailsCallbacks[hash] = callback;

    // Start polling for this specific torrent with configurable interval
    _detailsTimers[hash] = Timer.periodic(Duration(seconds: pollingInterval), (
      _,
    ) {
      updateTorrentDetails(hash);
    });

    // Initial load
    updateTorrentDetails(hash);
  }

  /// Stop real-time updates for a specific torrent
  void stopRealTimeUpdates(String hash) {
    // Remove the callback first
    _detailsCallbacks.remove(hash);

    // Cancel and remove the timer
    final timer = _detailsTimers[hash];
    if (timer != null) {
      timer.cancel();
      _detailsTimers.remove(hash);
    }

    // Clear cached data
    _cachedDetails.remove(hash);
  }

  /// Stop all real-time updates
  void stopAllRealTimeUpdates() {
    // Cancel all timers
    for (final timer in _detailsTimers.values) {
      timer.cancel();
    }

    // Clear all data
    _detailsTimers.clear();
    _detailsCallbacks.clear();
    _cachedDetails.clear();
  }

  /// Check if real-time updates are active for a torrent
  bool isRealTimeUpdatesActive(String hash) {
    return _detailsTimers.containsKey(hash) &&
        _detailsCallbacks.containsKey(hash);
  }

  /// Get count of active real-time updates
  int getActiveRealTimeUpdatesCount() {
    return _detailsTimers.length;
  }

  /// Update torrent details data and notify callback if changed
  void updateTorrentDetailsData(
    String hash,
    TorrentDetails? details,
    List<TorrentFile> files,
    List<TorrentTracker> trackers,
    List<TorrentPeer> peers,
  ) {
    // Multiple safety checks to prevent API calls after cleanup
    if (!_detailsCallbacks.containsKey(hash)) return;
    if (!_detailsTimers.containsKey(hash)) return;

    if (details != null) {
      // Check if data has changed to avoid unnecessary UI updates
      final currentData = {
        'details': details.toMap(),
        'files': files.map((f) => f.toMap()).toList(),
        'trackers': trackers.map((t) => t.toMap()).toList(),
        'peers': peers.map((p) => p.toMap()).toList(),
      };

      final cachedData = _cachedDetails[hash];
      if (cachedData == null || !_mapsEqual(cachedData, currentData)) {
        _cachedDetails[hash] = currentData;
        _detailsCallbacks[hash]?.call(details, files, trackers, peers);
      }
    }
  }

  /// Restart all real-time updates with new interval
  void restartAllRealTimeUpdates({
    required bool pollingEnabled,
    required int pollingInterval,
    required Future<void> Function(String) updateTorrentDetails,
  }) {
    if (!pollingEnabled) {
      stopAllRealTimeUpdates();
      return;
    }

    // Get all active hashes and callbacks before stopping
    final activeHashes = _detailsCallbacks.keys.toList();
    final callbacks = Map<String, TorrentDetailsUpdateCallback>.from(
      _detailsCallbacks,
    );

    // Stop all current real-time updates
    stopAllRealTimeUpdates();

    // Restart all real-time updates with new interval
    for (final hash in activeHashes) {
      final callback = callbacks[hash];
      if (callback != null) {
        startRealTimeUpdates(
          hash,
          callback,
          pollingEnabled: pollingEnabled,
          pollingInterval: pollingInterval,
          updateTorrentDetails: updateTorrentDetails,
        );
      }
    }
  }

  /// Clear all caches
  void clearCaches() {
    // Clear torrent card caches to free memory
    TorrentCardCacheManager.clearCaches();
    TorrentCardCacheManager.cleanupCaches();
  }

  /// Deep comparison of maps for change detection
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;

      final val1 = map1[key];
      final val2 = map2[key];

      if (val1 is Map && val2 is Map) {
        if (!_mapsEqual(
          Map<String, dynamic>.from(val1),
          Map<String, dynamic>.from(val2),
        )) {
          return false;
        }
      } else if (val1 is List && val2 is List) {
        if (val1.length != val2.length) return false;
        for (int i = 0; i < val1.length; i++) {
          if (val1[i] is Map && val2[i] is Map) {
            if (!_mapsEqual(
              Map<String, dynamic>.from(val1[i]),
              Map<String, dynamic>.from(val2[i]),
            )) {
              return false;
            }
          } else if (val1[i] != val2[i]) {
            return false;
          }
        }
      } else if (val1 != val2) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    stopPolling();
    stopAllRealTimeUpdates();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }
}
