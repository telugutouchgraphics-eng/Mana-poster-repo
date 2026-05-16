class LandingSitePoster {
  const LandingSitePoster({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.imageUrl,
    required this.storagePath,
    required this.sortOrder,
    required this.createdAt,
    this.altText = '',
    this.isVisible = true,
  });

  final String id;
  final String categoryId;
  final String title;
  final String imageUrl;
  final String storagePath;
  final int sortOrder;
  final DateTime createdAt;
  final String altText;
  final bool isVisible;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'imageUrl': imageUrl,
      'storagePath': storagePath,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'altText': altText,
      'isVisible': isVisible,
    };
  }

  factory LandingSitePoster.fromJson(Map<String, dynamic> json) {
    return LandingSitePoster(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      altText: json['altText'] as String? ?? '',
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }

  LandingSitePoster copyWith({
    String? title,
    String? altText,
    int? sortOrder,
    bool? isVisible,
  }) {
    return LandingSitePoster(
      id: id,
      categoryId: categoryId,
      title: title ?? this.title,
      imageUrl: imageUrl,
      storagePath: storagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      altText: altText ?? this.altText,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class LandingSiteContent {
  const LandingSiteContent({
    required this.bannerImageUrl,
    required this.bannerStoragePath,
    required this.sectionMediaUrl,
    required this.sectionMediaStoragePath,
    required this.sectionMediaType,
    required this.posters,
    required this.updatedAt,
    this.heroLine1 = 'Telugu Posters',
    this.heroLine2 = 'Ready to Share',
    this.heroBody1 =
        'Browse festival, devotional, birthday, quote and daily greeting posters.',
    this.heroBody2 = 'Use saved profile details for consistent poster output.',
    this.heroBody3 = 'Download or share polished posters in seconds.',
    this.primaryCtaLabel = 'Install App',
    this.secondaryCtaLabel = 'Browse Posters',
    this.playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.manaposter.app',
    this.featureTitle = 'A faster way to create share-ready posters',
    this.featureSubtitle =
        'Choose a category, select a poster, apply saved profile details and share quickly.',
    this.installTitle = 'Install Mana Poster Ai',
    this.installBody =
        'Browse ready-made Telugu posters, use saved profile details and share quickly every day.',
    this.seoTitle = 'Mana Poster Ai - Telugu Poster Maker Android App',
    this.seoDescription =
        'Create and share Telugu posters quickly with ready-made poster collections.',
    this.seoKeywords =
        'Mana Poster Ai, Telugu poster maker, festival poster app, devotional poster app',
  });

  final String bannerImageUrl;
  final String bannerStoragePath;
  final String sectionMediaUrl;
  final String sectionMediaStoragePath;
  final String sectionMediaType;
  final List<LandingSitePoster> posters;
  final DateTime updatedAt;
  final String heroLine1;
  final String heroLine2;
  final String heroBody1;
  final String heroBody2;
  final String heroBody3;
  final String primaryCtaLabel;
  final String secondaryCtaLabel;
  final String playStoreUrl;
  final String featureTitle;
  final String featureSubtitle;
  final String installTitle;
  final String installBody;
  final String seoTitle;
  final String seoDescription;
  final String seoKeywords;

  factory LandingSiteContent.empty() {
    return LandingSiteContent(
      bannerImageUrl: '',
      bannerStoragePath: '',
      sectionMediaUrl: '',
      sectionMediaStoragePath: '',
      sectionMediaType: '',
      posters: const <LandingSitePoster>[],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bannerImageUrl': bannerImageUrl,
      'bannerStoragePath': bannerStoragePath,
      'sectionMediaUrl': sectionMediaUrl,
      'sectionMediaStoragePath': sectionMediaStoragePath,
      'sectionMediaType': sectionMediaType,
      'posters': posters
          .map((LandingSitePoster item) => item.toJson())
          .toList(),
      'updatedAt': updatedAt.toIso8601String(),
      'heroLine1': heroLine1,
      'heroLine2': heroLine2,
      'heroBody1': heroBody1,
      'heroBody2': heroBody2,
      'heroBody3': heroBody3,
      'primaryCtaLabel': primaryCtaLabel,
      'secondaryCtaLabel': secondaryCtaLabel,
      'playStoreUrl': playStoreUrl,
      'featureTitle': featureTitle,
      'featureSubtitle': featureSubtitle,
      'installTitle': installTitle,
      'installBody': installBody,
      'seoTitle': seoTitle,
      'seoDescription': seoDescription,
      'seoKeywords': seoKeywords,
    };
  }

  factory LandingSiteContent.fromJson(Map<String, dynamic> json) {
    return LandingSiteContent(
      bannerImageUrl: json['bannerImageUrl'] as String? ?? '',
      bannerStoragePath: json['bannerStoragePath'] as String? ?? '',
      sectionMediaUrl: json['sectionMediaUrl'] as String? ?? '',
      sectionMediaStoragePath: json['sectionMediaStoragePath'] as String? ?? '',
      sectionMediaType: json['sectionMediaType'] as String? ?? '',
      posters:
          (json['posters'] as List<dynamic>? ?? <dynamic>[])
              .map(
                (dynamic item) => LandingSitePoster.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
            ..sort(
              (LandingSitePoster a, LandingSitePoster b) =>
                  a.sortOrder.compareTo(b.sortOrder),
            ),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      heroLine1: json['heroLine1'] as String? ?? 'Telugu Posters',
      heroLine2: json['heroLine2'] as String? ?? 'Ready to Share',
      heroBody1:
          json['heroBody1'] as String? ??
          'Browse festival, devotional, birthday, quote and daily greeting posters.',
      heroBody2:
          json['heroBody2'] as String? ??
          'Use saved profile details for consistent poster output.',
      heroBody3:
          json['heroBody3'] as String? ??
          'Download or share polished posters in seconds.',
      primaryCtaLabel: json['primaryCtaLabel'] as String? ?? 'Install App',
      secondaryCtaLabel:
          json['secondaryCtaLabel'] as String? ?? 'Browse Posters',
      playStoreUrl:
          json['playStoreUrl'] as String? ??
          'https://play.google.com/store/apps/details?id=com.manaposter.app',
      featureTitle:
          json['featureTitle'] as String? ??
          'A faster way to create share-ready posters',
      featureSubtitle:
          json['featureSubtitle'] as String? ??
          'Choose a category, select a poster, apply saved profile details and share quickly.',
      installTitle: json['installTitle'] as String? ?? 'Install Mana Poster Ai',
      installBody:
          json['installBody'] as String? ??
          'Browse ready-made Telugu posters, use saved profile details and share quickly every day.',
      seoTitle:
          json['seoTitle'] as String? ??
          'Mana Poster Ai - Telugu Poster Maker Android App',
      seoDescription:
          json['seoDescription'] as String? ??
          'Create and share Telugu posters quickly with ready-made poster collections.',
      seoKeywords:
          json['seoKeywords'] as String? ??
          'Mana Poster Ai, Telugu poster maker, festival poster app, devotional poster app',
    );
  }

  LandingSiteContent copyWith({
    String? bannerImageUrl,
    String? bannerStoragePath,
    String? sectionMediaUrl,
    String? sectionMediaStoragePath,
    String? sectionMediaType,
    List<LandingSitePoster>? posters,
    DateTime? updatedAt,
    String? heroLine1,
    String? heroLine2,
    String? heroBody1,
    String? heroBody2,
    String? heroBody3,
    String? primaryCtaLabel,
    String? secondaryCtaLabel,
    String? playStoreUrl,
    String? featureTitle,
    String? featureSubtitle,
    String? installTitle,
    String? installBody,
    String? seoTitle,
    String? seoDescription,
    String? seoKeywords,
  }) {
    return LandingSiteContent(
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      bannerStoragePath: bannerStoragePath ?? this.bannerStoragePath,
      sectionMediaUrl: sectionMediaUrl ?? this.sectionMediaUrl,
      sectionMediaStoragePath:
          sectionMediaStoragePath ?? this.sectionMediaStoragePath,
      sectionMediaType: sectionMediaType ?? this.sectionMediaType,
      posters: posters ?? this.posters,
      updatedAt: updatedAt ?? this.updatedAt,
      heroLine1: heroLine1 ?? this.heroLine1,
      heroLine2: heroLine2 ?? this.heroLine2,
      heroBody1: heroBody1 ?? this.heroBody1,
      heroBody2: heroBody2 ?? this.heroBody2,
      heroBody3: heroBody3 ?? this.heroBody3,
      primaryCtaLabel: primaryCtaLabel ?? this.primaryCtaLabel,
      secondaryCtaLabel: secondaryCtaLabel ?? this.secondaryCtaLabel,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      featureTitle: featureTitle ?? this.featureTitle,
      featureSubtitle: featureSubtitle ?? this.featureSubtitle,
      installTitle: installTitle ?? this.installTitle,
      installBody: installBody ?? this.installBody,
      seoTitle: seoTitle ?? this.seoTitle,
      seoDescription: seoDescription ?? this.seoDescription,
      seoKeywords: seoKeywords ?? this.seoKeywords,
    );
  }
}

