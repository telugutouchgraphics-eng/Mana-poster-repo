import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class EditorDraftService {
  const EditorDraftService();

  Future<File> _draftFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final draftsDirectory = Directory('${directory.path}/editor_drafts');
    if (!await draftsDirectory.exists()) {
      await draftsDirectory.create(recursive: true);
    }
    return File('${draftsDirectory.path}/latest_draft.json');
  }

  Future<String> saveDraft(Map<String, Object?> payload) async {
    final file = await _draftFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file.path;
  }

  Future<Map<String, Object?>?> loadLatestDraft() async {
    final file = await _draftFile();
    if (!await file.exists()) {
      return null;
    }
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return null;
    }
  }
}
