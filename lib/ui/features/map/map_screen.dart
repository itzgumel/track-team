import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/team.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/team_card.dart';
import 'map_view_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team map'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                const Text('Online only'),
                Switch(value: vm.onlineOnly, onChanged: vm.setOnlineOnly),
              ],
            ),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.teams.isEmpty
              ? EmptyState(
                  icon: Icons.map_outlined,
                  title: vm.onlineOnly
                      ? 'No ONLINE teams with a location'
                      : 'No teams with a location',
                  message: vm.onlineOnly
                      ? 'Switch off "Online only" to see offline teams.'
                      : 'Import a device-trace export to see teams here.',
                  action: vm.onlineOnly
                      ? FilledButton.tonal(
                          onPressed: () => vm.setOnlineOnly(false),
                          child: const Text('Show all teams'),
                        )
                      : null,
                )
              : _TeamMap(vm: vm),
    );
  }
}

class _TeamMap extends StatelessWidget {
  const _TeamMap({required this.vm});

  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final pos = vm.position;
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: vm.initialCenter,
            initialZoom: 9,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.trackteam.track_team',
            ),
            MarkerLayer(
              markers: [
                if (pos != null)
                  Marker(
                    point: LatLng(pos.latitude, pos.longitude),
                    width: 22,
                    height: 22,
                    child: const _MyLocationMarker(),
                  ),
                ...vm.teams.map(
                  (team) => Marker(
                    point: LatLng(
                      team.trace.latitude!,
                      team.trace.longitude!,
                    ),
                    width: 18,
                    height: 18,
                    child: GestureDetector(
                      onTap: () => _showTeamSheet(context, team),
                      child: StatusDot(status: team.trace.status, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: Text(
                '${vm.teams.length} team(s) • ${vm.onlineCount} online',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTeamSheet(BuildContext context, Team team) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamCard(team: team),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.push(
                        '/team/${Uri.encodeComponent(team.deviceId)}',
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  const _MyLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black45)],
      ),
    );
  }
}
