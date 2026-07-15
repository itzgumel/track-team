import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/dashboard_stats.dart';
import '../../domain/models/device_trace.dart';
import '../../domain/models/geo_filter.dart';
import '../../domain/models/import_result.dart';
import '../../domain/models/team.dart';
import '../services/database_service.dart';
import '../services/xlsx_parser.dart';

/// Data access for teams and imports.
///
/// Extends [ChangeNotifier] purely as a data-changed signal: view models
/// listen and reload after an import completes.
class TeamRepository extends ChangeNotifier {
  TeamRepository(this._databaseService, this._parser);

  final DatabaseService _databaseService;
  final XlsxParser _parser;

  /// Parses [bytes] and merges the traces into the database.
  ///
  /// The UNIQUE(device_id, trace_date) constraint makes re-importing the
  /// same export idempotent. With [clearFirst] the table is emptied first,
  /// treating the file as a full fresh snapshot.
  Future<ImportResult> importXlsx(
    Uint8List bytes, {
    required String fileName,
    bool clearFirst = false,
  }) async {
    final parsed = await compute(_parseInIsolate, _ParseRequest(_parser, bytes));
    final db = await _databaseService.database;

    await db.transaction((txn) async {
      if (clearFirst) await txn.delete('device_traces');
      final batch = txn.batch();
      for (final trace in parsed.traces) {
        batch.insert(
          'device_traces',
          trace.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      await txn.insert('import_history', {
        'file_name': fileName,
        'imported_at': DateTime.now().millisecondsSinceEpoch,
        'row_count': parsed.traces.length,
        'skipped_count': parsed.skippedRows,
        'team_count': Sqflite.firstIntValue(await txn.rawQuery(
              'SELECT COUNT(DISTINCT device_id) FROM device_traces',
            )) ??
            0,
      });
    });

    final stats = await this.stats();
    notifyListeners();
    return ImportResult(
      fileName: fileName,
      importedRows: parsed.traces.length,
      skippedRows: parsed.skippedRows,
      rowsWithoutLocation: parsed.rowsWithoutLocation,
      totalTeams: stats.totalTeams,
      onlineTeams: stats.onlineTeams,
      clearedExisting: clearFirst,
    );
  }

  /// SQL for the latest trace per device.
  ///
  /// Uses SQLite's documented bare-column-with-MAX behaviour (the selected
  /// row is the one holding the max) instead of window functions, which are
  /// unavailable on older Android system SQLite builds.
  static const _latestPerDevice = '''
    SELECT *, MAX(trace_date) AS _max_trace FROM device_traces
    GROUP BY device_id
  ''';

  /// Current teams (latest trace per device), optionally filtered.
  ///
  /// Filters apply to each team's *latest* trace, so a team counts as
  /// ONLINE only if its most recent trace is ONLINE.
  Future<List<Team>> currentTeams({
    GeoFilter filter = const GeoFilter(),
    bool onlineOnly = false,
    bool requireLocation = false,
    String? search,
  }) async {
    final db = await _databaseService.database;
    final where = StringBuffer('1=1');
    final args = <Object>[];

    void geoLevel(String column, String? value) {
      if (value != null) {
        where.write(' AND $column = ?');
        args.add(value);
      }
    }

    geoLevel('lga', filter.lga);
    geoLevel('ward', filter.ward);
    geoLevel('health_facility', filter.healthFacility);
    geoLevel('distribution_point', filter.distributionPoint);

    if (onlineOnly) where.write(" AND UPPER(status) = 'ONLINE'");
    if (requireLocation) {
      where.write(' AND latitude IS NOT NULL AND longitude IS NOT NULL');
    }
    if (search != null && search.trim().isNotEmpty) {
      where.write(' AND (team_name LIKE ? OR user_name LIKE ?'
          ' OR device_id LIKE ?)');
      final pattern = '%${search.trim()}%';
      args.addAll([pattern, pattern, pattern]);
    }

    final rows = await db.rawQuery(
      'SELECT * FROM ($_latestPerDevice) WHERE $where '
      'ORDER BY trace_date DESC',
      args,
    );
    return rows.map((r) => Team(trace: DeviceTrace.fromDbMap(r))).toList();
  }

  Future<Team?> teamByDeviceId(String deviceId) async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery(
      'SELECT * FROM ($_latestPerDevice) WHERE device_id = ?',
      [deviceId],
    );
    if (rows.isEmpty) return null;
    return Team(trace: DeviceTrace.fromDbMap(rows.first));
  }

  /// Full sync trail for one device, newest first.
  Future<List<DeviceTrace>> tracesForDevice(String deviceId) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'device_traces',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'trace_date DESC',
    );
    return rows.map(DeviceTrace.fromDbMap).toList();
  }

  // Cascade lookups. Each level lists DISTINCT values among the teams'
  // latest traces, scoped by the levels above it.

  Future<List<String>> lgas() => _distinct('lga', const GeoFilter());

  Future<List<String>> wards(GeoFilter filter) => _distinct('ward', filter);

  Future<List<String>> healthFacilities(GeoFilter filter) =>
      _distinct('health_facility', filter);

  Future<List<String>> distributionPoints(GeoFilter filter) =>
      _distinct('distribution_point', filter);

  Future<List<String>> _distinct(String column, GeoFilter filter) async {
    final db = await _databaseService.database;
    final where = StringBuffer('$column IS NOT NULL');
    final args = <Object>[];
    void geoLevel(String col, String? value) {
      // Only constrain by levels above the requested column.
      if (value != null && col != column) {
        where.write(' AND $col = ?');
        args.add(value);
      }
    }

    geoLevel('lga', filter.lga);
    geoLevel('ward', filter.ward);
    geoLevel('health_facility', filter.healthFacility);

    final rows = await db.rawQuery(
      'SELECT DISTINCT $column AS v FROM ($_latestPerDevice) '
      'WHERE $where ORDER BY v COLLATE NOCASE',
      args,
    );
    return rows.map((r) => r['v'] as String).toList();
  }

  Future<DashboardStats> stats() async {
    final db = await _databaseService.database;
    final teamRows = await db.rawQuery('''
      SELECT
        COUNT(*) AS teams,
        SUM(CASE WHEN UPPER(status) = 'ONLINE' THEN 1 ELSE 0 END) AS online,
        SUM(CASE WHEN latitude IS NOT NULL THEN 1 ELSE 0 END) AS located,
        COUNT(DISTINCT lga) AS lgas
      FROM ($_latestPerDevice)
    ''');
    final traceCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM device_traces'),
        ) ??
        0;
    final lastImport = await db.query(
      'import_history',
      orderBy: 'imported_at DESC',
      limit: 1,
    );

    final row = teamRows.first;
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    final teams = traceCount == 0 ? 0 : asInt(row['teams']);
    final online = asInt(row['online']);
    return DashboardStats(
      totalTeams: teams,
      onlineTeams: online,
      offlineTeams: teams - online,
      teamsWithLocation: asInt(row['located']),
      totalTraces: traceCount,
      lgaCount: traceCount == 0 ? 0 : asInt(row['lgas']),
      lastImportAt: lastImport.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              lastImport.first['imported_at'] as int,
            ),
      lastImportFile:
          lastImport.isEmpty ? null : lastImport.first['file_name'] as String,
    );
  }

  Future<List<ImportRecord>> importHistory({int limit = 20}) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'import_history',
      orderBy: 'imported_at DESC',
      limit: limit,
    );
    return rows
        .map((r) => ImportRecord(
              fileName: r['file_name'] as String,
              importedAt: DateTime.fromMillisecondsSinceEpoch(
                r['imported_at'] as int,
              ),
              rowCount: r['row_count'] as int,
              skippedCount: r['skipped_count'] as int,
              teamCount: r['team_count'] as int,
            ))
        .toList();
  }

  /// Removes all trace data and import history.
  Future<void> clearAll() async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await txn.delete('device_traces');
      await txn.delete('import_history');
    });
    notifyListeners();
  }
}

class _ParseRequest {
  const _ParseRequest(this.parser, this.bytes);
  final XlsxParser parser;
  final Uint8List bytes;
}

/// Top-level so [compute] can run the CPU-heavy parse off the UI thread.
XlsxParseResult _parseInIsolate(_ParseRequest request) =>
    request.parser.parse(request.bytes);
