import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'client/http_client.dart';
import 'endpoints/qbittorrent_endpoints.dart';
import 'services/api_prefix_service.dart';
import 'services/auth_service.dart';
import 'services/torrent_service.dart';
import 'services/torrent_details_service.dart';
import 'services/statistics_service.dart';
import 'services/endpoint_testing_service.dart';
import '../models/torrent.dart';
import '../models/transfer_info.dart';
import '../models/torrent_add_options.dart';
import '../services/prefs.dart';

class QbittorrentApiClient {
  QbittorrentApiClient({
    required String baseUrl,
    Map<String, String>? defaultHeaders,
    bool enableLogging = true,
  }) : _dio = HttpClientFactory.createClient(
         baseUrl: baseUrl,
         defaultHeaders: defaultHeaders,
         enableLogging: enableLogging,
       ) {
    // Initialize services
    _prefixService = ApiPrefixService(_dio);
    _endpointTestingService = EndpointTestingService(
      _dio,
      _prefixService.apiPrefix,
    );
  }

  final Dio _dio;
  late final ApiPrefixService _prefixService;
  late final EndpointTestingService _endpointTestingService;

  // Lazy-initialized services
  AuthService? _authService;
  TorrentService? _torrentService;
  TorrentDetailsService? _torrentDetailsService;
  StatisticsService? _statisticsService;

  /// Get the auth service
  AuthService get auth =>
      _authService ??= AuthService(_dio, _prefixService.apiPrefix);

  /// Get the torrent service
  TorrentService get torrents =>
      _torrentService ??= TorrentService(_dio, _prefixService.apiPrefix);

  /// Get the torrent details service
  TorrentDetailsService get torrentDetails => _torrentDetailsService ??=
      TorrentDetailsService(_dio, _prefixService.apiPrefix);

  /// Get the statistics service
  StatisticsService get statistics =>
      _statisticsService ??= StatisticsService(_dio, _prefixService.apiPrefix);

  /// Fetch app preferences
  Future<Map<String, dynamic>> fetchAppPreferences() async {
    await _ensureReady();
    return await _withAutoReauth(() => statistics.fetchAppPreferences());
  }

  /// Fetch app build info
  Future<Map<String, dynamic>> fetchAppBuildInfo() async {
    await _ensureReady();
    return await _withAutoReauth(() => statistics.fetchAppBuildInfo());
  }

  /// Ensure API prefix is resolved before making requests
  Future<void> _ensureReady() async {
    await _prefixService.ensureResolved();

    // Update endpoint testing service with resolved prefix if needed
    if (_endpointTestingService.apiPrefix != _prefixService.apiPrefix) {
      _endpointTestingService.updatePrefix(_prefixService.apiPrefix);
    }
  }

