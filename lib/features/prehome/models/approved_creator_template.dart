import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';

class PoliticalProtocolSlot {
  const PoliticalProtocolSlot({
    required this.x,
    required this.y,
    required this.scale,
  });

  final double x;
  final double y;
  final double scale;

  Map<String, double> toJson() => <String, double>{
    'x': x,
    'y': y,
    'scale': scale,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PoliticalProtocolSlot &&
            other.x == x &&
            other.y == y &&
            other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(x, y, scale);
}

const List<PoliticalProtocolSlot> defaultPoliticalProtocolSlots =
    <PoliticalProtocolSlot>[
      PoliticalProtocolSlot(x: 28, y: 8, scale: 85),
      PoliticalProtocolSlot(x: 72, y: 8, scale: 85),
    ];

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
    this.stripWidth = 100,
    this.stripX = 50,
    this.stripBottom = 0,
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
    this.stripLayoutStyle = 'full',
    this.boardVariant = 0,
    this.photoRenderMode = 'cutout',
    this.edgeStyle = 'soft_fade',
    this.showSafeAreas = true,
    this.showPoliticalProtocol = false,
    this.politicalProtocolX = 50,
    this.politicalProtocolY = 7,
    this.politicalProtocolScale = 85,
    this.politicalProtocolSlots = defaultPoliticalProtocolSlots,
    this.politicalProtocolEnabledAtMillis = 0,
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
        stripWidth: 100,
        stripX: 50,
        stripBottom: 0,
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
        stripLayoutStyle: 'full',
        boardVariant: 0,
        photoRenderMode: 'cutout',
        edgeStyle: 'soft_fade',
        showSafeAreas: true,
        showPoliticalProtocol: false,
        politicalProtocolX: 50,
        politicalProtocolY: 7,
        politicalProtocolScale: 85,
        politicalProtocolSlots: defaultPoliticalProtocolSlots,
        politicalProtocolEnabledAtMillis: 0,
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
  final double stripWidth;
  final double stripX;
  final double stripBottom;
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
  final String stripLayoutStyle;
  final int boardVariant;
  final String photoRenderMode;
  final String edgeStyle;
  final bool showSafeAreas;
  final bool showPoliticalProtocol;
  final double politicalProtocolX;
  final double politicalProtocolY;
  final double politicalProtocolScale;
  final List<PoliticalProtocolSlot> politicalProtocolSlots;
  final int politicalProtocolEnabledAtMillis;

  bool get hasPoliticalProtocolLayout =>
      showPoliticalProtocol && politicalProtocolSlots.isNotEmpty;

  bool get canShowPoliticalProtocol =>
      showPoliticalProtocol && politicalProtocolEnabledAtMillis > 0;

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
            other.stripWidth == stripWidth &&
            other.stripX == stripX &&
            other.stripBottom == stripBottom &&
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
            other.stripLayoutStyle == stripLayoutStyle &&
            other.boardVariant == boardVariant &&
            other.photoRenderMode == photoRenderMode &&
            other.edgeStyle == edgeStyle &&
            other.showSafeAreas == showSafeAreas &&
            other.showPoliticalProtocol == showPoliticalProtocol &&
            other.politicalProtocolX == politicalProtocolX &&
            other.politicalProtocolY == politicalProtocolY &&
            other.politicalProtocolScale == politicalProtocolScale &&
            other.politicalProtocolEnabledAtMillis ==
                politicalProtocolEnabledAtMillis &&
            _slotListsEqual(
              other.politicalProtocolSlots,
              politicalProtocolSlots,
            );
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
    stripWidth,
    stripX,
    stripBottom,
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
    stripLayoutStyle,
    boardVariant,
    photoRenderMode,
    edgeStyle,
    showSafeAreas,
    showPoliticalProtocol,
    politicalProtocolX,
    politicalProtocolY,
    politicalProtocolScale,
    politicalProtocolEnabledAtMillis,
    ...politicalProtocolSlots,
  ]);
}

bool _slotListsEqual(
  List<PoliticalProtocolSlot> left,
  List<PoliticalProtocolSlot> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
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
    this.publishAtMillis = 0,
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
  final int publishAtMillis;
  final CreatorPosterPersonalization personalizationConfig;
  final String creatorPublicId;
  final EditorPageConfig? pageConfig;
}
