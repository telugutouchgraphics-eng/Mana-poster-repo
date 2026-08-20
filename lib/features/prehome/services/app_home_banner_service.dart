import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/features/prehome/models/app_home_banner.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/services/app_location_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';

class AppHomeBannerService {
  const AppHomeBannerService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  void _debugLogStack(String message, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
    debugPrintStack(stackTrace: stackTrace);
  }

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<List<AppHomeBanner>> fetchBanners({
    int maxItems = 8,
    String placement = 'home_category_banner',
  }) async {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return const <AppHomeBanner>[];
    }
    final queryLimit = maxItems * 20;
    try {
      final snapshot = await firestore
          .collection('appBanners')
          .where('active', isEqualTo: true)
          .orderBy('sortOrder')
          .limit(queryLimit)
          .get(const GetOptions(source: Source.server));
      return _filterForSelectedUser(
        _mapSnapshot(snapshot, placement: placement),
        maxItems,
      );
    } catch (error, stackTrace) {
      _debugLogStack(
        'AppHomeBannerService.fetchBanners failed: $error',
        stackTrace,
      );
      try {
        final fallbackSnapshot = await firestore
            .collection('appBanners')
            .where('active', isEqualTo: true)
            .orderBy('sortOrder')
            .limit(queryLimit)
            .get();
        return _filterForSelectedRegion(
          _mapSnapshot(fallbackSnapshot, placement: placement),
          maxItems,
        );
      } catch (_) {
        return const <AppHomeBanner>[];
      }
    }
  }

  Future<List<AppHomeBanner>> fetchBannersFromCache({
    int maxItems = 8,
    String placement = 'home_category_banner',
  }) async {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return const <AppHomeBanner>[];
    }
    final queryLimit = maxItems * 20;
    try {
      final snapshot = await firestore
          .collection('appBanners')
          .where('active', isEqualTo: true)
          .orderBy('sortOrder')
          .limit(queryLimit)
          .get(const GetOptions(source: Source.cache));
      return _filterForSelectedUser(
        _mapSnapshot(snapshot, placement: placement),
        maxItems,
      );
    } catch (error, stackTrace) {
      _debugLogStack(
        'AppHomeBannerService.fetchBannersFromCache failed: $error',
        stackTrace,
      );
      return const <AppHomeBanner>[];
    }
  }

  Future<List<AppHomeBanner>> _filterForSelectedRegion(
    List<AppHomeBanner> banners,
    int maxItems,
  ) {
    return _filterForSelectedUser(banners, maxItems);
  }

  Future<List<AppHomeBanner>> _filterForSelectedUser(
    List<AppHomeBanner> banners,
    int maxItems,
  ) async {
    final selectedRegion = await AppRegionService.loadSelection();
    final selectedReligion =
        await AppReligionService.loadSelection() ?? AppReligionPreference.all;
    final area = await AppLocationService.instance.loadLocationArea();
    final filtered = banners
        .where((banner) {
          if (!_religionMatches(selectedReligion, banner.targetReligions)) {
            return false;
          }
          final hasRegionTargets = banner.targetRegionIds.isNotEmpty;
          final hasTarget =
              hasRegionTargets ||
              banner.targetState.isNotEmpty ||
              banner.targetDistrict.isNotEmpty ||
              banner.targetCity.isNotEmpty;
          if (!hasTarget) {
            return false;
          }
          if (hasRegionTargets &&
              !_regionIdsMatch(selectedRegion, banner.targetRegionIds)) {
            return false;
          }
          if (!hasRegionTargets &&
              banner.targetState.isNotEmpty &&
              !_regionMatches(selectedRegion, area, banner.targetState)) {
            return false;
          }
          final needsPreciseArea =
              banner.targetDistrict.isNotEmpty || banner.targetCity.isNotEmpty;
          if (!needsPreciseArea) {
            return true;
          }
          if (area == null) {
            return false;
          }
          return _areaMatches(
            localState: selectedRegion?.name ?? area.state,
            localDistrict: area.district,
            localCity: area.city,
            targetState: '',
            targetDistrict: banner.targetDistrict,
            targetCity: banner.targetCity,
          );
        })
        .toList(growable: false);
    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return filtered.take(maxItems).toList(growable: false);
  }

  bool _regionMatches(
    AppRegion? selectedRegion,
    AppLocationArea? area,
    String targetState,
  ) {
    final target = _normalizeAreaToken(targetState);
    if (target.isEmpty) {
      return true;
    }
    final regionName = _normalizeAreaToken(selectedRegion?.name ?? '');
    final regionId = _normalizeAreaToken(selectedRegion?.id ?? '');
    if (regionName == target || regionId == target) {
      return true;
    }
    final localState = _normalizeAreaToken(area?.state ?? '');
    return localState.isNotEmpty && localState == target;
  }

  bool _regionIdsMatch(
    AppRegion? selectedRegion,
    List<String> targetRegionIds,
  ) {
    final selected = _normalizeAreaToken(selectedRegion?.id ?? '');
    if (selected.isEmpty) {
      return false;
    }
    return targetRegionIds
        .map(_normalizeAreaToken)
        .where((item) => item.isNotEmpty)
        .contains(selected);
  }

  bool _religionMatches(
    AppReligionPreference selectedReligion,
    List<String> targetReligions,
  ) => religionMatchesForSelection(selectedReligion, targetReligions);

  @visibleForTesting
  static bool religionMatchesForSelection(
    AppReligionPreference selectedReligion,
    List<String> targetReligions,
  ) {
    final normalizedTargets = targetReligions
        .map(_normalizeAreaToken)
        .where((item) => item.isNotEmpty)
        .toSet();
    if (normalizedTargets.isEmpty || normalizedTargets.contains('all')) {
      return true;
    }
    final selected = _normalizeAreaToken(selectedReligion.name);
    if (selected == 'all') {
      return true;
    }
    return normalizedTargets.contains(selected);
  }

  bool _areaMatches({
    required String localState,
    required String localDistrict,
    required String localCity,
    required String targetState,
    required String targetDistrict,
    required String targetCity,
  }) {
    bool same(String local, String target) {
      return target.trim().isEmpty ||
          local.trim().toLowerCase() == target.trim().toLowerCase();
    }

    return same(localState, targetState) &&
        same(
          localDistrict.isNotEmpty ? localDistrict : localCity,
          targetDistrict,
        ) &&
        same(localCity, targetCity);
  }

  static String _normalizeAreaToken(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  List<AppHomeBanner> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required String placement,
  }) {
    final banners = snapshot.docs
        .map(_mapDoc)
        .whereType<AppHomeBanner>()
        .where((banner) => banner.active)
        .where((banner) => banner.placement == placement)
        .toList(growable: false);
    banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return banners;
  }

  AppHomeBanner? _mapDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final imageUrl = (data['imageUrl'] as String? ?? '').trim();
    if (imageUrl.isEmpty) {
      return null;
    }
    return AppHomeBanner(
      id: doc.id,
      title: (data['title'] as String? ?? '').trim(),
      subtitle: (data['subtitle'] as String? ?? '').trim(),
      imageUrl: imageUrl,
      ctaLabel: (data['ctaLabel'] as String? ?? '').trim(),
      ctaTarget: (data['ctaTarget'] as String? ?? '').trim(),
      placement: (data['placement'] as String? ?? '').trim(),
      targetState: (data['targetState'] as String? ?? '').trim(),
      targetDistrict: (data['targetDistrict'] as String? ?? '').trim(),
      targetCity: (data['targetCity'] as String? ?? '').trim(),
      targetRegionIds: _stringList(data['targetRegionIds']),
      targetReligions: _stringList(data['targetReligions']),
      promoCardGroup: _toInt(data['promoCardGroup']).clamp(1, 3).toInt(),
      sortOrder: _toInt(data['sortOrder']),
      active: data['active'] is bool ? data['active'] as bool : true,
    );
  }

  List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
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
