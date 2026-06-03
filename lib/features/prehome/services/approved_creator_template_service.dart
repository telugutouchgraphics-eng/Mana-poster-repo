import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/app/services/ist_time_service.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_repository.dart';

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
    if (!kDebugMode && !kProfileMode) {
      return;
    }
    // ignore: avoid_print
    print(message);
    // ignore: avoid_print
    print(stackTrace);
  }

  void _debugLog(String message) {
    if (!kDebugMode && !kProfileMode) {
      return;
    }
    // ignore: avoid_print
    print(message);
  }

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<List<ApprovedCreatorTemplate>> fetchApprovedTemplates({
    int maxItems = 40,
  }) async {
    final page = await fetchApprovedTemplatesPage(pageSize: maxItems);
    return page.templates;
  }

  Future<List<ApprovedCreatorTemplate>> fetchAllApprovedTemplatesForCategory({
    required String categoryId,
    Source source = Source.serverAndCache,
    int scanLimit = 800,
  }) async {
    final target = _normalizeTag(categoryId);
    if (target.isEmpty) {
      return const <ApprovedCreatorTemplate>[];
    }
    try {
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final seenIds = <String>{};
      final directCandidates = <String>{
        categoryId.trim(),
        target,
      }.where((value) => value.isNotEmpty).toList(growable: false);
      var queriedDocs = 0;
      var scannedDocs = 0;

      for (final candidate in directCandidates) {
        final snapshot = await firestore
            .collection('creatorPosters')
            .where('status', isEqualTo: 'approved')
            .where('categoryId', isEqualTo: candidate)
            .orderBy('createdAt', descending: true)
            .limit(scanLimit)
            .get(GetOptions(source: source));
        queriedDocs += snapshot.docs.length;
        scannedDocs += snapshot.docs.length;
        for (final doc in snapshot.docs) {
          if (seenIds.add(doc.id)) {
            docs.add(doc);
          }
        }
      }

      final mapped = _mapSortedTemplates(docs);
      final filtered = _filterPublished(mapped, docs, scanLimit);
      if (filtered.isNotEmpty) {
        _debugLog(
          '[PosterFetch] categoryDirect target=$target queriedDocs=$queriedDocs '
          'scannedDocs=$scannedDocs matchedDocs=${docs.length} '
          'filtered=${filtered.length} fallbackScan=skipped source=$source',
        );
        return filtered;
      }

      final fallbackDocs = await _scanApprovedTemplatesForCategory(
        categoryId: target,
        limit: scanLimit,
        source: source,
      );
      final fallbackMapped = _mapSortedTemplates(fallbackDocs);
      final fallbackFiltered = _filterPublished(
        fallbackMapped,
        fallbackDocs,
        scanLimit,
      );
      _debugLog(
        '[PosterFetch] categoryDirect target=$target queriedDocs=$queriedDocs '
        'scannedDocs=$scannedDocs matchedDocs=${docs.length} '
        'filtered=${filtered.length} fallbackScan=${fallbackFiltered.length} '
        'source=$source',
      );
      return fallbackFiltered;
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService.fetchAllApprovedTemplatesForCategory failed: $error',
        stackTrace,
      );
      return const <ApprovedCreatorTemplate>[];
    }
  }

  Future<bool> hasPublishedTemplatesForExactCategory({
    required String categoryId,
    Source source = Source.serverAndCache,
  }) async {
    final normalizedTarget = _normalizeTag(categoryId);
    if (normalizedTarget.isEmpty) {
      return false;
    }
    try {
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final seenIds = <String>{};
      final directCandidates = <String>{
        categoryId.trim(),
        normalizedTarget,
      }.where((value) => value.isNotEmpty).toList(growable: false);

      for (final candidate in directCandidates) {
        final snapshot = await firestore
            .collection('creatorPosters')
            .where('status', isEqualTo: 'approved')
            .where('categoryId', isEqualTo: candidate)
            .orderBy('createdAt', descending: true)
            .limit(8)
            .get(GetOptions(source: source));
        for (final doc in snapshot.docs) {
          if (seenIds.add(doc.id)) {
            docs.add(doc);
          }
        }
      }

      if (docs.isEmpty) {
        final fallbackDocs = await _scanApprovedTemplatesForCategory(
          categoryId: normalizedTarget,
          limit: 8,
          source: source,
        );
        if (fallbackDocs.isEmpty) {
          return false;
        }
        final fallbackMapped = _mapSortedTemplates(fallbackDocs);
        final fallbackFiltered = _filterPublished(
          fallbackMapped,
          fallbackDocs,
          8,
        );
        return fallbackFiltered.isNotEmpty;
      }

      final mapped = _mapSortedTemplates(docs);
      final filtered = _filterPublished(mapped, docs, 8);
      if (filtered.isNotEmpty) {
        return true;
      }

      final fallbackDocs = await _scanApprovedTemplatesForCategory(
        categoryId: normalizedTarget,
        limit: 8,
        source: source,
      );
      if (fallbackDocs.isEmpty) {
        return false;
      }
      final fallbackMapped = _mapSortedTemplates(fallbackDocs);
      final fallbackFiltered = _filterPublished(
        fallbackMapped,
        fallbackDocs,
        8,
      );
      return fallbackFiltered.isNotEmpty;
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService.hasPublishedTemplatesForExactCategory failed: $error',
        stackTrace,
      );
      return false;
    }
  }

  Future<ApprovedCreatorTemplatePage> fetchApprovedTemplatesPage({
    int pageSize = 5,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    Source source = Source.serverAndCache,
    bool allowFallbackMerge = true,
  }) async {
    try {
      final totalStopwatch = Stopwatch()..start();
      final queryLimit = (pageSize * 2).clamp(pageSize, pageSize * 3);
      final maxQueryPages = source == Source.cache
          ? 1
          : startAfterDocument == null
          ? (allowFallbackMerge ? 3 : 1)
          : 2;
      final mergedVisible = <ApprovedCreatorTemplate>[];
      final seenTemplateIds = <String>{};
      QueryDocumentSnapshot<Map<String, dynamic>>? cursor = startAfterDocument;
      QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument =
          startAfterDocument;
      var queryMs = 0;
      var mappingMs = 0;
      var scannedDocs = 0;
      var queriedPages = 0;
      var lastPageDocCount = 0;
      var hasExhaustedQuery = false;

      while (queriedPages < maxQueryPages && mergedVisible.length < pageSize) {
        final queryStopwatch = Stopwatch()..start();
        Query<Map<String, dynamic>> query = firestore
            .collection('creatorPosters')
            .where('status', isEqualTo: 'approved')
            .orderBy('createdAt', descending: true)
            .limit(queryLimit);
        if (cursor != null) {
          query = query.startAfterDocument(cursor);
        }
        final snapshot = await query.get(GetOptions(source: source));
        queryMs += queryStopwatch.elapsedMilliseconds;
        queriedPages++;
        lastPageDocCount = snapshot.docs.length;
        if (snapshot.docs.isEmpty) {
          hasExhaustedQuery = true;
          break;
        }
        cursor = snapshot.docs.last;
        lastDocument = cursor;
        scannedDocs += snapshot.docs.length;
        _debugLog(
          '[PosterFetch] primary query docs=${snapshot.docs.length} '
          'pageSize=$pageSize queryLimit=$queryLimit '
          'startAfter=${queriedPages == 1 ? startAfterDocument?.id ?? 'null' : lastDocument.id} '
          'source=$source page=$queriedPages/$maxQueryPages',
        );

        final mappingStopwatch = Stopwatch()..start();
        final batchVisible = _filterPublished(
          _mapSortedTemplates(snapshot.docs),
          snapshot.docs,
          queryLimit,
        );
        mappingMs += mappingStopwatch.elapsedMilliseconds;
        for (final template in batchVisible) {
          if (seenTemplateIds.add(template.id)) {
            mergedVisible.add(template);
            if (mergedVisible.length >= pageSize) {
              break;
            }
          }
        }
        if (snapshot.docs.length < queryLimit) {
          hasExhaustedQuery = true;
          break;
        }
      }

      final filteredTemplates = mergedVisible.length <= pageSize
          ? mergedVisible
          : mergedVisible.take(pageSize).toList(growable: false);
      final fallbackMergeMs = totalStopwatch.elapsedMilliseconds - queryMs - mappingMs;
      _debugLog(
        '[PosterFetch] final mergedDocs=$scannedDocs '
        'filteredTemplates=${filteredTemplates.length} '
        'pageTarget=$pageSize pageCapDropped=0 '
        'cacheQueryMs=$queryMs mappingMs=$mappingMs '
        'queryPages=$queriedPages exhausted=$hasExhaustedQuery '
        'fallbackMergeMs=$fallbackMergeMs totalMs=${totalStopwatch.elapsedMilliseconds}',
      );

      return ApprovedCreatorTemplatePage(
        templates: filteredTemplates,
        lastDocument: lastDocument,
        hasMore: !hasExhaustedQuery && lastPageDocCount >= queryLimit,
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _scanApprovedTemplatesForCategory({
    required String categoryId,
    required int limit,
    required Source source,
  }) async {
    try {
      final matched = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
      const pageSize = 120;
      var scanned = 0;
      while (matched.length < limit && scanned < limit * 4) {
        Query<Map<String, dynamic>> query = firestore
            .collection('creatorPosters')
            .where('status', isEqualTo: 'approved')
            .orderBy(FieldPath.documentId)
            .limit(pageSize);
        if (cursor != null) {
          query = query.startAfterDocument(cursor);
        }
        final page = await query.get(GetOptions(source: source));
        if (page.docs.isEmpty) {
          break;
        }
        cursor = page.docs.last;
        scanned += page.docs.length;
        for (final doc in page.docs) {
          if (_docMatchesCategory(doc.data(), categoryId)) {
            matched.add(doc);
            if (matched.length >= limit) {
              break;
            }
          }
        }
      }
      _debugLog(
        '[PosterFetch] categoryFallbackScan target=$categoryId '
        'matched=${matched.length} scanned=$scanned limit=$limit source=$source',
      );
      return matched;
    } catch (_) {
      return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }
  }

  List<ApprovedCreatorTemplate> _mapSortedTemplates(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final templates = docs
        .map(_mapDoc)
        .whereType<ApprovedCreatorTemplate>()
        .toList(growable: false);
    templates.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return templates;
  }

  bool _docMatchesCategory(Map<String, dynamic> data, String categoryId) {
    final targetAliases = _categoryAliases(categoryId);
    if (targetAliases.isEmpty) {
      return false;
    }
    final docCategoryId = (data['categoryId'] as String?)?.trim() ?? '';
    if (_categoryAliases(
      docCategoryId,
    ).intersection(targetAliases).isNotEmpty) {
      return true;
    }
    final docCategoryLabel = (data['categoryLabel'] as String?)?.trim() ?? '';
    final labelTokens = <String>{
      ..._categoryAliases(docCategoryLabel),
      ..._categoryLabelTokenTags(docCategoryLabel),
    };
    if (labelTokens.intersection(targetAliases).isNotEmpty) {
      return true;
    }
    return false;
  }

  Set<String> _categoryAliases(String value) {
    final normalized = _normalizeTag(value);
    if (normalized.isEmpty) {
      return const <String>{};
    }
    const aliasMap = <String, List<String>>{
      'all': <String>['all'],
      'good_morning': <String>['good_morning', 'morning'],
      'good_afternoon': <String>['good_afternoon', 'afternoon'],
      'good_night': <String>['good_night', 'night'],
      'motivational': <String>['motivational'],
      'love_quotes': <String>['love_quotes', 'love'],
      'today_special': <String>['today_special', 'important_day'],
      'birthdays': <String>['birthdays', 'birthday', 'celebration'],
      'life_advice': <String>['life_advice'],
      'gita_wisdom': <String>['gita_wisdom'],
      'devotional': <String>['devotional'],
      'mahabharata': <String>['mahabharata'],
      'anniversary': <String>['anniversary', 'celebration'],
      'good_thoughts': <String>['good_thoughts'],
      'bible': <String>['bible'],
      'islam': <String>['islam'],
      'new': <String>['new', 'today_special'],
      'weekday_special': <String>['weekday_special', 'today_special'],
      'weekday_monday_special': <String>[
        'weekday_monday_special',
        'weekday_special',
        'today_special',
      ],
      'weekday_tuesday_special': <String>[
        'weekday_tuesday_special',
        'weekday_special',
        'today_special',
      ],
      'weekday_wednesday_special': <String>[
        'weekday_wednesday_special',
        'weekday_special',
        'today_special',
      ],
      'weekday_thursday_special': <String>[
        'weekday_thursday_special',
        'weekday_special',
        'today_special',
      ],
      'weekday_friday_special': <String>[
        'weekday_friday_special',
        'weekday_special',
        'today_special',
      ],
      'weekday_saturday_special': <String>[
        'weekday_saturday_special',
        'weekday_special',
        'today_special',
      ],
      'weekday_sunday_special': <String>[
        'weekday_sunday_special',
        'weekday_special',
        'today_special',
      ],
      'important_day': <String>['important_day', 'today_special'],
      'regional_special': <String>['regional_special', 'today_special'],
      'festival': <String>['festival', 'devotional', 'today_special'],
      'jayanthi': <String>['jayanthi', 'important_day', 'regional_special'],
      'vardhanthi': <String>['vardhanthi', 'important_day', 'regional_special'],
    };
    final output = <String>{normalized};
    final aliases = aliasMap[normalized];
    if (aliases != null) {
      output.addAll(aliases.map(_normalizeTag));
    }
    return output.where((item) => item.isNotEmpty).toSet();
  }

  Set<String> _categoryLabelTokenTags(String value) {
    if (value.trim().isEmpty) {
      return const <String>{};
    }
    final output = <String>{};
    final normalized = _normalizeTag(value);
    if (normalized.isNotEmpty) {
      output.add(normalized);
    }
    for (final word in value.toLowerCase().split(RegExp(r'\s+'))) {
      final token = _normalizeTag(word);
      if (token.length > 2) {
        output.add(token);
      }
    }
    return output;
  }

  List<ApprovedCreatorTemplate> _filterPublished(
    List<ApprovedCreatorTemplate> templates,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int maxItems,
  ) {
    final now = IstTimeService.nowEpochMillis();
    final nowDate = IstTimeService.now();
    final activeDynamicTags = _activeDynamicTagsForDate(nowDate);
    final knownDynamicTags = _knownDynamicTags();
    final publishMap = <String, int>{};
    final eventEndMap = <String, int>{};
    for (final doc in docs) {
      final data = doc.data();
      final rawPublish = data['publishAt'];
      publishMap[doc.id] = _toMillis(rawPublish) ?? 0;
      eventEndMap[doc.id] = _toMillis(data['eventEndAt']) ?? 0;
    }
    final filtered = <ApprovedCreatorTemplate>[];
    final collectDebugCounts = kDebugMode;
    final totalByCategory = collectDebugCounts ? <String, int>{} : null;
    final publishHiddenByCategory = collectDebugCounts ? <String, int>{} : null;
    final eventEndedByCategory = collectDebugCounts ? <String, int>{} : null;
    final retentionHiddenByCategory = collectDebugCounts
        ? <String, int>{}
        : null;
    final dynamicHiddenByCategory = collectDebugCounts ? <String, int>{} : null;
    for (final template in templates) {
      final category = _normalizeTag(template.categoryId);
      if (collectDebugCounts) {
        totalByCategory![category] = (totalByCategory[category] ?? 0) + 1;
      }
      final publishAt = publishMap[template.id] ?? 0;
      final eventEndAt = eventEndMap[template.id] ?? 0;
      var visibleFrom = publishAt > 0 ? publishAt : template.createdAtMillis;
      if (visibleFrom <= 0) {
        visibleFrom = now;
      }
      if (visibleFrom > now) {
        if (collectDebugCounts) {
          publishHiddenByCategory![category] =
              (publishHiddenByCategory[category] ?? 0) + 1;
        }
        continue;
      }
      if (eventEndAt > 0 && now > eventEndAt) {
        if (collectDebugCounts) {
          eventEndedByCategory![category] =
              (eventEndedByCategory[category] ?? 0) + 1;
        }
        continue;
      }
      final usesRollingRetention =
          category.isNotEmpty && knownDynamicTags.contains(category);
      final retentionMs = usesRollingRetention
          ? _posterRetentionWindowMillis
          : 365 * 24 * 60 * 60 * 1000;
      if (eventEndAt <= 0 && visibleFrom + retentionMs <= now) {
        if (collectDebugCounts) {
          retentionHiddenByCategory![category] =
              (retentionHiddenByCategory[category] ?? 0) + 1;
        }
        continue;
      }
      final dynamicVisible = _isTemplateDynamicCategoryVisible(
        template.categoryId,
        activeDynamicTags,
        knownDynamicTags,
        nowDate,
      );
      if (!dynamicVisible) {
        if (collectDebugCounts) {
          dynamicHiddenByCategory![category] =
              (dynamicHiddenByCategory[category] ?? 0) + 1;
        }
        continue;
      }
      filtered.add(template);
    }
    if (kDebugMode) {
      final filteredByCategory = <String, int>{};
      for (final item in filtered) {
        final key = _normalizeTag(item.categoryId);
        filteredByCategory[key] = (filteredByCategory[key] ?? 0) + 1;
      }
      final pageCapDropped = filtered.length > maxItems
          ? filtered.length - maxItems
          : 0;
      _debugLog(
        '[PosterFetch] counts total=${templates.length} filtered=${filtered.length} '
        'totalByCategory=$totalByCategory filteredByCategory=$filteredByCategory '
        'publishHidden=$publishHiddenByCategory eventEnded=$eventEndedByCategory '
        'retentionHidden=$retentionHiddenByCategory dynamicHidden=$dynamicHiddenByCategory '
        'pageTarget=$maxItems pageCapDropped=$pageCapDropped',
      );
    }
    filtered.sort((a, b) {
      final publishA = publishMap[a.id] ?? 0;
      final publishB = publishMap[b.id] ?? 0;
      var left = publishA > 0 ? publishA : a.createdAtMillis;
      var right = publishB > 0 ? publishB : b.createdAtMillis;
      if (left <= 0) {
        left = now;
      }
      if (right <= 0) {
        right = now;
      }
      return right.compareTo(left);
    });
    if (filtered.length <= maxItems) {
      return filtered;
    }
    // Respect requested page size to avoid large UI list jumps during startup
    // and pagination; callers rely on deterministic page-sized batches.
    return filtered.take(maxItems).toList(growable: false);
  }

  String _firstNonEmptyTrimmed(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }
    return '';
  }

  String? _firstTrimmedUrlField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }
    return null;
  }

  int _effectiveCreationMillis(Map<String, dynamic> data) {
    return _toMillis(data['createdAt']) ??
        _toMillis(data['created_at']) ??
        _toMillis(data['updatedAt']) ??
        _toMillis(data['updated_at']) ??
        _toMillis(data['postedAt']) ??
        _toMillis(data['posted_at']) ??
        _toMillis(data['publishedAt']) ??
        _toMillis(data['uploadedAt']) ??
        _toMillis(data['uploadTimestamp']) ??
        0;
  }

  ApprovedCreatorTemplate? _mapDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final bool mutedByActiveFlag =
        data['active'] is bool && !(data['active'] as bool);
    if (mutedByActiveFlag) {
      return null;
    }

    final mediaType = (data['mediaType'] as String? ?? 'image')
        .trim()
        .toLowerCase();
    final imageUrl =
        (_firstTrimmedUrlField(data, const <String>[
                  'imageUrl',
                  'imageURL',
                  'posterUrl',
                  'previewUrl',
                  'posterImageUrl',
                  'posterImageURL',
                  'downloadUrl',
                  'downloadURL',
                  'publicUrl',
                  'url',
                  'firebaseUrl',
                ]) ??
                '')
            .trim();
    final imageStoragePath = _firstNonEmptyTrimmed(data, const <String>[
      'imagePath',
      'imageStoragePath',
      'posterImagePath',
      'posterStoragePath',
      'storagePath',
      'posterStorageRef',
      'firebaseStoragePath',
    ]);
    final thumbnailStoragePath = _firstNonEmptyTrimmed(data, const <String>[
      'thumbnailPath',
      'thumbnailStoragePath',
      'posterThumbnailPath',
      'thumbPath',
      'thumbnailRef',
    ]);
    final thumbnailUrl =
        (_firstTrimmedUrlField(data, const <String>[
                  'thumbnailUrl',
                  'thumbUrl',
                  'thumbnailImageUrl',
                  'previewUrl',
                ]) ??
                imageUrl)
            .trim();
    final thumbnailUrlResolved = thumbnailUrl;
    final videoUrl =
        (data['videoUrl'] as String?)?.trim() ??
        (data['videoPreviewUrl'] as String?)?.trim() ??
        '';
    final hasVideo = mediaType == 'video' && videoUrl.isNotEmpty;
    final hasImageByUrl = imageUrl.isNotEmpty;
    final hasImage =
        hasImageByUrl ||
        thumbnailUrlResolved.isNotEmpty ||
        imageStoragePath.isNotEmpty ||
        thumbnailStoragePath.isNotEmpty;
    if (!hasVideo && !hasImage) {
      return null;
    }

    final title = (data['title'] as String?)?.trim().isNotEmpty == true
        ? (data['title'] as String).trim()
        : 'Creator Poster';
    final categoryId = (data['categoryId'] as String?)?.trim() ?? '';
    final categoryLabel = (data['categoryLabel'] as String?)?.trim() ?? '';
    final createdAtMillis = _effectiveCreationMillis(data);
    final widthPx = (data['widthPx'] as num?)?.toInt();
    final heightPx = (data['heightPx'] as num?)?.toInt();
    final pageConfig =
        widthPx != null && heightPx != null && widthPx > 0 && heightPx > 0
        ? EditorPageConfig(
            name: '${widthPx}x$heightPx',
            widthPx: widthPx,
            heightPx: heightPx,
          )
        : null;

    return ApprovedCreatorTemplate(
      id: doc.id,
      title: title,
      imageUrl: imageUrl,
      imageStoragePath: imageStoragePath,
      thumbnailStoragePath: thumbnailStoragePath,
      thumbnailUrl: thumbnailUrl,
      mediaType: hasVideo ? 'video' : 'image',
      videoUrl: videoUrl,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      createdAtMillis: createdAtMillis,
      personalizationConfig: _parsePersonalization(
        data['personalizationConfig'] ?? data['personalization'],
      ),
      creatorPublicId: (data['creatorPublicId'] as String? ?? '').trim(),
      pageConfig: pageConfig,
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
    return activeDynamicTags.contains(normalized);
  }

  Set<String> _activeDynamicTagsForDate(DateTime now) {
    final service = DynamicCategoryService(
      repository: _dynamicEventRepository,
      daysBeforeEvent: 3,
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
