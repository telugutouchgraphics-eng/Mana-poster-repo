import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PosterDownloadRecord {
  const PosterDownloadRecord({
    required this.id,
    required this.relativeFilePath,
    required this.createdAtMillis,
  });

  final String id;
  /// Path relative to the downloads folder (basename only).
  final String relativeFilePath;
  final int createdAtMillis;

  factory PosterDownloadRecord.fromJson(Map<String, dynamic> map) {
    return PosterDownloadRecord(
      id: (map['id'] ?? '').toString(),
      relativeFilePath: (map['file'] ?? '').toString(),
      createdAtMillis: (map['t'] as num?)?.round() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'file': relativeFilePath,
        't': createdAtMillis,
      };
}

class PosterDownloadListed {
  const PosterDownloadListed({
    required this.record,
    required this.absolutePath,
  });

  final PosterDownloadRecord record;
  final String absolutePath;
}

/// Persists copies of posters the user saves to the gallery ([My Downloads]).
class PosterDownloadsService {
  PosterDownloadsService._();

  static const String _folderName = 'poster_my_downloads';
  static const String _manifestName = 'manifest.json';

  static Future<Directory> _downloadsDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('My Downloads is unavailable on web.');
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
        '${docs.path}${Platform.pathSeparator}$_folderName');
    await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _manifestFile(Directory downloadsDir) async =>
      File(
        '${downloadsDir.path}${Platform.pathSeparator}$_manifestName',
      );

  static Future<List<PosterDownloadRecord>> _loadManifestRecords(
      File manifest) async {
    if (!manifest.existsSync()) {
      return <PosterDownloadRecord>[];
    }
    try {
      final raw = jsonDecode(await manifest.readAsString());
      if (raw is! List<dynamic>) {
        return <PosterDownloadRecord>[];
      }
      return raw
          .map((dynamic e) {
            if (e is! Map) {
              return null;
            }
            return PosterDownloadRecord.fromJson(
              Map<String, dynamic>.from(e),
            );
          })
          .whereType<PosterDownloadRecord>()
          .toList();
    } catch (_) {
      return <PosterDownloadRecord>[];
    }
  }

  static Future<void> _saveManifestRecords(
      File manifest, List<PosterDownloadRecord> list) async {
    final encoder = JsonEncoder.withIndent('  ');
    await manifest.writeAsString(
      encoder.convert(list.map((PosterDownloadRecord e) => e.toJson()).toList()),
      flush: true,
    );
  }

  /// Newest first; drops manifest entries whose files are missing.
  static Future<List<PosterDownloadRecord>> listRecords() async {
    if (kIsWeb) {
      return <PosterDownloadRecord>[];
    }
    final dir = await _downloadsDirectory();
    final manifest = await _manifestFile(dir);
    final records = await _loadManifestRecords(manifest);
    final kept = <PosterDownloadRecord>[];
    for (final PosterDownloadRecord r in records) {
      final file = File(
        '${dir.path}${Platform.pathSeparator}${r.relativeFilePath}',
      );
      if (await file.exists()) {
        kept.add(r);
      }
    }
    if (kept.length != records.length) {
      await _saveManifestRecords(manifest, kept);
    }
    kept.sort(
      (PosterDownloadRecord a, PosterDownloadRecord b) =>
          b.createdAtMillis.compareTo(a.createdAtMillis),
    );
    return kept;
  }

  /// Same as [listRecords] but includes absolute paths for UI lists.
  static Future<List<PosterDownloadListed>> listForDisplay() async {
    if (kIsWeb) {
      return <PosterDownloadListed>[];
    }
    final dir = await _downloadsDirectory();
    final records = await listRecords();
    return records
        .map(
          (PosterDownloadRecord r) => PosterDownloadListed(
            record: r,
            absolutePath:
                '${dir.path}${Platform.pathSeparator}${r.relativeFilePath}',
          ),
        )
        .toList();
  }

  static Future<String?> absolutePathFor(PosterDownloadRecord record) async {
    if (kIsWeb) {
      return null;
    }
    final dir = await _downloadsDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}${record.relativeFilePath}';
    if (await File(path).exists()) {
      return path;
    }
    return null;
  }

  /// After a successful gallery save, copy the same bytes into app storage.
  static Future<void> recordCopyFromFile(
    String sourcePath, {
    String? suggestedFileName,
  }) async {
    if (kIsWeb) {
      return;
    }
    final src = File(sourcePath);
    if (!await src.exists()) {
      return;
    }
    try {
      final dir = await _downloadsDirectory();
      final ext = _extensionFor(suggestedFileName, sourcePath);
      final id =
          'md_${DateTime.now().microsecondsSinceEpoch}_${src.lengthSync()}';
      final storedName = '$id.$ext';
      final dest = File(
        '${dir.path}${Platform.pathSeparator}$storedName',
      );
      await src.copy(dest.path);
      final manifest = await _manifestFile(dir);
      final existing = await _loadManifestRecords(manifest);
      final next = <PosterDownloadRecord>[
        PosterDownloadRecord(
          id: id,
          relativeFilePath: storedName,
          createdAtMillis: DateTime.now().millisecondsSinceEpoch,
        ),
        ...existing,
      ];
      await _saveManifestRecords(manifest, next);
    } catch (error, stackTrace) {
      debugPrint('PosterDownloadsService.recordCopyFromFile failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static String _extensionFor(String? suggested, String sourcePath) {
    final fromSuggested = suggested == null || suggested.trim().isEmpty
        ? ''
        : _fileExtension(suggested);
    if (fromSuggested == 'png' ||
        fromSuggested == 'jpg' ||
        fromSuggested == 'jpeg' ||
        fromSuggested == 'webp') {
      return fromSuggested == 'jpeg' ? 'jpg' : fromSuggested;
    }
    final fromSrc = _fileExtension(sourcePath);
    if (fromSrc == 'png' ||
        fromSrc == 'jpg' ||
        fromSrc == 'jpeg' ||
        fromSrc == 'webp') {
      return fromSrc == 'jpeg' ? 'jpg' : fromSrc;
    }
    return 'png';
  }

  static String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot >= path.length - 1) {
      return '';
    }
    return path.substring(dot + 1).toLowerCase();
  }
}
