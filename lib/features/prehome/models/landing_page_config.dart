import 'package:mana_poster/app/config/landing_page_seed.dart';

class LandingPageConfig {
  const LandingPageConfig({
    required this.showHero,
    required this.showPreview,
    required this.showFeatures,
    required this.showCategories,
    required this.showDynamicEvents,
    required this.showPlans,
    required this.showTestimonials,
    required this.showFaq,
    required this.showDownloadCta,
    required this.downloadUrl,
    required this.watchDemoUrl,
    required this.supportEmail,
    required this.facebookUrl,
    required this.instagramUrl,
    required this.youtubeUrl,
    required this.heroEyebrow,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroPrimaryCtaLabel,
    required this.heroSecondaryCtaLabel,
    required this.heroHighlightLabel,
    required this.previewEyebrow,
    required this.previewTitle,
    required this.previewSubtitle,
    required this.featuresEyebrow,
    required this.featuresTitle,
    required this.featuresSubtitle,
    required this.categoriesEyebrow,
    required this.categoriesTitle,
    required this.categoriesSubtitle,
    required this.dynamicEventsEyebrow,
    required this.dynamicEventsTitle,
    required this.dynamicEventsSubtitle,
    required this.plansEyebrow,
    required this.plansTitle,
    required this.plansSubtitle,
    required this.plansPrimaryCtaLabel,
    required this.faqEyebrow,
    required this.faqTitle,
    required this.faqSubtitle,
    required this.downloadEyebrow,
    required this.downloadTitle,
    required this.downloadSubtitle,
    required this.downloadButtonLabel,
    required this.footerTagline,
    required this.customText,
  });

  factory LandingPageConfig.fallback() {
    return LandingPageSeed.fallbackConfig;
  }

  factory LandingPageConfig.fromMap(Map<String, dynamic> data) {
    bool readBool(String key, bool fallback) {
      final value = data[key];
      return value is bool ? value : fallback;
    }

    String readString(String key) {
      final value = data[key];
      return value is String ? value.trim() : '';
    }

    return LandingPageConfig(
      showHero: readBool('showHero', true),
      showPreview: readBool('showPreview', true),
      showFeatures: readBool('showFeatures', true),
      showCategories: readBool('showCategories', true),
      showDynamicEvents: readBool('showDynamicEvents', true),
      showPlans: readBool('showPlans', true),
      showTestimonials: readBool('showTestimonials', false),
      showFaq: readBool('showFaq', true),
      showDownloadCta: readBool('showDownloadCta', false),
      downloadUrl: readString('downloadUrl'),
      watchDemoUrl: readString('watchDemoUrl'),
      supportEmail: readString('supportEmail'),
      facebookUrl: readString('facebookUrl'),
      instagramUrl: readString('instagramUrl'),
      youtubeUrl: readString('youtubeUrl'),
      heroEyebrow: readString('heroEyebrow'),
      heroTitle: readString('heroTitle'),
      heroSubtitle: readString('heroSubtitle'),
      heroPrimaryCtaLabel: readString('heroPrimaryCtaLabel'),
      heroSecondaryCtaLabel: readString('heroSecondaryCtaLabel'),
      heroHighlightLabel: readString('heroHighlightLabel'),
      previewEyebrow: readString('previewEyebrow'),
      previewTitle: readString('previewTitle'),
      previewSubtitle: readString('previewSubtitle'),
      featuresEyebrow: readString('featuresEyebrow'),
      featuresTitle: readString('featuresTitle'),
      featuresSubtitle: readString('featuresSubtitle'),
      categoriesEyebrow: readString('categoriesEyebrow'),
      categoriesTitle: readString('categoriesTitle'),
      categoriesSubtitle: readString('categoriesSubtitle'),
      dynamicEventsEyebrow: readString('dynamicEventsEyebrow'),
      dynamicEventsTitle: readString('dynamicEventsTitle'),
      dynamicEventsSubtitle: readString('dynamicEventsSubtitle'),
      plansEyebrow: readString('plansEyebrow'),
      plansTitle: readString('plansTitle'),
      plansSubtitle: readString('plansSubtitle'),
      plansPrimaryCtaLabel: readString('plansPrimaryCtaLabel'),
      faqEyebrow: readString('faqEyebrow'),
      faqTitle: readString('faqTitle'),
      faqSubtitle: readString('faqSubtitle'),
      downloadEyebrow: readString('downloadEyebrow'),
      downloadTitle: readString('downloadTitle'),
      downloadSubtitle: readString('downloadSubtitle'),
      downloadButtonLabel: readString('downloadButtonLabel'),
      footerTagline: readString('footerTagline'),
      customText: () {
        final raw = data['customText'];
        if (raw is! Map) {
          return const <String, String>{};
        }
        return raw.map<String, String>((dynamic key, dynamic value) {
          return MapEntry(
            key.toString(),
            value is String ? value.trim() : value?.toString() ?? '',
          );
        });
      }(),
    );
  }

