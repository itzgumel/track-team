import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../domain/models/device_trace.dart';

/// Result of parsing a device-trace spreadsheet.
class XlsxParseResult {
  const XlsxParseResult({
    required this.traces,
    required this.totalDataRows,
    required this.skippedRows,
    required this.rowsWithoutLocation,
  });

  final List<DeviceTrace> traces;

  /// Data rows found below the header row.
  final int totalDataRows;

  /// Rows dropped because they had no device id.
  final int skippedRows;

  /// Parsed rows that carry no usable coordinates.
  final int rowsWithoutLocation;
}

class XlsxFormatException implements Exception {
  XlsxFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Parses the campaign "deviceTraceDataList" .xlsx export.
///
/// Reads the raw OOXML directly (via `archive` + `xml`) so both cell
/// encodings seen in the wild are supported: inline strings (as produced by
/// the campaign server) and shared strings (as produced by Excel re-saves).
/// Columns are matched by header name, not position, so column reordering
/// between export versions is tolerated.
class XlsxParser {
  static const _mainNs = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';

  XlsxParseResult parse(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw XlsxFormatException('The selected file is not a valid .xlsx workbook.');
    }

    final sharedStrings = _readSharedStrings(archive);
    final sheet = _firstWorksheet(archive);
    final rows = _readRows(sheet, sharedStrings);
    if (rows.isEmpty) {
      throw XlsxFormatException('The workbook contains no rows.');
    }

    final headerIndex = _findHeaderRow(rows);
    if (headerIndex == null) {
      throw XlsxFormatException(
        'Could not find the header row. Expected columns such as '
        '"Device Id", "LGA" and "Status".',
      );
    }
    final columns = _mapColumns(rows[headerIndex]);

    final traces = <DeviceTrace>[];
    var skipped = 0;
    var withoutLocation = 0;
    for (final row in rows.skip(headerIndex + 1)) {
      final trace = _rowToTrace(row, columns);
      if (trace == null) {
        skipped++;
        continue;
      }
      if (!trace.hasLocation) withoutLocation++;
      traces.add(trace);
    }

    return XlsxParseResult(
      traces: traces,
      totalDataRows: rows.length - headerIndex - 1,
      skippedRows: skipped,
      rowsWithoutLocation: withoutLocation,
    );
  }

