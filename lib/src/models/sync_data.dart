class SyncData {
  final int rid;
  final bool fullUpdate;
  final Map<String, dynamic>? torrents;
  final Map<String, dynamic>? torrentsRemoved;
  final Map<String, dynamic>? categories;
  final Map<String, dynamic>? categoriesRemoved;
  final Map<String, dynamic>? tags;
  final Map<String, dynamic>? tagsRemoved;
  final Map<String, dynamic>? trackers;
  final Map<String, dynamic>? trackersRemoved;
  final Map<String, dynamic>? serverState;

  const SyncData({
    required this.rid,
    required this.fullUpdate,
    this.torrents,
    this.torrentsRemoved,
    this.categories,
    this.categoriesRemoved,
    this.tags,
    this.tagsRemoved,
    this.trackers,
    this.trackersRemoved,
    this.serverState,
  });

  factory SyncData.fromMap(Map<String, dynamic> map) {
    return SyncData(
      rid: map['rid'] ?? 0,
      fullUpdate: map['full_update'] ?? false,
      torrents: map['torrents'],
      torrentsRemoved: map['torrents_removed'],
      categories: map['categories'],
      categoriesRemoved: map['categories_removed'],
      tags: map['tags'],
      tagsRemoved: map['tags_removed'],
      trackers: map['trackers'],
      trackersRemoved: map['trackers_removed'],
      serverState: map['server_state'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rid': rid,
      'full_update': fullUpdate,
      'torrents': torrents,
      'torrents_removed': torrentsRemoved,
      'categories': categories,
      'categories_removed': categoriesRemoved,
      'tags': tags,
      'tags_removed': tagsRemoved,
      'trackers': trackers,
      'trackers_removed': trackersRemoved,
      'server_state': serverState,
    };
  }

  @override
  String toString() {
    return 'SyncData(rid: $rid, fullUpdate: $fullUpdate)';
  }
}
