import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';

class ApprovedCreatorTemplateService {
  const ApprovedCreatorTemplateService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<List<ApprovedCreatorTemplate>> fetchApprovedTemplates({
    int maxItems = 40,
  }) async {
    try {
      // NOTE:
      // Firestore rules allow reads only when status == "approved".
      // So this query must stay exactly aligned with that rule.
      final snapshot = await firestore
          .collection('creatorPosters')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(maxItems)
          .get();
      return _mapSnapshot(snapshot);
    } catch (error, stackTrace) {
      debugPrint(
        'ApprovedCreatorTemplateService.fetchApprovedTemplates failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return const <ApprovedCreatorTemplate>[];
    }
  }

  Future<List<ApprovedCreatorTemplate>> fetchApprovedTemplatesFromCache({
    int maxItems = 40,
  }) async {
    try {
      final snapshot = await firestore
          .collection('creatorPosters')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(maxItems)
          .get(const GetOptions(source: Source.cache));
      return _mapSnapshot(snapshot);
    } catch (error, stackTrace) {
      debugPrint(
        'ApprovedCreatorTemplateService.fetchApprovedTemplatesFromCache failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return const <ApprovedCreatorTemplate>[];
    }
  }

  List<ApprovedCreatorTemplate> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final templates = snapshot.docs
        .map(_mapDoc)
        .whereType<ApprovedCreatorTemplate>()
        .toList(growable: false);
    templates.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return templates;
  }

  ApprovedCreatorTemplate? _mapDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final imageUrl =
        (data['imageUrl'] as String?)?.trim() ??
        (data['posterUrl'] as String?)?.trim() ??
        (data['previewUrl'] as String?)?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    final title =
        (data['title'] as String?)?.trim().isNotEmpty == true
        ? (data['title'] as String).trim()
        : 'Creator Poster';
    final categoryId = (data['categoryId'] as String?)?.trim() ?? '';
    final categoryLabel = (data['categoryLabel'] as String?)?.trim() ?? '';
    final createdAtRaw = data['createdAt'];
    final updatedAtRaw = data['updatedAt'];
    final createdAtMillis =
        _toMillis(createdAtRaw) ?? _toMillis(updatedAtRaw) ?? 0;

    return ApprovedCreatorTemplate(
      id: doc.id,
      title: title,
      imageUrl: imageUrl,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      createdAtMillis: createdAtMillis,
      personalizationConfig: _parsePersonalization(
        data['personalizationConfig'],
      ),
      creatorPublicId: (data['creatorPublicId'] as String? ?? '').trim(),
    );
  }

  CreatorPosterPersonalization _parsePersonalization(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return CreatorPosterPersonalization.defaults;
    }
    return CreatorPosterPersonalization(
      photoShape: _parsePhotoShape(raw['photoShape']),
      photoX: _parseDouble(raw['photoX'], 50),
      photoY: _parseDouble(raw['photoY'], 45),
      photoScale: _parseDouble(raw['photoScale'], 36),
      nameX: _parseDouble(raw['nameX'], 50),
      nameY: _parseDouble(raw['nameY'], 82),
      showBottomStrip: raw['showBottomStrip'] is bool
          ? raw['showBottomStrip'] as bool
          : true,
      stripHeight: _parseDouble(raw['stripHeight'], 16),
      showWhatsapp: raw['showWhatsapp'] is bool
          ? raw['showWhatsapp'] as bool
          : true,
      sampleName: (raw['sampleName'] as String? ?? '').trim().isNotEmpty
          ? (raw['sampleName'] as String).trim()
          : CreatorPosterPersonalization.defaults.sampleName,
      photoRenderMode: _parseRenderMode(raw['photoRenderMode']),
      edgeStyle: _parseEdgeStyle(raw['edgeStyle']),
      showSafeAreas: raw['showSafeAreas'] is bool
          ? raw['showSafeAreas'] as bool
          : true,
    );
  }

  String _parseRenderMode(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    return value == 'original' ? 'original' : 'cutout';
  }

  String _parseEdgeStyle(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    return value == 'sharp' ? 'sharp' : 'soft_fade';
  }

  String _parsePhotoShape(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    switch (value) {
      case 'circle':
      case 'rounded':
      case 'square':
      case 'hexagon':
      case 'pill':
        return value;
      default:
        return CreatorPosterPersonalization.defaults.photoShape;
    }
  }

  double _parseDouble(Object? raw, double fallback) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw) ?? fallback;
    }
    return fallback;
  }

  int? _toMillis(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) {
        return asInt;
      }
      return DateTime.tryParse(value)?.millisecondsSinceEpoch;
    }
    return null;
  }
}
