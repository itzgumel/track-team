import 'package:flutter/material.dart';

import '../theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color =
        AppTheme.statusColor(status, Theme.of(context).brightness);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: dense ? 8 : 10, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
