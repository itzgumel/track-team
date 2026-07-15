import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/team_card.dart';
import 'browse_view_model.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrowseViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse by area'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                const Text('Online only'),
                Switch(
                  value: vm.onlineOnly,
                  onChanged: vm.setOnlineOnly,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _CascadeFilters(vm: vm),
          const Divider(height: 1),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.teams.isEmpty
                    ? EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No teams in this selection',
                        message: vm.onlineOnly
                            ? 'Try switching off "Online only" or widening '
                                'the area filters.'
                            : 'Try widening the area filters, or import '
                                'fresh data.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        itemCount: vm.teams.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text(
                                '${vm.teams.length} team(s)'
                                '${vm.hasPosition ? ' • sorted by distance' : ''}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            );
                          }
                          return TeamCard(team: vm.teams[index - 1]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CascadeFilters extends StatelessWidget {
  const _CascadeFilters({required this.vm});

  final BrowseViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _LevelDropdown(
                  label: 'LGA',
                  value: vm.filter.lga,
                  options: vm.lgas,
                  onChanged: vm.selectLga,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LevelDropdown(
                  label: 'Ward',
                  value: vm.filter.ward,
                  options: vm.wards,
                  onChanged: vm.selectWard,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LevelDropdown(
                  label: 'Health Facility',
                  value: vm.filter.healthFacility,
                  options: vm.healthFacilities,
                  onChanged: vm.selectHealthFacility,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LevelDropdown(
                  label: 'Distribution Point',
                  value: vm.filter.distributionPoint,
                  options: vm.distributionPoints,
                  onChanged: vm.selectDistributionPoint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelDropdown extends StatelessWidget {
  const _LevelDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            'All',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        ...options.map(
          (o) => DropdownMenuItem<String?>(
            value: o,
            child: Text(o, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
