import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/team_repository.dart';
import '../../../data/services/maps_launcher_service.dart';
import '../../../domain/models/device_trace.dart';
import '../../../domain/models/team.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_chip.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Team? _team;
  List<DeviceTrace> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = context.read<TeamRepository>();
    final team = await repository.teamByDeviceId(widget.deviceId);
    final history = await repository.tracesForDevice(widget.deviceId);
    if (!mounted) return;
    setState(() {
      _team = team;
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    return Scaffold(
      appBar: AppBar(title: Text(team?.displayName ?? 'Team details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : team == null
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'Team not found',
                  message: 'This device is not in the imported data.',
                )
              : _DetailBody(team: team, history: _history),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.team, required this.history});

  final Team team;
  final List<DeviceTrace> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trace = team.trace;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team.displayName,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    StatusChip(status: trace.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Last synced ${Formatters.timeAgo(trace.lastSyncedAt)}'
                  ' (${Formatters.dateTime(trace.lastSyncedAt)})',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (trace.hasLocation)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.directions),
                          label: const Text('Navigate'),
                          onPressed: () => context
                              .read<MapsLauncherService>()
                              .navigateTo(trace.latitude!, trace.longitude!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.place_outlined),
                          label: const Text('Show pin'),
                          onPressed: () => context
                              .read<MapsLauncherService>()
                              .showOnMap(trace.latitude!, trace.longitude!),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'No location reported for this device.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              if (trace.hasLocation)
                ListTile(
                  leading: const Icon(Icons.pin_drop_outlined),
                  title: Text('${trace.latitude}, ${trace.longitude}'),
                  subtitle: const Text('Last known location'),
                  trailing: IconButton(
                    tooltip: 'Copy coordinates',
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(
                        text: '${trace.latitude}, ${trace.longitude}',
                      ));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coordinates copied')),
                        );
                      }
                    },
                  ),
                ),
              _infoTile(Icons.route_outlined, 'Area',
                  trace.hierarchyLabel.isEmpty ? '—' : trace.hierarchyLabel),
              _infoTile(Icons.person_outline, 'Username',
                  trace.userName ?? '—'),
              _infoTile(Icons.phone_android_outlined, 'Device',
                  '${trace.deviceModel ?? 'Unknown model'}\n${trace.deviceId}'),
              if (trace.imei != null)
                _infoTile(Icons.qr_code_2_outlined, 'IMEI', trace.imei!),
              if (trace.appVersion != null)
                _infoTile(Icons.apps_outlined, 'App version',
                    trace.appVersion!),
            ],
          ),
        ),
        if (history.length > 1) ...[
          const SizedBox(height: 16),
          Text('Sync trail (${history.length})',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: history
                  .take(20)
                  .map(
                    (t) => ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.history,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(Formatters.dateTime(t.traceDate)),
                      subtitle: t.hasLocation
                          ? Text('${t.latitude}, ${t.longitude}')
                          : const Text('No location'),
                      trailing: StatusChip(status: t.status, dense: true),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(value),
      subtitle: Text(label),
    );
  }
}
