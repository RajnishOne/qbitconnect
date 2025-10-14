// Localization keys for the app
// This file contains all the string keys used for localization

class LocaleKeys {
  // App info
  static const String appTitle = 'appTitle';
  static const String appName = 'appName';

  // Navigation and main screens
  static const String settings = 'settings';
  static const String servers = 'servers';
  static const String statistics = 'statistics';
  static const String theme = 'theme';
  static const String language = 'language';
  static const String torrents = 'torrents';
  static const String addTorrent = 'addTorrent';
  static const String downloads = 'downloads';
  static const String uploads = 'uploads';

  // Language selection
  static const String chooseLanguage = 'chooseLanguage';
  static const String chooseTheme = 'chooseTheme';
  static const String english = 'english';
  static const String spanish = 'spanish';
  static const String french = 'french';
  static const String german = 'german';

  // Themes
  static const String lightTheme = 'lightTheme';
  static const String darkTheme = 'darkTheme';
  static const String oledTheme = 'oledTheme';
  static const String highContrastLight = 'highContrastLight';
  static const String highContrastDark = 'highContrastDark';
  static const String systemTheme = 'systemTheme';

  // Common actions
  static const String save = 'save';
  static const String cancel = 'cancel';
  static const String ok = 'ok';
  static const String error = 'error';
  static const String success = 'success';
  static const String loading = 'loading';
  static const String retry = 'retry';
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String delete = 'delete';
  static const String remove = 'remove';
  static const String start = 'start';
  static const String stop = 'stop';
  static const String refresh = 'refresh';
  static const String reload = 'reload';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String sort = 'sort';
  static const String edit = 'edit';
  static const String add = 'add';
  static const String update = 'update';
  static const String reset = 'reset';

  // Torrent properties
  static const String name = 'name';
  static const String size = 'size';
  static const String status = 'status';
  static const String progress = 'progress';
  static const String speed = 'speed';
  static const String eta = 'eta';
  static const String category = 'category';
  static const String tags = 'tags';
  static const String tracker = 'tracker';
  static const String seeders = 'seeders';
  static const String leechers = 'leechers';
  static const String peers = 'peers';
  static const String ratio = 'ratio';
  static const String uploaded = 'uploaded';
  static const String downloaded = 'downloaded';

  // Torrent states
  static const String completed = 'completed';
  static const String downloading = 'downloading';
  static const String seeding = 'seeding';
  static const String paused = 'paused';
  static const String queued = 'queued';
  static const String checking = 'checking';
  static const String stalled = 'stalled';
  static const String unknown = 'unknown';
  static const String active = 'active';

  // Add torrent
  static const String addTorrentFile = 'addTorrentFile';
  static const String addTorrentUrl = 'addTorrentUrl';
  static const String changeLocation = 'changeLocation';
  static const String renameTorrent = 'renameTorrent';
  static const String setPriority = 'setPriority';
  static const String recheck = 'recheck';
  static const String rename = 'rename';

  // Priority levels
  static const String doNotDownload = 'doNotDownload';
  static const String normal = 'normal';
  static const String high = 'high';
  static const String maximum = 'maximum';

  // Connection settings
  static const String port = 'port';
  static const String username = 'username';
  static const String password = 'password';
  static const String customHeaders = 'customHeaders';
  static const String useHttps = 'useHttps';
  static const String savePassword = 'savePassword';
  static const String showPassword = 'showPassword';
  static const String hidePassword = 'hidePassword';
  static const String rememberPasswordForFutureConnections =
      'rememberPasswordForFutureConnections';

  // Torrent options
  static const String torrentOptions = 'torrentOptions';
  static const String startTorrent = 'startTorrent';
  static const String addToTopOfQueue = 'addToTopOfQueue';
  static const String manual = 'manual';
  static const String automatic = 'automatic';
  static const String none = 'none';
  static const String original = 'original';
  static const String torrentFile = 'torrentFile';
  static const String urls = 'urls';
  static const String torrentUrls = 'torrentUrls';

  // Connection
  static const String connectToQBittorrent = 'connectToQBittorrent';
  static const String connecting = 'connecting';
  static const String required = 'required';
  static const String invalidHostAddress = 'invalidHostAddress';
  static const String invalidProtocolFormat = 'invalidProtocolFormat';

  // Headers
  static const String noCustomHeadersAdded = 'noCustomHeadersAdded';
  static const String headersPreview = 'headersPreview';
  static const String editHeader = 'editHeader';
  static const String addHeader = 'addHeader';
  static const String headerKey = 'headerKey';
  static const String headerKeyRequired = 'headerKeyRequired';
  static const String headerKeyCannotContainColons =
      'headerKeyCannotContainColons';
  static const String headerValue = 'headerValue';
  static const String headerValueRequired = 'headerValueRequired';

