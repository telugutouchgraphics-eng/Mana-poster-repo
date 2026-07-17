// ignore_for_file: use_build_context_synchronously, unused_element, unused_field

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mana_poster/app/media/poster_network_image_cache.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:psd_sdk/psd_sdk.dart' as psd;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/services/media_export_service.dart';
import 'package:mana_poster/app/services/rewarded_access_service.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/services/poster_downloads_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_text_service.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/app/localization/app_language.dart';

import '../models/background_presets.dart';
import '../models/editor_template_document.dart';
import '../models/editor_page_config.dart';
import '../models/editor_stage_background.dart';
import '../services/background_removal_service.dart';
import '../services/editor_draft_storage_service.dart';
import '../services/editor_asset_catalog_service.dart';
import '../services/editor_font_catalog_service.dart';

part 'editor_constants.dart';
part 'editor_models.dart';
part 'editor_history.dart';
part 'editor_helpers.dart';
part 'editor_state.dart';
part 'editor_state_text.dart';
part 'editor_state_crop.dart';
part 'editor_state_adjust.dart';
part 'editor_state_history.dart';
part 'editor_state_background.dart';
part 'editor_state_export.dart';
part 'editor_state_layers.dart';
part 'editor_font_compat.dart';
part 'widgets/top_toolbar.dart';
part 'widgets/bottom_toolbar.dart';
part 'widgets/editor_fullscreen_overlay.dart';
part 'widgets/editor_canvas.dart';
part 'widgets/editor_misc.dart';
part 'tools/text_tool.dart';
part 'tools/crop_tool.dart';
part 'tools/adjust_tool.dart';
part 'tools/background_tool.dart';
part 'tools/draw_tool.dart';
part 'tools/clone_tool.dart';
part 'tools/stretch_tool.dart';
part 'tools/content_aware_tool.dart';
part 'tools/selection_tool.dart';
part 'tools/frame_lens_tool.dart';
part 'tools/replay_tool.dart';

const Color _editorChromeSurface = Color(0xFF24262B);
const Color _editorChromeSurfaceStrong = Color(0xFF1C1E23);
const Color _editorChromeBorder = Color(0xFF3A3D45);
const Color _editorChromeTextPrimary = Color(0xFFF1F3F4);
const Color _editorChromeTextSecondary = Color(0xFFBDC1C6);
const Color _editorCanvasBackdrop = Color(0xFF2A2C31);
const String _textEffectPresetsStorageKey = 'editor_text_effect_presets_v1';
const double _workspaceGestureMinZoom = 0.2;
const double _workspaceFitZoom = 1;
const double _workspaceMaxZoom = 8;

double _normalizeWorkspaceZoomValue(double value) {
  if (!value.isFinite) {
    return _workspaceFitZoom;
  }
  return value.clamp(_workspaceGestureMinZoom, _workspaceMaxZoom).toDouble();
}

@visibleForTesting
double debugNormalizeWorkspaceZoomForTest(double value) =>
    _normalizeWorkspaceZoomValue(value);

@visibleForTesting
double calculatePsdPageWidthScaleForTest({
  required int psdWidth,
  required double targetPageWidth,
}) {
  if (psdWidth <= 0 || !targetPageWidth.isFinite || targetPageWidth <= 0) {
    return 1;
  }
  return targetPageWidth / psdWidth;
}

({int width, int height}) _calculateExportTargetPixelSize({
  required int widthPx,
  required int heightPx,
  required bool shouldBoostRaster,
  required bool preservePixels,
}) {
  if (widthPx <= 0 || heightPx <= 0) {
    return (width: 1, height: 1);
  }
  var scale = 1.0;
  if (!preservePixels &&
      shouldBoostRaster &&
      math.max(widthPx, heightPx) <= 2048) {
    scale = 2.0;
  }
  const maxExportPixels = 64000000.0;
  final requestedPixels = widthPx * heightPx * scale * scale;
  if (requestedPixels > maxExportPixels) {
    scale = math.sqrt(maxExportPixels / (widthPx * heightPx));
  }
  return (
    width: math.max(1, (widthPx * scale).round()),
    height: math.max(1, (heightPx * scale).round()),
  );
}

@visibleForTesting
({int width, int height}) debugCalculateExportTargetPixelSizeForTest({
  required int widthPx,
  required int heightPx,
  required bool shouldBoostRaster,
  required bool preservePixels,
}) {
  return _calculateExportTargetPixelSize(
    widthPx: widthPx,
    heightPx: heightPx,
    shouldBoostRaster: shouldBoostRaster,
    preservePixels: preservePixels,
  );
}

double _calculateExportPixelRatioForStage({
  required double logicalWidth,
  required double logicalHeight,
  required double devicePixelRatio,
  required ({int width, int height})? targetSize,
  required bool preservePixels,
}) {
  if (logicalWidth <= 0 || logicalHeight <= 0) {
    return devicePixelRatio.clamp(1.0, 4.5).toDouble();
  }

  double ratio = devicePixelRatio;
  if (targetSize != null) {
    final neededW = targetSize.width / logicalWidth;
    final neededH = targetSize.height / logicalHeight;
    ratio = math.max(ratio, math.max(neededW, neededH));
  }

  const maxExportPixels = 64000000.0;
  final maxRatioByPixels = math.sqrt(
    maxExportPixels / math.max(1.0, logicalWidth * logicalHeight),
  );
  final safeMaxRatio = preservePixels
      ? math.max(1.0, maxRatioByPixels)
      : math.max(1.0, math.min(16.0, maxRatioByPixels));
  return ratio.clamp(1.0, safeMaxRatio).toDouble();
}

@visibleForTesting
double debugCalculateExportPixelRatioForTest({
  required double logicalWidth,
  required double logicalHeight,
  required double devicePixelRatio,
  required ({int width, int height})? targetSize,
  required bool preservePixels,
}) {
  return _calculateExportPixelRatioForStage(
    logicalWidth: logicalWidth,
    logicalHeight: logicalHeight,
    devicePixelRatio: devicePixelRatio,
    targetSize: targetSize,
    preservePixels: preservePixels,
  );
}

@visibleForTesting
bool isTopTextEditContextForTest({
  required bool isTextLayer,
  required String? psdEditableText,
  required bool isLocked,
}) {
  return !isLocked &&
      (isTextLayer || (psdEditableText?.trim().isNotEmpty ?? false));
}

double _snapEditorSliderValue(
  double value, {
  required double min,
  required double max,
  required double step,
}) {
  final clamped = value.clamp(min, max).toDouble();
  final snapped = min + (((clamped - min) / step).round() * step);
  return snapped.clamp(min, max).toDouble();
}

double _editorSliderToPercent(double value, double min, double max) {
  if ((max - min).abs() < 0.000001) {
    return 0;
  }
  return (((value.clamp(min, max).toDouble() - min) / (max - min)) * 100)
      .clamp(0, 100)
      .toDouble();
}

double _editorPercentToSlider(double percent, double min, double max) {
  final clampedPercent = percent.clamp(0, 100).toDouble();
  return min + ((clampedPercent / 100) * (max - min));
}

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({
    super.key,
    this.pageConfig,
    this.initialStageBackground,
    this.templateDocumentSource,
    this.initialPosterProfile,
    this.initialPersonalizationConfig,
    this.includeInitialPosterNameLayer = true,
    this.autoSelectInitialLayers = true,
    this.preferFullWidthCanvas = false,
    this.requireSubscriptionForExportActions = false,
    this.initialPhotoShapeOverride = '',
    this.initialPhotoRenderModeOverride = '',
    this.initialPhotoXOffsetPercent = 0,
    this.initialPhotoYOffsetPercent = 0,
    this.lockTemplateLayers = false,
    this.autoProcessAddedPhotos = false,
    this.defaultAddedPhotoMaskShape = '',
    this.initialDesignImportPath,
    this.initialDraft,
  });

  final EditorPageConfig? pageConfig;
  final EditorStageBackground? initialStageBackground;
  final String? templateDocumentSource;
  final PosterProfileData? initialPosterProfile;
  final CreatorPosterPersonalization? initialPersonalizationConfig;
  final bool includeInitialPosterNameLayer;
  final bool autoSelectInitialLayers;
  final bool preferFullWidthCanvas;
  final bool requireSubscriptionForExportActions;
  final String initialPhotoShapeOverride;
  final String initialPhotoRenderModeOverride;
  final double initialPhotoXOffsetPercent;
  final double initialPhotoYOffsetPercent;
  final bool lockTemplateLayers;
  final bool autoProcessAddedPhotos;
  final String defaultAddedPhotoMaskShape;
  final String? initialDesignImportPath;
  final Map<String, dynamic>? initialDraft;

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

enum _EditorRewardGateFeature { assets, teluguFonts, removeBackground }

