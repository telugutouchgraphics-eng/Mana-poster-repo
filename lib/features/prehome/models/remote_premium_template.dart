import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';

class RemotePremiumTemplate {
  const RemotePremiumTemplate({
    required this.id,
    required this.titleTe,
    required this.titleHi,
    required this.titleEn,
    required this.previewUrl,
    required this.templateDocumentSource,
    required this.productId,
    this.fallbackProductIds = const <String>[],
    required this.priceInr,
    required this.pageConfig,
    this.category = '',
    this.categoryTags = const <String>[],
    this.personalizationConfig,
    this.sortOrder = 0,
    this.createdAtMillis = 0,
    this.updatedAtMillis = 0,
  });

  final String id;
  final String titleTe;
  final String titleHi;
  final String titleEn;
  final String previewUrl;
  final String templateDocumentSource;
  final String productId;
  final List<String> fallbackProductIds;
  final int priceInr;
  final EditorPageConfig pageConfig;
  final String category;
  final List<String> categoryTags;
  final CreatorPosterPersonalization? personalizationConfig;
  final int sortOrder;
  final int createdAtMillis;
  final int updatedAtMillis;
}
