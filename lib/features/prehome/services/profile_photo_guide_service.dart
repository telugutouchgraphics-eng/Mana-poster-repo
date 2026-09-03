import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/features/prehome/services/app_region_service.dart';

class ProfilePhotoGuideImage {
  const ProfilePhotoGuideImage({
    required this.active,
    required this.url,
    this.fileName = '',
  });

  final bool active;
  final String url;
  final String fileName;

  bool get canShow => active && url.trim().isNotEmpty;
}

class ProfilePhotoGuideConfig {
  const ProfilePhotoGuideConfig({this.goodImage, this.badImage});

  final ProfilePhotoGuideImage? goodImage;
  final ProfilePhotoGuideImage? badImage;

  bool get hasAnyImage =>
      goodImage?.canShow == true || badImage?.canShow == true;
}

class ProfilePhotoGuideService {
  const ProfilePhotoGuideService({FirebaseFirestore? firestore})
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

  ProfilePhotoGuideConfig? _readConfig(Map<String, dynamic>? data) {
    final guide = data?['profilePhotoGuide'];
    if (guide is! Map<String, dynamic>) {
      return null;
    }
    return ProfilePhotoGuideConfig(
      goodImage: _readImage(guide['goodImage']),
      badImage: _readImage(guide['badImage']),
    );
  }

  ProfilePhotoGuideImage? _readImage(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    return ProfilePhotoGuideImage(
      active: value['active'] == true,
      url: (value['url'] as String? ?? '').trim(),
      fileName: (value['fileName'] as String? ?? '').trim(),
    );
  }

  Future<ProfilePhotoGuideConfig> fetchConfig() async {
    try {
      final region = await AppRegionService.loadSelection();
      final scopedSnapshot = await firestore
          .collection('websiteConfig')
          .doc(
            _scopedSettingsDocId(
              region?.id ?? AppRegionService.fallbackRegionId,
            ),
          )
          .get();
      final scopedConfig = _readConfig(scopedSnapshot.data());
      if (scopedConfig?.hasAnyImage == true) {
        return scopedConfig!;
      }

      final globalSnapshot = await firestore
          .collection('websiteConfig')
          .doc(_globalSettingsDocId)
          .get();
      return _readConfig(globalSnapshot.data()) ??
          scopedConfig ??
          const ProfilePhotoGuideConfig();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('profile photo guide config failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return const ProfilePhotoGuideConfig();
    }
  }
}
