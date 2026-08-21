import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Deletes abandoned Mana Poster temp files under [getTemporaryDirectory].
abstract final class AppTemporaryCleanup {
  static const Duration _minFileAge = Duration(seconds: 45);
  static const Duration _minCacheDirectoryAge = Duration(days: 1);
  static const int _maxDeletesPerSweep = 40;

  /// Cold start: brief delay so in-flight writes can finish.
  static Future<void> runAfterColdStart() async {
    if (kIsWeb) {
      return;
    }
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      await sweepEligibleTemporaryFiles();
    } catch (_) {}
  }

  /// Resume / periodic trim without blocking UI.
  static Future<void> sweepEligibleTemporaryFiles() async {
    if (kIsWeb) {
      return;
    }
    try {
      final Directory dir = await getTemporaryDirectory();
      final Directory systemDir = Directory.systemTemp;
      final DateTime now = DateTime.now();
      var remainingDeletes = _maxDeletesPerSweep;
      remainingDeletes = await _sweepDirectory(dir, now, remainingDeletes);
      if (remainingDeletes > 0 && systemDir.path != dir.path) {
        await _sweepDirectory(systemDir, now, remainingDeletes);
      }
    } catch (_) {}
  }

  static Future<int> _sweepDirectory(
    Directory dir,
    DateTime now,
    int remainingDeletes,
  ) async {
    try {
      await for (final FileSystemEntity entity in dir.list(
        followLinks: false,
      )) {
        if (remainingDeletes <= 0) {
          break;
        }
        final String name = _basename(entity.path);
        final bool disposable = entity is Directory
            ? _isDisposableDirectoryBasename(name)
            : _isDisposableFileBasename(name);
        if (!disposable) {
          continue;
        }
        try {
          final DateTime modified = await entity.stat().then((s) => s.modified);
          final minAge = entity is Directory
              ? _minimumAgeForDisposableDirectory(name)
              : _minFileAge;
          if (now.difference(modified) < minAge) {
            continue;
          }
          await entity.delete(recursive: entity is Directory);
          remainingDeletes -= 1;
        } catch (_) {}
      }
    } catch (_) {}
    return remainingDeletes;
  }

  static String _basename(String path) {
    final int i = path.replaceAll('\\', '/').lastIndexOf('/');
    return i == -1 ? path : path.substring(i + 1);
  }

  static bool _isDisposableFileBasename(String name) {
    return name.startsWith('mana_poster_export_') ||
        name.startsWith('mana_poster_status_') ||
        name.startsWith('mana_approved_upload_') ||
        name.startsWith('mana_political_poster_') ||
        name.startsWith('mana_poster_quiz_') ||
        name.startsWith('poster_editor_template_') ||
        name.startsWith('poster_profile_pick_') ||
        name.startsWith('poster_profile_saved_cutout_') ||
        name.startsWith('notif_') ||
        name.startsWith('notif_strip_') ||
        name.startsWith('notif_expanded_') ||
        name.startsWith('editor_crop_') ||
        name.startsWith('bg_removed_') ||
        name.startsWith('mana_poster_share.') ||
        name == 'mana_poster_share_app.png' ||
        RegExp(r'^mana_poster_\d+\.').hasMatch(name);
  }

  static bool _isDisposableDirectoryBasename(String name) {
    return name.startsWith('mana_poster_video_export_') ||
        name == 'mana_poster_video_export_cache' ||
        name == 'mana_poster_video_source_cache';
  }

  static Duration _minimumAgeForDisposableDirectory(String name) {
    if (name == 'mana_poster_video_export_cache' ||
        name == 'mana_poster_video_source_cache') {
      return _minCacheDirectoryAge;
    }
    return _minFileAge;
  }
}