  /// Wrapper for API calls that automatically handles re-authentication
  Future<T> _withAutoReauth<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } catch (e) {
      if (_isAuthenticationError(e)) {
        debugPrint(
          'Authentication error detected, attempting automatic re-authentication',
        );
        await _performAutoReauth();
        // Retry the original call after re-authentication
        return await apiCall();
      }
      rethrow;
    }
  }

  /// Check if an error is related to authentication
  bool _isAuthenticationError(dynamic error) {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('login') ||
        errorString.contains('authentication') ||
        errorString.contains('session') ||
        errorString.contains('cookie') ||
        errorString.contains('expired');
  }

  /// Perform automatic re-authentication using saved credentials
  Future<void> _performAutoReauth() async {
    try {
      final username = await Prefs.loadUsername();
      final password = await Prefs.loadPassword();

      if (username != null && password != null && password.isNotEmpty) {
        await auth.login(username: username, password: password);
        debugPrint('Automatic re-authentication successful');
      } else {
        throw Exception(
          'No saved credentials found for automatic re-authentication',
        );
      }
    } catch (e) {
      debugPrint('Automatic re-authentication failed: $e');
      rethrow;
    }
  }

  // Authentication methods
  Future<void> login({
    required String username,
    required String password,
  }) async {
    await auth.login(username: username, password: password);
  }

  Future<void> logout() async {
    await auth.logout();
  }

  Future<String> getVersion() async {
    await _ensureReady();
    return await _withAutoReauth(() => auth.getVersion());
  }

  // Torrent methods with automatic re-authentication
  Future<List<Torrent>> fetchTorrents({
    String? filter,
    String? sort,
    String? sortDirection,
  }) async {
    await _ensureReady();
    return await _withAutoReauth(
      () => torrents.fetchTorrents(
        filter: filter,
        sort: sort,
        sortDirection: sortDirection,
      ),
    );
  }

  Future<TransferInfo> fetchTransferInfo() async {
    await _ensureReady();
    return await _withAutoReauth(() => torrents.fetchTransferInfo());
  }

  Future<void> addTorrentFromFile({
    required String fileName,
    required List<int> bytes,
    TorrentAddOptions? options,
  }) async {
    return await _withAutoReauth(
      () => torrents.addTorrentFromFile(
        fileName: fileName,
        bytes: bytes,
        options: options,
      ),
    );
  }

  Future<void> addTorrentFromUrl({
    required String url,
    TorrentAddOptions? options,
  }) async {
    return await _withAutoReauth(
      () => torrents.addTorrentFromUrl(url: url, options: options),
    );
  }

  Future<void> pauseTorrents(List<String> hashes) async {
    if (hashes.isEmpty || hashes.every((h) => h.isEmpty)) {
      throw Exception('Failed to pause torrents: empty hash list');
    }

    return await _withAutoReauth(() async {
      final joined = hashes.join('|');
      final workingEndpoint = await _endpointTestingService.testPauseEndpoint(
        joined,
      );

      final response = await _dio.post(
        QbittorrentEndpoints.buildUrl(
          _prefixService.apiPrefix,
          workingEndpoint,
        ),
        data: {'hashes': joined},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to pause torrents: ${response.statusCode} ${response.statusMessage} ${response.data}',
        );
      }
    });
  }

  Future<void> resumeTorrents(List<String> hashes) async {
    if (hashes.isEmpty || hashes.every((h) => h.isEmpty)) {
      throw Exception('Failed to resume torrents: empty hash list');
    }

    return await _withAutoReauth(() async {
      final joined = hashes.join('|');
      final workingEndpoint = await _endpointTestingService.testResumeEndpoint(
        joined,
      );

      final response = await _dio.post(
        QbittorrentEndpoints.buildUrl(
          _prefixService.apiPrefix,
          workingEndpoint,
        ),
        data: {'hashes': joined},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to resume torrents: ${response.statusCode} ${response.statusMessage} ${response.data}',
        );
      }
    });
  }

  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    return await _withAutoReauth(
      () => torrents.deleteTorrents(hashes, deleteFiles: deleteFiles),
    );
  }

  // Torrent details methods
  Future<Map<String, dynamic>> getTorrentProperties(String hash) async {
    return await _withAutoReauth(
      () => torrentDetails.getTorrentProperties(hash),
    );
  }

  Future<List<Map<String, dynamic>>> getTorrentFiles(String hash) async {
    return await _withAutoReauth(() => torrentDetails.getTorrentFiles(hash));
  }

  Future<List<Map<String, dynamic>>> getTorrentTrackers(String hash) async {
    return await _withAutoReauth(() => torrentDetails.getTorrentTrackers(hash));
  }

  // Queue management methods
  Future<void> increaseTorrentPriority(List<String> hashes) async {
    return await _withAutoReauth(
      () => torrents.increaseTorrentPriority(hashes),
    );
  }

  Future<void> decreaseTorrentPriority(List<String> hashes) async {
    return await _withAutoReauth(
      () => torrents.decreaseTorrentPriority(hashes),
    );
  }

  Future<void> moveTorrentToTop(List<String> hashes) async {
    return await _withAutoReauth(() => torrents.moveTorrentToTop(hashes));
  }

  Future<void> moveTorrentToBottom(List<String> hashes) async {
    return await _withAutoReauth(() => torrents.moveTorrentToBottom(hashes));
  }

  // Torrent management methods
  Future<void> setTorrentPriority(String hash, int priority) async {
    return await _withAutoReauth(
      () => torrents.setTorrentPriority(hash, priority),
    );
  }

  Future<void> setFilePriority(
    String hash,
    List<String> fileIds,
    int priority,
  ) async {
    return await _withAutoReauth(
      () => torrents.setFilePriority(hash, fileIds, priority),
    );
  }

  Future<void> recheckTorrent(String hash) async {
    return await _withAutoReauth(() => torrents.recheckTorrent(hash));
  }

  Future<void> setTorrentLocation(String hash, String location) async {
    return await _withAutoReauth(
      () => torrents.setTorrentLocation(hash, location),
    );
  }

  Future<void> setTorrentName(String hash, String name) async {
    return await _withAutoReauth(() => torrents.setTorrentName(hash, name));
  }

  // Utility methods
  void clearEndpointCache() {
    _endpointTestingService.clearCache();
  }

  Map<String, String?> getCachedEndpoints() {
    return _endpointTestingService.getCachedEndpoints();
  }

  Map<String, dynamic> getApiStatus() {
    return {
      'prefix': _prefixService.getStatus(),
      'endpoints': getCachedEndpoints(),
    };
  }
}
