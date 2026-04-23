class LandingSectionDraft {
  LandingSectionDraft({
    required this.id,
    required this.label,
    required this.visible,
  });

  final String id;
  final String label;
  bool visible;
}

class HeroScreenshotDraft {
  HeroScreenshotDraft({required this.title, required this.assetPath});

  String title;
  String assetPath;
}

class HeroContentDraft {
  HeroContentDraft({
    required this.badgeText,
    required this.heading,
    required this.subheading,
    required this.primaryCtaText,
    required this.secondaryCtaText,
    required this.trustBullets,
    required this.screenshots,
  });

  String badgeText;
  String heading;
  String subheading;
  String primaryCtaText;
  String secondaryCtaText;
  List<String> trustBullets;
  List<HeroScreenshotDraft> screenshots;
}

class FeatureDraft {
  FeatureDraft({
    required this.title,
    required this.description,
    required this.iconKey,
  });

  String title;
  String description;
  String iconKey;
}

class CategoryDraft {
  CategoryDraft({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  String title;
  String subtitle;
  String badge;
}

class ShowcasePosterDraft {
  ShowcasePosterDraft({
    required this.title,
    required this.subtitle,
    required this.categoryTag,
    required this.accessLabel,
    required this.imageAssetPath,
  });

  String title;
  String subtitle;
  String categoryTag;
  String accessLabel;
  String imageAssetPath;
}

class FaqDraft {
  FaqDraft({required this.question, required this.answer});

  String question;
  String answer;
}

class FooterContentDraft {
  FooterContentDraft({
    required this.description,
    required this.supportEmail,
    required this.supportPhone,
    required this.privacyLink,
    required this.termsLink,
    required this.downloadLink,
    required this.quickLinks,
  });

  String description;
  String supportEmail;
  String supportPhone;
  String privacyLink;
  String termsLink;
  String downloadLink;
  List<String> quickLinks;
}

class MediaItemDraft {
  MediaItemDraft({
    required this.name,
    required this.assetPath,
    required this.type,
    this.id,
    this.originalFileName = '',
    this.storagePath = '',
    this.downloadUrl = '',
    this.contentType = '',
    this.sizeBytes = 0,
    this.width,
    this.height,
    this.uploadedByUserId = '',
  });

  String? id;
  String name;
  String assetPath;
  String type;
  String originalFileName;
  String storagePath;
  String downloadUrl;
  String contentType;
  int sizeBytes;
  int? width;
  int? height;
  String uploadedByUserId;
}

class AppLinksDraft {
  AppLinksDraft({
    required this.playStoreUrl,
    required this.watchDemoUrl,
    required this.privacyPolicyUrl,
    required this.termsUrl,
    required this.supportEmail,
    required this.supportPhone,
    required this.whatsappUrl,
    required this.canonicalUrl,
  });

  String playStoreUrl;
  String watchDemoUrl;
  String privacyPolicyUrl;
  String termsUrl;
  String supportEmail;
  String supportPhone;
  String whatsappUrl;
  String canonicalUrl;
}

class AdminSettingsDraft {
  AdminSettingsDraft({
    required this.brandName,
    required this.tagline,
    required this.accentTheme,
    required this.showSupportEmail,
    required this.showSupportPhone,
    required this.showSectionsSummary,
    required this.compactCards,
    required this.enablePreviewAnimations,
  });

  String brandName;
  String tagline;
  String accentTheme;
  bool showSupportEmail;
  bool showSupportPhone;
  bool showSectionsSummary;
  bool compactCards;
  bool enablePreviewAnimations;
}

class AdminLandingDraft {
  AdminLandingDraft({
    required this.sections,
    required this.hero,
    required this.features,
    required this.categories,
    required this.showcasePosters,
    required this.faqItems,
    required this.footer,
    required this.mediaItems,
    required this.appLinks,
    required this.settings,
  });

  final List<LandingSectionDraft> sections;
  final HeroContentDraft hero;
  final List<FeatureDraft> features;
  final List<CategoryDraft> categories;
  final List<ShowcasePosterDraft> showcasePosters;
  final List<FaqDraft> faqItems;
  final FooterContentDraft footer;
  final List<MediaItemDraft> mediaItems;
  final AppLinksDraft appLinks;
  final AdminSettingsDraft settings;

  factory AdminLandingDraft.seed() {
    return AdminLandingDraft(
      sections: <LandingSectionDraft>[
        LandingSectionDraft(id: 'hero', label: 'Hero', visible: true),
        LandingSectionDraft(id: 'features', label: 'Features', visible: true),
        LandingSectionDraft(
          id: 'categories',
          label: 'Categories',
          visible: true,
        ),
        LandingSectionDraft(
          id: 'how-it-works',
          label: 'How It Works',
          visible: true,
        ),
        LandingSectionDraft(id: 'showcase', label: 'Showcase', visible: true),
        LandingSectionDraft(id: 'faq', label: 'FAQ', visible: true),
        LandingSectionDraft(id: 'footer', label: 'Footer', visible: true),
      ],
      hero: HeroContentDraft(
        badgeText: 'Telugu Poster Maker App',
        heading: 'Create beautiful Telugu posters in minutes',
        subheading:
            'Ready-made festival, devotional, birthday and daily template designs with fast customization.',
        primaryCtaText: 'Download App',
        secondaryCtaText: 'Watch Demo',
        trustBullets: <String>[
          'Free and premium templates',
          'One tap share to WhatsApp',
          'Telugu fonts and festival posters',
        ],
        screenshots: <HeroScreenshotDraft>[
          HeroScreenshotDraft(
            title: 'Home Templates Screen',
            assetPath: 'assets/landing/screenshots/home.png',
          ),
          HeroScreenshotDraft(
            title: 'Poster Editor Screen',
            assetPath: 'assets/landing/screenshots/editor.png',
          ),
          HeroScreenshotDraft(
            title: 'Festival Poster Preview',
            assetPath: 'assets/landing/screenshots/festival.png',
          ),
        ],
      ),
      features: <FeatureDraft>[
        FeatureDraft(
          title: 'Easy Poster Editing',
          description: 'Quickly update text, color and layout in one flow.',
          iconKey: 'edit',
        ),
        FeatureDraft(
          title: 'Telugu Fonts',
          description: 'Readable Telugu typography for local audience posts.',
          iconKey: 'language',
        ),
        FeatureDraft(
          title: 'WhatsApp Share',
          description: 'Share posters directly to status and groups.',
          iconKey: 'share',
        ),
      ],
      categories: <CategoryDraft>[
        CategoryDraft(
          title: 'Good Morning',
          subtitle: 'Daily greeting poster collection',
          badge: 'Daily',
        ),
        CategoryDraft(
          title: 'Birthday',
          subtitle: 'Custom birthday designs with name/photo support',
          badge: 'Popular',
        ),
        CategoryDraft(
          title: 'Festival Special',
          subtitle: 'Ugadi, Sankranti and regional festival posters',
          badge: 'Seasonal',
        ),
      ],
      showcasePosters: <ShowcasePosterDraft>[
        ShowcasePosterDraft(
          title: 'Sri Rama Navami Wishes',
          subtitle: 'Devotional celebration design',
          categoryTag: 'Devotional',
          accessLabel: 'Free',
          imageAssetPath: 'assets/landing/showcase/rama_navami.png',
        ),
        ShowcasePosterDraft(
          title: 'Birthday Gold Theme',
          subtitle: 'Photo-ready birthday poster',
          categoryTag: 'Birthday',
          accessLabel: 'Premium',
          imageAssetPath: 'assets/landing/showcase/birthday_gold.png',
        ),
        ShowcasePosterDraft(
          title: 'Motivational Quote Card',
          subtitle: 'Daily social engagement poster',
          categoryTag: 'Motivational',
          accessLabel: 'Free',
          imageAssetPath: 'assets/landing/showcase/motivation_daily.png',
        ),
      ],
      faqItems: <FaqDraft>[
        FaqDraft(
          question: 'What is Mana Poster?',
          answer:
              'Mana Poster is an Android app to create and customize Telugu posters quickly.',
        ),
        FaqDraft(
          question: 'Can I share posters directly to WhatsApp?',
          answer:
              'Yes, posters can be downloaded and shared instantly to WhatsApp or other social apps.',
        ),
        FaqDraft(
          question: 'Are free templates available?',
          answer:
              'Yes, the app includes free templates and also premium templates for advanced designs.',
        ),
      ],
      footer: FooterContentDraft(
        description:
            'Mana Poster helps creators publish Telugu festival, devotional, birthday and event posters faster.',
        supportEmail: 'manaposter2026@gmail.com',
        supportPhone: '',
        privacyLink: 'https://manaposter.in/legal/privacy-policy.html',
        termsLink: 'https://manaposter.in/legal/terms-and-conditions.html',
        downloadLink:
            'https://play.google.com/store/apps/details?id=com.telugutouch.manaposter',
        quickLinks: <String>[
          'Home',
          'Features',
          'Categories',
          'FAQ',
          'Download',
        ],
      ),
      mediaItems: <MediaItemDraft>[
        MediaItemDraft(
          name: 'Hero Home Screenshot',
          assetPath: 'assets/landing/screenshots/home.png',
          type: 'hero',
        ),
        MediaItemDraft(
          name: 'Showcase Birthday',
          assetPath: 'assets/landing/showcase/birthday_gold.png',
          type: 'showcase',
        ),
        MediaItemDraft(
          name: 'Navbar Logo Mark',
          assetPath: 'assets/landing/icons/logo_mark.png',
          type: 'icon',
        ),
      ],
      appLinks: AppLinksDraft(
        playStoreUrl:
            'https://play.google.com/store/apps/details?id=com.telugutouch.manaposter',
        watchDemoUrl: 'https://manaposter.in/demo',
        privacyPolicyUrl: 'https://manaposter.in/legal/privacy-policy.html',
        termsUrl: 'https://manaposter.in/legal/terms-and-conditions.html',
        supportEmail: 'manaposter2026@gmail.com',
        supportPhone: '',
        whatsappUrl: '',
        canonicalUrl: 'https://manaposter.in',
      ),
      settings: AdminSettingsDraft(
        brandName: 'Mana Poster',
        tagline: 'Create Telugu posters faster for every event',
        accentTheme: 'saffron-pink',
        showSupportEmail: true,
        showSupportPhone: true,
        showSectionsSummary: true,
        compactCards: false,
        enablePreviewAnimations: true,
      ),
    );
  }
}
