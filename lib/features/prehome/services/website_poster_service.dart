import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/features/prehome/models/website_poster.dart';

class WebsitePosterService {
  const WebsitePosterService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<List<WebsitePoster>> fetchActivePosters({int? maxItems}) async {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('websitePosters')
          .orderBy('sortOrder');
      if (maxItems != null && maxItems > 0) {
        query = query.limit(maxItems * 3);
      }
      final snapshot = await query.get();
      final posters = _mapSnapshot(snapshot);
      if (maxItems != null && maxItems > 0 && posters.length > maxItems) {
        return posters.take(maxItems).toList(growable: false);
      }
      return posters;
    } catch (error, stackTrace) {
      debugPrint('WebsitePosterService.fetchActivePosters failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const <WebsitePoster>[];
    }
  }

  List<WebsitePoster> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final posters = snapshot.docs
        .map(_mapDoc)
        .whereType<WebsitePoster>()
        .where((poster) => poster.active)
        .toList(growable: false);
    posters.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return posters;
  }

  WebsitePoster? _mapDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final imageUrl = _safeUrl(data['imageUrl'] as String?);
    if (imageUrl.isEmpty) {
      return null;
    }

    final category = _sanitizeText(
      (data['category'] as String? ?? '').trim().isNotEmpty
          ? (data['category'] as String)
          : (data['tag'] as String? ?? '').trim().isNotEmpty
          ? (data['tag'] as String)
          : (data['title'] as String? ?? ''),
    );
    if (category.isEmpty) {
      return null;
    }

    return WebsitePoster(
      id: doc.id,
      category: category,
      imageUrl: imageUrl,
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

  String _safeUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return '';
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') {
      return '';
    }
    return value;
  }

  String _sanitizeText(String raw) {
    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
