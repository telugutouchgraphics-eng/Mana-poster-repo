import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';

class HomeExportManualAd {
  const HomeExportManualAd({
    required this.active,
    required this.url,
    this.contentType = '',
    this.fileName = '',
  });

  final bool active;
  final String url;
  final String contentType;
  final String fileName;

  bool get canShow => active && url.trim().isNotEmpty;
  bool get isVideo => contentType.toLowerCase().startsWith('video/');
}

class HomeExportAdSettings {
  const HomeExportAdSettings({required this.rewardedEnabled, this.manualAd});

  final bool rewardedEnabled;
  final HomeExportManualAd? manualAd;
}

class HomeExportAdSettingsService {
  HomeExportAdSettingsService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final Map<String, _CachedHomeExportAdSettings> _cache =
      <String, _CachedHomeExportAdSettings>{};

  static const Duration _cacheTtl = Duration(minutes: 5);

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<HomeExportAdSettings> fetchForSelectedRegion() async {
    final region = await AppRegionService.loadSelection();
    final regionId = (region?.id.trim().isNotEmpty ?? false)
        ? region!.id.trim()
        : AppRegionService.fallbackRegionId;
    return fetchForRegion(regionId);
  }

  Future<HomeExportAdSettings> fetchForRegion(String regionId) async {
    final normalizedRegionId = regionId.trim().isNotEmpty
        ? regionId.trim()
        : AppRegionService.fallbackRegionId;
    final cached = _cache[normalizedRegionId];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.loadedAt) < _cacheTtl) {
      return cached.settings;
    }

    try {
      final snapshot = await firestore
          .collection('websiteConfig')
          .doc('portalSettings_$normalizedRegionId')
          .get();
      final data = snapshot.data();
      final ads = data?['ads'];
      HomeExportManualAd? manualAd;
      final rawManualAd = ads is Map<String, dynamic>
          ? ads['homeExportManualAd']
          : null;
      if (rawManualAd is Map<String, dynamic>) {
        manualAd = HomeExportManualAd(
          active: rawManualAd['active'] == true,
          url: (rawManualAd['url'] as String? ?? '').trim(),
          contentType: (rawManualAd['contentType'] as String? ?? '').trim(),
          fileName: (rawManualAd['fileName'] as String? ?? '').trim(),
        );
      }

      final settings = HomeExportAdSettings(
        rewardedEnabled:
            ads is Map<String, dynamic> &&
            ads['homeExportRewardedEnabled'] == true,
        manualAd: manualAd,
      );
      _cache[normalizedRegionId] = _CachedHomeExportAdSettings(
        settings: settings,
        loadedAt: now,
      );
      return settings;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('home export ad settings fetch failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return const HomeExportAdSettings(rewardedEnabled: false);
    }
  }
}

class _CachedHomeExportAdSettings {
  const _CachedHomeExportAdSettings({
    required this.settings,
    required this.loadedAt,
  });

  final HomeExportAdSettings settings;
  final DateTime loadedAt;
}
