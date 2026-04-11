import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';

class ApprovedCreatorTemplateService {
  const ApprovedCreatorTemplateService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<List<ApprovedCreatorTemplate>> fetchApprovedTemplates({
    int maxItems = 100,
  }) async {
    try {
      final snapshot = await firestore
          .collection('creatorPosters')
          .where('status', isEqualTo: 'approved')
          .limit(maxItems)
          .get();

      final templates = snapshot.docs
          .map(_mapDoc)
          .whereType<ApprovedCreatorTemplate>()
          .toList(growable: false);

      templates.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
      return templates;
    } catch (_) {
      return const <ApprovedCreatorTemplate>[];
    }
  }

  ApprovedCreatorTemplate? _mapDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final imageUrl = (data['imageUrl'] as String?)?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    final title =
        (data['title'] as String?)?.trim().isNotEmpty == true
        ? (data['title'] as String).trim()
        : 'Creator Poster';
    final categoryId = (data['categoryId'] as String?)?.trim() ?? '';
    final categoryLabel = (data['categoryLabel'] as String?)?.trim() ?? '';
    final createdAtMillis = (data['createdAt'] as num?)?.toInt() ?? 0;

    return ApprovedCreatorTemplate(
      id: doc.id,
      title: title,
      imageUrl: imageUrl,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      createdAtMillis: createdAtMillis,
    );
  }
}
