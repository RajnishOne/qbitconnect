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
        (response.data is String &&
            (response.data as String).contains('Fails.'))) {
      throw Exception('Login failed: ${response.statusCode}');
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
