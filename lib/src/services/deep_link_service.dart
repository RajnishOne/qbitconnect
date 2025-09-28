import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// Service to handle deep links, magnet URLs, and torrent files
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callback function to handle magnet links when app is ready
  Function(String magnetLink)? _onMagnetLinkReceived;

  // Callback function to handle torrent files when app is ready
  Function(String torrentFilePath)? _onTorrentFileReceived;

  // Store magnet link if received before app is ready
  String? _pendingMagnetLink;

  // Store torrent file path if received before app is ready
  String? _pendingTorrentFile;

  /// Initialize the deep link service
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('DeepLinkService: Starting initialization...');
      }

      // Handle app links while app is already started
      _linkSubscription = _appLinks.uriLinkStream.listen(
        _handleIncomingLink,
        onError: (err) {
          if (kDebugMode) {
            print('DeepLinkService: Error handling incoming link: $err');
          }
        },
      );

      // Handle app links while app is in background
      _appLinks.stringLinkStream.listen(
        _handleIncomingStringLink,
        onError: (err) {
          if (kDebugMode) {
            print('DeepLinkService: Error handling incoming string link: $err');
          }
        },
      );

      // Check for initial link (when app is launched via deep link)
      await _handleInitialLink();

      if (kDebugMode) {
        print('DeepLinkService: Initialized successfully');
        print(
          'DeepLinkService: URI link stream active: ${_linkSubscription != null}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLinkService: Initialization error: $e');
      }
    }
  }

  /// Handle initial link when app is launched via deep link
  Future<void> _handleInitialLink() async {
    try {
      if (kDebugMode) {
        print('DeepLinkService: Checking for initial link...');
      }

      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        if (kDebugMode) {
          print('DeepLinkService: Found initial link: $initialUri');
        }
        await _handleIncomingLink(initialUri);
      } else {
        if (kDebugMode) {
          print('DeepLinkService: No initial link found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLinkService: Error getting initial link: $e');
      }
    }
  }

  /// Handle incoming URI link
  Future<void> _handleIncomingLink(Uri uri) async {
    if (kDebugMode) {
      print('DeepLinkService: Received URI link: $uri');
    }

    // Log the deep link event for analytics
    try {
      FirebaseService.instance.logEvent(
        name: 'deep_link_received',
        parameters: {'scheme': uri.scheme, 'host': uri.host, 'path': uri.path},
      );
    } catch (e) {
      // Ignore analytics errors
    }

    // Check if it's a torrent file
    if (_isTorrentFile(uri)) {
      await _processTorrentFile(uri.toString());
    } else {
      // Handle as magnet link
      await _processMagnetLink(uri.toString());
    }
  }

  /// Handle incoming string link
  Future<void> _handleIncomingStringLink(String link) async {
    if (kDebugMode) {
      print('DeepLinkService: Received string link: $link');
    }

    // Log the deep link event for analytics
    try {
      FirebaseService.instance.logEvent(
        name: 'deep_link_received',
        parameters: {'link': link, 'type': 'string'},
      );
    } catch (e) {
      // Ignore analytics errors
    }

    // Check if it's a torrent file
    if (_isTorrentFileFromString(link)) {
      await _processTorrentFile(link);
    } else {
      // Handle as magnet link
      await _processMagnetLink(link);
    }
  }

  /// Check if the URI is a torrent file
  bool _isTorrentFile(Uri uri) {
    // Check for file scheme with .torrent extension
    if (uri.scheme == 'file' && uri.path.toLowerCase().endsWith('.torrent')) {
      return true;
    }

    // Check for content scheme (Android content URIs)
    if (uri.scheme == 'content' && uri.toString().contains('.torrent')) {
      return true;
    }

    return false;
  }

  /// Check if the string link is a torrent file
  bool _isTorrentFileFromString(String link) {
    return link.toLowerCase().contains('.torrent') &&
        (link.startsWith('file://') || link.startsWith('content://'));
  }

  /// Process torrent file
  Future<void> _processTorrentFile(String filePath) async {
    if (kDebugMode) {
      print('DeepLinkService: Processing torrent file: $filePath');
    }

    // Log the torrent file event for analytics
    try {
      FirebaseService.instance.logEvent(
        name: 'torrent_file_received',
        parameters: {'file_path': filePath},
      );
    } catch (e) {
      // Ignore analytics errors
    }

    // If callback is set, use it; otherwise store for later
    if (_onTorrentFileReceived != null) {
      _onTorrentFileReceived!(filePath);
    } else {
      _pendingTorrentFile = filePath;
      if (kDebugMode) {
        print('DeepLinkService: Stored pending torrent file');
      }
    }
  }

  /// Process magnet link
  Future<void> _processMagnetLink(String link) async {
    if (!_isMagnetLink(link)) {
      if (kDebugMode) {
        print('DeepLinkService: Not a magnet link: $link');
      }
      return;
    }

    if (kDebugMode) {
      print('DeepLinkService: Processing magnet link: $link');
    }

    // If callback is set, use it; otherwise store for later
    if (_onMagnetLinkReceived != null) {
      _onMagnetLinkReceived!(link);
    } else {
      _pendingMagnetLink = link;
      if (kDebugMode) {
        print('DeepLinkService: Stored pending magnet link');
      }
    }
  }

  /// Check if the link is a magnet link
  bool _isMagnetLink(String link) {
    return link.toLowerCase().startsWith('magnet:');
  }

  /// Set callback for when magnet links are received
  void setMagnetLinkCallback(Function(String magnetLink) callback) {
    _onMagnetLinkReceived = callback;

    // Process any pending magnet link
    if (_pendingMagnetLink != null) {
      if (kDebugMode) {
        print('DeepLinkService: Processing pending magnet link');
      }
      callback(_pendingMagnetLink!);
      _pendingMagnetLink = null;
    }
  }

  /// Set callback for when torrent files are received
  void setTorrentFileCallback(Function(String torrentFilePath) callback) {
    _onTorrentFileReceived = callback;

    // Process any pending torrent file
    if (_pendingTorrentFile != null) {
      if (kDebugMode) {
        print('DeepLinkService: Processing pending torrent file');
      }
      callback(_pendingTorrentFile!);
      _pendingTorrentFile = null;
    }
  }

  /// Clear the magnet link callback
  void clearMagnetLinkCallback() {
    _onMagnetLinkReceived = null;
  }

  /// Clear the torrent file callback
  void clearTorrentFileCallback() {
    _onTorrentFileReceived = null;
  }

  /// Get pending magnet link if any
  String? getPendingMagnetLink() {
    return _pendingMagnetLink;
  }

  /// Get pending torrent file if any
  String? getPendingTorrentFile() {
    return _pendingTorrentFile;
  }

  /// Clear pending magnet link
  void clearPendingMagnetLink() {
    _pendingMagnetLink = null;
  }

  /// Clear pending torrent file
  void clearPendingTorrentFile() {
    _pendingTorrentFile = null;
  }

  /// Test method to simulate receiving a magnet link (for debugging)
  void testMagnetLink(String magnetLink) {
    if (kDebugMode) {
      print('DeepLinkService: Testing magnet link: $magnetLink');
    }
    _processMagnetLink(magnetLink);
  }

  /// Test method to simulate receiving a torrent file (for debugging)
  void testTorrentFile(String torrentFilePath) {
    if (kDebugMode) {
      print('DeepLinkService: Testing torrent file: $torrentFilePath');
    }
    _processTorrentFile(torrentFilePath);
  }

  /// Get debug information about the service state
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasMagnetCallback': _onMagnetLinkReceived != null,
      'hasTorrentCallback': _onTorrentFileReceived != null,
      'hasPendingMagnetLink': _pendingMagnetLink != null,
      'hasPendingTorrentFile': _pendingTorrentFile != null,
      'pendingMagnetLink': _pendingMagnetLink,
      'pendingTorrentFile': _pendingTorrentFile,
      'subscriptionActive': _linkSubscription != null,
    };
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
    _onMagnetLinkReceived = null;
    _onTorrentFileReceived = null;
    _pendingMagnetLink = null;
    _pendingTorrentFile = null;
  }
}

