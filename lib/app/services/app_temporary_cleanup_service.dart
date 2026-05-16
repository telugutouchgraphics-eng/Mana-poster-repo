import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Deletes abandoned Mana Poster temp files under [getTemporaryDirectory].
abstract final class AppTemporaryCleanup {
  static const Duration _minFileAge = Duration(seconds: 45);

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
      final DateTime now = DateTime.now();
      await for (final FileSystemEntity entity in dir.list(followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        final String name = _basename(entity.path);
        if (!_isDisposableBasename(name)) {
          continue;
        }
        try {
          final DateTime modified = await entity.lastModified();
          if (now.difference(modified) < _minFileAge) {
            continue;
          }
          await entity.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  static String _basename(String path) {
    final int i = path.replaceAll('\\', '/').lastIndexOf('/');
    return i == -1 ? path : path.substring(i + 1);
  }

  static bool _isDisposableBasename(String name) {
    return name.startsWith('mana_poster_export_') ||
        name.startsWith('notif_') ||
        name.startsWith('notif_strip_') ||
        name.startsWith('notif_expanded_') ||
        name.startsWith('editor_crop_') ||
        name.startsWith('bg_removed_') ||
        name.startsWith('mana_poster_share.') ||
        name == 'mana_poster_share_app.png' ||
        RegExp(r'^mana_poster_\d+\.').hasMatch(name);
  }
}
