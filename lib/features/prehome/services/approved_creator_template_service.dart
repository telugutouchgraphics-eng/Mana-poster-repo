import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_repository.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_schedule_service.dart';

class ApprovedCreatorTemplatePage {
  const ApprovedCreatorTemplatePage({
    required this.templates,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<ApprovedCreatorTemplate> templates;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class ApprovedCreatorTemplateService {
  static const int _posterRetentionWindowMillis = 7 * 24 * 60 * 60 * 1000;

  ApprovedCreatorTemplateService({
    FirebaseFirestore? firestore,
    DynamicEventRepository dynamicEventRepository =
        const LocalDynamicEventRepository(),
  }) : _firestore = firestore,
       _dynamicEventRepository = dynamicEventRepository;

  final FirebaseFirestore? _firestore;
  final DynamicEventRepository _dynamicEventRepository;

  void _debugLogStack(String message, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
    debugPrintStack(stackTrace: stackTrace);
  }

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<List<ApprovedCreatorTemplate>> fetchApprovedTemplates({
    int maxItems = 40,
  }) async {
    final page = await fetchApprovedTemplatesPage(pageSize: maxItems);
    return page.templates;
  }

  Future<ApprovedCreatorTemplatePage> fetchApprovedTemplatesPage({
    int pageSize = 5,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    Source source = Source.serverAndCache,
  }) async {
    try {
      final queryLimit = (pageSize * 2).clamp(pageSize, pageSize * 3);
      Query<Map<String, dynamic>> query = firestore
          .collection('creatorPosters')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(queryLimit);
      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }
      final snapshot = await query.get(GetOptions(source: source));
      return ApprovedCreatorTemplatePage(
        templates: _filterPublished(_mapSnapshot(snapshot), snapshot, pageSize),
        lastDocument: snapshot.docs.isEmpty
            ? startAfterDocument
            : snapshot.docs.last,
        hasMore: snapshot.docs.length >= queryLimit,
      );
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService.fetchApprovedTemplatesPage failed: $error',
        stackTrace,
      );
      return const ApprovedCreatorTemplatePage(
        templates: <ApprovedCreatorTemplate>[],
        lastDocument: null,
        hasMore: false,
      );
    }
  }

  Future<List<ApprovedCreatorTemplate>> fetchApprovedTemplatesFromCache({
    int maxItems = 40,
  }) async {
    final page = await fetchApprovedTemplatesPageFromCache(pageSize: maxItems);
    return page.templates;
  }

  Future<ApprovedCreatorTemplatePage> fetchApprovedTemplatesPageFromCache({
    int pageSize = 5,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    try {
      return fetchApprovedTemplatesPage(
        pageSize: pageSize,
        startAfterDocument: startAfterDocument,
        source: Source.cache,
      );
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService.fetchApprovedTemplatesPageFromCache failed: $error',
        stackTrace,
      );
      return const ApprovedCreatorTemplatePage(
        templates: <ApprovedCreatorTemplate>[],
        lastDocument: null,
        hasMore: false,
      );
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

  List<ApprovedCreatorTemplate> _filterPublished(
    List<ApprovedCreatorTemplate> templates,
    QuerySnapshot<Map<String, dynamic>> snapshot,
    int maxItems,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final nowDate = DateTime.now();
    final activeDynamicTags = _activeDynamicTagsForDate(nowDate);
    final knownDynamicTags = _knownDynamicTags();
    final publishMap = <String, int>{};
    for (final doc in snapshot.docs) {
      final raw = doc.data()['publishAt'];
      publishMap[doc.id] = _toMillis(raw) ?? 0;
    }
    final filtered = templates
        .where((template) {
          final publishAt = publishMap[template.id] ?? 0;
          final visibleFrom = publishAt > 0
              ? publishAt
              : template.createdAtMillis;
          if (visibleFrom > now) {
            return false;
          }
          final normalized = _normalizeTag(template.categoryId);
          final usesRollingRetention = normalized.isNotEmpty &&
              knownDynamicTags.contains(normalized);
          final retentionMs = usesRollingRetention
              ? _posterRetentionWindowMillis
              : 365 * 24 * 60 * 60 * 1000;
          if (visibleFrom + retentionMs <= now) {
            return false;
          }
          return _isTemplateDynamicCategoryVisible(
            template.categoryId,
            activeDynamicTags,
            knownDynamicTags,
            nowDate,
          );
        })
        .toList(growable: false);
    filtered.sort((a, b) {
      final publishA = publishMap[a.id] ?? 0;
      final publishB = publishMap[b.id] ?? 0;
      final left = publishA > 0 ? publishA : a.createdAtMillis;
      final right = publishB > 0 ? publishB : b.createdAtMillis;
      return right.compareTo(left);
    });
    if (filtered.length <= maxItems) {
      return filtered;
    }
    return filtered.take(maxItems).toList(growable: false);
  }

  ApprovedCreatorTemplate? _mapDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final mediaType = (data['mediaType'] as String? ?? 'image')
        .trim()
        .toLowerCase();
    final imageUrl =
        (data['imageUrl'] as String?)?.trim() ??
        (data['posterUrl'] as String?)?.trim() ??
        (data['previewUrl'] as String?)?.trim();
    final thumbnailUrl =
        (data['thumbnailUrl'] as String?)?.trim() ??
        (data['previewUrl'] as String?)?.trim() ??
        imageUrl;
    final videoUrl =
        (data['videoUrl'] as String?)?.trim() ??
        (data['videoPreviewUrl'] as String?)?.trim() ??
        '';
    final hasVideo = mediaType == 'video' && videoUrl.isNotEmpty;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    if (!hasVideo && !hasImage) {
      return null;
    }

    final title = (data['title'] as String?)?.trim().isNotEmpty == true
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
      imageUrl: imageUrl ?? '',
      thumbnailUrl: thumbnailUrl ?? '',
      mediaType: hasVideo ? 'video' : 'image',
      videoUrl: videoUrl,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      createdAtMillis: createdAtMillis,
      personalizationConfig: _parsePersonalization(
        data['personalizationConfig'] ?? data['personalization'],
      ),
      creatorPublicId: (data['creatorPublicId'] as String? ?? '').trim(),
    );
  }

  CreatorPosterPersonalization _parsePersonalization(Object? raw) {
    final Map<String, dynamic> source;
    if (raw is Map<String, dynamic>) {
      source = raw;
    } else if (raw is Map) {
      source = raw.cast<String, dynamic>();
    } else {
      return CreatorPosterPersonalization.defaults;
    }
    final bool hasAdminBoardConfig =
        source.containsKey('boardVariant') ||
        source.containsKey('nameScale') ||
        source.containsKey('designationScale') ||
        source.containsKey('phoneScale') ||
        source.containsKey('showStyledNameStrip') ||
        source.containsKey('showStyledDesignationStrip');
    return CreatorPosterPersonalization(
      photoShape: _parsePhotoShape(source['photoShape']),
      photoX: _parseDouble(source['photoX'], 50),
      photoY: _parseDouble(source['photoY'], 45),
      photoScale: _parseDouble(source['photoScale'], 36),
      nameX: _parseDouble(source['nameX'], 50),
      nameY: _parseDouble(source['nameY'], 82),
      showBottomStrip: source['showBottomStrip'] is bool
          ? source['showBottomStrip'] as bool
          : !hasAdminBoardConfig,
      stripHeight: _parseDouble(source['stripHeight'], 16),
      showWhatsapp: source['showWhatsapp'] is bool
          ? source['showWhatsapp'] as bool
          : true,
      sampleName: (source['sampleName'] as String? ?? '').trim().isNotEmpty
          ? (source['sampleName'] as String).trim()
          : CreatorPosterPersonalization.defaults.sampleName,
      nameScale: _parseDouble(source['nameScale'], 100),
      showStyledNameStrip: source['showStyledNameStrip'] is bool
          ? source['showStyledNameStrip'] as bool
          : hasAdminBoardConfig,
      showStyledDesignationStrip: source['showStyledDesignationStrip'] is bool
          ? source['showStyledDesignationStrip'] as bool
          : hasAdminBoardConfig,
      sampleDesignation: (source['sampleDesignation'] as String? ?? '').trim(),
      designationScale: _parseDouble(
        source['designationScale'],
        CreatorPosterPersonalization.defaults.designationScale,
      ),
      phoneScale: _parseDouble(
        source['phoneScale'],
        CreatorPosterPersonalization.defaults.phoneScale,
      ),
      nameStripColor:
          (source['nameStripColor'] as String? ?? '').trim().isNotEmpty
          ? (source['nameStripColor'] as String).trim()
          : CreatorPosterPersonalization.defaults.nameStripColor,
      designationStripColor:
          (source['designationStripColor'] as String? ?? '').trim().isNotEmpty
          ? (source['designationStripColor'] as String).trim()
          : CreatorPosterPersonalization.defaults.designationStripColor,
      boardVariant: source['boardVariant'] is num
          ? (source['boardVariant'] as num).toInt()
          : CreatorPosterPersonalization.defaults.boardVariant,
      photoRenderMode: _parseRenderMode(source['photoRenderMode']),
      edgeStyle: _parseEdgeStyle(source['edgeStyle']),
      showSafeAreas: source['showSafeAreas'] is bool
          ? source['showSafeAreas'] as bool
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
      case 'scallop_circle':
      case 'soft_burst':
      case 'rounded_square':
      case 'vertical_rectangle':
      case 'rounded':
      case 'square':
      case 'hexagon':
      case 'pill':
      case 'oval':
      case 'flower':
      case 'diamond':
      case 'arch':
      case 'shield':
      case 'star':
      case 'blob':
      case 'badge':
      case 'heart':
      case 'sunburst':
      case 'transparent_bottom_fade':
      case 'transparent_clean':
      case 'transparent_soft_round':
      case 'transparent_sharp_round':
      case 'custom_screen_fit':
      case 'custom_board_fit':
      case 'custom_frame_fit':
      case 'custom_polygon_fit':
        return value;
      default:
        return CreatorPosterPersonalization.defaults.photoShape;
    }
  }

  bool _isTemplateDynamicCategoryVisible(
    String categoryId,
    Set<String> activeDynamicTags,
    Set<String> knownDynamicTags,
    DateTime now,
  ) {
    final normalized = _normalizeTag(categoryId);
    if (normalized.isEmpty || !knownDynamicTags.contains(normalized)) {
      return true;
    }
    final visibleUntil = _dynamicCategoryVisibleUntil(normalized, now);
    if (visibleUntil != null) {
      // schedule.endDate is midnight at the start of the last calendar day;
      // comparing full DateTime hid every poster after 00:00 on that day.
      final today = DateTime(now.year, now.month, now.day);
      final lastDay = DateTime(
        visibleUntil.year,
        visibleUntil.month,
        visibleUntil.day,
      );
      return !today.isAfter(lastDay);
    }
    return activeDynamicTags.contains(normalized);
  }

  DateTime? _dynamicCategoryVisibleUntil(
    String normalizedCategoryId,
    DateTime now,
  ) {
    final scheduleService = DynamicEventScheduleService(
      repository: _dynamicEventRepository,
    );
    final schedules = scheduleService.schedulesForYear(now.year);
    for (final schedule in schedules) {
      final event = schedule.event;
      final candidateTags = <String>{
        _normalizeTag(event.id),
        _normalizeTag(event.slug),
        ...event.tags.map(_normalizeTag),
        ..._dynamicTypeFilterTags(event.type).map(_normalizeTag),
      };
      if (candidateTags.contains(normalizedCategoryId)) {
        return schedule.endDate;
      }
    }
    return null;
  }

  Set<String> _activeDynamicTagsForDate(DateTime now) {
    final service = DynamicCategoryService(
      repository: _dynamicEventRepository,
      daysBeforeEvent: 0,
    );
    final output = <String>{};
    for (final category in service.categoriesForDate(now)) {
      output.add(_normalizeTag(category.id));
      output.add(_normalizeTag(category.slug));
      output.addAll(category.tags.map(_normalizeTag));
      output.addAll(_dynamicTypeFilterTags(category.type).map(_normalizeTag));
    }
    return output.where((item) => item.isNotEmpty).toSet();
  }

  Set<String> _knownDynamicTags() {
    final output = <String>{
      'festival',
      'jayanthi',
      'vardhanthi',
      'important_day',
      'regional_special',
      'weekday_special',
      'weekday_monday_special',
      'weekday_tuesday_special',
      'weekday_wednesday_special',
      'weekday_thursday_special',
      'weekday_friday_special',
      'weekday_saturday_special',
      'weekday_sunday_special',
    };
    for (final event in _dynamicEventRepository.loadEvents()) {
      output.add(_normalizeTag(event.id));
      output.add(_normalizeTag(event.slug));
      output.addAll(event.tags.map(_normalizeTag));
      output.addAll(_dynamicTypeFilterTags(event.type).map(_normalizeTag));
    }
    return output.where((item) => item.isNotEmpty).toSet();
  }

  Iterable<String> _dynamicTypeFilterTags(DynamicCategoryType type) {
    return switch (type) {
      DynamicCategoryType.festival => const <String>['festival'],
      DynamicCategoryType.jayanthi => const <String>[
        'jayanthi',
        'important_day',
        'regional_special',
      ],
      DynamicCategoryType.vardhanthi => const <String>[
        'vardhanthi',
        'important_day',
        'regional_special',
      ],
      DynamicCategoryType.importantDay => const <String>['important_day'],
      DynamicCategoryType.weekdaySpecial => const <String>['weekday_special'],
      DynamicCategoryType.regionalSpecial => const <String>[
        'regional_special',
        'important_day',
      ],
    };
  }

  String _normalizeTag(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
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
