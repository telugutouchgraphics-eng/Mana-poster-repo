import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mana_poster/app/services/native_startup_state_store.dart';

enum AppReligionPreference { hindu, muslim, christian, all }

class AppReligionService {
  AppReligionService._();

  static const String _localKeyPrefix = 'selected_religion_v1_';
  static const String _remoteFieldKey = 'religionPreference';
  static const String _lastRemoteSyncKeyPrefix =
      'selected_religion_remote_sync_attempt_v1_';
  static const String _religionStateFileName = 'app_religion_state_v1.json';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static final Map<String, AppReligionPreference> _memorySelections =
      <String, AppReligionPreference>{};

  static Future<AppReligionPreference?> loadSelection() async {
    final user = _currentUser();
    if (user == null) {
      return null;
    }

    final cached = _memorySelections[user.uid];
    if (cached != null) {
      return cached;
    }

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final stored = await _loadStoredPreference(user.uid, prefs: prefs);
      if (stored != null) {
        _memorySelections[user.uid] = stored;
        return stored;
      }
    } catch (_) {
      prefs = null;
    }

    final remote = await _loadFromRemote(user.uid);
    if (remote != null) {
      _memorySelections[user.uid] = remote;
      try {
        await prefs?.setString(_localKey(user.uid), remote.name);
      } catch (_) {}
    }
    return remote;
  }

  static Future<bool> hasSelection() async {
    return (await loadSelection()) != null;
  }

  static Future<bool> hasDeviceSelection({
    String? fallbackUid,
    SharedPreferences? prefs,
  }) async {
    final uid = _resolvedUid(fallbackUid);
    if (uid == null) {
      return false;
    }

    if (_memorySelections[uid] != null) {
      return true;
    }

    try {
      final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
      return await _loadStoredPreference(uid, prefs: resolvedPrefs) != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> persistSelection(AppReligionPreference preference) async {
    final user = _currentUser();
    if (user == null) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await _secureStorage.write(
        key: _localKey(user.uid),
        value: preference.name,
      );
      await NativeStartupStateStore.writeEntries(<String, Object?>{
        _localKey(user.uid): preference.name,
      });
      await _writeReligionStateFile(<String, Object?>{user.uid: preference.name});
      await prefs.setString(_localKey(user.uid), preference.name);
      final storedPreference = await _loadStoredPreference(user.uid, prefs: prefs);
      if (storedPreference != preference) {
        return false;
      }
      _memorySelections[user.uid] = preference;
      final syncKey = '$_lastRemoteSyncKeyPrefix${user.uid}';
      if (prefs.getString(syncKey) == preference.name) {
        unawaited(_syncToRemote(user.uid, preference));
        return true;
      }
      await prefs.setString(syncKey, preference.name);
      if (prefs.getString(syncKey) != preference.name) {
        return false;
      }
    } catch (_) {
      return false;
    }

    unawaited(_syncToRemote(user.uid, preference));
    return true;
  }

  static Set<String> hiddenCategorySlugsFor(AppReligionPreference preference) {
    return switch (preference) {
      AppReligionPreference.hindu => const <String>{'islam', 'bible'},
      AppReligionPreference.muslim => const <String>{
        'gita_wisdom',
        'devotional',
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
        'bible',
        'weekday_special',
        'weekday_monday_special',
        'weekday_tuesday_special',
        'weekday_wednesday_special',
        'weekday_thursday_special',
        'weekday_friday_special',
        'weekday_saturday_special',
        'weekday_sunday_special',
      },
      AppReligionPreference.christian => const <String>{
        'gita_wisdom',
        'devotional',
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
        'islam',
        'weekday_special',
        'weekday_monday_special',
        'weekday_tuesday_special',
        'weekday_wednesday_special',
        'weekday_thursday_special',
        'weekday_friday_special',
        'weekday_saturday_special',
        'weekday_sunday_special',
      },
      AppReligionPreference.all => const <String>{},
    };
  }

  static String _localKey(String userId) => '$_localKeyPrefix$userId';

  static User? _currentUser() {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String? _resolvedUid(String? fallbackUid) {
    final currentUid = _currentUser()?.uid.trim();
    if (currentUid != null && currentUid.isNotEmpty) {
      return currentUid;
    }
    final fallback = fallbackUid?.trim() ?? '';
    return fallback.isEmpty ? null : fallback;
  }

  static AppReligionPreference? _readPreference(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }
    for (final item in AppReligionPreference.values) {
      if (item.name == rawValue.trim()) {
        return item;
      }
    }
    return null;
  }

  static Future<AppReligionPreference?> _loadFromRemote(String userId) async {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 2));
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return _readPreference(data[_remoteFieldKey] as String?);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _syncToRemote(
    String userId,
    AppReligionPreference preference,
  ) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            _remoteFieldKey: preference.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Best-effort sync only.
    }
  }

  static Future<AppReligionPreference?> _loadStoredPreference(
    String uid, {
    required SharedPreferences prefs,
  }) async {
    final prefsValue = prefs.getString(_localKey(uid));
    final nativeState = await NativeStartupStateStore.readAll();
    final nativeValue = nativeState[_localKey(uid)] as String?;
    final secureValue = await _secureStorage.read(key: _localKey(uid));
    final fileState = await _readReligionStateFile();
    final fileValue = fileState[uid] as String?;
    final resolved =
        _readPreference(prefsValue) ??
        _readPreference(nativeValue) ??
        _readPreference(fileValue) ??
        _readPreference(secureValue);
    if (resolved == null) {
      return null;
    }
    if (prefsValue != resolved.name) {
      await prefs.setString(_localKey(uid), resolved.name);
    }
    if (fileValue != resolved.name) {
      await _writeReligionStateFile(<String, Object?>{uid: resolved.name});
    }
    if (nativeValue != resolved.name) {
      await NativeStartupStateStore.writeEntries(<String, Object?>{
        _localKey(uid): resolved.name,
      });
    }
    if (secureValue != resolved.name) {
      await _secureStorage.write(key: _localKey(uid), value: resolved.name);
    }
    return resolved;
  }

  static Future<Map<String, Object?>> _readReligionStateFile() async {
    try {
      final file = await _religionStateFile();
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

  static Future<void> _writeReligionStateFile(Map<String, Object?> updates) async {
    try {
      final current = await _readReligionStateFile();
      current.addAll(updates);
      current.removeWhere((key, value) => value == null);
      final file = await _religionStateFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(current), flush: true);
    } catch (_) {}
  }

  static Future<File> _religionStateFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_religionStateFileName');
  }
}
