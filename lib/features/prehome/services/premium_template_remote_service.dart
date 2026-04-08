import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/prehome/models/remote_premium_template.dart';

class PremiumTemplateRemoteService {
  const PremiumTemplateRemoteService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get storage => _storage ?? FirebaseStorage.instance;

  Future<List<RemotePremiumTemplate>> fetchPoliticalTemplates() async {
    try {
      final snapshot = await firestore
          .collection('premium_templates')
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: 'political')
          .get();

      final templates = <RemotePremiumTemplate>[];
      for (final doc in snapshot.docs) {
        final template = await _mapDocument(doc);
        if (template != null) {
          templates.add(template);
        }
      }
      templates.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return templates;
    } catch (_) {
      return const <RemotePremiumTemplate>[];
    }
  }

  Future<RemotePremiumTemplate?> _mapDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final titleEn = (data['titleEn'] as String?)?.trim();
    final previewUrl =
        (data['previewUrl'] as String?)?.trim() ??
        await _resolveStorageUrl(data['previewStoragePath'] as String?);
    final templateDocumentSource =
        (data['templateDocumentUrl'] as String?)?.trim() ??
        await _resolveStorageUrl(data['templateDocumentStoragePath'] as String?);
    final productId = (data['productId'] as String?)?.trim();
    final widthPx = (data['widthPx'] as num?)?.toInt();
    final heightPx = (data['heightPx'] as num?)?.toInt();

    if (titleEn == null ||
        titleEn.isEmpty ||
        previewUrl == null ||
        previewUrl.isEmpty ||
        templateDocumentSource == null ||
        templateDocumentSource.isEmpty ||
        productId == null ||
        productId.isEmpty ||
        widthPx == null ||
        heightPx == null ||
        widthPx <= 0 ||
        heightPx <= 0) {
      return null;
    }

    return RemotePremiumTemplate(
      id: doc.id,
      titleTe: (data['titleTe'] as String?)?.trim() ?? titleEn,
      titleHi: (data['titleHi'] as String?)?.trim() ?? titleEn,
      titleEn: titleEn,
      previewUrl: previewUrl,
      templateDocumentSource: templateDocumentSource,
      productId: productId,
      fallbackProductIds: ((data['fallbackProductIds'] as List?) ?? const [])
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      priceInr: (data['priceInr'] as num?)?.toInt() ?? 499,
      pageConfig: EditorPageConfig(
        name: titleEn,
        widthPx: widthPx,
        heightPx: heightPx,
      ),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Future<String?> _resolveStorageUrl(String? storagePath) async {
    final normalized = storagePath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    try {
      return await storage.ref(normalized).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
