/// Aggregate numbers shown on the home dashboard.
class DashboardStats {
  const DashboardStats({
    required this.totalTeams,
    required this.onlineTeams,
    required this.offlineTeams,
    required this.teamsWithLocation,
    required this.totalTraces,
    required this.lgaCount,
    this.lastImportAt,
    this.lastImportFile,
  });

  static const empty = DashboardStats(
    totalTeams: 0,
    onlineTeams: 0,
    offlineTeams: 0,
    teamsWithLocation: 0,
    totalTraces: 0,
    lgaCount: 0,
  );

  final int totalTeams;
  final int onlineTeams;
  final int offlineTeams;
  final int teamsWithLocation;
  final int totalTraces;
  final int lgaCount;
  final DateTime? lastImportAt;
  final String? lastImportFile;

  bool get hasData => totalTraces > 0;
}
