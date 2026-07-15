import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/repositories/team_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../domain/models/team.dart';
import '../../core/safe_notifier.dart';

class MapViewModel extends ChangeNotifier with SafeNotifier {
  MapViewModel(this._repository, this._locationService) {
    _repository.addListener(_onDataChanged);
    _init();
  }

  final TeamRepository _repository;
  final LocationService _locationService;

  List<Team> teams = const [];
  bool loading = true;
  bool onlineOnly = false;
  Position? position;

  int get onlineCount => teams.where((t) => t.trace.isOnline).length;

  Future<void> _init() async {
    await Future.wait([_loadTeams(), _tryLocate()]);
    loading = false;
    notifyListeners();
  }

  Future<void> _tryLocate() async {
    final location = await _locationService.getCurrentPosition();
    if (location case LocationAvailable(position: final pos)) {
      position = pos;
    }
  }

  Future<void> _loadTeams() async {
    teams = await _repository.currentTeams(
      onlineOnly: onlineOnly,
      requireLocation: true,
    );
  }

  Future<void> setOnlineOnly(bool value) async {
    if (onlineOnly == value) return;
    onlineOnly = value;
    loading = true;
    notifyListeners();
    await _loadTeams();
    loading = false;
    notifyListeners();
  }

  /// Center of the mapped teams, falling back to the user or a default.
  LatLng get initialCenter {
    if (teams.isNotEmpty) {
      var lat = 0.0, lng = 0.0;
      for (final t in teams) {
        lat += t.trace.latitude!;
        lng += t.trace.longitude!;
      }
      return LatLng(lat / teams.length, lng / teams.length);
    }
    final pos = position;
    if (pos != null) return LatLng(pos.latitude, pos.longitude);
    return const LatLng(7.5629, 4.5200); // Osun State, Nigeria
  }

  void _onDataChanged() {
    _loadTeams().then((_) => notifyListeners());
  }

  @override
  void dispose() {
    _repository.removeListener(_onDataChanged);
    super.dispose();
  }
}
