import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';

abstract class MediaRepository {
  Future<List<MediaItem>> listMedia({String? type, String? searchQuery});

  Future<MediaItem?> getMediaById({required String mediaId});

  Future<MediaItem> uploadMedia({
    required MediaUploadPayload payload,
    required String uploadedByUserId,
  });

  Future<MediaItem> updateMediaMetadata(MediaItem item);

  Future<void> deleteMedia({required MediaItem item});
}
