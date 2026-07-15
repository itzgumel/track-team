@Skip('Run manually against a real export: '
    'FULL_EXPORT_PATH=/path/to/deviceTraceDataList.xlsx '
    'flutter test test/full_export_smoke_test.dart --run-skipped')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:track_team/data/services/xlsx_parser.dart';

/// Sanity check against a full production export (thousands of rows).
/// Not part of the normal suite; see the @Skip note above.
void main() {
  test('parses a full deviceTraceDataList export', () {
    final path = Platform.environment['FULL_EXPORT_PATH'];
    expect(path, isNotNull, reason: 'Set FULL_EXPORT_PATH');

    final stopwatch = Stopwatch()..start();
    final result = XlsxParser().parse(File(path!).readAsBytesSync());
    stopwatch.stop();

    // ignore: avoid_print
    print('Parsed ${result.traces.length} rows '
        '(${result.rowsWithoutLocation} without location, '
        '${result.skippedRows} skipped) '
        'in ${stopwatch.elapsedMilliseconds} ms');

    expect(result.traces, isNotEmpty);
    expect(result.skippedRows, 0);
  });
}
