import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:track_team/data/repositories/team_repository.dart';
import 'package:track_team/data/services/database_service.dart';
import 'package:track_team/data/services/maps_launcher_service.dart';
import 'package:track_team/data/services/xlsx_parser.dart';
import 'package:track_team/domain/models/dashboard_stats.dart';
import 'package:track_team/domain/models/device_trace.dart';
import 'package:track_team/domain/models/geo_filter.dart';
import 'package:track_team/domain/models/team.dart';
import 'package:track_team/ui/core/widgets/team_card.dart';
import 'package:track_team/ui/features/home/home_screen.dart';
import 'package:track_team/ui/features/home/home_view_model.dart';

/// In-memory repository stand-in: widget tests must not touch a real
/// database — its platform-thread futures never complete under the fake
/// clock that `testWidgets` runs on.
class FakeTeamRepository extends TeamRepository {
  FakeTeamRepository({
    this.fakeStats = DashboardStats.empty,
    this.teams = const [],
    // The lazily-opened DatabaseService is never touched by the overrides.
  }) : super(DatabaseService(), XlsxParser());

  final DashboardStats fakeStats;
  final List<Team> teams;

  @override
  Future<DashboardStats> stats() async => fakeStats;

  @override
  Future<List<Team>> currentTeams({
    GeoFilter filter = const GeoFilter(),
    bool onlineOnly = false,
    bool requireLocation = false,
    String? search,
  }) async =>
      teams;
}

void main() {
  group('HomeScreen', () {
    Widget wrap(TeamRepository repository) => MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => HomeViewModel(repository),
            child: const HomeScreen(),
          ),
        );

    testWidgets('shows import call-to-action when database is empty',
        (tester) async {
      await tester.pumpWidget(wrap(FakeTeamRepository()));
      await tester.pumpAndSettle();

      expect(find.text('No team data yet'), findsOneWidget);
      expect(find.text('Import spreadsheet'), findsOneWidget);
    });

    testWidgets('shows stats once data exists', (tester) async {
      final repository = FakeTeamRepository(
        fakeStats: const DashboardStats(
          totalTeams: 12,
          onlineTeams: 3,
          offlineTeams: 9,
          teamsWithLocation: 11,
          totalTraces: 40,
          lgaCount: 4,
        ),
      );
      await tester.pumpWidget(wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Nearest to me'), findsOneWidget);
      expect(find.text('Browse by area'), findsOneWidget);
    });

    testWidgets('search shows matching teams', (tester) async {
      final repository = FakeTeamRepository(
        fakeStats: const DashboardStats(
          totalTeams: 1,
          onlineTeams: 0,
          offlineTeams: 1,
          teamsWithLocation: 1,
          totalTraces: 1,
          lgaCount: 1,
        ),
        teams: const [
          Team(
            trace: DeviceTrace(
              deviceId: 'abc123',
              teamName: 'Amobi PHC Mobilizer',
              status: 'OFFLINE',
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(create: (_) => const MapsLauncherService()),
          ],
          child: wrap(repository),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'amobi');
      // Step past the 250 ms search debounce timer.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('1 team(s) found'), findsOneWidget);
      expect(find.text('Amobi PHC Mobilizer'), findsOneWidget);
    });
  });

  group('TeamCard', () {
    Widget wrap(Team team) => MultiProvider(
          providers: [
            Provider(create: (_) => const MapsLauncherService()),
          ],
          child: MaterialApp(home: Scaffold(body: TeamCard(team: team))),
        );

    testWidgets('renders name, hierarchy, status and distance',
        (tester) async {
      const trace = DeviceTrace(
        deviceId: 'dev1',
        teamName: 'Amobi PHC Mobilizer',
        status: 'ONLINE',
        latitude: 7.7,
        longitude: 4.4,
        lga: 'Ayedire',
        ward: 'Amobi',
        healthFacility: 'Amobi PHC',
        distributionPoint: 'Amobi PHC',
      );
      await tester.pumpWidget(
        wrap(const Team(trace: trace, distanceMeters: 3247)),
      );

      expect(find.text('Amobi PHC Mobilizer'), findsOneWidget);
      expect(find.text('Ayedire › Amobi › Amobi PHC'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('3.2 km'), findsOneWidget);
      expect(find.byIcon(Icons.directions), findsOneWidget);
    });

    testWidgets('shows location-off indicator when no coordinates',
        (tester) async {
      const trace = DeviceTrace(deviceId: 'dev1', teamName: 'No Loc Team');
      await tester.pumpWidget(wrap(const Team(trace: trace)));

      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.directions), findsNothing);
    });
  });
}
