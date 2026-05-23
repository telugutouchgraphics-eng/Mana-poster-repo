import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppReligionPreference { hindu, muslim, christian, all }

class AppReligionService {
  AppReligionService._();

  static const String _localKeyPrefix = 'selected_religion_v1_';
  static const String _remoteFieldKey = 'religionPreference';

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
      final stored = _readPreference(prefs.getString(_localKey(user.uid)));
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

  static Future<bool> persistSelection(AppReligionPreference preference) async {
    final user = _currentUser();
    if (user == null) {
      return false;
    }

    _memorySelections[user.uid] = preference;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey(user.uid), preference.name);
    } catch (_) {
      // Keep the in-memory selection so onboarding can continue.
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
        'bible',
      },
      AppReligionPreference.christian => const <String>{
        'gita_wisdom',
        'devotional',
        'mahabharata',
        'islam',
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
}
