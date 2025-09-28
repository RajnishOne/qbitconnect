import 'dart:convert';
import 'package:dio/dio.dart';
import '../endpoints/qbittorrent_endpoints.dart';
import '../../models/sync_data.dart';

class StatisticsService {
  StatisticsService(this._dio, this._apiPrefix);

  final Dio _dio;
  final String _apiPrefix;

  /// Fetch main sync data which includes server state and torrent information
  Future<SyncData> fetchMainData({int? rid}) async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.syncMainData,
      ),
      queryParameters: {if (rid != null) 'rid': rid},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        data = jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected data format for sync main data');
      }
      return SyncData.fromMap(data);
    }
    throw Exception('Failed to fetch sync main data: ${response.statusCode}');
  }

  /// Fetch torrent peers information
  Future<Map<String, dynamic>> fetchTorrentPeers(
    String hash, {
    int? rid,
  }) async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.syncTorrentPeers,
      ),
      queryParameters: {'hash': hash, if (rid != null) 'rid': rid},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        data = jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected data format for torrent peers');
      }
      return data;
    }
    throw Exception('Failed to fetch torrent peers: ${response.statusCode}');
  }

  /// Fetch app preferences
  Future<Map<String, dynamic>> fetchAppPreferences() async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.appPreferences,
      ),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        data = jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected data format for app preferences');
      }
      return data;
    }
    throw Exception('Failed to fetch app preferences: ${response.statusCode}');
  }

  /// Fetch app build info
  Future<Map<String, dynamic>> fetchAppBuildInfo() async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.appBuildInfo,
      ),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        data = jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected data format for app build info');
      }
      return data;
    }
    throw Exception('Failed to fetch app build info: ${response.statusCode}');
  }
}
