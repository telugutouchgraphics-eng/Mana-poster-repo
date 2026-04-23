part of 'image_editor_screen.dart';

@immutable
class _SnapGuideState {
  const _SnapGuideState({
    required this.showVerticalGuide,
    required this.showHorizontalGuide,
  });

  const _SnapGuideState.none()
    : showVerticalGuide = false,
      showHorizontalGuide = false;

  final bool showVerticalGuide;
  final bool showHorizontalGuide;

  bool get isVisible => showVerticalGuide || showHorizontalGuide;

  @override
  bool operator ==(Object other) {
    return other is _SnapGuideState &&
        other.showVerticalGuide == showVerticalGuide &&
        other.showHorizontalGuide == showHorizontalGuide;
  }

  @override
  int get hashCode => Object.hash(showVerticalGuide, showHorizontalGuide);
}

@immutable
class _AdjustSessionState {
  const _AdjustSessionState({
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.blur,
  });

  final double brightness;
  final double contrast;
  final double saturation;
  final double blur;

  _AdjustSessionState copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? blur,
  }) {
    return _AdjustSessionState(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      blur: blur ?? this.blur,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _AdjustSessionState &&
        (other.brightness - brightness).abs() < 0.0001 &&
        (other.contrast - contrast).abs() < 0.0001 &&
        (other.saturation - saturation).abs() < 0.0001 &&
        (other.blur - blur).abs() < 0.0001;
  }

  @override
  int get hashCode => Object.hash(
    brightness.toStringAsFixed(4),
    contrast.toStringAsFixed(4),
    saturation.toStringAsFixed(4),
    blur.toStringAsFixed(4),
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

  String get cacheKey =>
      '${_photoBytesSignature(bytes)}_'
      '${brightness.toStringAsFixed(3)}_'
      '${contrast.toStringAsFixed(3)}_'
      '${saturation.toStringAsFixed(3)}_'
      '${blur.toStringAsFixed(3)}_'
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
        (other.blur - blur).abs() < 0.0001;
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
  );
}

class _CanvasLayer {
  const _CanvasLayer({
    required this.id,
    required this.type,
    this.bytes,
    this.originalPhotoBytes,
    this.text,
    this.legacyRenderText,
    this.sticker,
    this.textColor = const Color(0xFF0F172A),
    this.textAlign = TextAlign.center,
    this.textGradientIndex = -1,
    this.textOpacity = 1,
    this.fontSize = 40,
    this.fontFamily = 'Anek Telugu Condensed Regular',
    this.photoOpacity = 1,
    this.photoBrightness = 0,
    this.photoContrast = 1,
    this.photoSaturation = 1,
    this.photoBlur = 0,
    this.flipPhotoHorizontally = false,
    this.flipPhotoVertically = false,
    this.isLocked = false,
    this.isHidden = false,
    this.textLineHeight = 1.15,
    this.textLetterSpacing = 0,
    this.textShadowOpacity = 0,
    this.textShadowBlur = 0,
    this.textShadowOffsetY = 0,
    this.isTextBold = true,
    this.isTextItalic = false,
    this.isTextUnderline = false,
    this.textStrokeColor = const Color(0xFF000000),
    this.textStrokeWidth = 0,
    this.textStrokeGradientIndex = -1,
    this.textBackgroundColor = const Color(0x00000000),
    this.textBackgroundOpacity = 0,
    this.textBackgroundRadius = 0,
    this.photoAspectRatio,
    required this.transform,
  });

  final String id;
  final _CanvasLayerType type;
  final Uint8List? bytes;
  final Uint8List? originalPhotoBytes;
  final String? text;
  final String? legacyRenderText;
  final String? sticker;
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
  final bool flipPhotoHorizontally;
  final bool flipPhotoVertically;
  final bool isLocked;
  final bool isHidden;
  final double textLineHeight;
  final double textLetterSpacing;
  final double textShadowOpacity;
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
  final double? photoAspectRatio;
  final Matrix4 transform;

  bool get isPhoto => type == _CanvasLayerType.photo;
  bool get isText => type == _CanvasLayerType.text;
  bool get isSticker => type == _CanvasLayerType.sticker;

  _CanvasLayer copyWith({
    String? id,
    _CanvasLayerType? type,
    Uint8List? bytes,
    Uint8List? originalPhotoBytes,
    String? text,
    String? legacyRenderText,
    String? sticker,
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
    bool? flipPhotoHorizontally,
    bool? flipPhotoVertically,
    bool? isLocked,
    bool? isHidden,
    double? textLineHeight,
    double? textLetterSpacing,
    double? textShadowOpacity,
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
    double? photoAspectRatio,
    Matrix4? transform,
  }) {
    return _CanvasLayer(
      id: id ?? this.id,
      type: type ?? this.type,
      bytes: bytes ?? this.bytes,
      originalPhotoBytes: originalPhotoBytes ?? this.originalPhotoBytes,
      text: text ?? this.text,
      legacyRenderText: legacyRenderText ?? this.legacyRenderText,
      sticker: sticker ?? this.sticker,
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
      flipPhotoHorizontally:
          flipPhotoHorizontally ?? this.flipPhotoHorizontally,
      flipPhotoVertically: flipPhotoVertically ?? this.flipPhotoVertically,
      isLocked: isLocked ?? this.isLocked,
      isHidden: isHidden ?? this.isHidden,
      textLineHeight: textLineHeight ?? this.textLineHeight,
      textLetterSpacing: textLetterSpacing ?? this.textLetterSpacing,
      textShadowOpacity: textShadowOpacity ?? this.textShadowOpacity,
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
      photoAspectRatio: photoAspectRatio ?? this.photoAspectRatio,
      transform: transform ?? this.transform,
    );
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
    required this.borderTargetLayerId,
    required this.backgroundBlurAmount,
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final Color canvasBackgroundColor;
  final int canvasBackgroundGradientIndex;
  final Uint8List? stageBackgroundImageBytes;
  final _BorderStyle borderStyle;
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
