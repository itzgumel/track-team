import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/repositories/team_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../domain/models/geo_filter.dart';
import '../../../domain/models/team.dart';
import '../../core/safe_notifier.dart';

class BrowseViewModel extends ChangeNotifier with SafeNotifier {
  BrowseViewModel(this._repository, this._locationService) {
    _repository.addListener(_onDataChanged);
    _init();
  }

  final TeamRepository _repository;
  final LocationService _locationService;

  GeoFilter filter = const GeoFilter();
  List<String> lgas = const [];
  List<String> wards = const [];
  List<String> healthFacilities = const [];
  List<String> distributionPoints = const [];

  List<Team> teams = const [];
  bool loading = true;
  bool onlineOnly = false;

  /// Position is fetched quietly; distance is a bonus here, not a gate.
  Position? _position;

  Future<void> _init() async {
    await Future.wait([_loadOptions(), _tryLocate()]);
    await _loadTeams();
    loading = false;
    notifyListeners();
  }

  Future<void> _tryLocate() async {
    final location = await _locationService.getCurrentPosition();
    if (location case LocationAvailable(position: final pos)) {
      _position = pos;
    }
  }

  Future<void> _loadOptions() async {
    lgas = await _repository.lgas();
    wards = await _repository.wards(filter);
    healthFacilities = await _repository.healthFacilities(filter);
    distributionPoints = await _repository.distributionPoints(filter);
  }

  Future<void> _loadTeams() async {
    var result = await _repository.currentTeams(
      filter: filter,
      onlineOnly: onlineOnly,
    );
    final pos = _position;
    if (pos != null) {
      result = result
          .map((t) => t.trace.hasLocation
              ? t.withDistance(_locationService.distanceBetween(
                  pos.latitude,
                  pos.longitude,
                  t.trace.latitude!,
                  t.trace.longitude!,
                ))
              : t)
          .toList()
        ..sort((a, b) {
          final da = a.distanceMeters, db = b.distanceMeters;
          if (da == null && db == null) return 0;
          if (da == null) return 1; // teams without location go last
          if (db == null) return -1;
          return da.compareTo(db);
        });
    }
    teams = result;
  }

  bool get hasPosition => _position != null;

  Future<void> _applyFilter(GeoFilter next) async {
    filter = next;
    loading = true;
    notifyListeners();
    await _loadOptions();
    await _loadTeams();
    loading = false;
    notifyListeners();
  }

  Future<void> selectLga(String? value) => _applyFilter(filter.selectLga(value));

  Future<void> selectWard(String? value) =>
      _applyFilter(filter.selectWard(value));

  Future<void> selectHealthFacility(String? value) =>
      _applyFilter(filter.selectHealthFacility(value));

  Future<void> selectDistributionPoint(String? value) =>
      _applyFilter(filter.selectDistributionPoint(value));

  Future<void> setOnlineOnly(bool value) async {
    if (onlineOnly == value) return;
    onlineOnly = value;
    loading = true;
    notifyListeners();
    await _loadTeams();
    loading = false;
    notifyListeners();
  }

  void _onDataChanged() => _applyFilter(const GeoFilter());

  @override
  void dispose() {
    _repository.removeListener(_onDataChanged);
    super.dispose();
  }
}
