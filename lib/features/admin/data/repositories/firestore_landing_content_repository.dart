import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mana_poster/features/admin/data/admin_backend_paths.dart';
import 'package:mana_poster/features/admin/data/mappers/admin_backend_content_mapper.dart';
import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';
import 'package:mana_poster/features/admin/data/repositories/landing_content_repository.dart';
import 'package:mana_poster/features/admin/models/admin_content_models.dart';

class FirestoreLandingContentRepository implements LandingContentRepository {
  FirestoreLandingContentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String defaultDraftId = AdminBackendPaths.mainLandingDocumentId;
  static const String defaultPublishedId =
      AdminBackendPaths.mainLandingDocumentId;
  static const String draftsCollection =
      AdminBackendPaths.landingDraftsCollection;
  static const String publishedCollection =
      AdminBackendPaths.landingPublishedCollection;
  static const String versionsCollection =
      AdminBackendPaths.landingVersionsCollection;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _drafts =>
      _firestore.collection(draftsCollection);
  CollectionReference<Map<String, dynamic>> get _published =>
      _firestore.collection(publishedCollection);
  CollectionReference<Map<String, dynamic>> get _versions =>
      _firestore.collection(versionsCollection);

  @override
  Future<LandingDraft?> loadDraft({required String draftId}) async {
    _ensureFirebaseConfigured();
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _drafts
          .doc(draftId)
          .get();
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return _decodeDraft(data, draftId: draftId);
    } on FirebaseException catch (error) {
      throw AdminDraftPersistenceException(_userMessageForFirebaseError(error));
    } on AdminDraftPersistenceException {
      rethrow;
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Could not load landing draft. Using local fallback draft.',
      );
    }
  }

  @override
  Future<LandingDraft> createDefaultDraftIfMissing({
    required String draftId,
    required String createdByUserId,
  }) async {
    _ensureFirebaseConfigured();
    try {
      final DocumentReference<Map<String, dynamic>> ref = _drafts.doc(draftId);
      final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
      if (existing.exists && existing.data() != null) {
        return _decodeDraft(existing.data()!, draftId: draftId);
      }

      final DateTime now = DateTime.now().toUtc();
      final LandingDraft seedDraft = AdminBackendContentMapper.toLandingDraft(
        AdminLandingDraft.seed(),
        id: draftId,
        version: 1,
        createdAt: now,
        updatedAt: now,
      );
      final Map<String, dynamic> payload = _encodeDraft(
        seedDraft,
        updatedByUserId: createdByUserId,
      );
      await ref.set(payload, SetOptions(merge: false));
      return seedDraft;
    } on FirebaseException catch (error) {
      throw AdminDraftPersistenceException(_userMessageForFirebaseError(error));
    } on AdminDraftPersistenceException {
      rethrow;
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Could not create a default cloud draft. Using local fallback draft.',
      );
    }
  }

  @override
  Future<LandingDraft> createDraft({required String createdByUserId}) async {
    return createDefaultDraftIfMissing(
      draftId: defaultDraftId,
      createdByUserId: createdByUserId,
    );
  }

  @override
  Future<LandingDraft> saveDraft(LandingDraft draft) async {
    _ensureFirebaseConfigured();
    try {
      final DateTime now = DateTime.now().toUtc();
      final DateTime createdAt = draft.createdAt.millisecondsSinceEpoch <= 0
          ? now
          : draft.createdAt.toUtc();
      final LandingDraft draftToStore = draft.copyWith(
        createdAt: createdAt,
        updatedAt: now,
        version: draft.version + 1,
      );
      await _drafts
          .doc(draftToStore.id)
          .set(_encodeDraft(draftToStore), SetOptions(merge: true));
      return draftToStore;
    } on FirebaseException catch (error) {
      throw AdminDraftPersistenceException(_userMessageForFirebaseError(error));
    } on AdminDraftPersistenceException {
      rethrow;
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Saving draft failed. Please try again.',
      );
    }
  }

  @override
  Future<PublishedLanding?> loadPublished() async {
    _ensureFirebaseConfigured();
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _published
          .doc(defaultPublishedId)
          .get();
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return _decodePublished(data, publishedId: defaultPublishedId);
    } on FirebaseException catch (error) {
      throw AdminDraftPersistenceException(
        _userMessageForFirebaseError(error, operation: 'published-load'),
      );
    } on AdminDraftPersistenceException {
      rethrow;
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Could not load published landing content.',
      );
    }
  }

  @override
  Future<PublishedLanding> publishDraft({
    required String draftId,
    required String publishedByUserId,
    String? changeNote,
  }) async {
    _ensureFirebaseConfigured();
    final LandingDraft? draft = await loadDraft(draftId: draftId);
    if (draft == null) {
      throw const AdminDraftPersistenceException(
        'Cannot publish because the draft document does not exist yet.',
      );
    }
    return publishFromDraft(
      draft: draft,
      publishedByUserId: publishedByUserId,
      changeNote: changeNote,
    );
  }

  @override
  Future<PublishedLanding> publishFromDraft({
    required LandingDraft draft,
    required String publishedByUserId,
    String? changeNote,
  }) async {
    _ensureFirebaseConfigured();
    try {
      final DocumentReference<Map<String, dynamic>> ref = _published.doc(
        defaultPublishedId,
      );
      final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
      final DateTime now = DateTime.now().toUtc();
      final PublishedLanding? existingPublished =
          existing.exists && existing.data() != null
          ? _decodePublished(existing.data()!, publishedId: defaultPublishedId)
          : null;
      final int nextVersion = (existingPublished?.version ?? 0) + 1;
      final PublishedLanding published = PublishedLanding(
        id: defaultPublishedId,
        sourceDraftId: draft.id,
        sourceDraftVersion: draft.version,
        sourceDraftUpdatedAt: draft.updatedAt.toUtc(),
        publishedByUserId: publishedByUserId,
        version: nextVersion,
        publishedAt: now,
        createdAt: existingPublished?.createdAt.toUtc() ?? now,
        updatedAt: now,
        sections: draft.sections,
        hero: draft.hero,
        features: draft.features,
        categories: draft.categories,
        showcaseItems: draft.showcaseItems,
        faqItems: draft.faqItems,
        footer: draft.footer,
        appLinks: draft.appLinks,
        settings: draft.settings,
        mediaItems: draft.mediaItems,
      );
      final String versionId = _versions.doc().id;
      final String versionLabel = 'v$nextVersion';
      final LandingVersionSnapshot snapshot = LandingVersionSnapshot(
        versionId: versionId,
        versionNumber: nextVersion,
        label: versionLabel,
        note: changeNote ?? '',
        snapshot: published,
        sourceDraftId: draft.id,
        sourceDraftVersion: draft.version,
        publishedAt: now,
        publishedByUserId: publishedByUserId,
        createdAt: now,
      );
      final Map<String, dynamic> payload = _encodePublished(
        published,
        changeNote: changeNote,
      );
      final WriteBatch batch = _firestore.batch();
      batch.set(ref, payload, SetOptions(merge: true));
      batch.set(_versions.doc(versionId), _encodeVersion(snapshot));
      await batch.commit();
      return published;
    } on FirebaseException catch (error) {
      throw AdminDraftPersistenceException(
        _userMessageForFirebaseError(error, operation: 'publish'),
      );
    } on AdminDraftPersistenceException {
      rethrow;
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Publish failed due to malformed content payload.',
      );
    }
  }

  @override
  Future<List<LandingVersionSnapshot>> listVersions({int limit = 30}) async {
    _ensureFirebaseConfigured();
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _versions
          .orderBy('versionNumber', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                _decodeVersion(doc.data(), versionId: doc.id),
          )
          .toList();
    } on FirebaseException catch (error) {
      throw AdminDraftPersistenceException(
        _userMessageForFirebaseError(error, operation: 'version-list'),
      );
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Unable to load version history.',
      );
    }
  }

  @override
  Future<LandingVersionSnapshot?> getVersion({
    required String versionId,
  }) async {
    _ensureFirebaseConfigured();
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _versions
          .doc(versionId)
          .get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return _decodeVersion(snapshot.data()!, versionId: snapshot.id);
    } on FirebaseException catch (error) {
      throw AdminDraftPersistenceException(
        _userMessageForFirebaseError(error, operation: 'version-read'),
      );
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Unable to read version data.',
      );
    }
  }

  @override
  Future<LandingDraft> restoreVersionToDraft({
    required String versionId,
    required String restoredByUserId,
  }) async {
    _ensureFirebaseConfigured();
    try {
      final LandingVersionSnapshot? version = await getVersion(
        versionId: versionId,
      );
      if (version == null) {
        throw const AdminDraftPersistenceException(
          'Selected version was not found.',
        );
      }
      final LandingDraft? existingDraft = await loadDraft(
        draftId: defaultDraftId,
      );
      final DateTime now = DateTime.now().toUtc();
      final LandingDraft restored = LandingDraft(
        id: defaultDraftId,
        version: (existingDraft?.version ?? version.snapshot.version) + 1,
        createdAt: existingDraft?.createdAt.toUtc() ?? now,
        updatedAt: now,
        sections: version.snapshot.sections,
        hero: version.snapshot.hero,
        features: version.snapshot.features,
        categories: version.snapshot.categories,
        showcaseItems: version.snapshot.showcaseItems,
        faqItems: version.snapshot.faqItems,
        footer: version.snapshot.footer,
        appLinks: version.snapshot.appLinks,
        settings: version.snapshot.settings,
        mediaItems: version.snapshot.mediaItems,
      );
      await _drafts
          .doc(defaultDraftId)
          .set(
            _encodeDraft(restored, updatedByUserId: restoredByUserId),
            SetOptions(merge: true),
          );
      return restored;
    } on FirebaseException catch (error) {
      throw AdminDraftPersistenceException(
        _userMessageForFirebaseError(error, operation: 'version-restore'),
      );
    } on AdminDraftPersistenceException {
      rethrow;
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Failed to restore selected version to draft.',
      );
    }
  }

  void _ensureFirebaseConfigured() {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    throw const AdminDraftPersistenceException(
      'Firebase is not configured on this build. Complete Firebase setup first.',
    );
  }

  LandingDraft _decodeDraft(
    Map<String, dynamic> rawData, {
    required String draftId,
  }) {
    try {
      final Map<String, dynamic> data = _normalizeMap(rawData);
      if ((data['id'] as String?)?.isNotEmpty != true) {
        data['id'] = draftId;
      }
      return LandingDraft.fromJson(data);
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Cloud draft data is invalid. Using local fallback draft.',
      );
    }
  }

  Map<String, dynamic> _encodeDraft(
    LandingDraft draft, {
    String? updatedByUserId,
  }) {
    final Map<String, dynamic> data = draft.toJson();
    data['id'] = draft.id;
    data['updatedByUserId'] = updatedByUserId;
    return data;
  }

  PublishedLanding _decodePublished(
    Map<String, dynamic> rawData, {
    required String publishedId,
  }) {
    try {
      final Map<String, dynamic> data = _normalizeMap(rawData);
      if ((data['id'] as String?)?.isNotEmpty != true) {
        data['id'] = publishedId;
      }
      return PublishedLanding.fromJson(data);
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Published document data is invalid.',
      );
    }
  }

  Map<String, dynamic> _encodePublished(
    PublishedLanding published, {
    String? changeNote,
  }) {
    final Map<String, dynamic> data = published.toJson();
    data['id'] = published.id;
    data['publishMeta'] = <String, dynamic>{
      'changeNote': changeNote,
      'publishedAt': published.publishedAt.toIso8601String(),
      'publishedByUserId': published.publishedByUserId,
      'sourceDraftId': published.sourceDraftId,
      'sourceDraftVersion': published.sourceDraftVersion,
      'sourceDraftUpdatedAt': published.sourceDraftUpdatedAt.toIso8601String(),
      'version': published.version,
    };
    return data;
  }

  LandingVersionSnapshot _decodeVersion(
    Map<String, dynamic> rawData, {
    required String versionId,
  }) {
    try {
      final Map<String, dynamic> data = _normalizeMap(rawData);
      if ((data['versionId'] as String?)?.isNotEmpty != true) {
        data['versionId'] = versionId;
      }
      return LandingVersionSnapshot.fromJson(data);
    } catch (_) {
      throw const AdminDraftPersistenceException(
        'Version snapshot payload is invalid.',
      );
    }
  }

  Map<String, dynamic> _encodeVersion(LandingVersionSnapshot snapshot) {
    final Map<String, dynamic> data = snapshot.toJson();
    data['versionId'] = snapshot.versionId;
    return data;
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

  String _userMessageForFirebaseError(
    FirebaseException error, {
    String operation = 'draft',
  }) {
    switch (error.code) {
      case 'permission-denied':
        if (operation == 'version-list' ||
            operation == 'version-read' ||
            operation == 'version-restore') {
          return 'You do not have permission to access version history.';
        }
        return operation == 'publish'
            ? 'You do not have permission to publish content.'
            : 'You do not have permission to access cloud draft data.';
      case 'unavailable':
        return 'Firestore is temporarily unavailable. Please try again.';
      case 'not-found':
        return operation == 'published-load'
            ? 'Published landing content not found.'
            : 'Cloud draft not found.';
      case 'failed-precondition':
        return 'Firestore is not fully configured for this project yet.';
      default:
        if (operation == 'version-list' ||
            operation == 'version-read' ||
            operation == 'version-restore') {
          return 'Version history request failed (${error.code}).';
        }
        return operation == 'publish'
            ? 'Publishing failed (${error.code}).'
            : 'Cloud draft request failed (${error.code}).';
    }
  }
}

class AdminDraftPersistenceException implements Exception {
  const AdminDraftPersistenceException(this.message);

  final String message;

  @override
  String toString() => message;
}
