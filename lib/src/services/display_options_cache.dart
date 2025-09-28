import '../models/torrent_card_display_options.dart';
import 'prefs.dart';

/// Global cache for torrent card display options to avoid repeated async loading
class DisplayOptionsCache {
  static List<TorrentCardDisplayOption>? _cachedOptions;
  static bool _isLoading = false;
  static final List<VoidCallback> _pendingCallbacks = [];
  static final List<VoidCallback> _changeListeners = [];

  /// Get cached display options or load them if not cached
  static List<TorrentCardDisplayOption> getCachedOptions() {
    return _cachedOptions ?? TorrentCardDisplayOption.defaultOptions;
  }

  /// Load display options asynchronously and cache them
  static Future<void> loadOptions() async {
    if (_cachedOptions != null || _isLoading) return;

    _isLoading = true;
    try {
      _cachedOptions = await Prefs.loadTorrentCardDisplayOptions();
    } catch (e) {
      _cachedOptions = TorrentCardDisplayOption.defaultOptions;
    } finally {
      _isLoading = false;
      // Notify all pending callbacks
      for (final callback in _pendingCallbacks) {
        callback();
      }
      _pendingCallbacks.clear();
    }
  }

  /// Update cached options and save to preferences
  static Future<void> updateOptions(
    List<TorrentCardDisplayOption> options,
  ) async {
    _cachedOptions = options;
    await Prefs.saveTorrentCardDisplayOptions(options);

    // Notify all listeners that options have changed
    for (final listener in _changeListeners) {
      listener();
    }
  }

  /// Add a callback to be notified when options are loaded
  static void addLoadCallback(VoidCallback callback) {
    if (_cachedOptions != null) {
      callback();
    } else if (!_isLoading) {
      _pendingCallbacks.add(callback);
      loadOptions();
    } else {
      _pendingCallbacks.add(callback);
    }
  }

  /// Clear the cache (useful for testing or when preferences change)
  static void clearCache() {
    _cachedOptions = null;
  }

  /// Check if options are currently cached
  static bool get isCached => _cachedOptions != null;

  /// Add a listener for option changes
  static void addChangeListener(VoidCallback listener) {
    _changeListeners.add(listener);
  }

  /// Remove a change listener
  static void removeChangeListener(VoidCallback listener) {
    _changeListeners.remove(listener);
  }

  /// Clear all listeners (useful for cleanup)
  static void clearListeners() {
    _changeListeners.clear();
    _pendingCallbacks.clear();
  }
}

typedef VoidCallback = void Function();
