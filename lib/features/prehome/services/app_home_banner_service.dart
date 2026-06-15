import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/features/prehome/models/app_home_banner.dart';
import 'package:mana_poster/features/prehome/services/app_location_service.dart';

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

  Future<List<AppHomeBanner>> fetchBanners({int maxItems = 8}) async {
    try {
      final snapshot = await firestore
          .collection('appBanners')
          .where('active', isEqualTo: true)
          .orderBy('sortOrder')
          .limit(maxItems)
          .get(const GetOptions(source: Source.server));
      return _filterForArea(_mapSnapshot(snapshot));
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
            .limit(maxItems)
            .get();
        return _filterForArea(_mapSnapshot(fallbackSnapshot));
      } catch (_) {
        return const <AppHomeBanner>[];
      }
    }
  }

  Future<List<AppHomeBanner>> fetchBannersFromCache({int maxItems = 8}) async {
    try {
      final snapshot = await firestore
          .collection('appBanners')
          .where('active', isEqualTo: true)
          .orderBy('sortOrder')
          .limit(maxItems)
          .get(const GetOptions(source: Source.cache));
      return _filterForArea(_mapSnapshot(snapshot));
    } catch (error, stackTrace) {
      _debugLogStack(
        'AppHomeBannerService.fetchBannersFromCache failed: $error',
        stackTrace,
      );
      return const <AppHomeBanner>[];
    }
  }

  Future<List<AppHomeBanner>> _filterForArea(
    List<AppHomeBanner> banners,
  ) async {
    final area = await AppLocationService.instance.loadLocationArea();
    final filtered = banners
        .where((banner) {
          final hasTarget =
              banner.targetState.isNotEmpty ||
              banner.targetDistrict.isNotEmpty ||
              banner.targetCity.isNotEmpty;
          if (!hasTarget) {
            return true;
          }
          if (area == null) {
            return false;
          }
          return _areaMatches(
            localState: area.state,
            localDistrict: area.district,
            localCity: area.city,
            targetState: banner.targetState,
            targetDistrict: banner.targetDistrict,
            targetCity: banner.targetCity,
          );
        })
        .toList(growable: false);
    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return filtered;
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

  List<AppHomeBanner> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final banners = snapshot.docs
        .map(_mapDoc)
        .whereType<AppHomeBanner>()
        .where((banner) => banner.active)
        .where((banner) => banner.placement == 'home_category_banner')
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
      sortOrder: _toInt(data['sortOrder']),
      active: data['active'] is bool ? data['active'] as bool : true,
    );
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
