class QbittorrentEndpoints {
  static const String _basePath = 'api/v2';

  // App endpoints
  static const String appVersion = '$_basePath/app/version';
  static const String authLogin = '$_basePath/auth/login';
  static const String authLogout = '$_basePath/auth/logout';

  // Transfer endpoints
  static const String transferInfo = '$_basePath/transfer/info';

  // Torrent endpoints
  static const String torrentsInfo = '$_basePath/torrents/info';
  static const String torrentsAdd = '$_basePath/torrents/add';
  static const String torrentsStop = '$_basePath/torrents/stop';
  static const String torrentsStart = '$_basePath/torrents/start';
  static const String torrentsDelete = '$_basePath/torrents/delete';
  static const String torrentsProperties = '$_basePath/torrents/properties';
  static const String torrentsFiles = '$_basePath/torrents/files';
  static const String torrentsTrackers = '$_basePath/torrents/trackers';

  static const String torrentsIncreasePrio = '$_basePath/torrents/increasePrio';
  static const String torrentsDecreasePrio = '$_basePath/torrents/decreasePrio';
  static const String torrentsTopPrio = '$_basePath/torrents/topPrio';
  static const String torrentsBottomPrio = '$_basePath/torrents/bottomPrio';
  static const String torrentsFilePrio = '$_basePath/torrents/filePrio';
  static const String torrentsRecheck = '$_basePath/torrents/recheck';
  static const String torrentsSetLocation = '$_basePath/torrents/setLocation';
  static const String torrentsRename = '$_basePath/torrents/rename';

  // Legacy endpoints (for backward compatibility)
  static const String torrentsPause = '$_basePath/torrents/pause';
  static const String torrentsResume = '$_basePath/torrents/resume';

  /// Builds a full endpoint URL with the given prefix
  static String buildUrl(String prefix, String endpoint) {
    return '$prefix$endpoint';
  }
}
