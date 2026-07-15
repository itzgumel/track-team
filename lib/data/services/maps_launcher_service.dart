import 'package:url_launcher/url_launcher.dart';

/// Hands off to Google Maps for turn-by-turn navigation.
///
/// Uses the official Google Maps URL scheme, which opens the Maps app when
/// installed and falls back to the browser otherwise.
class MapsLauncherService {
  const MapsLauncherService();

  /// Opens driving directions to the given coordinates.
  Future<bool> navigateTo(double latitude, double longitude) {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    });
    return _launch(uri);
  }

  /// Opens the location as a pin (no route).
  Future<bool> showOnMap(double latitude, double longitude) {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
    return _launch(uri);
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
