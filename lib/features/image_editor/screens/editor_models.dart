part of 'image_editor_screen.dart';

const Object _canvasLayerCopyWithUnset = Object();

@immutable
class _SnapGuideState {
  const _SnapGuideState({
    required this.showVerticalGuide,
    required this.showHorizontalGuide,
    this.rotationGuideAngle,
  });

  const _SnapGuideState.none()
    : showVerticalGuide = false,
      showHorizontalGuide = false,
      rotationGuideAngle = null;

  final bool showVerticalGuide;
  final bool showHorizontalGuide;
  final double? rotationGuideAngle;

  bool get isVisible =>
      showVerticalGuide || showHorizontalGuide || rotationGuideAngle != null;

  @override
  bool operator ==(Object other) {
    return other is _SnapGuideState &&
        other.showVerticalGuide == showVerticalGuide &&
        other.showHorizontalGuide == showHorizontalGuide &&
        other.rotationGuideAngle == rotationGuideAngle;
  }

  @override
  int get hashCode =>
      Object.hash(showVerticalGuide, showHorizontalGuide, rotationGuideAngle);
}

@immutable
class _AdjustSessionState {
  const _AdjustSessionState({
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.blur,
    required this.sharpen,
    required this.grain,
    required this.vignette,
    required this.motion,
    required this.tiltShift,
    required this.shadows,
    required this.highlights,
    required this.temperature,
    required this.tint,
  });

  final double brightness;
  final double contrast;
  final double saturation;
  final double blur;
  final double sharpen;
  final double grain;
  final double vignette;
  final double motion;
  final double tiltShift;
  final double shadows;
  final double highlights;
  final double temperature;
  final double tint;

  _AdjustSessionState copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? blur,
    double? sharpen,
    double? grain,
    double? vignette,
    double? motion,
    double? tiltShift,
    double? shadows,
    double? highlights,
    double? temperature,
    double? tint,
  }) {
    return _AdjustSessionState(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      blur: blur ?? this.blur,
      sharpen: sharpen ?? this.sharpen,
      grain: grain ?? this.grain,
      vignette: vignette ?? this.vignette,
      motion: motion ?? this.motion,
      tiltShift: tiltShift ?? this.tiltShift,
      shadows: shadows ?? this.shadows,
      highlights: highlights ?? this.highlights,
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _AdjustSessionState &&
        (other.brightness - brightness).abs() < 0.0001 &&
        (other.contrast - contrast).abs() < 0.0001 &&
        (other.saturation - saturation).abs() < 0.0001 &&
        (other.blur - blur).abs() < 0.0001 &&
        (other.sharpen - sharpen).abs() < 0.0001 &&
        (other.grain - grain).abs() < 0.0001 &&
        (other.vignette - vignette).abs() < 0.0001 &&
        (other.motion - motion).abs() < 0.0001 &&
        (other.tiltShift - tiltShift).abs() < 0.0001 &&
        (other.shadows - shadows).abs() < 0.0001 &&
        (other.highlights - highlights).abs() < 0.0001 &&
        (other.temperature - temperature).abs() < 0.0001 &&
        (other.tint - tint).abs() < 0.0001;
  }

  @override
  int get hashCode => Object.hash(
    brightness.toStringAsFixed(4),
    contrast.toStringAsFixed(4),
    saturation.toStringAsFixed(4),
    blur.toStringAsFixed(4),
    sharpen.toStringAsFixed(4),
    grain.toStringAsFixed(4),
    vignette.toStringAsFixed(4),
    motion.toStringAsFixed(4),
    tiltShift.toStringAsFixed(4),
    shadows.toStringAsFixed(4),
    highlights.toStringAsFixed(4),
    temperature.toStringAsFixed(4),
    tint.toStringAsFixed(4),
  );
}

@immutable
class _SelectedPhotoRenderState {
  const _SelectedPhotoRenderState({
    required this.layerId,
    required this.bytes,
    required this.opacity,
    required this.flipHorizontally,
    required this.flipVertically,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.blur,
    required this.sharpen,
    required this.grain,
    required this.vignette,
    required this.motion,
    required this.tiltShift,
    required this.shadows,
    required this.highlights,
    required this.temperature,
    required this.tint,
  });

  final String layerId;
  final Uint8List bytes;
  final double opacity;
  final bool flipHorizontally;
  final bool flipVertically;
  final double brightness;
  final double contrast;
  final double saturation;
  final double blur;
  final double sharpen;
  final double grain;
  final double vignette;
  final double motion;
  final double tiltShift;
  final double shadows;
  final double highlights;
  final double temperature;
  final double tint;

  String get cacheKey =>
      '${_photoBytesSignature(bytes)}_'
      '${brightness.toStringAsFixed(3)}_'
      '${contrast.toStringAsFixed(3)}_'
      '${saturation.toStringAsFixed(3)}_'
      '${blur.toStringAsFixed(3)}_'
      '${sharpen.toStringAsFixed(3)}_'
      '${grain.toStringAsFixed(3)}_'
      '${vignette.toStringAsFixed(3)}_'
      '${motion.toStringAsFixed(3)}_'
      '${tiltShift.toStringAsFixed(3)}_'
      '${shadows.toStringAsFixed(3)}_'
      '${highlights.toStringAsFixed(3)}_'
      '${temperature.toStringAsFixed(3)}_'
      '${tint.toStringAsFixed(3)}_'
      '${opacity.toStringAsFixed(3)}_'
      '${flipHorizontally ? 1 : 0}_${flipVertically ? 1 : 0}';

  @override
  bool operator ==(Object other) {
    return other is _SelectedPhotoRenderState &&
        other.layerId == layerId &&
        identical(other.bytes, bytes) &&
        (other.opacity - opacity).abs() < 0.0001 &&
        other.flipHorizontally == flipHorizontally &&
        other.flipVertically == flipVertically &&
        (other.brightness - brightness).abs() < 0.0001 &&
        (other.contrast - contrast).abs() < 0.0001 &&
        (other.saturation - saturation).abs() < 0.0001 &&
        (other.blur - blur).abs() < 0.0001 &&
        (other.sharpen - sharpen).abs() < 0.0001 &&
        (other.grain - grain).abs() < 0.0001 &&
        (other.vignette - vignette).abs() < 0.0001 &&
        (other.motion - motion).abs() < 0.0001 &&
        (other.tiltShift - tiltShift).abs() < 0.0001 &&
        (other.shadows - shadows).abs() < 0.0001 &&
        (other.highlights - highlights).abs() < 0.0001 &&
        (other.temperature - temperature).abs() < 0.0001 &&
        (other.tint - tint).abs() < 0.0001;
  }