  final bool showHero;
  final bool showPreview;
  final bool showFeatures;
  final bool showCategories;
  final bool showDynamicEvents;
  final bool showPlans;
  final bool showTestimonials;
  final bool showFaq;
  final bool showDownloadCta;
  final String downloadUrl;
  final String watchDemoUrl;
  final String supportEmail;
  final String facebookUrl;
  final String instagramUrl;
  final String youtubeUrl;
  final String heroEyebrow;
  final String heroTitle;
  final String heroSubtitle;
  final String heroPrimaryCtaLabel;
  final String heroSecondaryCtaLabel;
  final String heroHighlightLabel;
  final String previewEyebrow;
  final String previewTitle;
  final String previewSubtitle;
  final String featuresEyebrow;
  final String featuresTitle;
  final String featuresSubtitle;
  final String categoriesEyebrow;
  final String categoriesTitle;
  final String categoriesSubtitle;
  final String dynamicEventsEyebrow;
  final String dynamicEventsTitle;
  final String dynamicEventsSubtitle;
  final String plansEyebrow;
  final String plansTitle;
  final String plansSubtitle;
  final String plansPrimaryCtaLabel;
  final String faqEyebrow;
  final String faqTitle;
  final String faqSubtitle;
  final String downloadEyebrow;
  final String downloadTitle;
  final String downloadSubtitle;
  final String downloadButtonLabel;
  final String footerTagline;
  final Map<String, String> customText;

