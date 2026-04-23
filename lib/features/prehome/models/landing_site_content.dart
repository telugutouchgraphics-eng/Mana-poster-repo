class LandingSitePoster {
  const LandingSitePoster({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.imageUrl,
    required this.storagePath,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final String title;
  final String imageUrl;
  final String storagePath;
  final int sortOrder;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'imageUrl': imageUrl,
      'storagePath': storagePath,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
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
  });

  final String bannerImageUrl;
  final String bannerStoragePath;
  final String sectionMediaUrl;
  final String sectionMediaStoragePath;
  final String sectionMediaType;
  final List<LandingSitePoster> posters;
  final DateTime updatedAt;

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
      'posters': posters.map((LandingSitePoster item) => item.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LandingSiteContent.fromJson(Map<String, dynamic> json) {
    return LandingSiteContent(
      bannerImageUrl: json['bannerImageUrl'] as String? ?? '',
      bannerStoragePath: json['bannerStoragePath'] as String? ?? '',
      sectionMediaUrl: json['sectionMediaUrl'] as String? ?? '',
      sectionMediaStoragePath:
          json['sectionMediaStoragePath'] as String? ?? '',
      sectionMediaType: json['sectionMediaType'] as String? ?? '',
      posters: (json['posters'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                LandingSitePoster.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList()
        ..sort(
          (LandingSitePoster a, LandingSitePoster b) =>
              a.sortOrder.compareTo(b.sortOrder),
        ),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
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
    );
  }
}
