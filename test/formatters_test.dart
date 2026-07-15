import 'package:flutter_test/flutter_test.dart';
import 'package:track_team/ui/core/formatters.dart';

void main() {
  group('distance', () {
    test('meters below 1 km', () {
      expect(Formatters.distance(850), '850 m');
      expect(Formatters.distance(999.4), '999 m');
    });

    test('kilometers with one decimal', () {
      expect(Formatters.distance(1000), '1.0 km');
      expect(Formatters.distance(3247), '3.2 km');
      expect(Formatters.distance(15890), '15.9 km');
    });

    test('unknown distance', () {
      expect(Formatters.distance(null), '—');
    });
  });

  group('timeAgo', () {
    final now = DateTime(2026, 7, 15, 12, 0);

    test('recent syncs', () {
      expect(Formatters.timeAgo(now, now: now), 'just now');
      expect(
        Formatters.timeAgo(now.subtract(const Duration(minutes: 25)), now: now),
        '25 min ago',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(hours: 3)), now: now),
        '3 h ago',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(days: 2)), now: now),
        '2 d ago',
      );
    });

    test('never synced', () {
      expect(Formatters.timeAgo(null), 'never synced');
    });
  });

  group('isStale', () {
    final now = DateTime(2026, 7, 15, 12, 0);

    test('older than 24h is stale', () {
      expect(
        Formatters.isStale(now.subtract(const Duration(hours: 25)), now: now),
        isTrue,
      );
      expect(
        Formatters.isStale(now.subtract(const Duration(hours: 2)), now: now),
        isFalse,
      );
      expect(Formatters.isStale(null), isTrue);
    });
  });
}
