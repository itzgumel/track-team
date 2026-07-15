import 'package:geolocator/geolocator.dart';

/// Why a position could not be obtained.
enum LocationFailure {
  /// Device location services (GPS) are switched off.
  serviceDisabled,

  /// The user denied the permission for this request.
  permissionDenied,

  /// The user permanently denied the permission; only the system settings
  /// screen can undo this.
  permissionDeniedForever,

  /// Timed out or another platform error occurred.
  unavailable,
}

sealed class LocationState {
  const LocationState();
}

class LocationAvailable extends LocationState {
  const LocationAvailable(this.position);
  final Position position;
}

class LocationUnavailable extends LocationState {
  const LocationUnavailable(this.reason);
  final LocationFailure reason;
}

/// Wraps geolocator: permission flow, current position and distances.
class LocationService {
  const LocationService();

  /// Runs the full permission flow and returns either a position or the
  /// reason one is unavailable. Never throws.
  Future<LocationState> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationUnavailable(LocationFailure.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return switch (permission) {
        LocationPermission.denied =>
          const LocationUnavailable(LocationFailure.permissionDenied),
        LocationPermission.deniedForever =>
          const LocationUnavailable(LocationFailure.permissionDeniedForever),
        _ => LocationAvailable(
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 30),
              ),
            ),
          ),
      };
    } catch (_) {
      return const LocationUnavailable(LocationFailure.unavailable);
    }
  }

  /// Great-circle distance in meters.
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) =>
      Geolocator.distanceBetween(startLat, startLng, endLat, endLng);

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