class _ImageEditorScreenState extends State<ImageEditorScreen>
    with
        SingleTickerProviderStateMixin,
        AppLanguageStateMixin,
        WidgetsBindingObserver {
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
  final RewardedAccessService _rewardedAccessService = RewardedAccessService();
  final SubscriptionBackendService _appEntitlementService =
      SubscriptionBackendService.app();
  final SubscriptionBackendService _editorEntitlementService =
      SubscriptionBackendService.editor();

  final List<_CanvasLayer> _layers = <_CanvasLayer>[];
  final List<_EditorHistoryEntry> _undoStack = <_EditorHistoryEntry>[];
  final List<_EditorHistoryEntry> _redoStack = <_EditorHistoryEntry>[];
  String? _selectedLayerId;
  double _workspaceZoom = 1;
  Offset _workspacePan = Offset.zero;
  final Map<int, Offset> _workspacePointers = <int, Offset>{};
  final Map<String, Matrix4> _groupTransformStartTransforms =
      <String, Matrix4>{};
  double? _pinchStartDistance;
  double _pinchStartZoom = 1;
  Offset _pinchStartFocalPoint = Offset.zero;
  Offset _pinchStartPan = Offset.zero;
  bool _isWorkspacePinching = false;
  bool _groupTransformUndoPushed = false;
  String? _groupTransformSessionId;
  String? _groupTransformSelectedLayerId;
  Matrix4? _workspaceLayerBaseline;
  String? _workspaceLayerBaselineId;
  String? _lastLayerBrushPreviewLayerId;
  Offset? _lastLayerBrushPreviewPoint;
  _PhotoEraserPreviewState? _pendingEraserPreviewState;
  bool _eraserPreviewFrameScheduled = false;

  void _resetWorkspaceViewportToFit() {
    _workspaceZoom = _workspaceFitZoom;
    _workspacePan = Offset.zero;
    _workspacePointers.clear();
    _pinchStartDistance = null;
    _pinchStartZoom = _workspaceFitZoom;
    _pinchStartFocalPoint = Offset.zero;
    _pinchStartPan = Offset.zero;
    _isWorkspacePinching = false;
    _workspaceLayerBaseline = null;
    _workspaceLayerBaselineId = null;
  }

  Offset _boundWorkspacePan(Offset pan, double zoom) {
    final maxX = math.max(
      0.0,
      ((_lastCanvasSize.width * zoom) - _lastCanvasSize.width) / 2,
    );
    final maxY = math.max(
      0.0,
      ((_lastCanvasSize.height * zoom) - _lastCanvasSize.height) / 2,
    );
    return Offset(
      pan.dx.clamp(-maxX, maxX).toDouble(),
      pan.dy.clamp(-maxY, maxY).toDouble(),
    );
  }

  Offset _rubberBandWorkspacePan(Offset pan) {
    const limit = 36.0;
    const resistance = 0.18;
    return Offset(
      (pan.dx * resistance).clamp(-limit, limit).toDouble(),
      (pan.dy * resistance).clamp(-limit, limit).toDouble(),
    );
  }

  double _workspaceBrushSize(double screenSize) =>
      screenSize / math.max(0.1, _workspaceZoom);

  void _setEraserPreviewState(
    _PhotoEraserPreviewState? state, {
    bool coalesce = false,
  }) {
    if (!coalesce || state == null) {
      _pendingEraserPreviewState = null;
      _eraserPreviewNotifier.value = state;
      return;
    }
    _pendingEraserPreviewState = state;
    if (_eraserPreviewFrameScheduled) {
      return;
    }
    _eraserPreviewFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eraserPreviewFrameScheduled = false;
      final pending = _pendingEraserPreviewState;
      _pendingEraserPreviewState = null;
      if (!mounted || pending == null) {
        return;
      }
      _eraserPreviewNotifier.value = pending;
    });
  }

  void _rememberLayerBrushPreviewPoint(String layerId, Offset point) {
    _lastLayerBrushPreviewLayerId = layerId;
    _lastLayerBrushPreviewPoint = Offset(
      point.dx.clamp(0.0, 1.0).toDouble(),
      point.dy.clamp(0.0, 1.0).toDouble(),
    );
  }

  Offset _resolveLayerBrushPreviewPoint(String layerId, [Offset? point]) {
    if (point != null) {
      final normalized = Offset(
        point.dx.clamp(0.0, 1.0).toDouble(),
        point.dy.clamp(0.0, 1.0).toDouble(),
      );
      _rememberLayerBrushPreviewPoint(layerId, normalized);
      return normalized;
    }
    if (_lastLayerBrushPreviewLayerId == layerId &&
        _lastLayerBrushPreviewPoint != null) {
      return _lastLayerBrushPreviewPoint!;
    }
    final visiblePoint = _visibleWorkspaceCenterAsLayerPoint(layerId);
    if (visiblePoint != null) {
      _rememberLayerBrushPreviewPoint(layerId, visiblePoint);
      return visiblePoint;
    }
    const fallback = Offset(0.5, 0.5);
    _rememberLayerBrushPreviewPoint(layerId, fallback);
    return fallback;
  }

  Offset? _visibleWorkspaceCenterAsLayerPoint(String layerId) {
    final layer = _layers.cast<_CanvasLayer?>().firstWhere(
      (item) => item?.id == layerId,
      orElse: () => null,
    );
    if (layer == null || _lastCanvasSize.isEmpty) {
      return null;
    }
    final pageSize = _pageAspectRatio == null
        ? _lastCanvasSize
        : _fitPageSize(
            workspaceSize: _lastCanvasSize,
            aspectRatio: _pageAspectRatio!,
            preferFullWidth: widget.preferFullWidthCanvas,
            forceFullWidth: _pageAspectRatioAutoFromImage,
          );
    if (pageSize.isEmpty) {
      return null;
    }
    final viewportCenter = Offset(
      _lastCanvasSize.width / 2,
      _lastCanvasSize.height / 2,
    );
    final workspacePoint =
        viewportCenter - (_workspacePan / math.max(0.1, _workspaceZoom));
    final pageOrigin = Offset(
      (_lastCanvasSize.width - pageSize.width) / 2,
      (_lastCanvasSize.height - pageSize.height) / 2,
    );
    final pagePoint = workspacePoint - pageOrigin;
    final layerSize = layer.isPhoto
        ? (layer.fillPageBounds
              ? pageSize
              : _photoLayerVisualSize(layer, pageSize))
        : _workspaceLayerVisualSize(layer, pageSize);
    if (layerSize.isEmpty) {
      return null;
    }
    final layerOrigin = Offset(
      (pageSize.width - layerSize.width) / 2,
      (pageSize.height - layerSize.height) / 2,
    );
    final layerCenter = Offset(layerSize.width / 2, layerSize.height / 2);
    final transformedPoint = pagePoint - layerOrigin - layerCenter;
    final inverse = Matrix4.inverted(Matrix4.copy(layer.transform));
    final localCentered = MatrixUtils.transformPoint(inverse, transformedPoint);
    final localPoint = localCentered + layerCenter;
    return Offset(
      (localPoint.dx / layerSize.width).clamp(0.0, 1.0).toDouble(),
      (localPoint.dy / layerSize.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  void _handleWorkspacePointerDown(PointerDownEvent event) {
    _workspacePointers[event.pointer] = event.localPosition;
    if (_workspacePointers.length == 1) {
      _workspaceLayerBaselineId = _selectedLayerId;
      _workspaceLayerBaseline = _selectedLayerId == null
          ? null
          : Matrix4.copy(_transformationController.value);
    }
    if (_workspacePointers.length == 2) {
      final points = _workspacePointers.values.toList(growable: false);
      _pinchStartDistance = (points[0] - points[1]).distance;
      _pinchStartZoom = _workspaceZoom;
      _pinchStartFocalPoint = Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      );
      _pinchStartPan = _workspacePan;
      if (_workspaceLayerBaselineId == _selectedLayerId &&
          _workspaceLayerBaseline != null) {
        _transformationController.value = Matrix4.copy(
          _workspaceLayerBaseline!,
        );
      }
      _photoGestureVelocity = Offset.zero;
      _photoGestureLastScale = 1;
      _photoGestureLastRotation = 0;
      _snapGuideNotifier.value = const _SnapGuideState.none();
      setState(() => _isWorkspacePinching = true);
    }
  }

  void _handleWorkspacePointerMove(PointerMoveEvent event) {
    if (!_workspacePointers.containsKey(event.pointer)) return;
    _workspacePointers[event.pointer] = event.localPosition;
    if (_workspacePointers.length < 2 || _pinchStartDistance == null) return;
    final points = _workspacePointers.values.take(2).toList(growable: false);
    final distance = (points[0] - points[1]).distance;
    if (_pinchStartDistance! > 0) {
      final nextZoom = _normalizeWorkspaceZoomValue(
        _pinchStartZoom * (distance / _pinchStartDistance!),
      );
      final currentFocalPoint = Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      );
      final viewportCenter = Offset(
        _lastCanvasSize.width / 2,
        _lastCanvasSize.height / 2,
      );
      final scaleRatio = nextZoom / _pinchStartZoom;
      final anchoredPan =
          currentFocalPoint -
          viewportCenter -
          ((_pinchStartFocalPoint - viewportCenter - _pinchStartPan) *
              scaleRatio);
      final nextPan = nextZoom <= _workspaceFitZoom
          ? _rubberBandWorkspacePan(anchoredPan)
          : _boundWorkspacePan(anchoredPan, nextZoom);
      if ((nextZoom - _workspaceZoom).abs() > 0.0015 ||
          (nextPan - _workspacePan).distanceSquared > 0.36) {
        setState(() {
          _workspaceZoom = nextZoom;
          _workspacePan = nextPan;
        });
      }
    }
  }

  void _handleWorkspacePointerEnd(PointerEvent event) {
    _workspacePointers.remove(event.pointer);
    if (_workspacePointers.length < 2) {
      _pinchStartDistance = null;
      if (_isWorkspacePinching) {
        setState(() {
          _isWorkspacePinching = false;
          if (_workspaceZoom <= _workspaceFitZoom) {
            _workspaceZoom = _workspaceFitZoom;
            _workspacePan = Offset.zero;
          }
        });
      }
    }
    if (_workspacePointers.isEmpty) {
      _workspaceLayerBaseline = null;
      _workspaceLayerBaselineId = null;
    }
  }

  Color _canvasBackgroundColor = const Color(0xFFFFFFFF);
  int _canvasBackgroundGradientIndex = -1;
  int _layerSeed = 0;
  static const int _maxHistory = 40;
  _CanvasLayer? _fontSizeEditBeforeLayer;
  _CanvasLayer? _textStyleEditBeforeLayer;
  _CanvasLayer? _textContentEditBeforeLayer;
  _CanvasLayer? _photoMaskEditBeforeLayer;
  bool _isPhotoMaskPositionMode = false;
  _TextEffectSnapshot? _copiedTextEffect;
  _LayerStyleSnapshot? _copiedLayerStyle;
  _CanvasLayer? _layerStyleQuickBeforeLayer;
  Timer? _layerStyleQuickUpdateTimer;
  _LayerStyleQuickPatch? _pendingLayerStyleQuickUpdate;
  final List<_TextEffectSnapshot> _savedTextEffectPresets =
      <_TextEffectSnapshot>[];
  int _textEffectPresetSeed = 0;
  String? _textContentEditingLayerId;
  bool _isSyncingSelectedTextField = false;
  bool _isExporting = false;
  bool _isSharing = false;
  bool _isRemovingBackground = false;
  bool _isMagicWandMode = false;
  bool _isPhotoEraserMode = false;
  bool _isPhotoStretchMode = false;
  bool _isContentAwareMode = false;
  bool _isPhotoCloneMode = false;
  bool _isDrawBrushMode = false;
  bool _isPickingMedia = false;
  bool _isCapturingStage = false;
  bool _isTransparentExportCapture = false;
  bool _isCropMode = false;
  bool _isCropApplying = false;
  bool _suppressCanvasTapDown = false;
  bool _canvasTapResolvedLayer = false;
  bool _autoSelectCanvasLayer = true;
  bool _showSelectedLayerHandles = true;
  bool _showLayerStyleQuickControls = false;
  int _suppressCanvasTapToken = 0;
  bool _showTextControls = false;
  _TextToolTab _activeTextToolTab = _TextToolTab.style;
  _LayerStyleQuickTab _activeLayerStyleQuickTab = _LayerStyleQuickTab.stroke;
  _BottomPrimaryTool _activeBottomPrimaryTool = _BottomPrimaryTool.none;
  _BottomInlineMode _activeInlineMode = _BottomInlineMode.none;
  String _activeStickerCategory = 'Emojis';
  final EditorAssetCatalogService _editorAssetCatalogService =
      EditorAssetCatalogService();
  final EditorFontCatalogService _editorFontCatalogService =
      EditorFontCatalogService();
  EditorAssetCatalog _remoteEditorAssetCatalog = EditorAssetCatalog.empty;
  EditorFontCatalog _remoteEditorFontCatalog = EditorFontCatalog.empty;
  bool _isEditorAssetCatalogLoading = false;
  bool _isEditorFontCatalogLoading = false;
  _BorderStyle _borderStyle = _BorderStyle.none;
  double _borderWidth = 1.5;
  double _borderRadius = 0;
  Color _borderColor = Colors.white;
  String? _borderTargetLayerId;
  double _backgroundBlurAmount = 0;
  bool _isAdjustMode = false;
  bool _isLayerInteracting = false;
  bool _isCreatingTextLayer = false;
  bool _isRewardedGateBusy = false;
  bool _isHistoryReplayRunning = false;
  bool _assetsRewardUnlocked = false;
  bool _teluguFontsRewardUnlocked = false;
  int _removeBackgroundTaskId = 0;
  String? _activeCommitJobKey;
  Future<void> _commitJobTail = Future<void>.value();
  EditorPageConfig? _designPageConfig;
  bool _preserveDesignExportPixels = false;
  double? _pageAspectRatio;
  bool _pageAspectRatioAutoFromImage = false;
  bool _didShowSetupReadyHint = false;
  bool _isTextTypingScreenOpen = false;
  bool _isTextPlacementMode = false;
  bool _showLayersAdvancedPanel = false;
  bool _layerNudgeControlExpanded = false;
  Offset _layerNudgeControlOffset = const Offset(0, 220);
  Matrix4? _gestureStartMatrix;
  Offset _gestureStartFocalPoint = Offset.zero;
  Offset _gestureStartLocalFocalPoint = Offset.zero;
  Offset _photoGestureLastFocalPoint = Offset.zero;
  double _photoGestureLastScale = 1;
  double _photoGestureLastRotation = 0;
  double _stickerHandleStartAngle = 0;
  double _stickerHandleStartDistance = 1;
  Offset _transformHandleStartCenterGlobal = Offset.zero;
  Offset _textStretchStartGlobalPosition = Offset.zero;
  Offset _objectSideResizeAxisGlobal = Offset.zero;
  bool _objectSideResizeHorizontal = true;
  Offset _photoGestureVelocity = Offset.zero;
  int _photoGestureLastTimestampMicros = 0;
  late final AnimationController _photoGlideController;
  late final Future<void> _backgroundRemoverInitialization;
  Offset _photoGlideTotalTravel = Offset.zero;
  Offset _photoGlideAppliedTravel = Offset.zero;
  Timer? _selectedTextLongPressTimer;
  DateTime? _lastSelectedTextTapAt;
  String? _lastSelectedTextTapLayerId;
  OverlayEntry? _canvasLayerPickerEntry;
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
  double _adjustSessionSharpen = 0;
  double _adjustSessionGrain = 0;
  double _adjustSessionVignette = 0;
  double _adjustSessionMotion = 0;
  double _adjustSessionTiltShift = 0;
  double _adjustSessionShadows = 0;
  double _adjustSessionHighlights = 0;
  double _adjustSessionTemperature = 0;
  double _adjustSessionTint = 0;
  double _adjustInitialBrightness = 0;
  double _adjustInitialContrast = 1;
  double _adjustInitialSaturation = 1;
  double _adjustInitialBlur = 0;
  double _adjustInitialSharpen = 0;
  double _adjustInitialGrain = 0;
  double _adjustInitialVignette = 0;
  double _adjustInitialMotion = 0;
  double _adjustInitialTiltShift = 0;
  double _adjustInitialShadows = 0;
  double _adjustInitialHighlights = 0;
  double _adjustInitialTemperature = 0;
  double _adjustInitialTint = 0;
  double _eraserBrushSize = 42;
  double _eraserHardness = 0.28;
  double _stretchBrushSize = 48;
  double _stretchStrength = 0.62;
  double _stretchOpacity = 1;
  double _contentAwareBrushSize = 54;
  double _contentAwareStrength = 0.82;
  double _cloneBrushSize = 44;
  double _cloneHardness = 0.72;
  double _cloneOpacity = 1;
  bool _cloneAligned = false;
  Offset? _cloneSourcePoint;
  Offset? _cloneAlignedSampleOffset;
  ui.Image? _clonePreviewImage;
  String? _clonePreviewLayerId;
  ui.Image? _stretchPreviewImage;
  String? _stretchPreviewLayerId;
  bool _isLayerMaskBrushMode = false;
  bool _isLayerMaskBrushRestoreMode = false;
  double _layerMaskBrushSize = 42;
  double _layerMaskBrushHardness = 0.35;
  List<_EditorBrushPreset> _drawBrushPresets = const <_EditorBrushPreset>[
    _EditorBrushPreset.marker,
  ];
  final Map<String, _EditorBrushMask> _drawBrushMasks =
      <String, _EditorBrushMask>{};
  final List<_DrawStroke> _drawStrokes = <_DrawStroke>[];
  final List<_DrawStroke> _drawRedoStrokes = <_DrawStroke>[];
  List<Offset>? _drawActivePoints;
  final Color _drawColor = Colors.black;
  double _drawBrushSize = 12;
  double _drawOpacity = 1;
  _EditorBrushPreset _selectedDrawBrush = _EditorBrushPreset.marker;
  bool _showDrawBrushSettings = false;
  final List<Offset> _eraserStrokePoints = <Offset>[];
  final List<Offset> _contentAwareStrokePoints = <Offset>[];
  final Set<int> _contentAwareActivePointers = <int>{};
  bool _suppressContentAwareStroke = false;
  List<Offset> _cloneStrokePoints = <Offset>[];
  List<Offset> _clonePreviewStampPoints = <Offset>[];
  List<Offset> _stretchStrokePoints = <Offset>[];
  final List<_StretchStroke> _stretchLiveStrokes = <_StretchStroke>[];
  final List<_StretchStroke> _stretchRedoStrokes = <_StretchStroke>[];
  final List<Offset> _layerMaskStrokePoints = <Offset>[];
  String? _eraserStrokeLayerId;
  String? _contentAwareStrokeLayerId;
  String? _cloneStrokeLayerId;
  String? _stretchStrokeLayerId;
  String? _layerMaskStrokeLayerId;
  Size _eraserStrokeLayerSize = Size.zero;
  Size _contentAwareStrokeLayerSize = Size.zero;
  Size _cloneStrokeLayerSize = Size.zero;
  Size _stretchStrokeLayerSize = Size.zero;
  Size _layerMaskStrokeLayerSize = Size.zero;
  final ValueNotifier<_SnapGuideState> _snapGuideNotifier =
      ValueNotifier<_SnapGuideState>(const _SnapGuideState.none());
  final ValueNotifier<_SelectedPhotoRenderState?> _selectedPhotoRenderNotifier =
      ValueNotifier<_SelectedPhotoRenderState?>(null);
  final ValueNotifier<_PhotoEraserPreviewState?> _eraserPreviewNotifier =
      ValueNotifier<_PhotoEraserPreviewState?>(null);
  final ValueNotifier<_StretchLivePreviewState?> _stretchPreviewNotifier =
      ValueNotifier<_StretchLivePreviewState?>(null);
  final ValueNotifier<_DrawPreviewState?> _drawPreviewNotifier =
      ValueNotifier<_DrawPreviewState?>(null);
  final ValueNotifier<_AdjustSessionState?> _adjustSessionNotifier =
      ValueNotifier<_AdjustSessionState?>(null);
  final ValueNotifier<_EditorCommitState?> _commitStateNotifier =
      ValueNotifier<_EditorCommitState?>(null);
  final TextEditingController _selectedTextController = TextEditingController();
  final FocusNode _selectedTextFocusNode = FocusNode();
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
  bool _didApplyInitialPersonalization = false;
  ui.Image? _watermarkLogoImage;

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
  bool get _hasSelectedEditableTextLayer {
    final layer = _selectedLayer;
    if (layer == null) {
      return false;
    }
    return isTopTextEditContextForTest(
      isTextLayer: layer.isText,
      psdEditableText: layer.psdEditableText,
      isLocked: layer.isLocked,
    );
  }

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

  bool get _canUndo {
    if (_isDrawBrushMode) {
      return _drawStrokes.isNotEmpty;
    }
    return _undoStack.isNotEmpty ||
        (_isPhotoStretchMode && _stretchLiveStrokes.isNotEmpty);
  }

  bool get _canRedo {
    if (_isDrawBrushMode) {
      return _drawRedoStrokes.isNotEmpty;
    }
    return _redoStack.isNotEmpty ||
        (_isPhotoStretchMode && _stretchRedoStrokes.isNotEmpty);
  }

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

  double _effectivePhotoSharpen(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionSharpen
      : layer.photoSharpen;

  double _effectivePhotoGrain(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionGrain
      : layer.photoGrain;

  double _effectivePhotoVignette(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionVignette
      : layer.photoVignette;

  double _effectivePhotoMotion(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionMotion
      : layer.photoMotion;

  double _effectivePhotoTiltShift(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionTiltShift
      : layer.photoTiltShift;

  double _effectivePhotoShadows(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionShadows
      : layer.photoShadows;

  double _effectivePhotoHighlights(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionHighlights
      : layer.photoHighlights;

  double _effectivePhotoTemperature(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionTemperature
      : layer.photoTemperature;

  double _effectivePhotoTint(_CanvasLayer layer) =>
      _isAdjustMode && _adjustSessionLayerId == layer.id
      ? _adjustSessionTint
      : layer.photoTint;

  String? get _activeModeLabel {
    if (_isCropMode) {
      return 'Crop mode';
    }
    if (_isAdjustMode) {
      return 'Adjust mode';
    }
    if (_isMagicWandMode) {
      return 'Magic wand';
    }
    if (_isPhotoEraserMode) {
      return 'Eraser';
    }
    if (_isContentAwareMode) {
      return 'Content Aware';
    }
    if (_isPhotoCloneMode) {
      return 'Clone';
    }
    if (_isPhotoStretchMode) {
      return 'Smudge';
    }
    if (_isDrawBrushMode) {
      return 'Brushes';
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
        return strings.localized(telugu: 'అసెట్స్', english: 'Assets');
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
      case 'Remove BG':
        return strings.localized(telugu: 'బీజీ తొలగింపు', english: 'Remove BG');
      case 'Magic wand':
        return strings.localized(
          telugu: 'మ్యాజిక్ వాండ్',
          english: 'Magic wand',
        );
      case 'Eraser':
        return strings.localized(telugu: 'ఎరేసర్', english: 'Eraser');
      case 'Content Aware':
        return 'Content Aware';
      case 'Clone':
        return 'Clone';
      case 'Smudge':
        return strings.localized(telugu: 'స్మడ్జ్', english: 'Smudge');
      case 'Stretch':
        return strings.localized(telugu: 'స్ట్రెచ్', english: 'Stretch');
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

  bool get _hasRewardedEditorProAccess {
    if (_editorEntitlementService.cachedEntitlement?.hasAccess == true) {
      return true;
    }
    final appEntitlement =
        SubscriptionBackendService.entitlementNotifier.value ??
        _appEntitlementService.cachedEntitlement;
    if (appEntitlement?.hasAccess != true) {
      return false;
    }
    final productId = appEntitlement?.productId?.trim();
    return productId == EditorSubscriptionPlanConfig.productId ||
        productId == 'manual_lifetime_whitelist';
  }

  Future<void> _refreshEditorAdEntitlementInBackground() async {
    await Future.wait(<Future<void>>[
      _appEntitlementService.refreshEntitlementInBackground(),
      _editorEntitlementService.refreshEntitlementInBackground(),
    ]);
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasImmediateEditorSubscriptionAccess =>
      SubscriptionBackendService.entitlementNotifier.value?.hasAccess == true ||
      _appEntitlementService.cachedEntitlement?.hasAccess == true;

  Future<bool> _ensureSubscriptionAccessForExportActions() async {
    if (!widget.requireSubscriptionForExportActions) {
      return true;
    }
    if (_hasImmediateEditorSubscriptionAccess) {
      unawaited(_appEntitlementService.refreshEntitlementInBackground());
      return true;
    }

    if (_appEntitlementService.isConfigured &&
        FirebaseAuth.instance.currentUser != null) {
      final result = await _appEntitlementService.fetchEntitlement(
        forceRefresh: true,
      );
      if (!mounted) {
        return false;
      }
      if (result.hasAccess) {
        return true;
      }
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SubscriptionPlanScreen()),
    );
    if (!mounted) {
      return false;
    }
    final refreshed = _appEntitlementService.isConfigured
        ? await _appEntitlementService.fetchFreshEntitlementWithRetry()
        : _appEntitlementService.cachedEntitlement;
    return refreshed?.hasAccess == true;
  }

  bool _isPremiumTeluguFontFamily(String family) =>
      _textFontFamilies.contains(family) ||
      _remoteTeluguFontFamilies.contains(family);

  Future<bool> _ensureRewardedAccessForFeature(
    _EditorRewardGateFeature feature,
  ) async {
    if (_hasRewardedEditorProAccess) {
      return true;
    }
    if (feature == _EditorRewardGateFeature.assets && _assetsRewardUnlocked) {
      return true;
    }
    if (feature == _EditorRewardGateFeature.teluguFonts &&
        _teluguFontsRewardUnlocked) {
      return true;
    }
    if (_isRewardedGateBusy) {
      return false;
    }

    final strings = context.strings;
    final label = switch (feature) {
      _EditorRewardGateFeature.assets => 'editor_assets',
      _EditorRewardGateFeature.teluguFonts => 'telugu_fonts',
      _EditorRewardGateFeature.removeBackground => 'remove_background',
    };
    final featureTitle = switch (feature) {
      _EditorRewardGateFeature.assets => 'Editor Assets',
      _EditorRewardGateFeature.teluguFonts => 'Telugu Fonts',
      _EditorRewardGateFeature.removeBackground => 'Remove BG',
    };
    final failureMessage = switch (feature) {
      _EditorRewardGateFeature.assets => strings.localized(
        telugu: 'Assets వాడడానికి ad పూర్తిగా చూడాలి',
        english: 'Watch the full ad to use Assets',
      ),
      _EditorRewardGateFeature.teluguFonts => strings.localized(
        telugu: 'తెలుగు ఫాంట్స్ అన్‌లాక్ చేయడానికి ad పూర్తిగా చూడాలి',
        english: 'Watch the full ad to unlock Telugu fonts',
      ),
      _EditorRewardGateFeature.removeBackground => strings.localized(
        telugu: 'Background remove ఉపయోగించడానికి ad పూర్తిగా చూడాలి',
        english: 'Watch the full ad to use Remove BG',
      ),
    };

    final accessChoice = await _showEditorRewardChoiceDialog(
      title: featureTitle,
    );
    if (!mounted || accessChoice == null) {
      return false;
    }
    if (accessChoice == 'subscribe') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const SubscriptionPlanScreen.editorPro(),
        ),
      );
      if (!mounted) {
        return false;
      }
      final refreshed = _editorEntitlementService.isConfigured
          ? await _editorEntitlementService.fetchFreshEntitlementWithRetry()
          : _editorEntitlementService.cachedEntitlement;
      return refreshed?.hasAccess == true;
    }

    setState(() {
      _isRewardedGateBusy = true;
    });
    try {
      final granted = await _rewardedAccessService.showRewardedAccessAd(
        adUnitId: AppPublicInfo.adMobEditorRewardedAdUnitId,
        debugLabel: label,
      );
      if (!mounted) {
        return false;
      }
      if (!granted) {
        ScaffoldMessenger.of(
          context,
        ).showTopSnackBar(AppSnackBar.build(content: Text(failureMessage)));
        return false;
      }
      if (feature == _EditorRewardGateFeature.assets) {
        _assetsRewardUnlocked = true;
      }
      if (feature == _EditorRewardGateFeature.teluguFonts) {
        _teluguFontsRewardUnlocked = true;
      }
      return true;
    } finally {
      if (mounted) {
        setState(() {
          _isRewardedGateBusy = false;
        });
      } else {
        _isRewardedGateBusy = false;
      }
    }
  }

  Future<String?> _showEditorRewardChoiceDialog({required String title}) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF252A36),
                  Color(0xFF151821),
                  Color(0xFF101219),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(
                            0xFFFACC15,
                          ).withValues(alpha: 0.26),
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFACC15),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _editorChromeTextPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.strings.localized(
                    telugu:
                        'Editor Pro తో Assets, Telugu Fonts, Remove BG అన్‌లాక్ అవుతాయి. ₹99/month లేదా ₹699/year సబ్‌స్క్రైబ్ చేయండి, లేదా ad చూసి free గా కొనసాగండి.',
                    english:
                        'Editor Pro unlocks Assets, Telugu Fonts, and Remove BG. Subscribe for ₹99/month or ₹699/year, or continue free by watching an ad.',
                    hindi:
                        'Editor Pro से Assets, Telugu Fonts और Remove BG अनलॉक होते हैं। ₹99/month या ₹699/year सब्सक्राइब करें, या ad देखकर free जारी रखें।',
                    tamil:
                        'Editor Pro மூலம் Assets, Telugu Fonts மற்றும் Remove BG திறக்கும். ₹99/month அல்லது ₹699/year சந்தா எடுக்கவும், அல்லது ad பார்த்து free ஆக தொடரவும்.',
                    kannada:
                        'Editor Pro ಮೂಲಕ Assets, Telugu Fonts ಮತ್ತು Remove BG unlock ಆಗುತ್ತವೆ. ₹99/month ಅಥವಾ ₹699/year subscribe ಮಾಡಿ, ಅಥವಾ ad ನೋಡಿ free ಆಗಿ ಮುಂದುವರಿಸಿ.',
                    malayalam:
                        'Editor Pro ഉപയോഗിച്ച് Assets, Telugu Fonts, Remove BG unlock ചെയ്യും. ₹99/month അല്ലെങ്കിൽ ₹699/year subscribe ചെയ്യുക, അല്ലെങ്കിൽ ad കണ്ടു free ആയി തുടരുക.',
                  ),
                  style: TextStyle(
                    color: _editorChromeTextSecondary.withValues(alpha: 0.92),
                    fontSize: 14,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop('free'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _editorChromeTextPrimary,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Free',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop('subscribe'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Subscribe',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color get _activeModeAccent {
    if (_isCropMode) {
      return const Color(0xFF2563EB);
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

  void _openBottomPrimaryTool(_BottomPrimaryTool tool, String label) {
    setState(() {
      _isPhotoEraserMode = false;
      _isPhotoStretchMode = false;
      _isContentAwareMode = false;
      _isPhotoCloneMode = false;
      _isDrawBrushMode = false;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _eraserStrokePoints.clear();
      _contentAwareStrokePoints.clear();
      _cloneStrokePoints.clear();
      _clonePreviewStampPoints.clear();
      _layerMaskStrokePoints.clear();
      _eraserStrokeLayerId = null;
      _contentAwareStrokeLayerId = null;
      _cloneStrokeLayerId = null;
      _contentAwareStrokeLayerSize = Size.zero;
      _cloneStrokeLayerSize = Size.zero;
      _cloneSourcePoint = null;
      _cloneAlignedSampleOffset = null;
      _layerMaskStrokeLayerId = null;
      _eraserPreviewNotifier.value = null;
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
      _drawPreviewNotifier.value = null;
      if (tool != _BottomPrimaryTool.text) {
        _isTextPlacementMode = false;
      }
      _activeBottomPrimaryTool = tool;
      _activeMainToolLabel = label;
    });
  }

  void _showBottomToolGuidance(_BottomPrimaryTool tool) {
    return;
    // ignore: dead_code
    if (!mounted || tool == _BottomPrimaryTool.none) {
      return;
    }
    final strings = context.strings;
    final message = switch (tool) {
      _BottomPrimaryTool.photo => strings.localized(
        telugu: 'ఫోటో టూల్: గ్యాలరీ లేదా కెమెరా నుంచి ఫోటో జోడించండి.',
        english: 'Photo tool: add from Gallery or Camera.',
      ),
      _BottomPrimaryTool.text => strings.localized(
        telugu: 'టెక్స్ట్ టూల్: టెక్స్ట్ జోడించి వెంటనే రూపాన్ని మార్చండి.',
        english: 'Text tool: tap Add Text, then style it.',
      ),
      _BottomPrimaryTool.background => strings.localized(
        telugu:
            'బ్యాక్‌గ్రౌండ్ టూల్: తెలుపు, రంగు, గ్రేడియెంట్ లేదా చిత్రం ఎంచుకోండి.',
        english: 'Background tool: choose White, Color, Gradient, or Image.',
      ),
      _BottomPrimaryTool.none => '',
    };
    if (message.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(
        AppSnackBar.build(
          content: Text(message),
          duration: const Duration(milliseconds: 1100),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _closeBottomPrimaryTool() {
    if (_activeBottomPrimaryTool == _BottomPrimaryTool.none) {
      return;
    }
    setState(() {
      _isTextPlacementMode = false;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.none;
      _showTextControls = false;
      _showLayerStyleQuickControls = false;
      _restoreSelectedLayerToolContextFields();
    });
  }

  void _restoreSelectedLayerToolContextFields() {
    final selected = _selectedLayer;
    _activeBottomPrimaryTool = _BottomPrimaryTool.none;
    if (selected?.isPhoto ?? false) {
      _activeMainToolLabel = 'Photo';
    } else if (selected?.isText ?? false) {
      _activeMainToolLabel = 'Text';
    } else if (selected?.isSticker ?? false) {
      _activeMainToolLabel = 'Stickers';
    } else {
      _activeMainToolLabel = '';
    }
  }

  void _restoreSelectedLayerToolContext() {
    if (!mounted) {
      return;
    }
    setState(_restoreSelectedLayerToolContextFields);
  }

  void _openInlineMode(_BottomInlineMode mode) {
    setState(() {
      if (mode != _BottomInlineMode.photoEraser) {
        _isPhotoEraserMode = false;
        _isPhotoStretchMode = false;
        _isContentAwareMode = false;
        _isPhotoCloneMode = false;
        _contentAwareStrokePoints.clear();
        _cloneStrokePoints.clear();
        _clonePreviewStampPoints.clear();
        _contentAwareStrokeLayerId = null;
        _cloneStrokeLayerId = null;
        _contentAwareStrokeLayerSize = Size.zero;
        _cloneStrokeLayerSize = Size.zero;
        _cloneSourcePoint = null;
        _cloneAlignedSampleOffset = null;
        _eraserPreviewNotifier.value = null;
      }
      _isDrawBrushMode = false;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
      _drawPreviewNotifier.value = null;
      _activeInlineMode = mode;
      _showLayerStyleQuickControls = false;
      if (mode == _BottomInlineMode.border &&
          _borderStyle == _BorderStyle.none) {
        _borderStyle = _BorderStyle.custom;
        _borderTargetLayerId = _hasSelectedPhotoLayer ? _selectedLayerId : null;
      }
      if (mode != _BottomInlineMode.stickerItems) {
        _activeStickerCategory = 'Emojis';
      }
    });
  }

  void _closeInlineMode() {
    setState(() {
      _isPhotoEraserMode = false;
      _isPhotoStretchMode = false;
      _isContentAwareMode = false;
      _isPhotoCloneMode = false;
      _isDrawBrushMode = false;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _eraserStrokePoints.clear();
      _contentAwareStrokePoints.clear();
      _cloneStrokePoints.clear();
      _clonePreviewStampPoints.clear();
      _layerMaskStrokePoints.clear();
      _eraserStrokeLayerId = null;
      _contentAwareStrokeLayerId = null;
      _cloneStrokeLayerId = null;
      _contentAwareStrokeLayerSize = Size.zero;
      _cloneStrokeLayerSize = Size.zero;
      _cloneSourcePoint = null;
      _cloneAlignedSampleOffset = null;
      _layerMaskStrokeLayerId = null;
      _eraserPreviewNotifier.value = null;
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
      _drawPreviewNotifier.value = null;
      _activeInlineMode = _BottomInlineMode.none;
      _showLayerStyleQuickControls = false;
      _restoreSelectedLayerToolContextFields();
    });
  }

  void _openStickerCategory(String category) {
    setState(() {
      _activeStickerCategory = category;
      _activeInlineMode = _BottomInlineMode.stickerItems;
    });
  }

  void _applyBorderStyle(_BorderStyle style) {
    final nextTarget = _hasSelectedPhotoLayer ? _selectedLayerId : null;
    if (_borderStyle == style && _borderTargetLayerId == nextTarget) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      _borderStyle = style;
      _borderTargetLayerId = nextTarget;
    });
  }

  void _activateCustomBorder() {
    final nextTarget = _hasSelectedPhotoLayer ? _selectedLayerId : null;
    if (_borderStyle == _BorderStyle.custom &&
        _borderTargetLayerId == nextTarget) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      _borderStyle = _BorderStyle.custom;
      _borderTargetLayerId = nextTarget;
    });
  }

  Future<void> _openBorderColorPickerOverlay() async {
    _activateCustomBorder();
    final result = await _pushPremiumOverlay<_TextColorSelection>(
      _TextColorPickerScreen(
        colors: editorBackgroundColors.take(50).toList(growable: false),
        gradients: const <List<Color>>[],
        selectedColor: _borderColor,
        selectedGradientIndex: -1,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      _borderStyle = _BorderStyle.custom;
      _borderColor = result.textColor;
    });
  }

  void _setBorderWidth(double value) {
    final nextWidth = value.clamp(0.5, 100).toDouble();
    if ((_borderWidth - nextWidth).abs() < 0.001) {
      return;
    }
    setState(() {
      _borderWidth = nextWidth;
    });
  }

  void _beginBorderWidthEdit(double _) {
    _pushUndoSnapshot();
  }

  void _endBorderWidthEdit(double _) {}

  void _setBorderRadius(double value) {
    final nextRadius = value.clamp(0, 100).toDouble();
    if ((_borderRadius - nextRadius).abs() < 0.001) {
      return;
    }
    setState(() {
      _borderRadius = nextRadius;
      if (_borderStyle != _BorderStyle.none) {
        _borderStyle = _BorderStyle.custom;
      }
    });
  }

  void _beginBorderRadiusEdit(double _) {
    _pushUndoSnapshot();
  }

  void _endBorderRadiusEdit(double _) {}

  void _setBackgroundBlur(double amount) {
    if (_stageBackgroundImageBytes == null) {
      return;
    }
    if ((_backgroundBlurAmount - amount).abs() < 0.001) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      _backgroundBlurAmount = amount;
    });
  }

  Future<T?> _pushPremiumOverlay<T>(
    Widget child, {
    Color shellColor = const Color(0xF8F8FAFC),
    EdgeInsets shellPadding = const EdgeInsets.all(8),
    double shellBorderRadius = 18,
    double shellBlurSigma = 14,
    Color barrierColor = const Color(0x57000000),
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        barrierColor: barrierColor,
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: shellBlurSigma,
                    sigmaY: shellBlurSigma,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: shellPadding,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(shellBorderRadius),
                        child: Material(color: shellColor, child: child),
                      ),
                    ),
                  ),
                ),
              );
            },
      ),
    );
  }

  Future<void> _openFontPickerOverlay() async {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) {
      return;
    }
    if (_remoteEditorFontCatalog.fonts.isEmpty &&
        !_isEditorFontCatalogLoading) {
      await _loadEditorFontCatalog();
    }
    final selected = await _pushPremiumOverlay<String>(
      TextFontFullscreenOverlay(
        selectedFontFamily: layer.fontFamily,
        teluguFonts: <String>[
          ..._textFontFamilies,
          ..._remoteTeluguFontFamilies,
        ],
        englishFonts: <String>[
          ..._englishTextFontFamilies,
          ..._remoteEnglishFontFamilies,
        ],
        hindiFonts: <String>[
          ..._hindiTextFontFamilies,
          ..._remoteHindiFontFamilies,
        ],
        previewText: (layer.text ?? '').trim().isEmpty
            ? 'తెలుగు Poster Title नमस्ते'
            : layer.text!,
      ),
    );
    if (!mounted || selected == null || selected.isEmpty) {
      return;
    }
    if (selected != layer.fontFamily && _isPremiumTeluguFontFamily(selected)) {
      final granted = await _ensureRewardedAccessForFeature(
        _EditorRewardGateFeature.teluguFonts,
      );
      if (!mounted || !granted) {
        return;
      }
    }
    if (_isRemoteFontFamily(selected)) {
      final ready = await _editorFontCatalogService.ensureRegisteredByFamily(
        selected,
        _remoteEditorFontCatalog,
      );
      if (!mounted || !ready) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: const Text('Font download failed.')),
        );
        return;
      }
    }
    unawaited(_setSelectedTextFontFamily(selected));
  }

  Future<void> _openBackgroundPickerOverlay() async {
    Future<bool> pickImage() async {
      final beforeSignature = _stageBackgroundImageBytes == null
          ? null
          : _photoBytesSignature(_stageBackgroundImageBytes!);
      await _setCanvasBackgroundImage();
      final afterSignature = _stageBackgroundImageBytes == null
          ? null
          : _photoBytesSignature(_stageBackgroundImageBytes!);
      return beforeSignature != afterSignature;
    }

    await _pushPremiumOverlay<void>(
      BackgroundEditorFullscreenOverlay(
        colors: editorBackgroundColors.take(50).toList(growable: false),
        gradients: editorBackgroundGradients.take(50).toList(growable: false),
        selectedColor: _canvasBackgroundColor,
        selectedGradientIndex: _canvasBackgroundGradientIndex,
        hasSelectedImage: _stageBackgroundImageBytes != null,
        onColorSelected: _setCanvasBackgroundColor,
        onGradientSelected: _setCanvasBackgroundGradient,
        onImageSelected: pickImage,
      ),
    );
  }

  Future<void> _openTextColorPickerOverlay() async {
    final selected = _selectedLayer;
    if (selected == null || !selected.isText) {
      return;
    }
    final result = await _pushPremiumOverlay<_TextColorSelection>(
      _TextColorPickerScreen(
        colors: _textColors.take(50).toList(growable: false),
        gradients: _textGradients.take(50).toList(growable: false),
        selectedColor: selected.textColor,
        selectedGradientIndex: selected.textGradientIndex,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.textGradientIndex >= 0) {
      _setSelectedTextGradient(result.textGradientIndex);
      return;
    }
    _setSelectedTextColor(result.textColor);
  }

  Future<void> _openStickerColorPickerOverlay() async {
    final selected = _selectedLayer;
    if (selected == null || !selected.isSticker) {
      return;
    }
    final result = await _pushPremiumOverlay<_TextColorSelection>(
      _TextColorPickerScreen(
        colors: _textColors.take(50).toList(growable: false),
        gradients: const <List<Color>>[],
        selectedColor: selected.stickerColor,
        selectedGradientIndex: -1,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selected.id);
    if (index == -1 || !_layers[index].isSticker) {
      return;
    }
    final beforeLayer = _layers[index];
    if (beforeLayer.stickerColor.toARGB32() == result.textColor.toARGB32()) {
      return;
    }
    _replaceLayerWithHistory(
      index: index,
      afterLayer: beforeLayer.copyWith(stickerColor: result.textColor),
    );
  }

  Future<void> _openStickerBrowserOverlay({
    String? initialCategory,
    List<String> categories = const <String>[],
  }) async {
    if (_remoteEditorAssetCatalog.categories.isEmpty &&
        !_isEditorAssetCatalogLoading) {
      await _loadEditorAssetCatalog();
    }
    final allRemoteCategories = _remoteEditorAssetCatalog.categories
        .map((item) => item.name)
        .toList(growable: false);
    final visibleCategories = categories.isEmpty
        ? allRemoteCategories
        : categories
              .where(allRemoteCategories.contains)
              .toList(growable: false);
    if (visibleCategories.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: const Text('Assets are not available right now.'),
          ),
        );
      }
      return;
    }
    final selected = await _pushPremiumOverlay<String>(
      StickerBrowserFullscreenOverlay(
        categories: visibleCategories,
        catalog: const <String, List<String>>{},
        remoteCatalog: _remoteEditorAssetCatalog,
        localAssetPath: _localEditorAssetPath,
        requestRemoteAssetAccess: () =>
            _ensureRewardedAccessForFeature(_EditorRewardGateFeature.assets),
        downloadAsset: _downloadEditorAsset,
        initialCategory: initialCategory,
      ),
    );
    if (!mounted || selected == null || selected.isEmpty) {
      return;
    }
    _handleAddSticker(selected);
  }

  Future<void> _loadEditorAssetCatalog() async {
    if (_isEditorAssetCatalogLoading) return;
    _isEditorAssetCatalogLoading = true;
    try {
      final catalog = await _editorAssetCatalogService.loadCatalog();
      if (mounted) setState(() => _remoteEditorAssetCatalog = catalog);
      unawaited(_refreshEditorAssetCatalog());
    } catch (_) {
      // Bundled assets remain available when the network/catalog is unavailable.
    } finally {
      _isEditorAssetCatalogLoading = false;
    }
  }

  Future<void> _refreshEditorAssetCatalog() async {
    try {
      final catalog = await _editorAssetCatalogService.refreshCatalog();
      if (mounted) setState(() => _remoteEditorAssetCatalog = catalog);
    } catch (_) {}
  }

  Future<void> _loadEditorFontCatalog() async {
    if (_isEditorFontCatalogLoading) return;
    _isEditorFontCatalogLoading = true;
    try {
      final catalog = await _editorFontCatalogService.loadCatalog();
      if (mounted) {
        setState(() => _remoteEditorFontCatalog = catalog);
      }
    } catch (_) {
      // Bundled fonts remain available when remote fonts are unavailable.
    } finally {
      _isEditorFontCatalogLoading = false;
    }
  }

  List<String> get _remoteTeluguFontFamilies =>
      _remoteFontsForLanguage(EditorRemoteFontLanguage.telugu);

  List<String> get _remoteEnglishFontFamilies =>
      _remoteFontsForLanguage(EditorRemoteFontLanguage.english);

  List<String> get _remoteHindiFontFamilies =>
      _remoteFontsForLanguage(EditorRemoteFontLanguage.hindi);

  List<String> _remoteFontsForLanguage(EditorRemoteFontLanguage language) {
    final bundled = <String>{
      ..._textFontFamilies,
      ..._englishTextFontFamilies,
      ..._hindiTextFontFamilies,
    };
    return _remoteEditorFontCatalog.fonts
        .where(
          (font) => font.language == language && !bundled.contains(font.family),
        )
        .map((font) => font.family)
        .toList(growable: false);
  }

  bool _isRemoteFontFamily(String family) =>
      _remoteEditorFontCatalog.fonts.any((font) => font.family == family);

  Future<String> _downloadEditorAsset(
    EditorRemoteAsset asset,
    void Function(double progress) onProgress,
  ) => _editorAssetCatalogService.download(asset, onProgress: onProgress);

  Future<String?> _localEditorAssetPath(EditorRemoteAsset asset) =>
      _editorAssetCatalogService.localPath(asset);

  Future<void> _openLayersAdvancedOverlay() async {
    if (!mounted) {
      return;
    }
    setState(() => _showLayersAdvancedPanel = true);
  }

  void _closeLayersAdvancedPanel() {
    if (!_showLayersAdvancedPanel || !mounted) {
      return;
    }
    setState(() => _showLayersAdvancedPanel = false);
  }

  void _moveLayerToFrontById(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    if (_selectedLayerId != layerId) {
      _handleLayerSelected(layerId);
    }
    _moveSelectedLayerToFront();
  }

  void _moveLayerToBackById(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    if (_selectedLayerId != layerId) {
      _handleLayerSelected(layerId);
    }
    _moveSelectedLayerToBack();
  }

  void _setLayerBlendMode(String layerId, BlendMode blendMode) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].blendMode == blendMode) return;
    final beforeLayer = _layers[index];
    if (beforeLayer.isLocked) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(blendMode: blendMode);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _handleToolsLayersTap() {
    if (_activeInlineMode == _BottomInlineMode.layers) {
      unawaited(_openLayersAdvancedOverlay());
      return;
    }
    setState(() {
      _activeMainToolLabel = 'Layers';
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _showTextControls = false;
    });
    _openInlineMode(_BottomInlineMode.layers);
  }

  void _toggleLayerLockById(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) {
      return;
    }
    final beforeLayer = _layers[index];
    final nextLocked = !beforeLayer.isLocked;
    final afterLayer = beforeLayer.copyWith(isLocked: nextLocked);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
    if (nextLocked && _selectedLayerId == layerId) {
      _clearSelection();
    }
  }

  void _toggleLayerVisibilityById(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) {
      return;
    }
    final beforeLayer = _layers[index];
    final nextHidden = !beforeLayer.isHidden;
    final afterLayer = beforeLayer.copyWith(isHidden: nextHidden);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
    if (nextHidden && _selectedLayerId == layerId) {
      _clearSelection();
    }
  }

  void _reorderLayersFromAdvancedView(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _layers.length) {
      return;
    }
    if (_layers[oldIndex].isLocked) {
      return;
    }
    final insertIndex = newIndex.clamp(0, _layers.length - 1).toInt();
    if (insertIndex == oldIndex) {
      return;
    }
    final layerId = _layers[oldIndex].id;
    _pushLayerReorderHistoryEntry(
      layerId: layerId,
      fromIndex: oldIndex,
      toIndex: insertIndex,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: _selectedLayerId,
    );
    setState(() {
      final layer = _layers.removeAt(oldIndex);
      _layers.insert(insertIndex, layer);
      if (_selectedLayerId == layerId) {
        _transformationController.value = Matrix4.copy(layer.transform);
      }
    });
  }

  void _moveSelectedLayerForwardOne() {
    final index = _selectedLayerIndex;
    if (index == -1 || index >= _layers.length - 1) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null || _layers[index].isLocked) {
      return;
    }
    _pushLayerReorderHistoryEntry(
      layerId: selectedId,
      fromIndex: index,
      toIndex: index + 1,
      beforeSelectedLayerId: selectedId,
      afterSelectedLayerId: selectedId,
    );
    setState(() {
      final layer = _layers.removeAt(index);
      _layers.insert(index + 1, layer);
    });
  }

  void _moveSelectedLayerBackwardOne() {
    final index = _selectedLayerIndex;
    if (index <= 0) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null || _layers[index].isLocked) {
      return;
    }
    _pushLayerReorderHistoryEntry(
      layerId: selectedId,
      fromIndex: index,
      toIndex: index - 1,
      beforeSelectedLayerId: selectedId,
      afterSelectedLayerId: selectedId,
    );
    setState(() {
      final layer = _layers.removeAt(index);
      _layers.insert(index - 1, layer);
    });
  }

  void _cycleSelectedTextColor() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) {
      return;
    }
    final currentIndex = _textColors.indexWhere(
      (color) => color.toARGB32() == layer.textColor.toARGB32(),
    );
    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + 1) % _textColors.length;
    _setSelectedTextColor(_textColors[nextIndex]);
  }

  void _cycleSelectedTextFontFamily() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) {
      return;
    }
    final currentIndex = _allTextFontFamilies.indexOf(layer.fontFamily);
    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + 1) % _allTextFontFamilies.length;
    unawaited(_setSelectedTextFontFamily(_allTextFontFamilies[nextIndex]));
  }

  Future<void> _setSelectedTextFontFamily(String fontFamily) async {
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
    final beforeLayer = _layers[index];
    final converted = await _resolveLegacyRenderTextFor(
      text: beforeLayer.text ?? '',
      fontFamily: fontFamily,
    );
    if (!mounted) {
      return;
    }
    final refreshedIndex = _layers.indexWhere((item) => item.id == selectedId);
    if (refreshedIndex == -1 || !_layers[refreshedIndex].isText) {
      return;
    }
    final currentLayer = _layers[refreshedIndex];
    if (currentLayer.fontFamily == fontFamily) {
      return;
    }
    final afterLayer = currentLayer.copyWith(
      fontFamily: fontFamily,
      legacyRenderText: converted,
    );
    _replaceLayerWithHistory(index: refreshedIndex, afterLayer: afterLayer);
  }

  void _handleSelectedTextDoubleTap() {
    _cancelSelectedTextLongPress();
    unawaited(_openTextTypingScreen(selectAll: true));
  }

  void _handleSelectedTextEditButtonTap() {
    final selected = _selectedLayer;
    if (selected == null || selected.isLocked) {
      return;
    }
    if (selected.isText) {
      unawaited(_openTextTypingScreen());
      return;
    }
    if ((selected.psdEditableText ?? '').trim().isNotEmpty) {
      _editLayerTextById(selected.id);
    }
  }

  void _editLayerTextById(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    final layer = _layers[index];
    if (layer.isText) {
      if (_selectedLayerId != layer.id) {
        _handleLayerSelected(layer.id);
      }
      unawaited(_openTextTypingScreen());
      return;
    }
    final editableText = layer.psdEditableText?.trim();
    if (!layer.isPhoto || editableText == null || editableText.isEmpty) {
      return;
    }
    final normalizedText = _normalizePsdEditableText(editableText);
    final editableFontFamily = _resolvePsdEditFontFamily(layer);
    final legacyRenderText = _legacyRenderTextForPsdEdit(
      rawText: editableText,
      normalizedText: normalizedText,
      fontFamily: editableFontFamily,
    );
    final convertedLayer = _CanvasLayer(
      id: layer.id,
      type: _CanvasLayerType.text,
      layerName: layer.layerName,
      text: normalizedText,
      legacyRenderText: legacyRenderText,
      textColor: Colors.black,
      textAlign: layer.psdEditableTextAlign ?? TextAlign.center,
      fontSize: (layer.psdEditableFontSize ?? 40).clamp(1.0, 220.0).toDouble(),
      fontFamily: editableFontFamily,
      textOpacity: layer.photoOpacity,
      blendMode: layer.blendMode,
      transform: Matrix4.copy(layer.transform),
    );
    _replaceLayerWithHistory(
      index: index,
      afterLayer: convertedLayer,
      afterSelectedLayerId: convertedLayer.id,
    );
    _syncSelectedTextEditor();
    unawaited(_openTextTypingScreen(selectAll: true));
  }

  String _resolvePsdEditFontFamily(_CanvasLayer layer) {
    final family = layer.psdEditableFontFamily?.trim();
    if (family != null && family.isNotEmpty) {
      return _resolvePsdEditableFontFamily(family) ??
          'Anek Telugu Condensed Regular';
    }
    return 'Anek Telugu Condensed Regular';
  }

  String? _legacyRenderTextForPsdEdit({
    required String rawText,
    required String normalizedText,
    required String fontFamily,
  }) {
    if (!_isLegacyTeluguFontFamily(fontFamily)) {
      return null;
    }
    if (_looksLikeLegacyPsdText(rawText)) {
      return rawText.replaceAll('\r', '\n').trim();
    }
    return TeluguLegacyTextService.convertSync(
      normalizedText,
      fontFamily: fontFamily,
    );
  }

  String _normalizePsdEditableText(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .trim();
    if (normalized.isEmpty || !_looksLikeLegacyPsdText(normalized)) {
      return normalized;
    }
    final converted = TeluguLegacyTextService.reverseConvertSync(
      normalized,
    ).replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    return converted.isEmpty ? normalized : converted;
  }

  bool _looksLikeLegacyPsdText(String text) {
    var legacyGlyphs = 0;
    var readableChars = 0;
    for (final rune in text.runes) {
      if (rune == 10 || rune == 13 || rune == 32) {
        continue;
      }
      readableChars += 1;
      if (rune >= 0xE000 && rune <= 0xF8FF) {
        legacyGlyphs += 1;
      }
    }
    return legacyGlyphs >= 2 && legacyGlyphs >= (readableChars * 0.12);
  }

  void _handleSelectedTextTap() {
    if (!_hasSelectedTextLayer) {
      return;
    }
    _cancelSelectedTextLongPress();
    if (_showTextControls ||
        _activeBottomPrimaryTool != _BottomPrimaryTool.text ||
        _activeMainToolLabel != 'Text') {
      setState(() {
        _showTextControls = false;
        _activeBottomPrimaryTool = _BottomPrimaryTool.text;
        _activeMainToolLabel = 'Text';
      });
    }
  }

  Widget _buildTextStyleOverlay(double height) {
    return KeyedSubtree(
      key: const ValueKey<String>('text-style-overlay'),
      child: Container(
        height: height,
        color: const Color(0xCC0F172A),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 34,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 4),
                  _EditorIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: context.strings.localized(
                      telugu: 'వెనక్కి',
                      english: 'Back',
                    ),
                    onTap: () {
                      setState(() {
                        _showTextControls = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _TextStyleBar(
                visible: true,
                focusedTab: _activeTextToolTab,
                selectedLayer: _selectedLayer,
                textController: _selectedTextController,
                textFocusNode: _selectedTextFocusNode,
                colors: _textColors,
                backgroundColors: editorBackgroundColors,
                gradients: _textGradients,
                savedEffectPresets: _savedTextEffectPresets,
                copiedTextEffect: _copiedTextEffect,
                onEditTap: () => unawaited(_openTextTypingScreen()),
                onTextChanged: _handleSelectedTextChanged,
                onFontsTap: () => unawaited(_openFontPickerOverlay()),
                onColorWheelTap: () => unawaited(_openTextColorPickerOverlay()),
                onColorSelected: _setSelectedTextColor,
                onBackgroundColorSelected: _setSelectedTextBackgroundColor,
                onAlignSelected: _setSelectedTextAlignment,
                onGradientSelected: _setSelectedTextGradient,
                onEffectPresetSelected: _applySelectedTextEffectPreset,
                onCopyTextEffect: _copySelectedTextEffect,
                onPasteTextEffect: _pasteCopiedTextEffect,
                onSaveTextEffectPreset: _saveSelectedTextEffectPreset,
                onSavedTextEffectPresetSelected: _applySavedTextEffectPreset,
                onSavedTextEffectPresetDeleted: _deleteSavedTextEffectPreset,
                onTextOpacityChanged: _setSelectedTextOpacity,
                onFontSizeChanged: _setSelectedTextFontSize,
                onFontSizeChangeStart: _handleTextFontSizeEditStart,
                onFontSizeChangeEnd: _handleTextFontSizeEditEnd,
                onBackgroundOpacityChanged: _setSelectedTextBackgroundOpacity,
                onBackgroundOpacityChangeStart: _beginSelectedTextStyleEdit,
                onBackgroundOpacityChangeEnd: _endSelectedTextStyleEdit,
                onBackgroundRadiusChanged: _setSelectedTextBackgroundRadius,
                onBackgroundRadiusChangeStart: _beginSelectedTextStyleEdit,
                onBackgroundRadiusChangeEnd: _endSelectedTextStyleEdit,
                onBackgroundTopPaddingChanged:
                    _setSelectedTextBackgroundTopPadding,
                onBackgroundTopPaddingChangeStart: _beginSelectedTextStyleEdit,
                onBackgroundTopPaddingChangeEnd: _endSelectedTextStyleEdit,
                onBackgroundBottomPaddingChanged:
                    _setSelectedTextBackgroundBottomPadding,
                onBackgroundBottomPaddingChangeStart:
                    _beginSelectedTextStyleEdit,
                onBackgroundBottomPaddingChangeEnd: _endSelectedTextStyleEdit,
                onLineHeightChanged: _setSelectedTextLineHeight,
                onLineHeightChangeStart: _beginSelectedTextStyleEdit,
                onLineHeightChangeEnd: _endSelectedTextStyleEdit,
                onLetterSpacingChanged: _setSelectedTextLetterSpacing,
                onLetterSpacingChangeStart: _beginSelectedTextStyleEdit,
                onLetterSpacingChangeEnd: _endSelectedTextStyleEdit,
                onShadowOpacityChanged: _setSelectedTextShadowOpacity,
                onShadowOpacityChangeStart: _beginSelectedTextStyleEdit,
                onShadowOpacityChangeEnd: _endSelectedTextStyleEdit,
                onShadowBlurChanged: _setSelectedTextShadowBlur,
                onShadowBlurChangeStart: _beginSelectedTextStyleEdit,
                onShadowBlurChangeEnd: _endSelectedTextStyleEdit,
                onShadowOffsetYChanged: _setSelectedTextShadowOffsetY,
                onShadowOffsetYChangeStart: _beginSelectedTextStyleEdit,
                onShadowOffsetYChangeEnd: _endSelectedTextStyleEdit,
                onShadowColorSelected: _setSelectedTextShadowColorLive,
                onShadowColorChangeStart: _beginSelectedTextStyleEdit,
                onShadowColorChangeEnd: _endSelectedTextStyleEdit,
                onBoldToggle: _toggleSelectedTextBold,
                onItalicToggle: _toggleSelectedTextItalic,
                onUnderlineToggle: _toggleSelectedTextUnderline,
                onStrokeColorSelected: _setSelectedTextStrokeColorLive,
                onStrokeColorChangeStart: _beginSelectedTextStyleEdit,
                onStrokeColorChangeEnd: _endSelectedTextStyleEdit,
                onStrokeWidthChanged: _setSelectedTextStrokeWidth,
                onStrokeWidthChangeStart: _beginSelectedTextStyleEdit,
                onStrokeWidthChangeEnd: _endSelectedTextStyleEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSelectedTextLongPress(PointerDownEvent event) {
    if (!_hasSelectedTextLayer) {
      return;
    }
    _cancelSelectedTextLongPress();
    _selectedTextPressPosition = event.position;
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
    final nextOpacity = beforeLayer.textBackgroundOpacity <= 0.001
        ? 0.75
        : beforeLayer.textBackgroundOpacity;
    if (beforeLayer.textBackgroundColor.toARGB32() == color.toARGB32() &&
        (beforeLayer.textBackgroundOpacity - nextOpacity).abs() < 0.0001) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(
      textBackgroundColor: color,
      textBackgroundOpacity: nextOpacity,
    );
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
        textBackgroundRadius: radius.clamp(0, 100).toDouble(),
      );
    });
  }

  void _setSelectedTextBackgroundTopPadding(double padding) {
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
        textBackgroundTopPadding: padding.clamp(0, 100).toDouble(),
      );
    });
  }

  void _setSelectedTextBackgroundBottomPadding(double padding) {
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
        textBackgroundBottomPadding: padding.clamp(0, 100).toDouble(),
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
    final snappedValue = _snapEditorSliderValue(
      value,
      min: 0.2,
      max: 5.0,
      step: 0.05,
    );
    setState(() {
      _layers[index] = _layers[index].copyWith(textLineHeight: snappedValue);
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
    final snappedValue = _snapEditorSliderValue(
      value,
      min: -200,
      max: 200,
      step: 0.5,
    );
    setState(() {
      _layers[index] = _layers[index].copyWith(textLetterSpacing: snappedValue);
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
        textShadowBlur: value.clamp(0, 100).toDouble(),
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
        textShadowOffsetY: value.clamp(0, 100).toDouble(),
      );
    });
  }

  void _setSelectedTextShadowColorLive(Color color) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final layer = _layers[index];
    final nextOpacity = layer.textShadowOpacity <= 0.001
        ? 0.45
        : layer.textShadowOpacity;
    final nextBlur = layer.textShadowBlur <= 0.001
        ? 10.0
        : layer.textShadowBlur;
    final nextOffsetY = layer.textShadowOffsetY <= 0.001
        ? 4.0
        : layer.textShadowOffsetY;
    if (layer.textShadowColor.toARGB32() == color.toARGB32() &&
        (layer.textShadowOpacity - nextOpacity).abs() < 0.0001 &&
        (layer.textShadowBlur - nextBlur).abs() < 0.0001 &&
        (layer.textShadowOffsetY - nextOffsetY).abs() < 0.0001) {
      return;
    }
    setState(() {
      _layers[index] = layer.copyWith(
        textShadowColor: color,
        textShadowOpacity: nextOpacity,
        textShadowBlur: nextBlur,
        textShadowOffsetY: nextOffsetY,
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
    final afterLayer = beforeLayer.copyWith(
      textStrokeColor: color,
      textStrokeWidth: beforeLayer.textStrokeWidth <= 0.001
          ? 2.0
          : beforeLayer.textStrokeWidth,
      textStrokeGradientIndex: -1,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextStrokeColorLive(Color color) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final layer = _layers[index];
    final nextWidth = layer.textStrokeWidth <= 0.001
        ? 2.0
        : layer.textStrokeWidth;
    if (layer.textStrokeColor.toARGB32() == color.toARGB32() &&
        (layer.textStrokeWidth - nextWidth).abs() < 0.0001 &&
        layer.textStrokeGradientIndex == -1) {
      return;
    }
    setState(() {
      _layers[index] = layer.copyWith(
        textStrokeColor: color,
        textStrokeWidth: nextWidth,
        textStrokeGradientIndex: -1,
      );
    });
  }

  void _setSelectedTextStrokeWidth(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textStrokeWidth: value.clamp(0, 100).toDouble(),
      );
    });
  }

  void _showSetupReadyHintIfNeeded() {
    if (_didShowSetupReadyHint ||
        widget.pageConfig == null ||
        widget.templateDocumentSource != null ||
        !mounted) {
      return;
    }
    _didShowSetupReadyHint = true;
    if (_didShowSetupReadyHint) {
      return;
    }
    final strings = context.strings;
    final config = widget.pageConfig!;
    final backgroundLabel = switch (widget.initialStageBackground?.type) {
      EditorStageBackgroundType.transparent => strings.localized(
        telugu: 'పారదర్శకం',
        english: 'Transparent',
      ),
      EditorStageBackgroundType.color => strings.localized(
        telugu: 'రంగు',
        english: 'Color',
      ),
      EditorStageBackgroundType.gradient => strings.localized(
        telugu: 'గ్రేడియెంట్',
        english: 'Gradient',
      ),
      _ => strings.localized(telugu: 'వైట్', english: 'White'),
    };
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          strings.localized(
            telugu:
                'Canvas ready: ${config.widthPx}x${config.heightPx} • ${config.dpi} DPI • $backgroundLabel',
            english:
                'Canvas ready: ${config.widthPx}x${config.heightPx} • ${config.dpi} DPI • $backgroundLabel',
          ),
        ),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ScreenSecurityService.protectScreen());
    _selectedTextFocusNode.addListener(_handleSelectedTextFocusChange);
    unawaited(_loadEditorAssetCatalog());
    unawaited(_loadEditorFontCatalog());
    unawaited(_refreshEditorAdEntitlementInBackground());
    unawaited(
      _rewardedAccessService.preloadRewardedAd(
        adUnitId: AppPublicInfo.adMobEditorRewardedAdUnitId,
      ),
    );
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
    _applyInitialStageBackground(widget.initialStageBackground);
    _backgroundRemoverInitialization = Future<void>.delayed(
      kReleaseMode ? const Duration(seconds: 8) : const Duration(seconds: 30),
      _backgroundRemovalService.ensureReady,
    );
    unawaited(_enterEditorImmersiveMode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_enterEditorImmersiveMode());
      _showSetupReadyHintIfNeeded();
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 900),
          kReleaseMode
              ? _loadTextEffectPresets
              : () async {
                  await Future<void>.delayed(const Duration(seconds: 2));
                  await _loadTextEffectPresets();
                },
        ),
      );
      if (widget.initialDraft != null) {
        unawaited(_restoreFromDecodedDraft(widget.initialDraft!));
      } else if (widget.templateDocumentSource != null) {
        unawaited(
          Future<void>.delayed(
            kReleaseMode
                ? const Duration(milliseconds: 450)
                : const Duration(milliseconds: 1800),
            _loadInitialTemplateDocument,
          ),
        );
      } else if ((widget.initialDesignImportPath ?? '').trim().isNotEmpty) {
        unawaited(
          Future<void>.delayed(
            kReleaseMode
                ? const Duration(milliseconds: 450)
                : const Duration(milliseconds: 900),
            () => _importInitialDesignFile(widget.initialDesignImportPath!),
          ),
        );
      } else {
        unawaited(
          Future<void>.delayed(
            kReleaseMode
                ? const Duration(milliseconds: 1400)
                : const Duration(milliseconds: 3600),
            _restoreAutosavedDraftIfAvailable,
          ),
        );
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
      sharpen: liveAdjustState?.sharpen ?? layer.photoSharpen,
      grain: liveAdjustState?.grain ?? layer.photoGrain,
      vignette: liveAdjustState?.vignette ?? layer.photoVignette,
      motion: liveAdjustState?.motion ?? layer.photoMotion,
      tiltShift: liveAdjustState?.tiltShift ?? layer.photoTiltShift,
      shadows: liveAdjustState?.shadows ?? layer.photoShadows,
      highlights: liveAdjustState?.highlights ?? layer.photoHighlights,
      temperature: liveAdjustState?.temperature ?? layer.photoTemperature,
      tint: liveAdjustState?.tint ?? layer.photoTint,
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

  bool get _isKeyboardVisible {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      return false;
    }
    return views.any((ui.FlutterView view) => view.viewInsets.bottom > 0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_enterEditorImmersiveMode());
      unawaited(ScreenSecurityService.enableSecure());
    }
  }

  @override
  void didChangeMetrics() {
    if (_isKeyboardVisible || _selectedTextFocusNode.hasFocus) {
      return;
    }
    unawaited(_enterEditorImmersiveMode());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commitSelectedTextContentEdit();
    _watermarkLogoImage?.dispose();
    _watermarkLogoImage = null;
    _snapGuideNotifier.dispose();
    _selectedPhotoRenderNotifier.dispose();
    _eraserPreviewNotifier.dispose();
    _clonePreviewImage?.dispose();
    _clonePreviewImage = null;
    _stretchPreviewNotifier.dispose();
    _stretchPreviewImage?.dispose();
    _stretchPreviewImage = null;
    _drawPreviewNotifier.dispose();
    _adjustSessionNotifier.dispose();
    _commitStateNotifier.dispose();
    _selectedTextController.dispose();
    _selectedTextFocusNode.dispose();
    _rewardedAccessService.dispose();
    _editorAssetCatalogService.dispose();
    _editorFontCatalogService.dispose();
    _canvasLayerPickerEntry?.remove();
    _canvasLayerPickerEntry = null;
    _autosaveTimer?.cancel();
    _layerStyleQuickUpdateTimer?.cancel();
    unawaited(_persistAutosaveDraft());
    _photoGlideController.dispose();
    _selectedTextLongPressTimer?.cancel();
    _transformationController.dispose();
    _cropTransformationController.dispose();
    unawaited(_restoreSystemUiMode());
    unawaited(ScreenSecurityService.unprotectScreen());
    super.dispose();
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
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
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
    if (_looksLikeLocalFileSource(source)) {
      return File(source).readAsString();
    }
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
    if (_looksLikeLocalFileSource(source)) {
      return File(source).readAsBytes();
    }
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

  bool _looksLikeLocalFileSource(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty || _looksLikeNetworkSource(trimmed)) {
      return false;
    }
    return File(trimmed).existsSync();
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
        final fillPageBounds = templateLayer.id == 'base_poster';

        Uint8List bytes;
        try {
          bytes = await _loadTemplateLayerBytes(templateLayer.assetPath);
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'Template layer load failed for ${templateLayer.assetPath}: $error',
            );
            debugPrintStack(stackTrace: stackTrace);
          }
          continue;
        }
        final aspectRatio = templateLayer.width / templateLayer.height;
        final targetWidth =
            (templateLayer.width / document.sourceWidth) * pageSize.width;
        final baseSize = fillPageBounds
            ? pageSize
            : _fitPhotoLayerSize(
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
            isLocked: templateLayer.isLocked || widget.lockTemplateLayers,
            photoMaskShape: templateLayer.photoMaskShape.trim(),
            fillPageBounds: fillPageBounds,
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
        _selectedLayerId =
            widget.autoSelectInitialLayers && importedLayers.isNotEmpty
            ? importedLayers.last.id
            : null;
        _syncControllerFromSelection();
        _canvasBackgroundColor = const Color(0xFFFFFFFF);
        _canvasBackgroundGradientIndex = -1;
        _stageBackgroundImageBytes = null;
        _templateDocument = null;
        _isTemplateHydrated = true;
      });
      await _applyInitialTemplatePersonalizationIfNeeded(pageSize);
      if (importedLayers.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
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

  Future<void> _applyInitialTemplatePersonalizationIfNeeded(
    Size pageSize,
  ) async {
    if (_didApplyInitialPersonalization ||
        pageSize.width <= 0 ||
        pageSize.height <= 0) {
      return;
    }

    final posterProfile = widget.initialPosterProfile;
    final personalization = widget.initialPersonalizationConfig;
    if (posterProfile == null || personalization == null) {
      _didApplyInitialPersonalization = true;
      return;
    }

    _didApplyInitialPersonalization = true;

    final photoBytes = await _loadInitialPosterPhotoBytes(
      posterProfile: posterProfile,
      personalization: personalization,
    );
    if (!mounted) {
      return;
    }

    final resolvedName = posterProfile
        .resolvedName(language: context.currentLanguage)
        .trim();
    final insertedLayers = <_CanvasLayer>[];

    if (photoBytes != null) {
      final photoLayer = _buildInitialPersonalizedPhotoLayer(
        bytes: photoBytes.bytes,
        aspectRatio: photoBytes.aspectRatio,
        posterProfile: posterProfile,
        pageSize: pageSize,
        personalization: personalization,
      );
      if (photoLayer != null) {
        insertedLayers.add(photoLayer);
      }
    }

    if (widget.includeInitialPosterNameLayer && resolvedName.isNotEmpty) {
      insertedLayers.add(
        _buildInitialPersonalizedTextLayer(
          text: resolvedName,
          fontFamily: posterProfile.nameFontFamily,
          pageSize: pageSize,
          personalization: personalization,
        ),
      );
    }

    if (insertedLayers.isEmpty) {
      return;
    }

    setState(() {
      _layers.addAll(insertedLayers);
      if (widget.autoSelectInitialLayers) {
        _selectedLayerId = insertedLayers.last.id;
        _syncControllerFromSelection();
      }
    });
  }

  Future<_OptimizedPhotoPayload?> _loadInitialPosterPhotoBytes({
    required PosterProfileData posterProfile,
    required CreatorPosterPersonalization personalization,
  }) async {
    final overrideRenderMode = widget.initialPhotoRenderModeOverride.trim();
    final effectiveRenderMode = overrideRenderMode.isNotEmpty
        ? overrideRenderMode
        : personalization.photoRenderMode.trim();
    final preferOriginal = effectiveRenderMode == 'original';
    final localPath = preferOriginal
        ? posterProfile.originalPhotoPath.trim()
        : posterProfile.photoPath.trim();
    if (localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        final rawBytes = await file.readAsBytes();
        return compute(_optimizeEditorPhotoPayload, rawBytes);
      }
    }

    final remoteUrl = preferOriginal
        ? posterProfile.originalPhotoUrl.trim()
        : posterProfile.photoUrl.trim();
    if (remoteUrl.isNotEmpty) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(remoteUrl));
        final response = await request.close();
        final rawBytes = await consolidateHttpClientResponseBytes(response);
        return compute(_optimizeEditorPhotoPayload, rawBytes);
      } catch (_) {
        return null;
      } finally {
        client.close(force: true);
      }
    }

    return null;
  }

  _CanvasLayer? _buildInitialPersonalizedPhotoLayer({
    required Uint8List bytes,
    required double? aspectRatio,
    required PosterProfileData posterProfile,
    required Size pageSize,
    required CreatorPosterPersonalization personalization,
  }) {
    final isBusinessProfile =
        posterProfile.identityMode == PosterIdentityMode.business;
    final overrideShape = widget.initialPhotoShapeOverride.trim();
    final maskShape = isBusinessProfile
        ? 'circle'
        : (overrideShape.isNotEmpty
              ? overrideShape
              : personalization.photoShape.trim());
    final resolvedAspectRatio = maskShape.isNotEmpty
        ? _editorPhotoMaskAspectRatio(maskShape)
        : (aspectRatio ?? 1);
    if (resolvedAspectRatio <= 0) {
      return null;
    }

    final baseSize = _fitPhotoLayerSize(
      pageSize: pageSize,
      photoAspectRatio: resolvedAspectRatio,
    );
    if (baseSize.width <= 0 || baseSize.height <= 0) {
      return null;
    }

    final photoScale = personalization.photoScale.clamp(1, 100) / 100;
    final visualScale = isBusinessProfile ? photoScale * 0.72 : photoScale;
    final targetWidth = pageSize.width * visualScale;
    final scale = (targetWidth / baseSize.width).clamp(0.05, 20.0);
    final stripOverflowAllowance = personalization.showBottomStrip
        ? (isBusinessProfile ? 56.0 : 60.0)
        : 0.0;
    final baseImageHeight = math.max(
      1.0,
      pageSize.height - stripOverflowAllowance,
    );
    final pageCenter = Offset(pageSize.width / 2, pageSize.height / 2);
    final targetCenter = Offset(
      (pageSize.width * (personalization.photoX / 100)) +
          (pageSize.width * (widget.initialPhotoXOffsetPercent / 100)),
      (baseImageHeight * (personalization.photoY / 100)) +
          (pageSize.height * (widget.initialPhotoYOffsetPercent / 100)),
    );
    final translation = targetCenter - pageCenter;
    final transform = Matrix4.identity()
      ..translateByDouble(translation.dx, translation.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);

    return _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.photo,
      bytes: bytes,
      originalPhotoBytes: bytes,
      photoAspectRatio: resolvedAspectRatio,
      photoMaskShape: maskShape,
      transform: transform,
    );
  }

  _CanvasLayer _buildInitialPersonalizedTextLayer({
    required String text,
    required String fontFamily,
    required Size pageSize,
    required CreatorPosterPersonalization personalization,
  }) {
    final pageCenter = Offset(pageSize.width / 2, pageSize.height / 2);
    final targetCenter = Offset(
      pageSize.width * (personalization.nameX / 100),
      pageSize.height * (personalization.nameY / 100),
    );
    final translation = targetCenter - pageCenter;
    final scale = (personalization.nameScale / 100).clamp(0.2, 4.0);
    final fontSize =
        (personalization.showBottomStrip
            ? pageSize.width * 0.05
            : pageSize.width * 0.04) *
        scale;
    final textColor = personalization.showBottomStrip
        ? const Color(0xFF0F172A)
        : Colors.white;
    final strokeColor = personalization.showBottomStrip
        ? const Color(0x00000000)
        : const Color(0xCC000000);

    return _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.text,
      text: text,
      textColor: textColor,
      textStrokeColor: strokeColor,
      textStrokeWidth: personalization.showBottomStrip ? 0 : 1.5,
      fontSize: fontSize,
      fontFamily: _allTextFontFamilies.contains(fontFamily)
          ? fontFamily
          : 'Anek Telugu Condensed Bold',
      transform: Matrix4.identity()
        ..translateByDouble(translation.dx, translation.dy, 0, 1),
    );
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
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
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
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
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
      final refreshed = await _subscriptionBackendService
          .fetchFreshEntitlementWithRetry();
      await _setProStatus(refreshed.isPro);
      if (!mounted) {
        return false;
      }
      if (refreshed.isPro) {
        return true;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            'Purchase complete అయినా entitlement active కాలేదు. Support ని సంప్రదించండి',
          ),
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _editorCanvasBackdrop,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: _editorCanvasBackdrop,
          image: DecorationImage(
            image: AssetImage('assets/editor_ui/bg_texture.jpg'),
            fit: BoxFit.cover,
            opacity: 0.025,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final bottomToolsHeight = _isCropMode
                  ? _cropBarHeight
                  : _isAdjustMode
                  ? _adjustBarHeight
                  : _isPhotoStretchMode
                  ? _stretchBarHeight
                  : _isContentAwareMode
                  ? _eraserBarHeight
                  : _isPhotoCloneMode
                  ? _stretchBarHeight
                  : _isDrawBrushMode
                  ? _drawBarHeight
                  : (_isPhotoEraserMode ||
                        _isContentAwareMode ||
                        _isPhotoCloneMode ||
                        _isPhotoStretchMode ||
                        _isLayerMaskBrushMode)
                  ? _eraserBarHeight
                  : _bottomBarHeight;
              final showTextStyleQuickControls =
                  _showTextControls && _activeTextToolTab == _TextToolTab.style;
              final visibleBottomToolsHeight = _showTextControls
                  ? showTextStyleQuickControls
                        ? bottomToolsHeight
                        : _textStyleBarHeight
                  : bottomToolsHeight;
              final systemBottomInset = MediaQuery.viewPaddingOf(
                context,
              ).bottom;
              const bannerHeight = 0.0;
              final floatingBottom = systemBottomInset + bannerHeight + 6;
              const toolbarCanvasGap = 8.0;
              const landscapeTopRailWidth = 86.0;
              const landscapeBottomRailWidth = 136.0;
              final useLandscapeSideRails =
                  canvasSize.width > canvasSize.height;
              final landscapeLeftInset = useLandscapeSideRails
                  ? landscapeBottomRailWidth + toolbarCanvasGap
                  : 0.0;
              final landscapeRightInset = useLandscapeSideRails
                  ? landscapeTopRailWidth + toolbarCanvasGap
                  : 0.0;
              final bottomPanelUsesSideRail =
                  useLandscapeSideRails &&
                  _activeInlineMode == _BottomInlineMode.none &&
                  !_isCropMode &&
                  !_isAdjustMode &&
                  !_isPhotoEraserMode &&
                  !_isPhotoStretchMode &&
                  !_isContentAwareMode &&
                  !_isPhotoCloneMode &&
                  !_isDrawBrushMode &&
                  !_isLayerMaskBrushMode &&
                  !_showTextControls &&
                  !_showLayerStyleQuickControls;
              final selectedLayerCanEdit =
                  _selectedLayerId != null && !_isSelectedLayerLocked;
              final reservedTopInset = useLandscapeSideRails
                  ? 0.0
                  : _topBarHeight + toolbarCanvasGap;
              final reservedBottomInset = useLandscapeSideRails
                  ? 0.0
                  : floatingBottom +
                        visibleBottomToolsHeight +
                        toolbarCanvasGap;
              final workspaceHeight = math.max(
                canvasSize.height - reservedTopInset - reservedBottomInset,
                0.0,
              );
              final workspaceWidth = math.max(
                canvasSize.width - landscapeLeftInset - landscapeRightInset,
                0.0,
              );
              final workspaceSize = Size(workspaceWidth, workspaceHeight);
              final workspaceViewportSize = workspaceSize;
              final workspaceFrameTop = useLandscapeSideRails
                  ? 0.0
                  : reservedTopInset;
              final workspaceFrameBottom = useLandscapeSideRails
                  ? 0.0
                  : reservedBottomInset;
              _lastCanvasSize = workspaceViewportSize;
              final hasPageSelection = (_pageAspectRatio ?? 0) > 0;
              final pageSize = hasPageSelection
                  ? _fitPageSize(
                      workspaceSize: workspaceSize,
                      aspectRatio: _pageAspectRatio!,
                      preferFullWidth: widget.preferFullWidthCanvas,
                      forceFullWidth: _pageAspectRatioAutoFromImage,
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
              final nudgeControlSize = _layerNudgeControlExpanded
                  ? _FloatingLayerNudgeControl.expandedSize
                  : _FloatingLayerNudgeControl.collapsedSize;
              final nudgeMaxX = math.max(
                0.0,
                canvasSize.width - nudgeControlSize,
              );
              final nudgeMaxY = math.max(
                0.0,
                canvasSize.height - nudgeControlSize,
              );
              final nudgePosition = Offset(
                _layerNudgeControlOffset.dx.clamp(0.0, nudgeMaxX).toDouble(),
                _layerNudgeControlOffset.dy.clamp(0.0, nudgeMaxY).toDouble(),
              );
              final nudgeAtEdge =
                  nudgePosition.dx <= 0.5 ||
                  nudgePosition.dy <= 0.5 ||
                  (nudgeMaxX - nudgePosition.dx).abs() <= 0.5 ||
                  (nudgeMaxY - nudgePosition.dy).abs() <= 0.5;

              return Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(color: _editorCanvasBackdrop),
                    ),
                  ),
                  Positioned(
                    left: landscapeLeftInset,
                    right: landscapeRightInset,
                    top: workspaceFrameTop,
                    bottom: workspaceFrameBottom,
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: _handleWorkspacePointerDown,
                      onPointerMove: _handleWorkspacePointerMove,
                      onPointerUp: _handleWorkspacePointerEnd,
                      onPointerCancel: _handleWorkspacePointerEnd,
                      child: IgnorePointer(
                        ignoring: _isWorkspacePinching,
                        child: AnimatedContainer(
                          transform: Matrix4.identity()
                            ..translateByDouble(
                              _workspacePan.dx,
                              _workspacePan.dy,
                              0,
                              1,
                            )
                            ..scaleByDouble(
                              _workspaceZoom,
                              _workspaceZoom,
                              1,
                              1,
                            ),
                          transformAlignment: Alignment.center,
                          duration: _isWorkspacePinching
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          child: RepaintBoundary(
                            key: _stageRepaintKey,
                            child: _CanvasWorkspace(
                              layers: _layers,
                              selectedLayerId: _selectedLayerId,
                              canvasBackgroundColor: _canvasBackgroundColor,
                              canvasBackgroundGradientIndex:
                                  _canvasBackgroundGradientIndex,
                              stageBackgroundImageBytes:
                                  _stageBackgroundImageBytes,
                              backgroundBlurAmount: _backgroundBlurAmount,
                              borderStyle: _borderStyle,
                              borderWidth: _borderWidth,
                              borderRadius: _borderRadius,
                              borderColor: _borderColor,
                              borderTargetLayerId: _borderTargetLayerId,
                              canvasSize: workspaceViewportSize,
                              pageAspectRatio: _pageAspectRatio,
                              hideAutoPageFrame: _pageAspectRatioAutoFromImage,
                              showTransparentCheckerboard:
                                  (widget.initialDesignImportPath ?? '')
                                      .trim()
                                      .isEmpty,
                              topInset: 0,
                              bottomInset: 0,
                              viewportScale: _workspaceZoom,
                              transformationController:
                                  _transformationController,
                              onLayerSelected: _autoSelectCanvasLayer
                                  ? _handleLayerSelected
                                  : (_) {},
                              onSelectedLayerInteractionStart:
                                  _handleSelectedLayerInteractionStart,
                              onSelectedLayerScaleUpdate:
                                  _handleSelectedLayerScaleUpdate,
                              onSelectedLayerInteractionEnd:
                                  _handleSelectedLayerInteractionEnd,
                              onSelectedTransformHandlePointerDown:
                                  _handleSelectedTransformHandlePointerDown,
                              onSelectedStickerHandleStart:
                                  _handleSelectedStickerResizeHandleStart,
                              onSelectedStickerHandleUpdate:
                                  _handleSelectedStickerResizeHandleUpdate,
                              onSelectedObjectHorizontalResizeHandleStart:
                                  _handleSelectedObjectHorizontalResizeHandleStart,
                              onSelectedObjectHorizontalResizeHandleUpdate:
                                  _handleSelectedObjectHorizontalResizeHandleUpdate,
                              onSelectedObjectVerticalResizeHandleStart:
                                  _handleSelectedObjectVerticalResizeHandleStart,
                              onSelectedObjectVerticalResizeHandleUpdate:
                                  _handleSelectedObjectVerticalResizeHandleUpdate,
                              onSelectedStickerRotateHandleStart:
                                  _handleSelectedStickerRotateHandleStart,
                              onSelectedStickerRotateHandleUpdate:
                                  _handleSelectedStickerRotateHandleUpdate,
                              onSelectedTextResizeHandleStart:
                                  _handleSelectedTextResizeHandleStart,
                              onSelectedTextResizeHandleUpdate:
                                  _handleSelectedTextResizeHandleUpdate,
                              onSelectedTextRotateHandleStart:
                                  _handleSelectedTextRotateHandleStart,
                              onSelectedTextRotateHandleUpdate:
                                  _handleSelectedTextRotateHandleUpdate,
                              onSelectedTextStretchHandleStart:
                                  _handleSelectedTextStretchHandleStart,
                              onSelectedTextStretchHandleUpdate:
                                  _handleSelectedTextStretchHandleUpdate,
                              onSelectedStickerHandleEnd:
                                  _handleSelectedStickerHandleEnd,
                              onSelectedLayerDoubleTap:
                                  _resetSelectedLayerToFit,
                              onSelectedTextTap: _handleSelectedTextTap,
                              onSelectedTextDoubleTap:
                                  _handleSelectedTextDoubleTap,
                              onSelectedTextPointerDown:
                                  _startSelectedTextLongPress,
                              onSelectedTextPointerMove:
                                  _updateSelectedTextLongPress,
                              onSelectedTextPointerCancel:
                                  _cancelSelectedTextLongPress,
                              isTextTypingScreenOpen: _isTextTypingScreenOpen,
                              isPhotoEraserMode: _isPhotoEraserMode,
                              isPhotoStretchMode: _isPhotoStretchMode,
                              isContentAwareMode: _isContentAwareMode,
                              isPhotoCloneMode: _isPhotoCloneMode,
                              isLayerMaskBrushMode: _isLayerMaskBrushMode,
                              isDrawBrushMode: _isDrawBrushMode,
                              onPhotoEraserStart: _handlePhotoEraserStart,
                              onPhotoEraserUpdate: _handlePhotoEraserUpdate,
                              onPhotoEraserEnd: _handlePhotoEraserEnd,
                              onPhotoEraserCancel: _cancelPhotoEraserStroke,
                              onContentAwareStart: _handleContentAwareStart,
                              onContentAwareUpdate: _handleContentAwareUpdate,
                              onContentAwareEnd: () =>
                                  unawaited(_handleContentAwareEnd()),
                              onContentAwareCancel: _cancelContentAwareStroke,
                              onContentAwarePointerDown:
                                  _handleContentAwarePointerDown,
                              onContentAwarePointerEnd:
                                  _handleContentAwarePointerEnd,
                              canUseContentAwarePointerStroke:
                                  _canUseContentAwarePointerStroke,
                              onPhotoCloneSourceTap: _handlePhotoCloneSourceTap,
                              onPhotoCloneStart: _handlePhotoCloneStart,
                              onPhotoCloneUpdate: _handlePhotoCloneUpdate,
                              onPhotoCloneEnd: () =>
                                  unawaited(_handlePhotoCloneEnd()),
                              onPhotoCloneCancel: _cancelPhotoCloneStroke,
                              onPhotoStretchStart: _handlePhotoStretchStart,
                              onPhotoStretchUpdate: _handlePhotoStretchUpdate,
                              onPhotoStretchEnd: () =>
                                  unawaited(_handlePhotoStretchEnd()),
                              onPhotoStretchCancel: _cancelPhotoStretchStroke,
                              onLayerMaskBrushStart: _handleLayerMaskBrushStart,
                              onLayerMaskBrushUpdate:
                                  _handleLayerMaskBrushUpdate,
                              onLayerMaskBrushEnd: _handleLayerMaskBrushEnd,
                              onLayerMaskBrushCancel:
                                  _cancelLayerMaskBrushStroke,
                              onDrawBrushStart: _handleDrawBrushStart,
                              onDrawBrushUpdate: _handleDrawBrushUpdate,
                              onDrawBrushEnd: _handleDrawBrushEnd,
                              onDrawBrushCancel: _cancelDrawBrushStroke,
                              onCanvasTapDown: _isCropMode
                                  ? (
                                      Offset _,
                                      Rect pageRectIgnored,
                                      Size pageSizeIgnored,
                                    ) {}
                                  : _handleCanvasTapDown,
                              onCanvasLongPressStart: _isCropMode
                                  ? (
                                      Offset globalPositionIgnored,
                                      Offset localPositionIgnored,
                                      Rect pageRectIgnored,
                                      Size pageSizeIgnored,
                                    ) {}
                                  : _handleCanvasLongPressStart,
                              onCanvasTap: _isCropMode
                                  ? () {}
                                  : _handleCanvasTap,
                              routeCanvasGesturesToSelectedLayer:
                                  !_autoSelectCanvasLayer &&
                                  selectedLayerCanEdit &&
                                  _showSelectedLayerHandles &&
                                  !_isCropMode &&
                                  !_isPhotoEraserMode &&
                                  !_isPhotoStretchMode &&
                                  !_isContentAwareMode &&
                                  !_isPhotoCloneMode &&
                                  !_isLayerMaskBrushMode &&
                                  !_isDrawBrushMode &&
                                  !_isPhotoMaskPositionMode &&
                                  !_isMagicWandMode &&
                                  !_isTextPlacementMode &&
                                  !_isTextTypingScreenOpen,
                              showCanvasBackground:
                                  !_isTransparentExportCapture,
                              photoBrightnessForLayer:
                                  _effectivePhotoBrightness,
                              photoContrastForLayer: _effectivePhotoContrast,
                              photoSaturationForLayer:
                                  _effectivePhotoSaturation,
                              photoBlurForLayer: _effectivePhotoBlur,
                              photoSharpenForLayer: _effectivePhotoSharpen,
                              photoGrainForLayer: _effectivePhotoGrain,
                              photoVignetteForLayer: _effectivePhotoVignette,
                              photoMotionForLayer: _effectivePhotoMotion,
                              photoTiltShiftForLayer: _effectivePhotoTiltShift,
                              photoShadowsForLayer: _effectivePhotoShadows,
                              photoHighlightsForLayer:
                                  _effectivePhotoHighlights,
                              photoTemperatureForLayer:
                                  _effectivePhotoTemperature,
                              photoTintForLayer: _effectivePhotoTint,
                              showSelectionDecorations:
                                  _showSelectedLayerHandles &&
                                  !_isCropMode &&
                                  !_isPhotoEraserMode &&
                                  !_isContentAwareMode &&
                                  !_isPhotoCloneMode &&
                                  !_isLayerMaskBrushMode &&
                                  !_isDrawBrushMode &&
                                  !_isExporting &&
                                  !_isCapturingStage &&
                                  !_isLayerInteracting &&
                                  !_isWorkspacePinching,
                              isLayerInteracting: _isLayerInteracting,
                              showPageFramePreview:
                                  !_isExporting && !_isCapturingStage,
                              snapGuideListenable: _snapGuideNotifier,
                              snapGuidesEnabled:
                                  !_isCropMode &&
                                  !_isCapturingStage &&
                                  !_isWorkspacePinching,
                              selectedPhotoRenderListenable:
                                  _selectedPhotoRenderNotifier,
                              eraserPreviewListenable: _eraserPreviewNotifier,
                              stretchPreviewListenable: _stretchPreviewNotifier,
                              drawPreviewListenable: _drawPreviewNotifier,
                              exportHighQuality: _isCapturingStage,
                              preferFullWidthPage: widget.preferFullWidthCanvas,
                              forceFullWidthPage: _pageAspectRatioAutoFromImage,
                            ),
                          ),
                        ),
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
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_showLayersAdvancedPanel,
                      child: AnimatedOpacity(
                        opacity: _showLayersAdvancedPanel ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: _AdvancedLayersFullscreenOverlay(
                          layers: _layers,
                          selectedLayerId: _selectedLayerId,
                          autoSelectCanvasLayer: _autoSelectCanvasLayer,
                          onAutoSelectCanvasLayerTap:
                              _toggleCanvasAutoSelectLayer,
                          onSelectLayer: _handleLayerSelected,
                          onDeleteLayer: _deleteLayerById,
                          onToggleLayerLock: _toggleLayerLockById,
                          onToggleLayerVisibility: _toggleLayerVisibilityById,
                          onReorderLayers: _reorderLayersFromAdvancedView,
                          onMoveToFront: _moveLayerToFrontById,
                          onMoveToBack: _moveLayerToBackById,
                          onEditText: _editLayerTextById,
                          onBlendModeChanged: _setLayerBlendMode,
                          onClose: _closeLayersAdvancedPanel,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: useLandscapeSideRails ? null : 0,
                    right: useLandscapeSideRails ? 8 : 0,
                    top: useLandscapeSideRails ? 4 : 0,
                    bottom: useLandscapeSideRails ? 4 : null,
                    width: useLandscapeSideRails ? landscapeTopRailWidth : null,
                    child: RepaintBoundary(
                      child: _TopBar(
                        height: useLandscapeSideRails
                            ? canvasSize.height - 8
                            : _topBarHeight,
                        vertical: useLandscapeSideRails,
                        onUndoTap: _handleUndo,
                        onRedoTap: _handleRedo,
                        onDraftsTap: _openDraftsScreen,
                        onShareTap: _handleShareTap,
                        onDownloadTap: _handleDownloadTap,
                        onExportTap: _handleExportTap,
                        onDeleteTap: _handleDeleteSelectedLayer,
                        onDuplicateTap: _handleDuplicateSelectedLayer,
                        onBringFrontTap: _moveSelectedLayerToFront,
                        onSendBackTap: _moveSelectedLayerToBack,
                        onLayersTap: _openLayersAdvancedOverlay,
                        onUniversalLayerStyleTap: _openLayerStyleQuickControls,
                        onCopyLayerStyleTap: _copySelectedLayerStyle,
                        onPasteLayerStyleTap: _pasteCopiedLayerStyleToSelected,
                        autoSelectCanvasLayer: _autoSelectCanvasLayer,
                        onAutoSelectCanvasLayerTap:
                            _toggleCanvasAutoSelectLayer,
                        selectionHandlesVisible: _showSelectedLayerHandles,
                        onSelectLayerTap: _showSelectedLayerSelection,
                        onShowMainToolsTap: _clearSelection,
                        onAlignHorizontalCenterTap:
                            _alignSelectedLayerHorizontalCenter,
                        onAlignVerticalCenterTap:
                            _alignSelectedLayerVerticalCenter,
                        canUndo: _canUndo,
                        canRedo: _canRedo,
                        isSharing: _isSharing,
                        isExporting: _isExporting,
                        canDelete: selectedLayerCanEdit,
                        canDuplicate: selectedLayerCanEdit,
                        canPasteLayerStyle:
                            selectedLayerCanEdit && _copiedLayerStyle != null,
                        canBringFront:
                            selectedLayerCanEdit &&
                            _selectedLayerIndex != -1 &&
                            _selectedLayerIndex < _layers.length - 1,
                        canSendBack:
                            selectedLayerCanEdit && _selectedLayerIndex > 0,
                        canAlignSelectedLayer: selectedLayerCanEdit,
                        hasSelectedTextLayer: _hasSelectedEditableTextLayer,
                        hasSelectedPhotoLayer:
                            _hasSelectedPhotoLayer &&
                            !_hasSelectedEditableTextLayer &&
                            selectedLayerCanEdit,
                        hasSelectedStickerLayer:
                            (_selectedLayer?.isSticker ?? false) &&
                            selectedLayerCanEdit,
                        isBorderToolActive:
                            _activeInlineMode == _BottomInlineMode.border,
                        activeBorderStyle: _borderStyle,
                        activeBorderColor: _borderColor,
                        activeTextToolTab: _activeTextToolTab,
                        activeMainToolLabel: _activeMainToolLabel,
                        selectedLayer: _selectedLayer,
                        savedEffectPresets: _savedTextEffectPresets,
                        copiedTextEffect: _copiedTextEffect,
                        onTextEditTap: _handleSelectedTextEditButtonTap,
                        onTextStyleTap: () =>
                            unawaited(_handleTextStyleQuickTap()),
                        onTextFontTap: () =>
                            unawaited(_handleTextFontQuickTap()),
                        onTextColorTap: () =>
                            unawaited(_handleTextColorQuickTap()),
                        onTextEffectsTap: _handleTextEffectsQuickTap,
                        onTextAlignLeftTap: () =>
                            _setSelectedTextAlignment(TextAlign.left),
                        onTextAlignCenterTap: () =>
                            _setSelectedTextAlignment(TextAlign.center),
                        onTextAlignRightTap: () =>
                            _setSelectedTextAlignment(TextAlign.right),
                        onEffectPresetSelected: _applySelectedTextEffectPreset,
                        onCopyTextEffect: _copySelectedTextEffect,
                        onPasteTextEffect: _pasteCopiedTextEffect,
                        onSaveTextEffectPreset: _saveSelectedTextEffectPreset,
                        onSavedTextEffectPresetSelected:
                            _applySavedTextEffectPreset,
                        onPhotoCropTap: () => unawaited(_handleCropPhotoTap()),
                        onPhotoFitTap: _resetSelectedLayerToFit,
                        onPhotoEraserTap: _activatePhotoEraserMode,
                        onPhotoContentAwareTap: _activateContentAwareMode,
                        onPhotoAdjustTap: _openAdjustPanel,
                        onPhotoRemoveBgTap: () =>
                            unawaited(_handleRemoveBackgroundTap()),
                        onPhotoStyleTap: () =>
                            unawaited(_openSelectedPhotoStyleOverlay()),
                        onPhotoFlipHorizontalTap: _flipSelectedPhotoHorizontal,
                        onPhotoFlipVerticalTap: _flipSelectedPhotoVertical,
                        onPhotoMaskTap: () =>
                            unawaited(_openPhotoMaskPickerOverlay()),
                        onPhotoPerspectiveTap: () =>
                            unawaited(_openSelectedPhotoPerspectiveOverlay()),
                        onPhotoCloneTap: _activatePhotoCloneMode,
                        onPhotoStretchTap: _activatePhotoStretchMode,
                        onPhotoSelectionTap: () =>
                            unawaited(_openSelectedPhotoSelectionTool()),
                        onSelectedRotate90Tap: _rotateSelectedLayer90Degrees,
                        onStickerColorTap: () =>
                            unawaited(_openStickerColorPickerOverlay()),
                        onFrameColorTap: () =>
                            unawaited(_openSelectedFrameColorPickerOverlay()),
                        onBorderColorTap: () =>
                            unawaited(_openBorderColorPickerOverlay()),
                        onBorderRemoveTap: () =>
                            _applyBorderStyle(_BorderStyle.none),
                      ),
                    ),
                  ),
                  if (!_isTextTypingScreenOpen &&
                      !_isExporting &&
                      !_isCapturingStage)
                    Positioned(
                      left: nudgePosition.dx,
                      top: nudgePosition.dy,
                      child: _FloatingLayerNudgeControl(
                        expanded: _layerNudgeControlExpanded,
                        canNudge: selectedLayerCanEdit,
                        isAtEdge: nudgeAtEdge,
                        onToggle: () {
                          setState(() {
                            _layerNudgeControlExpanded =
                                !_layerNudgeControlExpanded;
                          });
                        },
                        onNudge: _nudgeSelectedLayer,
                        onDragUpdate: (details) {
                          setState(() {
                            _layerNudgeControlOffset = Offset(
                              (_layerNudgeControlOffset.dx + details.delta.dx)
                                  .clamp(0.0, nudgeMaxX)
                                  .toDouble(),
                              (_layerNudgeControlOffset.dy + details.delta.dy)
                                  .clamp(0.0, nudgeMaxY)
                                  .toDouble(),
                            );
                          });
                        },
                        onDragEnd: (_) {
                          const snapDistance = 28.0;
                          final distances = <double>[
                            nudgePosition.dx,
                            nudgePosition.dy,
                            nudgeMaxX - nudgePosition.dx,
                            nudgeMaxY - nudgePosition.dy,
                          ];
                          final nearest = distances.reduce(math.min);
                          if (nearest > snapDistance) {
                            return;
                          }
                          setState(() {
                            _layerNudgeControlExpanded = false;
                            if (nearest == distances[0]) {
                              _layerNudgeControlOffset = Offset(
                                0,
                                nudgePosition.dy,
                              );
                            } else if (nearest == distances[1]) {
                              _layerNudgeControlOffset = Offset(
                                nudgePosition.dx,
                                0,
                              );
                            } else if (nearest == distances[2]) {
                              _layerNudgeControlOffset = Offset(
                                nudgeMaxX,
                                nudgePosition.dy,
                              );
                            } else {
                              _layerNudgeControlOffset = Offset(
                                nudgePosition.dx,
                                nudgeMaxY,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  if (_isCropMode) const SizedBox.shrink(),
                  if (_showLayerStyleQuickControls &&
                      selectedLayerCanEdit &&
                      !_isKeyboardVisible &&
                      !_isTextTypingScreenOpen &&
                      !_isExporting &&
                      !_isCapturingStage)
                    Positioned(
                      left: useLandscapeSideRails
                          ? landscapeBottomRailWidth + toolbarCanvasGap
                          : 0,
                      right: useLandscapeSideRails
                          ? landscapeTopRailWidth + toolbarCanvasGap
                          : 0,
                      bottom: useLandscapeSideRails
                          ? 10
                          : floatingBottom + bottomToolsHeight + 8,
                      child: _LayerStyleQuickPanel(
                        height: _layerStyleQuickPanelHeight,
                        activeTab: _activeLayerStyleQuickTab,
                        layer: _selectedLayer,
                        gradients: _textGradients,
                        onChangeStart: (_) {
                          _layerStyleQuickBeforeLayer ??= _selectedLayer == null
                              ? null
                              : _cloneLayer(_selectedLayer!);
                        },
                        onChangeEnd: (_) => _commitLayerStyleQuickEdit(),
                        onUpdate: _updateSelectedLayerStyleQuick,
                      ),
                    ),
                  if (_isDrawBrushMode &&
                      _showDrawBrushSettings &&
                      !_isKeyboardVisible &&
                      !_isTextTypingScreenOpen &&
                      !_isExporting &&
                      !_isCapturingStage)
                    Positioned(
                      left: useLandscapeSideRails
                          ? landscapeBottomRailWidth + toolbarCanvasGap + 10
                          : 10,
                      right: useLandscapeSideRails
                          ? landscapeTopRailWidth + toolbarCanvasGap + 10
                          : 10,
                      bottom: useLandscapeSideRails
                          ? 10
                          : floatingBottom + bottomToolsHeight + 6,
                      child: RepaintBoundary(
                        child: _DrawBrushSettingsOverlay(
                          brushSize: _drawBrushSize,
                          opacity: _drawOpacity,
                          onBrushSizeChanged: _setDrawBrushSize,
                          onOpacityChanged: _setDrawBrushOpacity,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: bottomPanelUsesSideRail ? null : 0,
                    top: bottomPanelUsesSideRail ? 4 : null,
                    bottom: bottomPanelUsesSideRail ? 4 : floatingBottom,
                    width: bottomPanelUsesSideRail
                        ? landscapeBottomRailWidth
                        : null,
                    child: RepaintBoundary(
                      child: _EditorGlassSurface(
                        borderRadius: BorderRadius.zero,
                        surfaceColor:
                            (_showLayerStyleQuickControls ||
                                showTextStyleQuickControls)
                            ? Colors.transparent
                            : _editorChromeSurfaceStrong.withValues(
                                alpha: 0.25,
                              ),
                        showBorder: false,
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
                                  key: const ValueKey<String>(
                                    'crop-inline-strip',
                                  ),
                                  child: _CropInlineStrip(
                                    height: bottomToolsHeight,
                                    isApplying: _isCropApplying,
                                    selectedAspectRatio:
                                        _cropSessionAspectRatio,
                                    onBack: _discardCropSession,
                                    onReset: _resetCropSession,
                                    onApply: _applyCropSession,
                                    onAspectRatioChanged: _setCropAspectRatio,
                                  ),
                                )
                              : _isAdjustMode
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'adjust-inline-strip',
                                  ),
                                  child: _AdjustInlineStrip(
                                    height: bottomToolsHeight,
                                    sessionListenable: _adjustSessionNotifier,
                                    onSessionChanged: _updateAdjustSessionState,
                                    onBack: _discardAdjustSession,
                                    onReset: _resetAdjustSession,
                                    onApply: _applyAdjustSession,
                                  ),
                                )
                              : _isPhotoEraserMode
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'photo-eraser-inline-strip',
                                  ),
                                  child: _PhotoEraserInlineStrip(
                                    height: bottomToolsHeight,
                                    brushSize: _eraserBrushSize,
                                    hardness: _eraserHardness,
                                    isBusy: _isCommitWorkerBusy,
                                    onBack: _closePhotoEraserMode,
                                    onBrushSizeChanged: (value) {
                                      setState(() {
                                        _eraserBrushSize = value;
                                      });
                                      _showEraserBrushCursorPreview();
                                    },
                                    onHardnessChanged: (value) {
                                      setState(() {
                                        _eraserHardness = value;
                                      });
                                      _showEraserBrushCursorPreview();
                                    },
                                  ),
                                )
                              : _isPhotoStretchMode
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'photo-stretch-inline-strip',
                                  ),
                                  child: _PhotoStretchInlineStrip(
                                    height: bottomToolsHeight,
                                    brushSize: _stretchBrushSize,
                                    strength: _stretchStrength,
                                    opacity: _stretchOpacity,
                                    isBusy: _isCommitWorkerBusy,
                                    onBack: _closePhotoStretchMode,
                                    onBrushSizeChanged: (value) {
                                      setState(() {
                                        _stretchBrushSize = value;
                                      });
                                      _showStretchBrushCursorPreview();
                                    },
                                    onStrengthChanged: (value) {
                                      setState(() {
                                        _stretchStrength = value;
                                      });
                                      _showStretchBrushCursorPreview();
                                    },
                                    onOpacityChanged: (value) {
                                      setState(() {
                                        _stretchOpacity = value;
                                      });
                                      _showStretchBrushCursorPreview();
                                    },
                                  ),
                                )
                              : _isContentAwareMode
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'content-aware-inline-strip',
                                  ),
                                  child: _PhotoEraserInlineStrip(
                                    height: bottomToolsHeight,
                                    brushSize: _contentAwareBrushSize,
                                    hardness: _contentAwareStrength,
                                    isBusy: _isCommitWorkerBusy,
                                    message:
                                        'Tap or drag over an object to blend it into the background',
                                    modeLabel: 'Content Aware',
                                    onBack: _closeContentAwareMode,
                                    onBrushSizeChanged: (value) {
                                      setState(() {
                                        _contentAwareBrushSize = value;
                                      });
                                      _showContentAwareBrushCursorPreview();
                                    },
                                    onHardnessChanged: (value) {
                                      setState(() {
                                        _contentAwareStrength = value;
                                      });
                                      _showContentAwareBrushCursorPreview();
                                    },
                                  ),
                                )
                              : _isPhotoCloneMode
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'photo-clone-inline-strip',
                                  ),
                                  child: _PhotoEraserInlineStrip(
                                    height: bottomToolsHeight,
                                    brushSize: _cloneBrushSize,
                                    hardness: _cloneHardness,
                                    isBusy: _isCommitWorkerBusy,
                                    message: _cloneSourcePoint == null
                                        ? 'Tap photo area to select clone source'
                                        : 'Drag where you want to apply clone',
                                    modeLabel: _cloneAligned
                                        ? 'Aligned'
                                        : 'Fixed',
                                    hardnessLabel: 'Feather',
                                    opacity: _cloneOpacity,
                                    onModeToggle: () {
                                      setState(() {
                                        _cloneAligned = !_cloneAligned;
                                        _cloneAlignedSampleOffset = null;
                                      });
                                      _showCloneBrushCursorPreview();
                                    },
                                    onBack: _closePhotoCloneMode,
                                    onBrushSizeChanged: (value) {
                                      setState(() {
                                        _cloneBrushSize = value;
                                      });
                                      _showCloneBrushCursorPreview();
                                    },
                                    onHardnessChanged: (value) {
                                      setState(() {
                                        _cloneHardness = value;
                                      });
                                      _showCloneBrushCursorPreview();
                                    },
                                    onOpacityChanged: (value) {
                                      setState(() {
                                        _cloneOpacity = value;
                                      });
                                      _showCloneBrushCursorPreview();
                                    },
                                  ),
                                )
                              : _isDrawBrushMode
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'draw-live-inline-strip',
                                  ),
                                  child: _DrawLiveInlineStrip(
                                    height: bottomToolsHeight,
                                    brushPresets: _drawBrushPresets,
                                    selectedBrush: _selectedDrawBrush,
                                    brushMasks: _drawBrushMasks,
                                    color: _drawColor,
                                    brushSize: _drawBrushSize,
                                    opacity: _drawOpacity,
                                    canUndo: _drawStrokes.isNotEmpty,
                                    canRedo: _drawRedoStrokes.isNotEmpty,
                                    canApply: _drawStrokes.isNotEmpty,
                                    onBack: _closeDrawBrushMode,
                                    onApply: _applyDrawBrushStrokes,
                                    onUndo: _undoDrawStroke,
                                    onRedo: _redoDrawStroke,
                                    onClear: _clearDrawStrokes,
                                    onBrushSelected: _selectDrawBrushPreset,
                                    showBrushSettings: _showDrawBrushSettings,
                                    onBrushSettingsChanged: (value) {
                                      setState(() {
                                        _showDrawBrushSettings = value;
                                      });
                                    },
                                    onBrushSizeChanged: _setDrawBrushSize,
                                    onOpacityChanged: _setDrawBrushOpacity,
                                  ),
                                )
                              : _isLayerMaskBrushMode
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'layer-mask-brush-inline-strip',
                                  ),
                                  child: _PhotoEraserInlineStrip(
                                    height: bottomToolsHeight,
                                    brushSize: _layerMaskBrushSize,
                                    hardness: _layerMaskBrushHardness,
                                    isBusy: false,
                                    message: _isLayerMaskBrushRestoreMode
                                        ? 'Drag on layer to restore mask area'
                                        : 'Drag on layer to hide mask area',
                                    modeLabel: _isLayerMaskBrushRestoreMode
                                        ? 'Restore'
                                        : 'Hide',
                                    onModeToggle:
                                        _toggleLayerMaskBrushRestoreMode,
                                    onBack: _closeLayerMaskBrushMode,
                                    onBrushSizeChanged: (value) {
                                      setState(() {
                                        _layerMaskBrushSize = value;
                                      });
                                      _showLayerMaskBrushCursorPreview();
                                    },
                                    onHardnessChanged: (value) {
                                      setState(() {
                                        _layerMaskBrushHardness = value;
                                      });
                                      _showLayerMaskBrushCursorPreview();
                                    },
                                  ),
                                )
                              : _activeInlineMode == _BottomInlineMode.layers
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'layers-inline-strip',
                                  ),
                                  child: _LayersInlineStrip(
                                    height: bottomToolsHeight,
                                    layers: _layers,
                                    selectedLayerId: _selectedLayerId,
                                    onBack: _closeInlineMode,
                                    onSelectLayer: _handleLayerSelected,
                                    onMoveToFront: _moveSelectedLayerToFront,
                                    onMoveToBack: _moveSelectedLayerToBack,
                                    onMoveForward: _moveSelectedLayerForwardOne,
                                    onMoveBackward:
                                        _moveSelectedLayerBackwardOne,
                                    onDeleteSelected:
                                        _handleDeleteSelectedLayer,
                                  ),
                                )
                              : _activeInlineMode == _BottomInlineMode.border
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'border-inline-strip',
                                  ),
                                  child: _BorderInlineStrip(
                                    height: bottomToolsHeight,
                                    borderWidth: _borderWidth,
                                    borderRadius: _borderRadius,
                                    onBack: _closeInlineMode,
                                    onWidthChangeStart: _beginBorderWidthEdit,
                                    onWidthChanged: _setBorderWidth,
                                    onWidthChangeEnd: _endBorderWidthEdit,
                                    onRadiusChangeStart: _beginBorderRadiusEdit,
                                    onRadiusChanged: _setBorderRadius,
                                    onRadiusChangeEnd: _endBorderRadiusEdit,
                                  ),
                                )
                              : _showTextControls
                              ? KeyedSubtree(
                                  key: ValueKey<String>(
                                    showTextStyleQuickControls
                                        ? 'text-style-quick-strip'
                                        : 'text-style-overlay',
                                  ),
                                  child: showTextStyleQuickControls
                                      ? _TextStyleQuickToolsStrip(
                                          height: bottomToolsHeight,
                                          layer: _selectedLayer,
                                          onBack: () {
                                            setState(() {
                                              _showTextControls = false;
                                            });
                                          },
                                          onBoldToggle: _toggleSelectedTextBold,
                                          onItalicToggle:
                                              _toggleSelectedTextItalic,
                                          onUnderlineToggle:
                                              _toggleSelectedTextUnderline,
                                          onAlignSelected:
                                              _setSelectedTextAlignment,
                                        )
                                      : _buildTextStyleOverlay(
                                          _textStyleBarHeight,
                                        ),
                                )
                              : _showLayerStyleQuickControls
                              ? KeyedSubtree(
                                  key: const ValueKey<String>(
                                    'layer-style-quick-strip',
                                  ),
                                  child: _LayerStyleQuickToolsStrip(
                                    height: bottomToolsHeight,
                                    activeTab: _activeLayerStyleQuickTab,
                                    onBack: _closeLayerStyleQuickControls,
                                    onTabSelected: (tab) {
                                      setState(() {
                                        _activeLayerStyleQuickTab = tab;
                                      });
                                      HapticFeedback.selectionClick();
                                    },
                                  ),
                                )
                              : _activeBottomPrimaryTool ==
                                    _BottomPrimaryTool.none
                              ? KeyedSubtree(
                                  key: const ValueKey<String>('main-strip'),
                                  child: _EditorMainToolsStrip(
                                    height: bottomToolsHeight,
                                    vertical: bottomPanelUsesSideRail,
                                    activeToolLabel: _activeMainToolLabel,
                                    onPhotoTap: () => _openBottomPrimaryTool(
                                      _BottomPrimaryTool.photo,
                                      'Photo',
                                    ),
                                    onTextTap: _handleMainTextToolTap,
                                    onBackgroundTap: () =>
                                        _openBottomPrimaryTool(
                                          _BottomPrimaryTool.background,
                                          'Background',
                                        ),
                                    onEffectsTap: _openAdjustPanel,
                                    onEraserTap: () {
                                      setState(() {
                                        _activeMainToolLabel = 'Erase';
                                      });
                                      _activatePhotoEraserMode();
                                    },
                                    onContentAwareTap: () {
                                      setState(() {
                                        _activeMainToolLabel = 'Content Aware';
                                      });
                                      _activateContentAwareMode();
                                    },
                                    onRemoveBgTap: () {
                                      setState(() {
                                        _activeMainToolLabel = 'Remove BG';
                                      });
                                      unawaited(_handleRemoveBackgroundTap());
                                    },
                                    onFitTap: () {
                                      setState(() {
                                        _activeMainToolLabel = 'Fit';
                                      });
                                      if (_selectedLayerId != null &&
                                          !_isSelectedLayerLocked) {
                                        _resetSelectedLayerToFit();
                                      } else {
                                        _openBottomPrimaryTool(
                                          _BottomPrimaryTool.background,
                                          'Fit',
                                        );
                                      }
                                    },
                                    onBrushesTap: () {
                                      setState(() {
                                        _activeMainToolLabel = 'Brushes';
                                      });
                                      _openBrushesTool();
                                    },
                                    onFramesTap: () {
                                      setState(() {
                                        _activeMainToolLabel = 'Frames';
                                      });
                                      unawaited(_openFramePickerOverlay());
                                    },
                                    onReplayTap: () {
                                      setState(() {
                                        _activeMainToolLabel = 'Replay';
                                      });
                                      unawaited(_openHistoryReplay());
                                    },
                                    onCropTap: _handleCropPhotoTap,
                                    onStickersTap: () =>
                                        unawaited(_openStickerBrowserOverlay()),
                                    onBorderTap: () => _openInlineMode(
                                      _BottomInlineMode.border,
                                    ),
                                  ),
                                )
                              : KeyedSubtree(
                                  key: ValueKey<String>(
                                    'sub-strip_${_activeBottomPrimaryTool.name}',
                                  ),
                                  child: _EditorSubToolsStrip(
                                    height: bottomToolsHeight,
                                    vertical: bottomPanelUsesSideRail,
                                    tool: _activeBottomPrimaryTool,
                                    onBack: _closeBottomPrimaryTool,
                                    onPhotoGalleryTap: _handleAddPhoto,
                                    onPhotoCameraTap: _handleAddPhotoFromCamera,
                                    onPhotoFileImportTap:
                                        _handleImportDesignFile,
                                    onPhotoMagicWandTap: _activateMagicWandMode,
                                    hasSelectedPhotoLayer:
                                        _hasSelectedPhotoLayer &&
                                        selectedLayerCanEdit,
                                    onPhotoCropTap: () =>
                                        unawaited(_handleCropPhotoTap()),
                                    onPhotoFitTap: _resetSelectedLayerToFit,
                                    onPhotoEraserTap: _activatePhotoEraserMode,
                                    onPhotoContentAwareTap:
                                        _activateContentAwareMode,
                                    onPhotoAdjustTap: _openAdjustPanel,
                                    onPhotoRemoveBgTap: () =>
                                        unawaited(_handleRemoveBackgroundTap()),
                                    onPhotoStyleTap: () => unawaited(
                                      _openSelectedPhotoStyleOverlay(),
                                    ),
                                    onPhotoFlipHorizontalTap:
                                        _flipSelectedPhotoHorizontal,
                                    onPhotoFlipVerticalTap:
                                        _flipSelectedPhotoVertical,
                                    onPhotoMaskTap: () => unawaited(
                                      _openPhotoMaskPickerOverlay(),
                                    ),
                                    onPhotoPerspectiveTap: () => unawaited(
                                      _openSelectedPhotoPerspectiveOverlay(),
                                    ),
                                    onPhotoCloneTap: _activatePhotoCloneMode,
                                    onPhotoStretchTap:
                                        _activatePhotoStretchMode,
                                    onPhotoSelectionTap: () => unawaited(
                                      _openSelectedPhotoSelectionTool(),
                                    ),
                                    onTextAddTap: _handleTextAddQuickTap,
                                    onTextFontTap: _handleTextFontQuickTap,
                                    onTextSizeTap: _handleTextSizeQuickTap,
                                    onTextBackgroundTap:
                                        _handleTextBackgroundQuickTap,
                                    onBackgroundTransparentTap: () =>
                                        _setCanvasBackgroundColor(
                                          Colors.transparent,
                                        ),
                                    onBackgroundColorTap: () => unawaited(
                                      _openBackgroundPickerOverlay(),
                                    ),
                                    onBackgroundGradientTap: () => unawaited(
                                      _openBackgroundPickerOverlay(),
                                    ),
                                    onBackgroundImageTap: () async {
                                      await _setCanvasBackgroundImage();
                                    },
                                  ),
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
                                compact: commitState.compact,
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
      ),
    );
  }
}

