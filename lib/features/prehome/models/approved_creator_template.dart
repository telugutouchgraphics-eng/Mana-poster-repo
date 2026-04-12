class CreatorPosterPersonalization {
  const CreatorPosterPersonalization({
    required this.photoShape,
    required this.photoX,
    required this.photoY,
    required this.photoScale,
    required this.nameX,
    required this.nameY,
    required this.showBottomStrip,
    required this.stripHeight,
    required this.showWhatsapp,
    required this.sampleName,
    this.photoRenderMode = 'cutout',
    this.edgeStyle = 'soft_fade',
    this.showSafeAreas = true,
  });

  static const CreatorPosterPersonalization defaults =
      CreatorPosterPersonalization(
        photoShape: 'circle',
        photoX: 78,
        photoY: 42,
        photoScale: 44,
        nameX: 50,
        nameY: 82,
        showBottomStrip: true,
        stripHeight: 16,
        showWhatsapp: true,
        sampleName: 'User Name',
        photoRenderMode: 'cutout',
        edgeStyle: 'soft_fade',
        showSafeAreas: true,
      );

  final String photoShape;
  final double photoX;
  final double photoY;
  final double photoScale;
  final double nameX;
  final double nameY;
  final bool showBottomStrip;
  final double stripHeight;
  final bool showWhatsapp;
  final String sampleName;
  final String photoRenderMode;
  final String edgeStyle;
  final bool showSafeAreas;
}

class ApprovedCreatorTemplate {
  const ApprovedCreatorTemplate({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryLabel,
    required this.createdAtMillis,
    required this.personalizationConfig,
    this.creatorPublicId = '',
  });

  final String id;
  final String title;
  final String imageUrl;
  final String categoryId;
  final String categoryLabel;
  final int createdAtMillis;
  final CreatorPosterPersonalization personalizationConfig;
  final String creatorPublicId;
}