  @override
  int get hashCode => Object.hash(
    layerId,
    identityHashCode(bytes),
    opacity.toStringAsFixed(4),
    flipHorizontally,
    flipVertically,
    brightness.toStringAsFixed(4),
    contrast.toStringAsFixed(4),
    saturation.toStringAsFixed(4),
    blur.toStringAsFixed(4),
    sharpen.toStringAsFixed(4),
    grain.toStringAsFixed(4),
    vignette.toStringAsFixed(4),
    motion.toStringAsFixed(4),
    tiltShift.toStringAsFixed(4),
    shadows.toStringAsFixed(4),
    highlights.toStringAsFixed(4),
    temperature.toStringAsFixed(4),
    tint.toStringAsFixed(4),
  );
}

@immutable
class _PhotoEraserPreviewState {
  const _PhotoEraserPreviewState({
    required this.layerId,
    required this.points,
    required this.brushSize,
    required this.hardness,
    this.cloneSourceImage,
    this.cloneSampleOffset,
    this.cloneStampPoints,
    this.cloneOpacity = 1,
  });

  final String layerId;
  final List<Offset> points;
  final double brushSize;
  final double hardness;
  final ui.Image? cloneSourceImage;
  final Offset? cloneSampleOffset;
  final List<Offset>? cloneStampPoints;
  final double cloneOpacity;
}

@immutable
class _LayerMaskBrushStroke {
  const _LayerMaskBrushStroke({
    required this.points,
    required this.brushSize,
    required this.hardness,
    this.restores = false,
  });

  final List<Offset> points;
  final double brushSize;
  final double hardness;
  final bool restores;
}

class _CanvasLayer {
  const _CanvasLayer({
    required this.id,
    required this.type,
    this.layerName = '',
    this.bytes,
    this.originalPhotoBytes,
    this.text,
    this.legacyRenderText,
    this.isParagraphText = true,
    this.sticker,
    this.stickerColor = const Color(0xFF111827),
    this.textColor = const Color(0xFF0F172A),
    this.textAlign = TextAlign.center,
    this.textGradientIndex = -1,
    this.textOpacity = 1,
    this.fontSize = 40,
    this.fontFamily = 'Pallavi Bold',
    this.photoOpacity = 1,
    this.photoBrightness = 0,
    this.photoContrast = 1,
    this.photoSaturation = 1,
    this.photoBlur = 0,
    this.photoSharpen = 0,
    this.photoGrain = 0,
    this.photoVignette = 0,
    this.photoMotion = 0,
    this.photoTiltShift = 0,
    this.photoShadows = 0,
    this.photoHighlights = 0,
    this.photoTemperature = 0,
    this.photoTint = 0,
    this.photoPerspectiveX = 0,
    this.photoPerspectiveY = 0,
    this.photoShadowOpacity = 0,
    this.photoShadowBlur = 0,
    this.photoShadowOffsetY = 0,
    this.photoShadowColor = const Color(0xFF000000),
    this.flipPhotoHorizontally = false,
    this.flipPhotoVertically = false,
    this.isLocked = false,
    this.isHidden = false,
    this.textLineHeight = 1.15,
    this.textLetterSpacing = 0,
    this.textShadowOpacity = 0,
    this.textShadowColor = const Color(0xFF000000),
    this.textShadowBlur = 0,
    this.textShadowOffsetY = 0,
    this.isTextBold = false,
    this.isTextItalic = false,
    this.isTextUnderline = false,
    this.textStrokeColor = const Color(0xFF000000),
    this.textStrokeWidth = 0,
    this.textStrokeGradientIndex = -1,
    this.textBackgroundColor = const Color(0x00000000),
    this.textBackgroundOpacity = 0,
    this.textBackgroundRadius = 0,
    this.textBackgroundTopPadding = 8,
    this.textBackgroundBottomPadding = 8,
    this.photoAspectRatio,
    this.photoFixedWidth,
    this.photoFixedHeight,
    this.psdEditableText,
    this.psdEditableFontSize,
    this.psdEditableFontFamily,
    this.psdEditableTextAlign,
    this.photoMaskShape = '',
    this.photoMaskScale = 1,
    this.photoMaskOffsetX = 0,
    this.photoMaskOffsetY = 0,
    this.photoMaskFeather = 0,
    this.photoFramePreset = '',
    this.photoFrameColor = const Color(0xFFFFFFFF),
    this.photoFrameThickness = 50,
    this.fillPageBounds = false,
    this.clipsToLayerBelow = false,
    this.layerMaskEnabled = false,
    this.layerMaskShape = '',
    this.layerMaskInverted = false,
    this.layerMaskFeather = 0,
    this.layerMaskBrushStrokes = const <_LayerMaskBrushStroke>[],
    this.layerStyleOverlayColor = const Color(0xFF000000),
    this.layerStyleOverlayOpacity = 0,
    this.layerStyleColorOverlayBlendMode = 0,
    this.layerStyleStrokeColor = const Color(0xFFFFFFFF),
    this.layerStyleStrokeWidth = 0,
    this.layerStyleShadowColor = const Color(0xFF000000),
    this.layerStyleShadowOpacity = 0,
    this.layerStyleShadowBlur = 12,
    this.layerStyleShadowSpread = 0,
    this.layerStyleShadowOffsetX = 0,
    this.layerStyleShadowOffsetY = 6,
    this.layerStyleShadowBlendMode = 0,
    this.layerStyleShadowContour = 0,
    this.layerStyleShadowNoise = 0,
    this.layerStyleUseGlobalLight = false,
    this.layerStyleGlobalLightAngle = 120,
    this.layerStyleGlobalLightAltitude = 30,
    this.layerStyleBevelEnabled = false,
    this.layerStyleBevelStyle = 0,
    this.layerStyleBevelTechnique = 0,
    this.layerStyleBevelDirection = 0,
    this.layerStyleBevelDepth = 35,
    this.layerStyleBevelSize = 8,
    this.layerStyleBevelSoften = 2,
    this.layerStyleBevelAngle = 120,
    this.layerStyleBevelAltitude = 30,
    this.layerStyleBevelHighlightColor = const Color(0xFFFFFFFF),
    this.layerStyleBevelHighlightOpacity = 0.75,
    this.layerStyleBevelShadowColor = const Color(0xFF000000),
    this.layerStyleBevelShadowOpacity = 0.75,
    this.layerStyleContour = 0,
    this.layerStyleTextureEnabled = false,
    this.layerStyleTextureScale = 36,
    this.layerStyleTextureDepth = 18,
    this.layerStyleStrokeOpacity = 1,
    this.layerStyleStrokePosition = 0,
    this.layerStyleStrokeBlendMode = 0,
    this.layerStyleInnerShadowColor = const Color(0xFF000000),
    this.layerStyleInnerShadowOpacity = 0,
    this.layerStyleInnerShadowBlur = 12,
    this.layerStyleInnerShadowChoke = 0,
    this.layerStyleInnerShadowDistance = 8,
    this.layerStyleInnerShadowAngle = 120,
    this.layerStyleInnerShadowBlendMode = 0,
    this.layerStyleInnerShadowContour = 0,
    this.layerStyleInnerShadowNoise = 0,
    this.layerStyleGradientOverlayEnabled = false,
    this.layerStyleGradientOverlayIndex = 0,
    this.layerStyleGradientOverlayOpacity = 0,
    this.layerStyleGradientOverlayAngle = 0,
    this.layerStyleGradientOverlayStyle = 0,
    this.layerStyleGradientOverlayScale = 100,
    this.layerStyleGradientOverlayBlendMode = 0,
    this.layerStyleGradientOverlayReversed = false,
    this.layerStyleGradientOverlayDither = false,
    this.layerStyleOuterGlowColor = const Color(0xFFFFFFFF),
    this.layerStyleOuterGlowOpacity = 0,
    this.layerStyleOuterGlowSize = 18,
    this.layerStyleOuterGlowSpread = 0,
    this.layerStyleOuterGlowNoise = 0,
    this.layerStyleOuterGlowContour = 0,
    this.layerStyleOuterGlowRange = 50,
    this.layerStyleOuterGlowJitter = 0,
    this.layerStyleOuterGlowBlendMode = 0,
    this.layerStyleInnerGlowColor = const Color(0xFFFFFFFF),
    this.layerStyleInnerGlowOpacity = 0,
    this.layerStyleInnerGlowSize = 18,
    this.layerStyleInnerGlowSpread = 0,
    this.layerStyleInnerGlowNoise = 0,
    this.layerStyleInnerGlowSource = 0,
    this.layerStyleInnerGlowContour = 0,
    this.layerStyleInnerGlowRange = 50,
    this.layerStyleInnerGlowJitter = 0,
    this.layerStyleInnerGlowBlendMode = 0,
    this.layerStyleSatinColor = const Color(0xFF000000),
    this.layerStyleSatinOpacity = 0,
    this.layerStyleSatinAngle = 20,
    this.layerStyleSatinDistance = 12,
    this.layerStyleSatinSize = 18,
    this.layerStyleSatinInverted = false,
    this.layerStyleSatinBlendMode = 0,
    this.layerStylePatternOverlayEnabled = false,
    this.layerStylePatternOverlayOpacity = 0,
    this.layerStylePatternOverlayScale = 36,
    this.layerStylePatternOverlayBlendMode = 0,
    this.layerStylePatternOverlayPreset = 0,
    this.isSmartObject = false,
    this.smartObjectSourceBytes,
    this.groupId = '',
    this.groupName = '',
    this.linkGroupId = '',
    this.blendMode = BlendMode.srcOver,
    required this.transform,
  });

