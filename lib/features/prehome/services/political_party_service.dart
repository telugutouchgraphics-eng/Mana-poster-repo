import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mana_poster/app/localization/app_language.dart';

import '../models/political_party.dart';

class PoliticalPartyService {
  const PoliticalPartyService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  static List<PoliticalParty> _cachedParties = politicalParties;

  Stream<List<PoliticalParty>> watchParties() {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return Stream<List<PoliticalParty>>.value(_cachedParties);
    }
    return firestore.collection('politicalParties').limit(200).snapshots().map((
      snapshot,
    ) {
      final parties = _mergeManagedParties(snapshot.docs);
      _cachedParties = parties;
      return parties;
    });
  }

  Future<List<PoliticalParty>> fetchParties() async {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return _cachedParties;
    }
    try {
      final snapshot = await firestore
          .collection('politicalParties')
          .limit(200)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      final parties = _mergeManagedParties(snapshot.docs);
      _cachedParties = parties;
      return parties;
    } catch (_) {
      try {
        final snapshot = await firestore
            .collection('politicalParties')
            .limit(200)
            .get()
            .timeout(const Duration(seconds: 4));
        final parties = _mergeManagedParties(snapshot.docs);
        _cachedParties = parties;
        return parties;
      } catch (_) {
        return _cachedParties;
      }
    }
  }

  List<PoliticalParty> _mergeManagedParties(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final byId = <String, PoliticalParty>{
      for (final party in politicalParties) party.id: party,
    };
    final sortOrders = <String, num>{
      for (var index = 0; index < politicalParties.length; index += 1)
        politicalParties[index].id: index,
    };

    for (final doc in docs) {
      final data = doc.data();
      final partyId = _normalizePartyId(
        (data['partyId'] as String? ?? doc.id).trim(),
      );
      if (partyId.isEmpty) {
        continue;
      }
      if (data['active'] == false) {
        byId.remove(partyId);
        continue;
      }
      final name = (data['label'] as String? ?? data['name'] as String? ?? '')
          .trim();
      final shortName = (data['shortName'] as String? ?? '').trim();
      if (name.isEmpty || shortName.isEmpty) {
        continue;
      }
      final regions = _normalizeRegionIds(data['regionIds']);
      final scope = (data['scope'] as String? ?? 'Regional Party').trim();
      final logoUrl = (data['logoUrl'] as String? ?? '').trim();
      final localizedNames = _localizedNamesFromMap(data['labelsByLanguage']);
      byId[partyId] = PoliticalParty(
        id: partyId,
        name: name,
        shortName: shortName,
        scope: scope.isEmpty ? 'Regional Party' : scope,
        regionIds: regions,
        localizedNames: localizedNames,
        logoUrl: logoUrl.isEmpty ? null : logoUrl,
      );
      final sortOrder = data['sortOrder'];
      if (sortOrder is num) {
        sortOrders[partyId] = sortOrder;
      }
    }

    final parties = byId.values.toList(growable: false);
    parties.sort((left, right) {
      final leftOrder = sortOrders[left.id] ?? 10000;
      final rightOrder = sortOrders[right.id] ?? 10000;
      if (leftOrder != rightOrder) {
        return leftOrder.compareTo(rightOrder);
      }
      return left.name.compareTo(right.name);
    });
    return List<PoliticalParty>.unmodifiable(parties);
  }

  Set<String> _normalizeRegionIds(Object? value) {
    if (value is! Iterable) {
      return const <String>{};
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  String _normalizePartyId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Map<AppLanguage, String> _localizedNamesFromMap(Object? value) {
    if (value is! Map) {
      return const <AppLanguage, String>{};
    }
    final labels = <AppLanguage, String>{};
    for (final language in AppLanguage.values) {
      final label = value[language.name]?.toString().trim() ?? '';
      if (label.isNotEmpty) {
        labels[language] = label;
      }
    }
    return Map<AppLanguage, String>.unmodifiable(labels);
  }
}
