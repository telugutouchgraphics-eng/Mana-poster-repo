import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:mana_poster/features/admin/data/admin_backend_paths.dart';
import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';
import 'package:mana_poster/features/admin/data/repositories/media_repository.dart';

class FirestoreMediaRepository implements MediaRepository {
  FirestoreMediaRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  static const String mediaCollection =
      AdminBackendPaths.mediaLibraryCollection;
  static const String storageRoot = AdminBackendPaths.landingMediaStorageRoot;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _media =>
      _firestore.collection(mediaCollection);

  @override
  Future<List<MediaItem>> listMedia({String? type, String? searchQuery}) async {
    _ensureFirebaseConfigured();
    try {
      Query<Map<String, dynamic>> query = _media.orderBy(
        'updatedAt',
        descending: true,
      );
      if (type != null && type.trim().isNotEmpty && type != 'all') {
        query = query.where('type', isEqualTo: type.trim());
      }
      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      final String normalizedQuery = (searchQuery ?? '').trim().toLowerCase();
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return _decodeMedia(doc.id, doc.data());
          })
          .where((MediaItem item) {
            if (normalizedQuery.isEmpty) {
              return true;
            }
            final String name = item.name.toLowerCase();
            final String path = item.assetPath.toLowerCase();
            final String fileName = item.originalFileName.toLowerCase();
            return name.contains(normalizedQuery) ||
                path.contains(normalizedQuery) ||
                fileName.contains(normalizedQuery);
          })
          .toList();
    } on FirebaseException catch (error) {
      throw AdminMediaRepositoryException(_messageForError(error));
    } catch (_) {
      throw const AdminMediaRepositoryException(
        'Unable to load media library items.',
      );
    }
  }

  @override
  Future<MediaItem?> getMediaById({required String mediaId}) async {
    _ensureFirebaseConfigured();
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _media
          .doc(mediaId)
          .get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return _decodeMedia(snapshot.id, snapshot.data()!);
    } on FirebaseException catch (error) {
      throw AdminMediaRepositoryException(_messageForError(error));
    } catch (_) {
      throw const AdminMediaRepositoryException('Unable to read media item.');
    }
  }

  @override
  Future<MediaItem> uploadMedia({
    required MediaUploadPayload payload,
    required String uploadedByUserId,
  }) async {
    _ensureFirebaseConfigured();
    try {
      final DateTime now = DateTime.now().toUtc();
      final String mediaId = _media.doc().id;
      final String sanitizedName = _sanitizeFileName(payload.originalFileName);
      final String storagePath = AdminBackendPaths.landingMediaObjectPath(
        mediaId: mediaId,
        fileName: sanitizedName,
      );

      final Reference ref = _storage.ref().child(storagePath);
      final Uint8List data = Uint8List.fromList(payload.bytes);
      final SettableMetadata metadata = SettableMetadata(
        contentType: payload.contentType.trim().isEmpty
            ? 'application/octet-stream'
            : payload.contentType.trim(),
      );
      await ref.putData(data, metadata);
      final String downloadUrl = await ref.getDownloadURL();

      final MediaItem media = MediaItem(
        id: mediaId,
        name: payload.name.trim().isEmpty ? sanitizedName : payload.name.trim(),
        assetPath: downloadUrl,
        type: payload.type.trim().isEmpty ? 'misc' : payload.type.trim(),
        originalFileName: payload.originalFileName,
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        contentType: metadata.contentType ?? payload.contentType,
        sizeBytes: payload.bytes.length,
        width: payload.width,
        height: payload.height,
        uploadedByUserId: uploadedByUserId,
        createdAt: now,
        updatedAt: now,
      );

      await _media.doc(mediaId).set(media.toJson(), SetOptions(merge: false));
      return media;
    } on FirebaseException catch (error) {
      throw AdminMediaRepositoryException(_messageForError(error));
    } catch (_) {
      throw const AdminMediaRepositoryException('Media upload failed.');
    }
  }

  @override
  Future<MediaItem> updateMediaMetadata(MediaItem item) async {
    _ensureFirebaseConfigured();
    try {
      final MediaItem updated = item.copyWith(
        updatedAt: DateTime.now().toUtc(),
      );
      await _media
          .doc(updated.id)
          .set(updated.toJson(), SetOptions(merge: true));
      return updated;
    } on FirebaseException catch (error) {
      throw AdminMediaRepositoryException(_messageForError(error));
    } catch (_) {
      throw const AdminMediaRepositoryException(
        'Unable to update media metadata.',
      );
    }
  }

  @override
  Future<void> deleteMedia({required MediaItem item}) async {
    _ensureFirebaseConfigured();
    try {
      if (item.storagePath.trim().isNotEmpty) {
        await _storage.ref().child(item.storagePath.trim()).delete();
      } else if (item.assetPath.startsWith('http')) {
        try {
          await _storage.refFromURL(item.assetPath).delete();
        } on FirebaseException {
          // Keep delete resilient if referenced storage object is already gone.
        }
      }
      await _media.doc(item.id).delete();
    } on FirebaseException catch (error) {
      throw AdminMediaRepositoryException(_messageForError(error));
    } catch (_) {
      throw const AdminMediaRepositoryException('Unable to delete media item.');
    }
  }

  MediaItem _decodeMedia(String id, Map<String, dynamic> data) {
    final Map<String, dynamic> normalized = _normalizeMap(data);
    normalized['id'] = id;
    return MediaItem.fromJson(normalized);
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> source) {
    final Map<String, dynamic> output = <String, dynamic>{};
    source.forEach((String key, dynamic value) {
      if (value is Timestamp) {
        output[key] = value.toDate().toUtc().toIso8601String();
      } else if (value is DateTime) {
        output[key] = value.toUtc().toIso8601String();
      } else {
        output[key] = value;
      }
    });
    return output;
  }

  void _ensureFirebaseConfigured() {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    throw const AdminMediaRepositoryException(
      'Firebase is not configured on this build.',
    );
  }

  String _sanitizeFileName(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'upload_${DateTime.now().millisecondsSinceEpoch}.bin';
    }
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _messageForError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to manage media library files.';
      case 'unavailable':
        return 'Storage or Firestore is unavailable. Try again shortly.';
      case 'unauthenticated':
        return 'Admin login session is required for media actions.';
      default:
        return 'Media operation failed (${error.code}).';
    }
  }
}

class AdminMediaRepositoryException implements Exception {
  const AdminMediaRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
