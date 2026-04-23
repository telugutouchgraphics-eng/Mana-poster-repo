import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:mana_poster/features/prehome/models/landing_site_content.dart';

class LandingSiteContentService {
  LandingSiteContentService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore,
       _storage = storage;

  static const String collection = 'landingSite';
  static const String documentId = 'main';
  static const String storageRoot = 'landing-site';

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  DocumentReference<Map<String, dynamic>> get _doc =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection(collection)
          .doc(documentId);

  FirebaseStorage get _activeStorage => _storage ?? FirebaseStorage.instance;

  Future<LandingSiteContent> load() async {
    if (Firebase.apps.isEmpty) {
      return LandingSiteContent.empty();
    }
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _doc.get();
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return LandingSiteContent.empty();
      }
      return LandingSiteContent.fromJson(_normalizeMap(data));
    } catch (_) {
      return LandingSiteContent.empty();
    }
  }

  Future<LandingSiteContent> saveBanner({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    final _UploadResult upload = await _uploadFile(
      folder: 'banner',
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
    if (current.bannerStoragePath.isNotEmpty) {
      await _deleteStorageObject(current.bannerStoragePath);
    }
    final LandingSiteContent next = current.copyWith(
      bannerImageUrl: upload.downloadUrl,
      bannerStoragePath: upload.storagePath,
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<LandingSiteContent> deleteBanner() async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    if (current.bannerStoragePath.isNotEmpty) {
      await _deleteStorageObject(current.bannerStoragePath);
    }
    final LandingSiteContent next = LandingSiteContent(
      bannerImageUrl: '',
      bannerStoragePath: '',
      sectionMediaUrl: current.sectionMediaUrl,
      sectionMediaStoragePath: current.sectionMediaStoragePath,
      sectionMediaType: current.sectionMediaType,
      posters: current.posters,
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<LandingSiteContent> saveSectionMedia({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    required String mediaType,
  }) async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    final _UploadResult upload = await _uploadFile(
      folder: 'section-media',
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
    if (current.sectionMediaStoragePath.isNotEmpty) {
      await _deleteStorageObject(current.sectionMediaStoragePath);
    }
    final LandingSiteContent next = current.copyWith(
      sectionMediaUrl: upload.downloadUrl,
      sectionMediaStoragePath: upload.storagePath,
      sectionMediaType: mediaType,
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<LandingSiteContent> deleteSectionMedia() async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    if (current.sectionMediaStoragePath.isNotEmpty) {
      await _deleteStorageObject(current.sectionMediaStoragePath);
    }
    final LandingSiteContent next = current.copyWith(
      sectionMediaUrl: '',
      sectionMediaStoragePath: '',
      sectionMediaType: '',
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<LandingSiteContent> addPoster({
    required String categoryId,
    required String title,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    final _UploadResult upload = await _uploadFile(
      folder: 'posters/$categoryId',
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
    final int nextSortOrder = current.posters
            .where((LandingSitePoster item) => item.categoryId == categoryId)
            .length +
        1;
    final LandingSitePoster poster = LandingSitePoster(
      id: _doc.collection('ids').doc().id,
      categoryId: categoryId,
      title: title.trim().isEmpty ? 'Poster $nextSortOrder' : title.trim(),
      imageUrl: upload.downloadUrl,
      storagePath: upload.storagePath,
      sortOrder: nextSortOrder,
      createdAt: DateTime.now().toUtc(),
    );
    final LandingSiteContent next = current.copyWith(
      posters: <LandingSitePoster>[...current.posters, poster],
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<LandingSiteContent> deletePoster(String posterId) async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    LandingSitePoster? target;
    for (final LandingSitePoster poster in current.posters) {
      if (poster.id == posterId) {
        target = poster;
        break;
      }
    }
    if (target != null && target.storagePath.isNotEmpty) {
      await _deleteStorageObject(target.storagePath);
    }
    final LandingSiteContent next = current.copyWith(
      posters: current.posters
          .where((LandingSitePoster item) => item.id != posterId)
          .toList(growable: false),
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<_UploadResult> _uploadFile({
    required String folder,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final String safeName = _safeFileName(fileName);
    final String storagePath =
        '$storageRoot/$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final Reference ref = _activeStorage.ref().child(storagePath);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType.isEmpty ? 'application/octet-stream' : contentType,
      ),
    );
    return _UploadResult(
      storagePath: storagePath,
      downloadUrl: await ref.getDownloadURL(),
    );
  }

  Future<void> _deleteStorageObject(String storagePath) async {
    try {
      await _activeStorage.ref().child(storagePath).delete();
    } catch (_) {
      // Missing old files should not block content updates.
    }
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> source) {
    final Map<String, dynamic> output = <String, dynamic>{};
    source.forEach((String key, dynamic value) {
      output[key] = _normalizeValue(value);
    });
    return output;
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map<dynamic, dynamic>) {
      final Map<String, dynamic> normalized = <String, dynamic>{};
      value.forEach((dynamic key, dynamic innerValue) {
        normalized[key.toString()] = _normalizeValue(innerValue);
      });
      return normalized;
    }
    if (value is List<dynamic>) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  String _safeFileName(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'upload.bin';
    }
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  void _ensureFirebase() {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    throw const LandingSiteContentException('Firebase is not configured.');
  }
}

class _UploadResult {
  const _UploadResult({required this.storagePath, required this.downloadUrl});

  final String storagePath;
  final String downloadUrl;
}

class LandingSiteContentException implements Exception {
  const LandingSiteContentException(this.message);

  final String message;

  @override
  String toString() => message;
}
