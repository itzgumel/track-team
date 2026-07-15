import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/team_repository.dart';
import '../data/services/location_service.dart';
import '../ui/features/browse/browse_screen.dart';
import '../ui/features/browse/browse_view_model.dart';
import '../ui/features/home/home_screen.dart';
import '../ui/features/home/home_view_model.dart';
import '../ui/features/import/import_screen.dart';
import '../ui/features/import/import_view_model.dart';
import '../ui/features/map/map_screen.dart';
import '../ui/features/map/map_view_model.dart';
import '../ui/features/nearest/nearest_screen.dart';
import '../ui/features/nearest/nearest_view_model.dart';
import '../ui/features/team_detail/team_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() => GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (c) => HomeViewModel(c.read<TeamRepository>()),
                  child: const HomeScreen(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/nearest',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (c) => NearestViewModel(
                    c.read<TeamRepository>(),
                    c.read<LocationService>(),
                  ),
                  child: const NearestScreen(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/browse',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (c) => BrowseViewModel(
                    c.read<TeamRepository>(),
                    c.read<LocationService>(),
                  ),
                  child: const BrowseScreen(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (c) => MapViewModel(
                    c.read<TeamRepository>(),
                    c.read<LocationService>(),
                  ),
                  child: const MapScreen(),
                ),
              ),
            ]),
          ],
        ),
        GoRoute(
          path: '/import',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => ChangeNotifierProvider(
            create: (c) => ImportViewModel(c.read<TeamRepository>()),
            child: const ImportScreen(),
          ),
        ),
        GoRoute(
          path: '/team/:deviceId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => TeamDetailScreen(
            deviceId: state.pathParameters['deviceId'] ?? '',
          ),
        ),
      ],
    );

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.near_me_outlined),
            selectedIcon: Icon(Icons.near_me),
            label: 'Nearest',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
