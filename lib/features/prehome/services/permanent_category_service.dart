import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

const bool _verbosePermanentCategoryLogs = false;

class PermanentCategoryService {
  const PermanentCategoryService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  void _debugLog(String message) {
    if (!_verbosePermanentCategoryLogs || (!kDebugMode && !kProfileMode)) {
      return;
    }
    debugPrint(message);
  }

  Future<List<DynamicCategory>> fetchActiveCategories({
    AppLanguage language = AppLanguage.telugu,
    Source source = Source.serverAndCache,
  }) async {
    try {
      final snapshot = await firestore
          .collection('permanentCategories')
          .where('active', isEqualTo: true)
          .get(GetOptions(source: source));
      final categories =
          snapshot.docs
              .map((doc) => _mapDoc(doc, language: language))
              .whereType<DynamicCategory>()
              .toList(growable: false)
            ..sort((left, right) {
              final sortCompare = left.sortOrder.compareTo(right.sortOrder);
              if (sortCompare != 0) {
                return sortCompare;
              }
              return left.label.compareTo(right.label);
            });
      _debugLog(
        '[PermanentCategories] docs=${snapshot.docs.length} active=${categories.map((item) => item.slug).join(",")} source=$source',
      );
      return categories;
    } catch (error) {
      _debugLog('[PermanentCategories] failed error=$error source=$source');
      return const <DynamicCategory>[];
    }
  }

  DynamicCategory? _mapDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required AppLanguage language,
  }) {
    final data = doc.data();
    final id = (data['id'] as String?)?.trim() ?? doc.id.trim();
    final rawLabel = (data['label'] as String?)?.trim() ?? id;
    if (id.isEmpty || rawLabel.isEmpty) {
      return null;
    }
    final normalizedId = _normalizeTag(id);
    final localizedLabel = _labelForLanguage(data, rawLabel, language);
    final normalizedLabel = _normalizeTag(localizedLabel);
    return DynamicCategory(
      id: id,
      slug: id,
      label: localizedLabel,
      type: DynamicCategoryType.importantDay,
      scope: DynamicEventScope.global,
      priority: 40,
      sortOrder: _toInt(data['sortOrder']),
      tags: <String>[
        id,
        if (normalizedId.isNotEmpty) normalizedId,
        if (normalizedLabel.isNotEmpty) normalizedLabel,
        rawLabel,
        'permanent_category',
      ],
      isBlinking: false,
    );
  }

  String _labelForLanguage(
    Map<String, dynamic> data,
    String fallback,
    AppLanguage language,
  ) {
    final labels = data['labelsByLanguage'];
    if (labels is Map) {
      final direct = (labels[language.name] as String?)?.trim();
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }
      final supported = (labels[language.supportedUiLanguage.name] as String?)
          ?.trim();
      if (supported != null && supported.isNotEmpty) {
        return supported;
      }
    }
    return ScriptLocalizationService.localizeCategoryLabel(fallback, language);
  }

  int _toInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return 0;
  }

  String _normalizeTag(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
