import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/services/native_startup_state_store.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';

class AppRegionService {
  AppRegionService._();

  static const String _selectedLanguageKey = 'selected_language';
  static const String _languageSelectedKey = 'language_selected';
  static const String selectedRegionKey = 'selected_region_v1';
  static const String selectedRegionLanguageKey = 'selected_region_language_v1';
  static const String selectedRegionLanguageCodeKey =
      'selected_region_language_code_v1';
  static const String _lastRemoteSyncKey = 'selected_region_remote_sync_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static AppRegion? _memoryRegion;

  static Future<AppRegion?> loadSelection({SharedPreferences? prefs}) async {
    final cached = _memoryRegion;
    if (cached != null) {
      return cached;
    }

    try {
      final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
      final nativeState = await NativeStartupStateStore.readAll();
      final prefsRegionId = resolvedPrefs.getString(selectedRegionKey);
      final nativeRegionId = nativeState[selectedRegionKey] as String?;
      final secureRegionId = await _secureStorage.read(key: selectedRegionKey);
      final region =
          appRegionById(prefsRegionId) ??
          appRegionById(nativeRegionId) ??
          appRegionById(secureRegionId);
      if (region == null) {
        return null;
      }
      await _mirrorLocalSelection(region, resolvedPrefs);
      _memoryRegion = region;
      return region;
    } catch (_) {
      return _memoryRegion;
    }
  }

  static Future<bool> hasSelection({SharedPreferences? prefs}) async {
    return await loadSelection(prefs: prefs) != null;
  }

  static Future<bool> persistSelection(AppRegion region) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _mirrorLocalSelection(region, prefs);
      final stored = await loadSelection(prefs: prefs);
      if (stored?.id != region.id) {
        return false;
      }
      _memoryRegion = region;
      unawaited(_syncToRemote(region));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _mirrorLocalSelection(
    AppRegion region,
    SharedPreferences prefs,
  ) async {
    await prefs.setString(_selectedLanguageKey, region.appLanguage.name);
    await prefs.setBool(_languageSelectedKey, true);
    await prefs.setString(selectedRegionKey, region.id);
    await prefs.setString(selectedRegionLanguageKey, region.primaryLanguage);
    await prefs.setString(
      selectedRegionLanguageCodeKey,
      region.primaryLanguageCode,
    );
    await _secureStorage.write(
      key: _selectedLanguageKey,
      value: region.appLanguage.name,
    );
    await _secureStorage.write(key: _languageSelectedKey, value: 'true');
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
      _selectedLanguageKey: region.appLanguage.name,
      _languageSelectedKey: true,
      selectedRegionKey: region.id,
      selectedRegionLanguageKey: region.primaryLanguage,
      selectedRegionLanguageCodeKey: region.primaryLanguageCode,
    });
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
            'preferredLanguage': region.appLanguage.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
      await prefs.setString(_lastRemoteSyncKey, syncValue);
    } catch (_) {
      // Local startup state is the source of truth for this flow.
    }
  }
}
