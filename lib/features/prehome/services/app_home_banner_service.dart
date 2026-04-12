import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/features/prehome/models/app_home_banner.dart';

class AppHomeBannerService {
  const AppHomeBannerService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<List<AppHomeBanner>> fetchBanners({int maxItems = 8}) async {
    try {
      final snapshot = await firestore
          .collection('appBanners')
          .where('active', isEqualTo: true)
          .orderBy('sortOrder')
          .limit(maxItems)
          .get();
      return _mapSnapshot(snapshot);
    } catch (error, stackTrace) {
      debugPrint('AppHomeBannerService.fetchBanners failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const <AppHomeBanner>[];
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
      return _mapSnapshot(snapshot);
    } catch (error, stackTrace) {
      debugPrint('AppHomeBannerService.fetchBannersFromCache failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const <AppHomeBanner>[];
    }
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
