import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mana_poster/features/prehome/services/app_region_service.dart';

class PoliticalProtocolPhotoService {
  const PoliticalProtocolPhotoService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<List<String>> fetchPhotoUrlsForParty(String partyId) async {
    final normalizedPartyId = partyId.trim();
    if (normalizedPartyId.isEmpty ||
        (_firestore == null && Firebase.apps.isEmpty)) {
      return const <String>[];
    }
    final region = await AppRegionService.loadSelection();
    final regionId = (region?.id ?? AppRegionService.fallbackRegionId).trim();
    if (regionId.isEmpty) {
      return const <String>[];
    }
    try {
      final snapshot = await firestore
          .collection('politicalProtocolPhotos')
          .where('active', isEqualTo: true)
          .where('regionId', isEqualTo: regionId)
          .where('partyId', isEqualTo: normalizedPartyId)
          .limit(12)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      return _mapUrls(snapshot.docs);
    } catch (_) {
      try {
        final snapshot = await firestore
            .collection('politicalProtocolPhotos')
            .where('active', isEqualTo: true)
            .where('regionId', isEqualTo: regionId)
            .where('partyId', isEqualTo: normalizedPartyId)
            .limit(12)
            .get()
            .timeout(const Duration(seconds: 4));
        return _mapUrls(snapshot.docs);
      } catch (_) {
        return const <String>[];
      }
    }
  }

  List<String> _mapUrls(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final rows = docs
        .map((doc) {
          final data = doc.data();
          return (
            url: (data['imageUrl'] as String? ?? '').trim(),
            sortOrder: _toInt(data['sortOrder']),
            createdAt: _toInt(data['createdAt']),
          );
        })
        .where((item) => item.url.isNotEmpty)
        .toList(growable: false);
    rows.sort((a, b) {
      final orderComparison = a.sortOrder.compareTo(b.sortOrder);
      if (orderComparison != 0) {
        return orderComparison;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return rows.map((item) => item.url).toList(growable: false);
  }

  int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
