class TorrentAddOptions {
  final String? savePath;
  final String? name;
  final String? category;
  final bool startTorrent;
  final bool addToTopOfQueue;
  final String? stopCondition;
  final bool skipHashCheck;
  final String? contentLayout;
  final bool sequentialDownload;
  final bool firstLastPiecePriority;
  final int? downloadLimit;
  final int? uploadLimit;
  final String? torrentManagementMode;

  const TorrentAddOptions({
    this.savePath,
    this.name,
    this.category,
    this.startTorrent = true,
    this.addToTopOfQueue = false,
    this.stopCondition,
    this.skipHashCheck = false,
    this.contentLayout,
    this.sequentialDownload = false,
    this.firstLastPiecePriority = false,
    this.downloadLimit,
    this.uploadLimit,
    this.torrentManagementMode,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (savePath != null && savePath!.isNotEmpty) {
      map['savepath'] = savePath;
    }
    if (name != null && name!.isNotEmpty) {
      map['name'] = name;
    }
    if (category != null && category!.isNotEmpty) {
      map['category'] = category;
    }
    if (!startTorrent) {
      map['paused'] = 'true';
    }
    if (addToTopOfQueue) {
      map['addToTopOfQueue'] = 'true';
    }
    if (stopCondition != null && stopCondition!.isNotEmpty) {
      map['stopCondition'] = stopCondition;
    }
    if (skipHashCheck) {
      map['skip_checking'] = 'true';
    }
    if (contentLayout != null && contentLayout!.isNotEmpty) {
      map['contentLayout'] = contentLayout;
    }
    if (sequentialDownload) {
      map['sequentialDownload'] = 'true';
    }
    if (firstLastPiecePriority) {
      map['firstLastPiecePriority'] = 'true';
    }
    if (downloadLimit != null && downloadLimit! > 0) {
      map['dlLimit'] = downloadLimit.toString();
    }
    if (uploadLimit != null && uploadLimit! > 0) {
      map['upLimit'] = uploadLimit.toString();
    }
    if (torrentManagementMode != null && torrentManagementMode!.isNotEmpty) {
      map['autoTMM'] = torrentManagementMode == 'Automatic' ? 'true' : 'false';
    }

    return map;
  }

  TorrentAddOptions copyWith({
    String? savePath,
    String? name,
    String? category,
    bool? startTorrent,
    bool? addToTopOfQueue,
    String? stopCondition,
    bool? skipHashCheck,
    String? contentLayout,
    bool? sequentialDownload,
    bool? firstLastPiecePriority,
    int? downloadLimit,
    int? uploadLimit,
    String? torrentManagementMode,
  }) {
    return TorrentAddOptions(
      savePath: savePath ?? this.savePath,
      name: name ?? this.name,
      category: category ?? this.category,
      startTorrent: startTorrent ?? this.startTorrent,
      addToTopOfQueue: addToTopOfQueue ?? this.addToTopOfQueue,
      stopCondition: stopCondition ?? this.stopCondition,
      skipHashCheck: skipHashCheck ?? this.skipHashCheck,
      contentLayout: contentLayout ?? this.contentLayout,
      sequentialDownload: sequentialDownload ?? this.sequentialDownload,
      firstLastPiecePriority:
          firstLastPiecePriority ?? this.firstLastPiecePriority,
      downloadLimit: downloadLimit ?? this.downloadLimit,
      uploadLimit: uploadLimit ?? this.uploadLimit,
      torrentManagementMode:
          torrentManagementMode ?? this.torrentManagementMode,
    );
  }
}
