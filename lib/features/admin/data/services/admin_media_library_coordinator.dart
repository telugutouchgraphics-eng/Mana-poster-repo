import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';
import 'package:mana_poster/features/admin/data/repositories/firestore_media_repository.dart';
import 'package:mana_poster/features/admin/data/repositories/media_repository.dart';
import 'package:mana_poster/features/admin/models/admin_content_models.dart';

class AdminMediaLibraryCoordinator {
  AdminMediaLibraryCoordinator({MediaRepository? repository})
    : _repository = repository ?? FirestoreMediaRepository();

  final MediaRepository _repository;

  Future<List<MediaItemDraft>> listMedia({
    String? type,
    String? searchQuery,
  }) async {
    final List<MediaItem> items = await _repository.listMedia(
      type: type,
      searchQuery: searchQuery,
    );
    return items.map(_toDraft).toList();
  }

  Future<MediaItemDraft> uploadMedia({
    required MediaUploadPayload payload,
    required String uploadedByUserId,
  }) async {
    final MediaItem item = await _repository.uploadMedia(
      payload: payload,
      uploadedByUserId: uploadedByUserId,
    );
    return _toDraft(item);
  }

  Future<MediaItemDraft> updateMedia(MediaItemDraft draft) async {
    final MediaItem updated = await _repository.updateMediaMetadata(
      _fromDraft(draft),
    );
    return _toDraft(updated);
  }

  Future<void> deleteMedia(MediaItemDraft draft) async {
    await _repository.deleteMedia(item: _fromDraft(draft));
  }

  MediaItemDraft _toDraft(MediaItem item) {
    return MediaItemDraft(
      id: item.id,
      name: item.name,
      assetPath: item.assetPath,
      type: item.type,
      originalFileName: item.originalFileName,
      storagePath: item.storagePath,
      downloadUrl: item.downloadUrl,
      contentType: item.contentType,
      sizeBytes: item.sizeBytes,
      width: item.width,
      height: item.height,
      uploadedByUserId: item.uploadedByUserId,
    );
  }

  MediaItem _fromDraft(MediaItemDraft item) {
    final DateTime now = DateTime.now().toUtc();
    return MediaItem(
      id: (item.id ?? '').trim().isEmpty ? 'media_unknown' : item.id!,
      name: item.name,
      assetPath: item.assetPath,
      type: item.type,
      originalFileName: item.originalFileName,
      storagePath: item.storagePath,
      downloadUrl: item.downloadUrl,
      contentType: item.contentType,
      sizeBytes: item.sizeBytes,
      width: item.width,
      height: item.height,
      uploadedByUserId: item.uploadedByUserId,
      createdAt: now,
      updatedAt: now,
    );
  }
}