  // Server management
  static const String manageServers = 'manageServers';
  static const String serverList = 'serverList';
  static const String noServers = 'noServers';
  static const String deleteServer = 'deleteServer';
  static const String setAsAutoConnect = 'setAsAutoConnect';
  static const String selectAll = 'selectAll';
  static const String select = 'select';
  static const String failedToLoadServers = 'failedToLoadServers';
  static const String connectedTo = 'connectedTo';
  static const String deleteLastServer = 'deleteLastServer';
  static const String deleted = 'deleted';
  static const String failedToDeleteServer = 'failedToDeleteServer';
  static const String addServer = 'addServer';

  // Details and info
  static const String info = 'info';
  static const String files = 'files';
  static const String trackers = 'trackers';
  static const String message = 'message';
  static const String tier = 'tier';
  static const String state = 'state';

  // Data availability
  static const String noDataAvailable = 'noDataAvailable';
  static const String noDetailsAvailable = 'noDetailsAvailable';
  static const String noTorrentsFound = 'noTorrentsFound';
  static const String noTorrentsMatchSearch = 'noTorrentsMatchSearch';
  static const String anErrorOccurred = 'anErrorOccurred';
  static const String pleaseSelectFile = 'pleaseSelectFile';

  // Torrent actions
  static const String torrentRecheckStarted = 'torrentRecheckStarted';
  static const String refreshTorrents = 'refreshTorrents';
  static const String currentFilter = 'currentFilter';

  // Analytics and display
  static const String analytics = 'analytics';
  static const String torrentCardDisplay = 'torrentCardDisplay';
  static const String customizeTorrentCard = 'customizeTorrentCard';

  // Filter options
  static const String allTorrents = 'allTorrents';
  static const String showAllTorrents = 'showAllTorrents';
  static const String showOnlyDownloading = 'showOnlyDownloading';
  static const String showOnlyCompleted = 'showOnlyCompleted';
  static const String showOnlySeeding = 'showOnlySeeding';
  static const String showOnlyPaused = 'showOnlyPaused';
  static const String showOnlyActive = 'showOnlyActive';

  // Auto refresh
  static const String enableAutoRefresh = 'enableAutoRefresh';
  static const String automaticallyRefreshTorrentList =
      'automaticallyRefreshTorrentList';
  static const String refreshInterval = 'refreshInterval';

  // Legal and info
  static const String privacyPolicy = 'privacyPolicy';
  static const String termsConditions = 'termsConditions';
  static const String logs = 'logs';
  static const String version = 'version';

  // Torrent management
  static const String pleaseEnterAtLeastOneUrl = 'pleaseEnterAtLeastOneUrl';
  static const String failedToAddTorrent = 'failedToAddTorrent';
  static const String successfullyAddedTorrents = 'successfullyAddedTorrents';
  static const String errorAddingTorrent = 'errorAddingTorrent';
  static const String languageChangedTo = 'languageChangedTo';
  static const String torrentManagementMode = 'torrentManagementMode';
  static const String fileSize = 'fileSize';

  // Advanced torrent options
  static const String stopCondition = 'stopCondition';
  static const String metadataReceived = 'metadataReceived';
  static const String filesChecked = 'filesChecked';
  static const String contentLayout = 'contentLayout';
  static const String createSubfolder = 'createSubfolder';
  static const String dontCreateSubfolder = 'dontCreateSubfolder';
  static const String skipHashCheck = 'skipHashCheck';
  static const String downloadSequential = 'downloadSequential';
  static const String downloadFirstLast = 'downloadFirstLast';
  static const String limitDownloadRate = 'limitDownloadRate';
  static const String limitUploadRate = 'limitUploadRate';
  static const String saveFilesToLocation = 'saveFilesToLocation';

  // Server list screen specific keys
  static const String areYouSureDeleteServer = 'areYouSureDeleteServer';
  static const String willRemoveServerConfig = 'willRemoveServerConfig';
  static const String lastServerNeedToAddNew = 'lastServerNeedToAddNew';
  static const String serverDeletedReplacementSet =
      'serverDeletedReplacementSet';
  static const String serverDeleted = 'serverDeleted';
  static const String failedToDeleteServerTryAgain =
      'failedToDeleteServerTryAgain';
  static const String disconnectFirstToDelete = 'disconnectFirstToDelete';
  static const String checkingConnection = 'checkingConnection';
  static const String lastConnected = 'lastConnected';
  static const String qbittorrentVersion = 'qbittorrentVersion';
  static const String tapToConnectLongPressOptions =
      'tapToConnectLongPressOptions';
  static const String tapAddServerBelowToConnect = 'tapAddServerBelowToConnect';

