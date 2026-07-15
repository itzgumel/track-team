import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/team_repository.dart';
import 'data/services/database_service.dart';
import 'data/services/location_service.dart';
import 'data/services/maps_launcher_service.dart';
import 'data/services/xlsx_parser.dart';
import 'routing/app_router.dart';
import 'ui/core/theme.dart';

void main() {
  runApp(const TrackTeamApp());
}

class TrackTeamApp extends StatelessWidget {
  const TrackTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => DatabaseService(), dispose: (_, s) => s.close()),
        Provider(create: (_) => XlsxParser()),
        Provider(create: (_) => const LocationService()),
        Provider(create: (_) => const MapsLauncherService()),
        ChangeNotifierProvider(
          create: (c) => TeamRepository(
            c.read<DatabaseService>(),
            c.read<XlsxParser>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Track Team',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: buildRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
