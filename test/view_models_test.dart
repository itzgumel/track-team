import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:track_team/data/repositories/team_repository.dart';
import 'package:track_team/data/services/database_service.dart';
import 'package:track_team/data/services/location_service.dart';
import 'package:track_team/data/services/xlsx_parser.dart';
import 'package:track_team/domain/models/device_trace.dart';
import 'package:track_team/ui/features/browse/browse_view_model.dart';
import 'package:track_team/ui/features/nearest/nearest_view_model.dart';

/// Location fake: either a fixed position or a failure, no platform calls.
class FakeLocationService extends LocationService {
  const FakeLocationService({this.latitude, this.longitude, this.failure});

  final double? latitude;
  final double? longitude;
  final LocationFailure? failure;

  @override
  Future<LocationState> getCurrentPosition() async {
    if (failure != null) return LocationUnavailable(failure!);
    return LocationAvailable(Position(
      latitude: latitude!,
      longitude: longitude!,
      timestamp: DateTime(2026, 7, 15),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ));
  }
}

Future<void> pumpUntil(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue, reason: 'condition not met within 1s');
}

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

  Future<void> seed() async {
    final db = await databaseService.database;
    final traces = [
      // ~1.5 km from the fake position (7.50, 4.50).
      const DeviceTrace(
        deviceId: 'near-online',
        teamName: 'Near Online',
        status: 'ONLINE',
        latitude: 7.513,
        longitude: 4.50,
        lga: 'Ila',
        ward: 'Iperin',
      ),
      // ~11 km away.
      const DeviceTrace(
        deviceId: 'far-online',
        teamName: 'Far Online',
        status: 'ONLINE',
        latitude: 7.60,
        longitude: 4.50,
        lga: 'Ejigbo',
        ward: 'Owu',
      ),
      // Closest of all, but offline.
      const DeviceTrace(
        deviceId: 'nearest-offline',
        teamName: 'Nearest Offline',
        status: 'OFFLINE',
        latitude: 7.501,
        longitude: 4.50,
        lga: 'Ila',
        ward: 'Ejemu',
      ),
      // No location at all.
      const DeviceTrace(
        deviceId: 'no-location',
        teamName: 'No Location',
        status: 'ONLINE',
        lga: 'Ila',
        ward: 'Iperin',
      ),
    ];
    for (final t in traces) {
      await db.insert('device_traces', t.toDbMap());
    }
  }

  group('NearestViewModel', () {
    test('sorts online teams by distance from GPS position', () async {
      await seed();
      final vm = NearestViewModel(
        repository,
        const FakeLocationService(latitude: 7.50, longitude: 4.50),
      );
      await pumpUntil(() => vm.status == NearestStatus.ready);

      expect(vm.teams.map((t) => t.deviceId), ['near-online', 'far-online']);
      expect(vm.teams.first.distanceMeters, lessThan(2000));
      expect(vm.teams.last.distanceMeters, greaterThan(10000));
      expect(vm.onlineWithLocation, 2);
      expect(vm.totalWithLocation, 3); // no-location team excluded
      vm.dispose();
    });

    test('"show all" includes offline teams, still distance-sorted', () async {
      await seed();
      final vm = NearestViewModel(
        repository,
        const FakeLocationService(latitude: 7.50, longitude: 4.50),
      );
      await pumpUntil(() => vm.status == NearestStatus.ready);

      await vm.setOnlineOnly(false);
      expect(
        vm.teams.map((t) => t.deviceId),
        ['nearest-offline', 'near-online', 'far-online'],
      );
      vm.dispose();
    });

    test('surfaces permission failure', () async {
      final vm = NearestViewModel(
        repository,
        const FakeLocationService(
          failure: LocationFailure.permissionDeniedForever,
        ),
      );
      await pumpUntil(() => vm.status == NearestStatus.locationFailed);
      expect(vm.failure, LocationFailure.permissionDeniedForever);
      vm.dispose();
    });
  });

  group('BrowseViewModel', () {
    test('cascade options narrow with each selection', () async {
      await seed();
      final vm = BrowseViewModel(
        repository,
        const FakeLocationService(failure: LocationFailure.serviceDisabled),
      );
      await pumpUntil(() => !vm.loading);

      expect(vm.lgas, ['Ejigbo', 'Ila']);
      expect(vm.teams, hasLength(4));
      expect(vm.hasPosition, isFalse);

      await vm.selectLga('Ila');
      expect(vm.wards, ['Ejemu', 'Iperin']);
      expect(vm.teams.map((t) => t.deviceId),
          containsAll(['near-online', 'nearest-offline', 'no-location']));
      expect(vm.teams, hasLength(3));

      await vm.selectWard('Iperin');
      expect(vm.teams.map((t) => t.deviceId),
          containsAll(['near-online', 'no-location']));
      vm.dispose();
    });

    test('changing LGA resets dependent levels', () async {
      await seed();
      final vm = BrowseViewModel(
        repository,
        const FakeLocationService(failure: LocationFailure.serviceDisabled),
      );
      await pumpUntil(() => !vm.loading);

      await vm.selectLga('Ila');
      await vm.selectWard('Iperin');
      expect(vm.filter.ward, 'Iperin');

      await vm.selectLga('Ejigbo');
      expect(vm.filter.ward, isNull);
      expect(vm.wards, ['Owu']);
      vm.dispose();
    });

    test('teams without location sort after teams with distance', () async {
      await seed();
      final vm = BrowseViewModel(
        repository,
        const FakeLocationService(latitude: 7.50, longitude: 4.50),
      );
      await pumpUntil(() => !vm.loading);

      expect(vm.hasPosition, isTrue);
      expect(vm.teams.last.deviceId, 'no-location');
      expect(vm.teams.first.deviceId, 'nearest-offline');
      vm.dispose();
    });
  });
}
