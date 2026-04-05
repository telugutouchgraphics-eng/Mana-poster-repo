import 'dart:io';

import 'package:path_provider/path_provider.dart';

class EditorDraftStorageService {
  const EditorDraftStorageService();

  static const String _draftsDirectoryName = 'image_editor_drafts';
  static const String _autosaveFileName = 'autosave_v1.json';
  static const String _manualDraftPrefix = 'draft_';

  Future<Directory> getDraftsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final draftsDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}$_draftsDirectoryName',
    );
    if (!await draftsDirectory.exists()) {
      await draftsDirectory.create(recursive: true);
    }
    return draftsDirectory;
  }

  Future<File> getAutosaveFile() async {
    final draftsDirectory = await getDraftsDirectory();
    return File(
      '${draftsDirectory.path}${Platform.pathSeparator}$_autosaveFileName',
    );
  }

  Future<File> createManualDraftFile() async {
    final draftsDirectory = await getDraftsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return File(
      '${draftsDirectory.path}${Platform.pathSeparator}$_manualDraftPrefix$timestamp.json',
    );
  }

  Future<List<FileSystemEntity>> listManualDraftFiles() async {
    final draftsDirectory = await getDraftsDirectory();
    final files = draftsDirectory
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.json') &&
              !file.path.endsWith(_autosaveFileName),
        )
        .toList(growable: false);
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }
}
