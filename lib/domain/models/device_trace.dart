/// A single device trace row from the campaign device-trace export.
///
/// One physical team device can appear multiple times in an export (one row
/// per sync). The "current" picture of a team is the latest trace per
/// [deviceId].
class DeviceTrace {
  const DeviceTrace({
    required this.deviceId,
    this.imei,
    this.traceDate,
    this.lastSyncedAt,
    this.teamName,
    this.userName,
    this.userType,
    this.country,
    this.state,
    this.lga,
    this.ward,
    this.healthFacility,
    this.distributionPoint,
    this.settlement,
    this.latitude,
    this.longitude,
    this.deviceModel,
    this.appVersion,
    this.status = 'OFFLINE',
  });

  final String deviceId;
  final String? imei;
  final DateTime? traceDate;
  final DateTime? lastSyncedAt;

  /// Display name of the team/user that last synced ("Last Synched by").
  final String? teamName;
  final String? userName;
  final String? userType;
  final String? country;
  final String? state;
  final String? lga;
  final String? ward;
  final String? healthFacility;
  final String? distributionPoint;
  final String? settlement;
  final double? latitude;
  final double? longitude;
  final String? deviceModel;
  final String? appVersion;
  final String status;

  bool get hasLocation => latitude != null && longitude != null;

  bool get isOnline => status.toUpperCase() == 'ONLINE';

  /// Compact geo hierarchy line for list display, e.g.
  /// "Ayedire › Amobi › Amobi PHC".
  String get hierarchyLabel {
    final parts = [lga, ward, healthFacility, distributionPoint]
        .where((p) => p != null && p.trim().isNotEmpty)
        .cast<String>()
        .toList();
    // Collapse consecutive duplicates (DP often repeats the facility name).
    final unique = <String>[];
    for (final p in parts) {
      if (unique.isEmpty || unique.last != p) unique.add(p);
    }
    return unique.join(' › ');
  }

  /// `trace_date` is non-null in the schema (0 = unknown) so that the
  /// UNIQUE(device_id, trace_date) upsert works: SQLite would treat NULLs
  /// as always-distinct and re-imports would duplicate rows.
  Map<String, Object?> toDbMap() => {
        'device_id': deviceId,
        'imei': imei,
        'trace_date': traceDate?.millisecondsSinceEpoch ?? 0,
        'last_synced_at': lastSyncedAt?.millisecondsSinceEpoch,
        'team_name': teamName,
        'user_name': userName,
        'user_type': userType,
        'country': country,
        'state': state,
        'lga': lga,
        'ward': ward,
        'health_facility': healthFacility,
        'distribution_point': distributionPoint,
        'settlement': settlement,
        'latitude': latitude,
        'longitude': longitude,
        'device_model': deviceModel,
        'app_version': appVersion,
        'status': status,
      };

  static DeviceTrace fromDbMap(Map<String, Object?> map) {
    DateTime? epoch(Object? v) => (v == null || v == 0)
        ? null
        : DateTime.fromMillisecondsSinceEpoch(v as int);
    return DeviceTrace(
      deviceId: map['device_id'] as String,
      imei: map['imei'] as String?,
      traceDate: epoch(map['trace_date']),
      lastSyncedAt: epoch(map['last_synced_at']),
      teamName: map['team_name'] as String?,
      userName: map['user_name'] as String?,
      userType: map['user_type'] as String?,
      country: map['country'] as String?,
      state: map['state'] as String?,
      lga: map['lga'] as String?,
      ward: map['ward'] as String?,
      healthFacility: map['health_facility'] as String?,
      distributionPoint: map['distribution_point'] as String?,
      settlement: map['settlement'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      deviceModel: map['device_model'] as String?,
      appVersion: map['app_version'] as String?,
      status: (map['status'] as String?) ?? 'OFFLINE',
    );
  }
}
