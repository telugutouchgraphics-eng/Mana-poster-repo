import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/services/ist_time_service.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

const bool _verboseManualEventCategoryLogs = false;

class ManualEventCategoryService {
  const ManualEventCategoryService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const int _appLeadMillis = 3 * 24 * 60 * 60 * 1000;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  void _debugLog(String message) {
    if (!_verboseManualEventCategoryLogs || (!kDebugMode && !kProfileMode)) {
      return;
    }
    debugPrint(message);
  }

  Future<List<DynamicCategory>> fetchVisibleCategories({
    AppLanguage language = AppLanguage.telugu,
    Source source = Source.serverAndCache,
  }) async {
    try {
      final selectedRegionId =
          (await AppRegionService.loadSelection())?.id.trim() ?? '';
      final snapshot = await firestore
          .collection('manualEventCategories')
          .where('active', isEqualTo: true)
          .get(GetOptions(source: source));
      final now = IstTimeService.nowEpochMillis();
      final categories =
          snapshot.docs
              .map((doc) => _mapDoc(doc, language: language, now: now))
              .whereType<DynamicCategory>()
              .where(
                (category) =>
                    selectedRegionId.isEmpty ||
                    category.regionIds.isEmpty ||
                    category.regionIds.contains(selectedRegionId),
              )
              .toList(growable: false)
            ..sort((left, right) {
              final priorityCompare = right.priority.compareTo(left.priority);
              if (priorityCompare != 0) {
                return priorityCompare;
              }
              return left.slug.compareTo(right.slug);
            });
      _debugLog(
        '[ManualCategories] docs=${snapshot.docs.length} visible=${categories.map((item) => item.slug).join(",")} now=$now source=$source',
      );
      return categories;
    } catch (error) {
      _debugLog('[ManualCategories] failed error=$error source=$source');
      return const <DynamicCategory>[];
    }
  }

  DynamicCategory? _mapDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required AppLanguage language,
    required int now,
  }) {
    final data = doc.data();
    final id = (data['id'] as String?)?.trim() ?? doc.id.trim();
    final rawLabel = (data['label'] as String?)?.trim() ?? id;
    final regionId = (data['regionId'] as String?)?.trim() ?? '';
    final startAt = _toMillis(data['startAt']);
    final endAt = _toMillis(data['endAt']);
    if (id.isEmpty || rawLabel.isEmpty || startAt <= 0 || endAt <= 0) {
      return null;
    }
    final visibleAt = startAt - _appLeadMillis;
    if (now < visibleAt || now > endAt) {
      return null;
    }
    final normalizedId = _normalizeTag(id);
    final localizedLabel = _labelForLanguage(data, rawLabel, language);
    final normalizedLabel = _normalizeTag(rawLabel);
    final iconAssetPath = (data['iconAssetPath'] as String?)?.trim();
    return DynamicCategory(
      id: id,
      slug: id,
      label: localizedLabel,
      type: DynamicCategoryType.importantDay,
      scope: DynamicEventScope.global,
      priority: 95,
      sortOrder: 0,
      tags: <String>[
        id,
        if (normalizedId.isNotEmpty) normalizedId,
        if (normalizedLabel.isNotEmpty) normalizedLabel,
        'manual_event',
        'important_day',
      ],
      isBlinking: true,
      iconAssetPath: iconAssetPath == null || iconAssetPath.isEmpty
          ? null
          : iconAssetPath,
      regionIds: regionId.isEmpty ? const <String>{} : <String>{regionId},
      eventStartDate: DateTime.fromMillisecondsSinceEpoch(startAt),
      eventEndDate: DateTime.fromMillisecondsSinceEpoch(endAt),
    );
  }

  int _toMillis(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is Timestamp) {
      return raw.millisecondsSinceEpoch;
    }
    return 0;
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

  String _normalizeTag(String value) {
    var scratch = value.trim();
    if (scratch.isEmpty) {
      return '';
    }
    for (var round = 0; round < 8; round++) {
      final next = scratch.replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (Match match) => '${match.group(1)}_${match.group(2)}',
      );
      if (next == scratch) {
        break;
      }
      scratch = next;
    }
    return scratch
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
