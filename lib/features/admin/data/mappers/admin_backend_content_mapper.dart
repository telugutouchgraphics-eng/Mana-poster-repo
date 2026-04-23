import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';
import 'package:mana_poster/features/admin/models/admin_content_models.dart';

class AdminBackendContentMapper {
  const AdminBackendContentMapper._();

  static LandingDraft toLandingDraft(
    AdminLandingDraft source, {
    required String id,
    required int version,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return LandingDraft(
      id: id,
      version: version,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sections: source.sections
          .asMap()
          .entries
          .map(
            (MapEntry<int, LandingSectionDraft> entry) => LandingSectionState(
              id: entry.value.id,
              label: entry.value.label,
              visible: entry.value.visible,
              position: entry.key,
            ),
          )
          .toList(),
      hero: HeroContent(
        badgeText: source.hero.badgeText,
        heading: source.hero.heading,
        subheading: source.hero.subheading,
        primaryCtaText: source.hero.primaryCtaText,
        secondaryCtaText: source.hero.secondaryCtaText,
        trustBullets: List<String>.from(source.hero.trustBullets),
        screenshots: source.hero.screenshots
            .map(
              (HeroScreenshotDraft item) => HeroScreenshotContent(
                title: item.title,
                assetPath: item.assetPath,
              ),
            )
            .toList(),
      ),
      features: source.features
          .asMap()
          .entries
          .map(
            (MapEntry<int, FeatureDraft> entry) => FeatureItem(
              id: 'feature_${entry.key}',
              title: entry.value.title,
              description: entry.value.description,
              iconKey: entry.value.iconKey,
              position: entry.key,
            ),
          )
          .toList(),
      categories: source.categories
          .asMap()
          .entries
          .map(
            (MapEntry<int, CategoryDraft> entry) => CategoryItem(
              id: 'category_${entry.key}',
              title: entry.value.title,
              subtitle: entry.value.subtitle,
              badge: entry.value.badge,
              position: entry.key,
            ),
          )
          .toList(),
      showcaseItems: source.showcasePosters
          .asMap()
          .entries
          .map(
            (MapEntry<int, ShowcasePosterDraft> entry) => ShowcaseItem(
              id: 'showcase_${entry.key}',
              title: entry.value.title,
              subtitle: entry.value.subtitle,
              categoryTag: entry.value.categoryTag,
              accessLabel: entry.value.accessLabel,
              imageAssetPath: entry.value.imageAssetPath,
              position: entry.key,
            ),
          )
          .toList(),
      faqItems: source.faqItems
          .asMap()
          .entries
          .map(
            (MapEntry<int, FaqDraft> entry) => FAQItem(
              id: 'faq_${entry.key}',
              question: entry.value.question,
              answer: entry.value.answer,
              position: entry.key,
            ),
          )
          .toList(),
      footer: FooterContent(
        description: source.footer.description,
        supportEmail: source.footer.supportEmail,
        supportPhone: source.footer.supportPhone,
        privacyLink: source.footer.privacyLink,
        termsLink: source.footer.termsLink,
        downloadLink: source.footer.downloadLink,
        quickLinks: List<String>.from(source.footer.quickLinks),
      ),
      appLinks: AppLinks(
        playStoreUrl: source.appLinks.playStoreUrl,
        watchDemoUrl: source.appLinks.watchDemoUrl,
        privacyPolicyUrl: source.appLinks.privacyPolicyUrl,
        termsUrl: source.appLinks.termsUrl,
        supportEmail: source.appLinks.supportEmail,
        supportPhone: source.appLinks.supportPhone,
        whatsappUrl: source.appLinks.whatsappUrl,
        canonicalUrl: source.appLinks.canonicalUrl,
      ),
      settings: Settings(
        brandName: source.settings.brandName,
        tagline: source.settings.tagline,
        accentTheme: source.settings.accentTheme,
        showSupportEmail: source.settings.showSupportEmail,
        showSupportPhone: source.settings.showSupportPhone,
        showSectionsSummary: source.settings.showSectionsSummary,
        compactCards: source.settings.compactCards,
        enablePreviewAnimations: source.settings.enablePreviewAnimations,
      ),
      mediaItems: source.mediaItems
          .asMap()
          .entries
          .map(
            (MapEntry<int, MediaItemDraft> entry) => MediaItem(
              id: (entry.value.id ?? '').trim().isEmpty
                  ? 'media_${entry.key}'
                  : entry.value.id!,
              name: entry.value.name,
              assetPath: entry.value.assetPath,
              type: entry.value.type,
              originalFileName: entry.value.originalFileName,
              storagePath: entry.value.storagePath,
              downloadUrl: entry.value.downloadUrl,
              contentType: entry.value.contentType,
              sizeBytes: entry.value.sizeBytes,
              width: entry.value.width,
              height: entry.value.height,
              uploadedByUserId: entry.value.uploadedByUserId,
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          )
          .toList(),
    );
  }

  static AdminLandingDraft toAdminDraft(LandingDraft source) {
    return AdminLandingDraft(
      sections: source.sections
          .map(
            (LandingSectionState item) => LandingSectionDraft(
              id: item.id,
              label: item.label,
              visible: item.visible,
            ),
          )
          .toList(),
      hero: HeroContentDraft(
        badgeText: source.hero.badgeText,
        heading: source.hero.heading,
        subheading: source.hero.subheading,
        primaryCtaText: source.hero.primaryCtaText,
        secondaryCtaText: source.hero.secondaryCtaText,
        trustBullets: List<String>.from(source.hero.trustBullets),
        screenshots: source.hero.screenshots
            .map(
              (HeroScreenshotContent item) => HeroScreenshotDraft(
                title: item.title,
                assetPath: item.assetPath,
              ),
            )
            .toList(),
      ),
      features: source.features
          .map(
            (FeatureItem item) => FeatureDraft(
              title: item.title,
              description: item.description,
              iconKey: item.iconKey,
            ),
          )
          .toList(),
      categories: source.categories
          .map(
            (CategoryItem item) => CategoryDraft(
              title: item.title,
              subtitle: item.subtitle,
              badge: item.badge,
            ),
          )
          .toList(),
      showcasePosters: source.showcaseItems
          .map(
            (ShowcaseItem item) => ShowcasePosterDraft(
              title: item.title,
              subtitle: item.subtitle,
              categoryTag: item.categoryTag,
              accessLabel: item.accessLabel,
              imageAssetPath: item.imageAssetPath,
            ),
          )
          .toList(),
      faqItems: source.faqItems
          .map(
            (FAQItem item) =>
                FaqDraft(question: item.question, answer: item.answer),
          )
          .toList(),
      footer: FooterContentDraft(
        description: source.footer.description,
        supportEmail: source.footer.supportEmail,
        supportPhone: source.footer.supportPhone,
        privacyLink: source.footer.privacyLink,
        termsLink: source.footer.termsLink,
        downloadLink: source.footer.downloadLink,
        quickLinks: List<String>.from(source.footer.quickLinks),
      ),
      mediaItems: source.mediaItems
          .map(
            (MediaItem item) => MediaItemDraft(
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
            ),
          )
          .toList(),
      appLinks: AppLinksDraft(
        playStoreUrl: source.appLinks.playStoreUrl,
        watchDemoUrl: source.appLinks.watchDemoUrl,
        privacyPolicyUrl: source.appLinks.privacyPolicyUrl,
        termsUrl: source.appLinks.termsUrl,
        supportEmail: source.appLinks.supportEmail,
        supportPhone: source.appLinks.supportPhone,
        whatsappUrl: source.appLinks.whatsappUrl,
        canonicalUrl: source.appLinks.canonicalUrl,
      ),
      settings: AdminSettingsDraft(
        brandName: source.settings.brandName,
        tagline: source.settings.tagline,
        accentTheme: source.settings.accentTheme,
        showSupportEmail: source.settings.showSupportEmail,
        showSupportPhone: source.settings.showSupportPhone,
        showSectionsSummary: source.settings.showSectionsSummary,
        compactCards: source.settings.compactCards,
        enablePreviewAnimations: source.settings.enablePreviewAnimations,
      ),
    );
  }
}