typedef _LayerStyleQuickUpdate =
    void Function({
      Color? strokeColor,
      double? strokeWidth,
      double? strokeOpacity,
      Color? shadowColor,
      double? shadowOpacity,
      double? shadowBlur,
      double? shadowSpread,
      double? shadowOffsetX,
      double? shadowOffsetY,
      Color? innerShadowColor,
      double? innerShadowOpacity,
      double? innerShadowBlur,
      double? innerShadowChoke,
      double? innerShadowDistance,
      double? innerShadowAngle,
      Color? outerGlowColor,
      double? outerGlowOpacity,
      double? outerGlowSize,
      double? outerGlowSpread,
      Color? overlayColor,
      double? overlayOpacity,
      bool? gradientOverlayEnabled,
      int? gradientOverlayIndex,
      double? gradientOverlayOpacity,
      double? gradientOverlayAngle,
    });

class _LayerStyleQuickPanel extends StatelessWidget {
  const _LayerStyleQuickPanel({
    required this.height,
    required this.activeTab,
    required this.layer,
    required this.gradients,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.onUpdate,
  });

  final double height;
  final _LayerStyleQuickTab activeTab;
  final _CanvasLayer? layer;
  final List<List<Color>> gradients;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;
  final _LayerStyleQuickUpdate onUpdate;

