import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class AppFlowSnapshot {
  const AppFlowSnapshot({
    required this.language,
    required this.languageSelected,
    required this.permissionsStepHandled,
    required this.initialSetupCompleted,
  });

  final AppLanguage language;
  final bool languageSelected;
  final bool permissionsStepHandled;
  final bool initialSetupCompleted;

  String nextRoute({required bool isAuthenticated}) {
    if (!languageSelected) {
      return AppRoutes.language;
    }
    if (!isAuthenticated) {
      return AppRoutes.login;
    }
    if (!permissionsStepHandled) {
      return AppRoutes.permissions;
    }
    return AppRoutes.home;
  }
}

class AppFlowService {
  AppFlowService._();

  static const String _selectedLanguageKey = 'selected_language';
  static const String _languageSelectedKey = 'language_selected';
  static const String _permissionsHandledKey = 'permissions_step_handled';
  static const String _initialSetupCompletedKey = 'initial_setup_completed';

  static AppLanguage? _memoryLanguage;
  static bool _memoryLanguageSelected = false;

  static Future<AppFlowSnapshot> loadSnapshot() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppLanguage language = _readLanguage(
        prefs.getString(_selectedLanguageKey),
      );
      final bool languageSelected = prefs.getBool(_languageSelectedKey) ?? false;

      if (languageSelected) {
        _memoryLanguage = language;
        _memoryLanguageSelected = true;
      }

      return AppFlowSnapshot(
        language: language,
        languageSelected: languageSelected || _memoryLanguageSelected,
        permissionsStepHandled: prefs.getBool(_permissionsHandledKey) ?? false,
        initialSetupCompleted:
            prefs.getBool(_initialSetupCompletedKey) ?? false,
      );
    } catch (_) {
      return AppFlowSnapshot(
        language: _memoryLanguage ?? AppLanguage.telugu,
        languageSelected: _memoryLanguageSelected,
        permissionsStepHandled: false,
        initialSetupCompleted: false,
      );
    }
  }

  static Future<bool> persistLanguageSelection(AppLanguage language) async {
    _memoryLanguage = language;
    _memoryLanguageSelected = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedLanguageKey, language.name);
      await prefs.setBool(_languageSelectedKey, true);
      final storedLanguage = prefs.getString(_selectedLanguageKey);
      final storedFlag = prefs.getBool(_languageSelectedKey) ?? false;
      if (storedLanguage == language.name && storedFlag) {
        unawaited(_syncLanguageToRemote(language));
        return true;
      }
    } catch (_) {}

    // Prefs failed on some devices; keep in-memory selection so onboarding can continue.
    unawaited(_syncLanguageToRemote(language));
    return true;
  }

  static Future<void> markPermissionsStepHandled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsHandledKey, true);
  }

  static Future<void> markInitialSetupCompleted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initialSetupCompletedKey, true);
  }

  static Future<void> resetPermissionsStep() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsHandledKey, false);
    await prefs.setBool(_initialSetupCompletedKey, false);
  }

  static Future<void> syncInitialSetupCompletion({
    required bool isAuthenticated,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool permissionsHandled = await resolvePermissionsStepHandled();
    final bool completed =
        (prefs.getBool(_languageSelectedKey) ?? false) &&
        isAuthenticated &&
        permissionsHandled;
    await prefs.setBool(_initialSetupCompletedKey, completed);
  }

  static Future<bool> resolvePermissionsStepHandled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool storedHandled = prefs.getBool(_permissionsHandledKey) ?? false;
    if (!storedHandled) {
      return false;
    }
    if (kIsWeb) {
      return true;
    }
    final PermissionSnapshot snapshot = await PermissionService().getSnapshot();
    if (snapshot.allGranted) {
      return true;
    }
    final bool allDenied = snapshot.items.every(
      (AppPermissionState item) => item.isDenied,
    );
    if (allDenied) {
      await prefs.setBool(_permissionsHandledKey, false);
      await prefs.setBool(_initialSetupCompletedKey, false);
      return false;
    }
    return true;
  }

  static Future<String> resolveAuthenticatedEntryRoute() async {
    final PosterProfileData profile = await PosterProfileService.load();
    return PosterProfileService.isSetupComplete(profile)
        ? AppRoutes.home
        : AppRoutes.profileSetup;
  }

  static Future<String> resolveAuthenticatedEntryRouteForStartup() async {
    final PosterProfileData localProfile = await PosterProfileService.loadLocal();
    if (PosterProfileService.isSetupComplete(localProfile)) {
      return AppRoutes.home;
    }

    try {
      final PosterProfileData? remoteProfile = await PosterProfileService
          .refreshFromRemote(localProfile: localProfile)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      final PosterProfileData resolved = remoteProfile ?? localProfile;
      return PosterProfileService.isSetupComplete(resolved)
          ? AppRoutes.home
          : AppRoutes.profileSetup;
    } catch (_) {
      return PosterProfileService.isSetupComplete(localProfile)
          ? AppRoutes.home
          : AppRoutes.profileSetup;
    }
  }

  static Future<void> syncStoredLanguageToRemote() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppLanguage language = _readLanguage(
      prefs.getString(_selectedLanguageKey),
    );
    await _syncLanguageToRemote(language);
  }

  static Future<void> _syncLanguageToRemote(AppLanguage language) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'preferredLanguage': language.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Best-effort sync only. Local flow should continue even if remote save fails.
    }
  }

  static AppLanguage _readLanguage(String? rawValue) {
    if (kIsWeb && (rawValue == null || rawValue.trim().isEmpty)) {
      return AppLanguage.english;
    }
    return AppLanguage.values.firstWhere(
      (AppLanguage item) => item.name == rawValue,
      orElse: () => AppLanguage.telugu,
    );
  }
}
