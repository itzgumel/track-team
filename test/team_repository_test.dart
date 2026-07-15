import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:track_team/data/repositories/team_repository.dart';
import 'package:track_team/data/services/database_service.dart';
import 'package:track_team/data/services/xlsx_parser.dart';
import 'package:track_team/domain/models/device_trace.dart';
import 'package:track_team/domain/models/geo_filter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DatabaseService databaseService;
  late TeamRepository repository;

  setUp(() {
    databaseService = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = TeamRepository(databaseService, XlsxParser());
  });

  tearDown(() => databaseService.close());

  Future<void> insert(List<DeviceTrace> traces) async {
    final db = await databaseService.database;
    for (final trace in traces) {
      await db.insert('device_traces', trace.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  DeviceTrace trace(
    String deviceId, {
    DateTime? traceDate,
    String status = 'OFFLINE',
    String? lga,
    String? ward,
    String? healthFacility,
    String? distributionPoint,
    double? lat,
    double? lng,
    String? teamName,
  }) =>
      DeviceTrace(
        deviceId: deviceId,
        traceDate: traceDate ?? DateTime(2026, 6, 1, 8),
        lastSyncedAt: traceDate ?? DateTime(2026, 6, 1, 8),
        teamName: teamName ?? 'Team $deviceId',
        lga: lga,
        ward: ward,
        healthFacility: healthFacility,
        distributionPoint: distributionPoint,
        latitude: lat,
        longitude: lng,
        status: status,
      );

  group('importXlsx', () {
    test('imports the fixture and is idempotent on re-import', () async {
      final bytes =
          File('test/fixtures/sample_traces.xlsx').readAsBytesSync();

      final first = await repository.importXlsx(bytes, fileName: 'a.xlsx');
      expect(first.importedRows, 100);
      expect(first.skippedRows, 0);
      expect(first.rowsWithoutLocation, 8);

      final second = await repository.importXlsx(bytes, fileName: 'a.xlsx');
      final stats = await repository.stats();
      // UNIQUE(device_id, trace_date) replaced the duplicates.
      expect(stats.totalTraces, first.importedRows);
      expect(second.totalTeams, first.totalTeams);

      final history = await repository.importHistory();
      expect(history, hasLength(2));
    });

    test('clearFirst replaces previous data', () async {
      await insert([trace('old-device', lga: 'Ila')]);
      final bytes =
          File('test/fixtures/sample_traces.xlsx').readAsBytesSync();

      await repository.importXlsx(bytes, fileName: 'b.xlsx', clearFirst: true);

      expect(await repository.teamByDeviceId('old-device'), isNull);
    });
  });

  group('currentTeams', () {
    test('returns only the latest trace per device', () async {
      await insert([
        trace('dev1',
            traceDate: DateTime(2026, 6, 1), status: 'ONLINE', lga: 'Ila'),
        trace('dev1',
            traceDate: DateTime(2026, 6, 3), status: 'OFFLINE', lga: 'Ejigbo'),
        trace('dev2', traceDate: DateTime(2026, 6, 2), status: 'ONLINE'),
      ]);

      final teams = await repository.currentTeams();
      expect(teams, hasLength(2));
      final dev1 = teams.singleWhere((t) => t.deviceId == 'dev1');
      expect(dev1.trace.status, 'OFFLINE'); // the later trace wins
      expect(dev1.trace.lga, 'Ejigbo');
    });

    test('onlineOnly filters on the latest trace, not any trace', () async {
      await insert([
        // Was online in the past, latest is offline -> excluded.
        trace('dev1', traceDate: DateTime(2026, 6, 1), status: 'ONLINE'),
        trace('dev1', traceDate: DateTime(2026, 6, 3), status: 'OFFLINE'),
        // Latest is online -> included.
        trace('dev2', traceDate: DateTime(2026, 6, 2), status: 'ONLINE'),
      ]);

      final online = await repository.currentTeams(onlineOnly: true);
      expect(online.map((t) => t.deviceId), ['dev2']);
    });

    test('requireLocation excludes teams without coordinates', () async {
      await insert([
        trace('dev1', lat: 7.5, lng: 4.5),
        trace('dev2'),
      ]);

      final located = await repository.currentTeams(requireLocation: true);
      expect(located.map((t) => t.deviceId), ['dev1']);
    });

    test('geo filter narrows by cascade levels', () async {
      await insert([
        trace('dev1', lga: 'Ila', ward: 'Iperin', healthFacility: 'HF A'),
        trace('dev2', lga: 'Ila', ward: 'Ejemu', healthFacility: 'HF B'),
        trace('dev3', lga: 'Ejigbo', ward: 'Owu', healthFacility: 'HF C'),
      ]);

      final ila = await repository.currentTeams(
          filter: const GeoFilter(lga: 'Ila'));
      expect(ila, hasLength(2));

      final iperin = await repository.currentTeams(
          filter: const GeoFilter(lga: 'Ila', ward: 'Iperin'));
      expect(iperin.map((t) => t.deviceId), ['dev1']);
    });

    test('search matches team name, username and device id', () async {
      await insert([
        trace('abc123', teamName: 'Amobi PHC Mobilizer'),
        trace('def456', teamName: 'Other'),
      ]);

      expect(await repository.currentTeams(search: 'amobi'), hasLength(1));
      expect(await repository.currentTeams(search: 'def4'), hasLength(1));
      expect(await repository.currentTeams(search: 'zzz'), isEmpty);
    });
  });

  group('cascade lookups', () {
    setUp(() => insert([
          trace('dev1', lga: 'Ila', ward: 'Iperin', healthFacility: 'HF A',
              distributionPoint: 'DP A'),
          trace('dev2', lga: 'Ila', ward: 'Ejemu', healthFacility: 'HF B',
              distributionPoint: 'DP B'),
          trace('dev3', lga: 'Ejigbo', ward: 'Owu', healthFacility: 'HF C',
              distributionPoint: 'DP C'),
        ]));

    test('lgas lists distinct values', () async {
      expect(await repository.lgas(), ['Ejigbo', 'Ila']);
    });

    test('wards are scoped by selected LGA', () async {
      expect(await repository.wards(const GeoFilter(lga: 'Ila')),
          ['Ejemu', 'Iperin']);
      expect(await repository.wards(const GeoFilter()), hasLength(3));
    });

    test('health facilities scoped by LGA and ward', () async {
      expect(
        await repository
            .healthFacilities(const GeoFilter(lga: 'Ila', ward: 'Iperin')),
        ['HF A'],
      );
    });

    test('distribution points scoped by upper levels', () async {
      expect(
        await repository.distributionPoints(const GeoFilter(lga: 'Ejigbo')),
        ['DP C'],
      );
    });
  });

  group('stats', () {
    test('empty database reports zeros', () async {
      final stats = await repository.stats();
      expect(stats.hasData, isFalse);
      expect(stats.totalTeams, 0);
      expect(stats.lastImportAt, isNull);
    });

    test('aggregates latest-per-device values', () async {
      await insert([
        trace('dev1',
            traceDate: DateTime(2026, 6, 1), status: 'ONLINE', lat: 7, lng: 4),
        trace('dev1', traceDate: DateTime(2026, 6, 3), status: 'OFFLINE'),
        trace('dev2', status: 'ONLINE', lat: 7.5, lng: 4.5, lga: 'Ila'),
      ]);

      final stats = await repository.stats();
      expect(stats.totalTeams, 2);
      expect(stats.onlineTeams, 1); // dev1's latest is OFFLINE
      expect(stats.offlineTeams, 1);
      expect(stats.teamsWithLocation, 1); // dev1's latest has no coords
      expect(stats.totalTraces, 3);
    });
  });

  group('teamByDeviceId and trace history', () {
    test('returns latest trace and full trail', () async {
      await insert([
        trace('dev1', traceDate: DateTime(2026, 6, 1), status: 'ONLINE'),
        trace('dev1', traceDate: DateTime(2026, 6, 3), status: 'OFFLINE'),
      ]);

      final team = await repository.teamByDeviceId('dev1');
      expect(team, isNotNull);
      expect(team!.trace.status, 'OFFLINE');

      final trail = await repository.tracesForDevice('dev1');
      expect(trail, hasLength(2));
      expect(trail.first.traceDate, DateTime(2026, 6, 3)); // newest first
    });

    test('unknown device returns null', () async {
      expect(await repository.teamByDeviceId('nope'), isNull);
    });
  });
}
