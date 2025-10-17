import 'package:flutter/foundation.dart';

/// State management for batch selection operations
/// This class handles the selection state for torrents and provides
/// methods for batch operations that can be easily extended
class BatchSelectionState extends ChangeNotifier {
  // Selected torrent hashes
  final Set<String> _selectedHashes = {};

  // Selection mode state
  bool _isSelectionMode = false;

  // Quick selection states
  bool _isSelectAllMode = false;
  bool _isInvertSelectionMode = false;

  // Filter for selection (to support filtered selection)
  String _currentFilter = 'all';
  String _currentCategory = 'all';
  String _currentSearchQuery = '';

  // Callback to get filtered torrents
  List<String> Function()? _getFilteredHashesCallback;

  // Getters
  Set<String> get selectedHashes => Set.unmodifiable(_selectedHashes);
  bool get isSelectionMode => _isSelectionMode;
  bool get hasSelection => _selectedHashes.isNotEmpty;
  int get selectionCount => _selectedHashes.length;
  bool get isSelectAllMode => _isSelectAllMode;
  bool get isInvertSelectionMode => _isInvertSelectionMode;

  /// Initialize the batch selection state
  void initialize({
    required String currentFilter,
    required String currentCategory,
    required String currentSearchQuery,
    required List<String> Function() getFilteredHashesCallback,
  }) {
    _currentFilter = currentFilter;
    _currentCategory = currentCategory;
    _currentSearchQuery = currentSearchQuery;
    _getFilteredHashesCallback = getFilteredHashesCallback;
  }

  /// Update filter state (called when filters change)
  void updateFilterState({
    String? filter,
    String? category,
    String? searchQuery,
  }) {
    bool shouldClearSelection = false;

    if (filter != null && filter != _currentFilter) {
      _currentFilter = filter;
      shouldClearSelection = true;
    }

    if (category != null && category != _currentCategory) {
      _currentCategory = category;
      shouldClearSelection = true;
    }

    if (searchQuery != null && searchQuery != _currentSearchQuery) {
      _currentSearchQuery = searchQuery;
      shouldClearSelection = true;
    }

    if (shouldClearSelection && _isSelectionMode) {
      clearSelection();
    }
  }

  /// Enter selection mode
  void enterSelectionMode() {
    if (!_isSelectionMode) {
      _isSelectionMode = true;
      _selectedHashes.clear();
      notifyListeners();
    }
  }

  /// Exit selection mode
  void exitSelectionMode() {
    if (_isSelectionMode) {
      _isSelectionMode = false;
      _selectedHashes.clear();
      _isSelectAllMode = false;
      _isInvertSelectionMode = false;
      notifyListeners();
    }
  }

  /// Toggle selection for a specific torrent
  void toggleSelection(String hash) {
    if (!_isSelectionMode) {
      enterSelectionMode();
    }

    if (_selectedHashes.contains(hash)) {
      _selectedHashes.remove(hash);
    } else {
      _selectedHashes.add(hash);
    }

    // Exit selection mode if no items are selected
    if (_selectedHashes.isEmpty) {
      exitSelectionMode();
    } else {
      notifyListeners();
    }
  }

  /// Select a specific torrent
  void selectTorrent(String hash) {
    if (!_isSelectionMode) {
      enterSelectionMode();
    }

    if (!_selectedHashes.contains(hash)) {
      _selectedHashes.add(hash);
      notifyListeners();
    }
  }

  /// Deselect a specific torrent
  void deselectTorrent(String hash) {
    if (_selectedHashes.remove(hash)) {
      if (_selectedHashes.isEmpty) {
        exitSelectionMode();
      } else {
        notifyListeners();
      }
    }
  }

  /// Select all torrents (based on current filter)
  void selectAll() {
    if (_getFilteredHashesCallback == null) return;

    if (!_isSelectionMode) {
      enterSelectionMode();
    }

    final filteredHashes = _getFilteredHashesCallback!();
    _selectedHashes.addAll(filteredHashes);
    _isSelectAllMode = true;
    notifyListeners();
  }

  /// Deselect all torrents
  void deselectAll() {
    _selectedHashes.clear();
    _isSelectAllMode = false;
    _isInvertSelectionMode = false;

    // Since we just cleared the selection, always exit selection mode
    exitSelectionMode();
  }

  /// Invert current selection
  void invertSelection() {
    if (_getFilteredHashesCallback == null) return;

    if (!_isSelectionMode) {
      enterSelectionMode();
    }

    final filteredHashes = _getFilteredHashesCallback!();
    final newSelection = <String>{};

    for (final hash in filteredHashes) {
      if (!_selectedHashes.contains(hash)) {
        newSelection.add(hash);
      }
    }

    _selectedHashes.clear();
    _selectedHashes.addAll(newSelection);
    _isInvertSelectionMode = true;

    if (_selectedHashes.isEmpty) {
      exitSelectionMode();
    } else {
      notifyListeners();
    }
  }

  /// Clear current selection
  void clearSelection() {
    _selectedHashes.clear();
    _isSelectAllMode = false;
    _isInvertSelectionMode = false;
    exitSelectionMode();
  }

  /// Check if a torrent is selected
  bool isSelected(String hash) {
    return _selectedHashes.contains(hash);
  }

  /// Get selection summary for display
  String getSelectionSummary() {
    if (!hasSelection) return '';

    final count = selectionCount;
    if (count == 1) {
      return '1 torrent selected';
    } else {
      return '$count torrents selected';
    }
  }

  /// Get selection statistics
  Map<String, dynamic> getSelectionStats() {
    return {
      'count': selectionCount,
      'isSelectionMode': isSelectionMode,
      'hasSelection': hasSelection,
      'isSelectAllMode': isSelectAllMode,
      'isInvertSelectionMode': isInvertSelectionMode,
    };
  }

  /// Reset all state (useful for app restart or major state changes)
  void reset() {
    _selectedHashes.clear();
    _isSelectionMode = false;
    _isSelectAllMode = false;
    _isInvertSelectionMode = false;
    _currentFilter = 'all';
    _currentCategory = 'all';
    _currentSearchQuery = '';
    _getFilteredHashesCallback = null;
    notifyListeners();
  }
}
