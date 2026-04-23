import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';
import 'package:mana_poster/features/admin/data/repositories/firestore_landing_content_repository.dart';
import 'package:mana_poster/features/admin/data/repositories/landing_content_repository.dart';

class PublishedLandingReadService {
  PublishedLandingReadService({LandingContentRepository? repository})
    : _repository = repository ?? FirestoreLandingContentRepository();

  final LandingContentRepository _repository;

  Future<PublishedLanding?> loadPublishedLanding() {
    return _repository.loadPublished();
  }
}
