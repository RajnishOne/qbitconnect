import 'dart:convert';
import 'package:dio/dio.dart';
import '../endpoints/qbittorrent_endpoints.dart';

class TorrentDetailsService {
  TorrentDetailsService(this._dio, this._apiPrefix);

  final Dio _dio;
  final String _apiPrefix;

  /// Get torrent properties
  Future<Map<String, dynamic>> getTorrentProperties(String hash) async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsProperties,
      ),
      queryParameters: {'hash': hash},
    );

    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      }
    }
    throw Exception(
      'Failed to fetch torrent properties: ${response.statusCode}',
    );
  }

  /// Get torrent files
  Future<List<Map<String, dynamic>>> getTorrentFiles(String hash) async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsFiles,
      ),
      queryParameters: {'hash': hash},
    );

    if (response.statusCode == 200) {
      List<dynamic> data;
      if (response.data is List) {
        data = response.data as List;
      } else if (response.data is String) {
        data = jsonDecode(response.data) as List;
      } else {
        throw Exception('Unexpected data format for torrent files');
      }
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch torrent files: ${response.statusCode}');
  }

  /// Get torrent trackers
  Future<List<Map<String, dynamic>>> getTorrentTrackers(String hash) async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsTrackers,
      ),
      queryParameters: {'hash': hash},
    );

    if (response.statusCode == 200) {
      List<dynamic> data;
      if (response.data is List) {
        data = response.data as List;
      } else if (response.data is String) {
        data = jsonDecode(response.data) as List;
      } else {
        throw Exception('Unexpected data format for torrent trackers');
      }
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch torrent trackers: ${response.statusCode}');
  }
}
