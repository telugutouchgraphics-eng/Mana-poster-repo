import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/services/native_startup_state_store.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
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
      return AppRoutes.appLanguage;
    }
    return isAuthenticated ? AppRoutes.home : AppRoutes.login;
  }
}

class AppStartupResolution {
  const AppStartupResolution({
    required this.language,
    required this.languageSelected,
    required this.onboardingCompleted,
    required this.hasAuthenticatedUser,
    required this.currentUser,
    required this.cachedAuthUid,
    required this.resolvedRoute,
  });

  final AppLanguage language;
  final bool languageSelected;
  final bool onboardingCompleted;
  final bool hasAuthenticatedUser;
  final User? currentUser;
  final String? cachedAuthUid;
  final String resolvedRoute;
}

class AppFlowService {
  AppFlowService._();

  static const String _selectedLanguageKey = 'selected_language';
  static const String _languageSelectedKey = 'language_selected';
  static const String _manualLanguageSelectedKey =
      'manual_language_selected_v1';
  static const String _permissionsHandledKey = 'permissions_step_handled';
  static const String _initialSetupCompletedKey = 'initial_setup_completed';
  static const String _lastKnownAuthUidKey = 'last_known_auth_uid_v1';
  static const String _lastRemoteLanguageSyncKeyPrefix =
      'last_remote_language_sync_attempt_v1_';
  static const String _startupStateFileName = 'app_startup_state_v1.json';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static AppLanguage? _memoryLanguage;
  static bool _memoryLanguageSelected = false;
  static AppFlowSnapshot? _cachedSnapshot;
  static String? _cachedLastKnownAuthUid;