  @override
  Widget build(BuildContext context) {
    final current = layer;
    if (current == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: const Color(0x260B1220),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: KeyedSubtree(
            key: ValueKey<_LayerStyleQuickTab>(activeTab),
            child: _buildTabContent(current),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(_CanvasLayer current) {
    switch (activeTab) {
      case _LayerStyleQuickTab.stroke:
        return _QuickPanelBody(
          children: [
            _LayerStyleColorSlider(
              label: 'Color',
              color: current.layerStyleStrokeColor,
              onBlack: () => onUpdate(strokeColor: Colors.black),
              onWhite: () => onUpdate(strokeColor: Colors.white),
              onChangeStart: onChangeStart,
              onChangeEnd: onChangeEnd,
              onHueChanged: (color) => onUpdate(strokeColor: color),
            ),
            _LayerStyleQuickSlider(
              label: 'Size',
              value: current.layerStyleStrokeWidth,
              min: 0,
              max: 36,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(strokeWidth: value),
              onChangeEnd: onChangeEnd,
            ),
            _LayerStyleQuickSlider(
              label: 'Opacity',
              value: current.layerStyleStrokeOpacity * 100,
              min: 0,
              max: 100,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(strokeOpacity: value / 100),
              onChangeEnd: onChangeEnd,
            ),
          ],
        );
      case _LayerStyleQuickTab.shadow:
        return _QuickPanelBody(
          children: [
            _LayerStyleColorSlider(
              label: 'Color',
              color: current.layerStyleShadowColor,
              onBlack: () => onUpdate(shadowColor: Colors.black),
              onWhite: () => onUpdate(shadowColor: Colors.white),
              onChangeStart: onChangeStart,
              onChangeEnd: onChangeEnd,
              onHueChanged: (color) => onUpdate(shadowColor: color),
            ),
            _LayerStyleQuickSlider(
              label: 'Opacity',
              value: current.layerStyleShadowOpacity * 100,
              min: 0,
              max: 100,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(shadowOpacity: value / 100),
              onChangeEnd: onChangeEnd,
            ),
            _LayerStyleQuickSlider(
              label: 'Blur',
              value: current.layerStyleShadowBlur,
              min: 0,
              max: 56,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(shadowBlur: value),
              onChangeEnd: onChangeEnd,
            ),
            _LayerStyleQuickSlider(
              label: 'Y',
              value: current.layerStyleShadowOffsetY,
              min: -120,
              max: 120,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(shadowOffsetY: value),
              onChangeEnd: onChangeEnd,
            ),
          ],
        );
      case _LayerStyleQuickTab.glow:
        return _QuickPanelBody(
          children: [
            _LayerStyleColorSlider(
              label: 'Color',
              color: current.layerStyleOuterGlowColor,
              onBlack: () => onUpdate(outerGlowColor: Colors.black),
              onWhite: () => onUpdate(outerGlowColor: Colors.white),
              onChangeStart: onChangeStart,
              onChangeEnd: onChangeEnd,
              onHueChanged: (color) => onUpdate(outerGlowColor: color),
            ),
            _LayerStyleQuickSlider(
              label: 'Opacity',
              value: current.layerStyleOuterGlowOpacity * 100,
              min: 0,
              max: 100,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(outerGlowOpacity: value / 100),
              onChangeEnd: onChangeEnd,
            ),
            _LayerStyleQuickSlider(
              label: 'Size',
              value: current.layerStyleOuterGlowSize,
              min: 0,
              max: 64,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(outerGlowSize: value),
              onChangeEnd: onChangeEnd,
            ),
            _LayerStyleQuickSlider(
              label: 'Spread',
              value: current.layerStyleOuterGlowSpread,
              min: 0,
              max: 32,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(outerGlowSpread: value),
              onChangeEnd: onChangeEnd,
            ),
          ],
        );
      case _LayerStyleQuickTab.colorOverlay:
        return _QuickPanelBody(
          children: [
            _LayerStyleColorSlider(
              label: 'Color',
              color: current.layerStyleOverlayColor,
              onBlack: () => onUpdate(overlayColor: Colors.black),
              onWhite: () => onUpdate(overlayColor: Colors.white),
              onChangeStart: onChangeStart,
              onChangeEnd: onChangeEnd,
              onHueChanged: (color) => onUpdate(overlayColor: color),
            ),
            _LayerStyleQuickSlider(
              label: 'Color',
              value: current.layerStyleOverlayOpacity * 100,
              min: 0,
              max: 100,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(overlayOpacity: value / 100),
              onChangeEnd: onChangeEnd,
            ),
          ],
        );
      case _LayerStyleQuickTab.gradient:
        return _QuickPanelBody(
          children: [
            _LayerStyleGradientStrip(
              gradients: gradients,
              selectedIndex: current.layerStyleGradientOverlayIndex,
              onChangeStart: onChangeStart,
              onChangeEnd: onChangeEnd,
              onSelected: (index) {
                onUpdate(
                  gradientOverlayEnabled: true,
                  gradientOverlayIndex: index,
                  gradientOverlayOpacity:
                      current.layerStyleGradientOverlayOpacity <= 0.001
                      ? 0.65
                      : current.layerStyleGradientOverlayOpacity,
                );
              },
            ),
            _LayerStyleQuickSlider(
              label: 'Opacity',
              value: current.layerStyleGradientOverlayOpacity * 100,
              min: 0,
              max: 100,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(
                gradientOverlayEnabled: value > 0,
                gradientOverlayOpacity: value / 100,
              ),
              onChangeEnd: onChangeEnd,
            ),
            _LayerStyleQuickSlider(
              label: 'Angle',
              value: current.layerStyleGradientOverlayAngle,
              min: 0,
              max: 360,
              onChangeStart: onChangeStart,
              onChanged: (value) => onUpdate(
                gradientOverlayEnabled:
                    current.layerStyleGradientOverlayOpacity > 0.001,
                gradientOverlayAngle: value,
              ),
              onChangeEnd: onChangeEnd,
            ),
          ],
        );
    }
  }
}

class _QuickPanelBody extends StatelessWidget {
  const _QuickPanelBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 28),
      itemBuilder: (_, index) => children[index],
    );
  }
}

