class TransferInfo {
  final int dlInfoSpeed;
  final int dlInfoData;
  final int upInfoSpeed;
  final int upInfoData;
  final int dlRateLimit;
  final int upRateLimit;
  final int dlRateLimitAlt;
  final int upRateLimitAlt;
  final int dlRateLimitGlobal;
  final int upRateLimitGlobal;
  final int dlRateLimitAltGlobal;
  final int upRateLimitAltGlobal;
  final int dlRateLimitGlobalAlt;
  final int upRateLimitGlobalAlt;
  final int dlRateLimitGlobalAlt2;
  final int upRateLimitGlobalAlt2;
  final int dlRateLimitGlobalAlt3;
  final int upRateLimitGlobalAlt3;
  final int dlRateLimitGlobalAlt4;
  final int upRateLimitGlobalAlt4;
  final int dlRateLimitGlobalAlt5;
  final int upRateLimitGlobalAlt5;
  final int dlRateLimitGlobalAlt6;
  final int upRateLimitGlobalAlt6;
  final int dlRateLimitGlobalAlt7;
  final int upRateLimitGlobalAlt7;
  final int dlRateLimitGlobalAlt8;
  final int upRateLimitGlobalAlt8;
  final int dlRateLimitGlobalAlt9;
  final int upRateLimitGlobalAlt9;
  final int dlRateLimitGlobalAlt10;
  final int upRateLimitGlobalAlt10;

  const TransferInfo({
    required this.dlInfoSpeed,
    required this.dlInfoData,
    required this.upInfoSpeed,
    required this.upInfoData,
    required this.dlRateLimit,
    required this.upRateLimit,
    required this.dlRateLimitAlt,
    required this.upRateLimitAlt,
    required this.dlRateLimitGlobal,
    required this.upRateLimitGlobal,
    required this.dlRateLimitAltGlobal,
    required this.upRateLimitAltGlobal,
    required this.dlRateLimitGlobalAlt,
    required this.upRateLimitGlobalAlt,
    required this.dlRateLimitGlobalAlt2,
    required this.upRateLimitGlobalAlt2,
    required this.dlRateLimitGlobalAlt3,
    required this.upRateLimitGlobalAlt3,
    required this.dlRateLimitGlobalAlt4,
    required this.upRateLimitGlobalAlt4,
    required this.dlRateLimitGlobalAlt5,
    required this.upRateLimitGlobalAlt5,
    required this.dlRateLimitGlobalAlt6,
    required this.upRateLimitGlobalAlt6,
    required this.dlRateLimitGlobalAlt7,
    required this.upRateLimitGlobalAlt7,
    required this.dlRateLimitGlobalAlt8,
    required this.upRateLimitGlobalAlt8,
    required this.dlRateLimitGlobalAlt9,
    required this.upRateLimitGlobalAlt9,
    required this.dlRateLimitGlobalAlt10,
    required this.upRateLimitGlobalAlt10,
  });

