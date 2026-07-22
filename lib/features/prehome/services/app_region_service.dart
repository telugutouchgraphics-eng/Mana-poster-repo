import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/services/native_startup_state_store.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/services/device_session_service.dart';

class AppRegionService {
  AppRegionService._();

  static const String fallbackRegionId = 'telangana';
  static const String selectedRegionKey = 'selected_region_v1';
  static const String selectedRegionLanguageKey = 'selected_region_language_v1';
  static const String selectedRegionLanguageCodeKey =
      'selected_region_language_code_v1';
  static const String _lastRemoteSyncKey = 'selected_region_remote_sync_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static AppRegion? _memoryRegion;
  static final ValueNotifier<int> selectionVersion = ValueNotifier<int>(0);

  static Future<AppRegion?> loadSelection({SharedPreferences? prefs}) async {
    final cached = _memoryRegion;
    if (cached != null) {
      return cached;
    }

    SharedPreferences? resolvedPrefs;
    try {
      resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
      final prefsRegionId = resolvedPrefs.getString(selectedRegionKey);
      final prefsRegion = appRegionById(prefsRegionId);
      if (prefsRegion != null) {
        await _mirrorLocalSelection(prefsRegion, resolvedPrefs);
        _memoryRegion = prefsRegion;
        unawaited(_syncToRemote(prefsRegion));
        return prefsRegion;
      }
    } catch (_) {
      resolvedPrefs = null;
    }

    final nativeRegion = await _loadNativeRegion();
    if (nativeRegion != null) {
      final prefsForMirror =
          resolvedPrefs ?? prefs ?? await SharedPreferences.getInstance();
      await _mirrorLocalSelection(nativeRegion, prefsForMirror);
      _memoryRegion = nativeRegion;
      unawaited(_syncToRemote(nativeRegion));
      return nativeRegion;
    }

    final secureRegion = await _loadSecureRegion();
    if (secureRegion != null) {
      final prefsForMirror =
          resolvedPrefs ?? prefs ?? await SharedPreferences.getInstance();
      await _mirrorLocalSelection(secureRegion, prefsForMirror);
      _memoryRegion = secureRegion;
      unawaited(_syncToRemote(secureRegion));
      return secureRegion;
    }

    final remoteRegion = await _loadRemoteRegion();
    if (remoteRegion != null) {
      final prefsForMirror =
          resolvedPrefs ?? prefs ?? await SharedPreferences.getInstance();
      await _mirrorLocalSelection(remoteRegion, prefsForMirror);
      _memoryRegion = remoteRegion;
      return remoteRegion;
    }
    return _memoryRegion;
  }

  static Future<bool> hasSelection({SharedPreferences? prefs}) async {
    return await loadSelection(prefs: prefs) != null;
  }

  static Future<bool> persistSelection(AppRegion region) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _mirrorLocalSelection(region, prefs);
      _memoryRegion = region;
      selectionVersion.value++;
      unawaited(_syncToRemote(region));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> ensureRemoteSelectionSynced([AppRegion? region]) async {
    final resolvedRegion = region ?? await loadSelection();
    if (resolvedRegion == null) {
      return;
    }
    await _syncToRemote(resolvedRegion);
  }

  static Future<void> _mirrorLocalSelection(
    AppRegion region,
    SharedPreferences prefs,
  ) async {
    await prefs.setString(selectedRegionKey, region.id);
    await prefs.setString(selectedRegionLanguageKey, region.primaryLanguage);
    await prefs.setString(
      selectedRegionLanguageCodeKey,
      region.primaryLanguageCode,
    );
    await _secureStorage.write(key: selectedRegionKey, value: region.id);
    await _secureStorage.write(
      key: selectedRegionLanguageKey,
      value: region.primaryLanguage,
    );
    await _secureStorage.write(
      key: selectedRegionLanguageCodeKey,
      value: region.primaryLanguageCode,
    );
    await NativeStartupStateStore.writeEntries(<String, Object?>{
      selectedRegionKey: region.id,
      selectedRegionLanguageKey: region.primaryLanguage,
      selectedRegionLanguageCodeKey: region.primaryLanguageCode,
    });
  }

  static Future<AppRegion?> _loadNativeRegion() async {
    try {
      final nativeState = await NativeStartupStateStore.readAll();
      return appRegionById(nativeState[selectedRegionKey] as String?);
    } catch (_) {
      return null;
    }
  }

  static Future<AppRegion?> _loadSecureRegion() async {
    try {
      return appRegionById(await _secureStorage.read(key: selectedRegionKey));
    } catch (_) {
      return null;
    }
  }

  static Future<AppRegion?> _loadRemoteRegion() async {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 4));
      return appRegionById(snapshot.data()?['selectedRegion'] as String?);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _syncToRemote(AppRegion region) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncValue =
          '${user.uid}:${region.id}:${region.primaryLanguageCode}';
      if (prefs.getString(_lastRemoteSyncKey) == syncValue) {
        return;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'selectedRegion': region.id,
            'selectedRegionName': region.name,
            'selectedRegionLanguage': region.primaryLanguage,
            'selectedRegionLanguageCode': region.primaryLanguageCode,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
      await prefs.setString(_lastRemoteSyncKey, syncValue);
      unawaited(DeviceSessionService.instance.refreshRegionSession(region));
    } catch (_) {
      // Local startup state is the source of truth for this flow.
    }
  }
}
