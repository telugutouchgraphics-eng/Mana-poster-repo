import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';

class CreatorPosterPersonalization {
  const CreatorPosterPersonalization({
    required this.photoShape,
    required this.photoX,
    required this.photoY,
    required this.photoScale,
    this.photoAnimation = 'none',
    this.showVideoExtraPhoto = false,
    this.videoExtraPhotoShape = 'circle',
    this.videoExtraPhotoRenderMode = 'cutout',
    this.videoExtraPhotoEdgeStyle = 'soft_fade',
    this.videoExtraPhotoAnimation = 'none',
    this.videoExtraPhotoX = 24,
    this.videoExtraPhotoY = 44,
    this.videoExtraPhotoScale = 28,
    required this.nameX,
    required this.nameY,
    required this.showBottomStrip,
    required this.stripHeight,
    required this.showWhatsapp,
    required this.sampleName,
    this.nameScale = 100,
    this.showStyledNameStrip = false,
    this.showStyledDesignationStrip = false,
    this.sampleDesignation = '',
    this.designationScale = 100,
    this.phoneScale = 100,
    this.nameStripColor = '#0F172A',
    this.designationStripColor = '#1E293B',
    this.boardVariant = 0,
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
        photoAnimation: 'none',
        showVideoExtraPhoto: false,
        videoExtraPhotoShape: 'circle',
        videoExtraPhotoRenderMode: 'cutout',
        videoExtraPhotoEdgeStyle: 'soft_fade',
        videoExtraPhotoAnimation: 'none',
        videoExtraPhotoX: 24,
        videoExtraPhotoY: 44,
        videoExtraPhotoScale: 28,
        nameX: 50,
        nameY: 82,
        showBottomStrip: true,
        stripHeight: 16,
        showWhatsapp: true,
        sampleName: 'User Name',
        nameScale: 100,
        showStyledNameStrip: false,
        showStyledDesignationStrip: false,
        sampleDesignation: '',
        designationScale: 100,
        phoneScale: 100,
        nameStripColor: '#0F172A',
        designationStripColor: '#1E293B',
        boardVariant: 0,
        photoRenderMode: 'cutout',
        edgeStyle: 'soft_fade',
        showSafeAreas: true,
      );

  final String photoShape;
  final double photoX;
  final double photoY;
  final double photoScale;
  final String photoAnimation;
  final bool showVideoExtraPhoto;
  final String videoExtraPhotoShape;
  final String videoExtraPhotoRenderMode;
  final String videoExtraPhotoEdgeStyle;
  final String videoExtraPhotoAnimation;
  final double videoExtraPhotoX;
  final double videoExtraPhotoY;
  final double videoExtraPhotoScale;
  final double nameX;
  final double nameY;
  final bool showBottomStrip;
  final double stripHeight;
  final bool showWhatsapp;
  final String sampleName;
  final double nameScale;
  final bool showStyledNameStrip;
  final bool showStyledDesignationStrip;
  final String sampleDesignation;
  final double designationScale;
  final double phoneScale;
  final String nameStripColor;
  final String designationStripColor;
  final int boardVariant;
  final String photoRenderMode;
  final String edgeStyle;
  final bool showSafeAreas;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CreatorPosterPersonalization &&
            other.photoShape == photoShape &&
            other.photoX == photoX &&
            other.photoY == photoY &&
            other.photoScale == photoScale &&
            other.photoAnimation == photoAnimation &&
            other.showVideoExtraPhoto == showVideoExtraPhoto &&
            other.videoExtraPhotoShape == videoExtraPhotoShape &&
            other.videoExtraPhotoRenderMode == videoExtraPhotoRenderMode &&
            other.videoExtraPhotoEdgeStyle == videoExtraPhotoEdgeStyle &&
            other.videoExtraPhotoAnimation == videoExtraPhotoAnimation &&
            other.videoExtraPhotoX == videoExtraPhotoX &&
            other.videoExtraPhotoY == videoExtraPhotoY &&
            other.videoExtraPhotoScale == videoExtraPhotoScale &&
            other.nameX == nameX &&
            other.nameY == nameY &&
            other.showBottomStrip == showBottomStrip &&
            other.stripHeight == stripHeight &&
            other.showWhatsapp == showWhatsapp &&
            other.sampleName == sampleName &&
            other.nameScale == nameScale &&
            other.showStyledNameStrip == showStyledNameStrip &&
            other.showStyledDesignationStrip == showStyledDesignationStrip &&
            other.sampleDesignation == sampleDesignation &&
            other.designationScale == designationScale &&
            other.phoneScale == phoneScale &&
            other.nameStripColor == nameStripColor &&
            other.designationStripColor == designationStripColor &&
            other.boardVariant == boardVariant &&
            other.photoRenderMode == photoRenderMode &&
            other.edgeStyle == edgeStyle &&
            other.showSafeAreas == showSafeAreas;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    photoShape,
    photoX,
    photoY,
    photoScale,
    photoAnimation,
    showVideoExtraPhoto,
    videoExtraPhotoShape,
    videoExtraPhotoRenderMode,
    videoExtraPhotoEdgeStyle,
    videoExtraPhotoAnimation,
    videoExtraPhotoX,
    videoExtraPhotoY,
    videoExtraPhotoScale,
    nameX,
    nameY,
    showBottomStrip,
    stripHeight,
    showWhatsapp,
    sampleName,
    nameScale,
    showStyledNameStrip,
    showStyledDesignationStrip,
    sampleDesignation,
    designationScale,
    phoneScale,
    nameStripColor,
    designationStripColor,
    boardVariant,
    photoRenderMode,
    edgeStyle,
    showSafeAreas,
  ]);
}

class ApprovedCreatorTemplate {
  const ApprovedCreatorTemplate({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.imageStoragePath = '',
    this.thumbnailStoragePath = '',
    this.thumbnailUrl = '',
    this.mediaType = 'image',
    this.videoUrl = '',
    required this.categoryId,
    required this.categoryLabel,
    this.regionId = '',
    required this.createdAtMillis,
    required this.personalizationConfig,
    this.creatorPublicId = '',
    this.pageConfig,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String imageStoragePath;
  final String thumbnailStoragePath;
  final String thumbnailUrl;
  final String mediaType;
  final String videoUrl;
  final String categoryId;
  final String categoryLabel;
  final String regionId;
  final int createdAtMillis;
  final CreatorPosterPersonalization personalizationConfig;
  final String creatorPublicId;
  final EditorPageConfig? pageConfig;
}