  final String id;
  final _CanvasLayerType type;
  final String layerName;
  final Uint8List? bytes;
  final Uint8List? originalPhotoBytes;
  final String? text;
  final String? legacyRenderText;
  final bool isParagraphText;
  final String? sticker;
  final Color stickerColor;
  final Color textColor;
  final TextAlign textAlign;
  final int textGradientIndex;
  final double textOpacity;
  final double fontSize;
  final String fontFamily;
  final double photoOpacity;
  final double photoBrightness;
  final double photoContrast;
  final double photoSaturation;
  final double photoBlur;
  final double photoSharpen;
  final double photoGrain;
  final double photoVignette;
  final double photoMotion;
  final double photoTiltShift;
  final double photoShadows;
  final double photoHighlights;
  final double photoTemperature;
  final double photoTint;
  final double photoPerspectiveX;
  final double photoPerspectiveY;
  final double photoShadowOpacity;
  final double photoShadowBlur;
  final double photoShadowOffsetY;
  final Color photoShadowColor;
  final bool flipPhotoHorizontally;
  final bool flipPhotoVertically;
  final bool isLocked;
  final bool isHidden;
  final double textLineHeight;
  final double textLetterSpacing;
  final double textShadowOpacity;
  final Color textShadowColor;
  final double textShadowBlur;
  final double textShadowOffsetY;
  final bool isTextBold;
  final bool isTextItalic;
  final bool isTextUnderline;
  final Color textStrokeColor;
  final double textStrokeWidth;
  final int textStrokeGradientIndex;
  final Color textBackgroundColor;
  final double textBackgroundOpacity;
  final double textBackgroundRadius;
  final double textBackgroundTopPadding;
  final double textBackgroundBottomPadding;
  final double? photoAspectRatio;
  final double? photoFixedWidth;
  final double? photoFixedHeight;
  final String? psdEditableText;
  final double? psdEditableFontSize;
  final String? psdEditableFontFamily;
  final TextAlign? psdEditableTextAlign;
  final String photoMaskShape;
  final double photoMaskScale;
  final double photoMaskOffsetX;
  final double photoMaskOffsetY;
  final double photoMaskFeather;
  final String photoFramePreset;
  final Color photoFrameColor;
  final double photoFrameThickness;
  final bool fillPageBounds;
  final bool clipsToLayerBelow;
  final bool layerMaskEnabled;
  final String layerMaskShape;
  final bool layerMaskInverted;
  final double layerMaskFeather;
  final List<_LayerMaskBrushStroke> layerMaskBrushStrokes;
  final Color layerStyleOverlayColor;
  final double layerStyleOverlayOpacity;
  final int layerStyleColorOverlayBlendMode;
  final Color layerStyleStrokeColor;
  final double layerStyleStrokeWidth;
  final Color layerStyleShadowColor;
  final double layerStyleShadowOpacity;
  final double layerStyleShadowBlur;
  final double layerStyleShadowSpread;
  final double layerStyleShadowOffsetX;
  final double layerStyleShadowOffsetY;
  final int layerStyleShadowBlendMode;
  final int layerStyleShadowContour;
  final double layerStyleShadowNoise;
  final bool layerStyleUseGlobalLight;
  final double layerStyleGlobalLightAngle;
  final double layerStyleGlobalLightAltitude;
  final bool layerStyleBevelEnabled;
  final int layerStyleBevelStyle;
  final int layerStyleBevelTechnique;
  final int layerStyleBevelDirection;
  final double layerStyleBevelDepth;
  final double layerStyleBevelSize;
  final double layerStyleBevelSoften;
  final double layerStyleBevelAngle;
  final double layerStyleBevelAltitude;
  final Color layerStyleBevelHighlightColor;
  final double layerStyleBevelHighlightOpacity;
  final Color layerStyleBevelShadowColor;
  final double layerStyleBevelShadowOpacity;
  final int layerStyleContour;
  final bool layerStyleTextureEnabled;
  final double layerStyleTextureScale;
  final double layerStyleTextureDepth;
  final double layerStyleStrokeOpacity;
  final int layerStyleStrokePosition;
  final int layerStyleStrokeBlendMode;
  final Color layerStyleInnerShadowColor;
  final double layerStyleInnerShadowOpacity;
  final double layerStyleInnerShadowBlur;
  final double layerStyleInnerShadowChoke;
  final double layerStyleInnerShadowDistance;
  final double layerStyleInnerShadowAngle;
  final int layerStyleInnerShadowBlendMode;
  final int layerStyleInnerShadowContour;
  final double layerStyleInnerShadowNoise;
  final bool layerStyleGradientOverlayEnabled;
  final int layerStyleGradientOverlayIndex;
  final double layerStyleGradientOverlayOpacity;
  final double layerStyleGradientOverlayAngle;
  final int layerStyleGradientOverlayStyle;
  final double layerStyleGradientOverlayScale;
  final int layerStyleGradientOverlayBlendMode;
  final bool layerStyleGradientOverlayReversed;
  final bool layerStyleGradientOverlayDither;
  final Color layerStyleOuterGlowColor;
  final double layerStyleOuterGlowOpacity;
  final double layerStyleOuterGlowSize;
  final double layerStyleOuterGlowSpread;
  final double layerStyleOuterGlowNoise;
  final int layerStyleOuterGlowContour;
  final double layerStyleOuterGlowRange;
  final double layerStyleOuterGlowJitter;
  final int layerStyleOuterGlowBlendMode;
  final Color layerStyleInnerGlowColor;
  final double layerStyleInnerGlowOpacity;
  final double layerStyleInnerGlowSize;
  final double layerStyleInnerGlowSpread;
  final double layerStyleInnerGlowNoise;
  final int layerStyleInnerGlowSource;
  final int layerStyleInnerGlowContour;
  final double layerStyleInnerGlowRange;
  final double layerStyleInnerGlowJitter;
  final int layerStyleInnerGlowBlendMode;
  final Color layerStyleSatinColor;
  final double layerStyleSatinOpacity;
  final double layerStyleSatinAngle;
  final double layerStyleSatinDistance;
  final double layerStyleSatinSize;
  final bool layerStyleSatinInverted;
  final int layerStyleSatinBlendMode;
  final bool layerStylePatternOverlayEnabled;
  final double layerStylePatternOverlayOpacity;
  final double layerStylePatternOverlayScale;
  final int layerStylePatternOverlayBlendMode;
  final int layerStylePatternOverlayPreset;
  final bool isSmartObject;
  final Uint8List? smartObjectSourceBytes;
  final String groupId;
  final String groupName;
  final String linkGroupId;
  final BlendMode blendMode;
  final Matrix4 transform;