  LandingPageConfig copyWith({
    bool? showHero,
    bool? showPreview,
    bool? showFeatures,
    bool? showCategories,
    bool? showDynamicEvents,
    bool? showPlans,
    bool? showTestimonials,
    bool? showFaq,
    bool? showDownloadCta,
    String? downloadUrl,
    String? watchDemoUrl,
    String? supportEmail,
    String? facebookUrl,
    String? instagramUrl,
    String? youtubeUrl,
    String? heroEyebrow,
    String? heroTitle,
    String? heroSubtitle,
    String? heroPrimaryCtaLabel,
    String? heroSecondaryCtaLabel,
    String? heroHighlightLabel,
    String? previewEyebrow,
    String? previewTitle,
    String? previewSubtitle,
    String? featuresEyebrow,
    String? featuresTitle,
    String? featuresSubtitle,
    String? categoriesEyebrow,
    String? categoriesTitle,
    String? categoriesSubtitle,
    String? dynamicEventsEyebrow,
    String? dynamicEventsTitle,
    String? dynamicEventsSubtitle,
    String? plansEyebrow,
    String? plansTitle,
    String? plansSubtitle,
    String? plansPrimaryCtaLabel,
    String? faqEyebrow,
    String? faqTitle,
    String? faqSubtitle,
    String? downloadEyebrow,
    String? downloadTitle,
    String? downloadSubtitle,
    String? downloadButtonLabel,
    String? footerTagline,
    Map<String, String>? customText,
  }) {
    return LandingPageConfig(
      showHero: showHero ?? this.showHero,
      showPreview: showPreview ?? this.showPreview,
      showFeatures: showFeatures ?? this.showFeatures,
      showCategories: showCategories ?? this.showCategories,
      showDynamicEvents: showDynamicEvents ?? this.showDynamicEvents,
      showPlans: showPlans ?? this.showPlans,
      showTestimonials: showTestimonials ?? this.showTestimonials,
      showFaq: showFaq ?? this.showFaq,
      showDownloadCta: showDownloadCta ?? this.showDownloadCta,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      watchDemoUrl: watchDemoUrl ?? this.watchDemoUrl,
      supportEmail: supportEmail ?? this.supportEmail,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      heroEyebrow: heroEyebrow ?? this.heroEyebrow,
      heroTitle: heroTitle ?? this.heroTitle,
      heroSubtitle: heroSubtitle ?? this.heroSubtitle,
      heroPrimaryCtaLabel: heroPrimaryCtaLabel ?? this.heroPrimaryCtaLabel,
      heroSecondaryCtaLabel:
          heroSecondaryCtaLabel ?? this.heroSecondaryCtaLabel,
      heroHighlightLabel: heroHighlightLabel ?? this.heroHighlightLabel,
      previewEyebrow: previewEyebrow ?? this.previewEyebrow,
      previewTitle: previewTitle ?? this.previewTitle,
      previewSubtitle: previewSubtitle ?? this.previewSubtitle,
      featuresEyebrow: featuresEyebrow ?? this.featuresEyebrow,
      featuresTitle: featuresTitle ?? this.featuresTitle,
      featuresSubtitle: featuresSubtitle ?? this.featuresSubtitle,
      categoriesEyebrow: categoriesEyebrow ?? this.categoriesEyebrow,
      categoriesTitle: categoriesTitle ?? this.categoriesTitle,
      categoriesSubtitle: categoriesSubtitle ?? this.categoriesSubtitle,
      dynamicEventsEyebrow:
          dynamicEventsEyebrow ?? this.dynamicEventsEyebrow,
      dynamicEventsTitle: dynamicEventsTitle ?? this.dynamicEventsTitle,
      dynamicEventsSubtitle:
          dynamicEventsSubtitle ?? this.dynamicEventsSubtitle,
      plansEyebrow: plansEyebrow ?? this.plansEyebrow,
      plansTitle: plansTitle ?? this.plansTitle,
      plansSubtitle: plansSubtitle ?? this.plansSubtitle,
      plansPrimaryCtaLabel:
          plansPrimaryCtaLabel ?? this.plansPrimaryCtaLabel,
      faqEyebrow: faqEyebrow ?? this.faqEyebrow,
      faqTitle: faqTitle ?? this.faqTitle,
      faqSubtitle: faqSubtitle ?? this.faqSubtitle,
      downloadEyebrow: downloadEyebrow ?? this.downloadEyebrow,
      downloadTitle: downloadTitle ?? this.downloadTitle,
      downloadSubtitle: downloadSubtitle ?? this.downloadSubtitle,
      downloadButtonLabel: downloadButtonLabel ?? this.downloadButtonLabel,
      footerTagline: footerTagline ?? this.footerTagline,
      customText: customText ?? this.customText,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'showHero': showHero,
      'showPreview': showPreview,
      'showFeatures': showFeatures,
      'showCategories': showCategories,
      'showDynamicEvents': showDynamicEvents,
      'showPlans': showPlans,
      'showTestimonials': showTestimonials,
      'showFaq': showFaq,
      'showDownloadCta': showDownloadCta,
      'downloadUrl': downloadUrl,
      'watchDemoUrl': watchDemoUrl,
      'supportEmail': supportEmail,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'youtubeUrl': youtubeUrl,
      'heroEyebrow': heroEyebrow,
      'heroTitle': heroTitle,
      'heroSubtitle': heroSubtitle,
      'heroPrimaryCtaLabel': heroPrimaryCtaLabel,
      'heroSecondaryCtaLabel': heroSecondaryCtaLabel,
      'heroHighlightLabel': heroHighlightLabel,
      'previewEyebrow': previewEyebrow,
      'previewTitle': previewTitle,
      'previewSubtitle': previewSubtitle,
      'featuresEyebrow': featuresEyebrow,
      'featuresTitle': featuresTitle,
      'featuresSubtitle': featuresSubtitle,
      'categoriesEyebrow': categoriesEyebrow,
      'categoriesTitle': categoriesTitle,
      'categoriesSubtitle': categoriesSubtitle,
      'dynamicEventsEyebrow': dynamicEventsEyebrow,
      'dynamicEventsTitle': dynamicEventsTitle,
      'dynamicEventsSubtitle': dynamicEventsSubtitle,
      'plansEyebrow': plansEyebrow,
      'plansTitle': plansTitle,
      'plansSubtitle': plansSubtitle,
      'plansPrimaryCtaLabel': plansPrimaryCtaLabel,
      'faqEyebrow': faqEyebrow,
      'faqTitle': faqTitle,
      'faqSubtitle': faqSubtitle,
      'downloadEyebrow': downloadEyebrow,
      'downloadTitle': downloadTitle,
      'downloadSubtitle': downloadSubtitle,
      'downloadButtonLabel': downloadButtonLabel,
      'footerTagline': footerTagline,
      'customText': customText,
    };
  }
}
