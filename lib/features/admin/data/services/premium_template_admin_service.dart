import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';

class AdminPremiumTemplateRecord {
  const AdminPremiumTemplateRecord({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.previewStoragePath,
    required this.templateDocumentUrl,
    required this.templateDocumentStoragePath,
    required this.category,
    required this.productId,
    required this.priceInr,
    required this.widthPx,
    required this.heightPx,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminPremiumTemplateRecord.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AdminPremiumTemplateRecord(
      id: id,
      title: (data['titleEn'] as String?)?.trim().isNotEmpty == true
          ? (data['titleEn'] as String).trim()
          : ((data['title'] as String?)?.trim() ?? 'Premium Template'),
      previewUrl: (data['previewUrl'] as String? ?? '').trim(),
      previewStoragePath: (data['previewStoragePath'] as String? ?? '').trim(),
      templateDocumentUrl: (data['templateDocumentUrl'] as String? ?? '')
          .trim(),
      templateDocumentStoragePath:
          (data['templateDocumentStoragePath'] as String? ?? '').trim(),
      category: (data['category'] as String? ?? '').trim(),
      productId: (data['productId'] as String? ?? '').trim(),
      priceInr: (data['priceInr'] as num?)?.toInt() ?? 0,
      widthPx: (data['widthPx'] as num?)?.toInt() ?? 1080,
      heightPx: (data['heightPx'] as num?)?.toInt() ?? 1350,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(data['createdAt']),
    );
  }

  final String id;
  final String title;
  final String previewUrl;
  final String previewStoragePath;
  final String templateDocumentUrl;
  final String templateDocumentStoragePath;
  final String category;
  final String productId;
  final int priceInr;
  final int widthPx;
  final int heightPx;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class PremiumTemplateAdminService {
  PremiumTemplateAdminService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore,
       _storage = storage;

  static const String _collection = 'premium_templates';
  static const String _storageRoot = 'premium-templates';

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  FirebaseFirestore get _activeFirestore =>
      _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _activeStorage => _storage ?? FirebaseStorage.instance;

  Future<List<AdminPremiumTemplateRecord>> loadTemplates() async {
    if (Firebase.apps.isEmpty) {
      return const <AdminPremiumTemplateRecord>[];
    }
    try {
      final snapshot = await _activeFirestore
          .collection(_collection)
          .get()
          .timeout(const Duration(seconds: 15));
      final items = snapshot.docs
          .map(
            (doc) =>
                AdminPremiumTemplateRecord.fromFirestore(doc.id, doc.data()),
          )
          .toList(growable: false);
      items.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) {
          return order;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return items;
    } on TimeoutException {
      return const <AdminPremiumTemplateRecord>[];
    }
  }

  Future<AdminPremiumTemplateRecord> createTemplate({
    required String title,
    required String category,
    required int priceInr,
    required int widthPx,
    required int heightPx,
    required String productId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    CreatorPosterPersonalization personalization =
        CreatorPosterPersonalization.defaults,
  }) async {
    _ensureFirebase();

    final collection = _activeFirestore.collection(_collection);
    final doc = collection.doc();
    final previewUpload = await _uploadFile(
      folder: 'previews/$category',
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );

    final templateDocumentJson = jsonEncode(<String, dynamic>{
      'templateId': doc.id,
      'title': title,
      'sourceWidth': widthPx,
      'sourceHeight': heightPx,
      'layers': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'base_layer',
          'assetPath': previewUpload.downloadUrl,
          'left': 0,
          'top': 0,
          'width': widthPx,
          'height': heightPx,
          'opacity': 1,
          'visible': true,
        },
      ],
    });

    final templateDocumentUpload = await _uploadFile(
      folder: 'documents/$category',
      fileName: '${doc.id}.json',
      bytes: Uint8List.fromList(utf8.encode(templateDocumentJson)),
      contentType: 'application/json',
    );

    final existingInCategory = await collection
        .where('category', isEqualTo: category)
        .get();
    final sortOrder = existingInCategory.docs.length + 1;
    final now = DateTime.now().toUtc();

    final payload = <String, dynamic>{
      'title': title,
      'titleEn': title,
      'titleTe': title,
      'titleHi': title,
      'previewUrl': previewUpload.downloadUrl,
      'previewStoragePath': previewUpload.storagePath,
      'templateDocumentUrl': templateDocumentUpload.downloadUrl,
      'templateDocumentStoragePath': templateDocumentUpload.storagePath,
      'productId': productId,
      'fallbackProductIds': const <String>[],
      'priceInr': priceInr,
      'widthPx': widthPx,
      'heightPx': heightPx,
      'sortOrder': sortOrder,
      'isActive': true,
      'category': category,
      'categoryTags': <String>[category],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'personalization': <String, dynamic>{
        'photoShape': personalization.photoShape,
        'photoX': personalization.photoX,
        'photoY': personalization.photoY,
        'photoScale': personalization.photoScale,
        'nameX': personalization.nameX,
        'nameY': personalization.nameY,
        'showBottomStrip': personalization.showBottomStrip,
        'stripHeight': personalization.stripHeight,
        'showWhatsapp': personalization.showWhatsapp,
        'sampleName': personalization.sampleName,
        'nameScale': personalization.nameScale,
        'showStyledNameStrip': personalization.showStyledNameStrip,
        'showStyledDesignationStrip':
            personalization.showStyledDesignationStrip,
        'sampleDesignation': personalization.sampleDesignation,
        'designationScale': personalization.designationScale,
        'phoneScale': personalization.phoneScale,
        'nameStripColor': personalization.nameStripColor,
        'designationStripColor': personalization.designationStripColor,
        'boardVariant': personalization.boardVariant,
        'photoRenderMode': personalization.photoRenderMode,
        'edgeStyle': personalization.edgeStyle,
        'showSafeAreas': personalization.showSafeAreas,
      },
    };

    await doc.set(payload, SetOptions(merge: false));
    return AdminPremiumTemplateRecord.fromFirestore(doc.id, payload);
  }

  Future<void> deleteTemplate(AdminPremiumTemplateRecord template) async {
    _ensureFirebase();
    await _activeFirestore.collection(_collection).doc(template.id).delete();
    await Future.wait<void>(<Future<void>>[
      if (template.previewStoragePath.isNotEmpty)
        _deleteStorageObject(template.previewStoragePath),
      if (template.templateDocumentStoragePath.isNotEmpty)
        _deleteStorageObject(template.templateDocumentStoragePath),
    ]);
  }

  Future<_StorageUploadResult> _uploadFile({
    required String folder,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safeName = _safeFileName(fileName);
    final storagePath =
        '$_storageRoot/$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _activeStorage.ref().child(storagePath);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType.isEmpty
            ? 'application/octet-stream'
            : contentType,
      ),
    );
    return _StorageUploadResult(
      storagePath: storagePath,
      downloadUrl: await ref.getDownloadURL(),
    );
  }

  Future<void> _deleteStorageObject(String storagePath) async {
    try {
      await _activeStorage.ref().child(storagePath).delete();
    } catch (_) {}
  }

  String _safeFileName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'upload.bin';
    }
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  void _ensureFirebase() {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    throw const PremiumTemplateAdminException('Firebase is not configured.');
  }
}

class _StorageUploadResult {
  const _StorageUploadResult({
    required this.storagePath,
    required this.downloadUrl,
  });

  final String storagePath;
  final String downloadUrl;
}

class PremiumTemplateAdminException implements Exception {
  const PremiumTemplateAdminException(this.message);

  final String message;

  @override
  String toString() => message;
}
