import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/import_result.dart';
import '../../core/formatters.dart';
import 'import_view_model.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ImportViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Import team data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device-trace export', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Export deviceTraceDataList as .xlsx from the campaign '
                    'server, transfer it to this device, then import it '
                    'here. Re-importing the same file is safe — rows are '
                    'merged, not duplicated.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Replace existing data'),
                    subtitle: const Text(
                      'Clear all previously imported traces first',
                    ),
                    value: vm.clearFirst,
                    onChanged: vm.importing ? null : vm.setClearFirst,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: vm.importing ? null : vm.pickAndImport,
                      icon: vm.importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        vm.importing ? 'Importing…' : 'Choose .xlsx file',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (vm.error != null) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                title: Text(
                  vm.error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
          if (vm.lastResult != null) ...[
            const SizedBox(height: 12),
            _ResultCard(result: vm.lastResult!),
          ],
          if (vm.history.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Import history', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            ...vm.history.map(
              (record) => ListTile(
                dense: true,
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  record.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${Formatters.dateTime(record.importedAt)} • '
                  '${record.rowCount} rows • ${record.teamCount} teams',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ImportResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Import complete',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _line(context, '${result.importedRows} rows imported '
                '(${result.skippedRows} skipped)'),
            _line(context, '${result.totalTeams} teams total • '
                '${result.onlineTeams} online'),
            if (result.rowsWithoutLocation > 0)
              _line(
                context,
                '${result.rowsWithoutLocation} rows have no coordinates and '
                'are excluded from distance features',
              ),
            if (result.clearedExisting)
              _line(context, 'Previous data was cleared before import'),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
