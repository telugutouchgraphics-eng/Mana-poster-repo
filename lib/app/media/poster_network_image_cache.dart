import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Resize caps before bytes hit disk ([CachedNetworkImage] / [CachedNetworkImageProvider]).
abstract final class PosterNetworkImageLimits {
  /// Feed banners + templates + poster CDN URLs.
  static const int diskFeedMaxWidth = 1280;
  static const int diskFeedMaxHeight = 1920;

  /// Remote profile photo / logo — enough for on-poster placement without huge PNGs.
  static const int diskIdentityMaxWidth = 1200;
  static const int diskIdentityMaxHeight = 1200;
}

/// Bounded disk cache for remote poster/profile URLs.
abstract final class PosterNetworkImageCache {
  static final CacheManager instance = _PosterImageCacheManager._();
}

class _PosterImageCacheManager extends CacheManager with ImageCacheManager {
  _PosterImageCacheManager._()
    : super(
        Config(
          'mana_poster_network_images',
          stalePeriod: const Duration(days: 2),
          maxNrOfCacheObjects: 80,
        ),
      );
}
