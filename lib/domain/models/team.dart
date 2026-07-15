import 'device_trace.dart';

/// A field team as seen through its device's latest trace, optionally
/// annotated with the distance from the supervisor's position.
class Team {
  const Team({required this.trace, this.distanceMeters});

  final DeviceTrace trace;
  final double? distanceMeters;

  String get deviceId => trace.deviceId;

  /// Best available display name for the team.
  String get displayName {
    for (final candidate in [trace.teamName, trace.userName]) {
      if (candidate != null && candidate.trim().isNotEmpty) return candidate;
    }
    return trace.deviceId;
  }

  double? get distanceKm =>
      distanceMeters == null ? null : distanceMeters! / 1000.0;

  Team withDistance(double meters) =>
      Team(trace: trace, distanceMeters: meters);
}
