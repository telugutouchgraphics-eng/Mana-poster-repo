import 'package:mana_poster/src/features/home/domain/models/home_banner.dart';
import 'package:mana_poster/src/features/home/domain/models/home_category.dart';
import 'package:mana_poster/src/features/home/domain/models/home_template.dart';

class HomeFeed {
  const HomeFeed({
    required this.banners,
    required this.categories,
    required this.templates,
  });

  final List<HomeBanner> banners;
  final List<HomeCategory> categories;
  final List<HomeTemplate> templates;
}