  // Connection screen specific keys
  static const String serverNameOptional = 'serverNameOptional';
  static const String serverNameHint = 'serverNameHint';
  static const String hostIpAddress = 'hostIpAddress';
  static const String hostIpAddressHint = 'hostIpAddressHint';
  static const String protocolDetectedAutomatically =
      'protocolDetectedAutomatically';
  static const String portHint = 'portHint';
  static const String invalidPort = 'invalidPort';
  static const String pathOptional = 'pathOptional';
  static const String pathHint = 'pathHint';
  static const String noNetworkConnection = 'noNetworkConnection';
  static const String connectionTimeout = 'connectionTimeout';
  static const String authenticationRequired = 'authenticationRequired';
  static const String usernamePasswordRequiredRemote =
      'usernamePasswordRequiredRemote';
  static const String usernamePasswordRequiredRemoteMessage =
      'usernamePasswordRequiredRemoteMessage';
  static const String authenticationRequiredMessage =
      'authenticationRequiredMessage';
  static const String invalidCredentials = 'invalidCredentials';
  static const String cannotConnectToQBittorrent = 'cannotConnectToQBittorrent';
  static const String failedToConnectToQBittorrent =
      'failedToConnectToQBittorrent';

  // Statistics screen specific keys
  static const String notConnectedToQBittorrent = 'notConnectedToQBittorrent';
  static const String failedToLoadStatistics = 'failedToLoadStatistics';
  static const String overview = 'overview';
  static const String totalTorrents = 'totalTorrents';
  static const String activeTorrents = 'activeTorrents';
  static const String completedTorrents = 'completedTorrents';
  static const String pausedTorrents = 'pausedTorrents';
  static const String erroredTorrents = 'erroredTorrents';
  static const String transferStatistics = 'transferStatistics';
  static const String allTimeUpload = 'allTimeUpload';
  static const String allTimeDownload = 'allTimeDownload';
  static const String allTimeShareRatio = 'allTimeShareRatio';
  static const String sessionWaste = 'sessionWaste';
  static const String notAvailable = 'notAvailable';
  static const String totalSize = 'totalSize';
  static const String totalWasted = 'totalWasted';
  static const String torrentStatus = 'torrentStatus';
  static const String peersConnected = 'peersConnected';
  static const String totalSeeds = 'totalSeeds';
  static const String totalLeechers = 'totalLeechers';
  static const String performanceMetrics = 'performanceMetrics';
  static const String averageDownloadSpeed = 'averageDownloadSpeed';
  static const String averageUploadSpeed = 'averageUploadSpeed';
  static const String peakDownloadSpeed = 'peakDownloadSpeed';
  static const String peakUploadSpeed = 'peakUploadSpeed';
  static const String writeCacheOverload = 'writeCacheOverload';
  static const String readCacheOverload = 'readCacheOverload';
  static const String queuedIoJobs = 'queuedIoJobs';
  static const String averageTimeInQueue = 'averageTimeInQueue';
  static const String totalQueuedSize = 'totalQueuedSize';
  static const String cacheStatistics = 'cacheStatistics';
  static const String readCacheHits = 'readCacheHits';
  static const String totalBufferSize = 'totalBufferSize';
  static const String timeline = 'timeline';
  static const String firstTorrentAdded = 'firstTorrentAdded';
  static const String lastTorrentAdded = 'lastTorrentAdded';

  // Settings screen specific keys
  static const String serverName = 'serverName';
  static const String connectionUrl = 'connectionUrl';
  static const String transferSpeeds = 'transferSpeeds';
  static const String defaultStatusFilter = 'defaultStatusFilter';
  static const String everySeconds = 'everySeconds';
  static const String everyMinute = 'everyMinute';
  static const String everyMinutes = 'everyMinutes';

  // Torrent card display settings screen specific keys
  static const String maximumOptionsCanBeSelected =
      'maximumOptionsCanBeSelected';
  static const String customizeTorrentCardInfo = 'customizeTorrentCardInfo';
  static const String selectUpToOptionsToDisplay = 'selectUpToOptionsToDisplay';
  static const String currentlySelected = 'currentlySelected';
  static const String preview = 'preview';
  static const String availableOptions = 'availableOptions';
  static const String noOptionsSelected = 'noOptionsSelected';
  static const String showsDownloadProgressPercentage =
      'showsDownloadProgressPercentage';
  static const String showsTotalTorrentSize = 'showsTotalTorrentSize';
  static const String showsCurrentDownloadSpeed = 'showsCurrentDownloadSpeed';
  static const String showsCurrentUploadSpeed = 'showsCurrentUploadSpeed';
  static const String showsUploadDownloadRatio = 'showsUploadDownloadRatio';
  static const String showsEstimatedTimeToCompletion =
      'showsEstimatedTimeToCompletion';
  static const String showsNumberOfSeeders = 'showsNumberOfSeeders';
  static const String showsNumberOfLeechers = 'showsNumberOfLeechers';
  static const String showsTotalUploadedData = 'showsTotalUploadedData';
  static const String showsTotalDownloadedData = 'showsTotalDownloadedData';

