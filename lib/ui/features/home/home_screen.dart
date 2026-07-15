import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/team_card.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Team'),
        actions: [
          IconButton(
            tooltip: 'Import data',
            icon: const Icon(Icons.upload_file),
            onPressed: () => context.push('/import'),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : !vm.stats.hasData
              ? EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No team data yet',
                  message:
                      'Import the deviceTraceDataList export (.xlsx) from the '
                      'campaign server to start tracking field teams.',
                  action: FilledButton.icon(
                    onPressed: () => context.push('/import'),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import spreadsheet'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    children: [
                      _SearchField(vm: vm),
                      const SizedBox(height: 12),
                      if (vm.searchQuery.isNotEmpty)
                        ..._searchResults(vm)
                      else ...[
                        _StatsGrid(vm: vm),
                        const SizedBox(height: 12),
                        _LastImportCard(vm: vm),
                        const SizedBox(height: 12),
                        _QuickActions(theme: theme),
                      ],
                    ],
                  ),
                ),
    );
  }

  List<Widget> _searchResults(HomeViewModel vm) {
    if (vm.searchResults.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 32),
          child: EmptyState(
            icon: Icons.search_off,
            title: 'No teams match your search',
          ),
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text('${vm.searchResults.length} team(s) found'),
      ),
      ...vm.searchResults.map((t) => TeamCard(team: t)),
    ];
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: vm.search,
      decoration: InputDecoration(
        hintText: 'Search team, user or device id…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: vm.searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  vm.search('');
                },
              ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final stats = vm.stats;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Teams',
            value: '${stats.totalTeams}',
            icon: Icons.groups,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Online',
            value: '${stats.onlineTeams}',
            icon: Icons.wifi,
            emphasize: stats.onlineTeams > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Offline',
            value: '${stats.offlineTeams}',
            icon: Icons.wifi_off,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'LGAs',
            value: '${stats.lgaCount}',
            icon: Icons.map_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = emphasize
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _LastImportCard extends StatelessWidget {
  const _LastImportCard({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final stats = vm.stats;
    final theme = Theme.of(context);
    final stale = Formatters.isStale(stats.lastImportAt);
    return Card(
      child: ListTile(
        leading: Icon(
          stale ? Icons.warning_amber : Icons.check_circle_outline,
          color: stale ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        title: Text(
          'Data imported ${Formatters.timeAgo(stats.lastImportAt)}',
        ),
        subtitle: Text(
          stale
              ? 'Data may be outdated — import a fresh export.'
              : '${stats.totalTraces} traces • '
                  '${stats.teamsWithLocation} teams with location',
        ),
        trailing: TextButton(
          onPressed: () => context.push('/import'),
          child: const Text('Import'),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text('Find a team', style: theme.textTheme.titleSmall),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Nearest to me'),
            subtitle: const Text('Auto-detect with GPS, sorted by distance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/nearest'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: const Text('Browse by area'),
            subtitle:
                const Text('LGA → Ward → Health Facility → Distribution Point'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/browse'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Map view'),
            subtitle: const Text('All teams on an interactive map'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/map'),
          ),
        ),
      ],
    );
  }
}
