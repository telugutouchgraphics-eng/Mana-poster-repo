import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/features/prehome/models/landing_page_config.dart';
import 'package:mana_poster/features/prehome/models/website_poster.dart';

/// Stable fallback and seed data for the public landing page.
///
/// Keep these field names aligned with Firestore and any future admin panel.
/// Collections/docs expected by the public website:
/// - websiteConfig / landingPage
/// - websitePosters / generated document id
class LandingPageSeed {
  LandingPageSeed._();

  static const String playStoreUrl = AppPublicInfo.playStoreUrl;

  /// Default local fallback used when Firestore config is missing or invalid.
  ///
  /// These values are safe to change later without refactoring the public site.
  static final LandingPageConfig fallbackConfig = LandingPageConfig(
    showHero: true,
    showPreview: true,
    showFeatures: true,
    showCategories: true,
    showDynamicEvents: true,
    showPlans: true,
    showTestimonials: false,
    showFaq: true,
    showDownloadCta: false,
    downloadUrl: playStoreUrl,
    watchDemoUrl: AppPublicInfo.demoUrl,
    supportEmail: AppPublicInfo.supportEmail,
    facebookUrl: '',
    instagramUrl: '',
    youtubeUrl: '',
    heroEyebrow: 'Telugu-first poster creation',
    heroTitle: 'Create Telugu Posters in Seconds',
    heroSubtitle:
        'Mana Poster lets users create, customize, and share Telugu posters instantly with a simple, fast workflow.',
    heroPrimaryCtaLabel: 'Download App',
    heroSecondaryCtaLabel: 'Watch Demo',
    heroHighlightLabel: 'Free & Premium Posters Available',
    previewEyebrow: 'App Preview',
    previewTitle: 'A clear view of how poster flow looks inside the app',
    previewSubtitle:
        'The flow is designed to stay simple from category selection to preview, personalization, and final sharing.',
    featuresEyebrow: 'Features',
    featuresTitle: 'Built for fast Telugu poster creation',
    featuresSubtitle:
        'Templates, sharing, personalization, and daily-use category flows are organized to keep poster making quick and repeatable.',
    categoriesEyebrow: 'Categories',
    categoriesTitle: 'Colorful Category Gallery',
    categoriesSubtitle:
        'Each category opens like a poster wall so the landing page feels rich, bold, and closer to a real creative marketplace.',
    dynamicEventsEyebrow: 'Today\'s Special Posters',
    dynamicEventsTitle: 'Every Day New Posters Automatically',
    dynamicEventsSubtitle:
        'Mana Poster automatically shows posters for Festivals, Jayanthi, Vardhanthi, National Days and Telugu State Events based on the selected date.',
    plansEyebrow: 'Free vs Premium',
    plansTitle: 'Choose the plan that fits your poster workflow',
    plansSubtitle:
        'Free covers quick daily use. Premium opens fully editable posters, stronger templates, better exports, and faster personalization.',
    plansPrimaryCtaLabel: 'Buy Premium',
    faqEyebrow: 'FAQ',
    faqTitle: 'Frequently asked questions',
    faqSubtitle:
        'Common doubts about templates, photos, HD downloads, and daily Telugu poster updates.',
    downloadEyebrow: 'Final CTA',
    downloadTitle: 'Start Creating Beautiful Telugu Posters Today',
    downloadSubtitle:
        'Ready templates, Telugu-friendly typing, photo placement, and fast sharing come together in one app.',
    downloadButtonLabel: 'Download App',
    footerTagline:
        'Mana Poster is a simple way to create and share Telugu posters every day.',
    customText: const <String, String>{},
  );

  /// Copy-paste seed for Firestore document: websiteConfig / landingPage
  static final Map<String, Object?> firestoreLandingPageDocument =
      <String, Object?>{
        'showHero': true,
        'showPreview': true,
        'showFeatures': true,
        'showCategories': true,
        'showDynamicEvents': true,
        'showPlans': true,
        'showTestimonials': false,
        'showFaq': true,
        'showDownloadCta': false,
        'downloadUrl': playStoreUrl,
        'watchDemoUrl': AppPublicInfo.demoUrl,
        'supportEmail': AppPublicInfo.supportEmail,
        'facebookUrl': '',
        'instagramUrl': '',
        'youtubeUrl': '',
        'heroEyebrow': 'Telugu-first poster creation',
        'heroTitle': 'Create Telugu Posters in Seconds',
        'heroSubtitle':
            'Mana Poster lets users create, customize, and share Telugu posters instantly with a simple, fast workflow.',
        'heroPrimaryCtaLabel': 'Download App',
        'heroSecondaryCtaLabel': 'Watch Demo',
        'heroHighlightLabel': 'Free & Premium Posters Available',
        'previewEyebrow': 'App Preview',
        'previewTitle':
            'A clear view of how poster flow looks inside the app',
        'previewSubtitle':
            'The flow is designed to stay simple from category selection to preview, personalization, and final sharing.',
        'featuresEyebrow': 'Features',
        'featuresTitle': 'Built for fast Telugu poster creation',
        'featuresSubtitle':
            'Templates, sharing, personalization, and daily-use category flows are organized to keep poster making quick and repeatable.',
        'categoriesEyebrow': 'Categories',
        'categoriesTitle': 'Colorful Category Gallery',
        'categoriesSubtitle':
            'Each category opens like a poster wall so the landing page feels rich, bold, and closer to a real creative marketplace.',
        'dynamicEventsEyebrow': 'Today\'s Special Posters',
        'dynamicEventsTitle': 'Every Day New Posters Automatically',
        'dynamicEventsSubtitle':
            'Mana Poster automatically shows posters for Festivals, Jayanthi, Vardhanthi, National Days and Telugu State Events based on the selected date.',
        'plansEyebrow': 'Free vs Premium',
        'plansTitle': 'Choose the plan that fits your poster workflow',
        'plansSubtitle':
            'Free covers quick daily use. Premium opens fully editable posters, stronger templates, better exports, and faster personalization.',
        'plansPrimaryCtaLabel': 'Buy Premium',
        'faqEyebrow': 'FAQ',
        'faqTitle': 'Frequently asked questions',
        'faqSubtitle':
            'Common doubts about templates, photos, HD downloads, and daily Telugu poster updates.',
        'downloadEyebrow': 'Final CTA',
        'downloadTitle': 'Start Creating Beautiful Telugu Posters Today',
        'downloadSubtitle':
            'Ready templates, Telugu-friendly typing, photo placement, and fast sharing come together in one app.',
        'downloadButtonLabel': 'Download App',
        'footerTagline':
            'Mana Poster is a simple way to create and share Telugu posters every day.',
        'customText': <String, String>{},
      };

  /// Copy-paste seed for Firestore collection: websitePosters.
  /// Keep empty until real poster images are uploaded and approved in Admin.
  static final List<Map<String, Object?>>
  firestoreWebsitePosters = <Map<String, Object?>>[];

  /// No local poster fallbacks: real website posters must come from Admin.
  static const List<WebsitePoster> fallbackWebsitePosters = <WebsitePoster>[];
}