  List<String> _readSharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return const [];
    final doc = XmlDocument.parse(utf8.decode(file.content));
    return doc
        .findAllElements('si', namespace: _mainNs)
        .map((si) => si
            .findAllElements('t', namespace: _mainNs)
            .map((t) => t.innerText)
            .join())
        .toList();
  }

  XmlDocument _firstWorksheet(Archive archive) {
    final names = archive.files
        .map((f) => f.name)
        .where((n) => n.startsWith('xl/worksheets/') && n.endsWith('.xml'))
        .toList()
      ..sort();
    if (names.isEmpty) {
      throw XlsxFormatException('The workbook contains no worksheets.');
    }
    final file = archive.findFile(names.first)!;
    return XmlDocument.parse(utf8.decode(file.content));
  }

  /// Reads every row as a map of column letter -> cell value.
  ///
  /// Values are [String] for text cells and [num] for numeric cells.
  List<Map<String, Object>> _readRows(XmlDocument sheet, List<String> shared) {
    final rows = <Map<String, Object>>[];
    for (final row in sheet.findAllElements('row', namespace: _mainNs)) {
      final cells = <String, Object>{};
      for (final cell in row.findElements('c', namespace: _mainNs)) {
        final ref = cell.getAttribute('r') ?? '';
        final letters = ref.replaceAll(RegExp(r'[0-9]'), '');
        if (letters.isEmpty) continue;
        final value = _cellValue(cell, shared);
        if (value != null) cells[letters] = value;
      }
      rows.add(cells);
    }
    return rows;
  }

  Object? _cellValue(XmlElement cell, List<String> shared) {
    final type = cell.getAttribute('t') ?? 'n';
    switch (type) {
      case 'inlineStr':
        final inline = cell.getElement('is', namespace: _mainNs);
        if (inline == null) return null;
        final text = inline
            .findAllElements('t', namespace: _mainNs)
            .map((t) => t.innerText)
            .join();
        return text.isEmpty ? null : text;
      case 's':
        final index = int.tryParse(_v(cell) ?? '');
        if (index == null || index < 0 || index >= shared.length) return null;
        final text = shared[index];
        return text.isEmpty ? null : text;
      case 'str':
      case 'b':
        return _v(cell);
      default: // 'n' or untyped numeric
        final raw = _v(cell);
        if (raw == null) return null;
        return num.tryParse(raw) ?? raw;
    }
  }

  String? _v(XmlElement cell) =>
      cell.getElement('v', namespace: _mainNs)?.innerText;

  /// Normalises a header for matching: lowercase, alphanumerics only.
  static String _normalize(String header) =>
      header.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Header aliases -> canonical field key.
  static const Map<String, String> _headerAliases = {
    'deviceid': 'deviceId',
    'imei': 'imei',
    'tracedate': 'traceDate',
    'lastsynchedat': 'lastSyncedAt',
    'lastsyncedat': 'lastSyncedAt',
    'lastsynchedby': 'teamName',
    'lastsyncedby': 'teamName',
    'username': 'userName',
    'usertype': 'userType',
    'country': 'country',
    'state': 'state',
    'lga': 'lga',
    'ward': 'ward',
    'healthfacility': 'healthFacility',
    'distributionpoint': 'distributionPoint',
    'settlement': 'settlement',
    'lastknownlocation': 'location',
    'devicemodel': 'deviceModel',
    'appversion': 'appVersion',
    'status': 'status',
  };

  int? _findHeaderRow(List<Map<String, Object>> rows) {
    final limit = rows.length < 10 ? rows.length : 10;
    for (var i = 0; i < limit; i++) {
      final normalized =
          rows[i].values.whereType<String>().map(_normalize).toSet();
      if (normalized.contains('deviceid') && normalized.contains('status')) {
        return i;
      }
    }
    return null;
  }

  /// Maps column letters to canonical field keys using the header row.
  Map<String, String> _mapColumns(Map<String, Object> headerRow) {
    final mapping = <String, String>{};
    headerRow.forEach((letter, value) {
      if (value is! String) return;
      final field = _headerAliases[_normalize(value)];
      if (field != null) mapping[letter] = field;
    });
    return mapping;
  }

  DeviceTrace? _rowToTrace(
    Map<String, Object> row,
    Map<String, String> columns,
  ) {
    final fields = <String, Object>{};
    row.forEach((letter, value) {
      final field = columns[letter];
      if (field != null) fields[field] = value;
    });

    final deviceId = _string(fields['deviceId']);
    if (deviceId == null || deviceId.isEmpty) return null;

    final coords = parseLatLng(_string(fields['location']));
    return DeviceTrace(
      deviceId: deviceId,
      imei: _string(fields['imei']),
      traceDate: parseExcelDate(fields['traceDate']),
      lastSyncedAt: parseExcelDate(fields['lastSyncedAt']),
      teamName: _string(fields['teamName']),
      userName: _string(fields['userName']),
      userType: _string(fields['userType']),
      country: _string(fields['country']),
      state: _string(fields['state']),
      lga: _string(fields['lga']),
      ward: _string(fields['ward']),
      healthFacility: _string(fields['healthFacility']),
      distributionPoint: _string(fields['distributionPoint']),
      settlement: _string(fields['settlement']),
      latitude: coords?.$1,
      longitude: coords?.$2,
      deviceModel: _string(fields['deviceModel']),
      appVersion: _string(fields['appVersion']),
      status: _string(fields['status'])?.toUpperCase() ?? 'OFFLINE',
    );
  }

  String? _string(Object? value) {
    final text = switch (value) {
      null => null,
      String s => s.trim(),
      num n => n.toString(),
      _ => value.toString().trim(),
    };
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Excel serial day 0 in the default 1900 date system.
  static final DateTime _excelEpoch = DateTime(1899, 12, 30);

  /// Converts a cell value to a [DateTime].
  ///
  /// Numeric values are Excel serial dates (days since 1899-12-30, fraction
  /// is time of day). Strings are parsed as ISO-8601 or `dd/MM/yyyy HH:mm`.
  static DateTime? parseExcelDate(Object? value) {
    switch (value) {
      case null:
        return null;
      case num serial:
        if (serial <= 0) return null;
        return _excelEpoch
            .add(Duration(milliseconds: (serial * 86400000).round()));
      case String text:
        final trimmed = text.trim();
        if (trimmed.isEmpty) return null;
        final serial = num.tryParse(trimmed);
        if (serial != null) return parseExcelDate(serial);
        final iso = DateTime.tryParse(trimmed);
        if (iso != null) return iso;
        return _parseSlashDate(trimmed);
      default:
        return null;
    }
  }

  static DateTime? _parseSlashDate(String text) {
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(text);
    if (match == null) return null;
    int part(int i) => int.tryParse(match.group(i) ?? '') ?? 0;
    final day = part(1), month = part(2), year = part(3);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day, part(4), part(5), part(6));
  }

  /// Parses a `"lat, lng"` string into coordinates, or null when absent or
  /// out of range.
  static (double, double)? parseLatLng(String? value) {
    if (value == null) return null;
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    if (lat == 0 && lng == 0) return null;
    return (lat, lng);
  }
}
