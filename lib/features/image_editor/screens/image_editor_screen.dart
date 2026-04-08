import 'dart:async';
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

import '../models/background_presets.dart';
import '../models/editor_template_document.dart';
import '../models/elements_catalog.dart';
import '../models/editor_page_config.dart';
import '../services/background_removal_service.dart';
import '../services/editor_draft_storage_service.dart';

enum _CanvasLayerType { photo, text, sticker }

enum _ExportImageFormat { png, pngTransparent, jpg }

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
    with SingleTickerProviderStateMixin {
  static const double _topBarHeight = 64;
  static const double _bottomBarHeight = 86;
  static const double _cropBarHeight = 96;
  static const double _floatingBarGap = 10;
  static const double _photoControlsExtraHeight = 64;
  static const double _textStyleBarHeight = 148;
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

  final List<_CanvasLayer> _layers = <_CanvasLayer>[];
  final List<_EditorSnapshot> _undoStack = <_EditorSnapshot>[];
  final List<_EditorSnapshot> _redoStack = <_EditorSnapshot>[];
  String? _selectedLayerId;
  Color _canvasBackgroundColor = const Color(0xFFF4F7FC);
  int _canvasBackgroundGradientIndex = -1;
  int _layerSeed = 0;
  static const int _maxHistory = 40;
  bool _isFontSizeEditing = false;
  bool _isExporting = false;
  bool _isSharing = false;
  bool _isRemovingBackground = false;
  bool _isCapturingStage = false;
  bool _isTransparentExportCapture = false;
  bool _isCropMode = false;
  bool _suppressCanvasTapDown = false;
  int _suppressCanvasTapToken = 0;
  bool _showTextControls = false;
  bool _showVerticalSnapGuide = false;
  bool _showHorizontalSnapGuide = false;
  bool _isLayerInteracting = false;
  int _removeBackgroundTaskId = 0;
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

  int get _selectedLayerIndex {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return -1;
    }
    return _layers.indexWhere((item) => item.id == selectedId);
  }

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
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
    _backgroundRemoverInitialization = BackgroundRemover.instance.initializeOrt();
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
    if (_isRestoringDraft) {
      return;
    }
    if (_isLayerInteracting || _isCapturingStage) {
      _pendingAutosave = true;
      return;
    }
    _scheduleAutosave();
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
        const SnackBar(
          content: Text('Template load fail ayindi. Malli try cheyyandi'),
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
    return normalized.startsWith('http://') || normalized.startsWith('https://');
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

        final bytes = await _loadTemplateLayerBytes(templateLayer.assetPath);
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
        _selectedLayerId = importedLayers.isEmpty ? null : importedLayers.last.id;
        _canvasBackgroundColor = const Color(0xFFFFFFFF);
        _canvasBackgroundGradientIndex = -1;
        _stageBackgroundImageBytes = null;
        _templateDocument = null;
        _isTemplateHydrated = true;
      });
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
            'Subscription backend sync fail à°…à°¯à±à°¯à°¿à°‚à°¦à°¿. à°•à±Šà°¦à±à°¦à°¿à°¸à±‡à°ªà°Ÿà°¿ à°¤à°°à±à°µà°¾à°¤ à°®à°³à±à°²à±€ try à°šà±‡à°¯à°‚à°¡à°¿',
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
            'Purchase verification data à°¦à±Šà°°à°•à°²à±‡à°¦à±. Restore/Retry à°šà±‡à°¯à°‚à°¡à°¿',
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
            'Purchase complete à°…à°¯à°¿à°¨à°¾ entitlement active à°•à°¾à°²à±‡à°¦à±. Support à°¨à°¿ à°¸à°‚à°ªà±à°°à°¦à°¿à°‚à°šà°‚à°¡à°¿',
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
              : 'Subscription verification fail à°…à°¯à±à°¯à°¿à°‚à°¦à°¿',
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
    _undoStack.add(_takeSnapshot());
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
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

    final previous = _undoStack.removeLast();
    _redoStack.add(_takeSnapshot());
    setState(() {
      _restoreSnapshot(previous);
    });
  }

  void _handleRedo() {
    if (!_canRedo) {
      return;
    }

    final next = _redoStack.removeLast();
    _undoStack.add(_takeSnapshot());
    setState(() {
      _restoreSnapshot(next);
    });
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
          return AlertDialog(
            title: const Text('Recover Draft'),
            content: const Text(
              'Last autosaved project dorikindi. Danni restore cheyala?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Restore'),
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
        const SnackBar(content: Text('Draft saved in app storage')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft save fail ayyindi')));
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

  void _handleAddText() {
    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.text,
      text: 'Text',
      transform: Matrix4.identity(),
    );

    _pushUndoSnapshot();
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

    _pushUndoSnapshot();
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
    _handleAddText();
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

    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(text: value);
    });
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

    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textColor: color,
        textGradientIndex: -1,
      );
    });
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

    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(textAlign: align);
    });
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

    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textGradientIndex: gradientIndex,
      );
    });
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

    if (!_isFontSizeEditing) {
      _pushUndoSnapshot();
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        fontSize: fontSize.clamp(18, 96).toDouble(),
      );
    });
  }

  void _handleTextFontSizeEditStart(double _) {
    _isFontSizeEditing = true;
    _pushUndoSnapshot();
  }

  void _handleTextFontSizeEditEnd(double _) {
    _isFontSizeEditing = false;
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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.image_rounded),
                  title: const Text('PNG'),
                  subtitle: const Text(
                    'Transparent background, best for Remove BG',
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_ExportImageFormat.pngTransparent),
                ),
                ListTile(
                  leading: const Icon(Icons.crop_square_rounded),
                  title: const Text('PNG with Background'),
                  subtitle: const Text('Includes poster/stage background'),
                  onTap: () =>
                      Navigator.of(context).pop(_ExportImageFormat.png),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_rounded),
                  title: const Text('JPG'),
                  subtitle: const Text('Smaller file size'),
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

    final decision = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Canvas à°–à°¾à°³à±€à°—à°¾ à°‰à°‚à°¦à°¿'),
          content: const Text(
            'Design layers à°à°µà°¿ à°²à±‡à°µà±. à°…à°¯à°¿à°¨à°¾ à°•à±‚à°¡à°¾ background à°®à°¾à°¤à±à°°à°®à±‡ export à°šà±‡à°¯à°¾à°²à°¾?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('à°µà°¦à±à°¦à±'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('à°…à°µà±à°¨à±, export à°šà±‡à°¯à°¿'),
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
          const SnackBar(content: Text('Pro à°µà°¿à°œà°¯à°µà°‚à°¤à°‚à°—à°¾ activate à°…à°¯à±à°¯à°¿à°‚à°¦à°¿')),
        );
        return forExport;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            PurchaseFlowResult.cancelled => 'Payment cancel à°šà±‡à°¶à°¾à°°à±',
            PurchaseFlowResult.failed => 'Payment fail à°…à°¯à±à°¯à°¿à°‚à°¦à°¿',
            PurchaseFlowResult.billingUnavailable =>
              'Billing service à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°²à±‡à°¦à±. à°•à±Šà°¦à±à°¦à°¿à°¸à±‡à°ªà°Ÿà°¿ à°¤à°°à±à°µà°¾à°¤ à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿',
            PurchaseFlowResult.productNotFound =>
              'Subscription à°ªà±à°²à°¾à°¨à± storeà°²à±‹ à°•à°¨à°¿à°ªà°¿à°‚à°šà°²à±‡à°¦à±. supportâ€Œà°¨à°¿ à°¸à°‚à°ªà±à°°à°¦à°¿à°‚à°šà°‚à°¡à°¿',
            PurchaseFlowResult.timedOut =>
              'Payment response à°†à°²à°¸à±à°¯à°‚ à°…à°¯à±à°¯à°¿à°‚à°¦à°¿. purchase history à°šà±†à°•à± à°šà±‡à°¸à°¿ à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿',
            PurchaseFlowResult.nothingToRestore =>
              'Restore à°šà±‡à°¯à°¡à°¾à°¨à°¿à°•à°¿ purchase à°•à°¨à°¿à°ªà°¿à°‚à°šà°²à±‡à°¦à±',
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
          const SnackBar(content: Text('Purchase restore à°…à°¯à±à°¯à°¿à°‚à°¦à°¿')),
        );
        return forExport;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (restoreResult) {
            PurchaseFlowResult.billingUnavailable =>
              'Billing service à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°²à±‡à°¦à±. à°¤à°°à±à°µà°¾à°¤ à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿',
            PurchaseFlowResult.failed =>
              'Restore fail à°…à°¯à±à°¯à°¿à°‚à°¦à°¿, à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿',
            PurchaseFlowResult.cancelled => 'Restore process cancel à°…à°¯à°¿à°‚à°¦à°¿',
            PurchaseFlowResult.productNotFound =>
              'Restore à°šà±‡à°¯à°¡à°¾à°¨à°¿à°•à°¿ product details à°•à°¨à°¿à°ªà°¿à°‚à°šà°²à±‡à°¦à±',
            PurchaseFlowResult.timedOut =>
              'Restore response à°†à°²à°¸à±à°¯à°‚ à°…à°¯à°¿à°‚à°¦à°¿. à°•à±Šà°¦à±à°¦à°¿à°¸à±‡à°ªà°Ÿà°¿ à°¤à°°à±à°µà°¾à°¤ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿',
            PurchaseFlowResult.nothingToRestore =>
              'Restore à°šà±‡à°¯à°¡à°¾à°¨à°¿à°•à°¿ active plan à°•à°¨à°¿à°ªà°¿à°‚à°šà°²à±‡à°¦à±',
            PurchaseFlowResult.success => 'Purchase restore à°…à°¯à±à°¯à°¿à°‚à°¦à°¿',
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
    final bottomToolsHeight =
        _bottomBarHeight +
        (_hasSelectedPhotoLayer ? _photoControlsExtraHeight : 0);
    final topInset = _topBarHeight + _floatingBarGap;
    final bottomInset =
        _floatingBarGap +
        bottomToolsHeight +
        (_hasSelectedTextLayer && _showTextControls ? _textStyleBarHeight : 0);
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
    if (_isExporting) {
      return;
    }
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    setState(() {
      _isExporting = true;
    });

    try {
      if (format == _ExportImageFormat.pngTransparent) {
        setState(() {
          _isTransparentExportCapture = true;
        });
        await _waitForRenderedFrame();
      }
      final hasPermission = await _ensureGallerySavePermission();
      if (!hasPermission) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gallery permission ivvandi, taruvata malli export cheyyandi',
            ),
          ),
        );
        return;
      }
      final image = await _captureStageImage(
        pixelRatio: _exportPixelRatio(devicePixelRatio),
      );
      if (image == null) {
        throw Exception('Export boundary not ready');
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _exportResultMessage(finalResult, isSuccess: isSuccess),
          ),
          action: isSuccess
              ? SnackBarAction(
                  label: _isSharing ? 'Sharing...' : 'Share',
                  onPressed: _isSharing
                      ? () {}
                      : () => _shareLatestPoster(exportedBytes, format: format),
                )
              : null,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export fail à°…à°¯à±à°¯à°¿à°‚à°¦à°¿, à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _isTransparentExportCapture = false;
        });
      }
    }
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;
    if (storageStatus.isGranted ||
        photosStatus.isGranted ||
        photosStatus.isLimited) {
      return true;
    }
    final requested = await <Permission>[
      Permission.storage,
      Permission.photos,
    ].request();
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
      return 'Poster gallery à°²à±‹ save à°…à°¯à±à°¯à°¿à°‚à°¦à°¿';
    }
    final errorText = saveResult is Map
        ? (saveResult['errorMessage']?.toString() ??
              saveResult['message']?.toString() ??
              saveResult['error']?.toString() ??
              '')
        : '';
    if (errorText.toLowerCase().contains('permission')) {
      return 'Gallery permission à°‡à°µà±à°µà°‚à°¡à°¿, à°¤à°°à±à°µà°¾à°¤ à°®à°³à±à°²à±€ export à°šà±‡à°¯à°‚à°¡à°¿';
    }
    return 'Export fail à°…à°¯à±à°¯à°¿à°‚à°¦à°¿, à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿';
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
      ], text: 'Mana Poster à°¤à±‹ create à°šà±‡à°¸à°¿à°¨ à°¨à°¾ poster');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share fail à°…à°¯à±à°¯à°¿à°‚à°¦à°¿, à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿'),
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

    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(fontFamily: fontFamily);
    });
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

    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(textBackgroundColor: color);
    });
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
    setState(() {
      _layers[index] = _layers[index].copyWith(
        isTextBold: !_layers[index].isTextBold,
      );
    });
  }

  void _toggleSelectedTextItalic() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    setState(() {
      _layers[index] = _layers[index].copyWith(
        isTextItalic: !_layers[index].isTextItalic,
      );
    });
  }

  void _toggleSelectedTextUnderline() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    setState(() {
      _layers[index] = _layers[index].copyWith(
        isTextUnderline: !_layers[index].isTextUnderline,
      );
    });
  }

  void _setSelectedTextStrokeColor(Color color) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    setState(() {
      _layers[index] = _layers[index].copyWith(textStrokeColor: color);
    });
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
    setState(() {
      _layers[index] = _layers[index].copyWith(
        photoOpacity: value.clamp(0.1, 1).toDouble(),
      );
    });
  }

  void _toggleSelectedPhotoFlipHorizontal() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) return;
    setState(() {
      _layers[index] = _layers[index].copyWith(
        flipPhotoHorizontally: !_layers[index].flipPhotoHorizontally,
      );
    });
  }

  void _toggleSelectedPhotoFlipVertical() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) return;
    setState(() {
      _layers[index] = _layers[index].copyWith(
        flipPhotoVertically: !_layers[index].flipPhotoVertically,
      );
    });
  }

  void _rotateSelectedPhoto(double radians) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) return;
    final updated = Matrix4.copy(_layers[index].transform)..rotateZ(radians);
    _transformationController.value = Matrix4.copy(updated);
    setState(() {
      _layers[index] = _layers[index].copyWith(transform: updated);
    });
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

    _pushUndoSnapshot();
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

    _pushUndoSnapshot();
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
    _pushUndoSnapshot();
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
    if (_isCropMode) {
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
    });
  }

  void _handleCanvasTapDown(
    Offset localPosition,
    Rect pageRect,
    Size pageSize,
  ) {
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
        !_showVerticalSnapGuide &&
        !_showHorizontalSnapGuide) {
      return;
    }
    _transformationController.value = Matrix4.identity();
    setState(() {
      _selectedLayerId = null;
      _showTextControls = false;
      _showVerticalSnapGuide = false;
      _showHorizontalSnapGuide = false;
    });
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

    if (_showVerticalSnapGuide != shouldSnapX ||
        _showHorizontalSnapGuide != shouldSnapY) {
      setState(() {
        _showVerticalSnapGuide = shouldSnapX;
        _showHorizontalSnapGuide = shouldSnapY;
      });
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

    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(
        transform: Matrix4.copy(updated),
      );
      _isLayerInteracting = false;
      _showVerticalSnapGuide = false;
      _showHorizontalSnapGuide = false;
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
    setState(() {
      _isLayerInteracting = true;
    });
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
    setState(() {
      _isLayerInteracting = true;
    });
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
    if (_isRemovingBackground) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a photo first')),
      );
      return;
    }
    if (!_hasSelectedPhotoLayer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a photo first')),
      );
      return;
    }

    final taskId = ++_removeBackgroundTaskId;
    setState(() {
      _isRemovingBackground = true;
    });
    final layerIndex = _layers.indexWhere((item) => item.id == selectedId);
    if (layerIndex == -1) {
      if (mounted) {
        setState(() {
          _isRemovingBackground = false;
        });
      }
      return;
    }

    final layer = _layers[layerIndex];
    final sourceBytes = layer.bytes;
    if (sourceBytes == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRemovingBackground = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source photo unavailable for Remove BG')),
      );
      return;
    }
    try {
      await _backgroundRemoverInitialization;
      final result = await _backgroundRemovalService.removeBackground(
        sourceBytes,
      );
      if (!mounted || taskId != _removeBackgroundTaskId) {
        return;
      }

      _pushUndoSnapshot();
      setState(() {
        _layers[layerIndex] = _layers[layerIndex].copyWith(
          bytes: result.pngBytes,
        );
        _isRemovingBackground = false;
      });
      return;
    } catch (error) {
      if (!mounted || taskId != _removeBackgroundTaskId) {
        return;
      }
      setState(() {
        _isRemovingBackground = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Remove BG failed: ${error.toString()}'),
        ),
      );
      return;
    }
  }

  Future<void> _handleMagicToolTap() async {
    final selectedId = _selectedLayerId;
    if (selectedId == null || !_hasSelectedPhotoLayer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a photo first')),
      );
      return;
    }

    final layerIndex = _layers.indexWhere((item) => item.id == selectedId);
    if (layerIndex == -1) {
      return;
    }
    final layer = _layers[layerIndex];
    final currentBytes = layer.bytes;
    final originalBytes = layer.originalPhotoBytes;
    Uint8List? sessionBytes;
    if (currentBytes != null && img.decodeImage(currentBytes) != null) {
      sessionBytes = currentBytes;
    } else if (originalBytes != null && img.decodeImage(originalBytes) != null) {
      sessionBytes = originalBytes;
    }
    if (sessionBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected image could not be loaded')),
      );
      return;
    }

    final refinedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        builder: (BuildContext context) => _MagicToolScreen(
          currentBytes: sessionBytes!,
          originalBytes: originalBytes ?? sessionBytes,
        ),
      ),
    );

    if (!mounted || refinedBytes == null) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      _layers[layerIndex] = _layers[layerIndex].copyWith(bytes: refinedBytes);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Magic Tool apply ayyindi')));
  }

  Future<void> _handleCropPhotoTap() async {
    final selectedId = _selectedLayerId;
    if (selectedId == null || !_hasSelectedPhotoLayer || _isCropMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop kosam photo layer select cheyyandi'),
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
    if (!_isCropMode) {
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
    if (!_isCropMode) {
      return;
    }
    setState(() {
      _cropTransformationController.value = Matrix4.identity();
      _cropSessionAspectRatio = _cropSessionInitialAspectRatio;
    });
  }

  void _setCropAspectRatio(double? ratio) {
    if (!_isCropMode) {
      return;
    }
    setState(() {
      _cropSessionAspectRatio = ratio;
    });
  }

  Future<void> _applyCropSession() async {
    final layerId = _cropSessionLayerId;
    final sessionBytes = _cropSessionImageBytes;
    if (!_isCropMode || layerId == null || sessionBytes == null) {
      return;
    }
    final boundary =
        _cropBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null || !mounted) {
      return;
    }

    final croppedBytes = byteData.buffer.asUint8List();
    final newAspectRatio = await compute(
      _extractImageAspectRatio,
      croppedBytes,
    );
    if (!mounted) {
      return;
    }
    final layerIndex = _layers.indexWhere((item) => item.id == layerId);
    if (layerIndex == -1) {
      _discardCropSession();
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      _layers[layerIndex] = _layers[layerIndex].copyWith(
        bytes: croppedBytes,
        photoAspectRatio: newAspectRatio,
      );
      _isCropMode = false;
      _cropSessionLayerId = null;
      _cropSessionImageBytes = null;
      _cropSessionAspectRatio = null;
      _cropSessionInitialAspectRatio = null;
      _cropTransformationController.value = Matrix4.identity();
    });
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

    _pushUndoSnapshot();
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

    _pushUndoSnapshot();
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

    _pushUndoSnapshot();
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

    _pushUndoSnapshot();
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

    _pushUndoSnapshot();
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
                          'Layers',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
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
                                ? Image.memory(
                                    layer.bytes!,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.low,
                                    cacheWidth: 96,
                                  )
                                : layer.isText
                                ? const Icon(
                                    Icons.text_fields_rounded,
                                    color: Color(0xFF334155),
                                  )
                                : Center(
                                    child: _ImageEditorScreenState
                                        ._buildStickerVisual(
                                          layer.sticker,
                                          fontSize: 22,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.low,
                                        ),
                                  ),
                          ),
                          title: Text(
                            layer.isPhoto
                                ? 'Photo ${index + 1}'
                                : layer.isText
                                ? 'Text ${index + 1}'
                                : 'Sticker ${index + 1}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: isSelected
                              ? const Text(
                                  'Selected',
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
                                  tooltip: 'Delete',
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
      backgroundColor: const Color(0xFFF7F8FC),
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
                : _bottomBarHeight +
                      (_hasSelectedPhotoLayer ? _photoControlsExtraHeight : 0);
            final reservedTopInset = _topBarHeight + _floatingBarGap;
            final reservedBottomInset =
                _floatingBarGap +
                bottomToolsHeight +
                (!_isCropMode && _hasSelectedTextLayer && _showTextControls
                    ? _textStyleBarHeight
                    : 0);
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
                      onCanvasTapDown: _isCropMode
                          ? (
                              Offset _,
                              Rect pageRectIgnored,
                              Size pageSizeIgnored,
                            ) {}
                          : _handleCanvasTapDown,
                      onCanvasTap: _isCropMode ? () {} : _clearSelection,
                      showCanvasBackground: !_isTransparentExportCapture,
                      showSelectionDecorations:
                          !_isCropMode && !_isExporting && !_isCapturingStage,
                      showPageFramePreview: !_isExporting && !_isCapturingStage,
                      showVerticalSnapGuide:
                          !_isCropMode &&
                          !_isCapturingStage &&
                          _showVerticalSnapGuide,
                      showHorizontalSnapGuide:
                          !_isCropMode &&
                          !_isCapturingStage &&
                          _showHorizontalSnapGuide,
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
                  left: 12,
                  right: 12,
                  top: _floatingBarGap,
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
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: bottomToolsHeight,
                  child: _TextStyleBar(
                    visible:
                        !_isCropMode &&
                        _hasSelectedTextLayer &&
                        _showTextControls,
                    selectedLayer: _selectedLayer,
                    colors: _textColors,
                    backgroundColors: editorBackgroundColors,
                    gradients: _textGradients,
                    onEditTap: _openTextEditSheet,
                    onFontsTap: _openFontPickerScreen,
                    onColorSelected: _setSelectedTextColor,
                    onBackgroundColorSelected: _setSelectedTextBackgroundColor,
                    onAlignSelected: _setSelectedTextAlignment,
                    onGradientSelected: _setSelectedTextGradient,
                    onFontSizeChanged: _setSelectedTextFontSize,
                    onFontSizeChangeStart: _handleTextFontSizeEditStart,
                    onFontSizeChangeEnd: _handleTextFontSizeEditEnd,
                    onBackgroundOpacityChanged:
                        _setSelectedTextBackgroundOpacity,
                    onBackgroundRadiusChanged: _setSelectedTextBackgroundRadius,
                    onLineHeightChanged: _setSelectedTextLineHeight,
                    onLetterSpacingChanged: _setSelectedTextLetterSpacing,
                    onShadowOpacityChanged: _setSelectedTextShadowOpacity,
                    onShadowBlurChanged: _setSelectedTextShadowBlur,
                    onShadowOffsetYChanged: _setSelectedTextShadowOffsetY,
                    onBoldToggle: _toggleSelectedTextBold,
                    onItalicToggle: _toggleSelectedTextItalic,
                    onUnderlineToggle: _toggleSelectedTextUnderline,
                    onStrokeColorSelected: _setSelectedTextStrokeColor,
                    onStrokeWidthChanged: _setSelectedTextStrokeWidth,
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: _floatingBarGap,
                  child: _isCropMode
                      ? _CropBottomToolsBar(
                          height: bottomToolsHeight,
                          onBack: _discardCropSession,
                          onReset: _resetCropSession,
                          onApply: _applyCropSession,
                          selectedAspectRatio: _cropSessionAspectRatio,
                          onAspectRatioChanged: _setCropAspectRatio,
                        )
                      : _hasSelectedTextLayer
                      ? _TextBottomToolsBar(
                          height: bottomToolsHeight,
                          showOptionsSelected: _showTextControls,
                          onEditTap: _openTextEditSheet,
                          onFontsTap: _openFontPickerScreen,
                          onToggleOptionsTap: () {
                            setState(() {
                              _showTextControls = !_showTextControls;
                            });
                          },
                        )
                      : _BottomToolsBar(
                          height: bottomToolsHeight,
                          onAddPhotoTap: _handleAddPhoto,
                          onAddTextTap: _handleTextToolTap,
                          onStickerTap: _openStickerPanel,
                          onBackgroundTap: _openBackgroundPanel,
                          onLayersTap: _openLayersScreen,
                          onCropPhotoTap: _handleCropPhotoTap,
                          onRemoveBackgroundTap: _handleRemoveBackgroundTap,
                          onMagicToolTap: _handleMagicToolTap,
                          canCropPhoto: _hasSelectedPhotoLayer,
                          canRemoveBackground:
                              _hasSelectedPhotoLayer && !_isRemovingBackground,
                          canMagicTool:
                              _hasSelectedPhotoLayer && !_isRemovingBackground,
                          isRemovingBackground: _isRemovingBackground,
                          selectedPhotoLayer: _hasSelectedPhotoLayer
                              ? _selectedLayer
                              : null,
                          onOpacityChanged: _setSelectedPhotoOpacity,
                          onFlipHorizontalTap:
                              _toggleSelectedPhotoFlipHorizontal,
                          onFlipVerticalTap: _toggleSelectedPhotoFlipVertical,
                          onRotateLeftTap: () =>
                              _rotateSelectedPhoto(-math.pi / 2),
                          onRotateRightTap: () =>
                              _rotateSelectedPhoto(math.pi / 2),
                        ),
                ),
                if (_isRemovingBackground)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('AI is removing background...'),
                            ],
                          ),
                        ),
                      ),
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
    required this.showSelectionDecorations,
    required this.showPageFramePreview,
    required this.showVerticalSnapGuide,
    required this.showHorizontalSnapGuide,
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
  final bool showSelectionDecorations;
  final bool showPageFramePreview;
  final bool showVerticalSnapGuide;
  final bool showHorizontalSnapGuide;

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
                                      colors: editorBackgroundGradients[canvasBackgroundGradientIndex],
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
                            final layerChild = layer.isPhoto
                                ? SizedBox(
                                    width: photoSize.width,
                                    height: photoSize.height,
                                    child: Opacity(
                                      opacity: layer.photoOpacity.clamp(0.1, 1),
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.diagonal3Values(
                                          layer.flipPhotoHorizontally ? -1 : 1,
                                          layer.flipPhotoVertically ? -1 : 1,
                                          1,
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: <Widget>[
                                            AnimatedSwitcher(
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
                                              child: Image.memory(
                                                layer.bytes!,
                                                key: ValueKey<String>(
                                                  _photoBytesSignature(
                                                    layer.bytes!,
                                                  ),
                                                ),
                                                fit: BoxFit.contain,
                                                gaplessPlayback: true,
                                                filterQuality:
                                                    FilterQuality.medium,
                                                cacheWidth: isSelected
                                                    ? photoCacheWidth
                                                    : photoCacheWidth ??
                                                          unselectedPhotoCacheWidth,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                    layer.sticker ?? '⭐',
                                    style: TextStyle(fontSize: layer.fontSize),
                                  );
                            final stickerAsset =
                                _ImageEditorScreenState._isImageLikeSticker(
                                  layer.sticker,
                                );
                            final stickerOrTextChild = layer.isSticker &&
                                    stickerAsset
                                ? SizedBox(
                                    width: layerSize.width,
                                    height: layerSize.height,
                                    child: _ImageEditorScreenState
                                        ._buildStickerVisual(
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
                          layer.sticker ?? 'â­',
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

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.selectedLayer == null) {
      return const SizedBox.shrink();
    }
    final layer = widget.selectedLayer!;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xD8E7EDF7)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 12,
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
                  label: 'Edit',
                  onTap: widget.onEditTap,
                ),
                const SizedBox(width: 6),
                _TextQuickActionButton(
                  icon: Icons.font_download_rounded,
                  label: 'Fonts',
                  onTap: widget.onFontsTap,
                ),
                const SizedBox(width: 8),
                _TextTabChip(
                  label: 'Style',
                  selected: _activeTab == _TextToolTab.style,
                  onTap: () => setState(() => _activeTab = _TextToolTab.style),
                ),
                _TextTabChip(
                  label: 'Background',
                  selected: _activeTab == _TextToolTab.background,
                  onTap: () =>
                      setState(() => _activeTab = _TextToolTab.background),
                ),
                _TextTabChip(
                  label: 'Effects',
                  selected: _activeTab == _TextToolTab.effects,
                  onTap: () =>
                      setState(() => _activeTab = _TextToolTab.effects),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xB8F8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xCFE2E8F0)),
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
                          label: 'Size',
                          value: layer.fontSize.clamp(18, 96).toDouble(),
                          min: 18,
                          max: 96,
                          width: 148,
                          valueText: layer.fontSize.toStringAsFixed(0),
                          onChangeStart: widget.onFontSizeChangeStart,
                          onChanged: widget.onFontSizeChanged,
                          onChangeEnd: widget.onFontSizeChangeEnd,
                        ),
                        _CompactLabeledSlider(
                          label: 'Line',
                          value: layer.textLineHeight
                              .clamp(0.8, 2.2)
                              .toDouble(),
                          min: 0.8,
                          max: 2.2,
                          width: 136,
                          onChanged: widget.onLineHeightChanged,
                        ),
                        _CompactLabeledSlider(
                          label: 'Letter',
                          value: layer.textLetterSpacing
                              .clamp(-1, 12)
                              .toDouble(),
                          min: -1,
                          max: 12,
                          width: 144,
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
                          label: 'Opacity',
                          value: layer.textBackgroundOpacity
                              .clamp(0, 1)
                              .toDouble(),
                          min: 0,
                          max: 1,
                          width: 150,
                          onChanged: widget.onBackgroundOpacityChanged,
                        ),
                        _CompactLabeledSlider(
                          label: 'Curve',
                          value: layer.textBackgroundRadius
                              .clamp(0, 40)
                              .toDouble(),
                          min: 0,
                          max: 40,
                          width: 150,
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
                          label: 'Stroke',
                          value: layer.textStrokeWidth.clamp(0, 8).toDouble(),
                          min: 0,
                          max: 8,
                          width: 144,
                          onChanged: widget.onStrokeWidthChanged,
                        ),
                        _CompactLabeledSlider(
                          label: 'Shadow',
                          value: layer.textShadowOpacity.clamp(0, 1).toDouble(),
                          min: 0,
                          max: 1,
                          width: 146,
                          onChanged: widget.onShadowOpacityChanged,
                        ),
                        _CompactLabeledSlider(
                          label: 'Blur',
                          value: layer.textShadowBlur.clamp(0, 24).toDouble(),
                          min: 0,
                          max: 24,
                          width: 136,
                          onChanged: widget.onShadowBlurChanged,
                        ),
                        _CompactLabeledSlider(
                          label: 'Offset',
                          value: layer.textShadowOffsetY
                              .clamp(0, 20)
                              .toDouble(),
                          min: 0,
                          max: 20,
                          width: 144,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: const Color(0xFF0F172A)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
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

class _CompactLabeledSlider extends StatelessWidget {
  const _CompactLabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.width,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.valueText,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double width;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                valueText ?? value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChangeStart: onChangeStart,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
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
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: const Color(0x1A2563EB),
        highlightColor: const Color(0x0F2563EB),
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 34,
          height: 30,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDCEBFF) : const Color(0xFFFDFEFF),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? const Color(0xFFC4DBFF)
                  : const Color(0xFFE7EDF5),
            ),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x122563EB),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1E293B)),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF2FF) : const Color(0xFFFDFEFF),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD5E4FF)
                  : const Color(0xFFE7EDF5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF0F172A),
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
  });

  final String label;
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
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 3),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Fonts')),
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
                  hintText: 'Search fonts',
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
                  ? const Center(
                      child: Text(
                        'Fonts dorakaledu',
                        style: TextStyle(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Text'),
        actions: <Widget>[
          TextButton(onPressed: _handleSave, child: const Text('Save')),
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
          decoration: const InputDecoration(
            hintText: 'Type your text',
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(20),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Background')),
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
              title: const Text('Background Image'),
              subtitle: const Text('Apply gallery image to poster paper only'),
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
                child: Text(_hasSelectedImage ? 'Change' : 'Import'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Solid Colors',
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
              'Gradients',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drafts'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await widget.onSaveCurrentDraft();
              await _loadDrafts();
            },
            child: const Text('Save Current'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _draftFiles.isEmpty
            ? const Center(child: Text('No saved drafts'))
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
      return 'Photo ${index + 1}';
    }
    if (layer.isText) {
      return 'Text ${index + 1}';
    }
    return 'Sticker ${index + 1}';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Layers')),
      body: SafeArea(
        child: widget.layers.isEmpty
            ? const Center(child: Text('No layers available'))
            : ReorderableListView.builder(
                itemCount: widget.layers.length,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                onReorder: (oldIndex, newIndex) {
                  widget.onReorderLayers(oldIndex, newIndex);
                  setState(() {});
                },
                itemBuilder: (BuildContext context, int index) {
                  final layer = widget.layers[index];
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
                                          ? 'Hidden'
                                          : layer.isLocked
                                          ? 'Locked'
                                          : 'Selected',
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
                              tooltip: layer.isHidden ? 'Show' : 'Hide',
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
                              tooltip: layer.isLocked ? 'Unlock' : 'Lock',
                              onTap: () {
                                widget.onToggleLayerLock(layer.id);
                                setState(() {});
                              },
                            ),
                            _LayerActionButton(
                              icon: Icons.delete_outline_rounded,
                              tooltip: 'Delete',
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
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFF9FBFF).withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xEEF0F4FA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: _withHaptic(() => Navigator.of(context).maybePop()),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: 'Back',
            ),
            const SizedBox(width: 2),
            SizedBox(
              width: 138,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Image Editor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Text(
                    'Poster workspace',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            _TopActionButton(label: 'Undo', onTap: canUndo ? onUndoTap : null),
            const SizedBox(width: 4),
            _TopActionButton(label: 'Redo', onTap: canRedo ? onRedoTap : null),
            const SizedBox(width: 4),
            _TopActionButton(label: 'Drafts', onTap: onDraftsTap),
            const SizedBox(width: 4),
            _TopActionButton(
              label: isExporting ? 'Saving...' : 'Export',
              onTap: isExporting ? null : onExportTap,
            ),
            IconButton(
              onPressed: _withHaptic(canSendBack ? onSendBackTap : null),
              icon: const Icon(Icons.flip_to_back_rounded),
              tooltip: 'Send back',
            ),
            IconButton(
              onPressed: _withHaptic(canBringFront ? onBringFrontTap : null),
              icon: const Icon(Icons.flip_to_front_rounded),
              tooltip: 'Bring front',
            ),
            IconButton(
              onPressed: _withHaptic(canDuplicate ? onDuplicateTap : null),
              icon: const Icon(Icons.control_point_duplicate_rounded),
              tooltip: 'Duplicate selected',
            ),
            IconButton(
              onPressed: _withHaptic(canDelete ? onDeleteTap : null),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete selected',
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
    required this.onCropPhotoTap,
    required this.onRemoveBackgroundTap,
    required this.onMagicToolTap,
    required this.canCropPhoto,
    required this.canRemoveBackground,
    required this.canMagicTool,
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
  final VoidCallback onCropPhotoTap;
  final VoidCallback onRemoveBackgroundTap;
  final VoidCallback onMagicToolTap;
  final bool canCropPhoto;
  final bool canRemoveBackground;
  final bool canMagicTool;
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
        (label: 'Crop', icon: Icons.crop_rounded),
        (label: 'Remove BG', icon: Icons.auto_fix_high_outlined),
        (label: 'Magic Tool', icon: Icons.auto_fix_normal_rounded),
      ];

  @override
  Widget build(BuildContext context) {
    final photoLayer = selectedPhotoLayer;
    final hasPhotoControls = photoLayer != null && photoLayer.isPhoto;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.94),
            const Color(0xFFF8FBFF).withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xEEF0F4FA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          if (hasPhotoControls) ...<Widget>[
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
                  selected: photoLayer.flipPhotoHorizontally,
                  onTap: onFlipHorizontalTap,
                ),
                _AlignChip(
                  icon: Icons.flip_camera_android_rounded,
                  selected: photoLayer.flipPhotoVertically,
                  onTap: onFlipVerticalTap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LabeledSlider(
                    label: 'Opacity',
                    value: photoLayer.photoOpacity.clamp(0.1, 1).toDouble(),
                    min: 0.1,
                    max: 1,
                    onChanged: onOpacityChanged,
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 6),
              height: 1,
              color: const Color(0xFFE9EEF6),
            ),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tools.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final tool = _tools[index];
                return _ToolItem(
                  label: index == 6 && isRemovingBackground
                      ? 'Removing...'
                      : tool.label,
                  icon: tool.icon,
                  onTap: switch (index) {
                    0 => onAddPhotoTap,
                    1 => onAddTextTap,
                    2 => onStickerTap,
                    3 => onBackgroundTap,
                    4 => onLayersTap,
                    5 => canCropPhoto ? onCropPhotoTap : null,
                    6 => canRemoveBackground ? onRemoveBackgroundTap : null,
                    7 => canMagicTool ? onMagicToolTap : null,
                    _ => () {},
                  },
                  enabled: switch (index) {
                    5 => canCropPhoto,
                    6 => canRemoveBackground,
                    7 => canMagicTool,
                    _ => true,
                  },
                );
              },
            ),
          ),
        ],
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
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.94),
            const Color(0xFFF8FBFF).withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xEEF0F4FA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _TextModeToolItem(
            icon: Icons.edit_rounded,
            label: 'Edit',
            onTap: onEditTap,
          ),
          const SizedBox(width: 8),
          _TextModeToolItem(
            icon: Icons.font_download_rounded,
            label: 'Fonts',
            onTap: onFontsTap,
          ),
          const SizedBox(width: 8),
          _TextModeToolItem(
            icon: Icons.tune_rounded,
            label: 'Options',
            selected: showOptionsSelected,
            onTap: onToggleOptionsTap,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xE8F8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'Text tools',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
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
    required this.selectedAspectRatio,
    required this.onAspectRatioChanged,
  });

  final double height;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onApply;
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
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FBFF).withValues(alpha: 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xEEF0F4FA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _TopActionButton(label: 'Back', onTap: onBack),
          const SizedBox(width: 6),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _CropAspectChip(
                  label: 'Free',
                  selected: _isSelected(null),
                  onTap: () => onAspectRatioChanged(null),
                ),
                _CropAspectChip(
                  label: '1:1',
                  selected: _isSelected(1),
                  onTap: () => onAspectRatioChanged(1),
                ),
                _CropAspectChip(
                  label: '4:5',
                  selected: _isSelected(4 / 5),
                  onTap: () => onAspectRatioChanged(4 / 5),
                ),
                _CropAspectChip(
                  label: '16:9',
                  selected: _isSelected(16 / 9),
                  onTap: () => onAspectRatioChanged(16 / 9),
                ),
                _CropAspectChip(
                  label: '9:16',
                  selected: _isSelected(9 / 16),
                  onTap: () => onAspectRatioChanged(9 / 16),
                ),
                _CropAspectChip(
                  label: 'Reset',
                  selected: false,
                  onTap: onReset,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _TopActionButton(label: 'Apply', onTap: onApply),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(99),
        child: Ink(
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
    final items = _filteredItems;
    return Scaffold(
      appBar: AppBar(title: const Text('Elements')),
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
                  hintText: 'Search elements',
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
                                child: _ImageEditorScreenState
                                        ._isImageLikeSticker(sticker)
                                    ? Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: _ImageEditorScreenState
                                            ._buildStickerVisual(
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
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: const Color(0x1A2563EB),
        highlightColor: const Color(0x0F2563EB),
        borderRadius: BorderRadius.circular(99),
        child: Ink(
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

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!.call();
            },
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        foregroundColor: const Color(0xFF334155),
        backgroundColor: onTap == null
            ? const Color(0xFFF4F6FA)
            : const Color(0xFFFDFEFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE3EAF3)),
        ),
        textStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
      child: Text(label),
    );
  }
}

class _MagicToolScreen extends StatefulWidget {
  const _MagicToolScreen({
    required this.currentBytes,
    required this.originalBytes,
  });

  final Uint8List currentBytes;
  final Uint8List originalBytes;

  @override
  State<_MagicToolScreen> createState() => _MagicToolScreenState();
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

class _MagicToolScreenState extends State<_MagicToolScreen> {
  final OfflineBackgroundRemovalService _service =
      const OfflineBackgroundRemovalService();

  late Uint8List _workingBytes = Uint8List.fromList(widget.currentBytes);
  late final Uint8List _originalBytes = Uint8List.fromList(widget.originalBytes);
  final List<Uint8List> _undoHistory = <Uint8List>[];
  final List<Uint8List> _redoHistory = <Uint8List>[];
  BackgroundRefineMode _mode = BackgroundRefineMode.erase;
  double _brushRadius = 26;
  double _brushSoftness = 0.45;
  double _brushStrength = 0.9;
  double _edgeSmoothStrength = 2;
  double _featherStrength = 2;
  double _expandShrinkAmount = 1;
  bool _isApplying = false;
  bool _showOriginalPreview = false;
  Rect? _imageRect;
  Size? _imagePixelSize;
  late Size? _workingPixelSize = _decodePixelSize(_workingBytes);
  late final Size? _originalPixelSize = _decodePixelSize(_originalBytes);
  final List<Offset> _activeStroke = <Offset>[];
  int _strokeRevision = 0;

  bool get _canUndo => _undoHistory.isNotEmpty;
  bool get _canRedo => _redoHistory.isNotEmpty;
  Uint8List get _displayBytes => _showOriginalPreview ? _originalBytes : _workingBytes;
  Size? get _displayPixelSize =>
      _showOriginalPreview ? _originalPixelSize : _workingPixelSize;

  static Size? _decodePixelSize(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      return null;
    }
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }

  void _pushMagicUndo() {
    _undoHistory.add(_workingBytes);
    if (_undoHistory.length > 20) {
      _undoHistory.removeAt(0);
    }
    _redoHistory.clear();
  }

  Future<void> _applyActiveStroke() async {
    if (_activeStroke.isEmpty || _isApplying || _imagePixelSize == null) {
      return;
    }

    final stroke = List<Offset>.from(_activeStroke);
    final brushRadius = _brushRadius;
    final brushSoftness = _brushSoftness;
    final brushStrength = _brushStrength;
    setState(() {
      _activeStroke.clear();
      _strokeRevision++;
      _isApplying = true;
    });

    try {
      _pushMagicUndo();
      final refinedBytes = await _service.applyBrushEdits(
        currentBytes: _workingBytes,
        originalBytes: widget.originalBytes,
        mode: _mode,
        points: stroke,
        brushRadius: brushRadius,
        softness: brushSoftness,
        strength: brushStrength,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _workingBytes = refinedBytes;
        _workingPixelSize = _decodePixelSize(refinedBytes) ?? _workingPixelSize;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  void _handleMagicUndo() {
    if (!_canUndo || _isApplying) {
      return;
    }
    setState(() {
      _redoHistory.add(_workingBytes);
      _workingBytes = _undoHistory.removeLast();
      _workingPixelSize = _decodePixelSize(_workingBytes) ?? _workingPixelSize;
    });
  }

  void _handleMagicRedo() {
    if (!_canRedo || _isApplying) {
      return;
    }
    setState(() {
      _undoHistory.add(_workingBytes);
      _workingBytes = _redoHistory.removeLast();
      _workingPixelSize = _decodePixelSize(_workingBytes) ?? _workingPixelSize;
    });
  }

  Future<void> _applyEdgeSmooth() async {
    if (_isApplying) {
      return;
    }

    setState(() {
      _isApplying = true;
    });

    try {
      _pushMagicUndo();
      final refinedBytes = await _service.applyEdgeSmooth(
        currentBytes: _workingBytes,
        strength: _edgeSmoothStrength,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _workingBytes = refinedBytes;
        _workingPixelSize = _decodePixelSize(refinedBytes) ?? _workingPixelSize;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _applyFeather() async {
    if (_isApplying) {
      return;
    }

    setState(() {
      _isApplying = true;
    });

    try {
      _pushMagicUndo();
      final refinedBytes = await _service.applyEdgeFeather(
        currentBytes: _workingBytes,
        strength: _featherStrength,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _workingBytes = refinedBytes;
        _workingPixelSize = _decodePixelSize(refinedBytes) ?? _workingPixelSize;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _applyExpandShrink(bool expand) async {
    if (_isApplying) {
      return;
    }

    setState(() {
      _isApplying = true;
    });

    try {
      _pushMagicUndo();
      final refinedBytes = await _service.applyMaskExpansion(
        currentBytes: _workingBytes,
        amount: expand ? _expandShrinkAmount : -_expandShrinkAmount,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _workingBytes = refinedBytes;
        _workingPixelSize = _decodePixelSize(refinedBytes) ?? _workingPixelSize;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  void _resetMagicImage() {
    if (_isApplying) {
      return;
    }
    setState(() {
      _workingBytes = widget.currentBytes;
      _workingPixelSize = _decodePixelSize(widget.currentBytes) ?? _workingPixelSize;
      _undoHistory.clear();
      _redoHistory.clear();
      _activeStroke.clear();
      _strokeRevision++;
    });
  }

  Offset? _toImageSpace(Offset globalPosition) {
    final rect = _imageRect;
    final imagePixelSize = _imagePixelSize;
    if (rect == null ||
        imagePixelSize == null ||
        !rect.contains(globalPosition)) {
      return null;
    }

    final normalizedX = ((globalPosition.dx - rect.left) / rect.width).clamp(
      0.0,
      1.0,
    );
    final normalizedY = ((globalPosition.dy - rect.top) / rect.height).clamp(
      0.0,
      1.0,
    );
    return Offset(
      normalizedX * imagePixelSize.width,
      normalizedY * imagePixelSize.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        foregroundColor: Colors.white,
        title: const Text('Magic Tool'),
        leading: IconButton(
          onPressed: _isApplying ? null : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _canUndo && !_isApplying ? _handleMagicUndo : null,
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo',
          ),
          IconButton(
            onPressed: _canRedo && !_isApplying ? _handleMagicRedo : null,
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'Redo',
          ),
          IconButton(
            onPressed: _isApplying ? null : _resetMagicImage,
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset',
          ),
          TextButton(
            onPressed: _isApplying
                ? null
                : () => Navigator.of(context).pop(_workingBytes),
            child: const Text('Apply'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final previewBytes = _displayBytes;
                  final previewPixelSize = _displayPixelSize;
                  if (previewPixelSize == null) {
                    return const Center(
                      child: Text(
                        'Selected image preview load kaaledu',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final rawWidth = previewPixelSize.width;
                  final rawHeight = previewPixelSize.height;
                  final scale = math.min(
                    constraints.maxWidth / rawWidth,
                    constraints.maxHeight / rawHeight,
                  );
                  final displayWidth = rawWidth * scale;
                  final displayHeight = rawHeight * scale;
                  final left = (constraints.maxWidth - displayWidth) / 2;
                  final top = (constraints.maxHeight - displayHeight) / 2;
                  _imageRect = Rect.fromLTWH(
                    left,
                    top,
                    displayWidth,
                    displayHeight,
                  );
                  _imagePixelSize = previewPixelSize;

                  return Center(
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fromRect(
                            rect: _imageRect!,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0x0DFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0x22334155),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  previewBytes,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onPanStart: _isApplying
                                  ? null
                                  : (details) {
                                      final point = _toImageSpace(
                                        details.localPosition,
                                      );
                                      if (point == null) {
                                        return;
                                      }
                                      setState(() {
                                        _activeStroke
                                          ..clear()
                                          ..add(point);
                                        _strokeRevision++;
                                      });
                                    },
                              onPanUpdate: _isApplying
                                  ? null
                                  : (details) {
                                      final point = _toImageSpace(
                                        details.localPosition,
                                      );
                                      if (point == null) {
                                        return;
                                      }
                                      setState(() {
                                        _activeStroke.add(point);
                                        _strokeRevision++;
                                      });
                                    },
                              onPanEnd: _isApplying
                                  ? null
                                  : (_) {
                                      _applyActiveStroke();
                                    },
                              onPanCancel: _isApplying
                                  ? null
                                  : _applyActiveStroke,
                              child: CustomPaint(
                                painter: _BrushPreviewPainter(
                                  imageRect: _imageRect,
                                  imagePixelSize: _imagePixelSize,
                                  points: _activeStroke,
                                  strokeRevision: _strokeRevision,
                                  brushRadius: _brushRadius,
                                  brushSoftness: _brushSoftness,
                                  brushStrength: _brushStrength,
                                  mode: _mode,
                                ),
                              ),
                            ),
                          ),
                          if (_isApplying)
                            Positioned.fill(
                              child: ColoredBox(
                                color: Colors.black.withValues(alpha: 0.18),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              color: const Color(0xFF111827),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onLongPressStart: (_) {
                          setState(() {
                            _showOriginalPreview = true;
                          });
                        },
                        onLongPressEnd: (_) {
                          setState(() {
                            _showOriginalPreview = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            _showOriginalPreview ? 'Before' : 'Hold: Before',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SegmentedButton<BackgroundRefineMode>(
                          segments: const <ButtonSegment<BackgroundRefineMode>>[
                            ButtonSegment<BackgroundRefineMode>(
                              value: BackgroundRefineMode.erase,
                              label: Text('Erase'),
                              icon: Icon(Icons.remove_circle_outline_rounded),
                            ),
                            ButtonSegment<BackgroundRefineMode>(
                              value: BackgroundRefineMode.restore,
                              label: Text('Restore'),
                              icon: Icon(Icons.restore_rounded),
                            ),
                          ],
                          selected: <BackgroundRefineMode>{_mode},
                          onSelectionChanged: _isApplying
                              ? null
                              : (values) {
                                  setState(() {
                                    _mode = values.first;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Brush Size',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _brushRadius,
                          min: 8,
                          max: 72,
                          onChanged: _isApplying
                              ? null
                              : (value) {
                                  setState(() {
                                    _brushRadius = value;
                                  });
                                },
                        ),
                      ),
                      Text(
                        _brushRadius.round().toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Softness',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _brushSoftness,
                          min: 0,
                          max: 1,
                          onChanged: _isApplying
                              ? null
                              : (value) {
                                  setState(() {
                                    _brushSoftness = value;
                                  });
                                },
                        ),
                      ),
                      Text(
                        '${(_brushSoftness * 100).round()}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Strength',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _brushStrength,
                          min: 0.1,
                          max: 1,
                          onChanged: _isApplying
                              ? null
                              : (value) {
                                  setState(() {
                                    _brushStrength = value;
                                  });
                                },
                        ),
                      ),
                      Text(
                        '${(_brushStrength * 100).round()}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Edge Smooth',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _edgeSmoothStrength,
                          min: 1,
                          max: 6,
                          divisions: 5,
                          onChanged: _isApplying
                              ? null
                              : (value) {
                                  setState(() {
                                    _edgeSmoothStrength = value;
                                  });
                                },
                        ),
                      ),
                      Text(
                        _edgeSmoothStrength.round().toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isApplying ? null : _applyEdgeSmooth,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Feather',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _featherStrength,
                          min: 1,
                          max: 6,
                          divisions: 5,
                          onChanged: _isApplying
                              ? null
                              : (value) {
                                  setState(() {
                                    _featherStrength = value;
                                  });
                                },
                        ),
                      ),
                      Text(
                        _featherStrength.round().toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isApplying ? null : _applyFeather,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Expand/Shrink',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _expandShrinkAmount,
                          min: 1,
                          max: 8,
                          divisions: 7,
                          onChanged: _isApplying
                              ? null
                              : (value) {
                                  setState(() {
                                    _expandShrinkAmount = value;
                                  });
                                },
                        ),
                      ),
                      Text(
                        _expandShrinkAmount.round().toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isApplying
                              ? null
                              : () => _applyExpandShrink(false),
                          child: const Text('Shrink'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isApplying
                              ? null
                              : () => _applyExpandShrink(true),
                          child: const Text('Expand'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isApplying
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isApplying ? null : _resetMagicImage,
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isApplying
                              ? null
                              : () => Navigator.of(context).pop(_workingBytes),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrushPreviewPainter extends CustomPainter {
  const _BrushPreviewPainter({
    required this.imageRect,
    required this.imagePixelSize,
    required this.points,
    required this.strokeRevision,
    required this.brushRadius,
    required this.brushSoftness,
    required this.brushStrength,
    required this.mode,
  });

  final Rect? imageRect;
  final Size? imagePixelSize;
  final List<Offset> points;
  final int strokeRevision;
  final double brushRadius;
  final double brushSoftness;
  final double brushStrength;
  final BackgroundRefineMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = imageRect;
    final pixelSize = imagePixelSize;
    if (rect == null || pixelSize == null || points.isEmpty) {
      return;
    }

    final scaleX = rect.width / pixelSize.width;
    final scaleY = rect.height / pixelSize.height;
    final scale = math.min(scaleX, scaleY);
    final radius = brushRadius * scale;
    final innerRadius = radius * (1 - brushSoftness.clamp(0.0, 1.0));
    final color = mode == BackgroundRefineMode.erase
        ? const Color(0x66EF4444)
        : const Color(0x663B82F6);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(radius * 2 * brushStrength.clamp(0.1, 1.0), 1)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final displayPoint = Offset(
        rect.left + ((point.dx / pixelSize.width) * rect.width),
        rect.top + ((point.dy / pixelSize.height) * rect.height),
      );
      if (i == 0) {
        path.moveTo(displayPoint.dx, displayPoint.dy);
      } else {
        path.lineTo(displayPoint.dx, displayPoint.dy);
      }
    }
    canvas.drawPath(path, paint);

    final last = points.last;
    final displayLast = Offset(
      rect.left + ((last.dx / pixelSize.width) * rect.width),
      rect.top + ((last.dy / pixelSize.height) * rect.height),
    );
    canvas.drawCircle(
      displayLast,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      displayLast,
      innerRadius.clamp(0.0, radius),
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _BrushPreviewPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect ||
        oldDelegate.imagePixelSize != imagePixelSize ||
        oldDelegate.strokeRevision != strokeRevision ||
        oldDelegate.brushRadius != brushRadius ||
        oldDelegate.brushSoftness != brushSoftness ||
        oldDelegate.brushStrength != brushStrength ||
        oldDelegate.mode != mode ||
        oldDelegate.points != points;
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final iconTone = enabled
        ? const Color(0xFF1E3A8A)
        : const Color(0xFF94A3B8);
    final labelTone = enabled
        ? const Color(0xFF334155)
        : const Color(0xFF94A3B8);
    return InkWell(
      onTap: !enabled || onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!.call();
            },
      splashColor: const Color(0x1A2563EB),
      highlightColor: const Color(0x0F2563EB),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFFFDFEFF), Color(0xFFF2F7FF)],
                      )
                    : null,
                color: enabled ? null : const Color(0xFFF5F7FB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE7EDF5)),
              ),
              child: Icon(icon, size: 19, color: iconTone),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
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
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Ink(
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

