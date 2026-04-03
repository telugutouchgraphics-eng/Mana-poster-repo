import 'package:flutter/material.dart';

enum StageBackgroundType { solid, gradient, image }

enum StageBackgroundImageFit { fit, fill, stretch }

enum LayerBlendModeOption { normal, multiply, screen, overlay }

enum BorderStylePreset { solid, gradient, dashed }

enum BorderFrameSection { border, frame }

enum BorderFrameTarget { selectedPhoto, fullPoster }

enum FramePresetCategory { devotional, floral, birthday, wedding, festive }

class BorderDecorationConfig {
  const BorderDecorationConfig({
    this.style = BorderStylePreset.solid,
    this.solidColor = const Color(0xFFFFFFFF),
    this.gradientColors = const <Color>[Color(0xFFFFE082), Color(0xFFF59E0B)],
    this.thickness = 0,
    this.cornerRadius = 0.08,
    this.opacity = 1,
    this.shadow = 0,
  });

  static const BorderDecorationConfig none = BorderDecorationConfig(
    thickness: 0,
  );

  final BorderStylePreset style;
  final Color solidColor;
  final List<Color> gradientColors;
  final double thickness;
  final double cornerRadius;
  final double opacity;
  final double shadow;

  bool get isVisible => thickness > 0.0001;

  BorderDecorationConfig copyWith({
    BorderStylePreset? style,
    Color? solidColor,
    List<Color>? gradientColors,
    double? thickness,
    double? cornerRadius,
    double? opacity,
    double? shadow,
  }) {
    return BorderDecorationConfig(
      style: style ?? this.style,
      solidColor: solidColor ?? this.solidColor,
      gradientColors: gradientColors ?? this.gradientColors,
      thickness: thickness ?? this.thickness,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      opacity: opacity ?? this.opacity,
      shadow: shadow ?? this.shadow,
    );
  }
}

class FramePresetConfig {
  const FramePresetConfig({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
    this.accentColor = const Color(0xFFFFFFFF),
    this.opacity = 0.8,
    this.size = 0.12,
  });

  final String id;
  final String name;
  final FramePresetCategory category;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final double opacity;
  final double size;

  FramePresetConfig copyWith({
    String? id,
    String? name,
    FramePresetCategory? category,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    double? opacity,
    double? size,
  }) {
    return FramePresetConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      opacity: opacity ?? this.opacity,
      size: size ?? this.size,
    );
  }
}

class FrameDecorationConfig {
  const FrameDecorationConfig({
    this.presetId,
    this.opacity = 0,
    this.size = 0.12,
  });

  static const FrameDecorationConfig none = FrameDecorationConfig();

  final String? presetId;
  final double opacity;
  final double size;

  bool get isVisible => presetId != null && opacity > 0.0001;

  FrameDecorationConfig copyWith({
    String? presetId,
    bool clearPresetId = false,
    double? opacity,
    double? size,
  }) {
    return FrameDecorationConfig(
      presetId: clearPresetId ? null : (presetId ?? this.presetId),
      opacity: opacity ?? this.opacity,
      size: size ?? this.size,
    );
  }
}

class DecorationStyleConfig {
  const DecorationStyleConfig({
    this.border = BorderDecorationConfig.none,
    this.frame = FrameDecorationConfig.none,
  });

  static const DecorationStyleConfig none = DecorationStyleConfig();

  final BorderDecorationConfig border;
  final FrameDecorationConfig frame;

  bool get hasDecoration => border.isVisible || frame.isVisible;

  DecorationStyleConfig copyWith({
    BorderDecorationConfig? border,
    FrameDecorationConfig? frame,
  }) {
    return DecorationStyleConfig(
      border: border ?? this.border,
      frame: frame ?? this.frame,
    );
  }
}

class LayerShadowConfig {
  const LayerShadowConfig({
    this.color = const Color(0xFF000000),
    this.blur = 0,
    this.distance = 0,
    this.opacity = 0,
  });

  static const LayerShadowConfig none = LayerShadowConfig();

  final Color color;
  final double blur;
  final double distance;
  final double opacity;

  bool get isVisible =>
      opacity > 0.0001 && (blur > 0.0001 || distance > 0.0001);

