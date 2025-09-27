import 'dart:convert';
import 'package:dio/dio.dart';
import '../endpoints/qbittorrent_endpoints.dart';
import '../../models/torrent.dart';
import '../../models/transfer_info.dart';
import '../../models/torrent_add_options.dart';

class TorrentService {
  TorrentService(this._dio, this._apiPrefix);

  final Dio _dio;
  final String _apiPrefix;

  /// Fetch all torrents with optional filter and sort
  Future<List<Torrent>> fetchTorrents({
    String? filter,
    String? sort,
    String? sortDirection,
  }) async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsInfo,
      ),
      queryParameters: {
        if (filter != null) 'filter': filter,
        'sort': sort ?? 'name',
        if (sortDirection != null)
          'reverse': sortDirection == 'desc' ? 'true' : 'false',
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      List<Map<String, dynamic>> rawList;
      if (data is List) {
        rawList = data.cast<Map<String, dynamic>>();
      } else if (data is String) {
        final parsed = jsonDecode(data);
        rawList = (parsed as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Unexpected data format for torrents: ${data.runtimeType}',
        );
      }

      final torrents = rawList.map((map) => Torrent.fromMap(map)).toList();
      return torrents;
    }
    throw Exception('Failed to fetch torrents: ${response.statusCode}');
  }

  /// Fetch transfer information
  Future<TransferInfo> fetchTransferInfo() async {
    final response = await _dio.get(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.transferInfo,
      ),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        data = jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected data format for transfer info');
      }
      return TransferInfo.fromMap(data);
    }
    throw Exception('Failed to fetch transfer info: ${response.statusCode}');
  }

  /// Add torrent from file
  Future<void> addTorrentFromFile({
    required String fileName,
    required List<int> bytes,
    TorrentAddOptions? options,
  }) async {
    final optionsMap = options?.toMap() ?? {};
    final formData = <String, dynamic>{
      'torrents': MultipartFile.fromBytes(bytes, filename: fileName),
    };
    formData.addAll(optionsMap);

    final form = FormData.fromMap(formData);

    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsAdd,
      ),
      data: form,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add torrent file');
    }
  }

  /// Add torrent from URL
  Future<void> addTorrentFromUrl({
    required String url,
    TorrentAddOptions? options,
  }) async {
    final optionsMap = options?.toMap() ?? {};
    final formData = <String, dynamic>{'urls': url};
    formData.addAll(optionsMap);

    final form = FormData.fromMap(formData);

    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsAdd,
      ),
      data: form,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add torrent url');
    }
  }

  /// Delete torrents
  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsDelete,
      ),
      data: {
        'hashes': hashes.join('|'),
        'deleteFiles': deleteFiles ? 'true' : 'false',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete torrents: ${response.statusCode} ${response.statusMessage} ${response.data}',
      );
    }
  }

  /// Increase torrent priority (move up in queue)
  Future<void> increaseTorrentPriority(List<String> hashes) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsIncreasePrio,
      ),
      data: {'hashes': hashes.join('|')},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to increase torrent priority: ${response.statusCode}',
      );
    }
  }

  /// Decrease torrent priority (move down in queue)
  Future<void> decreaseTorrentPriority(List<String> hashes) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsDecreasePrio,
      ),
      data: {'hashes': hashes.join('|')},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to decrease torrent priority: ${response.statusCode}',
      );
    }
  }

  /// Move torrent to top of queue
  Future<void> moveTorrentToTop(List<String> hashes) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsTopPrio,
      ),
      data: {'hashes': hashes.join('|')},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to move torrent to top: ${response.statusCode}');
    }
  }

  /// Move torrent to bottom of queue
  Future<void> moveTorrentToBottom(List<String> hashes) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsBottomPrio,
      ),
      data: {'hashes': hashes.join('|')},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to move torrent to bottom: ${response.statusCode}',
      );
    }
  }

  /// Set torrent priority (legacy method)
  Future<void> setTorrentPriority(String hash, int priority) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsIncreasePrio,
      ),
      data: {'hashes': hash},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set torrent priority: ${response.statusCode}');
    }
  }

  /// Set file priority
  Future<void> setFilePriority(
    String hash,
    List<String> fileIds,
    int priority,
  ) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsFilePrio,
      ),
      data: {
        'hash': hash,
        'id': fileIds.join('|'),
        'priority': priority.toString(),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set file priority: ${response.statusCode}');
    }
  }

  /// Recheck torrent
  Future<void> recheckTorrent(String hash) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsRecheck,
      ),
      data: {'hashes': hash},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to recheck torrent: ${response.statusCode}');
    }
  }

  /// Set torrent location
  Future<void> setTorrentLocation(String hash, String location) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsSetLocation,
      ),
      data: {'hashes': hash, 'location': location},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set torrent location: ${response.statusCode}');
    }
  }

  /// Set torrent name
  Future<void> setTorrentName(String hash, String name) async {
    final response = await _dio.post(
      QbittorrentEndpoints.buildUrl(
        _apiPrefix,
        QbittorrentEndpoints.torrentsRename,
      ),
      data: {'hash': hash, 'name': name},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to rename torrent: ${response.statusCode}');
    }
  }
}
