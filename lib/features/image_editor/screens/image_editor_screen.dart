// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/app/localization/app_language.dart';

import '../models/background_presets.dart';
import '../models/editor_template_document.dart';
import '../models/elements_catalog.dart';
import '../models/editor_page_config.dart';
import '../services/background_removal_service.dart';
import '../services/editor_draft_storage_service.dart';
import '../services/eraser_controller.dart';
import '../services/eraser_processor.dart';
import '../widgets/eraser_overlay.dart';

enum _CanvasLayerType { photo, text, sticker }

enum _ExportImageFormat { png, pngTransparent, jpg }

enum _EraserMode { erase, restore }

enum _EraserControl { brushSize, hardness, strength }

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
    this.sticker,
    this.textColor = const Color(0xFF0F172A),
    this.textAlign = TextAlign.center,
    this.textGradientIndex = -1,
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
  final String? sticker;
  final Color textColor;
  final TextAlign textAlign;
  final int textGradientIndex;
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
    String? sticker,
    Color? textColor,
    TextAlign? textAlign,
    int? textGradientIndex,
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
      sticker: sticker ?? this.sticker,
      textColor: textColor ?? this.textColor,
      textAlign: textAlign ?? this.textAlign,
      textGradientIndex: textGradientIndex ?? this.textGradientIndex,
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
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final Color canvasBackgroundColor;
  final int canvasBackgroundGradientIndex;
  final Uint8List? stageBackgroundImageBytes;
}

abstract class _EditorHistoryEntry {
  const _EditorHistoryEntry();
}

class _SnapshotHistoryEntry extends _EditorHistoryEntry {
  const _SnapshotHistoryEntry(this.snapshot);

  final _EditorSnapshot snapshot;
}

class _LayerChangeHistoryEntry extends _EditorHistoryEntry {
  const _LayerChangeHistoryEntry({
    required this.layerId,
    required this.beforeLayer,
    required this.afterLayer,
    required this.beforeSelectedLayerId,
    required this.afterSelectedLayerId,
  });

  final String layerId;
  final _CanvasLayer beforeLayer;
  final _CanvasLayer afterLayer;
  final String? beforeSelectedLayerId;
  final String? afterSelectedLayerId;
}

class _LayerInsertHistoryEntry extends _EditorHistoryEntry {
  const _LayerInsertHistoryEntry({
    required this.layer,
    required this.insertIndex,
    required this.beforeSelectedLayerId,
    required this.afterSelectedLayerId,
  });

  final _CanvasLayer layer;
  final int insertIndex;
  final String? beforeSelectedLayerId;
  final String? afterSelectedLayerId;
}

class _LayerDeleteHistoryEntry extends _EditorHistoryEntry {
  const _LayerDeleteHistoryEntry({
    required this.layer,
    required this.deletedIndex,
    required this.beforeSelectedLayerId,
    required this.afterSelectedLayerId,
  });

  final _CanvasLayer layer;
  final int deletedIndex;
  final String? beforeSelectedLayerId;
  final String? afterSelectedLayerId;
}

class _LayerReorderHistoryEntry extends _EditorHistoryEntry {
  const _LayerReorderHistoryEntry({
    required this.layerId,
    required this.fromIndex,
    required this.toIndex,
    required this.beforeSelectedLayerId,
    required this.afterSelectedLayerId,
  });

  final String layerId;
  final int fromIndex;
  final int toIndex;
  final String? beforeSelectedLayerId;
  final String? afterSelectedLayerId;
}

class _CanvasBackgroundHistoryEntry extends _EditorHistoryEntry {
  const _CanvasBackgroundHistoryEntry({
    required this.beforeColor,
    required this.beforeGradientIndex,
    required this.beforeImageBytes,
    required this.afterColor,
    required this.afterGradientIndex,
    required this.afterImageBytes,
  });

  final Color beforeColor;
  final int beforeGradientIndex;
  final Uint8List? beforeImageBytes;
  final Color afterColor;
  final int afterGradientIndex;
  final Uint8List? afterImageBytes;
}

@immutable
class _EditorCommitState {
  const _EditorCommitState({required this.label, required this.detail});

  final String label;
  final String detail;
}

@immutable
class _AdjustedPhotoPresentation {
  const _AdjustedPhotoPresentation({
    required this.provider,
    required this.blurSigma,
    required this.saturationMatrix,
    required this.brightnessContrastMatrix,
  });

  final ImageProvider<Object> provider;
  final double blurSigma;
  final List<double>? saturationMatrix;
  final List<double>? brightnessContrastMatrix;
}

class _PhotoLayerImageProviderCache {
  static const int _maxEntries = 72;
  static final LinkedHashMap<String, ImageProvider<Object>> _providers =
      LinkedHashMap<String, ImageProvider<Object>>();

  static ImageProvider<Object> resolve({
    required Uint8List bytes,
    required int? cacheWidth,
  }) {
    final key = '${identityHashCode(bytes)}_${bytes.length}_${cacheWidth ?? 0}';
    final existing = _providers.remove(key);
    if (existing != null) {
      _providers[key] = existing;
      return existing;
    }

    final provider = ResizeImage.resizeIfNeeded(
      cacheWidth,
      null,
      MemoryImage(bytes),
    );
    _providers[key] = provider;
    while (_providers.length > _maxEntries) {
      _providers.remove(_providers.keys.first);
    }
    return provider;
  }
}

class _AdjustedPhotoPresentationCache {
  static const int _maxEntries = 72;
  static final LinkedHashMap<String, _AdjustedPhotoPresentation> _entries =
      LinkedHashMap<String, _AdjustedPhotoPresentation>();

  static _AdjustedPhotoPresentation resolve({
    required Uint8List bytes,
    required String filterKey,
    required int? cacheWidth,
    required double brightness,
    required double contrast,
    required double saturation,
    required double blur,
  }) {
    final key = '${filterKey}_${cacheWidth ?? 0}';
    final existing = _entries.remove(key);
    if (existing != null) {
      _entries[key] = existing;
      return existing;
    }
    final presentation = _AdjustedPhotoPresentation(
      provider: _PhotoLayerImageProviderCache.resolve(
        bytes: bytes,
        cacheWidth: cacheWidth,
      ),
      blurSigma: blur > 0.01 ? _mapAdjustBlurToSigma(blur) : 0,
      saturationMatrix: (saturation - 1).abs() > 0.0001
          ? _saturationMatrix(saturation)
          : null,
      brightnessContrastMatrix:
          brightness.abs() > 0.0001 || (contrast - 1).abs() > 0.0001
          ? _brightnessContrastMatrix(
              brightness: brightness,
              contrast: contrast,
            )
          : null,
    );
    _entries[key] = presentation;
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return presentation;
  }
}

class _OptimizedPhotoPayload {
  const _OptimizedPhotoPayload({
    required this.bytes,
    required this.aspectRatio,
  });

