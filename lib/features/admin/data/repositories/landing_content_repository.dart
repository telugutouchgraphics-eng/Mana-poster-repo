import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';

abstract class LandingContentRepository {
  Future<LandingDraft?> loadDraft({required String draftId});

  Future<LandingDraft> createDefaultDraftIfMissing({
    required String draftId,
    required String createdByUserId,
  });

  Future<LandingDraft> createDraft({required String createdByUserId});

  Future<LandingDraft> saveDraft(LandingDraft draft);

  Future<PublishedLanding?> loadPublished();

  Future<PublishedLanding> publishDraft({
    required String draftId,
    required String publishedByUserId,
    String? changeNote,
  });

  Future<PublishedLanding> publishFromDraft({
    required LandingDraft draft,
    required String publishedByUserId,
    String? changeNote,
  });

  Future<List<LandingVersionSnapshot>> listVersions({int limit = 30});

  Future<LandingVersionSnapshot?> getVersion({required String versionId});

  Future<LandingDraft> restoreVersionToDraft({
    required String versionId,
    required String restoredByUserId,
  });
}
