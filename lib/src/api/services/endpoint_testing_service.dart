import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../endpoints/qbittorrent_endpoints.dart';

class EndpointTestingService {
  EndpointTestingService(this._dio, this._apiPrefix);

  final Dio _dio;
  String _apiPrefix;

  // Cache for tested endpoints
  String? _cachedPauseEndpoint;
  String? _cachedResumeEndpoint;

  /// Get the current API prefix
  String get apiPrefix => _apiPrefix;

  /// Get the working pause endpoint (v5 by default, legacy only if v5 fails)
  Future<String> testPauseEndpoint(String hashes) async {
    if (_cachedPauseEndpoint != null) {
      return _cachedPauseEndpoint!;
    }

    // Always try v5 first (it's the standard)
    try {
      final response = await _dio.post(
        QbittorrentEndpoints.buildUrl(
          _apiPrefix,
          QbittorrentEndpoints.torrentsStop,
        ),
        data: {'hashes': hashes},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      // If successful or 403 (requires auth), v5 endpoint works
      if (response.statusCode == 200 || response.statusCode == 403) {
        _cachedPauseEndpoint = QbittorrentEndpoints.torrentsStop;
        debugPrint(
          'Using v5 pause endpoint: ${QbittorrentEndpoints.torrentsStop}',
        );
        return _cachedPauseEndpoint!;
      }
    } catch (e) {
      // Only try legacy if v5 returns 404 (endpoint doesn't exist)
      if (e is DioException && e.response?.statusCode == 404) {
        debugPrint('v5 pause endpoint not found, trying legacy...');

        try {
          final legacyResponse = await _dio.post(
            QbittorrentEndpoints.buildUrl(
              _apiPrefix,
              QbittorrentEndpoints.torrentsPause,
            ),
            data: {'hashes': hashes},
            options: Options(contentType: Headers.formUrlEncodedContentType),
          );

          if (legacyResponse.statusCode == 200 ||
              legacyResponse.statusCode == 403) {
            _cachedPauseEndpoint = QbittorrentEndpoints.torrentsPause;
            debugPrint(
              'Using legacy pause endpoint: ${QbittorrentEndpoints.torrentsPause}',
            );
            return _cachedPauseEndpoint!;
          }
        } catch (legacyError) {
          debugPrint('Legacy pause endpoint also failed: $legacyError');
        }
      } else {
        debugPrint('v5 pause endpoint error: $e');
      }
    }

    // Default to v5 (most common)
    _cachedPauseEndpoint = QbittorrentEndpoints.torrentsStop;
    debugPrint(
      'Defaulting to v5 pause endpoint: ${QbittorrentEndpoints.torrentsStop}',
    );
    return _cachedPauseEndpoint!;
  }

  /// Get the working resume endpoint (v5 by default, legacy only if v5 fails)
  Future<String> testResumeEndpoint(String hashes) async {
    if (_cachedResumeEndpoint != null) {
      return _cachedResumeEndpoint!;
    }

    // Always try v5 first (it's the standard)
    try {
      final response = await _dio.post(
        QbittorrentEndpoints.buildUrl(
          _apiPrefix,
          QbittorrentEndpoints.torrentsStart,
        ),
        data: {'hashes': hashes},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      // If successful or 403 (requires auth), v5 endpoint works
      if (response.statusCode == 200 || response.statusCode == 403) {
        _cachedResumeEndpoint = QbittorrentEndpoints.torrentsStart;
        debugPrint(
          'Using v5 resume endpoint: ${QbittorrentEndpoints.torrentsStart}',
        );
        return _cachedResumeEndpoint!;
      }
    } catch (e) {
      // Only try legacy if v5 returns 404 (endpoint doesn't exist)
      if (e is DioException && e.response?.statusCode == 404) {
        debugPrint('v5 resume endpoint not found, trying legacy...');

        try {
          final legacyResponse = await _dio.post(
            QbittorrentEndpoints.buildUrl(
              _apiPrefix,
              QbittorrentEndpoints.torrentsResume,
            ),
            data: {'hashes': hashes},
            options: Options(contentType: Headers.formUrlEncodedContentType),
          );

          if (legacyResponse.statusCode == 200 ||
              legacyResponse.statusCode == 403) {
            _cachedResumeEndpoint = QbittorrentEndpoints.torrentsResume;
            debugPrint(
              'Using legacy resume endpoint: ${QbittorrentEndpoints.torrentsResume}',
            );
            return _cachedResumeEndpoint!;
          }
        } catch (legacyError) {
          debugPrint('Legacy resume endpoint also failed: $legacyError');
        }
      } else {
        debugPrint('v5 resume endpoint error: $e');
      }
    }

    // Default to v5 (most common)
    _cachedResumeEndpoint = QbittorrentEndpoints.torrentsStart;
    debugPrint(
      'Defaulting to v5 resume endpoint: ${QbittorrentEndpoints.torrentsStart}',
    );
    return _cachedResumeEndpoint!;
  }

  /// Clear cached endpoints (useful for testing or when connection changes)
  void clearCache() {
    _cachedPauseEndpoint = null;
    _cachedResumeEndpoint = null;
  }

  /// Update API prefix and clear cache (useful when prefix changes)
  void updatePrefix(String newPrefix) {
    if (_apiPrefix != newPrefix) {
      _apiPrefix = newPrefix;
      clearCache();
      debugPrint('Updated API prefix to: $newPrefix and cleared cache');
    }
  }

  /// Get current cached endpoints for debugging
  Map<String, String?> getCachedEndpoints() {
    return {'pause': _cachedPauseEndpoint, 'resume': _cachedResumeEndpoint};
  }
}
