import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';

class PremiumTemplateDefinition {
  const PremiumTemplateDefinition({
    required this.id,
    required this.titleTe,
    required this.titleHi,
    required this.titleEn,
    required this.previewAssetPath,
    required this.templateDocumentAssetPath,
    required this.productId,
    required this.priceInr,
    required this.pageConfig,
  });

  final String id;
  final String titleTe;
  final String titleHi;
  final String titleEn;
  final String previewAssetPath;
  final String templateDocumentAssetPath;
  final String productId;
  final int priceInr;
  final EditorPageConfig pageConfig;
}

const List<PremiumTemplateDefinition> premiumPoliticalTemplates =
    <PremiumTemplateDefinition>[
      PremiumTemplateDefinition(
        id: 'political_tholi_yekadasi_copy',
        titleTe: 'థోలి ఏకాదశి ప్రీమియం డిజైన్',
        titleHi: 'थोली एकादशी प्रीमियम डिज़ाइन',
        titleEn: 'Tholi Ekadasi Premium Design',
        previewAssetPath:
            'assets/templates/premium/political/previews/political_tholi_yekadasi_copy.png',
        templateDocumentAssetPath:
            'assets/templates/premium/political/documents/political_tholi_yekadasi_copy.json',
        productId: 'premium_template_political_tholi_yekadasi_copy',
        priceInr: 499,
        pageConfig: EditorPageConfig(
          name: 'Tholi Ekadasi Premium',
          widthPx: 3000,
          heightPx: 3000,
        ),
      ),
      PremiumTemplateDefinition(
        id: 'political_untitled_1_2',
        titleTe: 'ప్రీమియం పొలిటికల్ డిజైన్ 1',
        titleHi: 'प्रीमियम पॉलिटिकल डिज़ाइन 1',
        titleEn: 'Premium Political Design 1',
        previewAssetPath:
            'assets/templates/premium/political/previews/political_untitled_1_2.png',
        templateDocumentAssetPath:
            'assets/templates/premium/political/documents/political_untitled_1_2.json',
        productId: 'premium_template_political_untitled_1_2',
        priceInr: 499,
        pageConfig: EditorPageConfig(
          name: 'Premium Political 1',
          widthPx: 3000,
          heightPx: 3000,
        ),
      ),
      PremiumTemplateDefinition(
        id: 'political_untitled_1',
        titleTe: 'ప్రీమియం బర్త్‌డే డిజైన్',
        titleHi: 'प्रीमियम बर्थडे डिज़ाइन',
        titleEn: 'Premium Birthday Design',
        previewAssetPath:
            'assets/templates/premium/political/previews/political_untitled_1.png',
        templateDocumentAssetPath:
            'assets/templates/premium/political/documents/political_untitled_1.json',
        productId: 'premium_template_political_untitled_1',
        priceInr: 499,
        pageConfig: EditorPageConfig(
          name: 'Premium Birthday',
          widthPx: 2400,
          heightPx: 2700,
        ),
      ),
      PremiumTemplateDefinition(
        id: 'political_untitled_2',
        titleTe: 'ప్రీమియం ఫ్లెక్స్ డిజైన్',
        titleHi: 'प्रीमियम फ्लेक्स डिज़ाइन',
        titleEn: 'Premium Flex Design',
        previewAssetPath:
            'assets/templates/premium/political/previews/political_untitled_2.png',
        templateDocumentAssetPath:
            'assets/templates/premium/political/documents/political_untitled_2.json',
        productId: 'premium_template_political_untitled_2',
        priceInr: 499,
        pageConfig: EditorPageConfig(
          name: 'Premium Flex',
          widthPx: 4200,
          heightPx: 4500,
        ),
      ),
      PremiumTemplateDefinition(
        id: 'political_whatsapp_image_2024_10_02_at_6_55_35_pm',
        titleTe: 'ప్రీమియం పోస్టర్ డిజైన్',
        titleHi: 'प्रीमियम पोस्टर डिज़ाइन',
        titleEn: 'Premium Poster Design',
        previewAssetPath:
            'assets/templates/premium/political/previews/political_whatsapp_image_2024_10_02_at_6_55_35_pm.png',
        templateDocumentAssetPath:
            'assets/templates/premium/political/documents/political_whatsapp_image_2024_10_02_at_6_55_35_pm.json',
        productId: 'premium_template_political_whatsapp_image_2024_10_02_at_6_55_35_pm',
        priceInr: 499,
        pageConfig: EditorPageConfig(
          name: 'Premium Poster',
          widthPx: 768,
          heightPx: 941,
        ),
      ),
    ];