  bool get isPhoto => type == _CanvasLayerType.photo;
  bool get isText => type == _CanvasLayerType.text;
  bool get isSticker => type == _CanvasLayerType.sticker;

  _CanvasLayer copyWith({
    String? id,
    _CanvasLayerType? type,
    String? layerName,
    Uint8List? bytes,
    Uint8List? originalPhotoBytes,
    String? text,
    Object? legacyRenderText = _canvasLayerCopyWithUnset,
    bool? isParagraphText,
    String? sticker,
    Color? stickerColor,
    Color? textColor,
    TextAlign? textAlign,
    int? textGradientIndex,
    double? textOpacity,
    double? fontSize,
    String? fontFamily,
    double? photoOpacity,
    double? photoBrightness,
    double? photoContrast,
    double? photoSaturation,
    double? photoBlur,
    double? photoSharpen,
    double? photoGrain,
    double? photoVignette,
    double? photoMotion,
    double? photoTiltShift,
    double? photoShadows,
    double? photoHighlights,
    double? photoTemperature,
    double? photoTint,
    double? photoPerspectiveX,
    double? photoPerspectiveY,
    double? photoShadowOpacity,
    double? photoShadowBlur,
    double? photoShadowOffsetY,
    Color? photoShadowColor,
    bool? flipPhotoHorizontally,
    bool? flipPhotoVertically,
    bool? isLocked,
    bool? isHidden,
    double? textLineHeight,
    double? textLetterSpacing,
    double? textShadowOpacity,
    Color? textShadowColor,
    double? textShadowBlur,
    double? textShadowOffsetY,
    bool? isTextBold,
    bool? isTextItalic,
    bool? isTextUnderline,
    Color? textStrokeColor,
    double? textStrokeWidth,
    int? textStrokeGradientIndex,
    Color? textBackgroundColor,
    double? textBackgroundOpacity,
    double? textBackgroundRadius,
    double? textBackgroundTopPadding,
    double? textBackgroundBottomPadding,
    double? photoAspectRatio,
    Object? photoFixedWidth = _canvasLayerCopyWithUnset,
    Object? photoFixedHeight = _canvasLayerCopyWithUnset,
    Object? psdEditableText = _canvasLayerCopyWithUnset,
    Object? psdEditableFontSize = _canvasLayerCopyWithUnset,
    Object? psdEditableFontFamily = _canvasLayerCopyWithUnset,
    Object? psdEditableTextAlign = _canvasLayerCopyWithUnset,
    String? photoMaskShape,
    double? photoMaskScale,
    double? photoMaskOffsetX,
    double? photoMaskOffsetY,
    double? photoMaskFeather,
    String? photoFramePreset,
    Color? photoFrameColor,
    double? photoFrameThickness,
    bool? fillPageBounds,
    bool? clipsToLayerBelow,
    bool? layerMaskEnabled,
    String? layerMaskShape,
    bool? layerMaskInverted,
    double? layerMaskFeather,
    List<_LayerMaskBrushStroke>? layerMaskBrushStrokes,
    Color? layerStyleOverlayColor,
    double? layerStyleOverlayOpacity,
    int? layerStyleColorOverlayBlendMode,
    Color? layerStyleStrokeColor,
    double? layerStyleStrokeWidth,
    Color? layerStyleShadowColor,
    double? layerStyleShadowOpacity,
    double? layerStyleShadowBlur,
    double? layerStyleShadowSpread,
    double? layerStyleShadowOffsetX,
    double? layerStyleShadowOffsetY,
    int? layerStyleShadowBlendMode,
    int? layerStyleShadowContour,
    double? layerStyleShadowNoise,
    bool? layerStyleUseGlobalLight,
    double? layerStyleGlobalLightAngle,
    double? layerStyleGlobalLightAltitude,
    bool? layerStyleBevelEnabled,
    int? layerStyleBevelStyle,
    int? layerStyleBevelTechnique,
    int? layerStyleBevelDirection,
    double? layerStyleBevelDepth,
    double? layerStyleBevelSize,
    double? layerStyleBevelSoften,
    double? layerStyleBevelAngle,
    double? layerStyleBevelAltitude,
    Color? layerStyleBevelHighlightColor,
    double? layerStyleBevelHighlightOpacity,
    Color? layerStyleBevelShadowColor,
    double? layerStyleBevelShadowOpacity,
    int? layerStyleContour,
    bool? layerStyleTextureEnabled,
    double? layerStyleTextureScale,
    double? layerStyleTextureDepth,
    double? layerStyleStrokeOpacity,
    int? layerStyleStrokePosition,
    int? layerStyleStrokeBlendMode,
    Color? layerStyleInnerShadowColor,
    double? layerStyleInnerShadowOpacity,
    double? layerStyleInnerShadowBlur,
    double? layerStyleInnerShadowChoke,
    double? layerStyleInnerShadowDistance,
    double? layerStyleInnerShadowAngle,
    int? layerStyleInnerShadowBlendMode,
    int? layerStyleInnerShadowContour,
    double? layerStyleInnerShadowNoise,
    bool? layerStyleGradientOverlayEnabled,
    int? layerStyleGradientOverlayIndex,
    double? layerStyleGradientOverlayOpacity,
    double? layerStyleGradientOverlayAngle,
    int? layerStyleGradientOverlayStyle,
    double? layerStyleGradientOverlayScale,
    int? layerStyleGradientOverlayBlendMode,
    bool? layerStyleGradientOverlayReversed,
    bool? layerStyleGradientOverlayDither,
    Color? layerStyleOuterGlowColor,
    double? layerStyleOuterGlowOpacity,
    double? layerStyleOuterGlowSize,
    double? layerStyleOuterGlowSpread,
    double? layerStyleOuterGlowNoise,
    int? layerStyleOuterGlowContour,
    double? layerStyleOuterGlowRange,
    double? layerStyleOuterGlowJitter,
    int? layerStyleOuterGlowBlendMode,
    Color? layerStyleInnerGlowColor,
    double? layerStyleInnerGlowOpacity,
    double? layerStyleInnerGlowSize,
    double? layerStyleInnerGlowSpread,
    double? layerStyleInnerGlowNoise,
    int? layerStyleInnerGlowSource,
    int? layerStyleInnerGlowContour,
    double? layerStyleInnerGlowRange,
    double? layerStyleInnerGlowJitter,
    int? layerStyleInnerGlowBlendMode,
    Color? layerStyleSatinColor,
    double? layerStyleSatinOpacity,
    double? layerStyleSatinAngle,
    double? layerStyleSatinDistance,
    double? layerStyleSatinSize,
    bool? layerStyleSatinInverted,
    int? layerStyleSatinBlendMode,
    bool? layerStylePatternOverlayEnabled,
    double? layerStylePatternOverlayOpacity,
    double? layerStylePatternOverlayScale,
    int? layerStylePatternOverlayBlendMode,
    int? layerStylePatternOverlayPreset,
    bool? isSmartObject,
    Object? smartObjectSourceBytes = _canvasLayerCopyWithUnset,
    String? groupId,
    String? groupName,
    String? linkGroupId,
    BlendMode? blendMode,
    Matrix4? transform,
  }) {
    return _CanvasLayer(
      id: id ?? this.id,
      type: type ?? this.type,
      layerName: layerName ?? this.layerName,
      bytes: bytes ?? this.bytes,
      originalPhotoBytes: originalPhotoBytes ?? this.originalPhotoBytes,
      text: text ?? this.text,
      legacyRenderText: identical(legacyRenderText, _canvasLayerCopyWithUnset)
          ? this.legacyRenderText
          : legacyRenderText as String?,
      isParagraphText: isParagraphText ?? this.isParagraphText,
      sticker: sticker ?? this.sticker,
      stickerColor: stickerColor ?? this.stickerColor,
      textColor: textColor ?? this.textColor,
      textAlign: textAlign ?? this.textAlign,
      textGradientIndex: textGradientIndex ?? this.textGradientIndex,
      textOpacity: textOpacity ?? this.textOpacity,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      photoOpacity: photoOpacity ?? this.photoOpacity,
      photoBrightness: photoBrightness ?? this.photoBrightness,
      photoContrast: photoContrast ?? this.photoContrast,
      photoSaturation: photoSaturation ?? this.photoSaturation,
      photoBlur: photoBlur ?? this.photoBlur,
      photoSharpen: photoSharpen ?? this.photoSharpen,
      photoGrain: photoGrain ?? this.photoGrain,
      photoVignette: photoVignette ?? this.photoVignette,
      photoMotion: photoMotion ?? this.photoMotion,
      photoTiltShift: photoTiltShift ?? this.photoTiltShift,
      photoShadows: photoShadows ?? this.photoShadows,
      photoHighlights: photoHighlights ?? this.photoHighlights,
      photoTemperature: photoTemperature ?? this.photoTemperature,
      photoTint: photoTint ?? this.photoTint,
      photoPerspectiveX: photoPerspectiveX ?? this.photoPerspectiveX,
      photoPerspectiveY: photoPerspectiveY ?? this.photoPerspectiveY,
      photoShadowOpacity: photoShadowOpacity ?? this.photoShadowOpacity,
      photoShadowBlur: photoShadowBlur ?? this.photoShadowBlur,
      photoShadowOffsetY: photoShadowOffsetY ?? this.photoShadowOffsetY,
      photoShadowColor: photoShadowColor ?? this.photoShadowColor,
      flipPhotoHorizontally:
          flipPhotoHorizontally ?? this.flipPhotoHorizontally,
      flipPhotoVertically: flipPhotoVertically ?? this.flipPhotoVertically,
      isLocked: isLocked ?? this.isLocked,
      isHidden: isHidden ?? this.isHidden,
      textLineHeight: textLineHeight ?? this.textLineHeight,
      textLetterSpacing: textLetterSpacing ?? this.textLetterSpacing,
      textShadowOpacity: textShadowOpacity ?? this.textShadowOpacity,
      textShadowColor: textShadowColor ?? this.textShadowColor,
      textShadowBlur: textShadowBlur ?? this.textShadowBlur,
      textShadowOffsetY: textShadowOffsetY ?? this.textShadowOffsetY,
      isTextBold: isTextBold ?? this.isTextBold,
      isTextItalic: isTextItalic ?? this.isTextItalic,
      isTextUnderline: isTextUnderline ?? this.isTextUnderline,
      textStrokeColor: textStrokeColor ?? this.textStrokeColor,
      textStrokeWidth: textStrokeWidth ?? this.textStrokeWidth,
      textStrokeGradientIndex:
          textStrokeGradientIndex ?? this.textStrokeGradientIndex,
      textBackgroundColor: textBackgroundColor ?? this.textBackgroundColor,
      textBackgroundOpacity:
          textBackgroundOpacity ?? this.textBackgroundOpacity,
      textBackgroundRadius: textBackgroundRadius ?? this.textBackgroundRadius,
      textBackgroundTopPadding:
          textBackgroundTopPadding ?? this.textBackgroundTopPadding,
      textBackgroundBottomPadding:
          textBackgroundBottomPadding ?? this.textBackgroundBottomPadding,
      photoAspectRatio: photoAspectRatio ?? this.photoAspectRatio,
      photoFixedWidth: identical(photoFixedWidth, _canvasLayerCopyWithUnset)
          ? this.photoFixedWidth
          : photoFixedWidth as double?,
      photoFixedHeight: identical(photoFixedHeight, _canvasLayerCopyWithUnset)
          ? this.photoFixedHeight
          : photoFixedHeight as double?,
      psdEditableText: identical(psdEditableText, _canvasLayerCopyWithUnset)
          ? this.psdEditableText
          : psdEditableText as String?,
      psdEditableFontSize:
          identical(psdEditableFontSize, _canvasLayerCopyWithUnset)
          ? this.psdEditableFontSize
          : psdEditableFontSize as double?,
      psdEditableFontFamily:
          identical(psdEditableFontFamily, _canvasLayerCopyWithUnset)
          ? this.psdEditableFontFamily
          : psdEditableFontFamily as String?,
      psdEditableTextAlign:
          identical(psdEditableTextAlign, _canvasLayerCopyWithUnset)
          ? this.psdEditableTextAlign
          : psdEditableTextAlign as TextAlign?,
      photoMaskShape: photoMaskShape ?? this.photoMaskShape,
      photoMaskScale: photoMaskScale ?? this.photoMaskScale,
      photoMaskOffsetX: photoMaskOffsetX ?? this.photoMaskOffsetX,
      photoMaskOffsetY: photoMaskOffsetY ?? this.photoMaskOffsetY,
      photoMaskFeather: photoMaskFeather ?? this.photoMaskFeather,
      photoFramePreset: photoFramePreset ?? this.photoFramePreset,
      photoFrameColor: photoFrameColor ?? this.photoFrameColor,
      photoFrameThickness: photoFrameThickness ?? this.photoFrameThickness,
      fillPageBounds: fillPageBounds ?? this.fillPageBounds,
      clipsToLayerBelow: clipsToLayerBelow ?? this.clipsToLayerBelow,
      layerMaskEnabled: layerMaskEnabled ?? this.layerMaskEnabled,
      layerMaskShape: layerMaskShape ?? this.layerMaskShape,
      layerMaskInverted: layerMaskInverted ?? this.layerMaskInverted,
      layerMaskFeather: layerMaskFeather ?? this.layerMaskFeather,
      layerMaskBrushStrokes:
          layerMaskBrushStrokes ?? this.layerMaskBrushStrokes,
      layerStyleOverlayColor:
          layerStyleOverlayColor ?? this.layerStyleOverlayColor,
      layerStyleOverlayOpacity:
          layerStyleOverlayOpacity ?? this.layerStyleOverlayOpacity,
      layerStyleColorOverlayBlendMode:
          layerStyleColorOverlayBlendMode ??
          this.layerStyleColorOverlayBlendMode,
      layerStyleStrokeColor:
          layerStyleStrokeColor ?? this.layerStyleStrokeColor,
      layerStyleStrokeWidth:
          layerStyleStrokeWidth ?? this.layerStyleStrokeWidth,
      layerStyleShadowColor:
          layerStyleShadowColor ?? this.layerStyleShadowColor,
      layerStyleShadowOpacity:
          layerStyleShadowOpacity ?? this.layerStyleShadowOpacity,
      layerStyleShadowBlur: layerStyleShadowBlur ?? this.layerStyleShadowBlur,
      layerStyleShadowSpread:
          layerStyleShadowSpread ?? this.layerStyleShadowSpread,
      layerStyleShadowOffsetX:
          layerStyleShadowOffsetX ?? this.layerStyleShadowOffsetX,
      layerStyleShadowOffsetY:
          layerStyleShadowOffsetY ?? this.layerStyleShadowOffsetY,
      layerStyleShadowBlendMode:
          layerStyleShadowBlendMode ?? this.layerStyleShadowBlendMode,
      layerStyleShadowContour:
          layerStyleShadowContour ?? this.layerStyleShadowContour,
      layerStyleShadowNoise:
          layerStyleShadowNoise ?? this.layerStyleShadowNoise,
      layerStyleUseGlobalLight:
          layerStyleUseGlobalLight ?? this.layerStyleUseGlobalLight,
      layerStyleGlobalLightAngle:
          layerStyleGlobalLightAngle ?? this.layerStyleGlobalLightAngle,
      layerStyleGlobalLightAltitude:
          layerStyleGlobalLightAltitude ?? this.layerStyleGlobalLightAltitude,
      layerStyleBevelEnabled:
          layerStyleBevelEnabled ?? this.layerStyleBevelEnabled,
      layerStyleBevelStyle: layerStyleBevelStyle ?? this.layerStyleBevelStyle,
      layerStyleBevelTechnique:
          layerStyleBevelTechnique ?? this.layerStyleBevelTechnique,
      layerStyleBevelDirection:
          layerStyleBevelDirection ?? this.layerStyleBevelDirection,
      layerStyleBevelDepth: layerStyleBevelDepth ?? this.layerStyleBevelDepth,
      layerStyleBevelSize: layerStyleBevelSize ?? this.layerStyleBevelSize,
      layerStyleBevelSoften:
          layerStyleBevelSoften ?? this.layerStyleBevelSoften,
      layerStyleBevelAngle: layerStyleBevelAngle ?? this.layerStyleBevelAngle,
      layerStyleBevelAltitude:
          layerStyleBevelAltitude ?? this.layerStyleBevelAltitude,
      layerStyleBevelHighlightColor:
          layerStyleBevelHighlightColor ?? this.layerStyleBevelHighlightColor,
      layerStyleBevelHighlightOpacity:
          layerStyleBevelHighlightOpacity ??
          this.layerStyleBevelHighlightOpacity,
      layerStyleBevelShadowColor:
          layerStyleBevelShadowColor ?? this.layerStyleBevelShadowColor,
      layerStyleBevelShadowOpacity:
          layerStyleBevelShadowOpacity ?? this.layerStyleBevelShadowOpacity,
      layerStyleContour: layerStyleContour ?? this.layerStyleContour,
      layerStyleTextureEnabled:
          layerStyleTextureEnabled ?? this.layerStyleTextureEnabled,
      layerStyleTextureScale:
          layerStyleTextureScale ?? this.layerStyleTextureScale,
      layerStyleTextureDepth:
          layerStyleTextureDepth ?? this.layerStyleTextureDepth,
      layerStyleStrokeOpacity:
          layerStyleStrokeOpacity ?? this.layerStyleStrokeOpacity,
      layerStyleStrokePosition:
          layerStyleStrokePosition ?? this.layerStyleStrokePosition,
      layerStyleStrokeBlendMode:
          layerStyleStrokeBlendMode ?? this.layerStyleStrokeBlendMode,
      layerStyleInnerShadowColor:
          layerStyleInnerShadowColor ?? this.layerStyleInnerShadowColor,
      layerStyleInnerShadowOpacity:
          layerStyleInnerShadowOpacity ?? this.layerStyleInnerShadowOpacity,
      layerStyleInnerShadowBlur:
          layerStyleInnerShadowBlur ?? this.layerStyleInnerShadowBlur,
      layerStyleInnerShadowChoke:
          layerStyleInnerShadowChoke ?? this.layerStyleInnerShadowChoke,
      layerStyleInnerShadowDistance:
          layerStyleInnerShadowDistance ?? this.layerStyleInnerShadowDistance,
      layerStyleInnerShadowAngle:
          layerStyleInnerShadowAngle ?? this.layerStyleInnerShadowAngle,
      layerStyleInnerShadowBlendMode:
          layerStyleInnerShadowBlendMode ?? this.layerStyleInnerShadowBlendMode,
      layerStyleInnerShadowContour:
          layerStyleInnerShadowContour ?? this.layerStyleInnerShadowContour,
      layerStyleInnerShadowNoise:
          layerStyleInnerShadowNoise ?? this.layerStyleInnerShadowNoise,
      layerStyleGradientOverlayEnabled:
          layerStyleGradientOverlayEnabled ??
          this.layerStyleGradientOverlayEnabled,
      layerStyleGradientOverlayIndex:
          layerStyleGradientOverlayIndex ?? this.layerStyleGradientOverlayIndex,
      layerStyleGradientOverlayOpacity:
          layerStyleGradientOverlayOpacity ??
          this.layerStyleGradientOverlayOpacity,
      layerStyleGradientOverlayAngle:
          layerStyleGradientOverlayAngle ?? this.layerStyleGradientOverlayAngle,
      layerStyleGradientOverlayStyle:
          layerStyleGradientOverlayStyle ?? this.layerStyleGradientOverlayStyle,
      layerStyleGradientOverlayScale:
          layerStyleGradientOverlayScale ?? this.layerStyleGradientOverlayScale,
      layerStyleGradientOverlayBlendMode:
          layerStyleGradientOverlayBlendMode ??
          this.layerStyleGradientOverlayBlendMode,
      layerStyleGradientOverlayReversed:
          layerStyleGradientOverlayReversed ??
          this.layerStyleGradientOverlayReversed,
      layerStyleGradientOverlayDither:
          layerStyleGradientOverlayDither ??
          this.layerStyleGradientOverlayDither,
      layerStyleOuterGlowColor:
          layerStyleOuterGlowColor ?? this.layerStyleOuterGlowColor,
      layerStyleOuterGlowOpacity:
          layerStyleOuterGlowOpacity ?? this.layerStyleOuterGlowOpacity,
      layerStyleOuterGlowSize:
          layerStyleOuterGlowSize ?? this.layerStyleOuterGlowSize,
      layerStyleOuterGlowSpread:
          layerStyleOuterGlowSpread ?? this.layerStyleOuterGlowSpread,
      layerStyleOuterGlowNoise:
          layerStyleOuterGlowNoise ?? this.layerStyleOuterGlowNoise,
      layerStyleOuterGlowContour:
          layerStyleOuterGlowContour ?? this.layerStyleOuterGlowContour,
      layerStyleOuterGlowRange:
          layerStyleOuterGlowRange ?? this.layerStyleOuterGlowRange,
      layerStyleOuterGlowJitter:
          layerStyleOuterGlowJitter ?? this.layerStyleOuterGlowJitter,
      layerStyleOuterGlowBlendMode:
          layerStyleOuterGlowBlendMode ?? this.layerStyleOuterGlowBlendMode,
      layerStyleInnerGlowColor:
          layerStyleInnerGlowColor ?? this.layerStyleInnerGlowColor,
      layerStyleInnerGlowOpacity:
          layerStyleInnerGlowOpacity ?? this.layerStyleInnerGlowOpacity,
      layerStyleInnerGlowSize:
          layerStyleInnerGlowSize ?? this.layerStyleInnerGlowSize,
      layerStyleInnerGlowSpread:
          layerStyleInnerGlowSpread ?? this.layerStyleInnerGlowSpread,
      layerStyleInnerGlowNoise:
          layerStyleInnerGlowNoise ?? this.layerStyleInnerGlowNoise,
      layerStyleInnerGlowSource:
          layerStyleInnerGlowSource ?? this.layerStyleInnerGlowSource,
      layerStyleInnerGlowContour:
          layerStyleInnerGlowContour ?? this.layerStyleInnerGlowContour,
      layerStyleInnerGlowRange:
          layerStyleInnerGlowRange ?? this.layerStyleInnerGlowRange,
      layerStyleInnerGlowJitter:
          layerStyleInnerGlowJitter ?? this.layerStyleInnerGlowJitter,
      layerStyleInnerGlowBlendMode:
          layerStyleInnerGlowBlendMode ?? this.layerStyleInnerGlowBlendMode,
      layerStyleSatinColor: layerStyleSatinColor ?? this.layerStyleSatinColor,
      layerStyleSatinOpacity:
          layerStyleSatinOpacity ?? this.layerStyleSatinOpacity,
      layerStyleSatinAngle: layerStyleSatinAngle ?? this.layerStyleSatinAngle,
      layerStyleSatinDistance:
          layerStyleSatinDistance ?? this.layerStyleSatinDistance,
      layerStyleSatinSize: layerStyleSatinSize ?? this.layerStyleSatinSize,
      layerStyleSatinInverted:
          layerStyleSatinInverted ?? this.layerStyleSatinInverted,
      layerStyleSatinBlendMode:
          layerStyleSatinBlendMode ?? this.layerStyleSatinBlendMode,
      layerStylePatternOverlayEnabled:
          layerStylePatternOverlayEnabled ??
          this.layerStylePatternOverlayEnabled,
      layerStylePatternOverlayOpacity:
          layerStylePatternOverlayOpacity ??
          this.layerStylePatternOverlayOpacity,
      layerStylePatternOverlayScale:
          layerStylePatternOverlayScale ?? this.layerStylePatternOverlayScale,
      layerStylePatternOverlayBlendMode:
          layerStylePatternOverlayBlendMode ??
          this.layerStylePatternOverlayBlendMode,
      layerStylePatternOverlayPreset:
          layerStylePatternOverlayPreset ?? this.layerStylePatternOverlayPreset,
      isSmartObject: isSmartObject ?? this.isSmartObject,
      smartObjectSourceBytes:
          identical(smartObjectSourceBytes, _canvasLayerCopyWithUnset)
          ? this.smartObjectSourceBytes
          : smartObjectSourceBytes as Uint8List?,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      linkGroupId: linkGroupId ?? this.linkGroupId,
      blendMode: blendMode ?? this.blendMode,
      transform: transform ?? this.transform,
    );
  }
}

