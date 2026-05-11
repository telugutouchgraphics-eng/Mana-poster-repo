import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  Future<SubscriptionExitVideoConfig?> fetchConfig({
    String fieldName = 'subscriptionExitVideo',
  }) async {
    try {
      final snapshot = await firestore
          .collection('websiteConfig')
          .doc('portalSettings')
          .get();
      final data = snapshot.data();
      final video = data?[fieldName];
      if (video is! Map<String, dynamic>) {
        return null;
      }
      return SubscriptionExitVideoConfig(
        active: video['active'] == true,
        url: (video['url'] as String? ?? '').trim(),
        fileName: (video['fileName'] as String? ?? '').trim(),
      );
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
