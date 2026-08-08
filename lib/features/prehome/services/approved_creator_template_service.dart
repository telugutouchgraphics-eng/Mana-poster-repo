import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mana_poster/app/services/ist_time_service.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_repository.dart';

const bool _verboseApprovedTemplateLogs = false;
const Set<String> _teluguSharedContentRegionIds = <String>{
  'andhra_pradesh',
  'telangana',
};
const Set<String> _hindiSharedContentRegionIds = <String>{
  'bihar',
  'chhattisgarh',
  'haryana',
  'himachal_pradesh',
  'jharkhand',
  'madhya_pradesh',
  'rajasthan',
  'uttar_pradesh',
  'uttarakhand',
  'delhi',
  'andaman_nicobar',
};
const String _appCreatorPostersFeedEndpoint =
    'https://asia-south1-mana-poster-ap.cloudfunctions.net/appCreatorPostersFeed';

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
    debugPrint(message);
    debugPrint(stackTrace.toString());
  }

  void _debugLog(String message) {
    if (!_verboseApprovedTemplateLogs || (!kDebugMode && !kProfileMode)) {
      return;
    }
    debugPrint(message);
  }

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<String> _selectedRegionId() async {
    final region = await AppRegionService.loadSelection();
    final resolvedRegion =
        region ?? appRegionById(AppRegionService.fallbackRegionId);
    await AppRegionService.ensureRemoteSelectionSynced(resolvedRegion);
    final regionId = resolvedRegion?.id.trim() ?? '';
    return regionId.isNotEmpty ? regionId : AppRegionService.fallbackRegionId;
  }

  bool _isPoliticalCategory(String categoryId) {
    return _normalizeTag(categoryId).startsWith('party_');
  }

  List<String> _posterLookupRegionIds({
    required String selectedRegionId,
    required String categoryId,
  }) {
    final regionId = selectedRegionId.trim();
    if (regionId.isEmpty) {
      return const <String>[];
    }
    if (_isPoliticalCategory(categoryId)) {
      return regionId.isEmpty ? const <String>[] : <String>[regionId];
    }
    return _sharedContentRegionIdsFor(regionId).toList(growable: false);
  }

  Set<String> _sharedContentRegionIdsFor(String selectedRegionId) {
    final regionId = selectedRegionId.trim();
    if (_teluguSharedContentRegionIds.contains(regionId)) {
      return _teluguSharedContentRegionIds;
    }
    if (_hindiSharedContentRegionIds.contains(regionId)) {
      return _hindiSharedContentRegionIds;
    }
    return <String>{if (regionId.isNotEmpty) regionId};
  }

  List<String> _otherSharedContentRegionIds(String selectedRegionId) {
    final regionId = selectedRegionId.trim();
    return _sharedContentRegionIdsFor(
      regionId,
    ).where((item) => item != regionId).toList(growable: false);
  }

  Query<Map<String, dynamic>> _applyRegionScope(
    Query<Map<String, dynamic>> query,
    List<String> regionIds,
  ) {
    if (regionIds.length > 1) {
      return query.where('regionId', whereIn: regionIds);
    }
    return query.where('regionId', isEqualTo: regionIds.first);
  }

  bool _posterMatchesSelectedRegion(
    ApprovedCreatorTemplate template,
    String selectedRegionId,
  ) {
    final posterRegionId = template.regionId.trim();
    final selected = selectedRegionId.trim();
    if (posterRegionId.isEmpty || selected.isEmpty) {
      return false;
    }
    if (_isPoliticalCategory(template.categoryId)) {
      return posterRegionId == selected;
    }
    if (_sharedContentRegionIdsFor(selected).contains(posterRegionId)) {
      return true;
    }
    return posterRegionId == selected;
  }

  Future<List<ApprovedCreatorTemplate>> fetchApprovedTemplates({
    int maxItems = 40,
  }) async {
    final page = await fetchApprovedTemplatesPage(pageSize: maxItems);
    return page.templates;
  }

  Future<List<ApprovedCreatorTemplate>> fetchApprovedTemplatesWindow({
    int scanLimit = 80,
    Source source = Source.serverAndCache,
  }) async {
    final regionId = await _selectedRegionId();
    if (regionId.isEmpty || scanLimit <= 0) {
      return const <ApprovedCreatorTemplate>[];
    }
    try {
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final seenIds = <String>{};
      final snapshot = await firestore
          .collection('creatorPosters')
          .where('status', isEqualTo: 'approved')
          .where('regionId', isEqualTo: regionId)
          .orderBy('createdAt', descending: true)
          .limit(scanLimit)
          .get(GetOptions(source: source));
      for (final doc in snapshot.docs) {
        if (seenIds.add(doc.id)) {
          docs.add(doc);
        }
      }
      final siblingDocs = await _fetchOtherSharedNonPoliticalDocs(
        selectedRegionId: regionId,
        limit: scanLimit,
        source: source,
      );
      for (final doc in siblingDocs) {
        if (seenIds.add(doc.id)) {
          docs.add(doc);
        }
      }
      final mapped = _mapSortedTemplates(docs);
      final filtered = _filterPublished(mapped, docs, scanLimit, regionId);
      if (filtered.length >= scanLimit || source != Source.server) {
        return filtered.length <= scanLimit
            ? filtered
            : filtered.take(scanLimit).toList(growable: false);
      }
      final backendTemplates = await _fetchApprovedTemplatesFromBackend(
        regionId: regionId,
        categoryId: '',
        limit: scanLimit,
      );
      if (backendTemplates.isEmpty) {
        return filtered;
      }
      final merged = <ApprovedCreatorTemplate>[];
      final seenTemplateIds = <String>{};
      for (final template in <ApprovedCreatorTemplate>[
        ...filtered,
        ...backendTemplates,
      ]) {
        if (seenTemplateIds.add(template.id)) {
          merged.add(template);
        }
      }
      merged.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
      return merged.length <= scanLimit
          ? merged
          : merged.take(scanLimit).toList(growable: false);
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService.fetchApprovedTemplatesWindow failed: $error',
        stackTrace,
      );
      final backendTemplates = await _fetchApprovedTemplatesFromBackend(
        regionId: regionId,
        categoryId: '',
        limit: scanLimit,
      );
      return backendTemplates.length <= scanLimit
          ? backendTemplates
          : backendTemplates.take(scanLimit).toList(growable: false);
    }
  }

  Future<List<ApprovedCreatorTemplate>> fetchAllApprovedTemplatesForCategory({
    required String categoryId,
    Source source = Source.serverAndCache,
    int scanLimit = 800,
  }) async {
    final target = _normalizeTag(categoryId);
    final regionId = await _selectedRegionId();
    if (target.isEmpty || regionId.isEmpty) {
      return const <ApprovedCreatorTemplate>[];
    }
    try {
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final seenIds = <String>{};
      final directCandidates = _categoryQueryCandidates(categoryId);
      var queriedDocs = 0;
      var scannedDocs = 0;

      for (final candidate in directCandidates) {
        for (final lookupRegionId in _posterLookupRegionIds(
          selectedRegionId: regionId,
          categoryId: target,
        )) {
          try {
            final snapshot = await firestore
                .collection('creatorPosters')
                .where('status', isEqualTo: 'approved')
                .where('regionId', isEqualTo: lookupRegionId)
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
          } catch (error, stackTrace) {
            _debugLogStack(
              'ApprovedCreatorTemplateService category direct query failed: $error',
              stackTrace,
            );
          }
        }
      }

      final mapped = _mapSortedTemplates(docs);
      final filtered = _filterPublished(mapped, docs, scanLimit, regionId);
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
        regionId: regionId,
        limit: scanLimit,
        source: source,
      );
      final fallbackMapped = _mapSortedTemplates(fallbackDocs);
      final fallbackFiltered = _filterPublished(
        fallbackMapped,
        fallbackDocs,
        scanLimit,
        regionId,
      );
      _debugLog(
        '[PosterFetch] categoryDirect target=$target queriedDocs=$queriedDocs '
        'scannedDocs=$scannedDocs matchedDocs=${docs.length} '
        'filtered=${filtered.length} fallbackScan=${fallbackFiltered.length} '
        'source=$source',
      );
      if (fallbackFiltered.isEmpty && source == Source.server) {
        final backendTemplates = await _fetchApprovedTemplatesFromBackend(
          regionId: regionId,
          categoryId: target,
          limit: scanLimit,
        );
        if (backendTemplates.isNotEmpty) {
          return backendTemplates;
        }
      }
      return fallbackFiltered;
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService.fetchAllApprovedTemplatesForCategory failed: $error',
        stackTrace,
      );
      if (source == Source.server) {
        final backendTemplates = await _fetchApprovedTemplatesFromBackend(
          regionId: regionId,
          categoryId: target,
          limit: scanLimit,
        );
        if (backendTemplates.isNotEmpty) {
          return backendTemplates;
        }
      }
      final fallbackDocs = await _scanApprovedTemplatesForCategory(
        categoryId: target,
        regionId: regionId,
        limit: scanLimit,
        source: source,
      );
      final fallbackMapped = _mapSortedTemplates(fallbackDocs);
      return _filterPublished(
        fallbackMapped,
        fallbackDocs,
        scanLimit,
        regionId,
      );
    }
  }

  Future<bool> hasPublishedTemplatesForExactCategory({
    required String categoryId,
    Source source = Source.serverAndCache,
  }) async {
    final normalizedTarget = _normalizeTag(categoryId);
    final regionId = await _selectedRegionId();
    if (normalizedTarget.isEmpty || regionId.isEmpty) {
      return false;
    }
    try {
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final seenIds = <String>{};
      final directCandidates = _categoryQueryCandidates(categoryId);

      for (final candidate in directCandidates) {
        for (final lookupRegionId in _posterLookupRegionIds(
          selectedRegionId: regionId,
          categoryId: normalizedTarget,
        )) {
          final snapshot = await firestore
              .collection('creatorPosters')
              .where('status', isEqualTo: 'approved')
              .where('regionId', isEqualTo: lookupRegionId)
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
      }

      if (docs.isEmpty) {
        final fallbackDocs = await _scanApprovedTemplatesForCategory(
          categoryId: normalizedTarget,
          regionId: regionId,
          limit: 8,
          source: source,
        );
        if (fallbackDocs.isEmpty) {
          return _hasPublishedTemplatesFromBackend(
            categoryId: normalizedTarget,
            regionId: regionId,
          );
        }
        final fallbackMapped = _mapSortedTemplates(fallbackDocs);
        final fallbackFiltered = _filterPublished(
          fallbackMapped,
          fallbackDocs,
          8,
          regionId,
        );
        if (fallbackFiltered.isNotEmpty) {
          return true;
        }
        return _hasPublishedTemplatesFromBackend(
          categoryId: normalizedTarget,
          regionId: regionId,
        );
      }

      final mapped = _mapSortedTemplates(docs);
      final filtered = _filterPublished(mapped, docs, 8, regionId);
      if (filtered.isNotEmpty) {
        return true;
      }

      final fallbackDocs = await _scanApprovedTemplatesForCategory(
        categoryId: normalizedTarget,
        regionId: regionId,
        limit: 8,
        source: source,
      );
      if (fallbackDocs.isEmpty) {
        return _hasPublishedTemplatesFromBackend(
          categoryId: normalizedTarget,
          regionId: regionId,
        );
      }
      final fallbackMapped = _mapSortedTemplates(fallbackDocs);
      final fallbackFiltered = _filterPublished(
        fallbackMapped,
        fallbackDocs,
        8,
        regionId,
      );
      if (fallbackFiltered.isNotEmpty) {
        return true;
      }
      return _hasPublishedTemplatesFromBackend(
        categoryId: normalizedTarget,
        regionId: regionId,
      );
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService.hasPublishedTemplatesForExactCategory failed: $error',
        stackTrace,
      );
      return _hasPublishedTemplatesFromBackend(
        categoryId: normalizedTarget,
        regionId: regionId,
      );
    }
  }

  Future<bool> _hasPublishedTemplatesFromBackend({
    required String categoryId,
    required String regionId,
  }) async {
    final templates = await _fetchApprovedTemplatesFromBackend(
      regionId: regionId,
      categoryId: categoryId,
      limit: 8,
    );
    final normalizedTarget = _normalizeTag(categoryId);
    return templates.any(
      (template) => _normalizeTag(template.categoryId) == normalizedTarget,
    );
  }

  Future<ApprovedCreatorTemplatePage> fetchApprovedTemplatesPage({
    int pageSize = 5,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    Source source = Source.serverAndCache,
    bool allowFallbackMerge = true,
  }) async {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return const ApprovedCreatorTemplatePage(
        templates: <ApprovedCreatorTemplate>[],
        lastDocument: null,
        hasMore: false,
      );
    }
    try {
      final regionId = await _selectedRegionId();
      if (regionId.isEmpty) {
        return const ApprovedCreatorTemplatePage(
          templates: <ApprovedCreatorTemplate>[],
          lastDocument: null,
          hasMore: false,
        );
      }
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
            .where('regionId', isEqualTo: regionId)
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
          regionId,
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

      if (allowFallbackMerge && startAfterDocument == null) {
        final siblingDocs = await _fetchOtherSharedNonPoliticalDocs(
          selectedRegionId: regionId,
          limit: pageSize * 2,
          source: source,
        );
        if (siblingDocs.isNotEmpty) {
          final siblingVisible = _filterPublished(
            _mapSortedTemplates(siblingDocs),
            siblingDocs,
            pageSize * 2,
            regionId,
          );
          for (final template in siblingVisible) {
            if (seenTemplateIds.add(template.id)) {
              mergedVisible.add(template);
            }
          }
          mergedVisible.sort(
            (a, b) => b.createdAtMillis.compareTo(a.createdAtMillis),
          );
        }
      }

      var filteredTemplates = mergedVisible.length <= pageSize
          ? mergedVisible
          : mergedVisible.take(pageSize).toList(growable: false);
      if (filteredTemplates.length < pageSize &&
          startAfterDocument == null &&
          (source == Source.server || source == Source.serverAndCache)) {
        final backendTemplates = await _fetchApprovedTemplatesFromBackend(
          regionId: regionId,
          categoryId: '',
          limit: pageSize,
        );
        if (backendTemplates.isNotEmpty) {
          final byId = <String, ApprovedCreatorTemplate>{
            for (final template in filteredTemplates) template.id: template,
          };
          for (final template in backendTemplates) {
            byId.putIfAbsent(template.id, () => template);
          }
          filteredTemplates = byId.values.toList(growable: false)
            ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
          if (filteredTemplates.length > pageSize) {
            filteredTemplates = filteredTemplates
                .take(pageSize)
                .toList(growable: false);
          }
          return ApprovedCreatorTemplatePage(
            templates: filteredTemplates,
            lastDocument: lastDocument,
            hasMore: backendTemplates.length >= pageSize,
          );
        }
      }
      final fallbackMergeMs =
          totalStopwatch.elapsedMilliseconds - queryMs - mappingMs;
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
      if (source == Source.server || source == Source.serverAndCache) {
        try {
          final regionId = await _selectedRegionId();
          final backendTemplates = await _fetchApprovedTemplatesFromBackend(
            regionId: regionId,
            categoryId: '',
            limit: pageSize,
          );
          if (backendTemplates.isNotEmpty) {
            return ApprovedCreatorTemplatePage(
              templates: backendTemplates,
              lastDocument: null,
              hasMore: false,
            );
          }
        } catch (backendError, backendStackTrace) {
          _debugLogStack(
            'ApprovedCreatorTemplateService backend page fallback failed: $backendError',
            backendStackTrace,
          );
        }
      }
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
    if (_firestore == null && Firebase.apps.isEmpty) {
      return const ApprovedCreatorTemplatePage(
        templates: <ApprovedCreatorTemplate>[],
        lastDocument: null,
        hasMore: false,
      );
    }
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
  _fetchOtherSharedNonPoliticalDocs({
    required String selectedRegionId,
    required int limit,
    required Source source,
  }) async {
    final otherRegionIds = _otherSharedContentRegionIds(selectedRegionId);
    if (otherRegionIds.isEmpty || limit <= 0) {
      return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final seenIds = <String>{};
    const pageSize = 120;
    final scanCap = (limit * 8).clamp(pageSize * 2, 800);
    for (final regionId in otherRegionIds) {
      QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
      var scanned = 0;
      while (scanned < scanCap) {
        try {
          Query<Map<String, dynamic>> query = firestore
              .collection('creatorPosters')
              .where('status', isEqualTo: 'approved')
              .where('regionId', isEqualTo: regionId)
              .orderBy('createdAt', descending: true)
              .limit(pageSize);
          if (cursor != null) {
            query = query.startAfterDocument(cursor);
          }
          final snapshot = await query.get(GetOptions(source: source));
          if (snapshot.docs.isEmpty) {
            break;
          }
          cursor = snapshot.docs.last;
          scanned += snapshot.docs.length;
          for (final doc in snapshot.docs) {
            final categoryId = (doc.data()['categoryId'] as String?) ?? '';
            if (_isPoliticalCategory(categoryId)) {
              continue;
            }
            if (seenIds.add(doc.id)) {
              docs.add(doc);
            }
          }
          if (snapshot.docs.length < pageSize) {
            break;
          }
        } catch (error, stackTrace) {
          _debugLogStack(
            'ApprovedCreatorTemplateService shared non-political fetch failed: $error',
            stackTrace,
          );
          break;
        }
      }
    }
    docs.sort((left, right) {
      final leftCreatedAt = _toMillis(left.data()['createdAt']) ?? 0;
      final rightCreatedAt = _toMillis(right.data()['createdAt']) ?? 0;
      return rightCreatedAt.compareTo(leftCreatedAt);
    });
    return docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _scanApprovedTemplatesForCategory({
    required String categoryId,
    required String regionId,
    required int limit,
    required Source source,
  }) async {
    try {
      final matched = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final seenIds = <String>{};
      final lookupRegionIds = _posterLookupRegionIds(
        selectedRegionId: regionId,
        categoryId: categoryId,
      );
      QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
      const pageSize = 120;
      var scanned = 0;
      for (final lookupRegionId in lookupRegionIds) {
        cursor = null;
        while (matched.length < limit && scanned < limit * 4) {
          Query<Map<String, dynamic>> query = _applyRegionScope(
            firestore
                .collection('creatorPosters')
                .where('status', isEqualTo: 'approved'),
            <String>[lookupRegionId],
          ).orderBy('createdAt', descending: true).limit(pageSize);
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
            if (seenIds.add(doc.id) &&
                _docMatchesCategory(doc.data(), categoryId)) {
              matched.add(doc);
              if (matched.length >= limit) {
                break;
              }
            }
          }
        }
        if (matched.length >= limit || scanned >= limit * 4) {
          break;
        }
      }
      _debugLog(
        '[PosterFetch] categoryFallbackScan target=$categoryId '
        'matched=${matched.length} scanned=$scanned limit=$limit source=$source',
      );
      return matched;
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService category ordered fallback failed: $error',
        stackTrace,
      );
      try {
        final page = await _applyRegionScope(
          firestore.collection('creatorPosters'),
          _posterLookupRegionIds(
            selectedRegionId: regionId,
            categoryId: categoryId,
          ),
        ).limit((limit * 4).clamp(120, 800)).get(GetOptions(source: source));
        final matched = page.docs
            .where((doc) {
              final data = doc.data();
              return data['status'] == 'approved' &&
                  _docMatchesCategory(data, categoryId);
            })
            .toList(growable: false);
        matched.sort((left, right) {
          final leftCreatedAt = _toMillis(left.data()['createdAt']) ?? 0;
          final rightCreatedAt = _toMillis(right.data()['createdAt']) ?? 0;
          return rightCreatedAt.compareTo(leftCreatedAt);
        });
        _debugLog(
          '[PosterFetch] categoryRegionFallback target=$categoryId '
          'matched=${matched.length} scanned=${page.docs.length} source=$source',
        );
        return matched.length <= limit
            ? matched
            : matched.take(limit).toList(growable: false);
      } catch (fallbackError, fallbackStackTrace) {
        _debugLogStack(
          'ApprovedCreatorTemplateService category region fallback failed: $fallbackError',
          fallbackStackTrace,
        );
        return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      }
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

  Future<List<ApprovedCreatorTemplate>> _fetchApprovedTemplatesFromBackend({
    required String regionId,
    required String categoryId,
    required int limit,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_appCreatorPostersFeedEndpoint),
            headers: const <String, String>{'content-type': 'application/json'},
            body: jsonEncode(<String, Object?>{
              'regionId': regionId,
              'categoryId': categoryId,
              'limit': limit,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <ApprovedCreatorTemplate>[];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
        return const <ApprovedCreatorTemplate>[];
      }
      final rawPosters = decoded['posters'];
      if (rawPosters is! List) {
        return const <ApprovedCreatorTemplate>[];
      }
      return rawPosters
          .whereType<Map<String, dynamic>>()
          .map(_mapBackendPoster)
          .whereType<ApprovedCreatorTemplate>()
          .where(_isTemplateVisibleByLocalSchedule)
          .toList(growable: false);
    } catch (error, stackTrace) {
      _debugLogStack(
        'ApprovedCreatorTemplateService backend fallback failed: $error',
        stackTrace,
      );
      return const <ApprovedCreatorTemplate>[];
    }
  }

  ApprovedCreatorTemplate? _mapBackendPoster(Map<String, dynamic> data) {
    final id = (data['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }
    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    final imageStoragePath = (data['imagePath'] as String?)?.trim() ?? '';
    final thumbnailStoragePath =
        (data['thumbnailPath'] as String?)?.trim() ?? '';
    final thumbnailUrl = (data['thumbnailUrl'] as String?)?.trim() ?? '';
    final videoUrl = (data['videoUrl'] as String?)?.trim() ?? '';
    final mediaType = (data['mediaType'] as String?)?.trim() ?? '';
    final hasVideo = mediaType == 'video' && videoUrl.isNotEmpty;
    if (!hasVideo &&
        imageUrl.isEmpty &&
        imageStoragePath.isEmpty &&
        thumbnailStoragePath.isEmpty &&
        thumbnailUrl.isEmpty) {
      return null;
    }
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
      id: id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'Creator Poster',
      imageUrl: imageUrl,
      imageStoragePath: imageStoragePath,
      thumbnailStoragePath: thumbnailStoragePath,
      thumbnailUrl: thumbnailUrl,
      mediaType: hasVideo ? 'video' : 'image',
      videoUrl: videoUrl,
      categoryId: (data['categoryId'] as String?)?.trim() ?? '',
      categoryLabel: (data['categoryLabel'] as String?)?.trim() ?? '',
      regionId: (data['regionId'] as String?)?.trim() ?? '',
      createdAtMillis: (data['createdAt'] as num?)?.toInt() ?? 0,
      publishAtMillis: (data['publishAt'] as num?)?.toInt() ?? 0,
      personalizationConfig: _parsePersonalization(
        data['personalizationConfig'],
      ),
      creatorPublicId: (data['creatorPublicId'] as String?)?.trim() ?? '',
      pageConfig: pageConfig,
    );
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
      'good_evening': <String>['good_evening', 'evening'],
      'good_night': <String>['good_night', 'night'],
      'motivational': <String>['motivational'],
      'today_special': <String>['today_special'],
      'birthdays': <String>['birthdays', 'birthday'],
      'life_advice': <String>['life_advice'],
      'gita_wisdom': <String>['gita_wisdom'],
      'devotional': <String>['devotional'],
      'mahabharata': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'mahabharatam': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'mahabharatham': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'maha_bharatam': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'maha_bharatham': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'anniversary': <String>['anniversary'],
      'good_thoughts': <String>['good_thoughts'],
      'bible': <String>['bible'],
      'islam': <String>['islam'],
      'new': <String>['new'],
      'weekday_special': <String>['weekday_special'],
      'weekday_monday_special': <String>['weekday_monday_special'],
      'weekday_tuesday_special': <String>['weekday_tuesday_special'],
      'weekday_wednesday_special': <String>['weekday_wednesday_special'],
      'weekday_thursday_special': <String>['weekday_thursday_special'],
      'weekday_friday_special': <String>['weekday_friday_special'],
      'weekday_saturday_special': <String>['weekday_saturday_special'],
      'weekday_sunday_special': <String>['weekday_sunday_special'],
      'important_day': <String>['important_day'],
      'regional_special': <String>['regional_special'],
      'festival': <String>['festival'],
      'jayanthi': <String>['jayanthi'],
      'vardhanthi': <String>['vardhanthi'],
    };
    final output = <String>{normalized};
    final aliases = aliasMap[normalized];
    if (aliases != null) {
      output.addAll(aliases.map(_normalizeTag));
    }
    return output.where((item) => item.isNotEmpty).toSet();
  }

  List<String> _categoryQueryCandidates(String value) {
    final normalized = _normalizeTag(value);
    final candidates = <String>{
      value.trim(),
      normalized,
      ..._categoryAliases(normalized),
    };
    for (final alias in List<String>.of(candidates)) {
      final trimmed = alias.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      candidates.add(trimmed.replaceAll('_', '-'));
      candidates.add(trimmed.replaceAll('_', ' '));
    }
    return candidates
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
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

  bool _isTemplateVisibleByLocalSchedule(ApprovedCreatorTemplate template) {
    if (!_isGoodNightTemplate(template)) {
      return true;
    }
    final visibleFrom = _templateVisibleFromMillis(template);
    if (visibleFrom <= 0) {
      return true;
    }
    return _isAfterGoodNightCategoryRelease(
      nowMillis: IstTimeService.nowEpochMillis(),
      visibleFromMillis: visibleFrom,
    );
  }

  int _templateVisibleFromMillis(ApprovedCreatorTemplate template) {
    if (template.publishAtMillis > 0) {
      return template.publishAtMillis;
    }
    return template.createdAtMillis;
  }

  bool _isGoodNightTemplate(ApprovedCreatorTemplate template) {
    final signals = <String>{
      ..._categoryAliases(template.categoryId),
      ..._categoryAliases(template.categoryLabel),
      ..._categoryLabelTokenTags(template.categoryLabel),
    };
    return signals.contains('good_night') || signals.contains('night');
  }

  bool _isAfterGoodNightCategoryRelease({
    required int nowMillis,
    required int visibleFromMillis,
  }) {
    return nowMillis >= _goodNightCategoryReleaseMillis(visibleFromMillis);
  }

  int _goodNightCategoryReleaseMillis(int visibleFromMillis) {
    final visibleFromIst = IstTimeService.toIst(
      DateTime.fromMillisecondsSinceEpoch(visibleFromMillis),
    );
    return DateTime.utc(
      visibleFromIst.year,
      visibleFromIst.month,
      visibleFromIst.day + 1,
    ).subtract(IstTimeService.offset).millisecondsSinceEpoch;
  }

  List<ApprovedCreatorTemplate> _filterPublished(
    List<ApprovedCreatorTemplate> templates,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int maxItems,
    String selectedRegionId,
  ) {
    final now = IstTimeService.nowEpochMillis();
    final nowDate = IstTimeService.now();
    final activeDynamicTags = _activeDynamicTagsForDate(
      nowDate,
      selectedRegionId,
    );
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
      if (!_posterMatchesSelectedRegion(template, selectedRegionId)) {
        continue;
      }
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
      if (_isGoodNightTemplate(template) &&
          !_isAfterGoodNightCategoryRelease(
            nowMillis: now,
            visibleFromMillis: visibleFrom,
          )) {
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
    return _mapDocData(doc.id, doc.data());
  }

  ApprovedCreatorTemplate? _mapDocData(
    String docId,
    Map<String, dynamic> data,
  ) {
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
      id: docId,
      title: title,
      imageUrl: imageUrl,
      imageStoragePath: imageStoragePath,
      thumbnailStoragePath: thumbnailStoragePath,
      thumbnailUrl: thumbnailUrl,
      mediaType: hasVideo ? 'video' : 'image',
      videoUrl: videoUrl,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      regionId: (data['regionId'] as String?)?.trim() ?? '',
      createdAtMillis: createdAtMillis,
      publishAtMillis: _toMillis(data['publishAt']) ?? 0,
      personalizationConfig: _parsePersonalization(
        data['personalizationConfig'] ?? data['personalization'],
      ),
      creatorPublicId: (data['creatorPublicId'] as String? ?? '').trim(),
      pageConfig: pageConfig,
    );
  }

  Future<ApprovedCreatorTemplate?> fetchTemplateById(
    String posterId, {
    bool forceServer = false,
  }) async {
    final safePosterId = posterId.trim();
    if (safePosterId.isEmpty) {
      return null;
    }
    if (_firestore == null && Firebase.apps.isEmpty) {
      return null;
    }
    try {
      final firestore = _firestore ?? FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('creatorPosters')
          .doc(safePosterId)
          .get(GetOptions(source: Source.serverAndCache));
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return _mapDocData(snapshot.id, data);
    } catch (error, stackTrace) {
      _debugLogStack(
        'approved template fetch by id failed: $error',
        stackTrace,
      );
      return null;
    }
  }

  Future<void> incrementPosterEngagementCount({
    required String posterId,
    required bool isShare,
    String creatorPublicId = '',
    String posterTitle = '',
    String categoryId = '',
    String categoryLabel = '',
    String regionId = '',
  }) async {
    final safePosterId = posterId.trim();
    if (safePosterId.isEmpty) {
      return;
    }
    if (_firestore == null && Firebase.apps.isEmpty) {
      return;
    }
    try {
      final firestore = _firestore ?? FirebaseFirestore.instance;
      final now = DateTime.now().millisecondsSinceEpoch;
      final batch = firestore.batch();
      final posterRef = firestore
          .collection('creatorPosters')
          .doc(safePosterId);
      batch.update(posterRef, {
        isShare ? 'shareCount' : 'downloadCount': FieldValue.increment(1),
        'engagementCount': FieldValue.increment(1),
        'updatedAt': now,
      });
      final safeCreatorPublicId = creatorPublicId.trim();
      if (safeCreatorPublicId.isNotEmpty) {
        final dateKey = _istDayKey(now);
        final statsRef = firestore
            .collection('creatorPosterDailyStats')
            .doc('$safePosterId-$dateKey');
        batch.set(statsRef, {
          'creatorPublicId': safeCreatorPublicId,
          'posterId': safePosterId,
          'templateId': safePosterId,
          'posterTitle': posterTitle.trim().isNotEmpty
              ? posterTitle.trim()
              : 'Poster',
          'categoryId': categoryId.trim(),
          'categoryLabel': categoryLabel.trim(),
          'regionId': regionId.trim(),
          'dateKey': dateKey,
          'shareCount': FieldValue.increment(isShare ? 1 : 0),
          'downloadCount': FieldValue.increment(isShare ? 0 : 1),
          'totalEngagement': FieldValue.increment(1),
          'updatedAt': now,
          'createdAt': now,
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (error, stackTrace) {
      _debugLogStack('poster engagement update failed: $error', stackTrace);
      // Best-effort analytics only; sharing/downloading must never be blocked.
    }
  }

  String _istDayKey(int epochMillis) {
    final ist = IstTimeService.toIst(
      DateTime.fromMillisecondsSinceEpoch(epochMillis),
    );
    final month = ist.month.toString().padLeft(2, '0');
    final day = ist.day.toString().padLeft(2, '0');
    return '${ist.year}-$month-$day';
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
      photoAnimation: _parseVideoPhotoAnimation(source['photoAnimation']),
      showVideoExtraPhoto: source['showVideoExtraPhoto'] as bool? ?? false,
      videoExtraPhotoShape: _parsePhotoShape(source['videoExtraPhotoShape']),
      videoExtraPhotoRenderMode: _parseRenderMode(
        source['videoExtraPhotoRenderMode'],
      ),
      videoExtraPhotoEdgeStyle: _parseEdgeStyle(
        source['videoExtraPhotoEdgeStyle'],
      ),
      videoExtraPhotoAnimation: _parseVideoPhotoAnimation(
        source['videoExtraPhotoAnimation'],
      ),
      videoExtraPhotoX: _parseDouble(source['videoExtraPhotoX'], 24),
      videoExtraPhotoY: _parseDouble(source['videoExtraPhotoY'], 44),
      videoExtraPhotoScale: _parseDouble(source['videoExtraPhotoScale'], 28),
      nameX: _parseDouble(source['nameX'], 50),
      nameY: _parseDouble(source['nameY'], 82),
      showBottomStrip: source['showBottomStrip'] is bool
          ? source['showBottomStrip'] as bool
          : !hasAdminBoardConfig,
      stripHeight: _parseDouble(source['stripHeight'], 16),
      stripWidth: _parseDouble(source['stripWidth'], 100),
      stripX: _parseDouble(source['stripX'], 50),
      stripBottom: _parseDouble(source['stripBottom'], 0),
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
      stripLayoutStyle: _parseStripLayoutStyle(source['stripLayoutStyle']),
      boardVariant: source['boardVariant'] is num
          ? (source['boardVariant'] as num).toInt()
          : CreatorPosterPersonalization.defaults.boardVariant,
      photoRenderMode: _parseRenderMode(source['photoRenderMode']),
      edgeStyle: _parseEdgeStyle(source['edgeStyle']),
      showSafeAreas: source['showSafeAreas'] is bool
          ? source['showSafeAreas'] as bool
          : true,
      showPoliticalProtocol: source['showPoliticalProtocol'] is bool
          ? source['showPoliticalProtocol'] as bool
          : false,
      politicalProtocolEnabledAtMillis:
          (source['politicalProtocolEnabledAtMillis'] as num?)?.toInt() ?? 0,
      politicalProtocolX: _parseDouble(source['politicalProtocolX'], 50),
      politicalProtocolY: _parseDouble(source['politicalProtocolY'], 7),
      politicalProtocolScale: _parseDouble(
        source['politicalProtocolScale'],
        100,
      ),
      politicalProtocolSlots: _parsePoliticalProtocolSlots(
        source['politicalProtocolSlots'],
        fallbackX: _parseDouble(source['politicalProtocolX'], 50),
        fallbackY: _parseDouble(source['politicalProtocolY'], 7),
        fallbackScale: _parseDouble(source['politicalProtocolScale'], 85),
      ),
    );
  }

  String _parseStripLayoutStyle(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    switch (value) {
      case 'split':
      case 'badge':
      case 'full':
        return value;
      default:
        return CreatorPosterPersonalization.defaults.stripLayoutStyle;
    }
  }

  List<PoliticalProtocolSlot> _parsePoliticalProtocolSlots(
    Object? raw, {
    required double fallbackX,
    required double fallbackY,
    required double fallbackScale,
  }) {
    if (raw is List) {
      final slots = raw
          .whereType<Map>()
          .map(
            (slot) => PoliticalProtocolSlot(
              x: _parseDouble(slot['x'], 50).clamp(4.0, 96.0).toDouble(),
              y: _parseDouble(slot['y'], 8).clamp(4.0, 96.0).toDouble(),
              scale: _parseDouble(
                slot['scale'],
                100,
              ).clamp(45.0, 135.0).toDouble(),
            ),
          )
          .take(defaultPoliticalProtocolSlots.length)
          .toList(growable: false);
      if (slots.length == defaultPoliticalProtocolSlots.length) {
        return slots;
      }
    }
    final spacing = 44.0 * (fallbackScale.clamp(55.0, 135.0) / 100);
    return List<PoliticalProtocolSlot>.generate(
      defaultPoliticalProtocolSlots.length,
      (index) {
        final x =
            fallbackX +
            ((index - ((defaultPoliticalProtocolSlots.length - 1) / 2)) *
                spacing);
        return PoliticalProtocolSlot(
          x: x.clamp(4.0, 96.0).toDouble(),
          y: fallbackY.clamp(4.0, 96.0).toDouble(),
          scale: fallbackScale.clamp(45.0, 135.0).toDouble(),
        );
      },
      growable: false,
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

  String _parseVideoPhotoAnimation(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    switch (value) {
      case 'top_to_place':
      case 'bottom_to_place':
      case 'left_to_place':
      case 'right_to_place':
      case 'zoom_in':
      case 'zoom_out':
        return value;
      default:
        return 'none';
    }
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

  Set<String> _activeDynamicTagsForDate(DateTime now, String selectedRegionId) {
    final service = DynamicCategoryService(
      repository: _dynamicEventRepository,
      daysBeforeEvent: 3,
    );
    final output = <String>{};
    for (final category in service.categoriesForDate(
      now,
      selectedRegionId: selectedRegionId,
    )) {
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
      DynamicCategoryType.birthday => const <String>['birthday', 'birthdays'],
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