@immutable
class _TextEffectSnapshot {
  const _TextEffectSnapshot({
    required this.id,
    required this.name,
    required this.textOpacity,
    required this.textStrokeColor,
    required this.textStrokeWidth,
    required this.textShadowOpacity,
    required this.textShadowColor,
    required this.textShadowBlur,
    required this.textShadowOffsetY,
  });

  factory _TextEffectSnapshot.fromLayer(
    _CanvasLayer layer, {
    required String id,
    required String name,
  }) {
    return _TextEffectSnapshot(
      id: id,
      name: name,
      textOpacity: layer.textOpacity,
      textStrokeColor: layer.textStrokeColor,
      textStrokeWidth: layer.textStrokeWidth,
      textShadowOpacity: layer.textShadowOpacity,
      textShadowColor: layer.textShadowColor,
      textShadowBlur: layer.textShadowBlur,
      textShadowOffsetY: layer.textShadowOffsetY,
    );
  }

  factory _TextEffectSnapshot.fromJson(Map<String, Object?> json) {
    double readDouble(String key, double fallback) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    int readInt(String key, int fallback) {
      final value = json[key];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    return _TextEffectSnapshot(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Custom effect',
      textOpacity: readDouble('textOpacity', 1).clamp(0, 1).toDouble(),
      textStrokeColor: Color(readInt('textStrokeColor', 0xFF000000)),
      textStrokeWidth: readDouble(
        'textStrokeWidth',
        0,
      ).clamp(0, 100).toDouble(),
      textShadowOpacity: readDouble(
        'textShadowOpacity',
        0,
      ).clamp(0, 1).toDouble(),
      textShadowColor: Color(readInt('textShadowColor', 0xFF000000)),
      textShadowBlur: readDouble('textShadowBlur', 0).clamp(0, 100).toDouble(),
      textShadowOffsetY: readDouble(
        'textShadowOffsetY',
        0,
      ).clamp(0, 100).toDouble(),
    );
  }

  final String id;
  final String name;
  final double textOpacity;
  final Color textStrokeColor;
  final double textStrokeWidth;
  final double textShadowOpacity;
  final Color textShadowColor;
  final double textShadowBlur;
  final double textShadowOffsetY;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'textOpacity': textOpacity,
    'textStrokeColor': textStrokeColor.toARGB32(),
    'textStrokeWidth': textStrokeWidth,
    'textShadowOpacity': textShadowOpacity,
    'textShadowColor': textShadowColor.toARGB32(),
    'textShadowBlur': textShadowBlur,
    'textShadowOffsetY': textShadowOffsetY,
  };

