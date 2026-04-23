import 'package:mana_poster/features/admin/data/mappers/admin_backend_content_mapper.dart';
import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';
import 'package:mana_poster/features/admin/data/repositories/firestore_landing_content_repository.dart';
import 'package:mana_poster/features/admin/data/repositories/landing_content_repository.dart';
import 'package:mana_poster/features/admin/models/admin_content_models.dart';

class AdminDraftPersistenceCoordinator {
  AdminDraftPersistenceCoordinator({LandingContentRepository? repository})
    : _repository = repository ?? FirestoreLandingContentRepository();

  static const String mainDraftId =
      FirestoreLandingContentRepository.defaultDraftId;

  final LandingContentRepository _repository;

  Future<AdminDraftSnapshot> loadOrCreateMainDraft({
    required String createdByUserId,
  }) async {
    LandingDraft? backendDraft = await _repository.loadDraft(
      draftId: mainDraftId,
    );
    backendDraft ??= await _repository.createDefaultDraftIfMissing(
      draftId: mainDraftId,
      createdByUserId: createdByUserId,
    );
    return AdminDraftSnapshot(
      draft: AdminBackendContentMapper.toAdminDraft(backendDraft),
      id: backendDraft.id,
      version: backendDraft.version,
      createdAt: backendDraft.createdAt,
      updatedAt: backendDraft.updatedAt,
    );
  }

  Future<AdminDraftSnapshot> saveMainDraft({
    required AdminLandingDraft draft,
    required String updatedByUserId,
    required int currentVersion,
    DateTime? existingCreatedAt,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final LandingDraft backendDraft = AdminBackendContentMapper.toLandingDraft(
      draft,
      id: mainDraftId,
      version: currentVersion,
      createdAt: existingCreatedAt?.toUtc() ?? now,
      updatedAt: now,
    );
    final LandingDraft saved = await _repository.saveDraft(backendDraft);
    return AdminDraftSnapshot(
      draft: AdminBackendContentMapper.toAdminDraft(saved),
      id: saved.id,
      version: saved.version,
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt,
    );
  }

  Future<AdminPublishedSnapshot> publishMainDraft({
    required AdminLandingDraft draft,
    required String publishedByUserId,
    required int currentDraftVersion,
    DateTime? existingDraftCreatedAt,
    String? changeNote,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final LandingDraft backendDraft = AdminBackendContentMapper.toLandingDraft(
      draft,
      id: mainDraftId,
      version: currentDraftVersion,
      createdAt: existingDraftCreatedAt?.toUtc() ?? now,
      updatedAt: now,
    );
    final PublishedLanding published = await _repository.publishFromDraft(
      draft: backendDraft,
      publishedByUserId: publishedByUserId,
      changeNote: changeNote,
    );
    return AdminPublishedSnapshot(
      id: published.id,
      version: published.version,
      publishedAt: published.publishedAt,
      publishedByUserId: published.publishedByUserId,
      sourceDraftVersion: published.sourceDraftVersion,
      sourceDraftUpdatedAt: published.sourceDraftUpdatedAt,
    );
  }

  Future<PublishedLanding?> loadPublishedMain() {
    return _repository.loadPublished();
  }

  Future<List<LandingVersionSnapshot>> listVersions({int limit = 30}) {
    return _repository.listVersions(limit: limit);
  }

  Future<LandingVersionSnapshot?> getVersion(String versionId) {
    return _repository.getVersion(versionId: versionId);
  }

  Future<AdminDraftSnapshot> restoreVersionToMainDraft({
    required String versionId,
    required String restoredByUserId,
  }) async {
    final LandingDraft restored = await _repository.restoreVersionToDraft(
      versionId: versionId,
      restoredByUserId: restoredByUserId,
    );
    return AdminDraftSnapshot(
      draft: AdminBackendContentMapper.toAdminDraft(restored),
      id: restored.id,
      version: restored.version,
      createdAt: restored.createdAt,
      updatedAt: restored.updatedAt,
    );
  }
}

class AdminDraftSnapshot {
  const AdminDraftSnapshot({
    required this.draft,
    required this.id,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  final AdminLandingDraft draft;
  final String id;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class AdminPublishedSnapshot {
  const AdminPublishedSnapshot({
    required this.id,
    required this.version,
    required this.publishedAt,
    required this.publishedByUserId,
    required this.sourceDraftVersion,
    required this.sourceDraftUpdatedAt,
  });

  final String id;
  final int version;
  final DateTime publishedAt;
  final String publishedByUserId;
  final int sourceDraftVersion;
  final DateTime sourceDraftUpdatedAt;
}
