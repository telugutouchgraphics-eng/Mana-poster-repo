import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/features/prehome/services/app_region_service.dart';

class SubscriptionExitVideoConfig {
  const SubscriptionExitVideoConfig({
    required this.active,
    required this.url,
    this.fileName = '',
  });

  final bool active;
  final String url;
  final String fileName;

  bool get canPlay => active && url.trim().isNotEmpty;
}

class SubscriptionExitVideoService {
  const SubscriptionExitVideoService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  static const String _globalSettingsDocId = 'portalSettings';

  static String _scopedSettingsDocId(String regionId) {
    final safeRegionId = regionId.trim();
    return safeRegionId.isEmpty
        ? _globalSettingsDocId
        : '${_globalSettingsDocId}_$safeRegionId';
  }

  SubscriptionExitVideoConfig? _readConfig(
    Map<String, dynamic>? data,
    String fieldName,
  ) {
    final video = data?[fieldName];
    if (video is! Map<String, dynamic>) {
      return null;
    }
    return SubscriptionExitVideoConfig(
      active: video['active'] == true,
      url: (video['url'] as String? ?? '').trim(),
      fileName: (video['fileName'] as String? ?? '').trim(),
    );
  }

  Future<SubscriptionExitVideoConfig?> fetchConfig({
    String fieldName = 'subscriptionExitVideo',
  }) async {
    try {
      final region = await AppRegionService.loadSelection();
      final scopedDocId = _scopedSettingsDocId(
        region?.id ?? AppRegionService.fallbackRegionId,
      );
      final scopedSnapshot = await firestore
          .collection('websiteConfig')
          .doc(scopedDocId)
          .get();
      final scopedConfig = _readConfig(scopedSnapshot.data(), fieldName);
      if (scopedConfig?.canPlay == true) {
        return scopedConfig;
      }

      final globalSnapshot = await firestore
          .collection('websiteConfig')
          .doc(_globalSettingsDocId)
          .get();
      return _readConfig(globalSnapshot.data(), fieldName) ?? scopedConfig;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('subscription exit video config failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return null;
    }
  }

  Future<SubscriptionExitVideoConfig?> fetchThanksConfig() {
    return fetchConfig(fieldName: 'subscriptionThanksVideo');
  }
}
