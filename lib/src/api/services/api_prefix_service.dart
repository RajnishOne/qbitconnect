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

    // Try direct prefix (most common configuration)
    try {
      final response = await _dio.post(
        QbittorrentEndpoints.buildUrl(
          _apiPrefix,
          QbittorrentEndpoints.authLogin,
        ),
        data: {'username': 'dummy_user', 'password': 'dummy_password'},
        options: Options(
          // Reduce timeout for prefix resolution to avoid long delays
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
          // Use form-encoded content type as required by qBittorrent API
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      if (response.statusCode == 200) {
        _prefixResolved = true;
        debugPrint('API prefix resolved: direct (empty prefix) - success');
        return;
      }
    } catch (e) {
      // 403 means endpoint exists but wrong credentials - this is the correct prefix
      if (e is DioException && e.response?.statusCode == 403) {
        _prefixResolved = true;
        debugPrint(
          'API prefix resolved: direct (empty prefix) - endpoint exists but wrong credentials',
        );
        return;
      }
      // For other errors (timeout, network, 404), assume direct prefix is correct
      _prefixResolved = true;
      debugPrint('API prefix resolved: direct (empty prefix) - using default');
    }
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
