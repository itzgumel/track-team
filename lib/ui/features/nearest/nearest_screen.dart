import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/location_service.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/team_card.dart';
import 'nearest_view_model.dart';

class NearestScreen extends StatelessWidget {
  const NearestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NearestViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearest teams'),
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            icon: const Icon(Icons.my_location),
            onPressed: vm.refresh,
          ),
        ],
      ),
      body: switch (vm.status) {
        NearestStatus.locating => const _ProgressMessage(
            message: 'Getting your location…',
          ),
        NearestStatus.loading => const _ProgressMessage(
            message: 'Finding teams near you…',
          ),
        NearestStatus.locationFailed => _LocationFailedView(vm: vm),
        NearestStatus.ready => _TeamListView(vm: vm),
      },
    );
  }
}

class _ProgressMessage extends StatelessWidget {
  const _ProgressMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

class _LocationFailedView extends StatelessWidget {
  const _LocationFailedView({required this.vm});

  final NearestViewModel vm;

  @override
  Widget build(BuildContext context) {
    final (title, message, action) = switch (vm.failure!) {
      LocationFailure.serviceDisabled => (
          'Location is switched off',
          'Turn on device location (GPS) to find the closest teams.',
          FilledButton(
            onPressed: vm.openLocationSettings,
            child: const Text('Open location settings'),
          ),
        ),
      LocationFailure.permissionDenied => (
          'Location permission needed',
          'Track Team uses your position only to sort teams by distance.',
          FilledButton(
            onPressed: vm.refresh,
            child: const Text('Grant permission'),
          ),
        ),
      LocationFailure.permissionDeniedForever => (
          'Location permission blocked',
          'Enable the location permission for Track Team in app settings.',
          FilledButton(
            onPressed: vm.openAppSettings,
            child: const Text('Open app settings'),
          ),
        ),
      LocationFailure.unavailable => (
          'Could not get a GPS fix',
          'Move to an open area and try again.',
          FilledButton(
            onPressed: vm.refresh,
            child: const Text('Retry'),
          ),
        ),
    };
    return EmptyState(
      icon: Icons.location_disabled,
      title: title,
      message: message,
      action: action,
    );
  }
}

class _TeamListView extends StatelessWidget {
  const _TeamListView({required this.vm});

  final NearestViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text('Online (${vm.onlineWithLocation})'),
                      icon: const Icon(Icons.wifi, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('All (${vm.totalWithLocation})'),
                      icon: const Icon(Icons.groups, size: 16),
                    ),
                  ],
                  selected: {vm.onlineOnly},
                  onSelectionChanged: (s) => vm.setOnlineOnly(s.first),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: vm.teams.isEmpty
              ? _emptyView(context)
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16, top: 4),
                    itemCount: vm.teams.length,
                    itemBuilder: (context, index) =>
                        TeamCard(team: vm.teams[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _emptyView(BuildContext context) {
    if (vm.totalWithLocation == 0) {
      return const EmptyState(
        icon: Icons.location_off_outlined,
        title: 'No teams with a known location',
        message: 'Import a device-trace export that includes '
            '"Last Known Location" coordinates.',
      );
    }
    // Teams exist but none are ONLINE — offer the fallback instead of a
    // dead end (exports can legitimately contain zero online devices).
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'No ONLINE teams right now',
      message: '${vm.totalWithLocation} team(s) with a location are '
          'currently offline. You can still view and navigate to them.',
      action: FilledButton.tonal(
        onPressed: () => vm.setOnlineOnly(false),
        child: const Text('Show all teams'),
      ),
    );
  }
}