  LayerShadowConfig copyWith({
    Color? color,
    double? blur,
    double? distance,
    double? opacity,
  }) {
    return LayerShadowConfig(
      color: color ?? this.color,
      blur: blur ?? this.blur,
      distance: distance ?? this.distance,
      opacity: opacity ?? this.opacity,
    );
  }
}

class LayerVisualConfig {
  const LayerVisualConfig({
    this.opacity = 1,
    this.shadow = LayerShadowConfig.none,
    this.blendMode = LayerBlendModeOption.normal,
    this.flipX = false,
    this.flipY = false,
  });

  static const LayerVisualConfig standard = LayerVisualConfig();

  final double opacity;
  final LayerShadowConfig shadow;
  final LayerBlendModeOption blendMode;
  final bool flipX;
  final bool flipY;

  LayerVisualConfig copyWith({
    double? opacity,
    LayerShadowConfig? shadow,
    LayerBlendModeOption? blendMode,
    bool? flipX,
    bool? flipY,
  }) {
    return LayerVisualConfig(
      opacity: opacity ?? this.opacity,
      shadow: shadow ?? this.shadow,
      blendMode: blendMode ?? this.blendMode,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
    );
  }
}

enum PhotoFilterPreset {
  none,
  natural,
  warm,
  cool,
  bright,
  vintage,
  blackWhite,
  cinematic,
  soft,
  vivid,
  matte,
}

class PhotoFilterConfig {
  const PhotoFilterConfig({
    this.preset = PhotoFilterPreset.none,
    this.intensity = 0,
  });

  static const PhotoFilterConfig none = PhotoFilterConfig();

  final PhotoFilterPreset preset;
  final double intensity;

  bool get isNeutral => preset == PhotoFilterPreset.none || intensity <= 0.0001;

  PhotoFilterConfig copyWith({PhotoFilterPreset? preset, double? intensity}) {
    return PhotoFilterConfig(
      preset: preset ?? this.preset,
      intensity: intensity ?? this.intensity,
    );
  }

  List<double>? toColorMatrix() {
    if (isNeutral) {
      return null;
    }
    final baseMatrix = _presetMatrix(preset);
    if (baseMatrix == null) {
      return null;
    }
    final t = intensity.clamp(0.0, 1.0);
    final identity = _identityMatrix;
    return List<double>.generate(20, (index) {
      final identityValue = identity[index];
      final presetValue = baseMatrix[index];
      return identityValue + ((presetValue - identityValue) * t);
    });
  }

