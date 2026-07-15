import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/repositories/team_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../domain/models/team.dart';
import '../../core/safe_notifier.dart';

enum NearestStatus { locating, loading, ready, locationFailed }

class NearestViewModel extends ChangeNotifier with SafeNotifier {
  NearestViewModel(this._repository, this._locationService) {
    _repository.addListener(_onDataChanged);
    refresh();
  }

  final TeamRepository _repository;
  final LocationService _locationService;

  NearestStatus status = NearestStatus.locating;
  LocationFailure? failure;
  Position? position;
  List<Team> teams = const [];
  bool onlineOnly = true;

  /// Latest-trace counts used for the empty-state messaging.
  int onlineWithLocation = 0;
  int totalWithLocation = 0;

  Future<void> refresh() async {
    status = NearestStatus.locating;
    failure = null;
    notifyListeners();

    final location = await _locationService.getCurrentPosition();
    switch (location) {
      case LocationUnavailable(:final reason):
        failure = reason;
        status = NearestStatus.locationFailed;
      case LocationAvailable(position: final pos):
        position = pos;
        status = NearestStatus.loading;
        notifyListeners();
        await _loadTeams();
        status = NearestStatus.ready;
    }
    notifyListeners();
  }

  Future<void> setOnlineOnly(bool value) async {
    if (onlineOnly == value) return;
    onlineOnly = value;
    if (position != null) {
      status = NearestStatus.loading;
      notifyListeners();
      await _loadTeams();
      status = NearestStatus.ready;
    }
    notifyListeners();
  }

  Future<void> _loadTeams() async {
    final all = await _repository.currentTeams(requireLocation: true);
    totalWithLocation = all.length;
    onlineWithLocation = all.where((t) => t.trace.isOnline).length;

    final filtered =
        onlineOnly ? all.where((t) => t.trace.isOnline) : all;
    final pos = position!;
    teams = filtered
        .map((t) => t.withDistance(_locationService.distanceBetween(
              pos.latitude,
              pos.longitude,
              t.trace.latitude!,
              t.trace.longitude!,
            )))
        .toList()
      ..sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));
  }

  Future<void> openAppSettings() => _locationService.openAppSettings();

  Future<void> openLocationSettings() =>
      _locationService.openLocationSettings();

  void _onDataChanged() {
    if (position != null) {
      _loadTeams().then((_) => notifyListeners());
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_onDataChanged);
    super.dispose();
  }
}
