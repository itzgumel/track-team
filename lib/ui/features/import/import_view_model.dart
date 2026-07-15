import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/team_repository.dart';
import '../../../data/services/xlsx_parser.dart';
import '../../../domain/models/import_result.dart';
import '../../core/safe_notifier.dart';

class ImportViewModel extends ChangeNotifier with SafeNotifier {
  ImportViewModel(this._repository) {
    _loadHistory();
  }

  final TeamRepository _repository;

  bool importing = false;
  bool clearFirst = false;
  ImportResult? lastResult;
  String? error;
  List<ImportRecord> history = const [];

  void setClearFirst(bool value) {
    clearFirst = value;
    notifyListeners();
  }

  Future<void> pickAndImport() async {
    error = null;
    lastResult = null;

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    if (file == null) return; // user cancelled
    final bytes = file.bytes;
    if (bytes == null) {
      error = 'Could not read the selected file.';
      notifyListeners();
      return;
    }

    importing = true;
    notifyListeners();
    try {
      lastResult = await _repository.importXlsx(
        bytes,
        fileName: file.name,
        clearFirst: clearFirst,
      );
      await _loadHistory();
    } on XlsxFormatException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Import failed. Check that the file is a valid '
          'device-trace export.';
    } finally {
      importing = false;
      notifyListeners();
    }
  }

  Future<void> _loadHistory() async {
    history = await _repository.importHistory();
    notifyListeners();
  }
}
