class LandingSectionState {
  const LandingSectionState({
    required this.id,
    required this.label,
    required this.visible,
    required this.position,
  });

  final String id;
  final String label;
  final bool visible;
  final int position;

  LandingSectionState copyWith({
    String? id,
    String? label,
    bool? visible,
    int? position,
  }) {
    return LandingSectionState(
      id: id ?? this.id,
      label: label ?? this.label,
      visible: visible ?? this.visible,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'visible': visible,
      'position': position,
    };
  }

  factory LandingSectionState.fromJson(Map<String, dynamic> json) {
    return LandingSectionState(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      visible: json['visible'] as bool? ?? false,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

class HeroScreenshotContent {
  const HeroScreenshotContent({required this.title, required this.assetPath});

  final String title;
  final String assetPath;

  HeroScreenshotContent copyWith({String? title, String? assetPath}) {
    return HeroScreenshotContent(
      title: title ?? this.title,
      assetPath: assetPath ?? this.assetPath,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'assetPath': assetPath};
  }

  factory HeroScreenshotContent.fromJson(Map<String, dynamic> json) {
    return HeroScreenshotContent(
      title: json['title'] as String? ?? '',
      assetPath: json['assetPath'] as String? ?? '',
    );
  }
}

class HeroContent {
  const HeroContent({
    required this.badgeText,
    required this.heading,
    required this.subheading,
    required this.primaryCtaText,
    required this.secondaryCtaText,
    required this.trustBullets,
    required this.screenshots,
  });

  final String badgeText;
  final String heading;
  final String subheading;
  final String primaryCtaText;
  final String secondaryCtaText;
  final List<String> trustBullets;
  final List<HeroScreenshotContent> screenshots;

  HeroContent copyWith({
    String? badgeText,
    String? heading,
    String? subheading,
    String? primaryCtaText,
    String? secondaryCtaText,
    List<String>? trustBullets,
    List<HeroScreenshotContent>? screenshots,
  }) {
    return HeroContent(
      badgeText: badgeText ?? this.badgeText,
      heading: heading ?? this.heading,
      subheading: subheading ?? this.subheading,
      primaryCtaText: primaryCtaText ?? this.primaryCtaText,
      secondaryCtaText: secondaryCtaText ?? this.secondaryCtaText,
      trustBullets: trustBullets ?? this.trustBullets,
      screenshots: screenshots ?? this.screenshots,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'badgeText': badgeText,
      'heading': heading,
      'subheading': subheading,
      'primaryCtaText': primaryCtaText,
      'secondaryCtaText': secondaryCtaText,
      'trustBullets': trustBullets,
      'screenshots': screenshots
          .map((HeroScreenshotContent item) => item.toJson())
          .toList(),
    };
  }

  factory HeroContent.fromJson(Map<String, dynamic> json) {
    return HeroContent(
      badgeText: json['badgeText'] as String? ?? '',
      heading: json['heading'] as String? ?? '',
      subheading: json['subheading'] as String? ?? '',
      primaryCtaText: json['primaryCtaText'] as String? ?? '',
      secondaryCtaText: json['secondaryCtaText'] as String? ?? '',
      trustBullets: (json['trustBullets'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      screenshots: (json['screenshots'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) => HeroScreenshotContent.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class FeatureItem {
  const FeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.position,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final int position;

  FeatureItem copyWith({
    String? id,
    String? title,
    String? description,
    String? iconKey,
    int? position,
  }) {
    return FeatureItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'iconKey': iconKey,
      'position': position,
    };
  }

  factory FeatureItem.fromJson(Map<String, dynamic> json) {
    return FeatureItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.position,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final int position;

  CategoryItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? badge,
    int? position,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badge: badge ?? this.badge,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'badge': badge,
      'position': position,
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShowcaseItem {
  const ShowcaseItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryTag,
    required this.accessLabel,
    required this.imageAssetPath,
    required this.position,
  });

  final String id;
  final String title;
  final String subtitle;
  final String categoryTag;
  final String accessLabel;
  final String imageAssetPath;
  final int position;

  ShowcaseItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? categoryTag,
    String? accessLabel,
    String? imageAssetPath,
    int? position,
  }) {
    return ShowcaseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      categoryTag: categoryTag ?? this.categoryTag,
      accessLabel: accessLabel ?? this.accessLabel,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'categoryTag': categoryTag,
      'accessLabel': accessLabel,
      'imageAssetPath': imageAssetPath,
      'position': position,
    };
  }

  factory ShowcaseItem.fromJson(Map<String, dynamic> json) {
    return ShowcaseItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      categoryTag: json['categoryTag'] as String? ?? '',
      accessLabel: json['accessLabel'] as String? ?? '',
      imageAssetPath: json['imageAssetPath'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

class FAQItem {
  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.position,
  });

  final String id;
  final String question;
  final String answer;
  final int position;

  FAQItem copyWith({
    String? id,
    String? question,
    String? answer,
    int? position,
  }) {
    return FAQItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'question': question,
      'answer': answer,
      'position': position,
    };
  }

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

class FooterContent {
  const FooterContent({
    required this.description,
    required this.supportEmail,
    required this.supportPhone,
    required this.privacyLink,
    required this.termsLink,
    required this.downloadLink,
    required this.quickLinks,
  });

  final String description;
  final String supportEmail;
  final String supportPhone;
  final String privacyLink;
  final String termsLink;
  final String downloadLink;
  final List<String> quickLinks;

  FooterContent copyWith({
    String? description,
    String? supportEmail,
    String? supportPhone,
    String? privacyLink,
    String? termsLink,
    String? downloadLink,
    List<String>? quickLinks,
  }) {
    return FooterContent(
      description: description ?? this.description,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      privacyLink: privacyLink ?? this.privacyLink,
      termsLink: termsLink ?? this.termsLink,
      downloadLink: downloadLink ?? this.downloadLink,
      quickLinks: quickLinks ?? this.quickLinks,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'description': description,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'privacyLink': privacyLink,
      'termsLink': termsLink,
      'downloadLink': downloadLink,
      'quickLinks': quickLinks,
    };
  }

  factory FooterContent.fromJson(Map<String, dynamic> json) {
    return FooterContent(
      description: json['description'] as String? ?? '',
      supportEmail: json['supportEmail'] as String? ?? '',
      supportPhone: json['supportPhone'] as String? ?? '',
      privacyLink: json['privacyLink'] as String? ?? '',
      termsLink: json['termsLink'] as String? ?? '',
      downloadLink: json['downloadLink'] as String? ?? '',
      quickLinks: (json['quickLinks'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
    );
  }
}

class AppLinks {
  const AppLinks({
    required this.playStoreUrl,
    required this.watchDemoUrl,
    required this.privacyPolicyUrl,
    required this.termsUrl,
    required this.supportEmail,
    required this.supportPhone,
    required this.whatsappUrl,
    required this.canonicalUrl,
  });

  final String playStoreUrl;
  final String watchDemoUrl;
  final String privacyPolicyUrl;
  final String termsUrl;
  final String supportEmail;
  final String supportPhone;
  final String whatsappUrl;
  final String canonicalUrl;

  AppLinks copyWith({
    String? playStoreUrl,
    String? watchDemoUrl,
    String? privacyPolicyUrl,
    String? termsUrl,
    String? supportEmail,
    String? supportPhone,
    String? whatsappUrl,
    String? canonicalUrl,
  }) {
    return AppLinks(
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      watchDemoUrl: watchDemoUrl ?? this.watchDemoUrl,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      termsUrl: termsUrl ?? this.termsUrl,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      whatsappUrl: whatsappUrl ?? this.whatsappUrl,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'playStoreUrl': playStoreUrl,
      'watchDemoUrl': watchDemoUrl,
      'privacyPolicyUrl': privacyPolicyUrl,
      'termsUrl': termsUrl,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'whatsappUrl': whatsappUrl,
      'canonicalUrl': canonicalUrl,
    };
  }

  factory AppLinks.fromJson(Map<String, dynamic> json) {
    return AppLinks(
      playStoreUrl: json['playStoreUrl'] as String? ?? '',
      watchDemoUrl: json['watchDemoUrl'] as String? ?? '',
      privacyPolicyUrl: json['privacyPolicyUrl'] as String? ?? '',
      termsUrl: json['termsUrl'] as String? ?? '',
      supportEmail: json['supportEmail'] as String? ?? '',
      supportPhone: json['supportPhone'] as String? ?? '',
      whatsappUrl: json['whatsappUrl'] as String? ?? '',
      canonicalUrl: json['canonicalUrl'] as String? ?? '',
    );
  }
}

class Settings {
  const Settings({
    required this.brandName,
    required this.tagline,
    required this.accentTheme,
    required this.showSupportEmail,
    required this.showSupportPhone,
    required this.showSectionsSummary,
    required this.compactCards,
    required this.enablePreviewAnimations,
  });

  final String brandName;
  final String tagline;
  final String accentTheme;
  final bool showSupportEmail;
  final bool showSupportPhone;
  final bool showSectionsSummary;
  final bool compactCards;
  final bool enablePreviewAnimations;

  Settings copyWith({
    String? brandName,
    String? tagline,
    String? accentTheme,
    bool? showSupportEmail,
    bool? showSupportPhone,
    bool? showSectionsSummary,
    bool? compactCards,
    bool? enablePreviewAnimations,
  }) {
    return Settings(
      brandName: brandName ?? this.brandName,
      tagline: tagline ?? this.tagline,
      accentTheme: accentTheme ?? this.accentTheme,
      showSupportEmail: showSupportEmail ?? this.showSupportEmail,
      showSupportPhone: showSupportPhone ?? this.showSupportPhone,
      showSectionsSummary: showSectionsSummary ?? this.showSectionsSummary,
      compactCards: compactCards ?? this.compactCards,
      enablePreviewAnimations:
          enablePreviewAnimations ?? this.enablePreviewAnimations,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'brandName': brandName,
      'tagline': tagline,
      'accentTheme': accentTheme,
      'showSupportEmail': showSupportEmail,
      'showSupportPhone': showSupportPhone,
      'showSectionsSummary': showSectionsSummary,
      'compactCards': compactCards,
      'enablePreviewAnimations': enablePreviewAnimations,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      brandName: json['brandName'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      accentTheme: json['accentTheme'] as String? ?? '',
      showSupportEmail: json['showSupportEmail'] as bool? ?? false,
      showSupportPhone: json['showSupportPhone'] as bool? ?? false,
      showSectionsSummary: json['showSectionsSummary'] as bool? ?? false,
      compactCards: json['compactCards'] as bool? ?? false,
      enablePreviewAnimations:
          json['enablePreviewAnimations'] as bool? ?? false,
    );
  }
}

class MediaItem {
  const MediaItem({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.type,
    this.originalFileName = '',
    this.storagePath = '',
    this.downloadUrl = '',
    this.contentType = '',
    this.sizeBytes = 0,
    this.width,
    this.height,
    this.uploadedByUserId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String assetPath;
  final String type;
  final String originalFileName;
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final int? width;
  final int? height;
  final String uploadedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaItem copyWith({
    String? id,
    String? name,
    String? assetPath,
    String? type,
    String? originalFileName,
    String? storagePath,
    String? downloadUrl,
    String? contentType,
    int? sizeBytes,
    int? width,
    int? height,
    String? uploadedByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      name: name ?? this.name,
      assetPath: assetPath ?? this.assetPath,
      type: type ?? this.type,
      originalFileName: originalFileName ?? this.originalFileName,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'assetPath': assetPath,
      'type': type,
      'originalFileName': originalFileName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'width': width,
      'height': height,
      'uploadedByUserId': uploadedByUserId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assetPath: json['assetPath'] as String? ?? '',
      type: json['type'] as String? ?? '',
      originalFileName: json['originalFileName'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      uploadedByUserId: json['uploadedByUserId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class MediaUploadPayload {
  const MediaUploadPayload({
    required this.name,
    required this.originalFileName,
    required this.bytes,
    required this.contentType,
    required this.type,
    this.width,
    this.height,
  });

  final String name;
  final String originalFileName;
  final List<int> bytes;
  final String contentType;
  final String type;
  final int? width;
  final int? height;
}

class LandingDraft {
  const LandingDraft({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.sections,
    required this.hero,
    required this.features,
    required this.categories,
    required this.showcaseItems,
    required this.faqItems,
    required this.footer,
    required this.appLinks,
    required this.settings,
    required this.mediaItems,
  });

  final String id;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LandingSectionState> sections;
  final HeroContent hero;
  final List<FeatureItem> features;
  final List<CategoryItem> categories;
  final List<ShowcaseItem> showcaseItems;
  final List<FAQItem> faqItems;
  final FooterContent footer;
  final AppLinks appLinks;
  final Settings settings;
  final List<MediaItem> mediaItems;

  LandingDraft copyWith({
    String? id,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LandingSectionState>? sections,
    HeroContent? hero,
    List<FeatureItem>? features,
    List<CategoryItem>? categories,
    List<ShowcaseItem>? showcaseItems,
    List<FAQItem>? faqItems,
    FooterContent? footer,
    AppLinks? appLinks,
    Settings? settings,
    List<MediaItem>? mediaItems,
  }) {
    return LandingDraft(
      id: id ?? this.id,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sections: sections ?? this.sections,
      hero: hero ?? this.hero,
      features: features ?? this.features,
      categories: categories ?? this.categories,
      showcaseItems: showcaseItems ?? this.showcaseItems,
      faqItems: faqItems ?? this.faqItems,
      footer: footer ?? this.footer,
      appLinks: appLinks ?? this.appLinks,
      settings: settings ?? this.settings,
      mediaItems: mediaItems ?? this.mediaItems,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sections': sections
          .map((LandingSectionState item) => item.toJson())
          .toList(),
      'hero': hero.toJson(),
      'features': features.map((FeatureItem item) => item.toJson()).toList(),
      'categories': categories
          .map((CategoryItem item) => item.toJson())
          .toList(),
      'showcaseItems': showcaseItems
          .map((ShowcaseItem item) => item.toJson())
          .toList(),
      'faqItems': faqItems.map((FAQItem item) => item.toJson()).toList(),
      'footer': footer.toJson(),
      'appLinks': appLinks.toJson(),
      'settings': settings.toJson(),
      'mediaItems': mediaItems.map((MediaItem item) => item.toJson()).toList(),
    };
  }

  factory LandingDraft.fromJson(Map<String, dynamic> json) {
    return LandingDraft(
      id: json['id'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sections: (json['sections'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) => LandingSectionState.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      hero: HeroContent.fromJson(
        Map<String, dynamic>.from(json['hero'] as Map? ?? <String, dynamic>{}),
      ),
      features: (json['features'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                FeatureItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                CategoryItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      showcaseItems: (json['showcaseItems'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                ShowcaseItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      faqItems: (json['faqItems'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                FAQItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      footer: FooterContent.fromJson(
        Map<String, dynamic>.from(
          json['footer'] as Map? ?? <String, dynamic>{},
        ),
      ),
      appLinks: AppLinks.fromJson(
        Map<String, dynamic>.from(
          json['appLinks'] as Map? ?? <String, dynamic>{},
        ),
      ),
      settings: Settings.fromJson(
        Map<String, dynamic>.from(
          json['settings'] as Map? ?? <String, dynamic>{},
        ),
      ),
      mediaItems: (json['mediaItems'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                MediaItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class PublishedLanding {
  const PublishedLanding({
    required this.id,
    required this.sourceDraftId,
    required this.sourceDraftVersion,
    required this.sourceDraftUpdatedAt,
    required this.publishedByUserId,
    required this.version,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.sections,
    required this.hero,
    required this.features,
    required this.categories,
    required this.showcaseItems,
    required this.faqItems,
    required this.footer,
    required this.appLinks,
    required this.settings,
    required this.mediaItems,
  });

  final String id;
  final String sourceDraftId;
  final int sourceDraftVersion;
  final DateTime sourceDraftUpdatedAt;
  final String publishedByUserId;
  final int version;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LandingSectionState> sections;
  final HeroContent hero;
  final List<FeatureItem> features;
  final List<CategoryItem> categories;
  final List<ShowcaseItem> showcaseItems;
  final List<FAQItem> faqItems;
  final FooterContent footer;
  final AppLinks appLinks;
  final Settings settings;
  final List<MediaItem> mediaItems;

  PublishedLanding copyWith({
    String? id,
    String? sourceDraftId,
    int? sourceDraftVersion,
    DateTime? sourceDraftUpdatedAt,
    String? publishedByUserId,
    int? version,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LandingSectionState>? sections,
    HeroContent? hero,
    List<FeatureItem>? features,
    List<CategoryItem>? categories,
    List<ShowcaseItem>? showcaseItems,
    List<FAQItem>? faqItems,
    FooterContent? footer,
    AppLinks? appLinks,
    Settings? settings,
    List<MediaItem>? mediaItems,
  }) {
    return PublishedLanding(
      id: id ?? this.id,
      sourceDraftId: sourceDraftId ?? this.sourceDraftId,
      sourceDraftVersion: sourceDraftVersion ?? this.sourceDraftVersion,
      sourceDraftUpdatedAt: sourceDraftUpdatedAt ?? this.sourceDraftUpdatedAt,
      publishedByUserId: publishedByUserId ?? this.publishedByUserId,
      version: version ?? this.version,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sections: sections ?? this.sections,
      hero: hero ?? this.hero,
      features: features ?? this.features,
      categories: categories ?? this.categories,
      showcaseItems: showcaseItems ?? this.showcaseItems,
      faqItems: faqItems ?? this.faqItems,
      footer: footer ?? this.footer,
      appLinks: appLinks ?? this.appLinks,
      settings: settings ?? this.settings,
      mediaItems: mediaItems ?? this.mediaItems,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sourceDraftId': sourceDraftId,
      'sourceDraftVersion': sourceDraftVersion,
      'sourceDraftUpdatedAt': sourceDraftUpdatedAt.toIso8601String(),
      'publishedByUserId': publishedByUserId,
      'version': version,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sections': sections
          .map((LandingSectionState item) => item.toJson())
          .toList(),
      'hero': hero.toJson(),
      'features': features.map((FeatureItem item) => item.toJson()).toList(),
      'categories': categories
          .map((CategoryItem item) => item.toJson())
          .toList(),
      'showcaseItems': showcaseItems
          .map((ShowcaseItem item) => item.toJson())
          .toList(),
      'faqItems': faqItems.map((FAQItem item) => item.toJson()).toList(),
      'footer': footer.toJson(),
      'appLinks': appLinks.toJson(),
      'settings': settings.toJson(),
      'mediaItems': mediaItems.map((MediaItem item) => item.toJson()).toList(),
    };
  }

  factory PublishedLanding.fromJson(Map<String, dynamic> json) {
    return PublishedLanding(
      id: json['id'] as String? ?? '',
      sourceDraftId: json['sourceDraftId'] as String? ?? '',
      sourceDraftVersion: (json['sourceDraftVersion'] as num?)?.toInt() ?? 1,
      sourceDraftUpdatedAt:
          DateTime.tryParse(json['sourceDraftUpdatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      publishedByUserId: json['publishedByUserId'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      publishedAt:
          DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sections: (json['sections'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) => LandingSectionState.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      hero: HeroContent.fromJson(
        Map<String, dynamic>.from(json['hero'] as Map? ?? <String, dynamic>{}),
      ),
      features: (json['features'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                FeatureItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                CategoryItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      showcaseItems: (json['showcaseItems'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                ShowcaseItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      faqItems: (json['faqItems'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                FAQItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      footer: FooterContent.fromJson(
        Map<String, dynamic>.from(
          json['footer'] as Map? ?? <String, dynamic>{},
        ),
      ),
      appLinks: AppLinks.fromJson(
        Map<String, dynamic>.from(
          json['appLinks'] as Map? ?? <String, dynamic>{},
        ),
      ),
      settings: Settings.fromJson(
        Map<String, dynamic>.from(
          json['settings'] as Map? ?? <String, dynamic>{},
        ),
      ),
      mediaItems: (json['mediaItems'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                MediaItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class LandingVersionSnapshot {
  const LandingVersionSnapshot({
    required this.versionId,
    required this.versionNumber,
    required this.snapshot,
    required this.sourceDraftId,
    required this.sourceDraftVersion,
    required this.publishedAt,
    required this.publishedByUserId,
    required this.createdAt,
    this.label = '',
    this.note = '',
  });

  final String versionId;
  final int versionNumber;
  final String label;
  final String note;
  final PublishedLanding snapshot;
  final String sourceDraftId;
  final int sourceDraftVersion;
  final DateTime publishedAt;
  final String publishedByUserId;
  final DateTime createdAt;

  LandingVersionSnapshot copyWith({
    String? versionId,
    int? versionNumber,
    String? label,
    String? note,
    PublishedLanding? snapshot,
    String? sourceDraftId,
    int? sourceDraftVersion,
    DateTime? publishedAt,
    String? publishedByUserId,
    DateTime? createdAt,
  }) {
    return LandingVersionSnapshot(
      versionId: versionId ?? this.versionId,
      versionNumber: versionNumber ?? this.versionNumber,
      label: label ?? this.label,
      note: note ?? this.note,
      snapshot: snapshot ?? this.snapshot,
      sourceDraftId: sourceDraftId ?? this.sourceDraftId,
      sourceDraftVersion: sourceDraftVersion ?? this.sourceDraftVersion,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedByUserId: publishedByUserId ?? this.publishedByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'versionId': versionId,
      'versionNumber': versionNumber,
      'label': label,
      'note': note,
      'sourceDraftId': sourceDraftId,
      'sourceDraftVersion': sourceDraftVersion,
      'publishedAt': publishedAt.toIso8601String(),
      'publishedByUserId': publishedByUserId,
      'createdAt': createdAt.toIso8601String(),
      'snapshot': snapshot.toJson(),
    };
  }

  factory LandingVersionSnapshot.fromJson(Map<String, dynamic> json) {
    return LandingVersionSnapshot(
      versionId: json['versionId'] as String? ?? '',
      versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
      note: json['note'] as String? ?? '',
      snapshot: PublishedLanding.fromJson(
        Map<String, dynamic>.from(
          json['snapshot'] as Map? ?? <String, dynamic>{},
        ),
      ),
      sourceDraftId: json['sourceDraftId'] as String? ?? '',
      sourceDraftVersion: (json['sourceDraftVersion'] as num?)?.toInt() ?? 0,
      publishedAt:
          DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      publishedByUserId: json['publishedByUserId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
