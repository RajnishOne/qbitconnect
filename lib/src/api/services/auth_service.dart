import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../endpoints/qbittorrent_endpoints.dart';

class AuthService {
  AuthService(this._dio, this._apiPrefix);

  final Dio _dio;
  final String _apiPrefix;

  /// Login to qBittorrent with username and password
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(_apiPrefix, QbittorrentEndpoints.authLogin),
      data: {'username': username, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200 ||
        (response.data is String && response.data.contains('Fails.'))) {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  /// Login to qBittorrent without credentials (for local network access)
  /// This attempts to access the API without authentication
  Future<void> loginWithoutAuth() async {
    try {
      // Try to access a public endpoint to test if authentication is required
      final response = await _dio.get(
        QbittorrentEndpoints.buildUrl(
          _apiPrefix,
          QbittorrentEndpoints.appVersion,
        ),
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      // If we get a successful response, no authentication is required
      if (response.statusCode == 200) {
        return;
      }

      // If we get 401/403, authentication is required
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Authentication required: ${response.statusCode}');
      }

      // Other status codes might indicate the endpoint doesn't exist
      throw Exception('Unexpected response: ${response.statusCode}');
    } catch (e) {
      // If it's a DioException, check the status code
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw Exception('Authentication required: ${e.response?.statusCode}');
        }
        if (e.response?.statusCode == 404) {
          throw Exception('API endpoint not found: ${e.response?.statusCode}');
        }
      }
      rethrow;
    }
  }

  /// Logout from qBittorrent
  Future<void> logout() async {
    await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.authLogout,
      ),
    );
  }

  /// Get qBittorrent version
  Future<String> getVersion() async {
    try {
      final response = await _dio.get(
        QbittorrentEndpoints.buildUrl(
          _apiPrefix,
          QbittorrentEndpoints.appVersion,
        ),
        options: Options(
          // Use form-encoded content type as required by qBittorrent API
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      if (response.statusCode == 200) {
        return response.data.toString();
      }
    } catch (e) {
      debugPrint('Error fetching qBittorrent version: $e');
      // Re-throw the error so the caller knows it failed
      rethrow;
    }
    return 'Unknown';
  }
}
