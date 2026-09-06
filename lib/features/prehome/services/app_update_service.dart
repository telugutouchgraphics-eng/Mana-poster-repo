import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  bool _hasCheckedThisSession = false;
  bool _isUpdateInProgress = false;

  /// Check Google Play Store for available updates and initiate native update flow.
  Future<void> checkForUpdate({bool force = false}) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    if (_hasCheckedThisSession && !force) {
      return;
    }
    if (_isUpdateInProgress) {
      return;
    }

    _hasCheckedThisSession = true;
    _isUpdateInProgress = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.flexibleUpdateAllowed) {
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            await InAppUpdate.completeFlexibleUpdate();
          }
        } else if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
      } else if (info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        // If an update was already in progress (e.g. flexible download finished)
        if (info.flexibleUpdateAllowed) {
          await InAppUpdate.completeFlexibleUpdate();
        } else if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
      }
    } catch (error) {
      // Ignored safely for sideloaded/debug builds, uncertified devices, or missing Play Store.
      debugPrint('AppUpdateService check skipped: $error');
    } finally {
      _isUpdateInProgress = false;
    }
  }
}

