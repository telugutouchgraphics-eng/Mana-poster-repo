import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class PoliticalPartyLogoService {
  const PoliticalPartyLogoService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  static Map<String, String> _cachedLogoUrlsByPartyId =
      const <String, String>{};

  Stream<Map<String, String>> watchLogoUrlsByPartyId() {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return Stream<Map<String, String>>.value(_cachedLogoUrlsByPartyId);
    }
    return firestore
        .collection('politicalPartyLogos')
        .where('active', isEqualTo: true)
        .limit(150)
        .snapshots()
        .map((snapshot) {
          final mapped = _mapLogoUrls(snapshot.docs);
          _cachedLogoUrlsByPartyId = mapped;
          return mapped;
        });
  }

  Future<Map<String, String>> fetchLogoUrlsByPartyId() async {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return _cachedLogoUrlsByPartyId;
    }
    try {
      final snapshot = await firestore
          .collection('politicalPartyLogos')
          .where('active', isEqualTo: true)
          .limit(150)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      final mapped = _mapLogoUrls(snapshot.docs);
      _cachedLogoUrlsByPartyId = mapped;
      return mapped;
    } catch (_) {
      try {
        final snapshot = await firestore
            .collection('politicalPartyLogos')
            .where('active', isEqualTo: true)
            .limit(150)
            .get()
            .timeout(const Duration(seconds: 4));
        final mapped = _mapLogoUrls(snapshot.docs);
        _cachedLogoUrlsByPartyId = mapped;
        return mapped;
      } catch (_) {
        return _cachedLogoUrlsByPartyId;
      }
    }
  }

  Map<String, String> _mapLogoUrls(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final mapped = <String, String>{};
    for (final doc in docs) {
      final data = doc.data();
      final logoUrl = (data['logoUrl'] as String? ?? '').trim();
      if (logoUrl.isEmpty) {
        continue;
      }
      final ids = <String>{
        doc.id,
        data['id'] as String? ?? '',
        data['partyId'] as String? ?? '',
        data['partyCategoryId'] as String? ?? '',
      };
      for (final id in ids) {
        final normalized = _normalizePartyId(id);
        if (normalized.isEmpty) {
          continue;
        }
        mapped[normalized] = logoUrl;
        if (normalized.startsWith('party_')) {
          mapped[normalized.substring('party_'.length)] = logoUrl;
        } else {
          mapped['party_$normalized'] = logoUrl;
        }
      }
    }
    return Map<String, String>.unmodifiable(mapped);
  }

  String _normalizePartyId(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}
