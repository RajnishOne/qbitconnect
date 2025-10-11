/// Centralized string constants for the qBitConnect app.
///
/// This file contains all hardcoded strings used throughout the app
/// to ensure consistency, maintainability, and easy localization.
class AppStrings {
  // Private constructor to prevent instantiation
  AppStrings._();

  // App Information
  static const String appName = 'qBitConnect';

  // Common Actions
  static const String pause = 'Pause';
  static const String resume = 'Resume';
  static const String recheck = 'Recheck';
  static const String rename = 'Rename';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String refresh = 'Refresh';
  static const String reload = 'Reload';
  static const String retry = 'Retry';

  // Selection Actions
  static const String selectAll = 'Select All';
  static const String select = 'Select';

  // Navigation & Tabs
  static const String info = 'Info';
  static const String files = 'Files';
  static const String trackers = 'Trackers';
  static const String settings = 'Settings';

  // Torrent Management
  static const String addTorrent = 'Add Torrent';
  static const String addTorrentFile = 'Add Torrent File';
  static const String addTorrentUrl = 'Add Torrent URL';
  static const String changeLocation = 'Change Location';
  static const String renameTorrent = 'Rename Torrent';
  static const String setPriority = 'Set Priority';

  // Torrent States & Status
  static const String downloading = 'Downloading';
  static const String seeding = 'Seeding';
  static const String paused = 'Paused';
  static const String completed = 'Completed';
  static const String error = 'Error';

  // File Management
  static const String doNotDownload = 'Do not download';
  static const String normal = 'Normal';
  static const String high = 'High';
  static const String maximum = 'Maximum';

  // Connection & Network
  static const String port = 'Port';
  static const String username = 'Username';
  static const String password = 'Password';
  static const String customHeaders = 'Custom Headers';
  static const String useHttps = 'Use HTTPS';
  static const String savePassword = 'Save Password';
  static const String connect = 'Connect';

  // Torrent Options
  static const String torrentOptions = 'Torrent Options';
  static const String startTorrent = 'Start Torrent';
  static const String addToTopOfQueue = 'Add to Top of Queue';

  // Torrent Management Modes
  static const String manual = 'Manual';
  static const String automatic = 'Automatic';

  // Stop Conditions
  static const String none = 'None';

  // Content Layouts
  static const String original = 'Original';

  // File Types & Extensions
  static const String torrentFile = 'Torrent File';

  // Connection Information
  static const String peers = 'Peers';
  static const String seeds = 'Seeds';
  static const String leeches = 'Leeches';
  static const String status = 'Status';
  static const String message = 'Message';
  static const String tier = 'Tier';

  // General Information
  static const String name = 'Name';
  static const String size = 'Size';
  static const String progress = 'Progress';
  static const String state = 'State';

  // Messages & Notifications
  static const String noDataAvailable = 'No data available';
  static const String noDetailsAvailable = 'No details available';
  static const String noTorrentsFound = 'No torrents found';
  static const String noTorrentsMatchSearch = 'No torrents match your search';
  static const String anErrorOccurred = 'An error occurred';

  // Success Messages
  static const String torrentRecheckStarted = 'Torrent recheck started';

  // Validation Messages
  static const String pleaseSelectFile = 'Please select a file';

  // Tooltips
  static const String refreshTorrents = 'Refresh torrents';

  // Search & Filter
  static const String currentFilter = 'Current Filter';

  // Development & Debug
  static const String analytics = 'Analytics';

  // Additional strings for remaining screens
  static const String urls = 'URLs';
  static const String torrentUrls = 'Torrent URLs';
  static const String connectToQBittorrent = 'Connect to qBittorrent';
  static const String connecting = 'Connecting…';
  static const String required = 'Required';
  static const String invalidHostAddress = 'Invalid host address';
  static const String invalidProtocolFormat = 'Invalid protocol format';
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';
  static const String rememberPasswordForFutureConnections =
      'Remember password for future connections';
  static const String noCustomHeadersAdded = 'No custom headers added';
  static const String headersPreview = 'Headers Preview';
  static const String editHeader = 'Edit Header';
  static const String addHeader = 'Add Header';
  static const String headerKey = 'Header Key';
  static const String headerKeyRequired = 'Header key is required';
  static const String headerKeyCannotContainColons =
      'Header key cannot contain colons';
  static const String headerValue = 'Header Value';
  static const String headerValueRequired = 'Header value is required';
  static const String update = 'Update';
  static const String add = 'Add';
  static const String chooseTheme = 'Choose Theme';

  // Server Management
  static const String servers = 'Servers';
  static const String manageServers = 'Manage Servers';
  static const String serverList = 'Server List';
  static const String noServers = 'No Servers';
  static const String active = 'Active';
  static const String deleteServer = 'Delete Server';
  static const String setAsAutoConnect = 'Set as Auto-Connect';
}