  factory TransferInfo.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) {
        if (value.isNaN || value.isInfinite) return 0;
        return value.toInt();
      }
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    try {
      return TransferInfo(
        dlInfoSpeed: safeInt(map['dl_info_speed']),
        dlInfoData: safeInt(map['dl_info_data']),
        upInfoSpeed: safeInt(map['up_info_speed']),
        upInfoData: safeInt(map['up_info_data']),
        dlRateLimit: safeInt(map['dl_rate_limit']),
        upRateLimit: safeInt(map['up_rate_limit']),
        dlRateLimitAlt: safeInt(map['dl_rate_limit_alt']),
        upRateLimitAlt: safeInt(map['up_rate_limit_alt']),
        dlRateLimitGlobal: safeInt(map['dl_rate_limit_global']),
        upRateLimitGlobal: safeInt(map['up_rate_limit_global']),
        dlRateLimitAltGlobal: safeInt(map['dl_rate_limit_alt_global']),
        upRateLimitAltGlobal: safeInt(map['up_rate_limit_alt_global']),
        dlRateLimitGlobalAlt: safeInt(map['dl_rate_limit_global_alt']),
        upRateLimitGlobalAlt: safeInt(map['up_rate_limit_global_alt']),
        dlRateLimitGlobalAlt2: safeInt(map['dl_rate_limit_global_alt2']),
        upRateLimitGlobalAlt2: safeInt(map['up_rate_limit_global_alt2']),
        dlRateLimitGlobalAlt3: safeInt(map['dl_rate_limit_global_alt3']),
        upRateLimitGlobalAlt3: safeInt(map['up_rate_limit_global_alt3']),
        dlRateLimitGlobalAlt4: safeInt(map['dl_rate_limit_global_alt4']),
        upRateLimitGlobalAlt4: safeInt(map['up_rate_limit_global_alt4']),
        dlRateLimitGlobalAlt5: safeInt(map['dl_rate_limit_global_alt5']),
        upRateLimitGlobalAlt5: safeInt(map['up_rate_limit_global_alt5']),
        dlRateLimitGlobalAlt6: safeInt(map['dl_rate_limit_global_alt6']),
        upRateLimitGlobalAlt6: safeInt(map['up_rate_limit_global_alt6']),
        dlRateLimitGlobalAlt7: safeInt(map['dl_rate_limit_global_alt7']),
        upRateLimitGlobalAlt7: safeInt(map['up_rate_limit_global_alt7']),
        dlRateLimitGlobalAlt8: safeInt(map['dl_rate_limit_global_alt8']),
        upRateLimitGlobalAlt8: safeInt(map['up_rate_limit_global_alt8']),
        dlRateLimitGlobalAlt9: safeInt(map['dl_rate_limit_global_alt9']),
        upRateLimitGlobalAlt9: safeInt(map['up_rate_limit_global_alt9']),
        dlRateLimitGlobalAlt10: safeInt(map['dl_rate_limit_global_alt10']),
        upRateLimitGlobalAlt10: safeInt(map['up_rate_limit_global_alt10']),
      );
    } catch (e) {
      throw Exception('Failed to parse transfer info data: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'dl_info_speed': dlInfoSpeed,
      'dl_info_data': dlInfoData,
      'up_info_speed': upInfoSpeed,
      'up_info_data': upInfoData,
      'dl_rate_limit': dlRateLimit,
      'up_rate_limit': upRateLimit,
      'dl_rate_limit_alt': dlRateLimitAlt,
      'up_rate_limit_alt': upRateLimitAlt,
      'dl_rate_limit_global': dlRateLimitGlobal,
      'up_rate_limit_global': upRateLimitGlobal,
      'dl_rate_limit_alt_global': dlRateLimitAltGlobal,
      'up_rate_limit_alt_global': upRateLimitAltGlobal,
      'dl_rate_limit_global_alt': dlRateLimitGlobalAlt,
      'up_rate_limit_global_alt': upRateLimitGlobalAlt,
      'dl_rate_limit_global_alt2': dlRateLimitGlobalAlt2,
      'up_rate_limit_global_alt2': upRateLimitGlobalAlt2,
      'dl_rate_limit_global_alt3': dlRateLimitGlobalAlt3,
      'up_rate_limit_global_alt3': upRateLimitGlobalAlt3,
      'dl_rate_limit_global_alt4': dlRateLimitGlobalAlt4,
      'up_rate_limit_global_alt4': upRateLimitGlobalAlt4,
      'dl_rate_limit_global_alt5': dlRateLimitGlobalAlt5,
      'up_rate_limit_global_alt5': upRateLimitGlobalAlt5,
      'dl_rate_limit_global_alt6': dlRateLimitGlobalAlt6,
      'up_rate_limit_global_alt6': upRateLimitGlobalAlt6,
      'dl_rate_limit_global_alt7': dlRateLimitGlobalAlt7,
      'up_rate_limit_global_alt7': upRateLimitGlobalAlt7,
      'dl_rate_limit_global_alt8': dlRateLimitGlobalAlt8,
      'up_rate_limit_global_alt8': upRateLimitGlobalAlt8,
      'dl_rate_limit_global_alt9': dlRateLimitGlobalAlt9,
      'up_rate_limit_global_alt9': upRateLimitGlobalAlt9,
      'dl_rate_limit_global_alt10': dlRateLimitGlobalAlt10,
      'up_rate_limit_global_alt10': upRateLimitGlobalAlt10,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferInfo &&
        other.dlInfoSpeed == dlInfoSpeed &&
        other.dlInfoData == dlInfoData &&
        other.upInfoSpeed == upInfoSpeed &&
        other.upInfoData == upInfoData;
  }

  @override
  int get hashCode {
    return Object.hash(dlInfoSpeed, dlInfoData, upInfoSpeed, upInfoData);
  }

  @override
  String toString() {
    return 'TransferInfo(dlSpeed: $dlInfoSpeed, upSpeed: $upInfoSpeed)';
  }
}
