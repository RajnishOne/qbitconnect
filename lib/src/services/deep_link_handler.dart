import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'torrent_file_handler.dart';
import '../screens/add_torrent_url_screen.dart';
import '../screens/add_torrent_file_screen.dart';

/// Service to handle deep links and app links
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final StreamController<Uri> _linkController =
      StreamController<Uri>.broadcast();

  /// Stream of incoming deep links
  Stream<Uri> get linkStream => _linkController.stream;

  /// Initialize the deep link handler
  Future<void> initialize() async {
    try {
      // Listen to incoming app links while the app is already started
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _linkController.add(uri);
        },
        onError: (Object err) {
          // Silently handle app link errors
        },
      );

      // Check for initial link (when app is opened from a link)
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _linkController.add(initialUri);
      }
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  /// Dispose the deep link handler
  void dispose() {
    _linkSubscription?.cancel();
    _linkController.close();
  }

  /// Check if a URI is a magnet link
  bool isMagnetLink(Uri uri) {
    return uri.scheme.toLowerCase() == 'magnet';
  }

  /// Check if a URI is a torrent file
  bool isTorrentFile(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final path = uri.path.toLowerCase();

    // For content URIs, we need to be more flexible since they don't always
    // have the file extension in the path. We'll accept content URIs that
    // could potentially be torrent files and let the TorrentFileHandler
    // validate them properly.
    if (scheme == 'content') {
      // Accept content URIs from downloads or external storage providers
      // that could be torrent files
      return uri.authority.contains('downloads') ||
          uri.authority.contains('external') ||
          uri.authority.contains('media') ||
          path.contains('torrent') ||
          path.endsWith('.torrent');
    }

    // For other schemes, check if path ends with .torrent
    return (scheme == 'http' || scheme == 'https' || scheme == 'file') &&
        path.endsWith('.torrent');
  }

  /// Check if a URI is a torrent-related link
  bool isTorrentRelated(Uri uri) {
    return isMagnetLink(uri) || isTorrentFile(uri);
  }

  /// Extract magnet link from URI
  String? extractMagnetLink(Uri uri) {
    if (isMagnetLink(uri)) {
      return uri.toString();
    }
    return null;
  }

  /// Extract torrent URL from URI
  String? extractTorrentUrl(Uri uri) {
    if (isTorrentFile(uri)) {
      return uri.toString();
    }
    return null;
  }

  /// Handle a torrent-related deep link
  Future<void> handleTorrentLink(Uri uri, BuildContext context) async {
    try {
      if (isMagnetLink(uri)) {
        await _handleMagnetLink(uri, context);
      } else if (isTorrentFile(uri)) {
        await _handleTorrentFile(uri, context);
      }
    } catch (e) {
      if (context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error handling torrent link: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (scaffoldError) {
          // Silently handle scaffold errors
        }
      }
    }
  }

  /// Handle magnet link
  Future<void> _handleMagnetLink(Uri uri, BuildContext context) async {
    final magnetLink = extractMagnetLink(uri);
    if (magnetLink == null) return;

    // Navigate to add torrent URL screen with pre-filled magnet link
    if (context.mounted) {
      try {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddTorrentUrlScreen(prefilledUrl: magnetLink),
          ),
        );
      } catch (e) {
        // Silently handle navigation errors
      }
    }
  }

  /// Handle torrent file
  Future<void> _handleTorrentFile(Uri uri, BuildContext context) async {
    // For torrent files, we need to process them through the TorrentFileHandler
    final torrentFileHandler = TorrentFileHandler();
    final filePath = await torrentFileHandler.processTorrentFile(
      uri.toString(),
    );

    if (filePath != null && context.mounted) {
      // Navigate to add torrent file screen with the processed file path
      try {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddTorrentFileScreen(filePath: filePath),
          ),
        );

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Torrent file detected and pre-selected'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        // Silently handle navigation errors
      }
    } else if (context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process torrent file'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        // Silently handle scaffold errors
      }
    }
  }
}
