import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/team_repository.dart';
import '../../../domain/models/dashboard_stats.dart';
import '../../../domain/models/team.dart';
import '../../core/safe_notifier.dart';

class HomeViewModel extends ChangeNotifier with SafeNotifier {
  HomeViewModel(this._repository) {
    _repository.addListener(_onDataChanged);
    refresh();
  }

  final TeamRepository _repository;

  DashboardStats stats = DashboardStats.empty;
  bool loading = true;
  String searchQuery = '';
  List<Team> searchResults = const [];
  Timer? _debounce;

  Future<void> refresh() async {
    stats = await _repository.stats();
    loading = false;
    if (searchQuery.isNotEmpty) {
      searchResults = await _repository.currentTeams(search: searchQuery);
    }
    notifyListeners();
  }

  void search(String query) {
    searchQuery = query.trim();
    _debounce?.cancel();
    if (searchQuery.isEmpty) {
      searchResults = const [];
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final results = await _repository.currentTeams(search: searchQuery);
      searchResults = results;
      notifyListeners();
    });
  }

  void _onDataChanged() => refresh();

  @override
  void dispose() {
    _debounce?.cancel();
    _repository.removeListener(_onDataChanged);
    super.dispose();
  }
}
