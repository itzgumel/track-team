/// Summary of a completed spreadsheet import.
class ImportResult {
  const ImportResult({
    required this.fileName,
    required this.importedRows,
    required this.skippedRows,
    required this.rowsWithoutLocation,
    required this.totalTeams,
    required this.onlineTeams,
    required this.clearedExisting,
  });

  final String fileName;
  final int importedRows;
  final int skippedRows;
  final int rowsWithoutLocation;

  /// Distinct devices in the database after the import.
  final int totalTeams;
  final int onlineTeams;
  final bool clearedExisting;
}

/// A row of the import history log.
class ImportRecord {
  const ImportRecord({
    required this.fileName,
    required this.importedAt,
    required this.rowCount,
    required this.skippedCount,
    required this.teamCount,
  });

  final String fileName;
  final DateTime importedAt;
  final int rowCount;
  final int skippedCount;
  final int teamCount;
}
