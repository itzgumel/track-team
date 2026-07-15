import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:track_team/data/services/xlsx_parser.dart';

void main() {
  final parser = XlsxParser();

  group('XlsxParser with real export fixture', () {
    // test/fixtures/sample_traces.xlsx is a 100-row slice of a real
    // deviceTraceDataList export: 92 rows with coordinates, 8 without.
    // It uses inline-string cells, exactly like the campaign server output.
    late XlsxParseResult result;

    setUpAll(() {
      final bytes =
          File('test/fixtures/sample_traces.xlsx').readAsBytesSync();
      result = parser.parse(bytes);
    });

    test('parses every data row', () {
      expect(result.totalDataRows, 100);
      expect(result.traces, hasLength(100));
      expect(result.skippedRows, 0);
    });

    test('counts rows without coordinates', () {
      expect(result.rowsWithoutLocation, 8);
      expect(result.traces.where((t) => t.hasLocation), hasLength(92));
    });

    test('maps columns by header name', () {
      final first = result.traces.first;
      expect(first.deviceId, '02ca4d513f95a350');
      expect(first.teamName, 'Amobi PHC Mobilzer');
      expect(first.userName, 'amobiphc');
      expect(first.country, 'Nigeria');
      expect(first.state, 'Osun');
      expect(first.lga, 'Ayedire');
      expect(first.ward, 'Amobi');
      expect(first.healthFacility, 'Amobi PHC');
      expect(first.distributionPoint, 'Amobi PHC');
      expect(first.status, 'OFFLINE');
      expect(first.latitude, closeTo(7.7028161, 1e-9));
      expect(first.longitude, closeTo(4.4556788, 1e-9));
    });

    test('converts Excel serial trace dates', () {
      final first = result.traces.first;
      // Serial 46177.50242506945 = 2026-06-04, shortly after 12:03.
      expect(first.traceDate, isNotNull);
      expect(first.traceDate!.year, 2026);
      expect(first.traceDate!.month, 6);
      expect(first.traceDate!.day, 4);
      expect(first.traceDate!.hour, 12);
      expect(first.lastSyncedAt, first.traceDate);
    });
  });

  group('XlsxParser error handling', () {
    test('rejects non-xlsx bytes', () {
      expect(
        () => parser.parse(File('test/xlsx_parser_test.dart').readAsBytesSync()),
        throwsA(isA<XlsxFormatException>()),
      );
    });
  });

  group('parseExcelDate', () {
    test('epoch anchor: serial 25569 is 1970-01-01', () {
      expect(XlsxParser.parseExcelDate(25569), DateTime(1970, 1, 1));
    });

    test('fraction is time of day', () {
      expect(
        XlsxParser.parseExcelDate(25569.5),
        DateTime(1970, 1, 1, 12, 0),
      );
    });

    test('numeric strings are treated as serials', () {
      expect(XlsxParser.parseExcelDate('25569.25'),
          DateTime(1970, 1, 1, 6, 0));
    });

    test('ISO strings parse', () {
      expect(
        XlsxParser.parseExcelDate('2026-06-05T10:30:00'),
        DateTime(2026, 6, 5, 10, 30),
      );
    });

    test('dd/MM/yyyy HH:mm strings parse', () {
      expect(
        XlsxParser.parseExcelDate('05/06/2026 10:30'),
        DateTime(2026, 6, 5, 10, 30),
      );
    });

    test('garbage returns null', () {
      expect(XlsxParser.parseExcelDate('soon'), isNull);
      expect(XlsxParser.parseExcelDate(null), isNull);
      expect(XlsxParser.parseExcelDate(0), isNull);
    });
  });

  group('parseLatLng', () {
    test('parses "lat, lng"', () {
      expect(XlsxParser.parseLatLng('7.7028161, 4.4556788'),
          (7.7028161, 4.4556788));
    });

    test('tolerates missing space and negatives', () {
      expect(XlsxParser.parseLatLng('-1.5,30.25'), (-1.5, 30.25));
    });

    test('rejects malformed values', () {
      expect(XlsxParser.parseLatLng(null), isNull);
      expect(XlsxParser.parseLatLng(''), isNull);
      expect(XlsxParser.parseLatLng('7.7'), isNull);
      expect(XlsxParser.parseLatLng('a, b'), isNull);
      expect(XlsxParser.parseLatLng('1, 2, 3'), isNull);
    });

    test('rejects out-of-range and null island', () {
      expect(XlsxParser.parseLatLng('91, 0'), isNull);
      expect(XlsxParser.parseLatLng('0, 181'), isNull);
      expect(XlsxParser.parseLatLng('0, 0'), isNull);
    });
  });
}