  final Uint8List bytes;
  final double? aspectRatio;
}

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({
    super.key,
    this.pageConfig,
    this.templateDocumentSource,
  });

  final EditorPageConfig? pageConfig;
  final String? templateDocumentSource;

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen>
    with SingleTickerProviderStateMixin, AppLanguageStateMixin {
  static const double _topBarHeight = 68;
  static const double _bottomBarHeight = 92;
  static const double _cropBarHeight = 90;
  static const double _adjustBarHeight = 196;
  static const double _eraserBarHeight = 92;
  static const double _photoControlsExtraHeight = 84;
  static const double _textStyleBarHeight = 140;
  static const double _canvasChromeInset = 18;
  static const List<Color> _textColors = <Color>[
    Color(0xFF0F172A),
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFFFFFFF),
  ];
  static const List<List<Color>> _textGradients = <List<Color>>[
    <Color>[Color(0xFF2563EB), Color(0xFF7C3AED)],
    <Color>[Color(0xFFEC4899), Color(0xFFF59E0B)],
    <Color>[Color(0xFF10B981), Color(0xFF06B6D4)],
    <Color>[Color(0xFFEF4444), Color(0xFFF97316)],
  ];
  static const List<String> _textFontFamilies = <String>[
    'Anek Telugu Condensed Regular',
    'Anek Telugu Condensed Bold',
    'Anek Telugu Condensed Extra Bold',
    'Anek Telugu Condensed Extra Light',
    'Anek Telugu Condensed Light',
    'Anek Telugu Condensed Medium',
    'Noto Sans Telugu Condensed Black',
    'Noto Sans Telugu Condensed Bold',
    'Noto Sans Telugu Condensed Extra Bold',
    'Noto Sans Telugu Condensed Extra Light',
    'Noto Sans Telugu Condensed Light',
    'Aaradhana',
    'Abhilasha',
    'Ajantha',
    'Akshara',
    'Amrutha',
    'Anjali',
    'Anu Subhalekha Two',
    'Anupama Bold',
    'Anupama Extra Bold',
    'Anupama Medium',
    'Anupama Thin',
    'Anusha',
    'Apoorva',
    'Ashwini',
    'Bapu Bold',
    'Bapu Brush',
    'Bapu Script',
    'Bharghava',
    'Bhavya',
    'Brahma',
    'Brahma Script',
    'Chandra Script',
    'Deepika',
    'Dharani',
    'Geetha',
    'Gowthami Black',
    'Gowthami Bold',
    'Gowthami Extra Bold',
    'Gowthami Medium',
    'Gowthami Narrow',
    'Gowthami Thin',
    'Harsha',
    'Hiranya',
    'Jyothi',
    'Kalaanjali',
    'Keerthi Font',
    'Kranthi',
    'Kusuma',
    'Maanasa',
    'Madhubala',
    'Meena Script',
    'Mohini',
    'Natyamayuri',
    'Neelima',
    'Padmini',
    'Pallavi Bold',
    'Pallavi Medium',
    'Pallavi Thin',
    'Prabhava',
    'Pragathi',
    'Pragathi Italic',
    'Pragathi Narrow',
    'Pragathi Special',
    'Preethi',
    'Pridhvi',
    'Priyaanka',
    'Priyaanka Bold',
    'Rachana',
    'Rachana Bold',
    'Ramana Brush',
    'Ramana Script',
    'Ramana Script Medium',
    'Ravali',
    'Reshma',
    'Rohini',
    'Saagari',
    'Sanghavi',
    'Sowmya',
    'Sravya',
    'Subhadra',
    'Suchithra',
    'Sujatha',
    'Suneetha',
    'Supriya',
    'Tejafont',
    'Thripura',
    'Udayam',
    'Vaibhav',
    'Vasantha',
    'Vasundhara',
    'Veenaa',
    'Vikaas',
  ];
  final ImagePicker _imagePicker = ImagePicker();
  final TransformationController _transformationController =
      TransformationController();
  final TransformationController _cropTransformationController =
      TransformationController();
  final GlobalKey _stageRepaintKey = GlobalKey();
  final GlobalKey _cropBoundaryKey = GlobalKey();
  final EditorDraftStorageService _draftStorageService =
      const EditorDraftStorageService();
  final OfflineBackgroundRemovalService _backgroundRemovalService =
      const OfflineBackgroundRemovalService();
  late final EraserController _eraserController;

  final List<_CanvasLayer> _layers = <_CanvasLayer>[];
  final List<_EditorHistoryEntry> _undoStack = <_EditorHistoryEntry>[];
  final List<_EditorHistoryEntry> _redoStack = <_EditorHistoryEntry>[];
  String? _selectedLayerId;
  Color _canvasBackgroundColor = const Color(0xFFF4F7FC);
  int _canvasBackgroundGradientIndex = -1;
  int _layerSeed = 0;
  static const int _maxHistory = 40;
  _CanvasLayer? _fontSizeEditBeforeLayer;
  bool _isExporting = false;
  bool _isSharing = false;
  bool _isRemovingBackground = false;
  bool _isCapturingStage = false;
  bool _isTransparentExportCapture = false;
  bool _isCropMode = false;
  bool _isCropApplying = false;
  bool _suppressCanvasTapDown = false;
  int _suppressCanvasTapToken = 0;
  bool _showTextControls = false;
  bool _isAdjustMode = false;
  bool _isEraserMode = false;
  bool _isEraserInitializing = false;
  bool _isEraserApplying = false;
  String? _eraserSessionLayerId;
  String? _eraserInitError;
  bool _showJoyHint = true;
  bool _isLayerInteracting = false;
  int _removeBackgroundTaskId = 0;
  String? _activeCommitJobKey;
  Future<void> _commitJobTail = Future<void>.value();
  double? _pageAspectRatio;
  bool _pageAspectRatioAutoFromImage = false;
  Matrix4? _gestureStartMatrix;
  Offset _gestureStartFocalPoint = Offset.zero;
  Offset _gestureStartLocalFocalPoint = Offset.zero;
  Offset _photoGestureLastFocalPoint = Offset.zero;
  double _photoGestureLastScale = 1;
  double _photoGestureLastRotation = 0;
  double _stickerHandleStartAngle = 0;
  double _stickerHandleStartDistance = 1;
  Offset _photoGestureVelocity = Offset.zero;
  int _photoGestureLastTimestampMicros = 0;
  late final AnimationController _photoGlideController;
  late final Future<void> _backgroundRemoverInitialization;
  Offset _photoGlideTotalTravel = Offset.zero;
  Offset _photoGlideAppliedTravel = Offset.zero;
  Timer? _selectedTextLongPressTimer;
  Offset? _selectedTextPressPosition;
  static const double _snapThreshold = 18;
  static const double _rotationSnapThresholdRadians = math.pi / 24;
  Size _lastCanvasSize = Size.zero;
  Timer? _autosaveTimer;
  String? _adjustSessionLayerId;
  String _activeMainToolLabel = 'Add Photo';
  double _adjustSessionBrightness = 0;
  double _adjustSessionContrast = 1;
  double _adjustSessionSaturation = 1;
  double _adjustSessionBlur = 0;
  double _adjustInitialBrightness = 0;
  double _adjustInitialContrast = 1;
  double _adjustInitialSaturation = 1;
  double _adjustInitialBlur = 0;
  _EraserMode _eraserMode = _EraserMode.erase;
  _EraserControl? _activeEraserControl;
  double _eraserBrushSize = 40;
  double _eraserBrushHardness = 0.35;
  double _eraserBrushStrength = 1;
  final ValueNotifier<Offset?> _eraserBrushCursorNotifier =
      ValueNotifier<Offset?>(null);
  final ValueNotifier<ui.Image?> _eraserPreviewImageNotifier =
      ValueNotifier<ui.Image?>(null);
  final ValueNotifier<ui.Image?> _eraserRestorePreviewImageNotifier =
      ValueNotifier<ui.Image?>(null);
  final ValueNotifier<EraserStrokeChunk?> _eraserActiveStrokeNotifier =
      ValueNotifier<EraserStrokeChunk?>(null);
  final ValueNotifier<_SnapGuideState> _snapGuideNotifier =
      ValueNotifier<_SnapGuideState>(const _SnapGuideState.none());
  final ValueNotifier<_SelectedPhotoRenderState?> _selectedPhotoRenderNotifier =
      ValueNotifier<_SelectedPhotoRenderState?>(null);
  final ValueNotifier<_AdjustSessionState?> _adjustSessionNotifier =
      ValueNotifier<_AdjustSessionState?>(null);
  final ValueNotifier<_EditorCommitState?> _commitStateNotifier =
      ValueNotifier<_EditorCommitState?>(null);
  bool _isRestoringDraft = false;
  bool _pendingAutosave = false;
  Uint8List? _stageBackgroundImageBytes;
  Uint8List? _cropSessionImageBytes;
  String? _cropSessionLayerId;
  double? _cropSessionAspectRatio;
  double? _cropSessionInitialAspectRatio;
  EditorTemplateDocument? _templateDocument;
  bool _isTemplateHydrated = false;
  bool _isTemplateHydrationInProgress = false;
  bool _templateHydrationScheduled = false;
  Uint8List? _eraserSessionStartBytes;
  Uint8List? _eraserSessionRestoreBytes;
  Size _eraserSessionImagePixelSize = Size.zero;
  Uint8List? _eraserPreviewSessionStartBytes;
  Uint8List? _eraserPreviewBaseBytes;
  Uint8List? _eraserPreviewRestoreBytes;
  Size _eraserPreviewImagePixelSize = Size.zero;
  bool _isEraserBakeInProgress = false;
  bool _eraserBakeQueued = false;
  bool _isEraserPreviewRendering = false;
  bool _eraserPreviewRenderQueued = false;
  int _eraserPreviewRevision = 0;
  Timer? _eraserPreviewThrottleTimer;

  _CanvasLayer? get _selectedLayer {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return null;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1) {
      return null;
    }
    return _layers[index];
  }

  bool get _hasSelectedTextLayer => _selectedLayer?.isText ?? false;
  bool get _hasSelectedPhotoLayer => _selectedLayer?.isPhoto ?? false;
  bool get _isSelectedLayerLocked => _selectedLayer?.isLocked ?? false;
  _SnapGuideState get _snapGuides => _snapGuideNotifier.value;

  int get _selectedLayerIndex {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return -1;
    }
    return _layers.indexWhere((item) => item.id == selectedId);
  }

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  double _effectivePhotoBrightness(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionBrightness
      : layer.photoBrightness;

  double _effectivePhotoContrast(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionContrast
      : layer.photoContrast;

  double _effectivePhotoSaturation(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionSaturation
      : layer.photoSaturation;

  double _effectivePhotoBlur(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionBlur
      : layer.photoBlur;

  String? get _activeModeLabel {
    if (_isCropMode) {
      return 'Crop mode';
    }
    if (_isEraserMode) {
      return 'Eraser mode';
    }
    if (_isAdjustMode) {
      return 'Adjust mode';
    }
    if (_hasSelectedTextLayer) {
      return _showTextControls ? 'Text styling' : 'Text selected';
    }
    if (_hasSelectedPhotoLayer) {
      return 'Photo selected';
    }
    if (_selectedLayerId != null) {
      return 'Object selected';
    }
    return null;
  }

  String _localizedEditorLabel(BuildContext context, String label) {
    final strings = context.strings;
    switch (label) {
      case 'Add Photo':
        return strings.localized(telugu: 'ఫోటో', english: 'Add Photo');
      case 'Text':
        return strings.localized(telugu: 'టెక్స్ట్', english: 'Text');
      case 'Stickers':
        return strings.localized(telugu: 'స్టికర్స్', english: 'Stickers');
      case 'Background':
        return strings.localized(
          telugu: 'బ్యాక్‌గ్రౌండ్',
          english: 'Background',
        );
      case 'Layers':
        return strings.localized(telugu: 'లేయర్స్', english: 'Layers');
      case 'Adjust':
        return strings.localized(telugu: 'అడ్జస్ట్', english: 'Adjust');
      case 'Crop':
        return strings.localized(telugu: 'క్రాప్', english: 'Crop');
      case 'Eraser':
        return strings.localized(telugu: 'ఈరేసర్', english: 'Eraser');
      case 'Remove BG':
        return strings.localized(telugu: 'బీజీ తొలగింపు', english: 'Remove BG');
      case 'Removing...':
        return strings.localized(
          telugu: 'తొలగిస్తోంది...',
          english: 'Removing...',
        );
      case 'Edit':
        return strings.localized(telugu: 'ఎడిట్', english: 'Edit');
      case 'Fonts':
        return strings.localized(telugu: 'ఫాంట్స్', english: 'Fonts');
      case 'Options':
        return strings.localized(telugu: 'ఆప్షన్స్', english: 'Options');
      case 'Back':
        return strings.localized(telugu: 'వెనక్కి', english: 'Back');
      case 'Undo':
        return strings.localized(telugu: 'అన్డు', english: 'Undo');
      case 'Redo':
        return strings.localized(telugu: 'రీడో', english: 'Redo');
      case 'Drafts':
        return strings.localized(telugu: 'డ్రాఫ్ట్స్', english: 'Drafts');
      case 'Export':
        return strings.localized(telugu: 'ఎగుమతి', english: 'Export');
      case 'Saving...':
        return strings.localized(
          telugu: 'సేవ్ అవుతోంది...',
          english: 'Saving...',
        );
      case 'Send back':
        return strings.localized(telugu: 'వెనక్కి పంపు', english: 'Send back');
      case 'Bring front':
        return strings.localized(
          telugu: 'ముందుకు తీసుకురా',
          english: 'Bring front',
        );
      case 'Duplicate selected':
        return strings.localized(
          telugu: 'డూప్లికేట్',
          english: 'Duplicate selected',
        );
      case 'Delete selected':
        return strings.localized(telugu: 'డిలీట్', english: 'Delete selected');
      case 'Brush':
        return strings.localized(telugu: 'బ్రష్', english: 'Brush');
      case 'Soft':
        return strings.localized(telugu: 'సాఫ్ట్', english: 'Soft');
      case 'Strength':
        return strings.localized(telugu: 'స్ట్రెంగ్త్', english: 'Strength');
      case 'Reset':
        return strings.localized(telugu: 'రిసెట్', english: 'Reset');
      case 'Apply':
        return strings.localized(telugu: 'అప్లై', english: 'Apply');
      case 'Applying...':
        return strings.localized(
          telugu: 'అప్లై అవుతోంది...',
          english: 'Applying...',
        );
      case 'Erase':
        return strings.localized(telugu: 'తొలగించు', english: 'Erase');
      case 'Restore':
        return strings.localized(telugu: 'తిరిగి తెచ్చు', english: 'Restore');
      case 'Brightness':
        return strings.localized(telugu: 'బ్రైట్‌నెస్', english: 'Brightness');
      case 'Contrast':
        return strings.localized(telugu: 'కాంట్రాస్ట్', english: 'Contrast');
      case 'Saturation':
        return strings.localized(telugu: 'సాచురేషన్', english: 'Saturation');
      case 'Blur':
        return strings.localized(telugu: 'బ్లర్', english: 'Blur');
      case 'Free':
        return strings.localized(telugu: 'ఫ్రీ', english: 'Free');
      case 'Elements':
        return strings.localized(telugu: 'ఎలిమెంట్స్', english: 'Elements');
      case 'Search elements':
        return strings.localized(
          telugu: 'ఎలిమెంట్స్ వెతకండి',
          english: 'Search elements',
        );
      case 'Photo quick actions':
        return strings.localized(
          telugu: 'ఫోటో త్వరిత చర్యలు',
          english: 'Photo quick actions',
        );
      case 'Selected photo':
        return strings.localized(
          telugu: 'ఎంచుకున్న ఫోటో',
          english: 'Selected photo',
        );
      case 'Opacity':
        return strings.localized(telugu: 'అపాసిటీ', english: 'Opacity');
      case 'Text tools':
        return strings.localized(
          telugu: 'టెక్స్ట్ టూల్స్',
          english: 'Text tools',
        );
      case 'Image Editor':
        return strings.localized(
          telugu: 'ఇమేజ్ ఎడిటర్',
          english: 'Image Editor',
        );
      case 'Poster workspace':
        return strings.localized(
          telugu: 'పోస్టర్ వర్క్‌స్పేస్',
          english: 'Poster workspace',
        );
      case 'Crop mode':
        return strings.localized(telugu: 'క్రాప్ మోడ్', english: 'Crop mode');
      case 'Eraser mode':
        return strings.localized(telugu: 'ఈరేసర్ మోడ్', english: 'Eraser mode');
      case 'Adjust mode':
        return strings.localized(
          telugu: 'అడ్జస్ట్ మోడ్',
          english: 'Adjust mode',
        );
      case 'Text styling':
        return strings.localized(
          telugu: 'టెక్స్ట్ స్టైలింగ్',
          english: 'Text styling',
        );
      case 'Text selected':
        return strings.localized(
          telugu: 'టెక్స్ట్ ఎంపికైంది',
          english: 'Text selected',
        );
      case 'Photo selected':
        return strings.localized(
          telugu: 'ఫోటో ఎంపికైంది',
          english: 'Photo selected',
        );
      case 'Object selected':
        return strings.localized(
          telugu: 'ఆబ్జెక్ట్ ఎంపికైంది',
          english: 'Object selected',
        );
      default:
        return label;
    }
  }

  Color get _activeModeAccent {
    if (_isCropMode) {
      return const Color(0xFF2563EB);
    }
    if (_isEraserMode) {
      return const Color(0xFFEF4444);
    }
    if (_isAdjustMode) {
      return const Color(0xFF7C3AED);
    }
    if (_hasSelectedTextLayer) {
      return const Color(0xFFDB2777);
    }
    if (_hasSelectedPhotoLayer) {
      return const Color(0xFF0EA5E9);
    }
    if (_selectedLayerId != null) {
      return const Color(0xFF14B8A6);
    }
    return const Color(0xFF2563EB);
  }

  void _dismissJoyHint() {
    if (!_showJoyHint) {
      return;
    }
    setState(() {
      _showJoyHint = false;
    });
  }

  Future<void> _runMainToolAction(
    String label,
    FutureOr<void> Function() action,
  ) async {
    if (mounted && _activeMainToolLabel != label) {
      setState(() {
        _activeMainToolLabel = label;
      });
    }
    _dismissJoyHint();
    await action();
  }

  @override
  void initState() {
    super.initState();
    _eraserController = EraserController(checkpointEveryStrokes: 1);
    _photoGlideController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 460),
          )
          ..addListener(_handlePhotoGlideTick)
          ..addStatusListener((AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              _photoGlideAppliedTravel = Offset.zero;
              _photoGlideTotalTravel = Offset.zero;
              _syncSelectedLayerTransform();
            }
          });
    _pageAspectRatio = widget.pageConfig?.aspectRatio;
    _backgroundRemoverInitialization = BackgroundRemover.instance
        .initializeOrt();
    unawaited(
      _eraserController.loadPreferences().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _eraserBrushSize = _eraserController.settings.size;
          _eraserBrushHardness = _eraserController.settings.hardness;
          _eraserBrushStrength = _eraserController.settings.strength;
          _eraserMode = _eraserController.mode == EraserBlendMode.restore
              ? _EraserMode.restore
              : _EraserMode.erase;
        });
      }),
    );
    _enterEditorImmersiveMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.templateDocumentSource != null) {
        unawaited(_loadInitialTemplateDocument());
      } else {
        unawaited(_restoreAutosavedDraftIfAvailable());
      }
    });
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _refreshSelectedPhotoRenderState();
    if (_isRestoringDraft) {
      return;
    }
    if (_isLayerInteracting ||
        _isCapturingStage ||
        _isEraserMode ||
        _isAdjustMode ||
        _isCropMode) {
      _pendingAutosave = true;
      return;
    }
    _scheduleAutosave();
  }

  void _refreshSelectedPhotoRenderState() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isPhoto || layer.bytes == null) {
      if (_selectedPhotoRenderNotifier.value != null) {
        _selectedPhotoRenderNotifier.value = null;
      }
      return;
    }
    final liveAdjustState = _isAdjustMode && _adjustSessionLayerId == layer.id
        ? _adjustSessionNotifier.value
        : null;
    final nextState = _SelectedPhotoRenderState(
      layerId: layer.id,
      bytes: layer.bytes!,
      opacity: layer.photoOpacity,
      flipHorizontally: layer.flipPhotoHorizontally,
      flipVertically: layer.flipPhotoVertically,
      brightness: liveAdjustState?.brightness ?? layer.photoBrightness,
      contrast: liveAdjustState?.contrast ?? layer.photoContrast,
      saturation: liveAdjustState?.saturation ?? layer.photoSaturation,
      blur: liveAdjustState?.blur ?? layer.photoBlur,
    );
    if (_selectedPhotoRenderNotifier.value != nextState) {
      _selectedPhotoRenderNotifier.value = nextState;
    }
  }

  Future<void> _enterEditorImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restoreSystemUiMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _loadInitialTemplateDocument() async {
    final source = widget.templateDocumentSource;
    if (source == null || source.isEmpty) {
      return;
    }
    try {
      final raw = await _loadTemplateDocumentString(source);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final document = EditorTemplateDocument.fromJson(decoded);
      if (!mounted) {
        return;
      }
      setState(() {
        _templateDocument = document;
        _pageAspectRatio = document.aspectRatio;
        _pageAspectRatioAutoFromImage = false;
        _isTemplateHydrated = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'టెంప్లేట్ లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి',
              english: 'Template failed to load. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<String> _loadTemplateDocumentString(String source) async {
    if (_looksLikeNetworkSource(source)) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(source));
        final response = await request.close();
        return await response.transform(utf8.decoder).join();
      } finally {
        client.close(force: true);
      }
    }
    return rootBundle.loadString(source);
  }

  Future<Uint8List> _loadTemplateLayerBytes(String source) async {
    if (_looksLikeNetworkSource(source)) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(source));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        return bytes;
      } finally {
        client.close(force: true);
      }
    }
    final assetData = await rootBundle.load(source);
    return assetData.buffer.asUint8List();
  }

  bool _looksLikeNetworkSource(String source) {
    final normalized = source.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  Future<void> _hydrateTemplateDocument({
    required EditorTemplateDocument document,
    required Size pageSize,
  }) async {
    if (_isTemplateHydrated ||
        _isTemplateHydrationInProgress ||
        pageSize.width <= 0 ||
        pageSize.height <= 0) {
      return;
    }

    _isTemplateHydrationInProgress = true;
    try {
      final importedLayers = <_CanvasLayer>[];
      final pageCenter = Offset(pageSize.width / 2, pageSize.height / 2);

      for (final templateLayer in document.layers) {
        if (!templateLayer.visible ||
            templateLayer.assetPath.isEmpty ||
            templateLayer.width <= 0 ||
            templateLayer.height <= 0) {
          continue;
        }

        Uint8List bytes;
        try {
          bytes = await _loadTemplateLayerBytes(templateLayer.assetPath);
        } catch (error, stackTrace) {
          debugPrint(
            'Template layer load failed for ${templateLayer.assetPath}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
          continue;
        }
        final aspectRatio = templateLayer.width / templateLayer.height;
        final targetWidth =
            (templateLayer.width / document.sourceWidth) * pageSize.width;
        final baseSize = _fitPhotoLayerSize(
          pageSize: pageSize,
          photoAspectRatio: aspectRatio,
        );
        final scale = baseSize.width <= 0
            ? 1.0
            : (targetWidth / baseSize.width).clamp(0.01, 100.0);
        final targetCenter = Offset(
          ((templateLayer.left + (templateLayer.width / 2)) /
                  document.sourceWidth) *
              pageSize.width,
          ((templateLayer.top + (templateLayer.height / 2)) /
                  document.sourceHeight) *
              pageSize.height,
        );
        final translation = targetCenter - pageCenter;
        final transform = Matrix4.identity()
          ..translateByDouble(translation.dx, translation.dy, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1);

        importedLayers.add(
          _CanvasLayer(
            id: 'layer_${_layerSeed++}',
            type: _CanvasLayerType.photo,
            bytes: bytes,
            originalPhotoBytes: bytes,
            photoOpacity: templateLayer.opacity,
            photoAspectRatio: aspectRatio,
            transform: transform,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _layers
          ..clear()
          ..addAll(importedLayers);
        _selectedLayerId = importedLayers.isEmpty
            ? null
            : importedLayers.last.id;
        _canvasBackgroundColor = const Color(0xFFFFFFFF);
        _canvasBackgroundGradientIndex = -1;
        _stageBackgroundImageBytes = null;
        _templateDocument = null;
        _isTemplateHydrated = true;
      });
      if (importedLayers.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.localized(
                telugu: 'టెంప్లేట్ లేయర్లు లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి',
                english: 'Template layers failed to load. Please try again.',
              ),
            ),
          ),
        );
      }
    } finally {
      _isTemplateHydrationInProgress = false;
    }
  }

  /*
  Future<SubscriptionBackendResult?> _syncEntitlementFromBackend({
    required bool showErrors,
  }) async {
    final result = await _subscriptionBackendService.fetchEntitlement();
    if (!mounted) {
      return null;
    }
    if (!result.isConfigured) {
      return result;
    }

    if (result.isSuccess) {
      await _setProStatus(result.isPro);
      return result;
    }

    if (showErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Subscription backend sync fail అయ్యింది. కొద్దిసేపటి తర్వాత మళ్లీ try చేయండి',
          ),
        ),
      );
    }
    return result;
  }

  Future<bool> _verifyEntitlementAfterPurchase(
    PurchaseVerificationEvidence? evidence,
  ) async {
    if (!_subscriptionBackendService.isConfigured) {
      await _setProStatus(true);
      return true;
    }
    if (evidence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Purchase verification data దొరకలేదు. Restore/Retry చేయండి',
          ),
        ),
      );
      return false;
    }

    final result = await _subscriptionBackendService.verifyPurchase(
      evidence: evidence,
    );
    if (!mounted) {
      return false;
    }

    if (result.isSuccess) {
      await _setProStatus(result.isPro);
      if (!mounted) {
        return false;
      }
      if (result.isPro) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Purchase complete అయినా entitlement active కాలేదు. Support ని సంప్రదించండి',
          ),
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message?.isNotEmpty == true
              ? 'Verification fail: ${result.message}'
              : 'Subscription verification fail అయ్యింది',
        ),
      ),
    );
    return false;
  }

  */
  _CanvasLayer _cloneLayer(_CanvasLayer layer) {
    return layer.copyWith(transform: Matrix4.copy(layer.transform));
  }

  _EditorSnapshot _takeSnapshot() {
    return _EditorSnapshot(
      layers: _layers.map(_cloneLayer).toList(growable: false),
      selectedLayerId: _selectedLayerId,
      canvasBackgroundColor: _canvasBackgroundColor,
      canvasBackgroundGradientIndex: _canvasBackgroundGradientIndex,
      stageBackgroundImageBytes: _stageBackgroundImageBytes == null
          ? null
          : Uint8List.fromList(_stageBackgroundImageBytes!),
    );
  }

  void _pushUndoSnapshot() {
    _undoStack.add(_SnapshotHistoryEntry(_takeSnapshot()));
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pushLayerHistoryEntry({
    required _CanvasLayer beforeLayer,
    required _CanvasLayer afterLayer,
    String? beforeSelectedLayerId,
    String? afterSelectedLayerId,
  }) {
    _undoStack.add(
      _LayerChangeHistoryEntry(
        layerId: beforeLayer.id,
        beforeLayer: _cloneLayer(beforeLayer),
        afterLayer: _cloneLayer(afterLayer),
        beforeSelectedLayerId: beforeSelectedLayerId ?? _selectedLayerId,
        afterSelectedLayerId: afterSelectedLayerId ?? _selectedLayerId,
      ),
    );
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pushLayerInsertHistoryEntry({
    required _CanvasLayer layer,
    required int insertIndex,
    required String? beforeSelectedLayerId,
    required String? afterSelectedLayerId,
  }) {
    _undoStack.add(
      _LayerInsertHistoryEntry(
        layer: _cloneLayer(layer),
        insertIndex: insertIndex,
        beforeSelectedLayerId: beforeSelectedLayerId,
        afterSelectedLayerId: afterSelectedLayerId,
      ),
    );
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pushLayerDeleteHistoryEntry({
    required _CanvasLayer layer,
    required int deletedIndex,
    required String? beforeSelectedLayerId,
    required String? afterSelectedLayerId,
  }) {
    _undoStack.add(
      _LayerDeleteHistoryEntry(
        layer: _cloneLayer(layer),
        deletedIndex: deletedIndex,
        beforeSelectedLayerId: beforeSelectedLayerId,
        afterSelectedLayerId: afterSelectedLayerId,
      ),
    );
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pushLayerReorderHistoryEntry({
    required String layerId,
    required int fromIndex,
    required int toIndex,
    required String? beforeSelectedLayerId,
    required String? afterSelectedLayerId,
  }) {
    _undoStack.add(
      _LayerReorderHistoryEntry(
        layerId: layerId,
        fromIndex: fromIndex,
        toIndex: toIndex,
        beforeSelectedLayerId: beforeSelectedLayerId,
        afterSelectedLayerId: afterSelectedLayerId,
      ),
    );
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _setCommitState(String? label, {String? detail}) {
    _commitStateNotifier.value = label == null
        ? null
        : _EditorCommitState(
            label: label,
            detail: detail ?? 'Please wait while the layer is updated',
          );
  }

  bool get _isCommitWorkerBusy => _activeCommitJobKey != null;

  Future<T?> _runQueuedCommitJob<T>({
    required String jobKey,
    required String label,
    required String detail,
    required Future<T> Function() operation,
    VoidCallback? onStart,
    VoidCallback? onFinish,
    bool showBusyMessage = true,
  }) async {
    if (_activeCommitJobKey != null) {
      if (showBusyMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.localized(
                telugu: 'ప్రస్తుత ఎడిటర్ పని పూర్తయ్యే వరకు వేచి ఉండండి',
                english: 'Please wait, current editor job is still running',
              ),
            ),
          ),
        );
      }
      return null;
    }

    _activeCommitJobKey = jobKey;
    if (mounted && onStart != null) {
      setState(onStart);
    } else {
      onStart?.call();
    }
    _setCommitState(label, detail: detail);

    Future<T> runOperation() async => operation();

    final scheduled = _commitJobTail.then((_) => runOperation());
    _commitJobTail = scheduled.then<void>((_) {}, onError: (_, stackTrace) {});

    try {
      return await scheduled;
    } finally {
      if (mounted && onFinish != null) {
        setState(onFinish);
      } else {
        onFinish?.call();
      }
      if (_activeCommitJobKey == jobKey) {
        _activeCommitJobKey = null;
      }
      _setCommitState(null);
    }
  }

  void _pushCanvasBackgroundHistoryEntry({
    required Color beforeColor,
    required int beforeGradientIndex,
    required Uint8List? beforeImageBytes,
    required Color afterColor,
    required int afterGradientIndex,
    required Uint8List? afterImageBytes,
  }) {
    _undoStack.add(
      _CanvasBackgroundHistoryEntry(
        beforeColor: beforeColor,
        beforeGradientIndex: beforeGradientIndex,
        beforeImageBytes: beforeImageBytes == null
            ? null
            : Uint8List.fromList(beforeImageBytes),
        afterColor: afterColor,
        afterGradientIndex: afterGradientIndex,
        afterImageBytes: afterImageBytes == null
            ? null
            : Uint8List.fromList(afterImageBytes),
      ),
    );
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _replaceLayerWithHistory({
    required int index,
    required _CanvasLayer afterLayer,
    String? afterSelectedLayerId,
  }) {
    final beforeLayer = _layers[index];
    _pushLayerHistoryEntry(
      beforeLayer: beforeLayer,
      afterLayer: afterLayer,
      afterSelectedLayerId: afterSelectedLayerId,
    );
    setState(() {
      _layers[index] = afterLayer;
      if (afterSelectedLayerId != null) {
        _selectedLayerId = afterSelectedLayerId;
      }
      if (_selectedLayerId == afterLayer.id) {
        _transformationController.value = Matrix4.copy(afterLayer.transform);
      }
    });
  }

  bool _isSameMatrix(Matrix4 a, Matrix4 b) {
    for (var i = 0; i < 16; i++) {
      if ((a.storage[i] - b.storage[i]).abs() > 0.0001) {
        return false;
      }
    }
    return true;
  }

  void _syncControllerFromSelection() {
    final layer = _selectedLayer;
    if (layer == null) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    _transformationController.value = Matrix4.copy(layer.transform);
  }

  void _restoreSnapshot(_EditorSnapshot snapshot) {
    _layers
      ..clear()
      ..addAll(snapshot.layers.map(_cloneLayer));
    _selectedLayerId = snapshot.selectedLayerId;
    _canvasBackgroundColor = snapshot.canvasBackgroundColor;
    _canvasBackgroundGradientIndex = snapshot.canvasBackgroundGradientIndex;
    _stageBackgroundImageBytes = snapshot.stageBackgroundImageBytes == null
        ? null
        : Uint8List.fromList(snapshot.stageBackgroundImageBytes!);
    _syncControllerFromSelection();
  }

  void _handleUndo() {
    if (!_canUndo) {
      return;
    }

    _closeTransientSessionsForHistory();
    final previous = _undoStack.removeLast();
    if (previous is _SnapshotHistoryEntry) {
      _redoStack.add(_SnapshotHistoryEntry(_takeSnapshot()));
      setState(() {
        _restoreSnapshot(previous.snapshot);
      });
      return;
    }
    if (previous is _LayerChangeHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyLayerHistoryEntry(previous, useAfter: false);
      });
      return;
    }
    if (previous is _LayerInsertHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyLayerInsertHistoryEntry(previous, useAfter: false);
      });
      return;
    }
    if (previous is _LayerDeleteHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyLayerDeleteHistoryEntry(previous, useAfter: false);
      });
      return;
    }
    if (previous is _LayerReorderHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyLayerReorderHistoryEntry(previous, useAfter: false);
      });
      return;
    }
    if (previous is _CanvasBackgroundHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyCanvasBackgroundHistoryEntry(previous, useAfter: false);
      });
    }
  }

  void _handleRedo() {
    if (!_canRedo) {
      return;
    }

    _closeTransientSessionsForHistory();
    final next = _redoStack.removeLast();
    if (next is _SnapshotHistoryEntry) {
      _undoStack.add(_SnapshotHistoryEntry(_takeSnapshot()));
      setState(() {
        _restoreSnapshot(next.snapshot);
      });
      return;
    }
    if (next is _LayerChangeHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyLayerHistoryEntry(next, useAfter: true);
      });
      return;
    }
    if (next is _LayerInsertHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyLayerInsertHistoryEntry(next, useAfter: true);
      });
      return;
    }
    if (next is _LayerDeleteHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyLayerDeleteHistoryEntry(next, useAfter: true);
      });
      return;
    }
    if (next is _LayerReorderHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyLayerReorderHistoryEntry(next, useAfter: true);
      });
      return;
    }
    if (next is _CanvasBackgroundHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyCanvasBackgroundHistoryEntry(next, useAfter: true);
      });
    }
  }

  void _applyLayerHistoryEntry(
    _LayerChangeHistoryEntry entry, {
    required bool useAfter,
  }) {
    final targetLayer = useAfter ? entry.afterLayer : entry.beforeLayer;
    final targetSelectedLayerId = useAfter
        ? entry.afterSelectedLayerId
        : entry.beforeSelectedLayerId;
    final index = _layers.indexWhere((item) => item.id == entry.layerId);
    if (index == -1) {
      return;
    }
    _layers[index] = _cloneLayer(targetLayer);
    _selectedLayerId = targetSelectedLayerId;
    _syncControllerFromSelection();
  }

  void _applyLayerInsertHistoryEntry(
    _LayerInsertHistoryEntry entry, {
    required bool useAfter,
  }) {
    if (useAfter) {
      final existingIndex = _layers.indexWhere(
        (item) => item.id == entry.layer.id,
      );
      if (existingIndex == -1) {
        final insertIndex = entry.insertIndex.clamp(0, _layers.length);
        _layers.insert(insertIndex, _cloneLayer(entry.layer));
      } else {
        final layer = _layers.removeAt(existingIndex);
        final insertIndex = entry.insertIndex.clamp(0, _layers.length);
        _layers.insert(insertIndex, layer);
      }
      _selectedLayerId = entry.afterSelectedLayerId;
    } else {
      _layers.removeWhere((item) => item.id == entry.layer.id);
      _selectedLayerId = entry.beforeSelectedLayerId;
    }
    _syncControllerFromSelection();
  }

  void _applyLayerDeleteHistoryEntry(
    _LayerDeleteHistoryEntry entry, {
    required bool useAfter,
  }) {
    if (useAfter) {
      _layers.removeWhere((item) => item.id == entry.layer.id);
      _selectedLayerId = entry.afterSelectedLayerId;
    } else {
      final existingIndex = _layers.indexWhere(
        (item) => item.id == entry.layer.id,
      );
      if (existingIndex == -1) {
        final insertIndex = entry.deletedIndex.clamp(0, _layers.length);
        _layers.insert(insertIndex, _cloneLayer(entry.layer));
      }
      _selectedLayerId = entry.beforeSelectedLayerId;
    }
    _syncControllerFromSelection();
  }

  void _applyLayerReorderHistoryEntry(
    _LayerReorderHistoryEntry entry, {
    required bool useAfter,
  }) {
    final currentIndex = _layers.indexWhere((item) => item.id == entry.layerId);
    if (currentIndex == -1) {
      return;
    }
    final targetIndex = useAfter ? entry.toIndex : entry.fromIndex;
    final boundedTargetIndex = targetIndex.clamp(0, _layers.length - 1);
    if (currentIndex != boundedTargetIndex) {
      final layer = _layers.removeAt(currentIndex);
      final insertIndex = boundedTargetIndex.clamp(0, _layers.length);
      _layers.insert(insertIndex, layer);
    }
    _selectedLayerId = useAfter
        ? entry.afterSelectedLayerId
        : entry.beforeSelectedLayerId;
    _syncControllerFromSelection();
  }

  void _applyCanvasBackgroundHistoryEntry(
    _CanvasBackgroundHistoryEntry entry, {
    required bool useAfter,
  }) {
    _canvasBackgroundColor = useAfter ? entry.afterColor : entry.beforeColor;
    _canvasBackgroundGradientIndex = useAfter
        ? entry.afterGradientIndex
        : entry.beforeGradientIndex;
    final bytes = useAfter ? entry.afterImageBytes : entry.beforeImageBytes;
    _stageBackgroundImageBytes = bytes == null
        ? null
        : Uint8List.fromList(bytes);
  }

  void _closeTransientSessionsForHistory() {
    if (_isCropMode) {
      _isCropMode = false;
      _isCropApplying = false;
      _cropSessionLayerId = null;
      _cropSessionImageBytes = null;
      _cropSessionAspectRatio = null;
      _cropSessionInitialAspectRatio = null;
      _cropTransformationController.value = Matrix4.identity();
    }
    if (_isAdjustMode) {
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _adjustSessionNotifier.value = null;
    }
    if (_isEraserMode || _isEraserInitializing || _isEraserApplying) {
      _isEraserMode = false;
      _isEraserInitializing = false;
      _isEraserApplying = false;
      _eraserSessionLayerId = null;
      _activeEraserControl = null;
      _eraserInitError = null;
      _disposeEraserSessionResources();
    }
    _setCommitState(null);
  }

  List<double> _matrixToList(Matrix4 matrix) =>
      matrix.storage.map((value) => value.toDouble()).toList(growable: false);

  Matrix4 _matrixFromList(dynamic value) {
    if (value is List && value.length == 16) {
      return Matrix4.fromList(
        value.map((item) => (item as num).toDouble()).toList(growable: false),
      );
    }
    return Matrix4.identity();
  }

  Map<String, dynamic> _serializeLayer(_CanvasLayer layer) {
    return <String, dynamic>{
      'id': layer.id,
      'type': layer.type.name,
      'bytes': layer.bytes == null ? null : base64Encode(layer.bytes!),
      'originalPhotoBytes': layer.originalPhotoBytes == null
          ? null
          : base64Encode(layer.originalPhotoBytes!),
      'text': layer.text,
      'sticker': layer.sticker,
      'textColor': layer.textColor.toARGB32(),
      'textAlign': layer.textAlign.name,
      'textGradientIndex': layer.textGradientIndex,
      'fontSize': layer.fontSize,
      'fontFamily': layer.fontFamily,
      'photoOpacity': layer.photoOpacity,
      'photoBrightness': layer.photoBrightness,
      'photoContrast': layer.photoContrast,
      'photoSaturation': layer.photoSaturation,
      'photoBlur': layer.photoBlur,
      'flipPhotoHorizontally': layer.flipPhotoHorizontally,
      'flipPhotoVertically': layer.flipPhotoVertically,
      'isLocked': layer.isLocked,
      'isHidden': layer.isHidden,
      'textLineHeight': layer.textLineHeight,
      'textLetterSpacing': layer.textLetterSpacing,
      'textShadowOpacity': layer.textShadowOpacity,
      'textShadowBlur': layer.textShadowBlur,
      'textShadowOffsetY': layer.textShadowOffsetY,
      'isTextBold': layer.isTextBold,
      'isTextItalic': layer.isTextItalic,
      'isTextUnderline': layer.isTextUnderline,
      'textStrokeColor': layer.textStrokeColor.toARGB32(),
      'textStrokeWidth': layer.textStrokeWidth,
      'textBackgroundColor': layer.textBackgroundColor.toARGB32(),
      'textBackgroundOpacity': layer.textBackgroundOpacity,
      'textBackgroundRadius': layer.textBackgroundRadius,
      'photoAspectRatio': layer.photoAspectRatio,
      'transform': _matrixToList(layer.transform),
    };
  }

  _CanvasLayer? _deserializeLayer(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    try {
      final typeName = raw['type'] as String? ?? _CanvasLayerType.text.name;
      final type = _CanvasLayerType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => _CanvasLayerType.text,
      );
      final textAlignName =
          raw['textAlign'] as String? ?? TextAlign.center.name;
      final textAlign = TextAlign.values.firstWhere(
        (item) => item.name == textAlignName,
        orElse: () => TextAlign.center,
      );
      return _CanvasLayer(
        id:
            raw['id'] as String? ??
            'layer_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        bytes: raw['bytes'] == null
            ? null
            : base64Decode(raw['bytes'] as String),
        originalPhotoBytes: raw['originalPhotoBytes'] == null
            ? null
            : base64Decode(raw['originalPhotoBytes'] as String),
        text: raw['text'] as String?,
        sticker: raw['sticker'] as String?,
        textColor: Color((raw['textColor'] as num?)?.toInt() ?? 0xFF0F172A),
        textAlign: textAlign,
        textGradientIndex: (raw['textGradientIndex'] as num?)?.toInt() ?? -1,
        fontSize: (raw['fontSize'] as num?)?.toDouble() ?? 40,
        fontFamily:
            raw['fontFamily'] as String? ?? 'Anek Telugu Condensed Regular',
        photoOpacity: (raw['photoOpacity'] as num?)?.toDouble() ?? 1,
        photoBrightness: (raw['photoBrightness'] as num?)?.toDouble() ?? 0,
        photoContrast: (raw['photoContrast'] as num?)?.toDouble() ?? 1,
        photoSaturation: (raw['photoSaturation'] as num?)?.toDouble() ?? 1,
        photoBlur: (raw['photoBlur'] as num?)?.toDouble() ?? 0,
        flipPhotoHorizontally: (raw['flipPhotoHorizontally'] as bool?) ?? false,
        flipPhotoVertically: (raw['flipPhotoVertically'] as bool?) ?? false,
        isLocked: (raw['isLocked'] as bool?) ?? false,
        isHidden: (raw['isHidden'] as bool?) ?? false,
        textLineHeight: (raw['textLineHeight'] as num?)?.toDouble() ?? 1.15,
        textLetterSpacing: (raw['textLetterSpacing'] as num?)?.toDouble() ?? 0,
        textShadowOpacity: (raw['textShadowOpacity'] as num?)?.toDouble() ?? 0,
        textShadowBlur: (raw['textShadowBlur'] as num?)?.toDouble() ?? 0,
        textShadowOffsetY: (raw['textShadowOffsetY'] as num?)?.toDouble() ?? 0,
        isTextBold: (raw['isTextBold'] as bool?) ?? true,
        isTextItalic: (raw['isTextItalic'] as bool?) ?? false,
        isTextUnderline: (raw['isTextUnderline'] as bool?) ?? false,
        textStrokeColor: Color(
          (raw['textStrokeColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        textStrokeWidth: (raw['textStrokeWidth'] as num?)?.toDouble() ?? 0,
        textBackgroundColor: Color(
          (raw['textBackgroundColor'] as num?)?.toInt() ?? 0x00000000,
        ),
        textBackgroundOpacity:
            (raw['textBackgroundOpacity'] as num?)?.toDouble() ?? 0,
        textBackgroundRadius:
            (raw['textBackgroundRadius'] as num?)?.toDouble() ?? 0,
        photoAspectRatio: (raw['photoAspectRatio'] as num?)?.toDouble(),
        transform: _matrixFromList(raw['transform']),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _serializeEditorDraft() {
    return <String, dynamic>{
      'layerSeed': _layerSeed,
      'selectedLayerId': _selectedLayerId,
      'canvasBackgroundColor': _canvasBackgroundColor.toARGB32(),
      'canvasBackgroundGradientIndex': _canvasBackgroundGradientIndex,
      'stageBackgroundImageBytes': _stageBackgroundImageBytes == null
          ? null
          : base64Encode(_stageBackgroundImageBytes!),
      'pageAspectRatio': _pageAspectRatio,
      'pageAspectRatioAutoFromImage': _pageAspectRatioAutoFromImage,
      'layers': _layers.map(_serializeLayer).toList(growable: false),
      'savedAt': DateTime.now().toIso8601String(),
    };
  }

  void _scheduleAutosave() {
    _pendingAutosave = false;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 900), () {
      unawaited(_persistAutosaveDraft());
    });
  }

  Future<void> _persistAutosaveDraft() async {
    try {
      final file = await _draftStorageService.getAutosaveFile();
      await file.writeAsString(jsonEncode(_serializeEditorDraft()));
    } catch (_) {}
  }

  Future<void> _restoreFromDecodedDraft(
    Map decoded, {
    bool resetHistory = true,
  }) async {
    final rawLayers = decoded['layers'];
    if (rawLayers is! List || rawLayers.isEmpty) {
      return;
    }
    final restoredLayers = rawLayers
        .map(_deserializeLayer)
        .whereType<_CanvasLayer>()
        .toList(growable: true);
    if (restoredLayers.isEmpty) {
      return;
    }
    _isRestoringDraft = true;
    setState(() {
      _layers
        ..clear()
        ..addAll(restoredLayers);
      _layerSeed =
          (decoded['layerSeed'] as num?)?.toInt() ?? restoredLayers.length;
      _selectedLayerId = decoded['selectedLayerId'] as String?;
      _canvasBackgroundColor = Color(
        (decoded['canvasBackgroundColor'] as num?)?.toInt() ?? 0xFFF4F7FC,
      );
      _canvasBackgroundGradientIndex =
          (decoded['canvasBackgroundGradientIndex'] as num?)?.toInt() ?? -1;
      _stageBackgroundImageBytes =
          decoded['stageBackgroundImageBytes'] is String
          ? base64Decode(decoded['stageBackgroundImageBytes'] as String)
          : null;
      _pageAspectRatio = (decoded['pageAspectRatio'] as num?)?.toDouble();
      _pageAspectRatioAutoFromImage =
          (decoded['pageAspectRatioAutoFromImage'] as bool?) ?? false;
      _syncControllerFromSelection();
    });
    if (resetHistory) {
      _undoStack.clear();
      _redoStack.clear();
    }
    _isRestoringDraft = false;
  }

  Future<void> _restoreAutosavedDraftIfAvailable() async {
    if (widget.pageConfig != null) {
      return;
    }
    try {
      final file = await _draftStorageService.getAutosaveFile();
      if (!await file.exists()) {
        return;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return;
      }
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        return;
      }
      if (!mounted) {
        return;
      }
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          final strings = context.strings;
          return AlertDialog(
            title: Text(
              strings.localized(
                telugu: 'Recover Draft',
                english: 'Recover Draft',
              ),
            ),
            content: Text(
              strings.localized(
                telugu:
                    'Last autosaved project dorikindi. Danni restore cheyala?',
                english:
                    'A last autosaved project was found. Do you want to restore it?',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.localized(telugu: 'No', english: 'No')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  strings.localized(telugu: 'Restore', english: 'Restore'),
                ),
              ),
            ],
          );
        },
      );
      if (shouldRestore != true) {
        return;
      }
      await _restoreFromDecodedDraft(decoded);
    } catch (_) {}
  }

  Future<void> _saveCurrentManualDraft() async {
    try {
      final file = await _draftStorageService.createManualDraftFile();
      await file.writeAsString(jsonEncode(_serializeEditorDraft()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Draft saved in app storage',
              english: 'Draft saved in app storage',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Draft save fail ayyindi',
              english: 'Draft save failed',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openDraftsScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _DraftsScreen(
          storageService: _draftStorageService,
          onSaveCurrentDraft: _saveCurrentManualDraft,
          onOpenDraft: (Map<String, dynamic> draft) async {
            await _restoreFromDecodedDraft(draft);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposeEraserSessionResources();
    _eraserController.dispose();
    _eraserBrushCursorNotifier.dispose();
    _eraserPreviewImageNotifier.value?.dispose();
    _eraserPreviewImageNotifier.dispose();
    _eraserRestorePreviewImageNotifier.value?.dispose();
    _eraserRestorePreviewImageNotifier.dispose();
    _eraserActiveStrokeNotifier.dispose();
    _snapGuideNotifier.dispose();
    _selectedPhotoRenderNotifier.dispose();
    _adjustSessionNotifier.dispose();
    _commitStateNotifier.dispose();
    _autosaveTimer?.cancel();
    unawaited(_persistAutosaveDraft());
    unawaited(BackgroundRemover.instance.dispose());
    _photoGlideController.dispose();
    _selectedTextLongPressTimer?.cancel();
    _transformationController.dispose();
    _cropTransformationController.dispose();
    unawaited(_restoreSystemUiMode());
    super.dispose();
  }

  Future<void> _handleAddPhoto() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
    if (!mounted || pickedFile == null) {
      return;
    }

    final rawBytes = await pickedFile.readAsBytes();
    final optimizedPhoto = await compute(_optimizeEditorPhotoPayload, rawBytes);
    final bytes = optimizedPhoto.bytes;
    if (!mounted) {
      return;
    }

    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.photo,
      bytes: bytes,
      originalPhotoBytes: bytes,
      photoAspectRatio: optimizedPhoto.aspectRatio,
      transform: Matrix4.identity(),
    );

    _pushUndoSnapshot();
    _transformationController.value = Matrix4.identity();
    setState(() {
      if (_pageAspectRatio == null && optimizedPhoto.aspectRatio != null) {
        _pageAspectRatio = optimizedPhoto.aspectRatio;
        _pageAspectRatioAutoFromImage = widget.pageConfig == null;
      }
      _layers.add(layer);
      _selectedLayerId = layer.id;
    });
  }

  Future<void> _handleAddText() async {
    String defaultFontFamily = 'Anek Telugu Condensed Regular';
    String defaultText = 'Text';
    final AppLanguage currentLanguage = context.currentLanguage;
    try {
      final posterProfile = await PosterProfileService.load();
      if (_textFontFamilies.contains(posterProfile.nameFontFamily)) {
        defaultFontFamily = posterProfile.nameFontFamily;
      }
      final resolvedName = posterProfile.resolvedName(
        language: currentLanguage,
      );
      if (resolvedName.trim().isNotEmpty) {
        defaultText = resolvedName.trim();
      }
    } catch (_) {
      // Ignore profile load failures and fallback to editor default.
    }

    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.text,
      text: defaultText,
      fontFamily: defaultFontFamily,
      transform: Matrix4.identity(),
    );

    _pushLayerInsertHistoryEntry(
      layer: layer,
      insertIndex: _layers.length,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: layer.id,
    );
    _transformationController.value = Matrix4.identity();
    setState(() {
      _layers.add(layer);
      _selectedLayerId = layer.id;
      _showTextControls = false;
    });
    _openTextEditSheet();
  }

  void _handleAddSticker(String sticker) {
    final resolvedSticker = _resolveStickerAssetPath(sticker) ?? sticker;
    final isAssetSticker = _isImageLikeSticker(resolvedSticker);
    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.sticker,
      sticker: resolvedSticker,
      fontSize: isAssetSticker ? 120 : 64,
      transform: Matrix4.identity(),
    );

    _pushLayerInsertHistoryEntry(
      layer: layer,
      insertIndex: _layers.length,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: layer.id,
    );
    _transformationController.value = Matrix4.identity();
    setState(() {
      _layers.add(layer);
      _selectedLayerId = layer.id;
    });
  }

  static bool _isImageLikeSticker(String? value) {
    return _resolveStickerAssetPath(value) != null ||
        _resolveStickerFilePath(value) != null;
  }

  static String? _resolveStickerAssetPath(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return null;
    }
    final lower = normalized.toLowerCase();
    final isImage =
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
    if (!isImage) {
      return null;
    }
    if (normalized.startsWith('assets/')) {
      return normalized;
    }
    if (normalized.startsWith('elements/')) {
      return 'assets/$normalized';
    }
    return null;
  }

  static String? _resolveStickerFilePath(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return null;
    }
    final lower = normalized.toLowerCase();
    final isImage =
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
    if (!isImage) {
      return null;
    }
    final isAbsoluteWindows = RegExp(r'^[a-zA-Z]:/').hasMatch(normalized);
    final isAbsoluteUnix = normalized.startsWith('/');
    if (!isAbsoluteWindows && !isAbsoluteUnix) {
      return null;
    }
    return normalized;
  }

  static Widget _buildStickerVisual(
    String? sticker, {
    required double fontSize,
    required BoxFit fit,
    required FilterQuality filterQuality,
  }) {
    final assetPath = _resolveStickerAssetPath(sticker);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: fit,
        filterQuality: filterQuality,
        errorBuilder: (_, error, stackTrace) =>
            Text(sticker ?? '*', style: TextStyle(fontSize: fontSize)),
      );
    }
    final filePath = _resolveStickerFilePath(sticker);
    if (filePath != null) {
      return Image.file(
        File(filePath),
        fit: fit,
        filterQuality: filterQuality,
        errorBuilder: (_, error, stackTrace) =>
            Text(sticker ?? '*', style: TextStyle(fontSize: fontSize)),
      );
    }
    return Text(sticker ?? '*', style: TextStyle(fontSize: fontSize));
  }

  void _handleTextToolTap() {
    if (_hasSelectedTextLayer) {
      _openTextEditSheet();
      return;
    }
    unawaited(_handleAddText());
  }

  void _updateSelectedText(String value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    final beforeLayer = _layers[index];
    if (beforeLayer.text == value) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(text: value);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextColor(Color color) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final layer = _layers[index];
    if (layer.textGradientIndex == -1 &&
        layer.textColor.toARGB32() == color.toARGB32()) {
      return;
    }

    final afterLayer = layer.copyWith(textColor: color, textGradientIndex: -1);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextAlignment(TextAlign align) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    if (_layers[index].textAlign == align) {
      return;
    }

    final afterLayer = _layers[index].copyWith(textAlign: align);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextGradient(int gradientIndex) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    if (_layers[index].textGradientIndex == gradientIndex) {
      return;
    }

    final afterLayer = _layers[index].copyWith(
      textGradientIndex: gradientIndex,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextFontSize(double fontSize) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        fontSize: fontSize.clamp(18, 96).toDouble(),
      );
    });
  }

  void _handleTextFontSizeEditStart(double _) {
    final selectedLayer = _selectedLayer;
    _fontSizeEditBeforeLayer = selectedLayer == null
        ? null
        : _cloneLayer(selectedLayer);
  }

  void _handleTextFontSizeEditEnd(double _) {
    final beforeLayer = _fontSizeEditBeforeLayer;
    final selectedLayer = _selectedLayer;
    if (beforeLayer != null &&
        selectedLayer != null &&
        beforeLayer.id == selectedLayer.id &&
        (beforeLayer.fontSize - selectedLayer.fontSize).abs() > 0.0001) {
      _pushLayerHistoryEntry(
        beforeLayer: beforeLayer,
        afterLayer: _cloneLayer(selectedLayer),
      );
    }
    _fontSizeEditBeforeLayer = null;
  }

  /*
  Future<ui.Image?> _loadWatermarkLogo() async {
    final existing = _watermarkLogoImage;
    if (existing != null) {
      return existing;
    }

    try {
      final assetData = await rootBundle.load(
        'assets/branding/mana_poster_logo.png',
      );
      final codec = await ui.instantiateImageCodec(
        assetData.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      _watermarkLogoImage = frame.image;
      return _watermarkLogoImage;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image> _buildWatermarkedImage(
    ui.Image sourceImage, {
    required bool includeWatermark,
  }) async {
    if (!includeWatermark) {
      return sourceImage;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    canvas.drawImage(sourceImage, Offset.zero, paint);
    final logoImage = await _loadWatermarkLogo();

    final watermarkText = TextPainter(
      text: const TextSpan(
        text: 'Mana Poster',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padding = 14.0;
    const logoSize = 26.0;
    const logoGap = 8.0;
    final textStartOffset = logoImage == null ? 0.0 : logoSize + logoGap;
    final contentHeight = math.max(
      watermarkText.height,
      logoImage == null ? 0.0 : logoSize,
    );
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        sourceImage.width -
            watermarkText.width -
            (padding * 2) -
            textStartOffset,
        sourceImage.height - contentHeight - (padding * 2),
        watermarkText.width + (padding * 2) + textStartOffset,
        contentHeight + (padding * 2),
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.48),
    );
    if (logoImage != null) {
      final logoTop = rect.top + ((rect.height - logoSize) / 2);
      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(
          0,
          0,
          logoImage.width.toDouble(),
          logoImage.height.toDouble(),
        ),
        Rect.fromLTWH(rect.left + padding, logoTop, logoSize, logoSize),
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
    }
    watermarkText.paint(
      canvas,
      Offset(
        rect.left + padding + textStartOffset,
        rect.top + ((rect.height - watermarkText.height) / 2) - 1,
      ),
    );

    final picture = recorder.endRecording();
    final output = await picture.toImage(sourceImage.width, sourceImage.height);
    sourceImage.dispose();
    return output;
  }

  */
  Future<Uint8List> _encodeExportImageBytes(
    ui.Image image, {
    required _ExportImageFormat format,
  }) async {
    try {
      switch (format) {
        case _ExportImageFormat.png:
        case _ExportImageFormat.pngTransparent:
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null) {
            throw Exception('PNG conversion failed');
          }
          return byteData.buffer.asUint8List();
        case _ExportImageFormat.jpg:
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (byteData == null) {
            throw Exception('JPG conversion failed');
          }
          final encoded = img.Image.fromBytes(
            width: image.width,
            height: image.height,
            bytes: byteData.buffer,
            order: img.ChannelOrder.rgba,
          );
          return Uint8List.fromList(img.encodeJpg(encoded, quality: 95));
      }
    } finally {
      image.dispose();
    }
  }

  Future<void> _handleExportTap() async {
    if (_isCropMode) {
      return;
    }
    if (_isExporting) {
      return;
    }
    final canProceed = await _confirmExportIfCanvasEmpty();
    if (!canProceed) {
      return;
    }

    final format = await _pickExportFormat();
    if (format == null) {
      return;
    }

    await _performExport(format: format);
  }

  Future<_ExportImageFormat?> _pickExportFormat() async {
    return showModalBottomSheet<_ExportImageFormat>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        final strings = context.strings;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.image_rounded),
                  title: Text(strings.localized(telugu: 'PNG', english: 'PNG')),
                  subtitle: Text(
                    strings.localized(
                      telugu: 'పారదర్శక బ్యాక్‌గ్రౌండ్, Remove BG కోసం ఉత్తమం',
                      english: 'Transparent background, best for Remove BG',
                    ),
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_ExportImageFormat.pngTransparent),
                ),
                ListTile(
                  leading: const Icon(Icons.crop_square_rounded),
                  title: Text(
                    strings.localized(
                      telugu: 'బ్యాక్‌గ్రౌండ్‌తో PNG',
                      english: 'PNG with Background',
                    ),
                  ),
                  subtitle: Text(
                    strings.localized(
                      telugu: 'పోస్టర్ లేదా స్టేజ్ బ్యాక్‌గ్రౌండ్ కూడా ఉంటుంది',
                      english: 'Includes poster/stage background',
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(_ExportImageFormat.png),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_rounded),
                  title: Text(strings.localized(telugu: 'JPG', english: 'JPG')),
                  subtitle: Text(
                    strings.localized(
                      telugu: 'చిన్న ఫైల్ సైజ్',
                      english: 'Smaller file size',
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(_ExportImageFormat.jpg),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmExportIfCanvasEmpty() async {
    if (_layers.isNotEmpty) {
      return true;
    }

    final strings = context.strings;
    final freshDecision = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            strings.localized(
              telugu: 'క్యాన్వాస్ ఖాళీగా ఉంది',
              english: 'Canvas is empty',
            ),
          ),
          content: Text(
            strings.localized(
              telugu:
                  'డిజైన్ లేయర్లు లేవు. అయినా కూడా బ్యాక్‌గ్రౌండ్ మాత్రమే ఎగుమతి చేయాలా?',
              english:
                  'There are no design layers. Do you still want to export only the background?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                strings.localized(telugu: 'వద్దు', english: 'Cancel'),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                strings.localized(
                  telugu: 'అవును, ఎగుమతి చేయి',
                  english: 'Yes, export',
                ),
              ),
            ),
          ],
        );
      },
    );
    return freshDecision ?? false;

    // ignore: dead_code
    final decision = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Canvas ఖాళీగా ఉంది'),
          content: const Text(
            'Design layers ఏవి లేవు. అయినా కూడా background మాత్రమే export చేయాలా?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('వద్దు'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('అవును, export చేయి'),
            ),
          ],
        );
      },
    );
    return decision ?? false;
  }

  /*
  Future<bool> _handlePaywallAction({
    required Uint8List? previewBytes,
    required bool forExport,
  }) async {
    if (!mounted) {
      return false;
    }
    final decision = await Navigator.of(context).push<ExportPaywallDecision>(
      MaterialPageRoute<ExportPaywallDecision>(
        fullscreenDialog: true,
        builder: (BuildContext context) => ExportPaywallScreen(
          previewBytes: previewBytes,
          isProUser: _isProUser,
          forExport: forExport,
        ),
      ),
    );
    if (!mounted ||
        decision == null ||
        decision == ExportPaywallDecision.cancel) {
      return false;
    }

    if (decision == ExportPaywallDecision.freeWithWatermark) {
      return forExport;
    }
    if (decision == ExportPaywallDecision.upgradeAndExport) {
      final outcome = await _purchaseGateway.purchaseMonthlyPro();
      final result = outcome.result;
      if (!mounted) {
        return false;
      }
      if (result == PurchaseFlowResult.success) {
        final isActivated = await _verifyEntitlementAfterPurchase(
          outcome.evidence,
        );
        if (!mounted) {
          return false;
        }
        if (!isActivated) {
          return false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pro విజయవంతంగా activate అయ్యింది')),
        );
        return forExport;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            PurchaseFlowResult.cancelled => 'Payment cancel చేశారు',
            PurchaseFlowResult.failed => 'Payment fail అయ్యింది',
            PurchaseFlowResult.billingUnavailable =>
              'Billing service అందుబాటులో లేదు. కొద్దిసేపటి తర్వాత మళ్లీ ప్రయత్నించండి',
            PurchaseFlowResult.productNotFound =>
              'Subscription ప్లాన్ storeలో కనిపించలేదు. support‌ని సంప్రదించండి',
            PurchaseFlowResult.timedOut =>
              'Payment response ఆలస్యం అయ్యింది. purchase history చెక్ చేసి మళ్లీ ప్రయత్నించండి',
            PurchaseFlowResult.nothingToRestore =>
              'Restore చేయడానికి purchase కనిపించలేదు',
            PurchaseFlowResult.success => '',
          }),
        ),
      );
      return false;
    }
    if (decision == ExportPaywallDecision.restorePurchase) {
      final restoreOutcome = await _purchaseGateway.restorePurchases();
      final restoreResult = restoreOutcome.result;
      if (!mounted) {
        return false;
      }
      if (restoreResult == PurchaseFlowResult.success) {
        final isActivated = await _verifyEntitlementAfterPurchase(
          restoreOutcome.evidence,
        );
        if (!mounted) {
          return false;
        }
        if (!isActivated) {
          return false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase restore అయ్యింది')),
        );
        return forExport;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (restoreResult) {
            PurchaseFlowResult.billingUnavailable =>
              'Billing service అందుబాటులో లేదు. తర్వాత మళ్లీ ప్రయత్నించండి',
            PurchaseFlowResult.failed =>
              'Restore fail అయ్యింది, మళ్లీ ప్రయత్నించండి',
            PurchaseFlowResult.cancelled => 'Restore process cancel అయింది',
            PurchaseFlowResult.productNotFound =>
              'Restore చేయడానికి product details కనిపించలేదు',
            PurchaseFlowResult.timedOut =>
              'Restore response ఆలస్యం అయింది. కొద్దిసేపటి తర్వాత ప్రయత్నించండి',
            PurchaseFlowResult.nothingToRestore =>
              'Restore చేయడానికి active plan కనిపించలేదు',
            PurchaseFlowResult.success => 'Purchase restore అయ్యింది',
          }),
        ),
      );
      return false;
    }
    return false;
  }

  */
  Rect _currentStageLogicalRect() {
    final canvasSize = _lastCanvasSize;
    const topInset = _canvasChromeInset;
    const bottomInset = _canvasChromeInset;
    final workspaceHeight = math.max(
      0.0,
      canvasSize.height - topInset - bottomInset,
    );
    final workspaceSize = Size(canvasSize.width, workspaceHeight);
    final hasPageSelection = _pageAspectRatio != null;
    final stageSize = hasPageSelection
        ? _fitPageSize(
            workspaceSize: workspaceSize,
            aspectRatio: _pageAspectRatio!,
          )
        : workspaceSize;
    return Rect.fromCenter(
      center: Offset(canvasSize.width / 2, topInset + (workspaceHeight / 2)),
      width: stageSize.width,
      height: stageSize.height,
    );
  }

  Future<ui.Image> _cropImageToVisibleStage(
    ui.Image source, {
    required double pixelRatio,
  }) async {
    final stageRect = _currentStageLogicalRect();
    final srcRect = Rect.fromLTWH(
      stageRect.left * pixelRatio,
      stageRect.top * pixelRatio,
      stageRect.width * pixelRatio,
      stageRect.height * pixelRatio,
    );
    final outputWidth = srcRect.width.round().clamp(1, source.width);
    final outputHeight = srcRect.height.round().clamp(1, source.height);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      srcRect,
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      Paint(),
    );
    final cropped = await recorder.endRecording().toImage(
      outputWidth,
      outputHeight,
    );
    source.dispose();
    return cropped;
  }

  Future<ui.Image?> _captureStageImage({required double pixelRatio}) async {
    setState(() {
      _isCapturingStage = true;
    });
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        await _waitForRenderedFrame();
        if (!mounted) {
          return null;
        }
        final boundary =
            _stageRepaintKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null) {
          continue;
        }
        try {
          final captured = await boundary.toImage(pixelRatio: pixelRatio);
          return _cropImageToVisibleStage(captured, pixelRatio: pixelRatio);
        } catch (_) {
          if (attempt == 1) {
            rethrow;
          }
        }
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingStage = false;
        });
      }
    }
  }

  Future<void> _waitForRenderedFrame() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (mounted) {
      await binding.endOfFrame;
    }
  }

  Future<void> _performExport({required _ExportImageFormat format}) async {
    if (_isExporting || _isCommitWorkerBusy) {
      return;
    }
    final exportPermissionMessage = context.strings.localized(
      telugu: 'గ్యాలరీ అనుమతి ఇవ్వండి, తర్వాత మళ్లీ ఎగుమతి చేయండి',
      english: 'Allow gallery permission and try exporting again',
    );
    final exportBoundaryMessage = context.strings.localized(
      telugu: 'ఎగుమతి ప్రాంతం సిద్ధంగా లేదు',
      english: 'Export boundary not ready',
    );
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    try {
      final exportedBytes = await _runQueuedCommitJob<Uint8List>(
        jobKey: 'export_${DateTime.now().microsecondsSinceEpoch}',
        label: context.strings.localized(
          telugu: 'పోస్టర్ ఎగుమతి అవుతోంది',
          english: 'Exporting poster',
        ),
        detail: context.strings.localized(
          telugu: 'ఫైనల్ అవుట్‌పుట్‌ను రెండర్ చేసి సేవ్ చేస్తోంది',
          english: 'Rendering and saving the final output',
        ),
        onStart: () {
          _isExporting = true;
        },
        onFinish: () {
          _isExporting = false;
          _isTransparentExportCapture = false;
        },
        operation: () async {
          if (format == _ExportImageFormat.pngTransparent) {
            if (mounted) {
              setState(() {
                _isTransparentExportCapture = true;
              });
            } else {
              _isTransparentExportCapture = true;
            }
            await _waitForRenderedFrame();
          }
          final hasPermission = await _ensureGallerySavePermission();
          if (!hasPermission) {
            throw Exception(exportPermissionMessage);
          }
          final image = await _captureStageImage(
            pixelRatio: _exportPixelRatio(devicePixelRatio),
          );
          if (image == null) {
            throw Exception(exportBoundaryMessage);
          }
          final shouldHaveTransparentBackground =
              format == _ExportImageFormat.pngTransparent;
          final exportedBytes = await _encodeExportImageBytes(
            image,
            format: shouldHaveTransparentBackground
                ? _ExportImageFormat.png
                : format,
          );
          final fileName =
              'mana_poster_${DateTime.now().millisecondsSinceEpoch}.${_exportFileExtension(format)}';
          final result = await ImageGallerySaverPlus.saveImage(
            exportedBytes,
            quality: 100,
            name: fileName,
          );
          var isSuccess = _isGallerySaveSuccess(result);
          dynamic finalResult = result;
          if (!isSuccess) {
            final tempDirectory = await getTemporaryDirectory();
            final tempPath =
                '${tempDirectory.path}${Platform.pathSeparator}$fileName';
            final tempFile = File(tempPath);
            await tempFile.writeAsBytes(exportedBytes, flush: true);
            final fallbackResult = await ImageGallerySaverPlus.saveFile(
              tempFile.path,
              name: fileName,
            );
            if (_isGallerySaveSuccess(fallbackResult)) {
              isSuccess = true;
              finalResult = fallbackResult;
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _exportResultMessage(finalResult, isSuccess: isSuccess),
                ),
                action: isSuccess
                    ? SnackBarAction(
                        label: context.strings.localized(
                          telugu: _isSharing ? 'షేర్ అవుతోంది...' : 'షేర్',
                          english: _isSharing ? 'Sharing...' : 'Share',
                        ),
                        onPressed: _isSharing
                            ? () {}
                            : () => _shareLatestPoster(
                                exportedBytes,
                                format: format,
                              ),
                      )
                    : null,
              ),
            );
          }
          return exportedBytes;
        },
      );
      if (exportedBytes == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.localized(
                telugu: 'ఎగుమతి ఇప్పటికే జరుగుతోంది',
                english: 'Export is already in progress',
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }
    final requested = await <Permission>[Permission.photos].request();
    return requested.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  bool _isGallerySaveSuccess(dynamic saveResult) {
    if (saveResult is bool) {
      return saveResult;
    }
    if (saveResult is! Map) {
      return false;
    }
    final status = saveResult['isSuccess'] ?? saveResult['success'];
    if (status is bool) {
      return status;
    }
    if (status is num) {
      return status > 0;
    }
    final normalized = status?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  String _exportResultMessage(dynamic saveResult, {required bool isSuccess}) {
    if (isSuccess) {
      return 'Poster gallery లో save అయ్యింది';
    }
    final errorText = saveResult is Map
        ? (saveResult['errorMessage']?.toString() ??
              saveResult['message']?.toString() ??
              saveResult['error']?.toString() ??
              '')
        : '';
    if (errorText.toLowerCase().contains('permission')) {
      return 'Gallery permission ఇవ్వండి, తర్వాత మళ్లీ export చేయండి';
    }
    return 'Export fail అయ్యింది, మళ్లీ ప్రయత్నించండి';
  }

  double _exportPixelRatio(double devicePixelRatio) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    // Keep quality high on regular devices, and only slightly cap on very large surfaces.
    if (shortestSide >= 720) {
      return devicePixelRatio.clamp(1.0, 2.7);
    }
    return devicePixelRatio.clamp(1.0, 3.0);
  }

  Future<void> _shareLatestPoster(
    Uint8List imageBytes, {
    required _ExportImageFormat format,
  }) async {
    if (_isSharing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });
    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}${Platform.pathSeparator}mana_poster_share.${_exportFileExtension(format)}';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);
      await Share.shareXFiles(<XFile>[
        XFile(file.path),
      ], text: 'Mana Poster తో create చేసిన నా poster');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'షేర్ కాలేదు, మళ్లీ ప్రయత్నించండి',
              english: 'Share failed, please try again',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  String _exportFileExtension(_ExportImageFormat format) {
    switch (format) {
      case _ExportImageFormat.jpg:
        return 'jpg';
      case _ExportImageFormat.png:
      case _ExportImageFormat.pngTransparent:
        return 'png';
    }
  }

  void _setSelectedTextFontFamily(String fontFamily) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    if (_layers[index].fontFamily == fontFamily) {
      return;
    }

    final afterLayer = _layers[index].copyWith(fontFamily: fontFamily);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextBackgroundColor(Color color) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    final beforeLayer = _layers[index];
    if (beforeLayer.textBackgroundColor.toARGB32() == color.toARGB32()) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(textBackgroundColor: color);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextBackgroundOpacity(double opacity) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    setState(() {
      _layers[index] = _layers[index].copyWith(
        textBackgroundOpacity: opacity.clamp(0, 1).toDouble(),
      );
    });
  }

  void _setSelectedTextBackgroundRadius(double radius) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    setState(() {
      _layers[index] = _layers[index].copyWith(
        textBackgroundRadius: radius.clamp(0, 40).toDouble(),
      );
    });
  }

  void _setSelectedTextLineHeight(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textLineHeight: value.clamp(0.8, 2.2).toDouble(),
      );
    });
  }

  void _setSelectedTextLetterSpacing(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textLetterSpacing: value.clamp(-1, 12).toDouble(),
      );
    });
  }

  void _setSelectedTextShadowOpacity(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textShadowOpacity: value.clamp(0, 1).toDouble(),
      );
    });
  }

  void _setSelectedTextShadowBlur(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textShadowBlur: value.clamp(0, 24).toDouble(),
      );
    });
  }

  void _setSelectedTextShadowOffsetY(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textShadowOffsetY: value.clamp(0, 20).toDouble(),
      );
    });
  }

  void _toggleSelectedTextBold() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      isTextBold: !beforeLayer.isTextBold,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _toggleSelectedTextItalic() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      isTextItalic: !beforeLayer.isTextItalic,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _toggleSelectedTextUnderline() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      isTextUnderline: !beforeLayer.isTextUnderline,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextStrokeColor(Color color) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final beforeLayer = _layers[index];
    if (beforeLayer.textStrokeColor.toARGB32() == color.toARGB32()) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(textStrokeColor: color);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextStrokeWidth(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textStrokeWidth: value.clamp(0, 8).toDouble(),
      );
    });
  }

  void _setSelectedPhotoOpacity(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      photoOpacity: value.clamp(0.1, 1).toDouble(),
    );
    if ((beforeLayer.photoOpacity - afterLayer.photoOpacity).abs() <= 0.0001) {
      return;
    }
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _toggleSelectedPhotoFlipHorizontal() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      flipPhotoHorizontally: !beforeLayer.flipPhotoHorizontally,
    );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _toggleSelectedPhotoFlipVertical() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      flipPhotoVertically: !beforeLayer.flipPhotoVertically,
    );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _rotateSelectedPhoto(double radians) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) return;
    final beforeLayer = _layers[index];
    final updated = Matrix4.copy(beforeLayer.transform)..rotateZ(radians);
    final afterLayer = beforeLayer.copyWith(transform: updated);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    _transformationController.value = Matrix4.copy(updated);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _openAdjustPanel() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _isAdjustMode = true;
      _adjustSessionLayerId = layer.id;
      _adjustSessionBrightness = layer.photoBrightness;
      _adjustSessionContrast = layer.photoContrast;
      _adjustSessionSaturation = layer.photoSaturation;
      _adjustSessionBlur = layer.photoBlur;
      _adjustInitialBrightness = layer.photoBrightness;
      _adjustInitialContrast = layer.photoContrast;
      _adjustInitialSaturation = layer.photoSaturation;
      _adjustInitialBlur = layer.photoBlur;
      _showTextControls = false;
    });
    _adjustSessionNotifier.value = _AdjustSessionState(
      brightness: layer.photoBrightness,
      contrast: layer.photoContrast,
      saturation: layer.photoSaturation,
      blur: layer.photoBlur,
    );
  }

  void _discardAdjustSession() {
    if (!_isAdjustMode) {
      return;
    }
    setState(() {
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _adjustSessionBrightness = 0;
      _adjustSessionContrast = 1;
      _adjustSessionSaturation = 1;
      _adjustSessionBlur = 0;
      _adjustInitialBrightness = 0;
      _adjustInitialContrast = 1;
      _adjustInitialSaturation = 1;
      _adjustInitialBlur = 0;
    });
    _adjustSessionNotifier.value = null;
  }

  void _resetAdjustSession() {
    if (!_isAdjustMode) {
      return;
    }
    setState(() {
      _adjustSessionBrightness = _adjustInitialBrightness;
      _adjustSessionContrast = _adjustInitialContrast;
      _adjustSessionSaturation = _adjustInitialSaturation;
      _adjustSessionBlur = _adjustInitialBlur;
    });
    _adjustSessionNotifier.value = _AdjustSessionState(
      brightness: _adjustInitialBrightness,
      contrast: _adjustInitialContrast,
      saturation: _adjustInitialSaturation,
      blur: _adjustInitialBlur,
    );
  }

  void _updateAdjustSessionState(_AdjustSessionState nextState) {
    if (!_isAdjustMode || _adjustSessionLayerId == null) {
      return;
    }
    _adjustSessionBrightness = nextState.brightness;
    _adjustSessionContrast = nextState.contrast;
    _adjustSessionSaturation = nextState.saturation;
    _adjustSessionBlur = nextState.blur;
    if (_adjustSessionNotifier.value != nextState) {
      _adjustSessionNotifier.value = nextState;
    }
    _refreshSelectedPhotoRenderState();
  }

  void _applyAdjustSession() {
    final selectedId = _selectedLayerId;
    if (!_isAdjustMode ||
        selectedId == null ||
        _adjustSessionLayerId != selectedId) {
      _discardAdjustSession();
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) {
      _discardAdjustSession();
      return;
    }
    final beforeLayer = _layers[index];
    final hasChanges =
        (beforeLayer.photoBrightness - _adjustSessionBrightness).abs() >
            0.0001 ||
        (beforeLayer.photoContrast - _adjustSessionContrast).abs() > 0.0001 ||
        (beforeLayer.photoSaturation - _adjustSessionSaturation).abs() >
            0.0001 ||
        (beforeLayer.photoBlur - _adjustSessionBlur).abs() > 0.0001;
    final afterLayer = beforeLayer.copyWith(
      photoBrightness: _adjustSessionBrightness,
      photoContrast: _adjustSessionContrast,
      photoSaturation: _adjustSessionSaturation,
      photoBlur: _adjustSessionBlur,
    );
    if (hasChanges) {
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    }
    setState(() {
      _layers[index] = afterLayer;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
    });
    _adjustSessionNotifier.value = null;
  }

  Future<void> _openEraserPanel() async {
    final layer = _selectedLayer;
    if (layer == null || !layer.isPhoto || layer.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }
    final restoreBytes = layer.originalPhotoBytes ?? layer.bytes;
    if (restoreBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'ఎంచుకున్న చిత్రం లోడ్ కాలేదు',
              english: 'Selected image could not be loaded',
            ),
          ),
        ),
      );
      return;
    }

    _disposeEraserSessionResources();
    await _eraserController.loadPreferences();
    setState(() {
      _isEraserMode = true;
      _isEraserInitializing = true;
      _isEraserApplying = false;
      _eraserSessionLayerId = layer.id;
      _eraserInitError = null;
      _eraserMode = _eraserController.mode == EraserBlendMode.restore
          ? _EraserMode.restore
          : _EraserMode.erase;
      _activeEraserControl = null;
      _eraserBrushSize = _eraserController.settings.size;
      _eraserBrushHardness = _eraserController.settings.hardness;
      _eraserBrushStrength = _eraserController.settings.strength;
      _showTextControls = false;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
    });
    await _initializeEraserSessionForLayer(layer);
  }

  Future<void> _initializeEraserSessionForLayer(_CanvasLayer layer) async {
    final currentBytes = layer.bytes;
    final restoreBytes = layer.originalPhotoBytes ?? layer.bytes;
    final decoded = currentBytes == null ? null : img.decodeImage(currentBytes);
    if (currentBytes == null || restoreBytes == null || decoded == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isEraserInitializing = false;
        _eraserInitError = context.strings.localized(
          telugu: 'ఎంచుకున్న చిత్రం లోడ్ కాలేదు',
          english: 'Selected image could not be loaded',
        );
      });
      return;
    }
    _eraserController.startSession(currentBytes);
    _eraserSessionStartBytes = Uint8List.fromList(currentBytes);
    _eraserSessionRestoreBytes = Uint8List.fromList(restoreBytes);
    _eraserSessionImagePixelSize = Size(
      decoded.width.toDouble(),
      decoded.height.toDouble(),
    );
    final previewCurrentBytes = _createEraserPreviewBytes(currentBytes);
    final previewRestoreBytes = _createEraserPreviewBytes(restoreBytes);
    final previewDecoded = img.decodeImage(previewCurrentBytes);
    _eraserPreviewSessionStartBytes = Uint8List.fromList(previewCurrentBytes);
    _eraserPreviewBaseBytes = Uint8List.fromList(previewCurrentBytes);
    _eraserPreviewRestoreBytes = Uint8List.fromList(previewRestoreBytes);
    _eraserPreviewImagePixelSize = previewDecoded == null
        ? _eraserSessionImagePixelSize
        : Size(
            previewDecoded.width.toDouble(),
            previewDecoded.height.toDouble(),
          );
    await _updateEraserPreviewImage(previewCurrentBytes);
    await _updateEraserRestorePreviewImage(previewRestoreBytes);
    if (!mounted) {
      return;
    }
    setState(() {
      _isEraserInitializing = false;
    });
  }

  void _discardEraserSession() {
    if (!_isEraserMode &&
        !_isEraserInitializing &&
        !_isEraserApplying &&
        _eraserSessionLayerId == null) {
      return;
    }
    _disposeEraserSessionResources();
    setState(() {
      _isEraserMode = false;
      _isEraserInitializing = false;
      _isEraserApplying = false;
      _eraserSessionLayerId = null;
      _activeEraserControl = null;
      _eraserInitError = null;
    });
  }

  void _disposeEraserSessionResources() {
    _eraserPreviewRevision += 1;
    _isEraserPreviewRendering = false;
    _eraserPreviewRenderQueued = false;
    _eraserController.resetSession();
    _eraserSessionStartBytes = null;
    _eraserSessionRestoreBytes = null;
    _eraserSessionImagePixelSize = Size.zero;
    _eraserPreviewSessionStartBytes = null;
    _eraserPreviewBaseBytes = null;
    _eraserPreviewRestoreBytes = null;
    _eraserPreviewImagePixelSize = Size.zero;
    _eraserBrushCursorNotifier.value = null;
    _eraserActiveStrokeNotifier.value = null;
    final oldPreview = _eraserPreviewImageNotifier.value;
    _eraserPreviewImageNotifier.value = null;
    oldPreview?.dispose();
    final oldRestorePreview = _eraserRestorePreviewImageNotifier.value;
    _eraserRestorePreviewImageNotifier.value = null;
    oldRestorePreview?.dispose();
    _isEraserBakeInProgress = false;
    _eraserBakeQueued = false;
    _eraserPreviewThrottleTimer?.cancel();
    _eraserPreviewThrottleTimer = null;
  }

  void _resetEraserSession() {
    if (!_isEraserMode || _isEraserApplying) {
      return;
    }
    _eraserController.resetSession();
    final sessionStartBytes = _eraserSessionStartBytes;
    if (sessionStartBytes != null) {
      _eraserController.updateBaseBytes(sessionStartBytes);
    }
    _eraserPreviewThrottleTimer?.cancel();
    _eraserPreviewThrottleTimer = null;
    _eraserPreviewRevision += 1;
    final previewBaseBytes = _eraserPreviewSessionStartBytes;
    if (previewBaseBytes == null || previewBaseBytes.isEmpty) {
      final oldPreview = _eraserPreviewImageNotifier.value;
      _eraserPreviewImageNotifier.value = null;
      oldPreview?.dispose();
    } else {
      _eraserPreviewBaseBytes = Uint8List.fromList(previewBaseBytes);
      unawaited(_updateEraserPreviewImage(previewBaseBytes));
    }
    setState(() {});
  }

  Uint8List _createEraserPreviewBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }
    const previewMaxDimension = 640;
    final longest = math.max(decoded.width, decoded.height);
    if (longest <= previewMaxDimension) {
      return bytes;
    }
    final scale = previewMaxDimension / longest;
    final width = math.max(256, (decoded.width * scale).round());
    final height = math.max(256, (decoded.height * scale).round());
    final resized = img.copyResize(
      decoded,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodePng(resized));
  }

  Future<void> _applyEraserSession() async {
    if (!_isEraserMode || _isEraserApplying || _isCommitWorkerBusy) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null || _eraserSessionLayerId != selectedId) {
      _discardEraserSession();
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) {
      _discardEraserSession();
      return;
    }
    await _waitForEraserBakeIdle();
    await _bakeEraserChunksIfNeeded(keepLastChunks: 0);
    await _waitForEraserBakeIdle();
    final restoreBytes = _eraserSessionRestoreBytes;
    final sessionStartBytes = _eraserSessionStartBytes;
    final baseBytes = _eraserController.baseBytes;
    final pendingChunks = _eraserController.pendingChunks;
    if (restoreBytes == null || baseBytes.isEmpty) {
      _discardEraserSession();
      return;
    }
    try {
      final hasBaseChanges =
          sessionStartBytes == null || !listEquals(sessionStartBytes, baseBytes);
      if (pendingChunks.isEmpty && !hasBaseChanges) {
        _discardEraserSession();
        return;
      }
      final pngBytes = pendingChunks.isEmpty
          ? baseBytes
          : await _runQueuedCommitJob<Uint8List>(
        jobKey: 'eraser_$selectedId',
        label: context.strings.localized(
          telugu: 'ఈరేసర్ అప్లై అవుతోంది',
          english: 'Applying eraser',
        ),
        detail: context.strings.localized(
          telugu: 'ఎంచుకున్న లేయర్ కోసం పారదర్శక PNG మళ్లీ తయారవుతోంది',
          english: 'Rebuilding transparent PNG for the selected layer',
        ),
        onStart: () {
          _isEraserApplying = true;
        },
        onFinish: () {
          _isEraserApplying = false;
        },
        operation: () async {
          return compute(applyEraserChunksToPng, <String, dynamic>{
            'currentBytes': baseBytes,
            'restoreBytes': restoreBytes,
            'chunks': pendingChunks
                .map((item) => item.toMap())
                .toList(growable: false),
          });
        },
      );
      if (pngBytes == null || !mounted) {
        return;
      }
      if (listEquals(baseBytes, pngBytes) && !hasBaseChanges) {
        _discardEraserSession();
        return;
      }

      final beforeLayer = _layers[index];
      final afterLayer = beforeLayer.copyWith(bytes: pngBytes);
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
      setState(() {
        _layers[index] = afterLayer;
        _isEraserMode = false;
        _isEraserInitializing = false;
        _eraserSessionLayerId = null;
        _activeEraserControl = null;
        _eraserInitError = null;
      });
      _disposeEraserSessionResources();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isEraserApplying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'ఈరేసర్ అప్లై కాలేదు: $error',
              english: 'Eraser apply failed: $error',
            ),
          ),
        ),
      );
    }
  }

  Offset? _mapCanvasPointToSelectedImage({
    required Offset localPosition,
    required Rect pageRect,
    required Size pageSize,
    required Size imagePixelSize,
  }) {
    final selected = _selectedLayer;
    if (selected == null ||
        !selected.isPhoto ||
        imagePixelSize.width <= 1 ||
        imagePixelSize.height <= 1) {
      return null;
    }
    final photoSize = _fitPhotoLayerSize(
      pageSize: pageSize,
      photoAspectRatio: selected.photoAspectRatio,
    );
    if (photoSize.width <= 0 || photoSize.height <= 0) {
      return null;
    }
    final localToPageCenter = localPosition - pageRect.center;
    final inverse = Matrix4.inverted(_transformationController.value);
    var point = MatrixUtils.transformPoint(inverse, localToPageCenter);

    if (selected.flipPhotoHorizontally) {
      point = Offset(-point.dx, point.dy);
    }
    if (selected.flipPhotoVertically) {
      point = Offset(point.dx, -point.dy);
    }

    final halfW = photoSize.width / 2;
    final halfH = photoSize.height / 2;
    if (point.dx < -halfW ||
        point.dx > halfW ||
        point.dy < -halfH ||
        point.dy > halfH) {
      return null;
    }

    final normalizedX = ((point.dx + halfW) / photoSize.width).clamp(0.0, 1.0);
    final normalizedY = ((point.dy + halfH) / photoSize.height).clamp(0.0, 1.0);
    return Offset(
      normalizedX * (imagePixelSize.width - 1),
      normalizedY * (imagePixelSize.height - 1),
    );
  }

  double _currentEraserZoomScale() {
    final matrix = _transformationController.value;
    final scale = math.sqrt(
      (matrix.storage[0] * matrix.storage[0]) +
          (matrix.storage[1] * matrix.storage[1]),
    );
    return scale.clamp(0.2, 8.0);
  }

  EraserStrokePoint? _buildEraserStrokePoint({
    required Offset localPosition,
    required Rect pageRect,
    required Size pageSize,
  }) {
    final imagePixelSize = _eraserSessionImagePixelSize;
    final mappedPoint = _mapCanvasPointToSelectedImage(
      localPosition: localPosition,
      pageRect: pageRect,
      pageSize: pageSize,
      imagePixelSize: imagePixelSize,
    );
    if (mappedPoint == null) {
      return null;
    }
    final selected = _selectedLayer;
    if (selected == null || !selected.isPhoto) {
      return null;
    }
    final photoSize = _fitPhotoLayerSize(
      pageSize: pageSize,
      photoAspectRatio: selected.photoAspectRatio,
    );
    final scaleX = imagePixelSize.width / math.max(photoSize.width, 1);
    final scaleY = imagePixelSize.height / math.max(photoSize.height, 1);
    final zoomScale = _currentEraserZoomScale();
    final radius = math.max(
      0.75,
      ((_eraserBrushSize * 0.5) * ((scaleX + scaleY) / 2)) / zoomScale,
    );
    return EraserStrokePoint(
      normalized: Offset(
        (mappedPoint.dx / math.max(imagePixelSize.width - 1, 1)).clamp(
          0.0,
          1.0,
        ),
        (mappedPoint.dy / math.max(imagePixelSize.height - 1, 1)).clamp(
          0.0,
          1.0,
        ),
      ),
      radiusInImagePixels: radius,
      hardness: _eraserBrushHardness,
      strength: _eraserBrushStrength,
      pressure: 1,
    );
  }

  void _handleEraserPanUpdate(
    Offset localPosition,
    Rect pageRect,
    Size pageSize,
  ) {
    final point = _buildEraserStrokePoint(
      localPosition: localPosition,
      pageRect: pageRect,
      pageSize: pageSize,
    );
    if (point == null) {
      return;
    }
    _eraserController.appendInterpolatedStroke(point);
    _eraserBrushCursorNotifier.value = localPosition;
    _eraserActiveStrokeNotifier.value = _eraserController.activeStrokeChunk;
    _scheduleEraserPreviewRender(activeOnly: true);
  }

  void _handleEraserPanStart(
    Offset localPosition,
    Rect pageRect,
    Size pageSize,
  ) {
    final point = _buildEraserStrokePoint(
      localPosition: localPosition,
      pageRect: pageRect,
      pageSize: pageSize,
    );
    if (point == null) {
      return;
    }
    _eraserController.beginStroke(point);
    _eraserBrushCursorNotifier.value = localPosition;
    _eraserActiveStrokeNotifier.value = _eraserController.activeStrokeChunk;
    _scheduleEraserPreviewRender(activeOnly: true);
  }

  void _handleEraserPanEnd() {
    _eraserPreviewThrottleTimer?.cancel();
    _eraserPreviewThrottleTimer = null;
    _eraserPreviewRevision += 1;
    final committed = _eraserController.endStroke();
    _eraserBrushCursorNotifier.value = null;
    _eraserActiveStrokeNotifier.value = null;
    if (committed) {
      unawaited(_commitLatestEraserChunkToPreview());
      unawaited(_bakeEraserChunksIfNeeded());
    } else {
      _eraserController.cancelActiveStroke();
      _eraserActiveStrokeNotifier.value = null;
    }
    setState(() {});
  }

  void _handleEraserScaleStart(ScaleStartDetails details) {
    _handleSelectedLayerInteractionStart(details);
  }

  void _handleEraserScaleUpdate(ScaleUpdateDetails details) {
    _handleSelectedLayerScaleUpdate(details);
  }

  void _handleEraserScaleEnd() {
    _handleSelectedLayerInteractionEnd();
    _eraserBrushCursorNotifier.value = null;
  }

  Future<void> _bakeEraserChunksIfNeeded({int keepLastChunks = 1}) async {
    if (_isEraserBakeInProgress || _isEraserApplying || !_isEraserMode) {
      _eraserBakeQueued = true;
      return;
    }
    final restoreBytes = _eraserSessionRestoreBytes;
    if (restoreBytes == null) {
      return;
    }
    _isEraserBakeInProgress = true;
    try {
      while (mounted && _isEraserMode) {
        final chunksToBake = _eraserController.takeChunksForBake(
          keepLastChunks: keepLastChunks,
        );
        if (chunksToBake.isEmpty) {
          break;
        }
        final bakedBytes =
            await compute(applyEraserChunksToPng, <String, dynamic>{
              'currentBytes': _eraserController.baseBytes,
              'restoreBytes': restoreBytes,
              'chunks': chunksToBake
                  .map((chunk) => chunk.toMap())
                  .toList(growable: false),
            });
        if (!mounted || !_isEraserMode) {
          break;
        }
        _eraserController.updateBaseBytes(bakedBytes);
      }
    } finally {
      _isEraserBakeInProgress = false;
      if (_eraserBakeQueued) {
        _eraserBakeQueued = false;
        if (mounted && _isEraserMode) {
          unawaited(_bakeEraserChunksIfNeeded());
        }
      }
    }
  }

  void _scheduleEraserPreviewRender({bool activeOnly = false}) {
    if (!_isEraserMode || _isEraserApplying) {
      return;
    }
    if (_isEraserPreviewRendering ||
        (_eraserPreviewThrottleTimer?.isActive ?? false)) {
      _eraserPreviewRenderQueued = true;
      return;
    }
    _eraserPreviewThrottleTimer = Timer(
      const Duration(milliseconds: 16),
      () {
        final revision = ++_eraserPreviewRevision;
        _isEraserPreviewRendering = true;
        unawaited(_renderEraserPreview(revision, activeOnly: activeOnly));
      },
    );
  }

  Future<void> _renderEraserPreview(
    int revision, {
    required bool activeOnly,
  }) async {
    final restoreBytes = _eraserPreviewRestoreBytes;
    final baseBytes = _eraserPreviewBaseBytes;
    final activeChunk = _eraserController.activeStrokeChunk;
    final chunks = activeOnly
        ? <EraserStrokeChunk>[...?activeChunk == null ? null : <EraserStrokeChunk>[activeChunk]]
        : _eraserController.chunksForPreview();
    if (!_isEraserMode ||
        _isEraserApplying ||
        restoreBytes == null ||
        baseBytes == null ||
        baseBytes.isEmpty ||
        chunks.isEmpty) {
      return;
    }
    final radiusScale =
        _eraserPreviewImagePixelSize.width > 0 &&
            _eraserSessionImagePixelSize.width > 0
        ? (_eraserPreviewImagePixelSize.width /
                  _eraserSessionImagePixelSize.width)
              .clamp(0.01, 1.0)
        : 1.0;
    final previewBytes =
        await compute(applyEraserChunksToPng, <String, dynamic>{
          'currentBytes': baseBytes,
          'restoreBytes': restoreBytes,
          'chunks': chunks.map((item) => item.toMap()).toList(growable: false),
          'radiusScale': radiusScale,
        });
    if (!mounted || !_isEraserMode || _isEraserApplying) {
      _isEraserPreviewRendering = false;
      return;
    }
    if (revision == _eraserPreviewRevision) {
      await _updateEraserPreviewImage(previewBytes);
    }
    _isEraserPreviewRendering = false;
    if (_eraserPreviewRenderQueued && mounted && _isEraserMode) {
      _eraserPreviewRenderQueued = false;
      _scheduleEraserPreviewRender(
        activeOnly: _eraserController.hasActiveStroke,
      );
    }
  }

  Future<void> _waitForEraserBakeIdle() async {
    var spins = 0;
    while (_isEraserBakeInProgress && spins < 120) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      spins += 1;
    }
  }

  Future<void> _commitLatestEraserChunkToPreview() async {
    final chunk = _eraserController.takeLastCommittedChunk();
    final restoreBytes = _eraserPreviewRestoreBytes;
    final baseBytes = _eraserPreviewBaseBytes;
    if (chunk == null ||
        restoreBytes == null ||
        baseBytes == null ||
        baseBytes.isEmpty) {
      return;
    }
    final radiusScale =
        _eraserPreviewImagePixelSize.width > 0 &&
            _eraserSessionImagePixelSize.width > 0
        ? (_eraserPreviewImagePixelSize.width /
                  _eraserSessionImagePixelSize.width)
              .clamp(0.01, 1.0)
        : 1.0;
    final previewBytes =
        await compute(applyEraserChunksToPng, <String, dynamic>{
          'currentBytes': baseBytes,
          'restoreBytes': restoreBytes,
          'chunks': <Map<String, dynamic>>[chunk.toMap()],
          'radiusScale': radiusScale,
        });
    if (!mounted || !_isEraserMode || _isEraserApplying) {
      return;
    }
    _eraserPreviewBaseBytes = Uint8List.fromList(previewBytes);
    await _updateEraserPreviewImage(previewBytes);
  }

  Future<void> _rebuildEraserPreviewFromCurrentState() async {
    _eraserPreviewThrottleTimer?.cancel();
    _eraserPreviewThrottleTimer = null;
    _eraserPreviewRevision += 1;
    final restoreBytes = _eraserPreviewRestoreBytes;
    final currentBaseBytes = _eraserController.baseBytes;
    if (restoreBytes == null || currentBaseBytes.isEmpty) {
      return;
    }
    final previewBaseBytes = _createEraserPreviewBytes(currentBaseBytes);
    final chunks = _eraserController.pendingChunks;
    if (chunks.isEmpty) {
      _eraserPreviewBaseBytes = Uint8List.fromList(previewBaseBytes);
      await _updateEraserPreviewImage(previewBaseBytes);
      return;
    }
    final radiusScale =
        _eraserPreviewImagePixelSize.width > 0 &&
            _eraserSessionImagePixelSize.width > 0
        ? (_eraserPreviewImagePixelSize.width /
                  _eraserSessionImagePixelSize.width)
              .clamp(0.01, 1.0)
        : 1.0;
    final previewBytes =
        await compute(applyEraserChunksToPng, <String, dynamic>{
          'currentBytes': previewBaseBytes,
          'restoreBytes': restoreBytes,
          'chunks': chunks.map((item) => item.toMap()).toList(growable: false),
          'radiusScale': radiusScale,
        });
    if (!mounted || !_isEraserMode) {
      return;
    }
    _eraserPreviewBaseBytes = Uint8List.fromList(previewBytes);
    await _updateEraserPreviewImage(previewBytes);
  }

  Future<void> _updateEraserPreviewImage(Uint8List bytes) async {
    final decoded = await _uiImageFromEncodedBytes(bytes);
    if (!mounted || !_isEraserMode) {
      decoded.dispose();
      return;
    }
    final oldPreview = _eraserPreviewImageNotifier.value;
    _eraserPreviewImageNotifier.value = decoded;
    oldPreview?.dispose();
  }

  Future<void> _updateEraserRestorePreviewImage(Uint8List bytes) async {
    final decoded = await _uiImageFromEncodedBytes(bytes);
    if (!mounted || !_isEraserMode) {
      decoded.dispose();
      return;
    }
    final oldPreview = _eraserRestorePreviewImageNotifier.value;
    _eraserRestorePreviewImageNotifier.value = decoded;
    oldPreview?.dispose();
  }

  Future<ui.Image> _uiImageFromEncodedBytes(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Future<void> _openFontPickerScreen() async {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) {
      return;
    }

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _FontPickerScreen(
          fontFamilies: _textFontFamilies,
          selectedFontFamily: layer.fontFamily,
        ),
      ),
    );

    if (!mounted || result == null || result == layer.fontFamily) {
      return;
    }
    _setSelectedTextFontFamily(result);
  }

  void _setCanvasBackgroundColor(Color color) {
    if (_canvasBackgroundGradientIndex == -1 &&
        _stageBackgroundImageBytes == null &&
        _canvasBackgroundColor.toARGB32() == color.toARGB32()) {
      return;
    }

    _pushCanvasBackgroundHistoryEntry(
      beforeColor: _canvasBackgroundColor,
      beforeGradientIndex: _canvasBackgroundGradientIndex,
      beforeImageBytes: _stageBackgroundImageBytes,
      afterColor: color,
      afterGradientIndex: -1,
      afterImageBytes: null,
    );
    setState(() {
      _canvasBackgroundColor = color;
      _canvasBackgroundGradientIndex = -1;
      _stageBackgroundImageBytes = null;
    });
  }

  void _setCanvasBackgroundGradient(int gradientIndex) {
    if (_canvasBackgroundGradientIndex == gradientIndex &&
        _stageBackgroundImageBytes == null) {
      return;
    }

    _pushCanvasBackgroundHistoryEntry(
      beforeColor: _canvasBackgroundColor,
      beforeGradientIndex: _canvasBackgroundGradientIndex,
      beforeImageBytes: _stageBackgroundImageBytes,
      afterColor: _canvasBackgroundColor,
      afterGradientIndex: gradientIndex,
      afterImageBytes: null,
    );
    setState(() {
      _canvasBackgroundGradientIndex = gradientIndex;
      _stageBackgroundImageBytes = null;
    });
  }

  Future<bool> _setCanvasBackgroundImage() async {
    final selected = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (selected == null) {
      return false;
    }

    final bytes = await selected.readAsBytes();
    final optimized = _optimizeEditorPhotoPayload(bytes);
    _pushCanvasBackgroundHistoryEntry(
      beforeColor: _canvasBackgroundColor,
      beforeGradientIndex: _canvasBackgroundGradientIndex,
      beforeImageBytes: _stageBackgroundImageBytes,
      afterColor: _canvasBackgroundColor,
      afterGradientIndex: -1,
      afterImageBytes: optimized.bytes,
    );
    setState(() {
      _stageBackgroundImageBytes = optimized.bytes;
      _canvasBackgroundGradientIndex = -1;
    });
    return true;
  }

  Future<void> _openBackgroundPanel() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _BackgroundPickerScreen(
          colors: editorBackgroundColors,
          gradients: editorBackgroundGradients,
          selectedColor: _canvasBackgroundColor,
          selectedGradientIndex: _canvasBackgroundGradientIndex,
          hasSelectedImage: _stageBackgroundImageBytes != null,
          onColorSelected: _setCanvasBackgroundColor,
          onGradientSelected: _setCanvasBackgroundGradient,
          onImageSelected: _setCanvasBackgroundImage,
        ),
      ),
    );
  }

  Future<void> _openStickerPanel() async {
    final selectedSticker = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _StickerPickerScreen(
          categories: editorElementCategories,
          catalog: editorElementCatalog,
        ),
      ),
    );

    if (!mounted || selectedSticker == null) {
      return;
    }
    _handleAddSticker(selectedSticker);
  }

  Future<void> _openTextEditSheet() async {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) {
      return;
    }

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (BuildContext context) =>
            _TextEditScreen(initialText: layer.text ?? 'Text'),
      ),
    );

    if (!mounted || result == null) {
      return;
    }
    final value = result.trim();
    if (value.isEmpty) {
      return;
    }
    _updateSelectedText(value);
  }

  void _handleLayerSelected(String id) {
    if (_isCropMode || _isEraserMode) {
      return;
    }
    if (_selectedLayerId == id) {
      if (_showTextControls && _hasSelectedTextLayer) {
        setState(() {
          _showTextControls = false;
        });
      }
      return;
    }

    final index = _layers.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    final layer = _layers[index];
    if (layer.isHidden) {
      return;
    }
    final selectedTransform = Matrix4.copy(layer.transform);
    if (!_isMatrixFinite(selectedTransform)) {
      selectedTransform.setIdentity();
    }
    _transformationController.value = selectedTransform;
    setState(() {
      _selectedLayerId = id;
      _showTextControls = false;
      if (_adjustSessionLayerId != id) {
        _isAdjustMode = false;
        _adjustSessionLayerId = null;
      }
      if (_eraserSessionLayerId != id) {
        _isEraserMode = false;
        _isEraserInitializing = false;
        _isEraserApplying = false;
        _eraserSessionLayerId = null;
        _eraserInitError = null;
      }
    });
    if (_eraserSessionLayerId != id) {
      _disposeEraserSessionResources();
    }
  }

  void _handleCanvasTapDown(
    Offset localPosition,
    Rect pageRect,
    Size pageSize,
  ) {
    _dismissJoyHint();
    if (_isCropMode) {
      return;
    }
    if (_suppressCanvasTapDown) {
      _suppressCanvasTapDown = false;
      return;
    }
    final resolvedId = _resolveTopLayerAtPoint(
      localPosition: localPosition,
      pageRect: pageRect,
      pageSize: pageSize,
    );
    if (resolvedId == null) {
      _clearSelection();
      return;
    }
    _handleLayerSelected(resolvedId);
  }

  void _handleSelectedTransformHandlePointerDown() {
    _suppressCanvasTapDown = true;
    _suppressCanvasTapToken++;
    final tokenAtSchedule = _suppressCanvasTapToken;
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (!mounted || _suppressCanvasTapToken != tokenAtSchedule) {
        return;
      }
      _suppressCanvasTapDown = false;
    });
  }

  String? _resolveTopLayerAtPoint({
    required Offset localPosition,
    required Rect pageRect,
    required Size pageSize,
  }) {
    final center = pageRect.center;
    for (final layer in _layers.reversed) {
      if (layer.isHidden) {
        continue;
      }
      final layerSize = _layerVisualSize(layer, pageSize);
      if (layerSize.width <= 0 || layerSize.height <= 0) {
        continue;
      }
      final paddedSize = layer.isText
          ? Size(layerSize.width + 32, layerSize.height + 20)
          : ((layer.isPhoto || layer.isSticker) && layer.id == _selectedLayerId)
          ? Size(layerSize.width + 28, layerSize.height + 28)
          : layerSize;
      final transform = Matrix4.copy(layer.transform);
      final inverse = Matrix4.inverted(transform);
      final localToLayer = MatrixUtils.transformPoint(
        inverse,
        localPosition - center,
      );
      if (layer.id == _selectedLayerId && (layer.isPhoto || layer.isSticker)) {
        final handleCenter = Offset(
          (layerSize.width / 2) + 14,
          (layerSize.height / 2) + 14,
        );
        final handleHit = (localToLayer - handleCenter).distance <= 24;
        if (handleHit) {
          return layer.id;
        }
      }
      final halfWidth = paddedSize.width / 2;
      final halfHeight = paddedSize.height / 2;
      final hit =
          localToLayer.dx >= -halfWidth &&
          localToLayer.dx <= halfWidth &&
          localToLayer.dy >= -halfHeight &&
          localToLayer.dy <= halfHeight;
      if (hit) {
        return layer.id;
      }
    }
    return null;
  }

  Size _layerVisualSize(_CanvasLayer layer, Size pageSize) {
    if (layer.isPhoto) {
      return _fitPhotoLayerSize(
        pageSize: pageSize,
        photoAspectRatio: layer.photoAspectRatio,
      );
    }
    if (layer.isText) {
      final painter = TextPainter(
        text: TextSpan(
          text: layer.text ?? 'Text',
          style: TextStyle(
            fontFamily: layer.fontFamily,
            fontSize: layer.fontSize,
            height: layer.textLineHeight,
            letterSpacing: layer.textLetterSpacing,
            fontWeight: layer.isTextBold ? FontWeight.w800 : FontWeight.w500,
            fontStyle: layer.isTextItalic ? FontStyle.italic : FontStyle.normal,
            decoration: layer.isTextUnderline
                ? TextDecoration.underline
                : TextDecoration.none,
            color: layer.textColor,
          ),
        ),
        textAlign: layer.textAlign,
        textDirection: TextDirection.ltr,
      )..layout();
      final hasBackground = layer.textBackgroundOpacity > 0.001;
      return hasBackground
          ? Size(painter.size.width + 24, painter.size.height + 16)
          : painter.size;
    }
    final sticker = layer.sticker;
    if (_isImageLikeSticker(sticker)) {
      return Size.square(layer.fontSize);
    }
    final painter = TextPainter(
      text: TextSpan(
        text: sticker ?? '*',
        style: TextStyle(fontSize: layer.fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.size;
  }

  void _clearSelection() {
    _cancelSelectedTextLongPress();
    if (_selectedLayerId == null &&
        !_isAdjustMode &&
        !_isEraserMode &&
        !_snapGuides.isVisible) {
      return;
    }
    _transformationController.value = Matrix4.identity();
    _snapGuideNotifier.value = const _SnapGuideState.none();
    setState(() {
      _selectedLayerId = null;
      _showTextControls = false;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _isEraserMode = false;
      _isEraserInitializing = false;
      _isEraserApplying = false;
      _eraserSessionLayerId = null;
      _eraserInitError = null;
    });
    _disposeEraserSessionResources();
  }

  void _handleSelectedTextDoubleTap() {
    if (!_hasSelectedTextLayer) {
      return;
    }
    _cancelSelectedTextLongPress();
    setState(() {
      _showTextControls = true;
    });
  }

  void _startSelectedTextLongPress(PointerDownEvent event) {
    if (!_hasSelectedTextLayer) {
      return;
    }
    _cancelSelectedTextLongPress();
    _selectedTextPressPosition = event.position;
    _selectedTextLongPressTimer = Timer(const Duration(seconds: 2), () {
      _selectedTextLongPressTimer = null;
      _selectedTextPressPosition = null;
      if (!mounted || !_hasSelectedTextLayer) {
        return;
      }
      _openTextEditSheet();
    });
  }

  void _updateSelectedTextLongPress(PointerMoveEvent event) {
    final origin = _selectedTextPressPosition;
    if (origin == null) {
      return;
    }
    if ((event.position - origin).distance > 12) {
      _cancelSelectedTextLongPress();
    }
  }

  void _cancelSelectedTextLongPress() {
    _selectedTextLongPressTimer?.cancel();
    _selectedTextLongPressTimer = null;
    _selectedTextPressPosition = null;
  }

  void _updateSmartGuides(Matrix4 matrix) {
    final currentX = matrix.storage[12];
    final currentY = matrix.storage[13];
    final shouldSnapX = currentX.abs() <= _snapThreshold;
    final shouldSnapY = currentY.abs() <= _snapThreshold;

    final nextState = _SnapGuideState(
      showVerticalGuide: shouldSnapX,
      showHorizontalGuide: shouldSnapY,
    );
    if (_snapGuideNotifier.value != nextState) {
      _snapGuideNotifier.value = nextState;
    }
  }

  void _syncSelectedLayerTransform() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1) {
      return;
    }
    final current = _layers[index].transform;
    final updated = _transformationController.value;
    if (_isSameMatrix(current, updated)) {
      return;
    }

    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(transform: Matrix4.copy(updated));
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    _isLayerInteracting = false;
    _snapGuideNotifier.value = const _SnapGuideState.none();
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _handleSelectedLayerInteractionStart(ScaleStartDetails details) {
    if (_isSelectedLayerLocked) {
      return;
    }
    _stopPhotoGlide(sync: false);
    _cancelSelectedTextLongPress();
    _gestureStartMatrix = Matrix4.copy(_transformationController.value);
    _gestureStartFocalPoint = details.focalPoint;
    _gestureStartLocalFocalPoint = details.localFocalPoint;
    _photoGestureLastFocalPoint = details.focalPoint;
    _photoGestureLastScale = 1;
    _photoGestureLastRotation = 0;
    _photoGestureVelocity = Offset.zero;
    _photoGestureLastTimestampMicros = DateTime.now().microsecondsSinceEpoch;
    if (_isLayerInteracting) {
      return;
    }
    _isLayerInteracting = true;
  }

  Offset _selectedTransformCenterGlobal() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return Offset.zero;
    }
    final stageRect = _currentStageLogicalRect();
    final matrix = _transformationController.value;
    final centerLocal = stageRect.center.translate(
      matrix.storage[12],
      matrix.storage[13],
    );
    return renderObject.localToGlobal(centerLocal);
  }

  void _handleSelectedStickerHandleStart(DragStartDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto) ||
        _isSelectedLayerLocked) {
      return;
    }
    _stopPhotoGlide(sync: false);
    _cancelSelectedTextLongPress();
    _gestureStartMatrix = Matrix4.copy(_transformationController.value);
    final center = _selectedTransformCenterGlobal();
    final vector = details.globalPosition - center;
    _stickerHandleStartAngle = math.atan2(vector.dy, vector.dx);
    _stickerHandleStartDistance = math.max(vector.distance, 1);
    _photoGestureVelocity = Offset.zero;
    if (_isLayerInteracting) {
      return;
    }
    _isLayerInteracting = true;
  }

  void _handleSelectedStickerHandleUpdate(DragUpdateDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto) ||
        _isSelectedLayerLocked) {
      return;
    }
    final base = Matrix4.copy(
      _gestureStartMatrix ?? _transformationController.value,
    );
    final updated = Matrix4.copy(base);
    final center = _selectedTransformCenterGlobal();
    final vector = details.globalPosition - center;
    final angle = math.atan2(vector.dy, vector.dx);
    final distance = math.max(vector.distance, 1);
    final angleDelta = _shortestAngleDelta(
      from: _stickerHandleStartAngle,
      to: angle,
    );
    final scaleRatio = (distance / _stickerHandleStartDistance)
        .clamp(0.25, 8.0)
        .toDouble();
    if (angleDelta.abs() > 0.0001) {
      updated.rotateZ(angleDelta);
    }
    if ((scaleRatio - 1).abs() > 0.0001) {
      updated.scaleByDouble(scaleRatio, scaleRatio, 1, 1);
    }
    if (!_isMatrixFinite(updated)) {
      return;
    }
    _transformationController.value = updated;
    _updateSmartGuides(updated);
  }

  void _handleSelectedStickerHandleEnd() {
    _handleSelectedLayerInteractionEnd();
  }

  void _handleSelectedLayerScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedLayerId == null || _isSelectedLayerLocked) {
      return;
    }
    final selectedLayer = _selectedLayer;
    if (selectedLayer == null) {
      return;
    }
    final base = Matrix4.copy(
      _gestureStartMatrix ?? _transformationController.value,
    );
    final updated = Matrix4.copy(base);

    if (selectedLayer.isPhoto || selectedLayer.isSticker) {
      final incremental = Matrix4.copy(_transformationController.value);
      final moveDelta = details.focalPoint - _photoGestureLastFocalPoint;
      final nowMicros = DateTime.now().microsecondsSinceEpoch;
      final elapsedMicros = _photoGestureLastTimestampMicros == 0
          ? 0
          : nowMicros - _photoGestureLastTimestampMicros;
      _photoGestureLastTimestampMicros = nowMicros;

      // One-finger transform drag follows the finger in screen-space only.
      if (details.pointerCount < 2) {
        if (moveDelta.distanceSquared < 0.04) {
          _photoGestureLastFocalPoint = details.focalPoint;
          return;
        }
        incremental.setTranslationRaw(
          incremental.storage[12] + moveDelta.dx,
          incremental.storage[13] + moveDelta.dy,
          incremental.storage[14],
        );
        if (!_isMatrixFinite(incremental)) {
          return;
        }
        _transformationController.value = incremental;
        _updateSmartGuides(incremental);
        if (elapsedMicros > 0) {
          final dtSeconds = elapsedMicros / Duration.microsecondsPerSecond;
          final instantVelocity = Offset(
            moveDelta.dx / dtSeconds,
            moveDelta.dy / dtSeconds,
          );
          _photoGestureVelocity = Offset(
            (_photoGestureVelocity.dx * 0.72) + (instantVelocity.dx * 0.28),
            (_photoGestureVelocity.dy * 0.72) + (instantVelocity.dy * 0.28),
          );
        }
        _photoGestureLastFocalPoint = details.focalPoint;
        _photoGestureLastScale = details.scale;
        _photoGestureLastRotation = details.rotation;
        return;
      }

      // Two-finger transform uses incremental deltas to avoid jumps when
      // fingers are added/removed or focal point shifts between frames.
      final scaleRatio =
          (_photoGestureLastScale == 0
                  ? 1.0
                  : details.scale / _photoGestureLastScale)
              .clamp(0.2, 8.0)
              .toDouble();
      final rotationDelta = details.rotation - _photoGestureLastRotation;
      final currentRotation = _matrixRotationZ(incremental);
      final targetRotation = currentRotation + rotationDelta;
      final snappedRotation = _softSnapRotation(targetRotation);
      final appliedRotationDelta = snappedRotation - currentRotation;

      incremental.setTranslationRaw(
        incremental.storage[12] + moveDelta.dx,
        incremental.storage[13] + moveDelta.dy,
        incremental.storage[14],
      );
      final focal = details.localFocalPoint;
      incremental.translateByDouble(focal.dx, focal.dy, 0, 1);
      if (appliedRotationDelta.abs() > 0.0001) {
        incremental.rotateZ(appliedRotationDelta);
      }
      if ((scaleRatio - 1).abs() > 0.0001) {
        incremental.scaleByDouble(scaleRatio, scaleRatio, 1, 1);
      }
      incremental.translateByDouble(-focal.dx, -focal.dy, 0, 1);

      if (!_isMatrixFinite(incremental)) {
        return;
      }
      _transformationController.value = incremental;
      _updateSmartGuides(incremental);
      _photoGestureLastFocalPoint = details.focalPoint;
      _photoGestureLastScale = details.scale;
      _photoGestureLastRotation = details.rotation;
      _photoGestureVelocity = Offset.zero;
      _photoGestureLastTimestampMicros = nowMicros;
      return;
    }

    // Non-transform layers keep the existing gesture flow.

    final effectiveBase = Matrix4.copy(
      _gestureStartMatrix ?? _transformationController.value,
    );
    final effectiveDelta = details.focalPoint - _gestureStartFocalPoint;
    updated.setFrom(effectiveBase);
    updated.translateByDouble(effectiveDelta.dx, effectiveDelta.dy, 0, 1);

    final focal = _gestureStartLocalFocalPoint;
    final baseRotation = _matrixRotationZ(effectiveBase);
    final targetRotation = baseRotation + details.rotation;
    final snappedRotation = _softSnapRotation(targetRotation);
    final deltaRotation = snappedRotation - baseRotation;

    updated.translateByDouble(focal.dx, focal.dy, 0, 1);
    if (deltaRotation.abs() > 0.0001) {
      updated.rotateZ(deltaRotation);
    }
    final scale = details.scale.clamp(0.2, 8.0).toDouble();
    if ((scale - 1).abs() > 0.0001) {
      updated.scaleByDouble(scale, scale, 1, 1);
    }
    updated.translateByDouble(-focal.dx, -focal.dy, 0, 1);

    if (!_isMatrixFinite(updated)) {
      return;
    }

    _transformationController.value = updated;
    _updateSmartGuides(updated);
  }

  void _handleSelectedLayerInteractionEnd() {
    if (_isSelectedLayerLocked) {
      return;
    }
    final selectedLayer = _selectedLayer;
    if ((selectedLayer?.isPhoto ?? false) ||
        (selectedLayer?.isSticker ?? false)) {
      final speed = _photoGestureVelocity.distance;
      if (speed > 220) {
        final clampedSpeed = speed.clamp(0, 1800).toDouble();
        final direction = _photoGestureVelocity / speed;
        final travel = clampedSpeed * 0.09;
        _photoGlideTotalTravel = Offset(
          direction.dx * travel,
          direction.dy * travel,
        );
        _photoGlideAppliedTravel = Offset.zero;
        _photoGlideController
          ..stop()
          ..reset()
          ..forward();
      } else {
        _syncSelectedLayerTransform();
      }
    } else {
      _syncSelectedLayerTransform();
    }
    _gestureStartMatrix = null;
    _gestureStartFocalPoint = Offset.zero;
    _gestureStartLocalFocalPoint = Offset.zero;
    _photoGestureLastFocalPoint = Offset.zero;
    _photoGestureLastScale = 1;
    _photoGestureLastRotation = 0;
    _stickerHandleStartAngle = 0;
    _stickerHandleStartDistance = 1;
    _photoGestureVelocity = Offset.zero;
    _photoGestureLastTimestampMicros = 0;
    if (_pendingAutosave) {
      _scheduleAutosave();
    }
  }

  void _resetSelectedLayerToFit() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    _transformationController.value = Matrix4.identity();
    _syncSelectedLayerTransform();
  }

  void _handlePhotoGlideTick() {
    if (!_photoGlideController.isAnimating) {
      return;
    }
    final progress = Curves.easeOutCubic.transform(_photoGlideController.value);
    final nextTravel = Offset(
      _photoGlideTotalTravel.dx * progress,
      _photoGlideTotalTravel.dy * progress,
    );
    final delta = nextTravel - _photoGlideAppliedTravel;
    if (delta.distanceSquared <= 0) {
      return;
    }
    final incremental = Matrix4.copy(_transformationController.value);
    incremental.setTranslationRaw(
      incremental.storage[12] + delta.dx,
      incremental.storage[13] + delta.dy,
      incremental.storage[14],
    );
    if (!_isMatrixFinite(incremental)) {
      return;
    }
    _photoGlideAppliedTravel = nextTravel;
    _transformationController.value = incremental;
  }

  void _stopPhotoGlide({required bool sync}) {
    if (!_photoGlideController.isAnimating &&
        _photoGlideAppliedTravel == Offset.zero &&
        _photoGlideTotalTravel == Offset.zero) {
      return;
    }
    _photoGlideController.stop();
    _photoGlideAppliedTravel = Offset.zero;
    _photoGlideTotalTravel = Offset.zero;
    if (sync) {
      _syncSelectedLayerTransform();
    }
  }

  void _handleDeleteSelectedLayer() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    _deleteLayerById(selectedId);
  }

  Future<void> _handleRemoveBackgroundTap() async {
    if (_isRemovingBackground || _isCommitWorkerBusy) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }
    if (!_hasSelectedPhotoLayer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }

    final taskId = ++_removeBackgroundTaskId;
    final initialLayerIndex = _layers.indexWhere(
      (item) => item.id == selectedId,
    );
    if (initialLayerIndex == -1) {
      return;
    }

    final layer = _layers[initialLayerIndex];
    final sourceBytes = layer.bytes;
    if (sourceBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Remove BG కోసం సోర్స్ ఫోటో అందుబాటులో లేదు',
              english: 'Source photo unavailable for Remove BG',
            ),
          ),
        ),
      );
      return;
    }

    try {
      final result = await _runQueuedCommitJob<BackgroundRemovalResult>(
        jobKey: 'remove_bg_$taskId',
        label: context.strings.localized(
          telugu: 'బ్యాక్‌గ్రౌండ్ తొలగిస్తోంది',
          english: 'Removing background',
        ),
        detail: context.strings.localized(
          telugu: 'ఎంచుకున్న ఫోటో లేయర్‌ను AI ప్రాసెస్ చేస్తోంది',
          english: 'AI is processing the selected photo layer',
        ),
        onStart: () {
          _isRemovingBackground = true;
        },
        onFinish: () {
          _isRemovingBackground = false;
        },
        operation: () async {
          await _backgroundRemoverInitialization;
          return _backgroundRemovalService.removeBackground(sourceBytes);
        },
      );
      if (result == null || !mounted || taskId != _removeBackgroundTaskId) {
        return;
      }

      final layerIndex = _layers.indexWhere((item) => item.id == selectedId);
      if (layerIndex == -1) {
        return;
      }
      final beforeLayer = _layers[layerIndex];
      final afterLayer = beforeLayer.copyWith(bytes: result.pngBytes);
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
      setState(() {
        _layers[layerIndex] = afterLayer;
      });
      return;
    } catch (error) {
      if (!mounted || taskId != _removeBackgroundTaskId) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Remove BG కాలేదు: ${error.toString()}',
              english: 'Remove BG failed: ${error.toString()}',
            ),
          ),
        ),
      );
      return;
    }
  }

  Future<void> _handleCropPhotoTap() async {
    final selectedId = _selectedLayerId;
    if (selectedId == null || !_hasSelectedPhotoLayer || _isCropMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'క్రాప్ కోసం ఒక ఫోటో లేయర్ ఎంచుకోండి',
              english: 'Select a photo layer for crop',
            ),
          ),
        ),
      );
      return;
    }
    final layerIndex = _layers.indexWhere((item) => item.id == selectedId);
    if (layerIndex == -1) {
      return;
    }
    final layer = _layers[layerIndex];
    if (layer.bytes == null) {
      return;
    }
    setState(() {
      _isCropMode = true;
      _cropSessionLayerId = selectedId;
      _cropSessionImageBytes = Uint8List.fromList(layer.bytes!);
      _cropSessionInitialAspectRatio = null;
      _cropSessionAspectRatio = _cropSessionInitialAspectRatio;
      _cropTransformationController.value = Matrix4.identity();
    });
  }

  void _discardCropSession() {
    if (!_isCropMode || _isCropApplying) {
      return;
    }
    setState(() {
      _isCropMode = false;
      _cropSessionLayerId = null;
      _cropSessionImageBytes = null;
      _cropSessionAspectRatio = null;
      _cropSessionInitialAspectRatio = null;
      _cropTransformationController.value = Matrix4.identity();
    });
  }

  void _resetCropSession() {
    if (!_isCropMode || _isCropApplying) {
      return;
    }
    setState(() {
      _cropTransformationController.value = Matrix4.identity();
      _cropSessionAspectRatio = _cropSessionInitialAspectRatio;
    });
  }

  void _setCropAspectRatio(double? ratio) {
    if (!_isCropMode || _isCropApplying) {
      return;
    }
    setState(() {
      _cropSessionAspectRatio = ratio;
    });
  }

  Future<void> _applyCropSession() async {
    final layerId = _cropSessionLayerId;
    final sessionBytes = _cropSessionImageBytes;
    if (_isCropApplying ||
        _isCommitWorkerBusy ||
        !_isCropMode ||
        layerId == null ||
        sessionBytes == null) {
      return;
    }
    final cropPreviewUnavailableMessage = context.strings.localized(
      telugu: 'క్రాప్ ప్రీవ్యూ అందుబాటులో లేదు',
      english: 'Crop preview unavailable',
    );
    final cropEncodeFailedMessage = context.strings.localized(
      telugu: 'క్రాప్ ఎన్‌కోడ్ కాలేదు',
      english: 'Crop encode failed',
    );
    ui.Image? image;
    try {
      final cropPayload = await _runQueuedCommitJob<Map<String, dynamic>>(
        jobKey: 'crop_$layerId',
        label: context.strings.localized(
          telugu: 'క్రాప్ అప్లై అవుతోంది',
          english: 'Applying crop',
        ),
        detail: context.strings.localized(
          telugu: 'క్రాప్ చేసిన లేయర్‌ను ఫైనల్ చేస్తోంది',
          english: 'Finalizing cropped layer preview',
        ),
        onStart: () {
          _isCropApplying = true;
        },
        onFinish: () {
          _isCropApplying = false;
        },
        operation: () async {
          final boundary =
              _cropBoundaryKey.currentContext?.findRenderObject()
                  as RenderRepaintBoundary?;
          if (boundary == null) {
            throw Exception(cropPreviewUnavailableMessage);
          }
          image = await boundary.toImage(pixelRatio: 2.5);
          final byteData = await image!.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null || !mounted) {
            throw Exception(cropEncodeFailedMessage);
          }
          return compute(
            _prepareCropCommitPayload,
            Uint8List.fromList(byteData.buffer.asUint8List()),
          );
        },
      );
      if (cropPayload == null || !mounted) {
        return;
      }
      final croppedBytes = cropPayload['bytes'] as Uint8List;
      final layerIndex = _layers.indexWhere((item) => item.id == layerId);
      if (layerIndex == -1) {
        _discardCropSession();
        return;
      }
      final beforeLayer = _layers[layerIndex];
      final afterLayer = beforeLayer.copyWith(
        bytes: croppedBytes,
        photoAspectRatio: (cropPayload['aspectRatio'] as num?)?.toDouble(),
      );
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
      setState(() {
        _layers[layerIndex] = afterLayer;
        _isCropMode = false;
        _cropSessionLayerId = null;
        _cropSessionImageBytes = null;
        _cropSessionAspectRatio = null;
        _cropSessionInitialAspectRatio = null;
        _cropTransformationController.value = Matrix4.identity();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCropApplying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'క్రాప్ అప్లై కాలేదు: $error',
              english: 'Crop apply failed: $error',
            ),
          ),
        ),
      );
    } finally {
      image?.dispose();
    }
  }

  void _handleDuplicateSelectedLayer() {
    final index = _selectedLayerIndex;
    if (index == -1) {
      return;
    }
    final current = _layers[index];
    final duplicatedTransform = Matrix4.copy(current.transform);
    duplicatedTransform.storage[12] += 12;
    duplicatedTransform.storage[13] += 12;
    final duplicated = current.copyWith(
      id: 'layer_${_layerSeed++}',
      transform: duplicatedTransform,
    );

    _pushLayerInsertHistoryEntry(
      layer: duplicated,
      insertIndex: _layers.length,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: duplicated.id,
    );
    setState(() {
      _layers.add(duplicated);
      _selectedLayerId = duplicated.id;
      _transformationController.value = Matrix4.copy(duplicated.transform);
    });
  }

  void _moveSelectedLayerToFront() {
    final index = _selectedLayerIndex;
    if (index == -1 || index == _layers.length - 1) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }

    _pushLayerReorderHistoryEntry(
      layerId: selectedId,
      fromIndex: index,
      toIndex: _layers.length - 1,
      beforeSelectedLayerId: selectedId,
      afterSelectedLayerId: selectedId,
    );
    setState(() {
      final layer = _layers.removeAt(index);
      _layers.add(layer);
      _selectedLayerId = selectedId;
      _transformationController.value = Matrix4.copy(layer.transform);
    });
  }

  void _moveSelectedLayerToBack() {
    final index = _selectedLayerIndex;
    if (index <= 0) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }

    _pushLayerReorderHistoryEntry(
      layerId: selectedId,
      fromIndex: index,
      toIndex: 0,
      beforeSelectedLayerId: selectedId,
      afterSelectedLayerId: selectedId,
    );
    setState(() {
      final layer = _layers.removeAt(index);
      _layers.insert(0, layer);
      _selectedLayerId = selectedId;
      _transformationController.value = Matrix4.copy(layer.transform);
    });
  }

  void _deleteLayerById(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) {
      return;
    }
    final layer = _layers[index];
    String? nextSelectedLayerId = _selectedLayerId;
    if (_selectedLayerId == layerId) {
      if (_layers.length == 1) {
        nextSelectedLayerId = null;
      } else {
        nextSelectedLayerId = index == _layers.length - 1
            ? _layers[_layers.length - 2].id
            : _layers.last.id;
      }
    }
    _pushLayerDeleteHistoryEntry(
      layer: layer,
      deletedIndex: index,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: nextSelectedLayerId,
    );
    setState(() {
      _layers.removeAt(index);
      if (_layers.isEmpty) {
        _selectedLayerId = null;
        _transformationController.value = Matrix4.identity();
      } else {
        if (_selectedLayerId == layerId) {
          final next = _layers.last;
          _selectedLayerId = next.id;
          _transformationController.value = Matrix4.copy(next.transform);
        } else if (_selectedLayerId != null) {
          final currentIndex = _layers.indexWhere(
            (item) => item.id == _selectedLayerId,
          );
          if (currentIndex != -1) {
            _transformationController.value = Matrix4.copy(
              _layers[currentIndex].transform,
            );
          }
        }
      }
    });
  }

  void _toggleLayerLock(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) return;
    setState(() {
      final updated = _layers[index].copyWith(
        isLocked: !_layers[index].isLocked,
      );
      _layers[index] = updated;
      if (updated.id == _selectedLayerId) {
        _transformationController.value = Matrix4.copy(updated.transform);
      }
    });
  }

  void _toggleLayerVisibility(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) return;
    setState(() {
      final updated = _layers[index].copyWith(
        isHidden: !_layers[index].isHidden,
      );
      _layers[index] = updated;
      if (updated.isHidden && _selectedLayerId == layerId) {
        _selectedLayerId = null;
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  void _reorderLayers(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _layers.length) {
      return;
    }

    final adjustedNewIndex = newIndex > oldIndex
        ? newIndex - 1
        : newIndex.clamp(0, _layers.length);
    if (adjustedNewIndex == oldIndex || adjustedNewIndex >= _layers.length) {
      return;
    }

    final layerId = _layers[oldIndex].id;
    _pushLayerReorderHistoryEntry(
      layerId: layerId,
      fromIndex: oldIndex,
      toIndex: adjustedNewIndex,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: _selectedLayerId,
    );
    setState(() {
      final item = _layers.removeAt(oldIndex);
      _layers.insert(adjustedNewIndex, item);
    });
  }

  // ignore: unused_element
  Future<void> _openLayersPanel() async {
    if (_layers.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        final strings = context.strings;
        final double height = math
            .min(MediaQuery.of(context).size.height * 0.65, 460)
            .toDouble();
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SizedBox(
              height: height,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: <Widget>[
                        Text(
                          strings.localized(
                            telugu: 'లేయర్స్',
                            english: 'Layers',
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: strings.localized(
                            telugu: 'మూసివేయి',
                            english: 'Close',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: _layers.length,
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      onReorder: (oldIndex, newIndex) {
                        _reorderLayers(oldIndex, newIndex);
                        setSheetState(() {});
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final layer = _layers[index];
                        final isSelected = layer.id == _selectedLayerId;

                        return ListTile(
                          key: ValueKey(layer.id),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: layer.isPhoto
                                ? Image(
                                    image:
                                        _PhotoLayerImageProviderCache.resolve(
                                          bytes: layer.bytes!,
                                          cacheWidth: 96,
                                        ),
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.low,
                                  )
                                : layer.isText
                                ? const Icon(
                                    Icons.text_fields_rounded,
                                    color: Color(0xFF334155),
                                  )
                                : Center(
                                    child:
                                        _ImageEditorScreenState._buildStickerVisual(
                                          layer.sticker,
                                          fontSize: 22,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.low,
                                        ),
                                  ),
                          ),
                          title: Text(
                            layer.isPhoto
                                ? strings.localized(
                                    telugu: 'Photo ${index + 1}',
                                    english: 'Photo ${index + 1}',
                                  )
                                : layer.isText
                                ? strings.localized(
                                    telugu: 'Text ${index + 1}',
                                    english: 'Text ${index + 1}',
                                  )
                                : strings.localized(
                                    telugu: 'Sticker ${index + 1}',
                                    english: 'Sticker ${index + 1}',
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: isSelected
                              ? Text(
                                  strings.localized(
                                    telugu: 'ఎంపికైంది',
                                    english: 'Selected',
                                  ),
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                          trailing: SizedBox(
                            width: 92,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                IconButton(
                                  onPressed: () {
                                    _deleteLayerById(layer.id);
                                    if (_layers.isEmpty && mounted) {
                                      Navigator.of(context).maybePop();
                                    } else {
                                      setSheetState(() {});
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  tooltip: strings.localized(
                                    telugu: 'డిలీట్',
                                    english: 'Delete',
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(Icons.drag_handle_rounded),
                                ),
                              ],
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: const Color(
                            0xFFDBEAFE,
                          ).withValues(alpha: 0.42),
                          onTap: () {
                            _handleLayerSelected(layer.id);
                            setSheetState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openLayersScreen() async {
    if (_layers.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _LayersScreen(
          layers: _layers,
          selectedLayerId: _selectedLayerId,
          onSelectLayer: _handleLayerSelected,
          onDeleteLayer: _deleteLayerById,
          onToggleLayerLock: _toggleLayerLock,
          onToggleLayerVisibility: _toggleLayerVisibility,
          onReorderLayers: _reorderLayers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B16),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final canvasSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final bottomToolsHeight = _isCropMode
                ? _cropBarHeight
                : _isEraserMode
                ? _eraserBarHeight
                : _isAdjustMode
                ? _adjustBarHeight
                : _bottomBarHeight +
                      (_hasSelectedPhotoLayer ? _photoControlsExtraHeight : 0);
            const reservedTopInset = _canvasChromeInset;
            const reservedBottomInset = _canvasChromeInset;
            final activeModeLabel = _activeModeLabel;
            final showQuickHint =
                _showJoyHint &&
                !_isCropMode &&
                !_isEraserMode &&
                !_isAdjustMode &&
                !_isRemovingBackground &&
                _selectedLayerId == null;
            _lastCanvasSize = canvasSize;
            final workspaceHeight = math.max(
              canvasSize.height - reservedTopInset - reservedBottomInset,
              0.0,
            );
            final workspaceSize = Size(canvasSize.width, workspaceHeight);
            final hasPageSelection = (_pageAspectRatio ?? 0) > 0;
            final pageSize = hasPageSelection
                ? _fitPageSize(
                    workspaceSize: workspaceSize,
                    aspectRatio: _pageAspectRatio!,
                  )
                : workspaceSize;

            if (_templateDocument != null &&
                !_isTemplateHydrated &&
                !_templateHydrationScheduled &&
                !_isTemplateHydrationInProgress &&
                pageSize.width > 0 &&
                pageSize.height > 0) {
              _templateHydrationScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _templateHydrationScheduled = false;
                final document = _templateDocument;
                if (document == null) {
                  return;
                }
                unawaited(
                  _hydrateTemplateDocument(
                    document: document,
                    pageSize: pageSize,
                  ),
                );
              });
            }

            return Stack(
              children: <Widget>[
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0xFF060B16),
                            Color(0xFF0B1220),
                            Color(0xFF111827),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -90,
                  left: -50,
                  child: IgnorePointer(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            const Color(0xFF2563EB).withValues(alpha: 0.15),
                            const Color(0xFF2563EB).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -70,
                  bottom: 110,
                  child: IgnorePointer(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            const Color(0xFF7C3AED).withValues(alpha: 0.14),
                            const Color(0xFF7C3AED).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _stageRepaintKey,
                    child: _CanvasWorkspace(
                      layers: _layers,
                      selectedLayerId: _selectedLayerId,
                      canvasBackgroundColor: _canvasBackgroundColor,
                      canvasBackgroundGradientIndex:
                          _canvasBackgroundGradientIndex,
                      stageBackgroundImageBytes: _stageBackgroundImageBytes,
                      canvasSize: canvasSize,
                      pageAspectRatio: _pageAspectRatio,
                      hideAutoPageFrame: _pageAspectRatioAutoFromImage,
                      topInset: reservedTopInset,
                      bottomInset: reservedBottomInset,
                      transformationController: _transformationController,
                      onLayerSelected: _handleLayerSelected,
                      onSelectedLayerInteractionStart:
                          _handleSelectedLayerInteractionStart,
                      onSelectedLayerScaleUpdate:
                          _handleSelectedLayerScaleUpdate,
                      onSelectedLayerInteractionEnd:
                          _handleSelectedLayerInteractionEnd,
                      onSelectedTransformHandlePointerDown:
                          _handleSelectedTransformHandlePointerDown,
                      onSelectedStickerHandleStart:
                          _handleSelectedStickerHandleStart,
                      onSelectedStickerHandleUpdate:
                          _handleSelectedStickerHandleUpdate,
                      onSelectedStickerHandleEnd:
                          _handleSelectedStickerHandleEnd,
                      onSelectedLayerDoubleTap: _resetSelectedLayerToFit,
                      onSelectedTextDoubleTap: _handleSelectedTextDoubleTap,
                      onSelectedTextPointerDown: _startSelectedTextLongPress,
                      onSelectedTextPointerMove: _updateSelectedTextLongPress,
                      onSelectedTextPointerCancel: _cancelSelectedTextLongPress,
                      onCanvasTapDown: (_isCropMode || _isEraserMode)
                          ? (
                              Offset _,
                              Rect pageRectIgnored,
                              Size pageSizeIgnored,
                            ) {}
                          : _handleCanvasTapDown,
                      onCanvasTap: (_isCropMode || _isEraserMode)
                          ? () {}
                          : _clearSelection,
                      showCanvasBackground: !_isTransparentExportCapture,
                      photoBrightnessForLayer: _effectivePhotoBrightness,
                      photoContrastForLayer: _effectivePhotoContrast,
                      photoSaturationForLayer: _effectivePhotoSaturation,
                      photoBlurForLayer: _effectivePhotoBlur,
                      showSelectionDecorations:
                          !_isCropMode &&
                          !_isEraserMode &&
                          !_isExporting &&
                          !_isCapturingStage,
                      showPageFramePreview: !_isExporting && !_isCapturingStage,
                      snapGuideListenable: _snapGuideNotifier,
                      snapGuidesEnabled:
                          !_isCropMode && !_isEraserMode && !_isCapturingStage,
                      selectedPhotoRenderListenable:
                          _selectedPhotoRenderNotifier,
                      eraserSessionLayerId: _eraserSessionLayerId,
                      eraserPreviewImageListenable: _eraserPreviewImageNotifier,
                      eraserRestorePreviewImageListenable:
                          _eraserRestorePreviewImageNotifier,
                      eraserActiveStrokeListenable:
                          _eraserActiveStrokeNotifier,
                      eraserPreviewBaseBytes:
                          _eraserController.baseBytes.isEmpty
                          ? null
                          : _eraserController.baseBytes,
                    ),
                  ),
                ),
                if (_isCropMode && _cropSessionImageBytes != null)
                  Positioned.fill(
                    child: _CropSessionOverlay(
                      boundaryKey: _cropBoundaryKey,
                      imageBytes: _cropSessionImageBytes!,
                      controller: _cropTransformationController,
                      topInset: reservedTopInset,
                      bottomInset: reservedBottomInset,
                      aspectRatio:
                          _cropSessionAspectRatio ??
                          (_selectedLayer?.photoAspectRatio ??
                              _pageAspectRatio),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: RepaintBoundary(
                    child: _TopBar(
                      height: _topBarHeight,
                      onUndoTap: _handleUndo,
                      onRedoTap: _handleRedo,
                      onDraftsTap: _openDraftsScreen,
                      onExportTap: _handleExportTap,
                      onDeleteTap: _handleDeleteSelectedLayer,
                      onDuplicateTap: _handleDuplicateSelectedLayer,
                      onBringFrontTap: _moveSelectedLayerToFront,
                      onSendBackTap: _moveSelectedLayerToBack,
                      canUndo: _canUndo,
                      canRedo: _canRedo,
                      isExporting: _isExporting,
                      canDelete: _selectedLayerId != null,
                      canDuplicate: _selectedLayerId != null,
                      canBringFront:
                          _selectedLayerIndex != -1 &&
                          _selectedLayerIndex < _layers.length - 1,
                      canSendBack: _selectedLayerIndex > 0,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: bottomToolsHeight + 10,
                  child: RepaintBoundary(
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      offset:
                          !_isCropMode &&
                              !_isEraserMode &&
                              _hasSelectedTextLayer &&
                              _showTextControls
                          ? Offset.zero
                          : const Offset(0, 0.06),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity:
                            !_isCropMode &&
                                !_isEraserMode &&
                                _hasSelectedTextLayer &&
                                _showTextControls
                            ? 1
                            : 0,
                        child: IgnorePointer(
                          ignoring:
                              _isCropMode ||
                              _isEraserMode ||
                              !_hasSelectedTextLayer ||
                              !_showTextControls,
                          child: _TextStyleBar(
                            visible:
                                !_isCropMode &&
                                !_isEraserMode &&
                                _hasSelectedTextLayer &&
                                _showTextControls,
                            selectedLayer: _selectedLayer,
                            colors: _textColors,
                            backgroundColors: editorBackgroundColors,
                            gradients: _textGradients,
                            onEditTap: _openTextEditSheet,
                            onFontsTap: _openFontPickerScreen,
                            onColorSelected: _setSelectedTextColor,
                            onBackgroundColorSelected:
                                _setSelectedTextBackgroundColor,
                            onAlignSelected: _setSelectedTextAlignment,
                            onGradientSelected: _setSelectedTextGradient,
                            onFontSizeChanged: _setSelectedTextFontSize,
                            onFontSizeChangeStart: _handleTextFontSizeEditStart,
                            onFontSizeChangeEnd: _handleTextFontSizeEditEnd,
                            onBackgroundOpacityChanged:
                                _setSelectedTextBackgroundOpacity,
                            onBackgroundRadiusChanged:
                                _setSelectedTextBackgroundRadius,
                            onLineHeightChanged: _setSelectedTextLineHeight,
                            onLetterSpacingChanged:
                                _setSelectedTextLetterSpacing,
                            onShadowOpacityChanged:
                                _setSelectedTextShadowOpacity,
                            onShadowBlurChanged: _setSelectedTextShadowBlur,
                            onShadowOffsetYChanged:
                                _setSelectedTextShadowOffsetY,
                            onBoldToggle: _toggleSelectedTextBold,
                            onItalicToggle: _toggleSelectedTextItalic,
                            onUnderlineToggle: _toggleSelectedTextUnderline,
                            onStrokeColorSelected: _setSelectedTextStrokeColor,
                            onStrokeWidthChanged: _setSelectedTextStrokeWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isEraserMode)
                  Positioned.fill(
                    child: EraserOverlay(
                      canvasSize: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                      topInset: reservedTopInset,
                      bottomInset: reservedBottomInset,
                      pageAspectRatio: _pageAspectRatio,
                      brushSize: _eraserBrushSize,
                      brushCenterListenable: _eraserBrushCursorNotifier,
                      mode: _eraserMode == _EraserMode.restore
                          ? EraserBlendMode.restore
                          : EraserBlendMode.erase,
                      isInitializing: _isEraserInitializing,
                      errorMessage: _eraserInitError,
                      onSingleFingerStart: _handleEraserPanStart,
                      onSingleFingerUpdate: _handleEraserPanUpdate,
                      onSingleFingerEnd: _handleEraserPanEnd,
                      onScaleStart: _handleEraserScaleStart,
                      onScaleUpdate: _handleEraserScaleUpdate,
                      onScaleEnd: _handleEraserScaleEnd,
                    ),
                  ),
                if (activeModeLabel != null)
                  Positioned(
                    left: 18,
                    bottom:
                        bottomToolsHeight +
                        ((!_isCropMode &&
                                !_isEraserMode &&
                                _hasSelectedTextLayer &&
                                _showTextControls)
                            ? _textStyleBarHeight + 10
                            : 10),
                    child: _EditorModeBadge(
                      label: _localizedEditorLabel(context, activeModeLabel),
                      accent: _activeModeAccent,
                    ),
                  ),
                if (showQuickHint)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom:
                        bottomToolsHeight +
                        ((!_isCropMode &&
                                !_isEraserMode &&
                                _hasSelectedTextLayer &&
                                _showTextControls)
                            ? _textStyleBarHeight + 12
                            : 12),
                    child: _EditorQuickHint(onDismiss: _dismissJoyHint),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RepaintBoundary(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      reverseDuration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                      child: _isCropMode
                          ? KeyedSubtree(
                              key: const ValueKey<String>('crop-tools'),
                              child: _CropBottomToolsBar(
                                height: bottomToolsHeight,
                                onBack: _discardCropSession,
                                onReset: _resetCropSession,
                                onApply: _applyCropSession,
                                isApplying: _isCropApplying,
                                selectedAspectRatio: _cropSessionAspectRatio,
                                onAspectRatioChanged: _setCropAspectRatio,
                              ),
                            )
                          : _isEraserMode
                          ? KeyedSubtree(
                              key: const ValueKey<String>('eraser-tools'),
                              child: _EraserBottomToolsBar(
                                height: bottomToolsHeight,
                                mode: _eraserMode,
                                brushSize: _eraserBrushSize,
                                hardness: _eraserBrushHardness,
                                strength: _eraserBrushStrength,
                                activeControl: _activeEraserControl,
                                isApplying: _isEraserApplying,
                                isInitializing: _isEraserInitializing,
                                canUndo: _eraserController.canUndo,
                                canRedo: _eraserController.canRedo,
                                onModeChanged: (_EraserMode mode) {
                                  setState(() {
                                    _eraserMode = mode;
                                    _eraserController.setMode(
                                      mode == _EraserMode.restore
                                          ? EraserBlendMode.restore
                                          : EraserBlendMode.erase,
                                    );
                                  });
                                },
                                onBrushSizeChanged: (value) {
                                  setState(() {
                                    _eraserBrushSize = value;
                                    _eraserController.updateSettings(
                                      size: value,
                                    );
                                  });
                                },
                                onHardnessChanged: (value) {
                                  setState(() {
                                    _eraserBrushHardness = value;
                                    _eraserController.updateSettings(
                                      hardness: value,
                                    );
                                  });
                                },
                                onStrengthChanged: (value) {
                                  setState(() {
                                    _eraserBrushStrength = value;
                                    _eraserController.updateSettings(
                                      strength: value,
                                    );
                                  });
                                },
                                onActiveControlChanged: (control) {
                                  setState(() {
                                    _activeEraserControl = control;
                                  });
                                },
                                onUndo: () {
                                  setState(() {
                                    _eraserController.undo();
                                  });
                                  unawaited(_rebuildEraserPreviewFromCurrentState());
                                },
                                onRedo: () {
                                  setState(() {
                                    _eraserController.redo();
                                  });
                                  unawaited(_rebuildEraserPreviewFromCurrentState());
                                },
                                onBack: _discardEraserSession,
                                onReset: _resetEraserSession,
                                onApply: _applyEraserSession,
                              ),
                            )
                          : _isAdjustMode
                          ? KeyedSubtree(
                              key: const ValueKey<String>('adjust-tools'),
                              child: _AdjustBottomToolsBar(
                                height: bottomToolsHeight,
                                sessionListenable: _adjustSessionNotifier,
                                onSessionChanged: _updateAdjustSessionState,
                                onBack: _discardAdjustSession,
                                onReset: _resetAdjustSession,
                                onApply: _applyAdjustSession,
                              ),
                            )
                          : _hasSelectedTextLayer
                          ? KeyedSubtree(
                              key: const ValueKey<String>('text-tools'),
                              child: _TextBottomToolsBar(
                                height: bottomToolsHeight,
                                showOptionsSelected: _showTextControls,
                                onEditTap: _openTextEditSheet,
                                onFontsTap: _openFontPickerScreen,
                                onToggleOptionsTap: () {
                                  setState(() {
                                    _showTextControls = !_showTextControls;
                                  });
                                },
                              ),
                            )
                          : KeyedSubtree(
                              key: const ValueKey<String>('main-tools'),
                              child: _BottomToolsBar(
                                height: bottomToolsHeight,
                                onAddPhotoTap: () {
                                  unawaited(
                                    _runMainToolAction('Add Photo', () async {
                                      await _handleAddPhoto();
                                    }),
                                  );
                                },
                                onAddTextTap: () {
                                  unawaited(
                                    _runMainToolAction('Text', () {
                                      _handleTextToolTap();
                                    }),
                                  );
                                },
                                onStickerTap: () {
                                  unawaited(
                                    _runMainToolAction('Stickers', () async {
                                      await _openStickerPanel();
                                    }),
                                  );
                                },
                                onBackgroundTap: () {
                                  unawaited(
                                    _runMainToolAction('Background', () async {
                                      await _openBackgroundPanel();
                                    }),
                                  );
                                },
                                onLayersTap: () {
                                  unawaited(
                                    _runMainToolAction('Layers', () async {
                                      await _openLayersScreen();
                                    }),
                                  );
                                },
                                onAdjustTap: () {
                                  unawaited(
                                    _runMainToolAction('Adjust', () {
                                      _openAdjustPanel();
                                    }),
                                  );
                                },
                                onCropPhotoTap: () {
                                  unawaited(
                                    _runMainToolAction('Crop', () async {
                                      await _handleCropPhotoTap();
                                    }),
                                  );
                                },
                                onEraserTap: () {
                                  unawaited(
                                    _runMainToolAction('Eraser', () async {
                                      await _openEraserPanel();
                                    }),
                                  );
                                },
                                onRemoveBackgroundTap: () {
                                  unawaited(
                                    _runMainToolAction('Remove BG', () async {
                                      await _handleRemoveBackgroundTap();
                                    }),
                                  );
                                },
                                activeToolLabel: _activeMainToolLabel,
                                canAdjustPhoto: _hasSelectedPhotoLayer,
                                canCropPhoto: _hasSelectedPhotoLayer,
                                canEraserPhoto: true,
                                canRemoveBackground:
                                    _hasSelectedPhotoLayer &&
                                    !_isRemovingBackground,
                                isRemovingBackground: _isRemovingBackground,
                                selectedPhotoLayer: _hasSelectedPhotoLayer
                                    ? _selectedLayer
                                    : null,
                                onOpacityChanged: _setSelectedPhotoOpacity,
                                onFlipHorizontalTap:
                                    _toggleSelectedPhotoFlipHorizontal,
                                onFlipVerticalTap:
                                    _toggleSelectedPhotoFlipVertical,
                                onRotateLeftTap: () =>
                                    _rotateSelectedPhoto(-math.pi / 2),
                                onRotateRightTap: () =>
                                    _rotateSelectedPhoto(math.pi / 2),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ValueListenableBuilder<_EditorCommitState?>(
                    valueListenable: _commitStateNotifier,
                    builder:
                        (
                          BuildContext context,
                          _EditorCommitState? commitState,
                          Widget? child,
                        ) {
                          if (commitState == null) {
                            return const SizedBox.shrink();
                          }
                          return AbsorbPointer(
                            absorbing: true,
                            child: _EditorCommitOverlay(
                              label: commitState.label,
                              detail: commitState.detail,
                            ),
                          );
                        },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _isMatrixFinite(Matrix4 matrix) {
  for (final value in matrix.storage) {
    if (!value.isFinite) {
      return false;
    }
  }
  return true;
}

String _photoBytesSignature(Uint8List bytes) {
  final length = bytes.length;
  if (length == 0) {
    return '0_0';
  }
  final sample = bytes.length > 64 ? 64 : bytes.length;
  var hash = 17;
  for (var i = 0; i < sample; i++) {
    hash = 37 * hash + bytes[i];
  }
  return '${bytes.length}_$hash';
}

Widget _buildAdjustedPhoto({
  required Uint8List bytes,
  required String cacheKey,
  required int? cacheWidth,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
}) {
  final presentation = _AdjustedPhotoPresentationCache.resolve(
    bytes: bytes,
    filterKey: cacheKey,
    cacheWidth: cacheWidth,
    brightness: brightness,
    contrast: contrast,
    saturation: saturation,
    blur: blur,
  );
  Widget child = Image(
    image: presentation.provider,
    key: ValueKey<String>(cacheKey),
    fit: BoxFit.contain,
    gaplessPlayback: true,
    filterQuality: FilterQuality.medium,
  );

  if (presentation.blurSigma > 0.01) {
    child = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: presentation.blurSigma,
        sigmaY: presentation.blurSigma,
      ),
      child: child,
    );
  }
  if (presentation.saturationMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(presentation.saturationMatrix!),
      child: child,
    );
  }
  if (presentation.brightnessContrastMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(presentation.brightnessContrastMatrix!),
      child: child,
    );
  }
  return child;
}

// ignore: unused_element
Widget _buildAdjustedRawPhoto({
  required ui.Image image,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
}) {
  Widget child = RawImage(
    image: image,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
  );

  final blurSigma = _mapAdjustBlurToSigma(blur);
  if (blurSigma > 0.01) {
    child = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: child,
    );
  }
  final saturationMatrix = saturation == 1
      ? null
      : _saturationMatrix(saturation);
  if (saturationMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(saturationMatrix),
      child: child,
    );
  }
  final brightnessContrastMatrix =
      brightness.abs() < 0.0001 && (contrast - 1).abs() < 0.0001
      ? null
      : _brightnessContrastMatrix(brightness: brightness, contrast: contrast);
  if (brightnessContrastMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(brightnessContrastMatrix),
      child: child,
    );
  }
  return child;
}

Widget _buildAdjustedEraserLivePhoto({
  required ui.Image baseImage,
  required ui.Image? restoreImage,
  required EraserStrokeChunk? activeStroke,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
}) {
  Widget child = CustomPaint(
    painter: _EraserLivePreviewPainter(
      baseImage: baseImage,
      restoreImage: restoreImage,
      activeStroke: activeStroke,
    ),
    size: Size.infinite,
  );

  final blurSigma = _mapAdjustBlurToSigma(blur);
  if (blurSigma > 0.01) {
    child = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: child,
    );
  }
  final saturationMatrix = saturation == 1 ? null : _saturationMatrix(saturation);
  if (saturationMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(saturationMatrix),
      child: child,
    );
  }
  final brightnessContrastMatrix =
      brightness.abs() < 0.0001 && (contrast - 1).abs() < 0.0001
      ? null
      : _brightnessContrastMatrix(brightness: brightness, contrast: contrast);
  if (brightnessContrastMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(brightnessContrastMatrix),
      child: child,
    );
  }
  return child;
}

class _EraserLivePhotoPreview extends StatelessWidget {
  const _EraserLivePhotoPreview({
    required this.previewImageListenable,
    required this.restoreImageListenable,
    required this.activeStrokeListenable,
    required this.fallbackBytes,
    required this.cacheWidth,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.blur,
  });

  final ValueListenable<ui.Image?> previewImageListenable;
  final ValueListenable<ui.Image?> restoreImageListenable;
  final ValueListenable<EraserStrokeChunk?> activeStrokeListenable;
  final Uint8List fallbackBytes;
  final int? cacheWidth;
  final double brightness;
  final double contrast;
  final double saturation;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ui.Image?>(
      valueListenable: previewImageListenable,
      builder: (BuildContext context, ui.Image? previewImage, Widget? child) {
        if (previewImage == null) {
          return _buildAdjustedPhoto(
            bytes: fallbackBytes,
            cacheKey:
                '${_photoBytesSignature(fallbackBytes)}_'
                '${brightness.toStringAsFixed(3)}_'
                '${contrast.toStringAsFixed(3)}_'
                '${saturation.toStringAsFixed(3)}_'
                '${blur.toStringAsFixed(3)}',
            cacheWidth: cacheWidth,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            blur: blur,
          );
        }
        return ValueListenableBuilder<ui.Image?>(
          valueListenable: restoreImageListenable,
          builder:
              (BuildContext context, ui.Image? restoreImage, Widget? child) {
                return ValueListenableBuilder<EraserStrokeChunk?>(
                  valueListenable: activeStrokeListenable,
                  builder:
                      (
                        BuildContext context,
                        EraserStrokeChunk? activeStroke,
                        Widget? child,
                      ) {
                        return _buildAdjustedEraserLivePhoto(
                          baseImage: previewImage,
                          restoreImage: restoreImage,
                          activeStroke: activeStroke,
                          brightness: brightness,
                          contrast: contrast,
                          saturation: saturation,
                          blur: blur,
                        );
                      },
                );
              },
        );
      },
    );
  }
}

class _EraserLivePreviewPainter extends CustomPainter {
  const _EraserLivePreviewPainter({
    required this.baseImage,
    required this.restoreImage,
    required this.activeStroke,
  });

  final ui.Image baseImage;
  final ui.Image? restoreImage;
  final EraserStrokeChunk? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(baseImage.width.toDouble(), baseImage.height.toDouble()),
      size,
    );
    final destRect = Alignment.center.inscribe(fitted.destination, Offset.zero & size);
    final srcRect = Offset.zero &
        Size(baseImage.width.toDouble(), baseImage.height.toDouble());

    final stroke = activeStroke;
    if (stroke == null || stroke.points.isEmpty) {
      canvas.drawImageRect(baseImage, srcRect, destRect, Paint());
      return;
    }

    if (stroke.mode == EraserBlendMode.erase) {
      canvas.saveLayer(destRect, Paint());
      canvas.drawImageRect(baseImage, srcRect, destRect, Paint());
      for (final point in stroke.points) {
        final center = Offset(
          destRect.left + (point.normalized.dx * destRect.width),
          destRect.top + (point.normalized.dy * destRect.height),
        );
        final radius = point.radiusInImagePixels *
            (destRect.width / math.max(baseImage.width.toDouble(), 1));
        final blurSigma = (radius * (1 - point.hardness.clamp(0.0, 1.0)) * 0.45)
            .clamp(0.0, 18.0);
        final clearPaint = Paint()
          ..blendMode = BlendMode.clear
          ..color = Colors.black.withValues(alpha: point.strength.clamp(0.0, 1.0));
        if (blurSigma > 0.01) {
          clearPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
        }
        canvas.drawCircle(center, radius, clearPaint);
      }
      canvas.restore();
      return;
    }

    canvas.drawImageRect(baseImage, srcRect, destRect, Paint());
    if (restoreImage == null) {
      return;
    }
    final restore = restoreImage!;
    canvas.saveLayer(destRect, Paint());
    canvas.drawImageRect(
      restore,
      Offset.zero & Size(restore.width.toDouble(), restore.height.toDouble()),
      destRect,
      Paint(),
    );
    for (final point in stroke.points) {
      final center = Offset(
        destRect.left + (point.normalized.dx * destRect.width),
        destRect.top + (point.normalized.dy * destRect.height),
      );
      final radius = point.radiusInImagePixels *
          (destRect.width / math.max(baseImage.width.toDouble(), 1));
      final blurSigma = (radius * (1 - point.hardness.clamp(0.0, 1.0)) * 0.45)
          .clamp(0.0, 18.0);
      final maskPaint = Paint()
        ..blendMode = BlendMode.dstIn
        ..color = Colors.white.withValues(alpha: point.strength.clamp(0.0, 1.0));
      if (blurSigma > 0.01) {
        maskPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
      }
      canvas.drawCircle(center, radius, maskPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EraserLivePreviewPainter oldDelegate) {
    return oldDelegate.baseImage != baseImage ||
        oldDelegate.restoreImage != restoreImage ||
        oldDelegate.activeStroke != activeStroke;
  }
}

double _mapAdjustBlurToSigma(double blur) {
  final normalized = (blur / 10).clamp(0.0, 1.0);
  final eased = math.pow(normalized, 1.65).toDouble();
  return (eased * 24).clamp(0.0, 24.0);
}

List<double> _brightnessContrastMatrix({
  required double brightness,
  required double contrast,
}) {
  final clampedContrast = contrast.clamp(0.4, 2.2);
  final clampedBrightness = brightness.clamp(-1.0, 1.0);
  final bias = (clampedBrightness * 255) + ((1 - clampedContrast) * 128);
  return <double>[
    clampedContrast,
    0,
    0,
    0,
    bias,
    0,
    clampedContrast,
    0,
    0,
    bias,
    0,
    0,
    clampedContrast,
    0,
    bias,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _saturationMatrix(double saturation) {
  final s = saturation.clamp(0.0, 2.5);
  const rw = 0.3086;
  const gw = 0.6094;
  const bw = 0.0820;
  final inv = 1 - s;
  final r = inv * rw;
  final g = inv * gw;
  final b = inv * bw;
  return <double>[
    r + s,
    g,
    b,
    0,
    0,
    r,
    g + s,
    b,
    0,
    0,
    r,
    g,
    b + s,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

double _normalizeAngle(double angle) {
  var normalized = angle % (2 * math.pi);
  if (normalized < 0) {
    normalized += 2 * math.pi;
  }
  return normalized;
}

double _shortestAngleDelta({required double from, required double to}) {
  var delta = to - from;
  while (delta > math.pi) {
    delta -= 2 * math.pi;
  }
  while (delta < -math.pi) {
    delta += 2 * math.pi;
  }
  return delta;
}

double _matrixRotationZ(Matrix4 matrix) {
  final m = matrix.storage;
  return math.atan2(m[1], m[0]);
}

double _softSnapRotation(double angle) {
  final normalized = _normalizeAngle(angle);
  const targets = <double>[
    0,
    math.pi / 2,
    math.pi,
    3 * math.pi / 2,
    2 * math.pi,
  ];

  var nearest = targets.first;
  var smallestDelta = double.infinity;
  for (final target in targets) {
    final delta = (normalized - target).abs();
    if (delta < smallestDelta) {
      smallestDelta = delta;
      nearest = target;
    }
  }

  if (smallestDelta >= _ImageEditorScreenState._rotationSnapThresholdRadians) {
    return angle;
  }

  final strength =
      1 -
      (smallestDelta / _ImageEditorScreenState._rotationSnapThresholdRadians);
  final snappedNormalized =
      normalized + ((nearest - normalized) * strength.clamp(0.0, 1.0));
  return angle + (snappedNormalized - normalized);
}

Uint8List _optimizeEditorPhotoBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }

  const targetMaxDimension = 1920;
  final longest = math.max(decoded.width, decoded.height);
  if (longest <= targetMaxDimension) {
    return bytes;
  }

  final scale = targetMaxDimension / longest;
  final width = math.max(320, (decoded.width * scale).round());
  final height = math.max(320, (decoded.height * scale).round());
  final resized = img.copyResize(decoded, width: width, height: height);
  if (resized.hasAlpha) {
    return Uint8List.fromList(img.encodePng(resized));
  }
  return Uint8List.fromList(img.encodeJpg(resized, quality: 92));
}

_OptimizedPhotoPayload _optimizeEditorPhotoPayload(Uint8List bytes) {
  final optimizedBytes = _optimizeEditorPhotoBytes(bytes);
  final decoded = img.decodeImage(optimizedBytes);
  final aspectRatio = decoded != null && decoded.height > 0
      ? decoded.width / decoded.height
      : null;
  return _OptimizedPhotoPayload(
    bytes: optimizedBytes,
    aspectRatio: aspectRatio,
  );
}

double? _extractImageAspectRatio(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.height == 0) {
    return null;
  }
  return decoded.width / decoded.height;
}

Map<String, dynamic> _prepareCropCommitPayload(Uint8List pngBytes) {
  final detachedBytes = Uint8List.fromList(pngBytes);
  return <String, dynamic>{
    'bytes': detachedBytes,
    'aspectRatio': _extractImageAspectRatio(detachedBytes),
  };
}

class _CanvasWorkspace extends StatelessWidget {
  const _CanvasWorkspace({
    required this.layers,
    required this.selectedLayerId,
    required this.canvasBackgroundColor,
    required this.canvasBackgroundGradientIndex,
    required this.stageBackgroundImageBytes,
    required this.canvasSize,
    required this.pageAspectRatio,
    required this.hideAutoPageFrame,
    required this.topInset,
    required this.bottomInset,
    required this.transformationController,
    required this.onSelectedLayerInteractionStart,
    required this.onSelectedLayerScaleUpdate,
    required this.onLayerSelected,
    required this.onSelectedLayerInteractionEnd,
    required this.onSelectedTransformHandlePointerDown,
    required this.onSelectedStickerHandleStart,
    required this.onSelectedStickerHandleUpdate,
    required this.onSelectedStickerHandleEnd,
    required this.onSelectedLayerDoubleTap,
    required this.onSelectedTextDoubleTap,
    required this.onSelectedTextPointerDown,
    required this.onSelectedTextPointerMove,
    required this.onSelectedTextPointerCancel,
    required this.onCanvasTapDown,
    required this.onCanvasTap,
    required this.showCanvasBackground,
    required this.photoBrightnessForLayer,
    required this.photoContrastForLayer,
    required this.photoSaturationForLayer,
    required this.photoBlurForLayer,
    required this.showSelectionDecorations,
    required this.showPageFramePreview,
    required this.snapGuideListenable,
    required this.snapGuidesEnabled,
    required this.selectedPhotoRenderListenable,
    required this.eraserSessionLayerId,
    required this.eraserPreviewImageListenable,
    required this.eraserRestorePreviewImageListenable,
    required this.eraserActiveStrokeListenable,
    required this.eraserPreviewBaseBytes,
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final Color canvasBackgroundColor;
  final int canvasBackgroundGradientIndex;
  final Uint8List? stageBackgroundImageBytes;
  final Size canvasSize;
  final double? pageAspectRatio;
  final bool hideAutoPageFrame;
  final double topInset;
  final double bottomInset;
  final TransformationController transformationController;
  final ValueChanged<ScaleStartDetails> onSelectedLayerInteractionStart;
  final ValueChanged<ScaleUpdateDetails> onSelectedLayerScaleUpdate;
  final ValueChanged<String> onLayerSelected;
  final VoidCallback onSelectedLayerInteractionEnd;
  final VoidCallback onSelectedTransformHandlePointerDown;
  final ValueChanged<DragStartDetails> onSelectedStickerHandleStart;
  final ValueChanged<DragUpdateDetails> onSelectedStickerHandleUpdate;
  final VoidCallback onSelectedStickerHandleEnd;
  final VoidCallback onSelectedLayerDoubleTap;
  final VoidCallback onSelectedTextDoubleTap;
  final ValueChanged<PointerDownEvent> onSelectedTextPointerDown;
  final ValueChanged<PointerMoveEvent> onSelectedTextPointerMove;
  final VoidCallback onSelectedTextPointerCancel;
  final void Function(Offset localPosition, Rect pageRect, Size pageSize)
  onCanvasTapDown;
  final VoidCallback onCanvasTap;
  final bool showCanvasBackground;
  final double Function(_CanvasLayer layer) photoBrightnessForLayer;
  final double Function(_CanvasLayer layer) photoContrastForLayer;
  final double Function(_CanvasLayer layer) photoSaturationForLayer;
  final double Function(_CanvasLayer layer) photoBlurForLayer;
  final bool showSelectionDecorations;
  final bool showPageFramePreview;
  final ValueListenable<_SnapGuideState> snapGuideListenable;
  final bool snapGuidesEnabled;
  final ValueListenable<_SelectedPhotoRenderState?>
  selectedPhotoRenderListenable;
  final String? eraserSessionLayerId;
  final ValueListenable<ui.Image?> eraserPreviewImageListenable;
  final ValueListenable<ui.Image?> eraserRestorePreviewImageListenable;
  final ValueListenable<EraserStrokeChunk?> eraserActiveStrokeListenable;
  final Uint8List? eraserPreviewBaseBytes;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final unselectedPhotoCacheWidth =
        (canvasSize.width * devicePixelRatio * 1.5).round().clamp(720, 1600);
    final workspaceHeight = math.max(
      0.0,
      canvasSize.height - topInset - bottomInset,
    );
    final workspaceSize = Size(canvasSize.width, workspaceHeight);
    final hasPageSelection = pageAspectRatio != null;
    final showPageFrame =
        hasPageSelection && !hideAutoPageFrame && showPageFramePreview;
    final pageSize = hasPageSelection
        ? _fitPageSize(
            workspaceSize: workspaceSize,
            aspectRatio: pageAspectRatio!,
          )
        : workspaceSize;
    final pageRect = Rect.fromCenter(
      center: Offset(canvasSize.width / 2, topInset + (workspaceHeight / 2)),
      width: pageSize.width,
      height: pageSize.height,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: showCanvasBackground
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFF9FAFF), Color(0xFFF2F6FB)],
              )
            : null,
        color: showCanvasBackground ? null : Colors.transparent,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) =>
            onCanvasTapDown(details.localPosition, pageRect, pageSize),
        child: SizedBox.expand(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                  child: ClipRect(
                    child: Stack(
                      children: <Widget>[
                        Center(
                          child: RepaintBoundary(
                            child: Container(
                              width: pageSize.width,
                              height: pageSize.height,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                gradient:
                                    stageBackgroundImageBytes == null &&
                                        canvasBackgroundGradientIndex >= 0 &&
                                        canvasBackgroundGradientIndex <
                                            editorBackgroundGradients.length &&
                                        showCanvasBackground
                                    ? LinearGradient(
                                        colors:
                                            editorBackgroundGradients[canvasBackgroundGradientIndex],
                                      )
                                    : null,
                                color: showCanvasBackground
                                    ? canvasBackgroundColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                                border: showPageFrame && showCanvasBackground
                                    ? Border.all(
                                        color: const Color(0x331E293B),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child:
                                  stageBackgroundImageBytes != null &&
                                      showCanvasBackground
                                  ? SizedBox.expand(
                                      child: Image.memory(
                                        stageBackgroundImageBytes!,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (layers.isNotEmpty)
                          ...layers.where((layer) => !layer.isHidden).map((
                            layer,
                          ) {
                            final isSelected = layer.id == selectedLayerId;
                            final layerSize = _workspaceLayerVisualSize(
                              layer,
                              pageSize,
                            );
                            final photoSize = layer.isPhoto
                                ? _fitPhotoLayerSize(
                                    pageSize: pageSize,
                                    photoAspectRatio: layer.photoAspectRatio,
                                  )
                                : Size.zero;
                            final transformLayerSize = layer.isPhoto
                                ? photoSize
                                : layerSize;
                            final photoCacheWidth = layer.isPhoto
                                ? (photoSize.width * devicePixelRatio)
                                      .round()
                                      .clamp(512, 2048)
                                : null;
                            final effectiveBrightness = layer.isPhoto
                                ? photoBrightnessForLayer(layer)
                                : 0.0;
                            final effectiveContrast = layer.isPhoto
                                ? photoContrastForLayer(layer)
                                : 1.0;
                            final effectiveSaturation = layer.isPhoto
                                ? photoSaturationForLayer(layer)
                                : 1.0;
                            final effectiveBlur = layer.isPhoto
                                ? photoBlurForLayer(layer)
                                : 0.0;
                            final isEraserSessionPhoto =
                                layer.isPhoto &&
                                isSelected &&
                                eraserSessionLayerId == layer.id;
                            final layerChild = layer.isPhoto
                                ? SizedBox(
                                    width: photoSize.width,
                                    height: photoSize.height,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        if (isEraserSessionPhoto)
                                          Opacity(
                                            opacity: layer.photoOpacity.clamp(
                                              0.1,
                                              1,
                                            ),
                                            child: Transform(
                                              alignment: Alignment.center,
                                              transform:
                                                  Matrix4.diagonal3Values(
                                                    layer.flipPhotoHorizontally
                                                        ? -1
                                                        : 1,
                                                    layer.flipPhotoVertically
                                                        ? -1
                                                        : 1,
                                                    1,
                                                  ),
                                              child: _EraserLivePhotoPreview(
                                                previewImageListenable:
                                                    eraserPreviewImageListenable,
                                                restoreImageListenable:
                                                    eraserRestorePreviewImageListenable,
                                                activeStrokeListenable:
                                                    eraserActiveStrokeListenable,
                                                fallbackBytes:
                                                    eraserPreviewBaseBytes ??
                                                    layer.bytes!,
                                                cacheWidth: photoCacheWidth,
                                                brightness: effectiveBrightness,
                                                contrast: effectiveContrast,
                                                saturation:
                                                    effectiveSaturation,
                                                blur: effectiveBlur,
                                              ),
                                            ),
                                          )
                                        else if (isSelected)
                                          ValueListenableBuilder<
                                            _SelectedPhotoRenderState?
                                          >(
                                            valueListenable:
                                                selectedPhotoRenderListenable,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  _SelectedPhotoRenderState?
                                                  renderState,
                                                  Widget? child,
                                                ) {
                                                  final resolvedState =
                                                      renderState != null &&
                                                          renderState.layerId ==
                                                              layer.id
                                                      ? renderState
                                                      : _SelectedPhotoRenderState(
                                                          layerId: layer.id,
                                                          bytes: layer.bytes!,
                                                          opacity: layer
                                                              .photoOpacity
                                                              .clamp(0.1, 1),
                                                          flipHorizontally: layer
                                                              .flipPhotoHorizontally,
                                                          flipVertically: layer
                                                              .flipPhotoVertically,
                                                          brightness:
                                                              effectiveBrightness,
                                                          contrast:
                                                              effectiveContrast,
                                                          saturation:
                                                              effectiveSaturation,
                                                          blur: effectiveBlur,
                                                        );
                                                  return Opacity(
                                                    opacity: resolvedState
                                                        .opacity
                                                        .clamp(0.1, 1),
                                                    child: Transform(
                                                      alignment:
                                                          Alignment.center,
                                                      transform: Matrix4.diagonal3Values(
                                                        resolvedState
                                                                .flipHorizontally
                                                            ? -1
                                                            : 1,
                                                        resolvedState
                                                                .flipVertically
                                                            ? -1
                                                            : 1,
                                                        1,
                                                      ),
                                                      child:
                                                          _buildAdjustedPhoto(
                                                            bytes: resolvedState
                                                                .bytes,
                                                            cacheKey:
                                                                resolvedState
                                                                    .cacheKey,
                                                            cacheWidth:
                                                                photoCacheWidth,
                                                            brightness:
                                                                resolvedState
                                                                    .brightness,
                                                            contrast:
                                                                resolvedState
                                                                    .contrast,
                                                            saturation:
                                                                resolvedState
                                                                    .saturation,
                                                            blur: resolvedState
                                                                .blur,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          )
                                        else
                                          Opacity(
                                            opacity: layer.photoOpacity.clamp(
                                              0.1,
                                              1,
                                            ),
                                            child: Transform(
                                              alignment: Alignment.center,
                                              transform:
                                                  Matrix4.diagonal3Values(
                                                    layer.flipPhotoHorizontally
                                                        ? -1
                                                        : 1,
                                                    layer.flipPhotoVertically
                                                        ? -1
                                                        : 1,
                                                    1,
                                                  ),
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 260,
                                                ),
                                                switchInCurve:
                                                    Curves.easeOutCubic,
                                                switchOutCurve:
                                                    Curves.easeInCubic,
                                                transitionBuilder:
                                                    (child, animation) =>
                                                        FadeTransition(
                                                          opacity: animation,
                                                          child: child,
                                                        ),
                                                child: _buildAdjustedPhoto(
                                                  bytes: layer.bytes!,
                                                  cacheKey:
                                                      '${_photoBytesSignature(layer.bytes!)}_'
                                                      '${effectiveBrightness.toStringAsFixed(3)}_'
                                                      '${effectiveContrast.toStringAsFixed(3)}_'
                                                      '${effectiveSaturation.toStringAsFixed(3)}_'
                                                      '${effectiveBlur.toStringAsFixed(3)}',
                                                  cacheWidth: isSelected
                                                      ? photoCacheWidth
                                                      : photoCacheWidth ??
                                                            unselectedPhotoCacheWidth,
                                                  brightness:
                                                      effectiveBrightness,
                                                  contrast: effectiveContrast,
                                                  saturation:
                                                      effectiveSaturation,
                                                  blur: effectiveBlur,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : layer.isText
                                ? _CanvasTextLayerView(
                                    text: layer.text ?? 'Text',
                                    textColor: layer.textColor,
                                    textAlign: layer.textAlign,
                                    fontFamily: layer.fontFamily,
                                    textLineHeight: layer.textLineHeight,
                                    textLetterSpacing: layer.textLetterSpacing,
                                    textShadowOpacity: layer.textShadowOpacity,
                                    textShadowBlur: layer.textShadowBlur,
                                    textShadowOffsetY: layer.textShadowOffsetY,
                                    isTextBold: layer.isTextBold,
                                    isTextItalic: layer.isTextItalic,
                                    isTextUnderline: layer.isTextUnderline,
                                    textStrokeColor: layer.textStrokeColor,
                                    textStrokeWidth: layer.textStrokeWidth,
                                    textBackgroundColor:
                                        layer.textBackgroundColor,
                                    textBackgroundOpacity:
                                        layer.textBackgroundOpacity,
                                    textBackgroundRadius:
                                        layer.textBackgroundRadius,
                                    textGradient:
                                        layer.textGradientIndex >= 0 &&
                                            layer.textGradientIndex <
                                                _ImageEditorScreenState
                                                    ._textGradients
                                                    .length
                                        ? _ImageEditorScreenState
                                              ._textGradients[layer
                                              .textGradientIndex]
                                        : null,
                                    fontSize: layer.fontSize,
                                  )
                                : Text(
                                    layer.sticker ?? '?',
                                    style: TextStyle(fontSize: layer.fontSize),
                                  );
                            final stickerAsset =
                                _ImageEditorScreenState._isImageLikeSticker(
                                  layer.sticker,
                                );
                            final stickerOrTextChild =
                                layer.isSticker && stickerAsset
                                ? SizedBox(
                                    width: layerSize.width,
                                    height: layerSize.height,
                                    child:
                                        _ImageEditorScreenState._buildStickerVisual(
                                          layer.sticker,
                                          fontSize: layer.fontSize,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.medium,
                                        ),
                                  )
                                : layerChild;

                            final decoratedChild =
                                showSelectionDecorations && isSelected
                                ? DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(
                                          0xFF2563EB,
                                        ).withValues(alpha: 0.55),
                                        width: 1.25,
                                      ),
                                      borderRadius: layer.isText
                                          ? BorderRadius.circular(10)
                                          : null,
                                    ),
                                    child: Padding(
                                      padding: layer.isText
                                          ? const EdgeInsets.fromLTRB(
                                              12,
                                              14,
                                              12,
                                              10,
                                            )
                                          : EdgeInsets.zero,
                                      child: RepaintBoundary(
                                        child: stickerOrTextChild,
                                      ),
                                    ),
                                  )
                                : RepaintBoundary(child: stickerOrTextChild);
                            final effectiveTextChild = layer.isText
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: decoratedChild,
                                  )
                                : decoratedChild;

                            final child = isSelected
                                ? (layer.isPhoto || layer.isSticker)
                                      ? SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: Center(
                                            child: ValueListenableBuilder<Matrix4>(
                                              valueListenable:
                                                  transformationController,
                                              builder:
                                                  (
                                                    BuildContext context,
                                                    Matrix4 matrix,
                                                    Widget? child,
                                                  ) {
                                                    return Transform(
                                                      alignment:
                                                          Alignment.center,
                                                      transform: matrix,
                                                      child: child,
                                                    );
                                                  },
                                              child: SizedBox(
                                                width:
                                                    transformLayerSize.width +
                                                    64,
                                                height:
                                                    transformLayerSize.height +
                                                    64,
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: <Widget>[
                                                    Center(
                                                      child: SizedBox(
                                                        width:
                                                            transformLayerSize
                                                                .width,
                                                        height:
                                                            transformLayerSize
                                                                .height,
                                                        child: GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .translucent,
                                                          onDoubleTap:
                                                              onSelectedLayerDoubleTap,
                                                          onScaleStart:
                                                              onSelectedLayerInteractionStart,
                                                          onScaleUpdate:
                                                              onSelectedLayerScaleUpdate,
                                                          onScaleEnd: (_) =>
                                                              onSelectedLayerInteractionEnd(),
                                                          child: decoratedChild,
                                                        ),
                                                      ),
                                                    ),
                                                    if (showSelectionDecorations &&
                                                        (layer.isSticker ||
                                                            layer.isPhoto))
                                                      Positioned(
                                                        right: 0,
                                                        bottom: 0,
                                                        child: _StickerResizeRotateHandle(
                                                          onPointerDown:
                                                              onSelectedTransformHandlePointerDown,
                                                          onPanStart:
                                                              onSelectedStickerHandleStart,
                                                          onPanUpdate:
                                                              onSelectedStickerHandleUpdate,
                                                          onPanEnd: (_) =>
                                                              onSelectedStickerHandleEnd(),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : layer.isText
                                      ? SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: Center(
                                            child: ValueListenableBuilder<Matrix4>(
                                              valueListenable:
                                                  transformationController,
                                              builder:
                                                  (
                                                    BuildContext context,
                                                    Matrix4 matrix,
                                                    Widget? child,
                                                  ) {
                                                    return Transform(
                                                      alignment:
                                                          Alignment.center,
                                                      transform: matrix,
                                                      child: child,
                                                    );
                                                  },
                                              child: Listener(
                                                onPointerDown:
                                                    onSelectedTextPointerDown,
                                                onPointerMove:
                                                    onSelectedTextPointerMove,
                                                onPointerUp: (_) =>
                                                    onSelectedTextPointerCancel(),
                                                onPointerCancel: (_) =>
                                                    onSelectedTextPointerCancel(),
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onDoubleTap:
                                                      onSelectedTextDoubleTap,
                                                  onScaleStart:
                                                      onSelectedLayerInteractionStart,
                                                  onScaleUpdate:
                                                      onSelectedLayerScaleUpdate,
                                                  onScaleEnd: (_) =>
                                                      onSelectedLayerInteractionEnd(),
                                                  child: effectiveTextChild,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onDoubleTap:
                                                onSelectedLayerDoubleTap,
                                            child: InteractiveViewer(
                                              transformationController:
                                                  transformationController,
                                              minScale: 0.2,
                                              maxScale: 8.0,
                                              panEnabled: true,
                                              scaleEnabled: true,
                                              constrained: false,
                                              clipBehavior: Clip.none,
                                              boundaryMargin:
                                                  const EdgeInsets.all(2400),
                                              onInteractionStart:
                                                  onSelectedLayerInteractionStart,
                                              onInteractionUpdate:
                                                  onSelectedLayerScaleUpdate,
                                              onInteractionEnd: (_) =>
                                                  onSelectedLayerInteractionEnd(),
                                              child: Center(
                                                child: decoratedChild,
                                              ),
                                            ),
                                          ),
                                        )
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: layer.transform,
                                    child: layer.isSticker
                                        ? stickerOrTextChild
                                        : layerChild,
                                  );

                            return Center(
                              child: isSelected
                                  ? child
                                  : layer.isText
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: child,
                                    )
                                  : child,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: topInset,
                      bottom: bottomInset,
                    ),
                    child: ValueListenableBuilder<_SnapGuideState>(
                      valueListenable: snapGuideListenable,
                      builder:
                          (
                            BuildContext context,
                            _SnapGuideState snapGuides,
                            Widget? child,
                          ) {
                            return RepaintBoundary(
                              child: CustomPaint(
                                painter: _SnapGuidesPainter(
                                  showVerticalGuide:
                                      snapGuidesEnabled &&
                                      snapGuides.showVerticalGuide,
                                  showHorizontalGuide:
                                      snapGuidesEnabled &&
                                      snapGuides.showHorizontalGuide,
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    /*
    final background = canvasBackgroundGradientIndex >= 0 &&
            canvasBackgroundGradientIndex <
                editorBackgroundGradients.length
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: editorBackgroundGradients[canvasBackgroundGradientIndex],
            ),
          )
        : BoxDecoration(color: canvasBackgroundColor);

    return DecoratedBox(
      decoration: background,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onCanvasTap,
        child: SizedBox.expand(
          child: Stack(
            children: <Widget>[
          if (layers.isEmpty)
            Center(
              child: Text(
                'Canvas Area',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
            )
          else
            ...layers.map((layer) {
              final isSelected = layer.id == selectedLayerId;
              final layerChild = layer.isPhoto
                  ? Image.memory(
                      layer.bytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                      cacheWidth: isSelected ? null : unselectedPhotoCacheWidth,
                    )
                  : layer.isText
                      ? _CanvasTextLayerView(
                      text: layer.text ?? 'Text',
                      textColor: layer.textColor,
                      textAlign: layer.textAlign,
                      fontFamily: layer.fontFamily,
                      textGradient: layer.textGradientIndex >= 0 &&
                              layer.textGradientIndex <
                                  _ImageEditorScreenState._textGradients.length
                          ? _ImageEditorScreenState
                              ._textGradients[layer.textGradientIndex]
                          : null,
                      fontSize: layer.fontSize,
                    )
                      : Text(
                          layer.sticker ?? '⭐',
                          style: TextStyle(fontSize: layer.fontSize),
                        );

              final child = isSelected
                  ? InteractiveViewer(
                      transformationController: transformationController,
                      minScale: 1,
                      maxScale: layer.isPhoto || layer.isSticker ? 5 : 1,
                      scaleEnabled: layer.isPhoto || layer.isSticker,
                      constrained: false,
                      clipBehavior: Clip.none,
                      boundaryMargin: const EdgeInsets.all(240),
                      onInteractionUpdate: (_) => onSelectedLayerInteractionUpdate(),
                      onInteractionEnd: (_) => onSelectedLayerInteractionEnd(),
                      child: showSelectionDecorations
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                              ),
                              child: layerChild,
                            )
                          : layerChild,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: layer.transform,
                      child: layerChild,
                    );

              return Center(
                child: isSelected
                    ? child
                    : GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTap: () => onLayerSelected(layer.id),
                        child: child,
                      ),
              );
            }),
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                child: CustomPaint(
                  painter: _SnapGuidesPainter(
                    showVerticalGuide: showVerticalSnapGuide,
                    showHorizontalGuide: showHorizontalSnapGuide,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
*/
  }
}

Size _fitPageSize({required Size workspaceSize, required double aspectRatio}) {
  if (workspaceSize.width <= 0 || workspaceSize.height <= 0) {
    return Size.zero;
  }

  final safeAspect = aspectRatio <= 0 ? 1.0 : aspectRatio;
  final maxWidth = workspaceSize.width;
  final maxHeight = workspaceSize.height;

  var width = maxWidth;
  var height = width / safeAspect;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * safeAspect;
  }

  return Size(width, height);
}

Size _fitPhotoLayerSize({
  required Size pageSize,
  required double? photoAspectRatio,
}) {
  if (pageSize.width <= 0 || pageSize.height <= 0) {
    return Size.zero;
  }

  final ratio = (photoAspectRatio != null && photoAspectRatio > 0)
      ? photoAspectRatio
      : (pageSize.width / pageSize.height);

  final maxWidth = pageSize.width * 0.88;
  final maxHeight = pageSize.height * 0.88;
  var width = maxWidth;
  var height = width / ratio;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * ratio;
  }
  return Size(width, height);
}

Size _workspaceLayerVisualSize(_CanvasLayer layer, Size pageSize) {
  if (layer.isPhoto) {
    return _fitPhotoLayerSize(
      pageSize: pageSize,
      photoAspectRatio: layer.photoAspectRatio,
    );
  }
  if (layer.isText) {
    final painter = TextPainter(
      text: TextSpan(
        text: layer.text ?? 'Text',
        style: TextStyle(
          fontFamily: layer.fontFamily,
          fontSize: layer.fontSize,
          height: layer.textLineHeight,
          letterSpacing: layer.textLetterSpacing,
          fontWeight: layer.isTextBold ? FontWeight.w800 : FontWeight.w500,
          fontStyle: layer.isTextItalic ? FontStyle.italic : FontStyle.normal,
          decoration: layer.isTextUnderline
              ? TextDecoration.underline
              : TextDecoration.none,
          color: layer.textColor,
        ),
      ),
      textAlign: layer.textAlign,
      textDirection: TextDirection.ltr,
    )..layout();
    final hasBackground = layer.textBackgroundOpacity > 0.001;
    return hasBackground
        ? Size(painter.size.width + 24, painter.size.height + 16)
        : painter.size;
  }
  final sticker = layer.sticker;
  if (_ImageEditorScreenState._isImageLikeSticker(sticker)) {
    return Size.square(layer.fontSize);
  }
  final painter = TextPainter(
    text: TextSpan(
      text: sticker ?? '*',
      style: TextStyle(fontSize: layer.fontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.size;
}

class _StickerResizeRotateHandle extends StatelessWidget {
  const _StickerResizeRotateHandle({
    required this.onPointerDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final VoidCallback onPointerDown;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onPointerDown(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x331E293B),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.rotate_right_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _SnapGuidesPainter extends CustomPainter {
  const _SnapGuidesPainter({
    required this.showVerticalGuide,
    required this.showHorizontalGuide,
  });

  final bool showVerticalGuide;
  final bool showHorizontalGuide;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    if (showVerticalGuide) {
      final x = size.width / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    if (showHorizontalGuide) {
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnapGuidesPainter oldDelegate) {
    return oldDelegate.showVerticalGuide != showVerticalGuide ||
        oldDelegate.showHorizontalGuide != showHorizontalGuide;
  }
}

class _CanvasTextLayerView extends StatelessWidget {
  const _CanvasTextLayerView({
    required this.text,
    required this.textColor,
    required this.textAlign,
    required this.fontSize,
    required this.fontFamily,
    required this.textLineHeight,
    required this.textLetterSpacing,
    required this.textShadowOpacity,
    required this.textShadowBlur,
    required this.textShadowOffsetY,
    required this.isTextBold,
    required this.isTextItalic,
    required this.isTextUnderline,
    required this.textStrokeColor,
    required this.textStrokeWidth,
    required this.textBackgroundColor,
    required this.textBackgroundOpacity,
    required this.textBackgroundRadius,
    this.textGradient,
  });

  final String text;
  final Color textColor;
  final TextAlign textAlign;
  final double fontSize;
  final String fontFamily;
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
  final Color textBackgroundColor;
  final double textBackgroundOpacity;
  final double textBackgroundRadius;
  final List<Color>? textGradient;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontSize: fontSize,
      height: textLineHeight,
      letterSpacing: textLetterSpacing,
      fontWeight: isTextBold ? FontWeight.w700 : FontWeight.w500,
      fontStyle: isTextItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isTextUnderline
          ? TextDecoration.underline
          : TextDecoration.none,
      fontFamily: fontFamily,
      color: textGradient == null ? textColor : Colors.white,
      shadows: textShadowOpacity <= 0.001
          ? null
          : <Shadow>[
              Shadow(
                color: Colors.black.withValues(alpha: textShadowOpacity),
                blurRadius: textShadowBlur,
                offset: Offset(0, textShadowOffsetY),
              ),
            ],
    );

    final strokeText = textStrokeWidth <= 0.001
        ? null
        : Text(
            text,
            textAlign: textAlign,
            style: baseStyle?.copyWith(
              color: null,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = textStrokeWidth
                ..color = textStrokeColor,
            ),
          );

    final fillText = Text(text, textAlign: textAlign, style: baseStyle);

    final textView = textGradient == null
        ? (strokeText == null
              ? fillText
              : Stack(
                  alignment: Alignment.center,
                  children: <Widget>[strokeText, fillText],
                ))
        : ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(colors: textGradient!).createShader(bounds);
            },
            child: strokeText == null
                ? fillText
                : Stack(
                    alignment: Alignment.center,
                    children: <Widget>[strokeText, fillText],
                  ),
          );

    final hasBackground = textBackgroundOpacity > 0.001;
    if (!hasBackground) {
      return textView;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: textBackgroundColor.withValues(alpha: textBackgroundOpacity),
        borderRadius: BorderRadius.circular(textBackgroundRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: textView,
      ),
    );
  }
}

enum _TextToolTab { style, background, effects }

class _TextStyleBar extends StatefulWidget {
  const _TextStyleBar({
    required this.visible,
    required this.selectedLayer,
    required this.colors,
    required this.backgroundColors,
    required this.gradients,
    required this.onEditTap,
    required this.onFontsTap,
    required this.onColorSelected,
    required this.onBackgroundColorSelected,
    required this.onAlignSelected,
    required this.onGradientSelected,
    required this.onFontSizeChanged,
    required this.onFontSizeChangeStart,
    required this.onFontSizeChangeEnd,
    required this.onBackgroundOpacityChanged,
    required this.onBackgroundRadiusChanged,
    required this.onLineHeightChanged,
    required this.onLetterSpacingChanged,
    required this.onShadowOpacityChanged,
    required this.onShadowBlurChanged,
    required this.onShadowOffsetYChanged,
    required this.onBoldToggle,
    required this.onItalicToggle,
    required this.onUnderlineToggle,
    required this.onStrokeColorSelected,
    required this.onStrokeWidthChanged,
  });

  final bool visible;
  final _CanvasLayer? selectedLayer;
  final List<Color> colors;
  final List<Color> backgroundColors;
  final List<List<Color>> gradients;
  final VoidCallback onEditTap;
  final VoidCallback onFontsTap;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<Color> onBackgroundColorSelected;
  final ValueChanged<TextAlign> onAlignSelected;
  final ValueChanged<int> onGradientSelected;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onFontSizeChangeStart;
  final ValueChanged<double> onFontSizeChangeEnd;
  final ValueChanged<double> onBackgroundOpacityChanged;
  final ValueChanged<double> onBackgroundRadiusChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onLetterSpacingChanged;
  final ValueChanged<double> onShadowOpacityChanged;
  final ValueChanged<double> onShadowBlurChanged;
  final ValueChanged<double> onShadowOffsetYChanged;
  final VoidCallback onBoldToggle;
  final VoidCallback onItalicToggle;
  final VoidCallback onUnderlineToggle;
  final ValueChanged<Color> onStrokeColorSelected;
  final ValueChanged<double> onStrokeWidthChanged;

  @override
  State<_TextStyleBar> createState() => _TextStyleBarState();
}

class _TextStyleBarState extends State<_TextStyleBar> {
  _TextToolTab _activeTab = _TextToolTab.style;
  String? _activeSliderId;

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.selectedLayer == null) {
      return const SizedBox.shrink();
    }
    final strings = context.strings;
    final layer = widget.selectedLayer!;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xE60F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _TextQuickActionButton(
                  icon: Icons.edit_rounded,
                  label: strings.localized(telugu: 'ఎడిట్', english: 'Edit'),
                  onTap: widget.onEditTap,
                ),
                const SizedBox(width: 6),
                _TextQuickActionButton(
                  icon: Icons.font_download_rounded,
                  label: strings.localized(telugu: 'ఫాంట్స్', english: 'Fonts'),
                  onTap: widget.onFontsTap,
                ),
                const SizedBox(width: 8),
                _TextTabChip(
                  label: strings.localized(telugu: 'స్టైల్', english: 'Style'),
                  selected: _activeTab == _TextToolTab.style,
                  onTap: () => setState(() {
                    _activeTab = _TextToolTab.style;
                    _activeSliderId = null;
                  }),
                ),
                _TextTabChip(
                  label: strings.localized(
                    telugu: 'బ్యాక్‌గ్రౌండ్',
                    english: 'Background',
                  ),
                  selected: _activeTab == _TextToolTab.background,
                  onTap: () => setState(() {
                    _activeTab = _TextToolTab.background;
                    _activeSliderId = null;
                  }),
                ),
                _TextTabChip(
                  label: strings.localized(
                    telugu: 'ఎఫెక్ట్స్',
                    english: 'Effects',
                  ),
                  selected: _activeTab == _TextToolTab.effects,
                  onTap: () => setState(() {
                    _activeTab = _TextToolTab.effects;
                    _activeSliderId = null;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _activeTab == _TextToolTab.style
                    ? <Widget>[
                        _AlignChip(
                          icon: Icons.format_align_left_rounded,
                          selected: layer.textAlign == TextAlign.left,
                          onTap: () => widget.onAlignSelected(TextAlign.left),
                        ),
                        _AlignChip(
                          icon: Icons.format_align_center_rounded,
                          selected: layer.textAlign == TextAlign.center,
                          onTap: () => widget.onAlignSelected(TextAlign.center),
                        ),
                        _AlignChip(
                          icon: Icons.format_align_right_rounded,
                          selected: layer.textAlign == TextAlign.right,
                          onTap: () => widget.onAlignSelected(TextAlign.right),
                        ),
                        _AlignChip(
                          icon: Icons.format_bold_rounded,
                          selected: layer.isTextBold,
                          onTap: widget.onBoldToggle,
                        ),
                        _AlignChip(
                          icon: Icons.format_italic_rounded,
                          selected: layer.isTextItalic,
                          onTap: widget.onItalicToggle,
                        ),
                        _AlignChip(
                          icon: Icons.format_underline_rounded,
                          selected: layer.isTextUnderline,
                          onTap: widget.onUnderlineToggle,
                        ),
                        const SizedBox(width: 8),
                        _CompactLabeledSlider(
                          sliderId: 'text-size',
                          label: strings.localized(
                            telugu: 'సైజ్',
                            english: 'Size',
                          ),
                          value: layer.fontSize.clamp(18, 96).toDouble(),
                          min: 18,
                          max: 96,
                          width: 148,
                          valueText: layer.fontSize.toStringAsFixed(0),
                          isActive: _activeSliderId == 'text-size',
                          onActivate: () => setState(() {
                            _activeSliderId = 'text-size';
                          }),
                          onChangeStart: widget.onFontSizeChangeStart,
                          onChanged: widget.onFontSizeChanged,
                          onChangeEnd: widget.onFontSizeChangeEnd,
                        ),
                        _CompactLabeledSlider(
                          sliderId: 'line-height',
                          label: strings.localized(
                            telugu: 'లైన్',
                            english: 'Line',
                          ),
                          value: layer.textLineHeight
                              .clamp(0.8, 2.2)
                              .toDouble(),
                          min: 0.8,
                          max: 2.2,
                          width: 136,
                          isActive: _activeSliderId == 'line-height',
                          onActivate: () => setState(() {
                            _activeSliderId = 'line-height';
                          }),
                          onChanged: widget.onLineHeightChanged,
                        ),
                        _CompactLabeledSlider(
                          sliderId: 'letter-spacing',
                          label: strings.localized(
                            telugu: 'లెటర్',
                            english: 'Letter',
                          ),
                          value: layer.textLetterSpacing
                              .clamp(-1, 12)
                              .toDouble(),
                          min: -1,
                          max: 12,
                          width: 144,
                          isActive: _activeSliderId == 'letter-spacing',
                          onActivate: () => setState(() {
                            _activeSliderId = 'letter-spacing';
                          }),
                          onChanged: widget.onLetterSpacingChanged,
                        ),
                        const SizedBox(width: 8),
                        ...List<Widget>.generate(widget.colors.length, (
                          int index,
                        ) {
                          final color = widget.colors[index];
                          final selected =
                              layer.textGradientIndex == -1 &&
                              layer.textColor == color;
                          return _ColorDot(
                            color: color,
                            selected: selected,
                            onTap: () => widget.onColorSelected(color),
                          );
                        }),
                        const SizedBox(width: 6),
                        ...List<Widget>.generate(widget.gradients.length, (
                          int index,
                        ) {
                          return _GradientDot(
                            colors: widget.gradients[index],
                            selected: layer.textGradientIndex == index,
                            onTap: () => widget.onGradientSelected(index),
                          );
                        }),
                      ]
                    : _activeTab == _TextToolTab.background
                    ? <Widget>[
                        _CompactLabeledSlider(
                          sliderId: 'bg-opacity',
                          label: strings.localized(
                            telugu: 'అపాసిటీ',
                            english: 'Opacity',
                          ),
                          value: layer.textBackgroundOpacity
                              .clamp(0, 1)
                              .toDouble(),
                          min: 0,
                          max: 1,
                          width: 150,
                          isActive: _activeSliderId == 'bg-opacity',
                          onActivate: () => setState(() {
                            _activeSliderId = 'bg-opacity';
                          }),
                          onChanged: widget.onBackgroundOpacityChanged,
                        ),
                        _CompactLabeledSlider(
                          sliderId: 'bg-curve',
                          label: strings.localized(
                            telugu: 'కర్వ్',
                            english: 'Curve',
                          ),
                          value: layer.textBackgroundRadius
                              .clamp(0, 40)
                              .toDouble(),
                          min: 0,
                          max: 40,
                          width: 150,
                          isActive: _activeSliderId == 'bg-curve',
                          onActivate: () => setState(() {
                            _activeSliderId = 'bg-curve';
                          }),
                          onChanged: widget.onBackgroundRadiusChanged,
                        ),
                        const SizedBox(width: 8),
                        ...List<Widget>.generate(
                          widget.backgroundColors.length,
                          (int index) {
                            final color = widget.backgroundColors[index];
                            final selected =
                                layer.textBackgroundColor.toARGB32() ==
                                color.toARGB32();
                            return _ColorDot(
                              color: color,
                              selected: selected,
                              onTap: () =>
                                  widget.onBackgroundColorSelected(color),
                            );
                          },
                        ),
                      ]
                    : <Widget>[
                        _CompactLabeledSlider(
                          sliderId: 'stroke-width',
                          label: strings.localized(
                            telugu: 'స్ట్రోక్',
                            english: 'Stroke',
                          ),
                          value: layer.textStrokeWidth.clamp(0, 8).toDouble(),
                          min: 0,
                          max: 8,
                          width: 144,
                          isActive: _activeSliderId == 'stroke-width',
                          onActivate: () => setState(() {
                            _activeSliderId = 'stroke-width';
                          }),
                          onChanged: widget.onStrokeWidthChanged,
                        ),
                        _CompactLabeledSlider(
                          sliderId: 'shadow-opacity',
                          label: strings.localized(
                            telugu: 'షాడో',
                            english: 'Shadow',
                          ),
                          value: layer.textShadowOpacity.clamp(0, 1).toDouble(),
                          min: 0,
                          max: 1,
                          width: 146,
                          isActive: _activeSliderId == 'shadow-opacity',
                          onActivate: () => setState(() {
                            _activeSliderId = 'shadow-opacity';
                          }),
                          onChanged: widget.onShadowOpacityChanged,
                        ),
                        _CompactLabeledSlider(
                          sliderId: 'shadow-blur',
                          label: strings.localized(
                            telugu: 'బ్లర్',
                            english: 'Blur',
                          ),
                          value: layer.textShadowBlur.clamp(0, 24).toDouble(),
                          min: 0,
                          max: 24,
                          width: 136,
                          isActive: _activeSliderId == 'shadow-blur',
                          onActivate: () => setState(() {
                            _activeSliderId = 'shadow-blur';
                          }),
                          onChanged: widget.onShadowBlurChanged,
                        ),
                        _CompactLabeledSlider(
                          sliderId: 'shadow-offset',
                          label: strings.localized(
                            telugu: 'ఆఫ్‌సెట్',
                            english: 'Offset',
                          ),
                          value: layer.textShadowOffsetY
                              .clamp(0, 20)
                              .toDouble(),
                          min: 0,
                          max: 20,
                          width: 144,
                          isActive: _activeSliderId == 'shadow-offset',
                          onActivate: () => setState(() {
                            _activeSliderId = 'shadow-offset';
                          }),
                          onChanged: widget.onShadowOffsetYChanged,
                        ),
                        const SizedBox(width: 8),
                        ...List<Widget>.generate(widget.colors.length, (
                          int index,
                        ) {
                          final color = widget.colors[index];
                          final selected =
                              layer.textStrokeColor.toARGB32() ==
                              color.toARGB32();
                          return _ColorDot(
                            color: color,
                            selected: selected,
                            onTap: () => widget.onStrokeColorSelected(color),
                          );
                        }),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextQuickActionButton extends StatelessWidget {
  const _TextQuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLabeledSlider extends StatelessWidget {
  const _CompactLabeledSlider({
    required this.sliderId,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.width,
    required this.isActive,
    required this.onActivate,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.valueText,
  });

  final String sliderId;
  final String label;
  final double value;
  final double min;
  final double max;
  final double width;
  final bool isActive;
  final VoidCallback onActivate;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      key: ValueKey<String>('compact-slider-$sliderId'),
      width: width,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF172554) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF60A5FA) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              const Spacer(),
              Text(
                valueText ?? value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 17),
              activeTrackColor: isActive
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF64748B),
              inactiveTrackColor: const Color(0xFF334155),
              thumbColor: isActive
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF94A3B8),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChangeStart: isActive
                  ? (val) {
                      onActivate();
                      onChangeStart?.call(val);
                    }
                  : null,
              onChanged: isActive ? onChanged : null,
              onChangeEnd: isActive
                  ? (val) {
                      onChangeEnd?.call(val);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
    if (isActive) {
      return body;
    }
    return _PressableSurface(
      onTap: onActivate,
      borderRadius: BorderRadius.circular(12),
      child: body,
    );
  }
}

class _AlignChip extends StatelessWidget {
  const _AlignChip({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 30,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF172554) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF334155),
            ),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x222563EB),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

class _TextTabChip extends StatelessWidget {
  const _TextTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF172554) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF334155),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFFF8FAFC),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.localizedLabel,
  });

  final String label;
  final String? localizedLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 72,
          child: Text(
            localizedLabel ?? label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE2E8F0),
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: const Color(0xFF60A5FA),
              inactiveTrackColor: const Color(0xFF334155),
              thumbColor: const Color(0xFF93C5FD),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _FontPickerScreen extends StatefulWidget {
  const _FontPickerScreen({
    required this.fontFamilies,
    required this.selectedFontFamily,
  });

  final List<String> fontFamilies;
  final String selectedFontFamily;

  @override
  State<_FontPickerScreen> createState() => _FontPickerScreenState();
}

class _FontPickerScreenState extends State<_FontPickerScreen> {
  late final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<String> get _filteredFonts {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.fontFamilies;
    }
    return widget.fontFamilies
        .where((family) => family.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fonts = _filteredFonts;
    final strings = context.strings;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(strings.localized(telugu: 'Fonts', english: 'Fonts')),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: strings.localized(
                    telugu: 'Search fonts',
                    english: 'Search fonts',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: fonts.isEmpty
                  ? Center(
                      child: Text(
                        strings.localized(
                          telugu: 'Fonts dorakaledu',
                          english: 'Fonts not found',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: fonts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) {
                        final family = fonts[index];
                        final isSelected = family == widget.selectedFontFamily;
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pop(family),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          family,
                                          style: TextStyle(
                                            fontFamily: family,
                                            fontSize: 24,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          family,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF2563EB),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextEditScreen extends StatefulWidget {
  const _TextEditScreen({required this.initialText});

  final String initialText;

  @override
  State<_TextEditScreen> createState() => _TextEditScreenState();
}

class _TextEditScreenState extends State<_TextEditScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.localized(telugu: 'Edit Text', english: 'Edit Text'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _handleSave,
            child: Text(strings.localized(telugu: 'Save', english: 'Save')),
          ),
        ],
      ),
      body: SafeArea(
        child: TextField(
          controller: _controller,
          autofocus: true,
          expands: true,
          minLines: null,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: strings.localized(
              telugu: 'Type your text',
              english: 'Type your text',
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ),
    );
  }
}

class _BackgroundPickerScreen extends StatefulWidget {
  const _BackgroundPickerScreen({
    required this.colors,
    required this.gradients,
    required this.selectedColor,
    required this.selectedGradientIndex,
    required this.hasSelectedImage,
    required this.onColorSelected,
    required this.onGradientSelected,
    required this.onImageSelected,
  });

  final List<Color> colors;
  final List<List<Color>> gradients;
  final Color selectedColor;
  final int selectedGradientIndex;
  final bool hasSelectedImage;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<int> onGradientSelected;
  final Future<bool> Function() onImageSelected;

  @override
  State<_BackgroundPickerScreen> createState() =>
      _BackgroundPickerScreenState();
}

class _BackgroundPickerScreenState extends State<_BackgroundPickerScreen> {
  late Color _selectedColor = widget.selectedColor;
  late int _selectedGradientIndex = widget.selectedGradientIndex;
  late bool _hasSelectedImage = widget.hasSelectedImage;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.localized(telugu: 'Background', english: 'Background'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_outlined),
              ),
              title: Text(
                strings.localized(
                  telugu: 'Background Image',
                  english: 'Background Image',
                ),
              ),
              subtitle: Text(
                strings.localized(
                  telugu: 'Apply gallery image to poster paper only',
                  english: 'Apply gallery image to poster paper only',
                ),
              ),
              trailing: TextButton(
                onPressed: () async {
                  final didSelect = await widget.onImageSelected();
                  if (!mounted) {
                    return;
                  }
                  if (!didSelect) {
                    return;
                  }
                  setState(() {
                    _hasSelectedImage = true;
                    _selectedGradientIndex = -1;
                  });
                },
                child: Text(
                  _hasSelectedImage
                      ? strings.localized(telugu: 'Change', english: 'Change')
                      : strings.localized(telugu: 'Import', english: 'Import'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.localized(
                telugu: 'Solid Colors',
                english: 'Solid Colors',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.colors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final color = widget.colors[index];
                final isSelected =
                    _selectedGradientIndex == -1 &&
                    _selectedColor.toARGB32() == color.toARGB32();
                return _BackgroundColorTile(
                  color: color,
                  selected: isSelected,
                  onTap: () {
                    widget.onColorSelected(color);
                    setState(() {
                      _selectedColor = color;
                      _selectedGradientIndex = -1;
                      _hasSelectedImage = false;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              strings.localized(telugu: 'Gradients', english: 'Gradients'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.gradients.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                return _BackgroundGradientTile(
                  colors: widget.gradients[index],
                  selected: _selectedGradientIndex == index,
                  onTap: () {
                    widget.onGradientSelected(index);
                    setState(() {
                      _selectedGradientIndex = index;
                      _hasSelectedImage = false;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftsScreen extends StatefulWidget {
  const _DraftsScreen({
    required this.storageService,
    required this.onSaveCurrentDraft,
    required this.onOpenDraft,
  });

  final EditorDraftStorageService storageService;
  final Future<void> Function() onSaveCurrentDraft;
  final Future<void> Function(Map<String, dynamic> draft) onOpenDraft;

  @override
  State<_DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<_DraftsScreen> {
  List<File> _draftFiles = <File>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDrafts());
  }

  Future<void> _loadDrafts() async {
    final files = await widget.storageService.listManualDraftFiles();
    if (!mounted) return;
    setState(() {
      _draftFiles = files.whereType<File>().toList(growable: false);
      _isLoading = false;
    });
  }

  Future<void> _handleOpenDraft(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    await widget.onOpenDraft(decoded);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _handleDeleteDraft(File file) async {
    await file.delete();
    await _loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.localized(telugu: 'Drafts', english: 'Drafts')),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await widget.onSaveCurrentDraft();
              await _loadDrafts();
            },
            child: Text(
              strings.localized(
                telugu: 'Save Current',
                english: 'Save Current',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _draftFiles.isEmpty
            ? Center(
                child: Text(
                  strings.localized(
                    telugu: 'No saved drafts',
                    english: 'No saved drafts',
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: _draftFiles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final file = _draftFiles[index];
                  final name = file.path.split(Platform.pathSeparator).last;
                  final modified = file.statSync().modified;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    tileColor: Colors.white,
                    title: Text(name),
                    subtitle: Text(
                      modified.toLocal().toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const Icon(Icons.drafts_rounded),
                    trailing: IconButton(
                      onPressed: () => _handleDeleteDraft(file),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    onTap: () => _handleOpenDraft(file),
                  );
                },
              ),
      ),
    );
  }
}

class _LayersScreen extends StatefulWidget {
  const _LayersScreen({
    required this.layers,
    required this.selectedLayerId,
    required this.onSelectLayer,
    required this.onDeleteLayer,
    required this.onToggleLayerLock,
    required this.onToggleLayerVisibility,
    required this.onReorderLayers,
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final ValueChanged<String> onSelectLayer;
  final ValueChanged<String> onDeleteLayer;
  final ValueChanged<String> onToggleLayerLock;
  final ValueChanged<String> onToggleLayerVisibility;
  final void Function(int oldIndex, int newIndex) onReorderLayers;

  @override
  State<_LayersScreen> createState() => _LayersScreenState();
}

class _LayersScreenState extends State<_LayersScreen> {
  String? _selectedLayerId;

  @override
  void initState() {
    super.initState();
    _selectedLayerId = widget.selectedLayerId;
  }

  String _layerTitle(_CanvasLayer layer, int index) {
    if (layer.isPhoto) {
      return context.strings.localized(
        telugu: 'Photo ${index + 1}',
        english: 'Photo ${index + 1}',
      );
    }
    if (layer.isText) {
      return context.strings.localized(
        telugu: 'Text ${index + 1}',
        english: 'Text ${index + 1}',
      );
    }
    return context.strings.localized(
      telugu: 'Sticker ${index + 1}',
      english: 'Sticker ${index + 1}',
    );
  }

  Widget _buildLayerPreview(_CanvasLayer layer) {
    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: layer.isPhoto
          ? Image.memory(
              layer.bytes!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              cacheWidth: 96,
            )
          : layer.isText
          ? const Icon(Icons.text_fields_rounded, color: Color(0xFF334155))
          : Center(
              child: _ImageEditorScreenState._buildStickerVisual(
                layer.sticker,
                fontSize: 22,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
              ),
            ),
    );
  }

  void _handleDelete(String layerId) {
    widget.onDeleteLayer(layerId);
    if (widget.layers.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_selectedLayerId == layerId) {
      _selectedLayerId = widget.layers.last.id;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final displayLayers = widget.layers.reversed.toList(growable: false);
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.localized(telugu: 'Layers', english: 'Layers')),
      ),
      body: SafeArea(
        child: widget.layers.isEmpty
            ? Center(
                child: Text(
                  strings.localized(
                    telugu: 'No layers available',
                    english: 'No layers available',
                  ),
                ),
              )
            : ReorderableListView.builder(
                itemCount: displayLayers.length,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                onReorder: (oldIndex, newIndex) {
                  final total = widget.layers.length;
                  final mappedOldIndex = (total - 1) - oldIndex;
                  final mappedNewIndex = total - newIndex;
                  widget.onReorderLayers(mappedOldIndex, mappedNewIndex);
                  setState(() {});
                },
                itemBuilder: (BuildContext context, int index) {
                  final layer = displayLayers[index];
                  final isSelected = layer.id == _selectedLayerId;

                  return Container(
                    key: ValueKey(layer.id),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        widget.onSelectLayer(layer.id);
                        setState(() {
                          _selectedLayerId = layer.id;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: <Widget>[
                            _buildLayerPreview(layer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _layerTitle(layer, index),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isSelected)
                                    Text(
                                      layer.isHidden
                                          ? strings.localized(
                                              telugu: 'దాచబడింది',
                                              english: 'Hidden',
                                            )
                                          : layer.isLocked
                                          ? strings.localized(
                                              telugu: 'లాక్ అయింది',
                                              english: 'Locked',
                                            )
                                          : strings.localized(
                                              telugu: 'ఎంపికైంది',
                                              english: 'Selected',
                                            ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            _LayerActionButton(
                              icon: layer.isHidden
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              tooltip: layer.isHidden
                                  ? strings.localized(
                                      telugu: 'చూపించు',
                                      english: 'Show',
                                    )
                                  : strings.localized(
                                      telugu: 'దాచు',
                                      english: 'Hide',
                                    ),
                              onTap: () {
                                widget.onToggleLayerVisibility(layer.id);
                                if (layer.id == _selectedLayerId &&
                                    !layer.isHidden) {
                                  _selectedLayerId = null;
                                }
                                setState(() {});
                              },
                            ),
                            _LayerActionButton(
                              icon: layer.isLocked
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              tooltip: layer.isLocked
                                  ? strings.localized(
                                      telugu: 'అన్‌లాక్',
                                      english: 'Unlock',
                                    )
                                  : strings.localized(
                                      telugu: 'లాక్',
                                      english: 'Lock',
                                    ),
                              onTap: () {
                                widget.onToggleLayerLock(layer.id);
                                setState(() {});
                              },
                            ),
                            _LayerActionButton(
                              icon: Icons.delete_outline_rounded,
                              tooltip: strings.localized(
                                telugu: 'డిలీట్',
                                english: 'Delete',
                              ),
                              onTap: () => _handleDelete(layer.id),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 1),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _BackgroundColorTile extends StatelessWidget {
  const _BackgroundColorTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundGradientTile extends StatelessWidget {
  const _BackgroundGradientTile({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1F0F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: selected
            ? const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: const Color(0x1A2563EB),
        highlightColor: const Color(0x0F2563EB),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFD1D5DB),
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _LayerActionButton extends StatelessWidget {
  const _LayerActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      visualDensity: VisualDensity.compact,
      splashRadius: 16,
      icon: Icon(icon, size: 17),
    );
  }
}

class _GradientDot extends StatelessWidget {
  const _GradientDot({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: const Color(0x1A2563EB),
        highlightColor: const Color(0x0F2563EB),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: colors),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFD1D5DB),
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.height,
    required this.onUndoTap,
    required this.onRedoTap,
    required this.onDraftsTap,
    required this.onExportTap,
    required this.onDeleteTap,
    required this.onDuplicateTap,
    required this.onBringFrontTap,
    required this.onSendBackTap,
    required this.canUndo,
    required this.canRedo,
    required this.isExporting,
    required this.canDelete,
    required this.canDuplicate,
    required this.canBringFront,
    required this.canSendBack,
  });

  final double height;
  final VoidCallback onUndoTap;
  final VoidCallback onRedoTap;
  final VoidCallback onDraftsTap;
  final VoidCallback onExportTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onDuplicateTap;
  final VoidCallback onBringFrontTap;
  final VoidCallback onSendBackTap;
  final bool canUndo;
  final bool canRedo;
  final bool isExporting;
  final bool canDelete;
  final bool canDuplicate;
  final bool canBringFront;
  final bool canSendBack;

  VoidCallback? _withHaptic(VoidCallback? callback) {
    if (callback == null) {
      return null;
    }
    return () {
      HapticFeedback.selectionClick();
      callback();
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Color(0xF2101826),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _EditorIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: strings.localized(telugu: '???????', english: 'Back'),
              onTap: _withHaptic(() => Navigator.of(context).maybePop()),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 164,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    strings.localized(
                      telugu: '????? ??????',
                      english: 'Image Editor',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF8FAFC),
                      letterSpacing: -0.2,
                      fontSize: 20,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Poster workspace',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.1,
                      color: Color(0xFFB8C4D6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _TopActionButton(
              label: strings.localized(telugu: '????', english: 'Undo'),
              onTap: canUndo ? onUndoTap : null,
            ),
            const SizedBox(width: 8),
            _TopActionButton(
              label: strings.localized(telugu: '????', english: 'Redo'),
              onTap: canRedo ? onRedoTap : null,
            ),
            const SizedBox(width: 8),
            _TopActionButton(
              label: strings.localized(telugu: '??????????', english: 'Drafts'),
              onTap: onDraftsTap,
            ),
            const SizedBox(width: 8),
            _TopActionButton(
              label: strings.localized(
                telugu: isExporting ? '???? ????????...' : '??????',
                english: isExporting ? 'Saving...' : 'Export',
              ),
              onTap: isExporting ? null : onExportTap,
            ),
            const SizedBox(width: 6),
            _EditorIconButton(
              icon: Icons.flip_to_back_rounded,
              tooltip: strings.localized(
                telugu: '??????? ????',
                english: 'Send back',
              ),
              onTap: _withHaptic(canSendBack ? onSendBackTap : null),
            ),
            _EditorIconButton(
              icon: Icons.flip_to_front_rounded,
              tooltip: strings.localized(
                telugu: '??????? ????????',
                english: 'Bring front',
              ),
              onTap: _withHaptic(canBringFront ? onBringFrontTap : null),
            ),
            _EditorIconButton(
              icon: Icons.control_point_duplicate_rounded,
              tooltip: strings.localized(
                telugu: '??????????',
                english: 'Duplicate selected',
              ),
              onTap: _withHaptic(canDuplicate ? onDuplicateTap : null),
            ),
            _EditorIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: strings.localized(
                telugu: '??????',
                english: 'Delete selected',
              ),
              onTap: _withHaptic(canDelete ? onDeleteTap : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorModeBadge extends StatelessWidget {
  const _EditorModeBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey<String>(label),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorQuickHint extends StatelessWidget {
  const _EditorQuickHint({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      offset: Offset.zero,
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xE4DCE8F8)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x070F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF60A5FA), Color(0xFFF472B6)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.tips_and_updates_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.localized(
                  telugu:
                      'సూచన: ఒక లేయర్ ఎంచుకుంటే టూల్స్ యాక్టివ్ అవుతాయి. ఖాళీ క్యాన్వాస్‌పై టాప్ చేస్తే ఎంపిక తొలగుతుంది.',
                  english:
                      'Tip: Select a layer to unlock tool actions. Tap empty canvas to deselect.',
                ),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _PressableSurface(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomToolsBar extends StatelessWidget {
  const _BottomToolsBar({
    required this.height,
    required this.onAddPhotoTap,
    required this.onAddTextTap,
    required this.onStickerTap,
    required this.onBackgroundTap,
    required this.onLayersTap,
    required this.onAdjustTap,
    required this.onCropPhotoTap,
    required this.onEraserTap,
    required this.onRemoveBackgroundTap,
    required this.activeToolLabel,
    required this.canAdjustPhoto,
    required this.canCropPhoto,
    required this.canEraserPhoto,
    required this.canRemoveBackground,
    required this.isRemovingBackground,
    required this.selectedPhotoLayer,
    required this.onOpacityChanged,
    required this.onFlipHorizontalTap,
    required this.onFlipVerticalTap,
    required this.onRotateLeftTap,
    required this.onRotateRightTap,
  });

  final double height;
  final VoidCallback onAddPhotoTap;
  final VoidCallback onAddTextTap;
  final VoidCallback onStickerTap;
  final VoidCallback onBackgroundTap;
  final VoidCallback onLayersTap;
  final VoidCallback onAdjustTap;
  final VoidCallback onCropPhotoTap;
  final VoidCallback onEraserTap;
  final VoidCallback onRemoveBackgroundTap;
  final String activeToolLabel;
  final bool canAdjustPhoto;
  final bool canCropPhoto;
  final bool canEraserPhoto;
  final bool canRemoveBackground;
  final bool isRemovingBackground;
  final _CanvasLayer? selectedPhotoLayer;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onFlipHorizontalTap;
  final VoidCallback onFlipVerticalTap;
  final VoidCallback onRotateLeftTap;
  final VoidCallback onRotateRightTap;

  static const List<({String label, IconData icon})> _tools =
      <({String label, IconData icon})>[
        (label: 'Add Photo', icon: Icons.add_photo_alternate_outlined),
        (label: 'Text', icon: Icons.text_fields_rounded),
        (label: 'Stickers', icon: Icons.emoji_emotions_outlined),
        (label: 'Background', icon: Icons.wallpaper_outlined),
        (label: 'Layers', icon: Icons.layers_outlined),
        (label: 'Adjust', icon: Icons.tune_rounded),
        (label: 'Crop', icon: Icons.crop_rounded),
        (label: 'Eraser', icon: Icons.brush_outlined),
        (label: 'Remove BG', icon: Icons.auto_fix_high_outlined),
      ];

  String _localizedToolLabel(AppStrings strings, String label) {
    switch (label) {
      case 'Add Photo':
        return strings.localized(telugu: 'ఫోటో', english: 'Add Photo');
      case 'Text':
        return strings.localized(telugu: 'టెక్స్ట్', english: 'Text');
      case 'Stickers':
        return strings.localized(telugu: 'స్టికర్స్', english: 'Stickers');
      case 'Background':
        return strings.localized(
          telugu: 'బ్యాక్‌గ్రౌండ్',
          english: 'Background',
        );
      case 'Layers':
        return strings.localized(telugu: 'లేయర్స్', english: 'Layers');
      case 'Adjust':
        return strings.localized(telugu: 'అడ్జస్ట్', english: 'Adjust');
      case 'Crop':
        return strings.localized(telugu: 'క్రాప్', english: 'Crop');
      case 'Eraser':
        return strings.localized(telugu: 'ఈరేసర్', english: 'Eraser');
      case 'Remove BG':
        return strings.localized(telugu: 'బీజీ తొలగింపు', english: 'Remove BG');
      case 'Removing...':
        return strings.localized(
          telugu: 'తొలగిస్తోంది...',
          english: 'Removing...',
        );
      default:
        return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final photoLayer = selectedPhotoLayer;
    final hasPhotoControls = photoLayer != null && photoLayer.isPhoto;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF2101826),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compactTools = constraints.maxHeight < 155;
          final needsScrollableLayout =
              hasPhotoControls && constraints.maxHeight < 168;

          Widget buildToolsList({required double stripHeight}) {
            final list = ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              scrollDirection: Axis.horizontal,
              itemCount: _tools.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                final tool = _tools[index];
                return _ToolItem(
                  label: _localizedToolLabel(
                    strings,
                    index == 8 && isRemovingBackground
                        ? 'Removing...'
                        : tool.label,
                  ),
                  icon: tool.icon,
                  active: tool.label == activeToolLabel,
                  compact: compactTools,
                  onTap: switch (index) {
                    0 => onAddPhotoTap,
                    1 => onAddTextTap,
                    2 => onStickerTap,
                    3 => onBackgroundTap,
                    4 => onLayersTap,
                    5 => canAdjustPhoto ? onAdjustTap : null,
                    6 => canCropPhoto ? onCropPhotoTap : null,
                    7 => canEraserPhoto ? onEraserTap : null,
                    8 => canRemoveBackground ? onRemoveBackgroundTap : null,
                    _ => () {},
                  },
                  enabled: switch (index) {
                    5 => canAdjustPhoto,
                    6 => canCropPhoto,
                    7 => canEraserPhoto,
                    8 => canRemoveBackground,
                    _ => true,
                  },
                );
              },
            );
            if (!stripHeight.isFinite) {
              return list;
            }
            return SizedBox(height: stripHeight, child: list);
          }

          Widget buildPhotoQuickActions() {
            final selectedPhoto = photoLayer!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      strings.localized(
                        telugu: 'ఫోటో త్వరిత చర్యలు',
                        english: 'Photo quick actions',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF172554),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        strings.localized(
                          telugu: 'ఎంచుకున్న ఫోటో',
                          english: 'Selected photo',
                        ),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    _AlignChip(
                      icon: Icons.rotate_left_rounded,
                      selected: false,
                      onTap: onRotateLeftTap,
                    ),
                    _AlignChip(
                      icon: Icons.rotate_right_rounded,
                      selected: false,
                      onTap: onRotateRightTap,
                    ),
                    _AlignChip(
                      icon: Icons.flip_rounded,
                      selected: selectedPhoto.flipPhotoHorizontally,
                      onTap: onFlipHorizontalTap,
                    ),
                    _AlignChip(
                      icon: Icons.flip_camera_android_rounded,
                      selected: selectedPhoto.flipPhotoVertically,
                      onTap: onFlipVerticalTap,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LabeledSlider(
                        label: 'Opacity',
                        localizedLabel: strings.localized(
                          telugu: 'అపాసిటీ',
                          english: 'Opacity',
                        ),
                        value: selectedPhoto.photoOpacity
                            .clamp(0.1, 1)
                            .toDouble(),
                        min: 0.1,
                        max: 1,
                        onChanged: onOpacityChanged,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 1,
                  color: const Color(0xFF334155),
                ),
                const SizedBox(height: 6),
              ],
            );
          }

          if (needsScrollableLayout) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (hasPhotoControls) buildPhotoQuickActions(),
                  buildToolsList(stripHeight: compactTools ? 58 : 64),
                ],
              ),
            );
          }

          return Column(
            children: <Widget>[
              if (hasPhotoControls) buildPhotoQuickActions(),
              Expanded(child: buildToolsList(stripHeight: double.infinity)),
            ],
          );
        },
      ),
    );
  }
}

class _TextBottomToolsBar extends StatelessWidget {
  const _TextBottomToolsBar({
    required this.height,
    required this.showOptionsSelected,
    required this.onEditTap,
    required this.onFontsTap,
    required this.onToggleOptionsTap,
  });

  final double height;
  final bool showOptionsSelected;
  final VoidCallback onEditTap;
  final VoidCallback onFontsTap;
  final VoidCallback onToggleOptionsTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xEE0F172A),
            const Color(0xEE111827),
            const Color(0xEE1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _TextModeToolItem(
            icon: Icons.edit_rounded,
            label: strings.localized(telugu: 'ఎడిట్', english: 'Edit'),
            onTap: onEditTap,
          ),
          const SizedBox(width: 8),
          _TextModeToolItem(
            icon: Icons.font_download_rounded,
            label: strings.localized(telugu: 'ఫాంట్స్', english: 'Fonts'),
            onTap: onFontsTap,
          ),
          const SizedBox(width: 8),
          _TextModeToolItem(
            icon: Icons.tune_rounded,
            label: strings.localized(telugu: 'ఆప్షన్స్', english: 'Options'),
            selected: showOptionsSelected,
            onTap: onToggleOptionsTap,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              strings.localized(
                telugu: 'టెక్స్ట్ టూల్స్',
                english: 'Text tools',
              ),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorCommitOverlay extends StatelessWidget {
  const _EditorCommitOverlay({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x220F172A),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xE5E2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.8),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EraserBottomToolsBar extends StatelessWidget {
  const _EraserBottomToolsBar({
    required this.height,
    required this.mode,
    required this.brushSize,
    required this.hardness,
    required this.strength,
    required this.activeControl,
    required this.isApplying,
    required this.isInitializing,
    required this.canUndo,
    required this.canRedo,
    required this.onModeChanged,
    required this.onBrushSizeChanged,
    required this.onHardnessChanged,
    required this.onStrengthChanged,
    required this.onActiveControlChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onBack,
    required this.onReset,
    required this.onApply,
  });

  final double height;
  final _EraserMode mode;
  final double brushSize;
  final double hardness;
  final double strength;
  final _EraserControl? activeControl;
  final bool isApplying;
  final bool isInitializing;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<_EraserMode> onModeChanged;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onHardnessChanged;
  final ValueChanged<double> onStrengthChanged;
  final ValueChanged<_EraserControl> onActiveControlChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final disabled = isApplying || isInitializing;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF2F7FF).withValues(alpha: 0.94),
            const Color(0xFFFDF2F8).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xEAEFF4FA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: height - 16,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _TopActionButton(
                label: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
                onTap: disabled ? null : onBack,
              ),
              const SizedBox(width: 8),
              _EraserModeToggle(
                mode: mode,
                enabled: !disabled,
                onModeChanged: onModeChanged,
              ),
              const SizedBox(width: 10),
              _TopActionButton(
                label: strings.localized(telugu: 'Undo', english: 'Undo'),
                onTap: (!disabled && canUndo) ? onUndo : null,
              ),
              const SizedBox(width: 6),
              _TopActionButton(
                label: strings.localized(telugu: 'Redo', english: 'Redo'),
                onTap: (!disabled && canRedo) ? onRedo : null,
              ),
              const SizedBox(width: 10),
              _EraserSliderChip(
                label: strings.localized(telugu: 'బ్రష్', english: 'Brush'),
                value: brushSize,
                min: 8,
                max: 120,
                display: brushSize.round().toString(),
                isActive: activeControl == _EraserControl.brushSize,
                enabled: !disabled,
                onActivate: () =>
                    onActiveControlChanged(_EraserControl.brushSize),
                onChanged: onBrushSizeChanged,
              ),
              const SizedBox(width: 8),
              _EraserSliderChip(
                label: strings.localized(
                  telugu: 'హార్డ్‌నెస్',
                  english: 'Hard',
                ),
                value: hardness,
                min: 0,
                max: 1,
                display: hardness.toStringAsFixed(2),
                isActive: activeControl == _EraserControl.hardness,
                enabled: !disabled,
                onActivate: () =>
                    onActiveControlChanged(_EraserControl.hardness),
                onChanged: onHardnessChanged,
              ),
              const SizedBox(width: 8),
              _EraserSliderChip(
                label: strings.localized(
                  telugu: 'స్ట్రెంగ్త్',
                  english: 'Strength',
                ),
                value: strength,
                min: 0.1,
                max: 1,
                display: strength.toStringAsFixed(2),
                isActive: activeControl == _EraserControl.strength,
                enabled: !disabled,
                onActivate: () =>
                    onActiveControlChanged(_EraserControl.strength),
                onChanged: onStrengthChanged,
              ),
              const SizedBox(width: 10),
              _TopActionButton(
                label: strings.localized(telugu: 'రిసెట్', english: 'Reset'),
                onTap: disabled ? null : onReset,
              ),
              const SizedBox(width: 6),
              _TopActionButton(
                label: strings.localized(
                  telugu: isApplying ? 'అప్లై అవుతోంది...' : 'అప్లై',
                  english: isApplying ? 'Applying...' : 'Apply',
                ),
                onTap: disabled ? null : onApply,
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _EraserModeToggle extends StatelessWidget {
  const _EraserModeToggle({
    required this.mode,
    required this.enabled,
    required this.onModeChanged,
  });

  final _EraserMode mode;
  final bool enabled;
  final ValueChanged<_EraserMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _EraserModeChip(
            label: strings.localized(telugu: 'తొలగించు', english: 'Erase'),
            selected: mode == _EraserMode.erase,
            enabled: enabled,
            color: const Color(0xFFEF4444),
            onTap: () => onModeChanged(_EraserMode.erase),
          ),
          const SizedBox(width: 4),
          _EraserModeChip(
            label: strings.localized(
              telugu: 'తిరిగి తెచ్చు',
              english: 'Restore',
            ),
            selected: mode == _EraserMode.restore,
            enabled: enabled,
            color: const Color(0xFF16A34A),
            onTap: () => onModeChanged(_EraserMode.restore),
          ),
        ],
      ),
    );
  }
}

class _EraserModeChip extends StatelessWidget {
  const _EraserModeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      enabled: enabled,
      child: Container(
        constraints: const BoxConstraints(minWidth: 68),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? color : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _EraserSliderChip extends StatelessWidget {
  const _EraserSliderChip({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.isActive,
    required this.enabled,
    required this.onActivate,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final bool isActive;
  final bool enabled;
  final VoidCallback onActivate;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? const Color(0xFF2563EB)
        : const Color(0xFFE2E8F0);
    final fillColor = isActive
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFF8FAFD);
    final sliderBody = Container(
      width: 196,
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 54,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF334155),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                activeTrackColor: isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
                inactiveTrackColor: const Color(0xFFDDE5EF),
                thumbColor: isActive
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF64748B),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: (enabled && isActive) ? onChanged : null,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              display,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      height: 60,
      child: isActive
          ? sliderBody
          : _PressableSurface(
              onTap: enabled ? onActivate : null,
              borderRadius: BorderRadius.circular(14),
              enabled: enabled,
              child: sliderBody,
            ),
    );
  }
}

class _AdjustBottomToolsBar extends StatelessWidget {
  const _AdjustBottomToolsBar({
    required this.height,
    required this.sessionListenable,
    required this.onSessionChanged,
    required this.onBack,
    required this.onReset,
    required this.onApply,
  });

  final double height;
  final ValueListenable<_AdjustSessionState?> sessionListenable;
  final ValueChanged<_AdjustSessionState> onSessionChanged;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FBFF).withValues(alpha: 0.93),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xEAEFF4FA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text(
                strings.localized(telugu: 'అడ్జస్ట్', english: 'Adjust'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder<_AdjustSessionState?>(
              valueListenable: sessionListenable,
              builder:
                  (
                    BuildContext context,
                    _AdjustSessionState? session,
                    Widget? child,
                  ) {
                    final resolved =
                        session ??
                        const _AdjustSessionState(
                          brightness: 0,
                          contrast: 1,
                          saturation: 1,
                          blur: 0,
                        );
                    return SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _AdjustSlider(
                            label: strings.localized(
                              telugu: 'బ్రైట్‌నెస్',
                              english: 'Brightness',
                            ),
                            value: resolved.brightness,
                            min: -0.35,
                            max: 0.35,
                            display: resolved.brightness.toStringAsFixed(2),
                            onChanged: (value) => onSessionChanged(
                              resolved.copyWith(brightness: value),
                            ),
                          ),
                          _AdjustSlider(
                            label: strings.localized(
                              telugu: 'కాంట్రాస్ట్',
                              english: 'Contrast',
                            ),
                            value: resolved.contrast,
                            min: 0.6,
                            max: 1.6,
                            display: resolved.contrast.toStringAsFixed(2),
                            onChanged: (value) => onSessionChanged(
                              resolved.copyWith(contrast: value),
                            ),
                          ),
                          _AdjustSlider(
                            label: strings.localized(
                              telugu: 'సాచురేషన్',
                              english: 'Saturation',
                            ),
                            value: resolved.saturation,
                            min: 0,
                            max: 2,
                            display: resolved.saturation.toStringAsFixed(2),
                            onChanged: (value) => onSessionChanged(
                              resolved.copyWith(saturation: value),
                            ),
                          ),
                          _AdjustSlider(
                            label: strings.localized(
                              telugu: 'బ్లర్',
                              english: 'Blur',
                            ),
                            value: resolved.blur,
                            min: 0,
                            max: 10,
                            display: resolved.blur.toStringAsFixed(1),
                            onChanged: (value) => onSessionChanged(
                              resolved.copyWith(blur: value),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(
                    strings.localized(telugu: 'వెనక్కి', english: 'Back'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: Text(
                    strings.localized(telugu: 'రిసెట్', english: 'Reset'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApply,
                  child: Text(
                    strings.localized(telugu: 'అప్లై', english: 'Apply'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjustSlider extends StatelessWidget {
  const _AdjustSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

class _CropSessionOverlay extends StatelessWidget {
  const _CropSessionOverlay({
    required this.boundaryKey,
    required this.imageBytes,
    required this.controller,
    required this.topInset,
    required this.bottomInset,
    required this.aspectRatio,
  });

  final GlobalKey boundaryKey;
  final Uint8List imageBytes;
  final TransformationController controller;
  final double topInset;
  final double bottomInset;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final frameAspectRatio = (aspectRatio != null && aspectRatio! > 0)
        ? aspectRatio!
        : 1.0;
    return IgnorePointer(
      ignoring: false,
      child: Padding(
        padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
        child: ColoredBox(
          color: const Color(0xB30B1120),
          child: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final maxWidth = constraints.maxWidth * 0.9;
                final maxHeight = constraints.maxHeight * 0.9;
                var frameWidth = maxWidth;
                var frameHeight = frameWidth / frameAspectRatio;
                if (frameHeight > maxHeight) {
                  frameHeight = maxHeight;
                  frameWidth = frameHeight * frameAspectRatio;
                }
                return SizedBox(
                  width: frameWidth,
                  height: frameHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      RepaintBoundary(
                        key: boundaryKey,
                        child: ClipRect(
                          child: InteractiveViewer(
                            transformationController: controller,
                            minScale: 0.5,
                            maxScale: 6,
                            boundaryMargin: const EdgeInsets.all(240),
                            child: SizedBox.expand(
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: const _CropOverlayPainter(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CropBottomToolsBar extends StatelessWidget {
  const _CropBottomToolsBar({
    required this.height,
    required this.onBack,
    required this.onReset,
    required this.onApply,
    required this.isApplying,
    required this.selectedAspectRatio,
    required this.onAspectRatioChanged,
  });

  final double height;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final bool isApplying;
  final double? selectedAspectRatio;
  final ValueChanged<double?> onAspectRatioChanged;

  bool _isSelected(double? ratio) {
    if (ratio == null && selectedAspectRatio == null) {
      return true;
    }
    if (ratio == null || selectedAspectRatio == null) {
      return false;
    }
    return (ratio - selectedAspectRatio!).abs() < 0.001;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final disabled = isApplying;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF2F7FF).withValues(alpha: 0.94),
            const Color(0xFFFDF2F8).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xEAEFF4FA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _TopActionButton(
            label: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
            onTap: disabled ? null : onBack,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _CropAspectChip(
                  label: strings.localized(telugu: 'ఫ్రీ', english: 'Free'),
                  selected: _isSelected(null),
                  onTap: disabled ? null : () => onAspectRatioChanged(null),
                ),
                _CropAspectChip(
                  label: '1:1',
                  selected: _isSelected(1),
                  onTap: disabled ? null : () => onAspectRatioChanged(1),
                ),
                _CropAspectChip(
                  label: '4:5',
                  selected: _isSelected(4 / 5),
                  onTap: disabled ? null : () => onAspectRatioChanged(4 / 5),
                ),
                _CropAspectChip(
                  label: '16:9',
                  selected: _isSelected(16 / 9),
                  onTap: disabled ? null : () => onAspectRatioChanged(16 / 9),
                ),
                _CropAspectChip(
                  label: '9:16',
                  selected: _isSelected(9 / 16),
                  onTap: disabled ? null : () => onAspectRatioChanged(9 / 16),
                ),
                _CropAspectChip(
                  label: strings.localized(telugu: 'రిసెట్', english: 'Reset'),
                  selected: false,
                  onTap: disabled ? null : onReset,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _TopActionButton(
            label: strings.localized(
              telugu: isApplying ? 'అప్లై అవుతోంది...' : 'అప్లై',
              english: isApplying ? 'Applying...' : 'Apply',
            ),
            onTap: disabled ? null : onApply,
          ),
        ],
      ),
    );
  }
}

class _CropAspectChip extends StatelessWidget {
  const _CropAspectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerPickerScreen extends StatefulWidget {
  const _StickerPickerScreen({required this.categories, required this.catalog});

  final List<String> categories;
  final Map<String, List<String>> catalog;

  @override
  State<_StickerPickerScreen> createState() => _StickerPickerScreenState();
}

class _StickerPickerScreenState extends State<_StickerPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeCategory = 'All';
  String _query = '';

  List<String> get _allItems {
    final seen = <String>{};
    final items = <String>[];
    for (final category in widget.catalog.values) {
      for (final item in category) {
        if (seen.add(item)) {
          items.add(item);
        }
      }
    }
    return items;
  }

  List<String> get _filteredItems {
    final source = _activeCategory == 'All'
        ? _allItems
        : (widget.catalog[_activeCategory] ?? const <String>[]);
    if (_query.trim().isEmpty) {
      return source;
    }
    final query = _query.trim().toLowerCase();
    return source.where((item) => item.toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final items = _filteredItems;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.localized(telugu: 'ఎలిమెంట్స్', english: 'Elements'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: strings.localized(
                    telugu: 'ఎలిమెంట్స్ వెతకండి',
                    english: 'Search elements',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.categories.map((category) {
                    final selected = _activeCategory == category;
                    return _StickerCategoryChip(
                      label: category,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _activeCategory = category;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No elements found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                        itemCount: items.length,
                        itemBuilder: (BuildContext context, int index) {
                          final sticker = items[index];
                          return InkWell(
                            onTap: () => Navigator.of(context).pop(sticker),
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Center(
                                child:
                                    _ImageEditorScreenState._isImageLikeSticker(
                                      sticker,
                                    )
                                    ? Padding(
                                        padding: const EdgeInsets.all(6),
                                        child:
                                            _ImageEditorScreenState._buildStickerVisual(
                                              sticker,
                                              fontSize: 30,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.low,
                                            ),
                                      )
                                    : Text(
                                        sticker,
                                        style: const TextStyle(fontSize: 30),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerCategoryChip extends StatelessWidget {
  const _StickerCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PressableSurface extends StatefulWidget {
  const _PressableSurface({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final bool enabled;

  @override
  State<_PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<_PressableSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && widget.onTap != null;
    return AnimatedScale(
      scale: canTap && _pressed ? 0.965 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: !canTap
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!.call();
              },
        onHighlightChanged: (value) {
          if (_pressed != value && mounted) {
            setState(() {
              _pressed = value;
            });
          }
        },
        splashColor: const Color(0x122563EB),
        highlightColor: const Color(0x0A2563EB),
        borderRadius: widget.borderRadius,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 110),
          opacity: canTap ? (_pressed ? 0.93 : 1) : 0.72,
          child: widget.child,
        ),
      ),
    );
  }
}

class _EditorIconButton extends StatelessWidget {
  const _EditorIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _PressableSurface(
        onTap: onTap,
        enabled: onTap != null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: onTap == null
                ? const Color(0xFF172033)
                : const Color(0xFF1B2638),
            borderRadius: BorderRadius.circular(14),
            boxShadow: onTap == null
                ? null
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null
                ? const Color(0xFF94A3B8)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      enabled: onTap != null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFF172033)
              : const Color(0xFF1B2638),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? null
              : const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 6,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
            color: onTap == null
                ? const Color(0xFF94A3B8)
                : const Color(0xFFF8FAFC),
          ),
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final rect = Offset.zero & size;
    canvas.drawRect(rect, borderPaint);

    const handleLength = 22.0;
    const handleThickness = 4.0;

    void drawHandle(Offset origin, bool left, bool top) {
      final horizontal = Rect.fromLTWH(
        left ? origin.dx : origin.dx - handleLength,
        origin.dy - (top ? 0 : handleThickness),
        handleLength,
        handleThickness,
      );
      final vertical = Rect.fromLTWH(
        origin.dx - (left ? 0 : handleThickness),
        top ? origin.dy : origin.dy - handleLength,
        handleThickness,
        handleLength,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(horizontal, const Radius.circular(4)),
        handlePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(vertical, const Radius.circular(4)),
        handlePaint,
      );
    }

    drawHandle(rect.topLeft, true, true);
    drawHandle(rect.topRight, false, true);
    drawHandle(rect.bottomLeft, true, false);
    drawHandle(rect.bottomRight, false, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconTone = enabled
        ? active
              ? const Color(0xFF4F46E5)
              : const Color(0xFF1D4ED8)
        : const Color(0xFF94A3B8);
    final labelTone = enabled
        ? active
              ? const Color(0xFF312E81)
              : const Color(0xFF334155)
        : const Color(0xFF94A3B8);
    final itemWidth = compact ? 74.0 : 86.0;
    final iconSize = compact ? 18.0 : 20.0;
    final iconBubble = compact ? 38.0 : 42.0;
    final labelSize = compact ? 10.5 : 11.0;
    return _PressableSurface(
      onTap: onTap,
      enabled: enabled,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: iconBubble,
              height: iconBubble,
              decoration: BoxDecoration(
                color: enabled
                    ? active
                          ? const Color(0xFFE0E7FF)
                          : const Color(0xFFF8FAFC)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? <BoxShadow>[
                        BoxShadow(
                          color: active
                              ? const Color(0x183B82F6)
                              : const Color(0x0E0F172A),
                          blurRadius: active ? 8 : 5,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, size: iconSize, color: iconTone),
            ),
            SizedBox(height: compact ? 5 : 7),
            Text(
              label,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: labelSize,
                height: 1.05,
                color: labelTone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextModeToolItem extends StatelessWidget {
  const _TextModeToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFDBEAFE).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: const Color(0xFF0F172A)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
