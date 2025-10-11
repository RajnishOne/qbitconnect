/// Model representing a qBittorrent server configuration
class ServerConfig {
  /// Unique identifier for this server
  final String id;

  /// User-friendly name for the server
  final String name;

  /// Base URL of the qBittorrent Web UI
  final String baseUrl;

  /// Username for authentication
  final String username;

  /// Whether this is a no-auth session (local network)
  final bool noAuthSession;

  /// Custom HTTP headers as text (Key: Value format, one per line)
  /// Stored as text to avoid serialization complexity
  final String? customHeadersText;

  /// When this server configuration was created
  final DateTime createdAt;

  /// When this server was last successfully connected to
  final DateTime? lastConnectedAt;

  /// qBittorrent version (cached from last connection)
  final String? qbittorrentVersion;

  ServerConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.username,
    this.noAuthSession = false,
    this.customHeadersText,
    required this.createdAt,
    this.lastConnectedAt,
    this.qbittorrentVersion,
  });

  /// Create a copy of this server config with updated fields
  ServerConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? username,
    bool? noAuthSession,
    String? customHeadersText,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
    String? qbittorrentVersion,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      noAuthSession: noAuthSession ?? this.noAuthSession,
      customHeadersText: customHeadersText ?? this.customHeadersText,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      qbittorrentVersion: qbittorrentVersion ?? this.qbittorrentVersion,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'username': username,
      'noAuthSession': noAuthSession,
      'customHeadersText': customHeadersText,
      'createdAt': createdAt.toIso8601String(),
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      'qbittorrentVersion': qbittorrentVersion,
    };
  }

  /// Create from JSON
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      username: json['username'] as String? ?? '',
      noAuthSession: json['noAuthSession'] as bool? ?? false,
      customHeadersText: json['customHeadersText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.parse(json['lastConnectedAt'] as String)
          : null,
      qbittorrentVersion: json['qbittorrentVersion'] as String?,
    );
  }

  /// Parse custom headers from text format to Map
  /// Format: "Key: Value" per line
  Map<String, String>? parseCustomHeaders() {
    if (customHeadersText == null || customHeadersText!.isEmpty) return null;

    final Map<String, String> headers = {};
    final lines = customHeadersText!.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0 && colonIndex < trimmed.length - 1) {
        final key = trimmed.substring(0, colonIndex).trim();
        final value = trimmed.substring(colonIndex + 1).trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          headers[key] = value;
        }
      }
    }

    return headers.isEmpty ? null : headers;
  }

  @override
  String toString() {
    return 'ServerConfig(id: $id, name: $name, baseUrl: $baseUrl, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ServerConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