class _LayerStyleGradientStrip extends StatelessWidget {
  const _LayerStyleGradientStrip({
    required this.gradients,
    required this.selectedIndex,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.onSelected,
  });

  final List<List<Color>> gradients;
  final int selectedIndex;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final width = math.min(360.0, MediaQuery.sizeOf(context).width * 0.78);
    final safeSelected = gradients.isEmpty
        ? -1
        : selectedIndex.clamp(0, gradients.length - 1);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gradient',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                gradients.isEmpty ? '0' : '${safeSelected + 1}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: gradients.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == safeSelected;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => onChangeStart(index.toDouble()),
                  onTapCancel: () => onChangeEnd(index.toDouble()),
                  onTap: () {
                    onSelected(index);
                    onChangeEnd(index.toDouble());
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: selected ? 54 : 46,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(colors: gradients[index]),
                      border: Border.all(
                        color: selected ? Colors.black : Colors.white70,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerStyleQuickToolsStrip extends StatelessWidget {
  const _LayerStyleQuickToolsStrip({
    required this.height,
    required this.activeTab,
    required this.onBack,
    required this.onTabSelected,
  });

  final double height;
  final _LayerStyleQuickTab activeTab;
  final VoidCallback onBack;
  final ValueChanged<_LayerStyleQuickTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _LayerStyleToolButton(
            label: 'Close',
            icon: Icons.keyboard_arrow_down_rounded,
            selected: false,
            onTap: onBack,
          ),
          _LayerStyleToolButton(
            label: 'Stroke',
            icon: Icons.border_outer_rounded,
            selected: activeTab == _LayerStyleQuickTab.stroke,
            onTap: () => onTabSelected(_LayerStyleQuickTab.stroke),
          ),
          _LayerStyleToolButton(
            label: 'Shadow',
            icon: Icons.wb_twilight_rounded,
            selected: activeTab == _LayerStyleQuickTab.shadow,
            onTap: () => onTabSelected(_LayerStyleQuickTab.shadow),
          ),
          _LayerStyleToolButton(
            label: 'Glow',
            icon: Icons.blur_on_rounded,
            selected: activeTab == _LayerStyleQuickTab.glow,
            onTap: () => onTabSelected(_LayerStyleQuickTab.glow),
          ),
          _LayerStyleToolButton(
            label: 'Color',
            icon: Icons.invert_colors_rounded,
            selected: activeTab == _LayerStyleQuickTab.colorOverlay,
            onTap: () => onTabSelected(_LayerStyleQuickTab.colorOverlay),
          ),
          _LayerStyleToolButton(
            label: 'Gradient',
            icon: Icons.gradient_rounded,
            selected: activeTab == _LayerStyleQuickTab.gradient,
            onTap: () => onTabSelected(_LayerStyleQuickTab.gradient),
          ),
        ],
      ),
    );
  }
}

