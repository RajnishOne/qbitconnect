/// Enum representing different display options for torrent cards
enum TorrentCardDisplayOption {
  percentage('Percentage', 'pct'),
  size('Size', 'size'),
  downloadSpeed('Download Speed', 'dlspeed'),
  uploadSpeed('Upload Speed', 'upspeed'),
  ratio('Upload/Download Ratio', 'ratio'),
  eta('ETA', 'eta'),
  seeds('Seeds', 'seeds'),
  leeches('Leeches', 'leeches'),
  uploaded('Uploaded', 'uploaded'),
  downloaded('Downloaded', 'downloaded');

  const TorrentCardDisplayOption(this.displayName, this.shortName);

  final String displayName;
  final String shortName;

  /// Get the default display options
  static List<TorrentCardDisplayOption> get defaultOptions => [
    TorrentCardDisplayOption.percentage,
    TorrentCardDisplayOption.size,
    TorrentCardDisplayOption.downloadSpeed,
    TorrentCardDisplayOption.uploadSpeed,
  ];

  /// Get all available options
  static List<TorrentCardDisplayOption> get allOptions =>
      TorrentCardDisplayOption.values;

  /// Maximum number of options that can be selected
  static const int maxSelections = 4;
}
