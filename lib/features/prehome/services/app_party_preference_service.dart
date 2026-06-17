import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/features/prehome/models/political_party.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';

class AppPartyPreferenceService {
  AppPartyPreferenceService._();

  static const String _selectedPartyIdsKey = 'selected_party_ids_v1';
  static const String _lastRemoteSyncKey = 'selected_party_remote_sync_v1';

  static Set<String> _memoryPartyIds = <String>{};

  static Future<Set<String>> loadSelection({SharedPreferences? prefs}) async {
    if (_memoryPartyIds.isNotEmpty) {
      return Set<String>.from(_memoryPartyIds);
    }
    try {
      final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
      final stored =
          resolvedPrefs.getStringList(_selectedPartyIdsKey) ?? <String>[];
      _memoryPartyIds = stored
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
      return Set<String>.from(_memoryPartyIds);
    } catch (_) {
      return Set<String>.from(_memoryPartyIds);
    }
  }

  static Future<bool> persistSelection(Set<String> partyIds) async {
    try {
      final cleanIds = partyIds
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _selectedPartyIdsKey,
        cleanIds.toList()..sort(),
      );
      _memoryPartyIds = cleanIds;
      unawaited(syncStoredSelectionToRemote());
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncStoredSelectionToRemote() async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final partyIds = await loadSelection(prefs: prefs);
    final region = await AppRegionService.loadSelection(prefs: prefs);
    if (region == null) {
      return;
    }
    final partiesById = <String, PoliticalParty>{
      for (final party in politicalParties) party.id: party,
    };
    final selectedParties = partyIds
        .map((id) => partiesById[id])
        .whereType<PoliticalParty>()
        .toList(growable: false);
    final sortedIds = partyIds.toList()..sort();
    final syncValue =
        '${user.uid}:${region.id}:${region.primaryLanguageCode}:${sortedIds.join(',')}';
    if (prefs.getString(_lastRemoteSyncKey) == syncValue) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'selectedRegion': region.id,
            'selectedRegionName': region.name,
            'selectedRegionLanguage': region.primaryLanguage,
            'selectedRegionLanguageCode': region.primaryLanguageCode,
            'preferredLanguage': region.appLanguage.name,
            'selectedPartyIds': sortedIds,
            'selectedParties': selectedParties
                .map(
                  (party) => <String, String>{
                    'id': party.id,
                    'name': party.name,
                    'shortName': party.shortName,
                    'scope': party.scope,
                  },
                )
                .toList(growable: false),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
      await prefs.setString(_lastRemoteSyncKey, syncValue);
    } catch (_) {
      // Best-effort sync. Local preference remains available for startup.
    }
  }
}
