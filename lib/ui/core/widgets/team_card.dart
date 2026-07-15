import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/services/maps_launcher_service.dart';
import '../../../domain/models/team.dart';
import '../formatters.dart';
import '../theme.dart';
import 'status_chip.dart';

/// List card for a team: name, hierarchy, freshness, distance, and a
/// one-tap Google Maps navigation button. Tapping the card opens details.
class TeamCard extends StatelessWidget {
  const TeamCard({super.key, required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trace = team.trace;
    final stale = Formatters.isStale(trace.lastSyncedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/team/${Uri.encodeComponent(team.deviceId)}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.displayName,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusChip(status: trace.status, dense: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trace.hierarchyLabel.isEmpty
                          ? 'No area assigned'
                          : trace.hierarchyLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          stale ? Icons.history_toggle_off : Icons.sync,
                          size: 14,
                          color: stale
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.timeAgo(trace.lastSyncedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: stale
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (team.distanceMeters != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.near_me,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.distance(team.distanceMeters),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _NavigateButton(team: team),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigateButton extends StatelessWidget {
  const _NavigateButton({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final trace = team.trace;
    if (!trace.hasLocation) {
      return Tooltip(
        message: 'No location reported',
        child: Icon(
          Icons.location_off_outlined,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return IconButton.filled(
      tooltip: 'Navigate with Google Maps',
      icon: const Icon(Icons.directions),
      onPressed: () async {
        final launched = await context
            .read<MapsLauncherService>()
            .navigateTo(trace.latitude!, trace.longitude!);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      },
    );
  }
}

/// Colored map/status dot used by the map markers and legends.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status, this.size = 16});

  final String status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status, Theme.of(context).brightness);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black38)],
      ),
    );
  }
}
