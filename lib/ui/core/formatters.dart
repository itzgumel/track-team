import 'package:intl/intl.dart';

/// Shared display formatting helpers.
abstract final class Formatters {
  static final _dateTime = DateFormat('d MMM yyyy, HH:mm');
  static final _compact = DateFormat('d MMM, HH:mm');

  static String dateTime(DateTime? value) =>
      value == null ? 'Unknown' : _dateTime.format(value);

  /// "3.2 km" above 1 km, "850 m" below.
  static String distance(double? meters) {
    if (meters == null) return '—';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Relative freshness of a sync, e.g. "25 min ago", "3 h ago".
  static String timeAgo(DateTime? value, {DateTime? now}) {
    if (value == null) return 'never synced';
    final reference = now ?? DateTime.now();
    final diff = reference.difference(value);
    if (diff.isNegative) return _compact.format(value);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return _compact.format(value);
  }

  /// A sync older than this is flagged as stale in the UI.
  static const staleAfter = Duration(hours: 24);

  static bool isStale(DateTime? lastSync, {DateTime? now}) {
    if (lastSync == null) return true;
    return (now ?? DateTime.now()).difference(lastSync) > staleAfter;
  }
}
