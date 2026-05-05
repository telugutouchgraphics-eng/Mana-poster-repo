import 'dart:typed_data';
import 'dart:async';

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
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _doc
          .get()
          .timeout(const Duration(seconds: 15));
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return LandingSiteContent.empty();
      }
      return LandingSiteContent.fromJson(_normalizeMap(data));
    } on TimeoutException {
      return LandingSiteContent.empty();
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
    final int nextSortOrder =
        current.posters
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
      altText: title.trim().isEmpty ? 'Mana Poster artwork' : title.trim(),
    );
    final LandingSiteContent next = current.copyWith(
      posters: <LandingSitePoster>[...current.posters, poster],
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<LandingSiteContent> savePageSettings({
    required String heroLine1,
    required String heroLine2,
    required String heroBody1,
    required String heroBody2,
    required String heroBody3,
    required String primaryCtaLabel,
    required String secondaryCtaLabel,
    required String playStoreUrl,
    required String featureTitle,
    required String featureSubtitle,
    required String installTitle,
    required String installBody,
    required String seoTitle,
    required String seoDescription,
    required String seoKeywords,
  }) async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    final LandingSiteContent next = current.copyWith(
      heroLine1: _cleanOr(heroLine1, current.heroLine1),
      heroLine2: _cleanOr(heroLine2, current.heroLine2),
      heroBody1: _cleanOr(heroBody1, current.heroBody1),
      heroBody2: _cleanOr(heroBody2, current.heroBody2),
      heroBody3: _cleanOr(heroBody3, current.heroBody3),
      primaryCtaLabel: _cleanOr(primaryCtaLabel, current.primaryCtaLabel),
      secondaryCtaLabel: _cleanOr(secondaryCtaLabel, current.secondaryCtaLabel),
      playStoreUrl: _cleanOr(playStoreUrl, current.playStoreUrl),
      featureTitle: _cleanOr(featureTitle, current.featureTitle),
      featureSubtitle: _cleanOr(featureSubtitle, current.featureSubtitle),
      installTitle: _cleanOr(installTitle, current.installTitle),
      installBody: _cleanOr(installBody, current.installBody),
      seoTitle: _cleanOr(seoTitle, current.seoTitle),
      seoDescription: _cleanOr(seoDescription, current.seoDescription),
      seoKeywords: _cleanOr(seoKeywords, current.seoKeywords),
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<LandingSiteContent> updatePosterDetails({
    required String posterId,
    required String title,
    required String altText,
    required bool isVisible,
  }) async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    final List<LandingSitePoster> posters = current.posters
        .map(
          (LandingSitePoster poster) => poster.id == posterId
              ? poster.copyWith(
                  title: _cleanOr(title, poster.title),
                  altText: altText.trim(),
                  isVisible: isVisible,
                )
              : poster,
        )
        .toList(growable: false);
    final LandingSiteContent next = current.copyWith(
      posters: posters,
      updatedAt: DateTime.now().toUtc(),
    );
    await _doc.set(next.toJson(), SetOptions(merge: true));
    return next;
  }

  Future<LandingSiteContent> movePoster({
    required String posterId,
    required int direction,
  }) async {
    _ensureFirebase();
    final LandingSiteContent current = await load();
    LandingSitePoster? target;
    for (final LandingSitePoster poster in current.posters) {
      if (poster.id == posterId) {
        target = poster;
        break;
      }
    }
    if (target == null) {
      return current;
    }
    final String categoryId = target.categoryId;
    final List<LandingSitePoster> categoryPosters =
        current.posters
            .where(
              (LandingSitePoster poster) => poster.categoryId == categoryId,
            )
            .toList()
          ..sort(
            (LandingSitePoster a, LandingSitePoster b) =>
                a.sortOrder.compareTo(b.sortOrder),
          );
    final int currentIndex = categoryPosters.indexWhere(
      (LandingSitePoster poster) => poster.id == posterId,
    );
    final int nextIndex = currentIndex + direction;
    if (currentIndex < 0 ||
        nextIndex < 0 ||
        nextIndex >= categoryPosters.length) {
      return current;
    }
    final LandingSitePoster moved = categoryPosters.removeAt(currentIndex);
    categoryPosters.insert(nextIndex, moved);
    final Map<String, int> nextOrderById = <String, int>{};
    for (int index = 0; index < categoryPosters.length; index++) {
      nextOrderById[categoryPosters[index].id] = index + 1;
    }
    final LandingSiteContent next = current.copyWith(
      posters: current.posters
          .map(
            (LandingSitePoster poster) => poster.categoryId == categoryId
                ? poster.copyWith(sortOrder: nextOrderById[poster.id])
                : poster,
          )
          .toList(growable: false),
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
        contentType: contentType.isEmpty
            ? 'application/octet-stream'
            : contentType,
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

  String _cleanOr(String input, String fallback) {
    final String trimmed = input.trim();
    return trimmed.isEmpty ? fallback : trimmed;
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