  _CanvasLayer applyTo(_CanvasLayer layer) {
    return layer.copyWith(
      textOpacity: textOpacity,
      textStrokeColor: textStrokeColor,
      textStrokeWidth: textStrokeWidth,
      textShadowOpacity: textShadowOpacity,
      textShadowColor: textShadowColor,
      textShadowBlur: textShadowBlur,
      textShadowOffsetY: textShadowOffsetY,
    );
  }

  bool matchesLayer(_CanvasLayer layer) {
    bool near(double a, double b) => (a - b).abs() < 0.0001;
    return near(layer.textOpacity, textOpacity) &&
        layer.textStrokeColor.toARGB32() == textStrokeColor.toARGB32() &&
        near(layer.textStrokeWidth, textStrokeWidth) &&
        near(layer.textShadowOpacity, textShadowOpacity) &&
        layer.textShadowColor.toARGB32() == textShadowColor.toARGB32() &&
        near(layer.textShadowBlur, textShadowBlur) &&
        near(layer.textShadowOffsetY, textShadowOffsetY);
  }

  bool visuallyEquals(_TextEffectSnapshot other) {
    bool near(double a, double b) => (a - b).abs() < 0.0001;
    return near(textOpacity, other.textOpacity) &&
        textStrokeColor.toARGB32() == other.textStrokeColor.toARGB32() &&
        near(textStrokeWidth, other.textStrokeWidth) &&
        near(textShadowOpacity, other.textShadowOpacity) &&
        textShadowColor.toARGB32() == other.textShadowColor.toARGB32() &&
        near(textShadowBlur, other.textShadowBlur) &&
        near(textShadowOffsetY, other.textShadowOffsetY);
  }
}