class _TextStyleQuickToolsStrip extends StatelessWidget {
  const _TextStyleQuickToolsStrip({
    required this.height,
    required this.layer,
    required this.onBack,
    required this.onBoldToggle,
    required this.onItalicToggle,
    required this.onUnderlineToggle,
    required this.onAlignSelected,
  });

  final double height;
  final _CanvasLayer? layer;
  final VoidCallback onBack;
  final VoidCallback onBoldToggle;
  final VoidCallback onItalicToggle;
  final VoidCallback onUnderlineToggle;
  final ValueChanged<TextAlign> onAlignSelected;

  @override
  Widget build(BuildContext context) {
    final textLayer = layer;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _TextStyleQuickIcon(
              tooltip: 'Close',
              icon: Icons.keyboard_arrow_down_rounded,
              selected: false,
              onTap: onBack,
            ),
            _TextStyleQuickIcon(
              tooltip: 'Bold',
              icon: Icons.format_bold_rounded,
              selected: textLayer?.isTextBold ?? false,
              onTap: onBoldToggle,
            ),
            _TextStyleQuickIcon(
              tooltip: 'Italic',
              icon: Icons.format_italic_rounded,
              selected: textLayer?.isTextItalic ?? false,
              onTap: onItalicToggle,
            ),
            _TextStyleQuickIcon(
              tooltip: 'Underline',
              icon: Icons.format_underline_rounded,
              selected: textLayer?.isTextUnderline ?? false,
              onTap: onUnderlineToggle,
            ),
            _TextStyleQuickIcon(
              tooltip: 'Left',
              icon: Icons.format_align_left_rounded,
              selected: textLayer?.textAlign == TextAlign.left,
              onTap: () => onAlignSelected(TextAlign.left),
            ),
            _TextStyleQuickIcon(
              tooltip: 'Center',
              icon: Icons.format_align_center_rounded,
              selected: textLayer?.textAlign == TextAlign.center,
              onTap: () => onAlignSelected(TextAlign.center),
            ),
            _TextStyleQuickIcon(
              tooltip: 'Right',
              icon: Icons.format_align_right_rounded,
              selected: textLayer?.textAlign == TextAlign.right,
              onTap: () => onAlignSelected(TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextStyleQuickIcon extends StatelessWidget {
  const _TextStyleQuickIcon({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: _PressableSurface(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 34,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.72)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 18,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ),
      ),
    );
  }
}

class _LayerStyleToolButton extends StatelessWidget {
  const _LayerStyleToolButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2563EB).withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFFBFDBFE)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFFD1D5DB),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFD1D5DB),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayerStyleQuickSlider extends StatelessWidget {
  const _LayerStyleQuickSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max).toDouble();
    double valueForDx(double dx, double width) {
      if (width <= 0 || (max - min).abs() < 0.001) {
        return clamped;
      }
      final raw = min + (dx.clamp(0.0, width) / width) * (max - min);
      final steps = math.max(1, (max - min).round());
      final stepped =
          min +
          (((raw - min) / (max - min)) * steps).round() / steps * (max - min);
      return stepped.clamp(min, max).toDouble();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return SizedBox(
          width: math.min(availableWidth * 0.82, 300.0).clamp(220.0, 300.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    clamped.round().toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              LayoutBuilder(
                builder: (context, trackConstraints) {
                  final trackWidth = trackConstraints.maxWidth;
                  final percent = (max - min).abs() < 0.001
                      ? 0.0
                      : ((clamped - min) / (max - min)).clamp(0.0, 1.0);
                  void update(Offset localPosition) {
                    onChanged(valueForDx(localPosition.dx, trackWidth));
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      final next = valueForDx(
                        details.localPosition.dx,
                        trackWidth,
                      );
                      onChangeStart(next);
                      onChanged(next);
                    },
                    onTapUp: (details) => onChangeEnd(
                      valueForDx(details.localPosition.dx, trackWidth),
                    ),
                    onTapCancel: () => onChangeEnd(clamped),
                    onHorizontalDragStart: (details) {
                      final next = valueForDx(
                        details.localPosition.dx,
                        trackWidth,
                      );
                      onChangeStart(next);
                      onChanged(next);
                    },
                    onHorizontalDragUpdate: (details) =>
                        update(details.localPosition),
                    onHorizontalDragEnd: (_) => onChangeEnd(clamped),
                    child: SizedBox(
                      height: 34,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned.fill(
                            top: 14,
                            bottom: 14,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: trackWidth * (1 - percent),
                            top: 14,
                            bottom: 14,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF60A5FA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (trackWidth * percent - 7).clamp(
                              0.0,
                              math.max(0.0, trackWidth - 14),
                            ),
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LayerStyleColorSlider extends StatelessWidget {
  const _LayerStyleColorSlider({
    required this.label,
    required this.color,
    required this.onBlack,
    required this.onWhite,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.onHueChanged,
  });

  final String label;
  final Color color;
  final VoidCallback onBlack;
  final VoidCallback onWhite;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;
  final ValueChanged<Color> onHueChanged;

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(color);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return SizedBox(
          width: math.min(availableWidth * 0.84, 320.0).clamp(220.0, 320.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  _LayerStyleColorDot(
                    color: Colors.black,
                    selected: color.computeLuminance() <= 0.02,
                    onTap: onBlack,
                  ),
                  const SizedBox(width: 8),
                  _LayerStyleColorDot(
                    color: Colors.white,
                    selected: hsv.saturation <= 0.04 && hsv.value >= 0.96,
                    onTap: onWhite,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 26,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _LayerStyleAllColorsSlider(
                hue: hsv.hue.clamp(0.0, 359.0).toDouble(),
                onChangeStart: onChangeStart,
                onChanged: (hue) {
                  final saturation = hsv.saturation <= 0.04
                      ? 1.0
                      : hsv.saturation;
                  final value = hsv.value <= 0.02 ? 1.0 : hsv.value;
                  onHueChanged(
                    HSVColor.fromAHSV(1, hue, saturation, value).toColor(),
                  );
                },
                onChangeEnd: onChangeEnd,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LayerStyleAllColorsSlider extends StatelessWidget {
  const _LayerStyleAllColorsSlider({
    required this.hue,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double hue;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  static const double _maxHue = 359;

  double _hueForDx(double dx, double width) {
    if (width <= 0) {
      return hue.clamp(0.0, _maxHue).toDouble();
    }
    return ((dx.clamp(0.0, width) / width) * _maxHue)
        .clamp(0.0, _maxHue)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          void updateFromLocal(Offset localPosition) {
            onChanged(_hueForDx(localPosition.dx, width));
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final next = _hueForDx(details.localPosition.dx, width);
              onChangeStart(next);
              onChanged(next);
            },
            onTapUp: (details) =>
                onChangeEnd(_hueForDx(details.localPosition.dx, width)),
            onTapCancel: () => onChangeEnd(hue),
            onHorizontalDragStart: (details) {
              final next = _hueForDx(details.localPosition.dx, width);
              onChangeStart(next);
              onChanged(next);
            },
            onHorizontalDragUpdate: (details) =>
                updateFromLocal(details.localPosition),
            onHorizontalDragEnd: (_) => onChangeEnd(hue),
            child: CustomPaint(
              painter: _LayerStyleAllColorsSliderPainter(hue: hue),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _LayerStyleAllColorsSliderPainter extends CustomPainter {
  const _LayerStyleAllColorsSliderPainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 7.0;
    final trackRect = Rect.fromLTWH(
      0,
      (size.height - trackHeight) / 2,
      size.width,
      trackHeight,
    );
    final rrect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(999),
    );
    final colors = List<Color>.generate(
      37,
      (index) => HSVColor.fromAHSV(1, index * 10.0, 1, 1).toColor(),
    );
    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(trackRect);
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    final thumbX = size.width <= 0
        ? 0.0
        : (hue.clamp(0.0, 359.0) / 359.0) * size.width;
    final thumbCenter = Offset(thumbX, size.height / 2);
    canvas.drawCircle(thumbCenter, 9, Paint()..color = const Color(0xCC000000));
    canvas.drawCircle(thumbCenter, 7, Paint()..color = Colors.white);
    canvas.drawCircle(
      thumbCenter,
      5,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _LayerStyleAllColorsSliderPainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

class _LayerStyleColorDot extends StatelessWidget {
  const _LayerStyleColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? const Color(0xFF60A5FA)
                : Colors.white.withValues(alpha: 0.45),
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