  // Theme selection screen specific keys
  static const String lightThemeDescription = 'lightThemeDescription';
  static const String darkThemeDescription = 'darkThemeDescription';
  static const String oledThemeDescription = 'oledThemeDescription';
  static const String systemThemeDescription = 'systemThemeDescription';
  static const String highContrastLightTheme = 'highContrastLightTheme';
  static const String highContrastLightThemeDescription =
      'highContrastLightThemeDescription';
  static const String highContrastDarkTheme = 'highContrastDarkTheme';
  static const String highContrastDarkThemeDescription =
      'highContrastDarkThemeDescription';

  // Torrent details screen specific keys
  static const String stats = 'stats';
  static const String generalInformation = 'generalInformation';
  static const String transferInformation = 'transferInformation';
  static const String connectionInformation = 'connectionInformation';
  static const String technicalInformation = 'technicalInformation';
  static const String savePath = 'savePath';
  static const String additionDate = 'additionDate';
  static const String comment = 'comment';
  static const String createdBy = 'createdBy';
  static const String wasted = 'wasted';
  static const String downloadSpeed = 'downloadSpeed';
  static const String uploadSpeed = 'uploadSpeed';
  static const String downloadSpeedAvg = 'downloadSpeedAvg';
  static const String uploadSpeedAvg = 'uploadSpeedAvg';
  static const String shareRatio = 'shareRatio';
  static const String seeds = 'seeds';
  static const String leeches = 'leeches';
  static const String connections = 'connections';
  static const String timeElapsed = 'timeElapsed';
  static const String seedingTime = 'seedingTime';
  static const String pieces = 'pieces';
  static const String pieceSize = 'pieceSize';
  static const String downloadLimit = 'downloadLimit';
  static const String uploadLimit = 'uploadLimit';
  static const String unlimited = 'unlimited';
  static const String private = 'private';
  static const String sequentialDownload = 'sequentialDownload';
  static const String forceStart = 'forceStart';
  static const String autoTmm = 'autoTmm';
  static const String yes = 'yes';
  static const String no = 'no';
  static const String total = 'total';
  static const String changeSaveLocation = 'changeSaveLocation';
  static const String newLocation = 'newLocation';
  static const String typeOrSelectDirectory = 'typeOrSelectDirectory';
  static const String change = 'change';
  static const String deleteTorrent = 'deleteTorrent';
  static const String chooseWhatToDelete = 'chooseWhatToDelete';
  static const String torrentOnly = 'torrentOnly';
  static const String torrentAndFiles = 'torrentAndFiles';
  static const String torrentRenamedSuccessfully = 'torrentRenamedSuccessfully';
  static const String torrentDeletedSuccessfully = 'torrentDeletedSuccessfully';
  static const String torrentAndFilesDeletedSuccessfully =
      'torrentAndFilesDeletedSuccessfully';
  static const String torrentLocationChangedSuccessfully =
      'torrentLocationChangedSuccessfully';
  static const String failedToRename = 'failedToRename';
  static const String failedToChangeLocation = 'failedToChangeLocation';
  static const String failedToDeleteTorrent = 'failedToDeleteTorrent';
  static const String actionFailed = 'actionFailed';

  // Filter bottom sheet specific keys
  static const String sortAndFilter = 'sortAndFilter';
  static const String applyFilter = 'applyFilter';
  static const String sortBy = 'sortBy';
  static const String priority = 'priority';
  static const String addedDate = 'addedDate';
  static const String completionDate = 'completionDate';
  static const String moveUp = 'moveUp';
  static const String moveDown = 'moveDown';
  static const String moveToTop = 'moveToTop';
  static const String moveToBottom = 'moveToBottom';
  static const String torrentMovedUpInQueue = 'torrentMovedUpInQueue';
  static const String torrentMovedDownInQueue = 'torrentMovedDownInQueue';
  static const String torrentMovedToTopOfQueue = 'torrentMovedToTopOfQueue';
  static const String torrentMovedToBottomOfQueue =
      'torrentMovedToBottomOfQueue';
  static const String failedToMoveTorrent = 'failedToMoveTorrent';

  // Search filter bar specific keys
  static const String searchTorrents = 'searchTorrents';
  static const String filters = 'filters';

  // Add torrent FAB specific keys
  static const String addViaUrl = 'addViaUrl';
}
