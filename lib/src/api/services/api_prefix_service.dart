import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../endpoints/qbittorrent_endpoints.dart';

class ApiPrefixService {
  ApiPrefixService(this._dio);

  final Dio _dio;
  String _apiPrefix = '';
  bool _prefixResolved = false;

  /// Get the resolved API prefix
  String get apiPrefix => _apiPrefix;

  /// Check if prefix has been resolved
  bool get isResolved => _prefixResolved;

  /// Ensure the API prefix is resolved by testing different configurations
  Future<void> ensureResolved() async {
    if (_prefixResolved) return;

    // Common prefix configurations to try
    final prefixesToTry = ['', '/qbittorrent', '/api'];

    for (final prefix in prefixesToTry) {
      try {
        // Try to get version endpoint (doesn't require authentication)
        final response = await _dio.get(
          QbittorrentEndpoints.buildUrl(
            prefix,
            QbittorrentEndpoints.appVersion,
          ),
          options: Options(
            sendTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 2),
          ),
        );

        // If we get a response (even 401/403), the endpoint exists
        if (response.statusCode != null) {
          _apiPrefix = prefix;
          _prefixResolved = true;
          debugPrint('API prefix resolved: "$prefix" - endpoint accessible');
          return;
        }
      } catch (e) {
        // 401/403 means endpoint exists but requires auth - this is good
        if (e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          _apiPrefix = prefix;
          _prefixResolved = true;
          debugPrint(
            'API prefix resolved: "$prefix" - endpoint exists but requires auth',
          );
          return;
        }
        // 404 means endpoint doesn't exist with this prefix, try next
        if (e is DioException && e.response?.statusCode == 404) {
          debugPrint('API prefix "$prefix" not found, trying next...');
          continue;
        }
        // For other errors (timeout, network), assume this prefix might work
        _apiPrefix = prefix;
        _prefixResolved = true;
        debugPrint(
          'API prefix resolved: "$prefix" - using default after error',
        );
        return;
      }
    }

    // If all prefixes failed, default to empty prefix
    _apiPrefix = '';
    _prefixResolved = true;
    debugPrint('API prefix resolved: empty prefix - using default fallback');
  }

  /// Reset the prefix resolution (useful for testing or reconnection)
  void reset() {
    _prefixResolved = false;
    _apiPrefix = '';
  }

  /// Get current prefix status for debugging
  Map<String, dynamic> getStatus() {
    return {'prefix': _apiPrefix, 'resolved': _prefixResolved};
  }
}