  static Future<AppFlowSnapshot> preloadStartupSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final nativeState = await NativeStartupStateStore.readAll();
    final fileState = await _readStartupStateFile();
    _cachedLastKnownAuthUid = _loadFastStoredAuthUid(
      prefs: prefs,
      fileState: fileState,
      nativeState: nativeState,
    );
    final snapshot = await _loadFastStartupSnapshot(
      prefs: prefs,
      fileState: fileState,
      nativeState: nativeState,
    );
    _cachedSnapshot = snapshot;
    return snapshot;
  }

  static Future<AppFlowSnapshot> _loadFastStartupSnapshot({
    required SharedPreferences prefs,
    required Map<String, Object?> fileState,
    required Map<String, Object?> nativeState,
  }) async {
    final String prefsLanguage = prefs.getString(_selectedLanguageKey) ?? '';
    final bool prefsLanguageSelected =
        prefs.getBool(_languageSelectedKey) ?? false;
    final bool manualLanguageSelected =
        prefs.getBool(_manualLanguageSelectedKey) ?? false;
    final String fileLanguage =
        (fileState[_selectedLanguageKey] as String? ?? '').trim();
    final bool fileLanguageSelected = fileState[_languageSelectedKey] == true;
    final bool fileManualLanguageSelected =
        fileState[_manualLanguageSelectedKey] == true;
    final String nativeLanguage =
        (nativeState[_selectedLanguageKey] as String? ?? '').trim();
    final bool nativeLanguageSelected =
        nativeState[_languageSelectedKey] == true;
    final bool nativeManualLanguageSelected =
        nativeState[_manualLanguageSelectedKey] == true;
    final bool hasManualLanguageSelection =
        manualLanguageSelected ||
        nativeManualLanguageSelected ||
        fileManualLanguageSelected;
    final String manualLanguageRaw = prefsLanguage.isNotEmpty
        ? prefsLanguage
        : (nativeLanguage.isNotEmpty ? nativeLanguage : fileLanguage);
    final String resolvedLanguageRaw =
        hasManualLanguageSelection && manualLanguageRaw.isNotEmpty
        ? manualLanguageRaw
        : (prefsLanguage.isNotEmpty
              ? prefsLanguage
              : (nativeLanguage.isNotEmpty
                    ? nativeLanguage
                    : (fileLanguage.isNotEmpty ? fileLanguage : '')));
    final bool languageSelected =
        prefsLanguageSelected || nativeLanguageSelected || fileLanguageSelected;
    final language = _readLanguage(resolvedLanguageRaw);
    if (languageSelected) {
      _memoryLanguage = language;
      _memoryLanguageSelected = true;
    }
    return AppFlowSnapshot(
      language: language,
      languageSelected: languageSelected || _memoryLanguageSelected,
      permissionsStepHandled: prefs.getBool(_permissionsHandledKey) ?? false,
      initialSetupCompleted: prefs.getBool(_initialSetupCompletedKey) ?? false,
    );
  }

  static Future<AppStartupResolution> resolveDeterministicStartupState() async {
    final snapshot = await preloadStartupSnapshot();
    final currentUser = await _resolveInitialCurrentUser();
    final cachedAuthUid = await loadLastKnownAuthUid();
    final hasAuthenticatedUser =
        currentUser?.uid.trim().isNotEmpty == true ||
        (Firebase.apps.isEmpty && (cachedAuthUid?.trim().isNotEmpty ?? false));
    final prefs = await SharedPreferences.getInstance();
    final hasSelectedRegion = await AppRegionService.hasSelection(prefs: prefs);
    final resolvedRoute = determineStartupRoute(
      hasAuthenticatedUser: hasAuthenticatedUser,
      hasSelectedRegion: hasSelectedRegion,
      hasSelectedLanguage: snapshot.languageSelected,
    );

    return AppStartupResolution(
      language: snapshot.language,
      languageSelected: snapshot.languageSelected,
      onboardingCompleted: snapshot.initialSetupCompleted,
      hasAuthenticatedUser: hasAuthenticatedUser,
      currentUser: currentUser,
      cachedAuthUid: cachedAuthUid,
      resolvedRoute: resolvedRoute,
    );
  }

  static String? _loadFastStoredAuthUid({
    required SharedPreferences prefs,
    required Map<String, Object?> fileState,
    required Map<String, Object?> nativeState,
  }) {
    final prefsUid = (prefs.getString(_lastKnownAuthUidKey) ?? '').trim();
    final nativeUid = (nativeState[_lastKnownAuthUidKey] as String? ?? '')
        .trim();
    final fileUid = (fileState[_lastKnownAuthUidKey] as String? ?? '').trim();
    final resolved = prefsUid.isNotEmpty
        ? prefsUid
        : (nativeUid.isNotEmpty ? nativeUid : fileUid);
    return resolved.isEmpty ? null : resolved;
  }

  static Future<AppFlowSnapshot> loadSnapshot({
    SharedPreferences? prefs,
  }) async {
    if (prefs == null) {
      final cached = _cachedSnapshot;
      if (cached != null) {
        return cached;
      }
    }
    try {
      final SharedPreferences resolvedPrefs =
          prefs ?? await SharedPreferences.getInstance();
      final snapshot = await _loadDurableSnapshot(prefs: resolvedPrefs);
      _cachedSnapshot = snapshot;
      return snapshot;
    } catch (_) {
      return AppFlowSnapshot(
        language: _memoryLanguage ?? AppLanguage.telugu,
        languageSelected: _memoryLanguageSelected,
        permissionsStepHandled: false,
        initialSetupCompleted: false,
      );
    }
  }

  static Future<bool> persistLanguageSelection(
    AppLanguage language, {
    bool userInitiated = true,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool hasExistingManualLanguageSelection =
          !userInitiated && await _hasManualLanguageSelection(prefs: prefs);
      if (hasExistingManualLanguageSelection) {
        return true;
      }
      await _secureStorage.write(
        key: _selectedLanguageKey,
        value: language.name,
      );
      await _secureStorage.write(key: _languageSelectedKey, value: 'true');
      await NativeStartupStateStore.writeEntries(<String, Object?>{
        _selectedLanguageKey: language.name,
        _languageSelectedKey: true,
      });
      await _writeStartupStateFile(<String, Object?>{
        _selectedLanguageKey: language.name,
        _languageSelectedKey: true,
      });
      await prefs.setString(_selectedLanguageKey, language.name);
      await prefs.setBool(_languageSelectedKey, true);
      if (userInitiated) {
        await _secureStorage.write(
          key: _manualLanguageSelectedKey,
          value: 'true',
        );
        await NativeStartupStateStore.writeEntries(<String, Object?>{
          _manualLanguageSelectedKey: true,
        });
        await _writeStartupStateFile(<String, Object?>{
          _manualLanguageSelectedKey: true,
        });
        await prefs.setBool(_manualLanguageSelectedKey, true);
      }
      final secureLanguage = await _secureStorage.read(
        key: _selectedLanguageKey,
      );
      final secureFlag = await _secureStorage.read(key: _languageSelectedKey);
      final storedLanguage = prefs.getString(_selectedLanguageKey);
      final storedFlag = prefs.getBool(_languageSelectedKey) ?? false;
      if ((storedLanguage != language.name || !storedFlag) &&
          (secureLanguage != language.name || secureFlag != 'true')) {
        return false;
      }
      _memoryLanguage = language;
      _memoryLanguageSelected = true;
      _cachedSnapshot = AppFlowSnapshot(
        language: language,
        languageSelected: true,
        permissionsStepHandled: prefs.getBool(_permissionsHandledKey) ?? false,
        initialSetupCompleted:
            prefs.getBool(_initialSetupCompletedKey) ?? false,
      );
      unawaited(_syncLanguageToRemote(language));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _hasManualLanguageSelection({
    required SharedPreferences prefs,
  }) async {
    if (prefs.getBool(_manualLanguageSelectedKey) ?? false) {
      return true;
    }
    try {
      if (await _secureStorage.read(key: _manualLanguageSelectedKey) ==
          'true') {
        return true;
      }
    } catch (_) {}
    try {
      final nativeState = await NativeStartupStateStore.readAll();
      if (nativeState[_manualLanguageSelectedKey] == true) {
        return true;
      }
    } catch (_) {}
    try {
      final fileState = await _readStartupStateFile();
      return fileState[_manualLanguageSelectedKey] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markPermissionsStepHandled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsHandledKey, true);
    await _refreshCachedSnapshot(prefs);
  }

  static Future<void> markInitialSetupCompleted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initialSetupCompletedKey, true);
    await _refreshCachedSnapshot(prefs);
  }

  static Future<void> resetPermissionsStep() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsHandledKey, false);
    await prefs.setBool(_initialSetupCompletedKey, false);
    await _refreshCachedSnapshot(prefs);
  }

  static Future<void> syncInitialSetupCompletion({
    required bool isAuthenticated,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool religionHandled = isAuthenticated
        ? await AppReligionService.hasDeviceSelection()
        : false;
    final bool completed =
        (prefs.getBool(_languageSelectedKey) ?? false) &&
        isAuthenticated &&
        religionHandled;
    await prefs.setBool(_initialSetupCompletedKey, completed);
    await _refreshCachedSnapshot(prefs);
  }

  static Future<void> persistLastKnownAuthUid(String? uid) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final trimmed = uid?.trim() ?? '';
      if (trimmed.isEmpty) {
        await _secureStorage.delete(key: _lastKnownAuthUidKey);
        await NativeStartupStateStore.writeEntries(<String, Object?>{
          _lastKnownAuthUidKey: null,
        });
        await _writeStartupStateFile(<String, Object?>{
          _lastKnownAuthUidKey: null,
        });
        await prefs.remove(_lastKnownAuthUidKey);
        _cachedLastKnownAuthUid = null;
      } else {
        await _secureStorage.write(key: _lastKnownAuthUidKey, value: trimmed);
        await NativeStartupStateStore.writeEntries(<String, Object?>{
          _lastKnownAuthUidKey: trimmed,
        });
        await _writeStartupStateFile(<String, Object?>{
          _lastKnownAuthUidKey: trimmed,
        });
        await prefs.setString(_lastKnownAuthUidKey, trimmed);
        _cachedLastKnownAuthUid = trimmed;
      }
    } catch (_) {}
  }

  static Future<String?> loadLastKnownAuthUid({
    SharedPreferences? prefs,
  }) async {
    if (prefs == null) {
      final cached = _cachedLastKnownAuthUid?.trim() ?? '';
      if (cached.isNotEmpty) {
        return cached;
      }
    }
    try {
      final SharedPreferences resolvedPrefs =
          prefs ?? await SharedPreferences.getInstance();
      final trimmed = await _loadStoredAuthUid(prefs: resolvedPrefs) ?? '';
      _cachedLastKnownAuthUid = trimmed.isEmpty ? null : trimmed;
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> resolvePermissionsStepHandled({
    SharedPreferences? prefs,
  }) async {
    final SharedPreferences resolvedPrefs =
        prefs ?? await SharedPreferences.getInstance();
    return resolvedPrefs.getBool(_permissionsHandledKey) ?? false;
  }

  static Future<String> resolveAuthenticatedEntryRoute({
    bool includeReligionGate = true,
  }) async {
    if (includeReligionGate && !await AppReligionService.hasDeviceSelection()) {
      return AppRoutes.religion;
    }
    final PosterProfileData profile = await PosterProfileService.load();
    final bool canEnterHome =
        PosterProfileService.isSetupComplete(profile) ||
        await PosterProfileService.hasSkippedSetup();
    return canEnterHome ? AppRoutes.home : AppRoutes.profileSetup;
  }

  static Future<String> resolvePostRegionEntryRoute() async {
    final currentUser = await _resolveInitialCurrentUser();
    if (currentUser?.uid.trim().isNotEmpty != true) {
      return AppRoutes.login;
    }
    return resolveAuthenticatedEntryRoute();
  }

  static Future<String> resolvePostSplashEntryRoute({
    SharedPreferences? prefs,
  }) async {
    final SharedPreferences resolvedPrefs =
        prefs ?? await SharedPreferences.getInstance();
    final snapshot = await loadSnapshot(prefs: resolvedPrefs);
    final currentUser = await _resolveInitialCurrentUser();
    final cachedAuthUid = await loadLastKnownAuthUid(prefs: resolvedPrefs);
    final hasAuthenticatedUser =
        currentUser?.uid.trim().isNotEmpty == true ||
        (Firebase.apps.isEmpty && (cachedAuthUid?.trim().isNotEmpty ?? false));
    if (hasAuthenticatedUser) {
      return resolveAuthenticatedEntryRouteForStartup(
        startupUidHint: currentUser?.uid ?? cachedAuthUid,
        prefs: resolvedPrefs,
      );
    }
    final hasSelectedRegion = await AppRegionService.hasSelection(
      prefs: resolvedPrefs,
    );
    return determineStartupRoute(
      hasAuthenticatedUser: hasAuthenticatedUser,
      hasSelectedRegion: hasSelectedRegion,
      hasSelectedLanguage: snapshot.languageSelected,
    );
  }

  static String determineStartupRoute({
    required bool hasAuthenticatedUser,
    required bool hasSelectedRegion,
    required bool hasSelectedLanguage,
  }) {
    if (hasAuthenticatedUser) {
      return AppRoutes.home;
    }
    if (!hasSelectedRegion) {
      return AppRoutes.language;
    }
    if (!hasSelectedLanguage) {
      return AppRoutes.appLanguage;
    }
    return AppRoutes.login;
  }

  static Future<String> resolveAuthenticatedEntryRouteForStartup({
    bool includeReligionGate = true,
    String? startupUidHint,
    bool allowRemoteProfileRefresh = true,
    SharedPreferences? prefs,
  }) async {
    if (includeReligionGate &&
        !await AppReligionService.hasDeviceSelection(
          fallbackUid: startupUidHint,
          prefs: prefs,
        )) {
      return AppRoutes.religion;
    }
    final PosterProfileData localProfile = await PosterProfileService.loadLocal(
      fallbackUid: startupUidHint,
      prefs: prefs,
    );
    final bool hasSkippedSetup = await PosterProfileService.hasSkippedSetup(
      fallbackUid: startupUidHint,
      prefs: prefs,
    );
    if (PosterProfileService.isSetupComplete(localProfile) || hasSkippedSetup) {
      return AppRoutes.home;
    }

    if (!allowRemoteProfileRefresh) {
      return PosterProfileService.isSetupComplete(localProfile) ||
              hasSkippedSetup
          ? AppRoutes.home
          : AppRoutes.profileSetup;
    }

    try {
      final PosterProfileData? remoteProfile =
          await PosterProfileService.refreshFromRemote(
            localProfile: localProfile,
          ).timeout(const Duration(seconds: 2), onTimeout: () => null);
      final PosterProfileData resolved = remoteProfile ?? localProfile;
      return PosterProfileService.isSetupComplete(resolved) || hasSkippedSetup
          ? AppRoutes.home
          : AppRoutes.profileSetup;
    } catch (_) {
      return PosterProfileService.isSetupComplete(localProfile) ||
              hasSkippedSetup
          ? AppRoutes.home
          : AppRoutes.profileSetup;
    }
  }

  static Future<void> syncStoredLanguageToRemote() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppLanguage language = _readLanguage(
      prefs.getString(_selectedLanguageKey),
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final syncKey = '$_lastRemoteLanguageSyncKeyPrefix${user.uid}';
    if (prefs.getString(syncKey) == language.name) {
      return;
    }
    final synced = await _syncLanguageToRemote(language);
    if (!synced) {
      return;
    }
    await prefs.setString(syncKey, language.name);
  }

  static Future<bool> _syncLanguageToRemote(AppLanguage language) async {
    if (Firebase.apps.isEmpty) {
      return false;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
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
      return true;
    } catch (_) {
      // Best-effort sync only. Local flow should continue even if remote save fails.
      return false;
    }
  }

  static AppLanguage _readLanguage(String? rawValue) {
    if (kIsWeb && (rawValue == null || rawValue.trim().isEmpty)) {
      return AppLanguage.english;
    }
    return AppLanguage.values.firstWhere(
      (AppLanguage item) => item.name == rawValue,
      orElse: () => AppLanguage.english,
    );
  }

  static Future<AppFlowSnapshot> _loadDurableSnapshot({
    required SharedPreferences prefs,
    Map<String, Object?>? fileState,
    Map<String, Object?>? nativeState,
  }) async {
    final resolvedNativeState =
        nativeState ?? await NativeStartupStateStore.readAll();
    final resolvedFileState = fileState ?? await _readStartupStateFile();
    final String? secureLanguage = await _secureStorage.read(
      key: _selectedLanguageKey,
    );
    final String? secureLanguageSelected = await _secureStorage.read(
      key: _languageSelectedKey,
    );
    final String prefsLanguage = prefs.getString(_selectedLanguageKey) ?? '';
    final bool prefsLanguageSelected =
        prefs.getBool(_languageSelectedKey) ?? false;
    final bool manualLanguageSelected =
        prefs.getBool(_manualLanguageSelectedKey) ?? false;
    final bool secureManualLanguageSelected =
        await _secureStorage.read(key: _manualLanguageSelectedKey) == 'true';
    final bool fileManualLanguageSelected =
        resolvedFileState[_manualLanguageSelectedKey] == true;
    final bool nativeManualLanguageSelected =
        resolvedNativeState[_manualLanguageSelectedKey] == true;
    final bool hasManualLanguageSelection =
        manualLanguageSelected ||
        secureManualLanguageSelected ||
        fileManualLanguageSelected ||
        nativeManualLanguageSelected;
    final bool secureFlag = secureLanguageSelected == 'true';
    final String fileLanguage =
        (resolvedFileState[_selectedLanguageKey] as String? ?? '').trim();
    final bool fileLanguageSelected =
        resolvedFileState[_languageSelectedKey] == true;
    final String nativeLanguage =
        (resolvedNativeState[_selectedLanguageKey] as String? ?? '').trim();
    final bool nativeLanguageSelected =
        resolvedNativeState[_languageSelectedKey] == true;
    final String manualLanguageRaw = prefsLanguage.isNotEmpty
        ? prefsLanguage
        : (nativeLanguage.isNotEmpty
              ? nativeLanguage
              : (fileLanguage.isNotEmpty
                    ? fileLanguage
                    : (secureLanguage ?? '')));
    final String resolvedLanguageRaw =
        hasManualLanguageSelection && manualLanguageRaw.isNotEmpty
        ? manualLanguageRaw
        : (prefsLanguage.isNotEmpty
              ? prefsLanguage
              : (nativeLanguage.isNotEmpty
                    ? nativeLanguage
                    : (fileLanguage.isNotEmpty
                          ? fileLanguage
                          : (secureLanguage ?? ''))));
    final bool languageSelected =
        prefsLanguageSelected ||
        nativeLanguageSelected ||
        fileLanguageSelected ||
        secureFlag;
    final AppLanguage language = _readLanguage(resolvedLanguageRaw);

    if (prefsLanguage != language.name) {
      await prefs.setString(_selectedLanguageKey, language.name);
    }
    if (languageSelected && !prefsLanguageSelected) {
      await prefs.setBool(_languageSelectedKey, true);
    }
    if ((secureLanguage ?? '') != language.name) {
      await _secureStorage.write(
        key: _selectedLanguageKey,
        value: language.name,
      );
    }
    if (languageSelected && !secureFlag) {
      await _secureStorage.write(key: _languageSelectedKey, value: 'true');
    }
    if (hasManualLanguageSelection && !manualLanguageSelected) {
      await prefs.setBool(_manualLanguageSelectedKey, true);
    }
    if (hasManualLanguageSelection && !secureManualLanguageSelected) {
      await _secureStorage.write(
        key: _manualLanguageSelectedKey,
        value: 'true',
      );
    }
    if (nativeLanguage != language.name ||
        nativeLanguageSelected != languageSelected ||
        nativeManualLanguageSelected != hasManualLanguageSelection) {
      await NativeStartupStateStore.writeEntries(<String, Object?>{
        _selectedLanguageKey: language.name,
        _languageSelectedKey: languageSelected,
        _manualLanguageSelectedKey: hasManualLanguageSelection,
      });
    }
    if (fileLanguage != language.name ||
        fileLanguageSelected != languageSelected ||
        fileManualLanguageSelected != hasManualLanguageSelection) {
      await _writeStartupStateFile(<String, Object?>{
        _selectedLanguageKey: language.name,
        _languageSelectedKey: languageSelected,
        _manualLanguageSelectedKey: hasManualLanguageSelection,
      });
    }

    if (languageSelected) {
      _memoryLanguage = language;
      _memoryLanguageSelected = true;
    }

    return AppFlowSnapshot(
      language: language,
      languageSelected: languageSelected || _memoryLanguageSelected,
      permissionsStepHandled: prefs.getBool(_permissionsHandledKey) ?? false,
      initialSetupCompleted: prefs.getBool(_initialSetupCompletedKey) ?? false,
    );
  }

  static Future<void> _refreshCachedSnapshot(SharedPreferences prefs) async {
    _cachedSnapshot = await _loadDurableSnapshot(prefs: prefs);
  }

  static Future<String?> _loadStoredAuthUid({
    required SharedPreferences prefs,
    Map<String, Object?>? fileState,
    Map<String, Object?>? nativeState,
  }) async {
    final resolvedNativeState =
        nativeState ?? await NativeStartupStateStore.readAll();
    final resolvedFileState = fileState ?? await _readStartupStateFile();
    final prefsUid = (prefs.getString(_lastKnownAuthUidKey) ?? '').trim();
    final secureUid =
        (await _secureStorage.read(key: _lastKnownAuthUidKey) ?? '').trim();
    final nativeUid =
        (resolvedNativeState[_lastKnownAuthUidKey] as String? ?? '').trim();
    final fileUid = (resolvedFileState[_lastKnownAuthUidKey] as String? ?? '')
        .trim();
    final resolved = prefsUid.isNotEmpty
        ? prefsUid
        : (nativeUid.isNotEmpty
              ? nativeUid
              : (fileUid.isNotEmpty ? fileUid : secureUid));
    if (resolved.isEmpty) {
      return null;
    }
    if (prefsUid != resolved) {
      await prefs.setString(_lastKnownAuthUidKey, resolved);
    }
    if (secureUid != resolved) {
      await _secureStorage.write(key: _lastKnownAuthUidKey, value: resolved);
    }
    await NativeStartupStateStore.writeEntries(<String, Object?>{
      _lastKnownAuthUidKey: resolved,
    });
    await _writeStartupStateFile(<String, Object?>{
      _lastKnownAuthUidKey: resolved,
    });
    return resolved;
  }

  static Future<Map<String, Object?>> _readStartupStateFile() async {
    try {
      final file = await _startupStateFile();
      if (!await file.exists()) {
        return <String, Object?>{};
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return <String, Object?>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return <String, Object?>{};
  }

  static Future<void> _writeStartupStateFile(
    Map<String, Object?> updates,
  ) async {
    try {
      final current = await _readStartupStateFile();
      current.addAll(updates);
      current.removeWhere((key, value) => value == null);
      final file = await _startupStateFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(current), flush: true);
    } catch (_) {}
  }

  static Future<File> _startupStateFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}$_startupStateFileName',
    );
  }

  static Future<User?> _resolveInitialCurrentUser() async {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }
    try {
      return await auth.authStateChanges().first;
    } catch (_) {
      return auth.currentUser;
    }
  }

  static const String _lastDailyHeartbeatKey = 'user_last_heartbeat_ist_day_v1';

  static Future<void> recordZeroCostDailyHeartbeat() async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.trim().isEmpty) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastRecordedDay = prefs.getString(_lastDailyHeartbeatKey);
      if (lastRecordedDay == todayKey) {
        return; // Zero cost: already recorded once today for this user
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(<String, dynamic>{
            'lastActiveDay': todayKey,
            'lastActiveAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));

      await prefs.setString(_lastDailyHeartbeatKey, todayKey);
    } catch (_) {}
  }
}
