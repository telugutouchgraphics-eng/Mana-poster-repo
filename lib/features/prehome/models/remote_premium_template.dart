import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';

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
    this.sortOrder = 0,
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
  final int sortOrder;
}