class _EditorSnapshot {
  const _EditorSnapshot({
    required this.layers,
    required this.selectedLayerId,
    required this.canvasBackgroundColor,
    required this.canvasBackgroundGradientIndex,
    required this.stageBackgroundImageBytes,
    required this.borderStyle,
    required this.borderWidth,
    required this.borderRadius,
    required this.borderColor,
    required this.borderTargetLayerId,
    required this.backgroundBlurAmount,
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final Color canvasBackgroundColor;
  final int canvasBackgroundGradientIndex;
  final Uint8List? stageBackgroundImageBytes;
  final _BorderStyle borderStyle;
  final double borderWidth;
  final double borderRadius;
  final Color borderColor;
  final String? borderTargetLayerId;
  final double backgroundBlurAmount;
}

@immutable
class _EditorCommitState {
  const _EditorCommitState({required this.label, this.detail});

  final String label;
  final String? detail;
}

@immutable
class _AdjustedPhotoPresentation {
  const _AdjustedPhotoPresentation({
    required this.key,
    required this.image,
    required this.opacity,
  });

  final String key;
  final Image image;
  final double opacity;
}

class _OptimizedPhotoPayload {
  const _OptimizedPhotoPayload({
    required this.bytes,
    required this.aspectRatio,
  });

  final Uint8List bytes;
  final double? aspectRatio;
}