  static List<double>? _presetMatrix(PhotoFilterPreset preset) {
    switch (preset) {
      case PhotoFilterPreset.none:
        return null;
      case PhotoFilterPreset.natural:
        return <double>[
          1.02,
          0,
          0,
          0,
          4,
          0,
          1.01,
          0,
          0,
          2,
          0,
          0,
          1.00,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.warm:
        return <double>[
          1.08,
          0,
          0,
          0,
          14,
          0,
          1.01,
          0,
          0,
          3,
          0,
          0,
          0.92,
          0,
          -8,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.cool:
        return <double>[
          0.95,
          0,
          0,
          0,
          -6,
          0,
          1.00,
          0,
          0,
          0,
          0,
          0,
          1.08,
          0,
          12,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.bright:
        return <double>[
          1.08,
          0,
          0,
          0,
          16,
          0,
          1.08,
          0,
          0,
          16,
          0,
          0,
          1.08,
          0,
          16,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.vintage:
        return <double>[
          0.98,
          0.04,
          0.00,
          0,
          10,
          0.02,
          0.93,
          0.00,
          0,
          4,
          0.00,
          0.02,
          0.82,
          0,
          -10,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.blackWhite:
        return <double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.cinematic:
        return <double>[
          1.04,
          0.00,
          0.00,
          0,
          4,
          0.00,
          0.98,
          0.00,
          0,
          -2,
          0.00,
          0.00,
          0.88,
          0,
          -12,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.soft:
        return <double>[
          0.98,
          0.00,
          0.00,
          0,
          8,
          0.00,
          0.98,
          0.00,
          0,
          8,
          0.00,
          0.00,
          0.98,
          0,
          8,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.vivid:
        return <double>[
          1.14,
          -0.02,
          -0.02,
          0,
          2,
          -0.02,
          1.12,
          -0.02,
          0,
          2,
          -0.02,
          -0.02,
          1.14,
          0,
          2,
          0,
          0,
          0,
          1,
          0,
        ];
      case PhotoFilterPreset.matte:
        return <double>[
          0.92,
          0.00,
          0.00,
          0,
          12,
          0.00,
          0.92,
          0.00,
          0,
          12,
          0.00,
          0.00,
          0.92,
          0,
          12,
          0,
          0,
          0,
          1,
          0,
        ];
    }
  }

  static const List<double> _identityMatrix = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

enum RemoveBgRefineMode { erase, restore }

enum AutoMaskTemplateKind { none, subjectEllipse }

class AutoMaskTemplate {
  const AutoMaskTemplate({
    this.kind = AutoMaskTemplateKind.none,
    this.center = const Offset(0.5, 0.5),
    this.radiusX = 0.34,
    this.radiusY = 0.44,
    this.feather = 0.14,
    this.source = 'none',
    this.modelSlot = 'none',
  });

  static const AutoMaskTemplate none = AutoMaskTemplate();

  final AutoMaskTemplateKind kind;
  final Offset center;
  final double radiusX;
  final double radiusY;
  final double feather;
  final String source;
  final String modelSlot;

  bool get isActive => kind != AutoMaskTemplateKind.none;

  AutoMaskTemplate copyWith({
    AutoMaskTemplateKind? kind,
    Offset? center,
    double? radiusX,
    double? radiusY,
    double? feather,
    String? source,
    String? modelSlot,
  }) {
    return AutoMaskTemplate(
      kind: kind ?? this.kind,
      center: center ?? this.center,
      radiusX: radiusX ?? this.radiusX,
      radiusY: radiusY ?? this.radiusY,
      feather: feather ?? this.feather,
      source: source ?? this.source,
      modelSlot: modelSlot ?? this.modelSlot,
    );
  }
}

class RemoveBgStroke {
  const RemoveBgStroke({
    required this.mode,
    required this.points,
    required this.brushSize,
    required this.softness,
  });

  final RemoveBgRefineMode mode;
  final List<Offset> points;
  final double brushSize;
  final double softness;

  RemoveBgStroke copyWith({
    RemoveBgRefineMode? mode,
    List<Offset>? points,
    double? brushSize,
    double? softness,
  }) {
    return RemoveBgStroke(
      mode: mode ?? this.mode,
      points: points ?? this.points,
      brushSize: brushSize ?? this.brushSize,
      softness: softness ?? this.softness,
    );
  }
}

class RemoveBgState {
  const RemoveBgState({
    this.autoMask = AutoMaskTemplate.none,
    this.strokes = const <RemoveBgStroke>[],
    this.lastAppliedMode = 'none',
  });

  static const RemoveBgState none = RemoveBgState();

  final AutoMaskTemplate autoMask;
  final List<RemoveBgStroke> strokes;
  final String lastAppliedMode;

  bool get hasMask => autoMask.isActive || strokes.isNotEmpty;

  RemoveBgState copyWith({
    AutoMaskTemplate? autoMask,
    List<RemoveBgStroke>? strokes,
    String? lastAppliedMode,
  }) {
    return RemoveBgState(
      autoMask: autoMask ?? this.autoMask,
      strokes: strokes ?? this.strokes,
      lastAppliedMode: lastAppliedMode ?? this.lastAppliedMode,
    );
  }
}

class PhotoAdjustments {
  const PhotoAdjustments({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.tint = 0,
    this.highlights = 0,
    this.shadows = 0,
    this.sharpness = 0,
  });

  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double tint;
  final double highlights;
  final double shadows;
  final double sharpness;

  static const PhotoAdjustments neutral = PhotoAdjustments();

  bool get isNeutral =>
      brightness == 0 &&
      contrast == 0 &&
      saturation == 0 &&
      warmth == 0 &&
      tint == 0 &&
      highlights == 0 &&
      shadows == 0 &&
      sharpness == 0;

  double get softnessSigma => sharpness < 0 ? (-sharpness * 2.2) : 0;

  List<double> toColorMatrix() {
    final satStrength = (1 + (saturation * 0.85)).clamp(0.15, 1.85);
    final contrastScale = (1 + (contrast * 0.65)).clamp(0.35, 1.9);
    final warmScale = warmth * 0.2;
    final tintScale = tint * 0.14;
    final sharpScale = sharpness > 0 ? sharpness * 0.1 : 0.0;

    final rScale =
        (contrastScale * (1 + warmScale + sharpScale + (highlights * 0.06)))
            .clamp(0.2, 2.4);
    final gScale =
        (contrastScale * (1 + (tintScale * 0.6) + (sharpScale * 0.5))).clamp(
          0.2,
          2.4,
        );
    final bScale =
        (contrastScale *
                (1 -
                    warmScale -
                    tintScale +
                    (sharpScale * 0.3) -
                    (highlights * 0.04)))
            .clamp(0.2, 2.4);

    final baseOffset = (brightness * 82) + (shadows * 34) + (highlights * 20);
    final rOffset = baseOffset + (warmth * 18) + (tint * 10);
    final gOffset = baseOffset + (tint * 4);
    final bOffset = baseOffset - (warmth * 18) - (tint * 10);

    final rw = (1 - satStrength) * 0.2126;
    final gw = (1 - satStrength) * 0.7152;
    final bw = (1 - satStrength) * 0.0722;

    return <double>[
      (rw + satStrength) * rScale,
      gw * rScale,
      bw * rScale,
      0,
      rOffset,
      rw * gScale,
      (gw + satStrength) * gScale,
      bw * gScale,
      0,
      gOffset,
      rw * bScale,
      gw * bScale,
      (bw + satStrength) * bScale,
      0,
      bOffset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  PhotoAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? tint,
    double? highlights,
    double? shadows,
    double? sharpness,
  }) {
    return PhotoAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      tint: tint ?? this.tint,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      sharpness: sharpness ?? this.sharpness,
    );
  }
}

class StageBackgroundConfig {
  const StageBackgroundConfig._({
    required this.type,
    this.solidColor,
    this.gradientColors,
    this.gradientAngle = 270,
    this.imageUrl,
    this.imageFit = StageBackgroundImageFit.fill,
    this.imageBlur = 0,
    this.imageOpacity = 1,
    this.posterDecoration = DecorationStyleConfig.none,
  });

  const StageBackgroundConfig.solid(Color color)
    : this._(type: StageBackgroundType.solid, solidColor: color);

  const StageBackgroundConfig.gradient(List<Color> colors, {double angle = 270})
    : this._(
        type: StageBackgroundType.gradient,
        gradientColors: colors,
        gradientAngle: angle,
      );

  const StageBackgroundConfig.image(
    String url, {
    StageBackgroundImageFit fit = StageBackgroundImageFit.fill,
    double blur = 0,
    double opacity = 1,
  }) : this._(
         type: StageBackgroundType.image,
         imageUrl: url,
         imageFit: fit,
         imageBlur: blur,
         imageOpacity: opacity,
       );

  final StageBackgroundType type;
  final Color? solidColor;
  final List<Color>? gradientColors;
  final double gradientAngle;
  final String? imageUrl;
  final StageBackgroundImageFit imageFit;
  final double imageBlur;
  final double imageOpacity;
  final DecorationStyleConfig posterDecoration;

  StageBackgroundConfig copyWith({
    StageBackgroundType? type,
    Color? solidColor,
    List<Color>? gradientColors,
    double? gradientAngle,
    String? imageUrl,
    StageBackgroundImageFit? imageFit,
    double? imageBlur,
    double? imageOpacity,
    DecorationStyleConfig? posterDecoration,
  }) {
    return StageBackgroundConfig._(
      type: type ?? this.type,
      solidColor: solidColor ?? this.solidColor,
      gradientColors: gradientColors ?? this.gradientColors,
      gradientAngle: gradientAngle ?? this.gradientAngle,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFit: imageFit ?? this.imageFit,
      imageBlur: imageBlur ?? this.imageBlur,
      imageOpacity: imageOpacity ?? this.imageOpacity,
      posterDecoration: posterDecoration ?? this.posterDecoration,
    );
  }
}

class StageSurfacePhoto {
  const StageSurfacePhoto({
    required this.imageUrl,
    this.adjustments = PhotoAdjustments.neutral,
    this.filter = PhotoFilterConfig.none,
    this.removeBgState = RemoveBgState.none,
    this.decoration = DecorationStyleConfig.none,
    this.visuals = LayerVisualConfig.standard,
    this.isLocked = false,
  });

  final String imageUrl;
  final PhotoAdjustments adjustments;
  final PhotoFilterConfig filter;
  final RemoveBgState removeBgState;
  final DecorationStyleConfig decoration;
  final LayerVisualConfig visuals;
  final bool isLocked;

  StageSurfacePhoto copyWith({
    String? imageUrl,
    PhotoAdjustments? adjustments,
    PhotoFilterConfig? filter,
    RemoveBgState? removeBgState,
    DecorationStyleConfig? decoration,
    LayerVisualConfig? visuals,
    bool? isLocked,
  }) {
    return StageSurfacePhoto(
      imageUrl: imageUrl ?? this.imageUrl,
      adjustments: adjustments ?? this.adjustments,
      filter: filter ?? this.filter,
      removeBgState: removeBgState ?? this.removeBgState,
      decoration: decoration ?? this.decoration,
      visuals: visuals ?? this.visuals,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class StagePhotoLayer {
  const StagePhotoLayer({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.size,
    required this.offset,
    required this.scale,
    required this.rotation,
    this.cropRatio,
    this.cropTurns = 0,
    this.adjustments = PhotoAdjustments.neutral,
    this.filter = PhotoFilterConfig.none,
    this.removeBgState = RemoveBgState.none,
    this.decoration = DecorationStyleConfig.none,
    this.visuals = LayerVisualConfig.standard,
    required this.zIndex,
    this.isLocked = false,
    this.isVisible = true,
  });

  final String id;
  final String imageUrl;
  final String name;
  final Size size;
  final Offset offset;
  final double scale;
  final double rotation;
  final double? cropRatio;
  final int cropTurns;
  final PhotoAdjustments adjustments;
  final PhotoFilterConfig filter;
  final RemoveBgState removeBgState;
  final DecorationStyleConfig decoration;
  final LayerVisualConfig visuals;
  final int zIndex;
  final bool isLocked;
  final bool isVisible;

  StagePhotoLayer copyWith({
    String? id,
    String? imageUrl,
    String? name,
    Size? size,
    Offset? offset,
    double? scale,
    double? rotation,
    double? cropRatio,
    bool clearCropRatio = false,
    int? cropTurns,
    PhotoAdjustments? adjustments,
    PhotoFilterConfig? filter,
    RemoveBgState? removeBgState,
    DecorationStyleConfig? decoration,
    LayerVisualConfig? visuals,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
  }) {
    return StagePhotoLayer(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      size: size ?? this.size,
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      cropRatio: clearCropRatio ? null : (cropRatio ?? this.cropRatio),
      cropTurns: cropTurns ?? this.cropTurns,
      adjustments: adjustments ?? this.adjustments,
      filter: filter ?? this.filter,
      removeBgState: removeBgState ?? this.removeBgState,
      decoration: decoration ?? this.decoration,
      visuals: visuals ?? this.visuals,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class StageElementLayer {
  const StageElementLayer({
    required this.id,
    required this.assetId,
    required this.assetUrl,
    required this.name,
    required this.category,
    required this.size,
    required this.offset,
    required this.scale,
    required this.rotation,
    this.visuals = LayerVisualConfig.standard,
    required this.zIndex,
    this.isLocked = false,
    this.isVisible = true,
  });

  final String id;
  final String assetId;
  final String assetUrl;
  final String name;
  final String category;
  final Size size;
  final Offset offset;
  final double scale;
  final double rotation;
  final LayerVisualConfig visuals;
  final int zIndex;
  final bool isLocked;
  final bool isVisible;

  StageElementLayer copyWith({
    String? id,
    String? assetId,
    String? assetUrl,
    String? name,
    String? category,
    Size? size,
    Offset? offset,
    double? scale,
    double? rotation,
    LayerVisualConfig? visuals,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
  }) {
    return StageElementLayer(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetUrl: assetUrl ?? this.assetUrl,
      name: name ?? this.name,
      category: category ?? this.category,
      size: size ?? this.size,
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      visuals: visuals ?? this.visuals,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class StageStickerLayer {
  const StageStickerLayer({
    required this.id,
    required this.stickerId,
    required this.stickerUrl,
    required this.name,
    required this.category,
    required this.size,
    required this.offset,
    required this.scale,
    required this.rotation,
    this.visuals = LayerVisualConfig.standard,
    required this.zIndex,
    this.isLocked = false,
    this.isVisible = true,
  });

  final String id;
  final String stickerId;
  final String stickerUrl;
  final String name;
  final String category;
  final Size size;
  final Offset offset;
  final double scale;
  final double rotation;
  final LayerVisualConfig visuals;
  final int zIndex;
  final bool isLocked;
  final bool isVisible;

  StageStickerLayer copyWith({
    String? id,
    String? stickerId,
    String? stickerUrl,
    String? name,
    String? category,
    Size? size,
    Offset? offset,
    double? scale,
    double? rotation,
    LayerVisualConfig? visuals,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
  }) {
    return StageStickerLayer(
      id: id ?? this.id,
      stickerId: stickerId ?? this.stickerId,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      name: name ?? this.name,
      category: category ?? this.category,
      size: size ?? this.size,
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      visuals: visuals ?? this.visuals,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

enum DrawToolMode { pen, brush, highlighter, eraser }

enum DrawBrushStyle { smoothPen, softBrush, neonHighlighter, dottedLine }

class DrawStroke {
  const DrawStroke({
    required this.id,
    required this.mode,
    required this.style,
    required this.points,
    required this.color,
    required this.size,
    required this.opacity,
  });

  final String id;
  final DrawToolMode mode;
  final DrawBrushStyle style;
  final List<Offset> points;
  final Color color;
  final double size;
  final double opacity;

  DrawStroke copyWith({
    String? id,
    DrawToolMode? mode,
    DrawBrushStyle? style,
    List<Offset>? points,
    Color? color,
    double? size,
    double? opacity,
  }) {
    return DrawStroke(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      style: style ?? this.style,
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
    );
  }
}

class StageDrawLayer {
  const StageDrawLayer({
    required this.id,
    required this.name,
    required this.strokes,
    this.visuals = LayerVisualConfig.standard,
    required this.zIndex,
    this.isLocked = false,
    this.isVisible = true,
  });

  final String id;
  final String name;
  final List<DrawStroke> strokes;
  final LayerVisualConfig visuals;
  final int zIndex;
  final bool isLocked;
  final bool isVisible;

  StageDrawLayer copyWith({
    String? id,
    String? name,
    List<DrawStroke>? strokes,
    LayerVisualConfig? visuals,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
  }) {
    return StageDrawLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      strokes: strokes ?? this.strokes,
      visuals: visuals ?? this.visuals,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

enum ShapeKind {
  rectangle,
  roundedRectangle,
  circle,
  oval,
  line,
  triangle,
  polygon,
  star,
  heart,
  arrow,
}

class StageShapeLayer {
  const StageShapeLayer({
    required this.id,
    required this.kind,
    required this.name,
    required this.size,
    required this.offset,
    required this.scale,
    required this.rotation,
    this.fillColor = const Color(0xFF2563EB),
    this.useGradientFill = false,
    this.gradientColors = const <Color>[Color(0xFF6366F1), Color(0xFF06B6D4)],
    this.strokeColor = const Color(0xFFFFFFFF),
    this.strokeWidth = 0,
    this.opacity = 1,
    this.cornerRadius = 0.18,
    this.visuals = LayerVisualConfig.standard,
    required this.zIndex,
    this.isLocked = false,
    this.isVisible = true,
  });

  final String id;
  final ShapeKind kind;
  final String name;
  final Size size;
  final Offset offset;
  final double scale;
  final double rotation;
  final Color fillColor;
  final bool useGradientFill;
  final List<Color> gradientColors;
  final Color strokeColor;
  final double strokeWidth;
  final double opacity;
  final double cornerRadius;
  final LayerVisualConfig visuals;
  final int zIndex;
  final bool isLocked;
  final bool isVisible;

  StageShapeLayer copyWith({
    String? id,
    ShapeKind? kind,
    String? name,
    Size? size,
    Offset? offset,
    double? scale,
    double? rotation,
    Color? fillColor,
    bool? useGradientFill,
    List<Color>? gradientColors,
    Color? strokeColor,
    double? strokeWidth,
    double? opacity,
    double? cornerRadius,
    LayerVisualConfig? visuals,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
  }) {
    return StageShapeLayer(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      size: size ?? this.size,
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      fillColor: fillColor ?? this.fillColor,
      useGradientFill: useGradientFill ?? this.useGradientFill,
      gradientColors: gradientColors ?? this.gradientColors,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      visuals: visuals ?? this.visuals,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
