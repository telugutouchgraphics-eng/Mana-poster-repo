import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mana_poster/features/editor/models/editor_element_asset.dart';
import 'package:mana_poster/features/editor/models/editor_architecture.dart';
import 'package:mana_poster/features/editor/models/editor_layer_entry.dart';
import 'package:mana_poster/features/editor/models/editor_sticker_asset.dart';
import 'package:mana_poster/features/editor/models/editor_stage.dart';
import 'package:mana_poster/features/editor/models/editor_text.dart';
import 'package:mana_poster/features/editor/constants/editor_font_catalog.dart';
import 'package:mana_poster/features/editor/services/background_removal_service.dart';
import 'package:mana_poster/features/editor/models/editor_tool.dart';
import 'package:mana_poster/features/editor/utils/editor_image_source.dart';

class EditorController extends ChangeNotifier {
  EditorController()
    : fontCatalog = kEditorFontCatalog,
      elementCatalog = const EditorElementCatalog(
        pngCategories: <String>['Devotional', 'Festival', 'Love', 'Frames'],
      ),
      smartGuides = const EditorSmartGuideConfig(),
      layerState = const EditorLayerSelectionState(layerIds: <String>['base']) {
    _stageBackground = const StageBackgroundConfig.solid(Colors.white);
    _lastCommittedState = _captureHistoryEntry();
  }

  final EditorFontCatalog fontCatalog;
  final EditorElementCatalog elementCatalog;
  final EditorSmartGuideConfig smartGuides;
  final EditorLayerSelectionState layerState;
  final BackgroundRemovalService _backgroundRemovalService =
      const HybridBackgroundRemovalService();

  static const double _mainSurfaceMinScale = 1.0;
  static const double _mainSurfaceMaxScale = 5.0;
  static const double _overlayMinScale = 0.28;
  static const double _overlayMaxScale = 5.0;
  static const double _rotationSnapThresholdRad = 0.12;
  static const double _rotationHardSnapThresholdRad = 0.04;
  static const double _guideCenterThreshold = 10;
  static const double _minVisiblePx = 56;

  EditorToolDefinition? _activeTool;
  static const int _historyLimit = 80;
  final List<_EditorHistoryEntry> _undoHistory = <_EditorHistoryEntry>[];
  final List<_EditorHistoryEntry> _redoHistory = <_EditorHistoryEntry>[];
  _EditorHistoryEntry? _lastCommittedState;

  StageBackgroundConfig _stageBackground = const StageBackgroundConfig.solid(
    Colors.white,
  );
  final List<Color> _recentBackgroundColors = <Color>[Colors.white];
  final List<String> _recentElementAssetIds = <String>[];
  final List<String> _recentStickerAssetIds = <String>[];
  int _backgroundSampleSeq = 0;
  StageSurfacePhoto? _mainSurfacePhoto;
  Size? _mainSurfaceImageSize;
  final List<StagePhotoLayer> _extraPhotoLayers = <StagePhotoLayer>[];
  final List<StageElementLayer> _elementLayers = <StageElementLayer>[];
  final List<StageStickerLayer> _stickerLayers = <StageStickerLayer>[];
  final List<StageDrawLayer> _drawLayers = <StageDrawLayer>[];
  final List<StageShapeLayer> _shapeLayers = <StageShapeLayer>[];
  int _photoSeq = 0;
  int _elementSeq = 0;
  int _stickerSeq = 0;
  int _drawSeq = 0;
  int _shapeSeq = 0;
  int _drawStrokeSeq = 0;
  String? _selectedExtraPhotoLayerId;
  String? _selectedElementLayerId;
  String? _selectedStickerLayerId;
  String? _selectedDrawLayerId;
  String? _selectedShapeLayerId;
  bool _isMainSurfaceSelected = false;

  Size _stageSize = Size.zero;
  double _mainSurfaceScale = 1;
  double _mainSurfaceRotation = 0;
  Offset _mainSurfaceOffset = Offset.zero;

  bool _showVerticalGuide = false;
  bool _showHorizontalGuide = false;
  bool _isTextLayerInteracting = false;
  String? _activeTextMoveLayerId;
  Offset _textMoveStartOffset = Offset.zero;
  double _textGestureStartScale = 1;
  double _textGestureStartRotation = 0;
  Offset _textGestureStartFocal = Offset.zero;
  bool _isExtraPhotoLayerInteracting = false;
  bool _isElementLayerInteracting = false;
  bool _isStickerLayerInteracting = false;
  bool _isShapeLayerInteracting = false;
  bool _cropSessionActive = false;
  _CropTargetType? _cropTargetType;
  String? _cropTargetLayerId;
  String _cropDraftRatioKey = 'free';
  int _cropDraftTurns = 0;
  String _cropInitialRatioKey = 'free';
  int _cropInitialTurns = 0;
  Size? _cropInitialSize;
  double _cropInitialRotation = 0;
  double? _mainSurfaceCropRatio;
  int _mainSurfaceCropTurns = 0;
  bool _adjustSessionActive = false;
  _AdjustTargetType? _adjustTargetType;
  String? _adjustTargetLayerId;
  PhotoAdjustments _adjustInitial = PhotoAdjustments.neutral;
  PhotoAdjustments _adjustDraft = PhotoAdjustments.neutral;
  bool _filterSessionActive = false;
  _FilterTargetType? _filterTargetType;
  String? _filterTargetLayerId;
  PhotoFilterConfig _filterInitial = PhotoFilterConfig.none;
  PhotoFilterConfig _filterDraft = PhotoFilterConfig.none;
  bool _borderFrameSessionActive = false;
  BorderFrameSection _borderFrameSection = BorderFrameSection.border;
  BorderFrameTarget _borderFrameTarget = BorderFrameTarget.selectedPhoto;
  DecorationStyleConfig _borderFrameInitial = DecorationStyleConfig.none;
  DecorationStyleConfig _borderFrameDraft = DecorationStyleConfig.none;
  final Set<String> _favoriteFramePresetIds = <String>{};
  final List<String> _recentFramePresetIds = <String>[];
  bool _removeBgSessionActive = false;
  _RemoveBgTargetType? _removeBgTargetType;
  String? _removeBgTargetLayerId;
  RemoveBgState _removeBgInitial = RemoveBgState.none;
  RemoveBgState _removeBgDraft = RemoveBgState.none;
  RemoveBgRefineMode _removeBgRefineMode = RemoveBgRefineMode.erase;
  double _removeBgBrushSize = 0.11;
  double _removeBgSoftness = 0.45;
  bool _removeBgIsProcessing = false;
  int _activeRemoveBgStrokeIndex = -1;
  bool _drawSessionActive = false;
  String? _drawEditingLayerId;
  List<DrawStroke> _drawInitialStrokes = <DrawStroke>[];
  List<DrawStroke> _drawDraftStrokes = <DrawStroke>[];
  final List<DrawStroke> _drawRedoStack = <DrawStroke>[];
  DrawToolMode _drawMode = DrawToolMode.pen;
  DrawBrushStyle _drawBrushStyle = DrawBrushStyle.smoothPen;
  Color _drawColor = const Color(0xFF111827);
  double _drawSize = 0.014;
  double _drawOpacity = 1;
  int? _activeDraftStrokeIndex;
  EditorToolId? _selectedLayerQuickActionTool;
  bool _isStageExportMode = false;
  bool _exportTransparentBackground = false;

  double _gestureStartScale = 1;
  double _gestureStartRotation = 0;
  Offset _gestureStartFocal = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;

  String? _activeExtraPhotoGestureLayerId;
  String? _activeElementGestureLayerId;
  String? _activeStickerGestureLayerId;
  String? _activeShapeGestureLayerId;
  double _extraPhotoGestureStartScale = 1;
  double _extraPhotoGestureStartRotation = 0;
  Offset _extraPhotoGestureStartOffset = Offset.zero;
  Offset _extraPhotoGestureStartFocal = Offset.zero;
  double _elementGestureStartScale = 1;
  double _elementGestureStartRotation = 0;
  Offset _elementGestureStartOffset = Offset.zero;
  Offset _elementGestureStartFocal = Offset.zero;
  double _stickerGestureStartScale = 1;
  double _stickerGestureStartRotation = 0;
  Offset _stickerGestureStartOffset = Offset.zero;
  Offset _stickerGestureStartFocal = Offset.zero;
  double _shapeGestureStartScale = 1;
  double _shapeGestureStartRotation = 0;
  Offset _shapeGestureStartOffset = Offset.zero;
  Offset _shapeGestureStartFocal = Offset.zero;

  final List<EditorTextLayer> _textLayers = <EditorTextLayer>[];
  int _textSeq = 0;
  String? _selectedTextLayerId;
  String? _pendingFullScreenTextEditorLayerId;
  bool _pendingLayersPanelRequest = false;
  bool _pendingPhotoPickerRequest = false;
  bool _pendingBackgroundImagePickerRequest = false;

  EditorToolDefinition? get activeTool => _activeTool;
  bool get hasActiveTool => _activeTool != null;
  bool get canUndo => _drawSessionActive
      ? _drawDraftStrokes.isNotEmpty
      : _undoHistory.isNotEmpty;
  bool get canRedo =>
      _drawSessionActive ? _drawRedoStack.isNotEmpty : _redoHistory.isNotEmpty;

  StageBackgroundConfig get stageBackground => _stageBackground;
  List<Color> get recentBackgroundColors =>
      List<Color>.unmodifiable(_recentBackgroundColors);

  List<List<Color>> get backgroundGradientPresets => _backgroundGradientOptions;
  List<String> get backgroundImageSamples => _backgroundImageUrls;
  StageSurfacePhoto? get mainSurfacePhoto => _mainSurfacePhoto;
  bool get isMainSurfaceSelected => _isMainSurfaceSelected;

  List<StageElementLayer> get elementLayers {
    final layers = List<StageElementLayer>.from(_elementLayers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return List<StageElementLayer>.unmodifiable(layers);
  }

  String? get selectedElementLayerId => _selectedElementLayerId;

  StageElementLayer? get selectedElementLayer {
    final id = _selectedElementLayerId;
    if (id == null) {
      return null;
    }
    return _findElementLayer(id);
  }

  List<StageStickerLayer> get stickerLayers {
    final layers = List<StageStickerLayer>.from(_stickerLayers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return List<StageStickerLayer>.unmodifiable(layers);
  }

  String? get selectedStickerLayerId => _selectedStickerLayerId;

  StageStickerLayer? get selectedStickerLayer {
    final id = _selectedStickerLayerId;
    if (id == null) {
      return null;
    }
    return _findStickerLayer(id);
  }

  List<StageShapeLayer> get shapeLayers {
    final layers = List<StageShapeLayer>.from(_shapeLayers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return List<StageShapeLayer>.unmodifiable(layers);
  }

  String? get selectedShapeLayerId => _selectedShapeLayerId;

  StageShapeLayer? get selectedShapeLayer {
    final id = _selectedShapeLayerId;
    if (id == null) {
      return null;
    }
    return _findShapeLayer(id);
  }

  List<StageDrawLayer> get drawLayers {
    final layers = List<StageDrawLayer>.from(_drawLayers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return List<StageDrawLayer>.unmodifiable(layers);
  }

  String? get selectedDrawLayerId => _selectedDrawLayerId;

  StageDrawLayer? get selectedDrawLayer {
    final id = _selectedDrawLayerId;
    if (id == null) {
      return null;
    }
    return _findDrawLayer(id);
  }

  List<StagePhotoLayer> get extraPhotoLayers {
    final layers = List<StagePhotoLayer>.from(_extraPhotoLayers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return List<StagePhotoLayer>.unmodifiable(layers);
  }

  String? get selectedExtraPhotoLayerId => _selectedExtraPhotoLayerId;

  StagePhotoLayer? get selectedExtraPhotoLayer {
    final id = _selectedExtraPhotoLayerId;
    if (id == null) {
      return null;
    }
    return _findExtraPhotoLayer(id);
  }

  bool get hasSelectedExtraPhotoLayer => selectedExtraPhotoLayer != null;

  double get mainSurfaceScale => _mainSurfaceScale;
  double get mainSurfaceRotation => _mainSurfaceRotation;
  Offset get mainSurfaceOffset => _mainSurfaceOffset;
  bool get showVerticalGuide => _showVerticalGuide;
  bool get showHorizontalGuide => _showHorizontalGuide;
  bool get isTextLayerInteracting => _isTextLayerInteracting;
  bool get isAnyLayerInteracting =>
      _isTextLayerInteracting ||
      _isExtraPhotoLayerInteracting ||
      _isElementLayerInteracting ||
      _isStickerLayerInteracting ||
      _isShapeLayerInteracting;

  bool get isPhotoLayerEditingContext {
    return hasSelectedExtraPhotoLayer ||
        _isMainSurfaceSelected ||
        _activeTool?.id == EditorToolId.photo;
  }

  bool get isElementsEditingContext {
    return _activeTool?.id == EditorToolId.elements ||
        selectedElementLayer != null;
  }

  bool get isStickersEditingContext {
    return _activeTool?.id == EditorToolId.stickers ||
        selectedStickerLayer != null;
  }

  bool get isShapesEditingContext =>
      _activeTool?.id == EditorToolId.shapes || selectedShapeLayer != null;

  bool get isDrawEditingContext =>
      _activeTool?.id == EditorToolId.draw ||
      selectedDrawLayer != null ||
      _drawSessionActive;

  List<EditorTextLayer> get textLayers {
    final layers = List<EditorTextLayer>.from(_textLayers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return List<EditorTextLayer>.unmodifiable(layers);
  }

  String? get selectedTextLayerId => _selectedTextLayerId;

  EditorTextLayer? get selectedTextLayer {
    final id = _selectedTextLayerId;
    if (id == null) {
      return null;
    }
    for (final layer in _textLayers) {
      if (layer.id == id) {
        return layer;
      }
    }
    return null;
  }

  bool get isTextEditingContext {
    return _activeTool?.id == EditorToolId.text || selectedTextLayer != null;
  }

  bool get isCropSessionActive => _cropSessionActive;
  String get cropDraftRatioKey => _cropDraftRatioKey;
  List<MapEntry<String, String>> get cropRatioOptions =>
      _cropRatioLabels.entries.toList(growable: false);
  bool get hasCropTargetForSession =>
      selectedExtraPhotoLayer != null || _isMainSurfaceSelected;
  double? get mainSurfaceCropRatio => _mainSurfaceCropRatio;
  int get mainSurfaceCropTurns => _mainSurfaceCropTurns;
  bool get isAdjustSessionActive => _adjustSessionActive;
  bool get hasAdjustTargetForSession =>
      selectedExtraPhotoLayer != null || _isMainSurfaceSelected;
  PhotoAdjustments get adjustDraft => _adjustDraft;
  bool get isFilterSessionActive => _filterSessionActive;
  bool get hasFilterTargetForSession =>
      selectedExtraPhotoLayer != null || _isMainSurfaceSelected;
  PhotoFilterConfig get filterDraft => _filterDraft;
  bool get isBorderFrameSessionActive => _borderFrameSessionActive;
  BorderFrameSection get borderFrameSection => _borderFrameSection;
  BorderFrameTarget get borderFrameTarget => _borderFrameTarget;
  DecorationStyleConfig get borderFrameDraft => _borderFrameDraft;
  List<FramePresetConfig> get framePresets => _framePresetCatalog;
  List<String> get favoriteFramePresetIds =>
      List<String>.unmodifiable(_favoriteFramePresetIds.toList());
  List<String> get recentFramePresetIds =>
      List<String>.unmodifiable(_recentFramePresetIds);
  bool get isRemoveBgSessionActive => _removeBgSessionActive;
  bool get hasRemoveBgTargetForSession =>
      selectedExtraPhotoLayer != null || _isMainSurfaceSelected;
  RemoveBgState get removeBgDraft => _removeBgDraft;
  RemoveBgRefineMode get removeBgRefineMode => _removeBgRefineMode;
  double get removeBgBrushSize => _removeBgBrushSize;
  double get removeBgSoftness => _removeBgSoftness;
  bool get isRemoveBgProcessing => _removeBgIsProcessing;
  bool get isRemoveBgRefineActive =>
      _removeBgSessionActive && _activeTool?.id == EditorToolId.removeBg;
  bool get isDrawSessionActive => _drawSessionActive;
  List<DrawStroke> get drawDraftStrokes =>
      List<DrawStroke>.unmodifiable(_drawDraftStrokes);
  DrawToolMode get drawMode => _drawMode;
  DrawBrushStyle get drawBrushStyle => _drawBrushStyle;
  Color get drawColor => _drawColor;
  double get drawSize => _drawSize;
  double get drawOpacity => _drawOpacity;
  bool get canUndoDrawStroke => _drawDraftStrokes.isNotEmpty;
  bool get canRedoDrawStroke => _drawRedoStack.isNotEmpty;
  bool get isStageExportMode => _isStageExportMode;
  bool get exportTransparentBackground => _exportTransparentBackground;
  EditorToolId? get selectedLayerQuickActionTool =>
      _selectedLayerQuickActionTool;
  bool get hasSelectedEditableLayer =>
      _isMainSurfaceSelected ||
      _selectedExtraPhotoLayerId != null ||
      _selectedTextLayerId != null ||
      _selectedElementLayerId != null ||
      _selectedStickerLayerId != null ||
      _selectedDrawLayerId != null ||
      _selectedShapeLayerId != null;
  bool get isSelectedLayerQuickActionOpen =>
      _selectedLayerQuickActionTool != null;

  bool get isSelectedLayerLocked {
    if (_isMainSurfaceSelected) {
      return _mainSurfacePhoto?.isLocked ?? false;
    }
    if (selectedExtraPhotoLayer != null) {
      return selectedExtraPhotoLayer!.isLocked;
    }
    if (selectedTextLayer != null) {
      return selectedTextLayer!.isLocked;
    }
    if (selectedElementLayer != null) {
      return selectedElementLayer!.isLocked;
    }
    if (selectedStickerLayer != null) {
      return selectedStickerLayer!.isLocked;
    }
    if (selectedDrawLayer != null) {
      return selectedDrawLayer!.isLocked;
    }
    if (selectedShapeLayer != null) {
      return selectedShapeLayer!.isLocked;
    }
    return false;
  }

  double get selectedLayerOpacity {
    if (_isMainSurfaceSelected) {
      return _mainSurfacePhoto?.visuals.opacity ?? 1;
    }
    if (selectedExtraPhotoLayer != null) {
      return selectedExtraPhotoLayer!.visuals.opacity;
    }
    if (selectedTextLayer != null) {
      return selectedTextLayer!.style.opacity;
    }
    if (selectedElementLayer != null) {
      return selectedElementLayer!.visuals.opacity;
    }
    if (selectedStickerLayer != null) {
      return selectedStickerLayer!.visuals.opacity;
    }
    if (selectedDrawLayer != null) {
      return selectedDrawLayer!.visuals.opacity;
    }
    if (selectedShapeLayer != null) {
      return selectedShapeLayer!.visuals.opacity;
    }
    return 1;
  }

  LayerShadowConfig get selectedLayerShadow {
    if (_isMainSurfaceSelected) {
      return _mainSurfacePhoto?.visuals.shadow ?? LayerShadowConfig.none;
    }
    if (selectedExtraPhotoLayer != null) {
      return selectedExtraPhotoLayer!.visuals.shadow;
    }
    if (selectedTextLayer != null) {
      final shadow = selectedTextLayer!.style.shadow;
      return LayerShadowConfig(
        color: shadow.color,
        blur: (shadow.blurRadius / 24).clamp(0.0, 1.0),
        distance: (shadow.offset.distance / 18).clamp(0.0, 1.0),
        opacity: shadow.color.a,
      );
    }
    if (selectedElementLayer != null) {
      return selectedElementLayer!.visuals.shadow;
    }
    if (selectedStickerLayer != null) {
      return selectedStickerLayer!.visuals.shadow;
    }
    if (selectedDrawLayer != null) {
      return selectedDrawLayer!.visuals.shadow;
    }
    if (selectedShapeLayer != null) {
      return selectedShapeLayer!.visuals.shadow;
    }
    return LayerShadowConfig.none;
  }

  LayerBlendModeOption get selectedLayerBlendMode {
    if (_isMainSurfaceSelected) {
      return _mainSurfacePhoto?.visuals.blendMode ??
          LayerBlendModeOption.normal;
    }
    if (selectedExtraPhotoLayer != null) {
      return selectedExtraPhotoLayer!.visuals.blendMode;
    }
    if (selectedTextLayer != null) {
      return selectedTextLayer!.blendMode;
    }
    if (selectedElementLayer != null) {
      return selectedElementLayer!.visuals.blendMode;
    }
    if (selectedStickerLayer != null) {
      return selectedStickerLayer!.visuals.blendMode;
    }
    if (selectedDrawLayer != null) {
      return selectedDrawLayer!.visuals.blendMode;
    }
    if (selectedShapeLayer != null) {
      return selectedShapeLayer!.visuals.blendMode;
    }
    return LayerBlendModeOption.normal;
  }

  bool get selectedLayerFlipX {
    if (_isMainSurfaceSelected) {
      return _mainSurfacePhoto?.visuals.flipX ?? false;
    }
    if (selectedExtraPhotoLayer != null) {
      return selectedExtraPhotoLayer!.visuals.flipX;
    }
    if (selectedTextLayer != null) {
      return selectedTextLayer!.isFlipped;
    }
    if (selectedElementLayer != null) {
      return selectedElementLayer!.visuals.flipX;
    }
    if (selectedStickerLayer != null) {
      return selectedStickerLayer!.visuals.flipX;
    }
    if (selectedDrawLayer != null) {
      return selectedDrawLayer!.visuals.flipX;
    }
    if (selectedShapeLayer != null) {
      return selectedShapeLayer!.visuals.flipX;
    }
    return false;
  }

  bool get selectedLayerFlipY {
    if (_isMainSurfaceSelected) {
      return _mainSurfacePhoto?.visuals.flipY ?? false;
    }
    if (selectedExtraPhotoLayer != null) {
      return selectedExtraPhotoLayer!.visuals.flipY;
    }
    if (selectedTextLayer != null) {
      return selectedTextLayer!.isFlippedVertical;
    }
    if (selectedElementLayer != null) {
      return selectedElementLayer!.visuals.flipY;
    }
    if (selectedStickerLayer != null) {
      return selectedStickerLayer!.visuals.flipY;
    }
    if (selectedDrawLayer != null) {
      return selectedDrawLayer!.visuals.flipY;
    }
    if (selectedShapeLayer != null) {
      return selectedShapeLayer!.visuals.flipY;
    }
    return false;
  }

  double get selectedLayerRotation {
    if (_isMainSurfaceSelected) {
      return _mainSurfaceRotation;
    }
    if (selectedExtraPhotoLayer != null) {
      return selectedExtraPhotoLayer!.rotation;
    }
    if (selectedTextLayer != null) {
      return selectedTextLayer!.rotation;
    }
    if (selectedElementLayer != null) {
      return selectedElementLayer!.rotation;
    }
    if (selectedStickerLayer != null) {
      return selectedStickerLayer!.rotation;
    }
    if (selectedDrawLayer != null) {
      return 0;
    }
    if (selectedShapeLayer != null) {
      return selectedShapeLayer!.rotation;
    }
    return 0;
  }

  List<String> get elementCategories => _elementCategories;

  List<EditorElementAsset> get elementAssets => _elementAssetCatalog;
  List<String> get stickerCategories => _stickerCategories;
  List<EditorStickerAsset> get stickerAssets => _stickerAssetCatalog;

  Size get mainSurfaceFitSize {
    if (_stageSize == Size.zero) {
      return Size.zero;
    }
    final source = _mainSurfaceImageSize;
    if (source == null || source.width <= 0 || source.height <= 0) {
      return _stageSize;
    }

    final stageRatio = _stageSize.width / _stageSize.height;
    final imageRatio = _mainSurfaceCropRatio ?? (source.width / source.height);

    if (imageRatio > stageRatio) {
      final width = _stageSize.width;
      return Size(width, width / imageRatio);
    }

    final height = _stageSize.height;
    return Size(height * imageRatio, height);
  }

  List<EditorLayerEntry> get layerEntriesForPanel {
    final entries = <EditorLayerEntry>[
      EditorLayerEntry(
        entryId: 'background',
        layerId: 'background',
        type: EditorLayerType.background,
        name: 'Background',
        isVisible: true,
        isLocked: true,
        isSelected:
            !_isMainSurfaceSelected &&
            _selectedExtraPhotoLayerId == null &&
            _selectedTextLayerId == null &&
            _selectedElementLayerId == null &&
            _selectedStickerLayerId == null &&
            _selectedDrawLayerId == null &&
            _selectedShapeLayerId == null,
        isMovable: false,
        zIndex: -1000,
      ),
      if (_mainSurfacePhoto != null)
        EditorLayerEntry(
          entryId: 'surface_photo',
          layerId: 'surface_photo',
          type: EditorLayerType.surfacePhoto,
          name: 'Photo 1',
          isVisible: true,
          isLocked: _mainSurfacePhoto!.isLocked,
          isSelected: _isMainSurfaceSelected,
          isMovable: false,
          zIndex: -900,
          thumbnailUrl: _mainSurfacePhoto!.imageUrl,
        ),
    ];

    final overlays = <EditorLayerEntry>[
      ..._extraPhotoLayers.map(
        (layer) => EditorLayerEntry(
          entryId: 'photo:${layer.id}',
          layerId: layer.id,
          type: EditorLayerType.photo,
          name: layer.name,
          isVisible: layer.isVisible,
          isLocked: layer.isLocked,
          isSelected: _selectedExtraPhotoLayerId == layer.id,
          isMovable: true,
          zIndex: layer.zIndex,
          thumbnailUrl: layer.imageUrl,
        ),
      ),
      ..._textLayers.map(
        (layer) => EditorLayerEntry(
          entryId: 'text:${layer.id}',
          layerId: layer.id,
          type: EditorLayerType.text,
          name: layer.name,
          isVisible: layer.isVisible,
          isLocked: layer.isLocked,
          isSelected: _selectedTextLayerId == layer.id,
          isMovable: true,
          zIndex: layer.zIndex,
        ),
      ),
      ..._elementLayers.map(
        (layer) => EditorLayerEntry(
          entryId: 'element:${layer.id}',
          layerId: layer.id,
          type: EditorLayerType.element,
          name: layer.name,
          isVisible: layer.isVisible,
          isLocked: layer.isLocked,
          isSelected: _selectedElementLayerId == layer.id,
          isMovable: true,
          zIndex: layer.zIndex,
          thumbnailUrl: layer.assetUrl,
        ),
      ),
      ..._stickerLayers.map(
        (layer) => EditorLayerEntry(
          entryId: 'sticker:${layer.id}',
          layerId: layer.id,
          type: EditorLayerType.sticker,
          name: layer.name,
          isVisible: layer.isVisible,
          isLocked: layer.isLocked,
          isSelected: _selectedStickerLayerId == layer.id,
          isMovable: true,
          zIndex: layer.zIndex,
          thumbnailUrl: layer.stickerUrl,
        ),
      ),
      ..._drawLayers.map(
        (layer) => EditorLayerEntry(
          entryId: 'draw:${layer.id}',
          layerId: layer.id,
          type: EditorLayerType.draw,
          name: layer.name,
          isVisible: layer.isVisible,
          isLocked: layer.isLocked,
          isSelected: _selectedDrawLayerId == layer.id,
          isMovable: true,
          zIndex: layer.zIndex,
        ),
      ),
      ..._shapeLayers.map(
        (layer) => EditorLayerEntry(
          entryId: 'shape:${layer.id}',
          layerId: layer.id,
          type: EditorLayerType.shape,
          name: layer.name,
          isVisible: layer.isVisible,
          isLocked: layer.isLocked,
          isSelected: _selectedShapeLayerId == layer.id,
          isMovable: true,
          zIndex: layer.zIndex,
        ),
      ),
    ]..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    entries.addAll(overlays);
    return List<EditorLayerEntry>.unmodifiable(entries);
  }

  void setStageSize(Size size) {
    if (size == _stageSize || size.width <= 0 || size.height <= 0) {
      return;
    }
    _stageSize = size;
    _mainSurfaceOffset = _clampOffset(_mainSurfaceOffset, _mainSurfaceScale);
    notifyListeners();
  }

  void openTool(EditorToolDefinition tool) {
    if (tool.id == EditorToolId.layers) {
      _activeTool = null;
      requestLayersPanel();
      return;
    }
    if (tool.id == EditorToolId.crop) {
      _activeTool = tool;
      _beginCropSession();
      notifyListeners();
      return;
    }
    if (tool.id == EditorToolId.adjust) {
      _activeTool = tool;
      _beginAdjustSession();
      notifyListeners();
      return;
    }
    if (tool.id == EditorToolId.filters) {
      _activeTool = tool;
      _beginFilterSession();
      notifyListeners();
      return;
    }
    if (tool.id == EditorToolId.borderFrame) {
      _activeTool = tool;
      _beginBorderFrameSession();
      notifyListeners();
      return;
    }
    if (tool.id == EditorToolId.removeBg) {
      _activeTool = tool;
      _beginRemoveBgSession();
      notifyListeners();
      return;
    }
    if (tool.id == EditorToolId.draw) {
      _activeTool = tool;
      _beginDrawSession();
      notifyListeners();
      return;
    }
    _activeTool = tool;
    notifyListeners();
  }

  void closeTool() {
    if (_selectedLayerQuickActionTool != null) {
      _selectedLayerQuickActionTool = null;
      notifyListeners();
      return;
    }
    if (_activeTool?.id == EditorToolId.crop && _cropSessionActive) {
      cancelCropSession();
      return;
    }
    if (_activeTool?.id == EditorToolId.adjust && _adjustSessionActive) {
      cancelAdjustSession();
      return;
    }
    if (_activeTool?.id == EditorToolId.filters && _filterSessionActive) {
      cancelFilterSession();
      return;
    }
    if (_activeTool?.id == EditorToolId.borderFrame &&
        _borderFrameSessionActive) {
      cancelBorderFrameSession();
      return;
    }
    if (_activeTool?.id == EditorToolId.removeBg && _removeBgSessionActive) {
      cancelRemoveBgSession();
      return;
    }
    if (_activeTool?.id == EditorToolId.draw && _drawSessionActive) {
      cancelDrawSession();
      return;
    }
    _activeTool = null;
    notifyListeners();
  }

  void requestLayersPanel() {
    _pendingLayersPanelRequest = true;
    notifyListeners();
  }

  bool consumePendingLayersPanelRequest() {
    final request = _pendingLayersPanelRequest;
    _pendingLayersPanelRequest = false;
    return request;
  }

  void requestPhotoPicker() {
    _pendingPhotoPickerRequest = true;
    notifyListeners();
  }

  bool consumePendingPhotoPickerRequest() {
    final request = _pendingPhotoPickerRequest;
    _pendingPhotoPickerRequest = false;
    return request;
  }

  void requestBackgroundImagePicker() {
    _pendingBackgroundImagePickerRequest = true;
    notifyListeners();
  }

  bool consumePendingBackgroundImagePickerRequest() {
    final request = _pendingBackgroundImagePickerRequest;
    _pendingBackgroundImagePickerRequest = false;
    return request;
  }

  void clearOverlaySelection() {
    final hadSelection =
        _selectedTextLayerId != null ||
        _selectedExtraPhotoLayerId != null ||
        _selectedElementLayerId != null ||
        _selectedStickerLayerId != null ||
        _selectedDrawLayerId != null ||
        _selectedShapeLayerId != null ||
        _isMainSurfaceSelected;
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
    _selectedLayerQuickActionTool = null;
    if (hadSelection) {
      notifyListeners();
    }
  }

  void _normalizeSelectionState() {
    if (_selectedExtraPhotoLayerId != null) {
      final layer = _findExtraPhotoLayer(_selectedExtraPhotoLayerId!);
      if (layer == null || !layer.isVisible) {
        _selectedExtraPhotoLayerId = null;
      }
    }
    if (_selectedTextLayerId != null) {
      final layer = _findTextLayer(_selectedTextLayerId!);
      if (layer == null || !layer.isVisible) {
        _selectedTextLayerId = null;
      }
    }
    if (_selectedElementLayerId != null) {
      final layer = _findElementLayer(_selectedElementLayerId!);
      if (layer == null || !layer.isVisible) {
        _selectedElementLayerId = null;
      }
    }
    if (_selectedStickerLayerId != null) {
      final layer = _findStickerLayer(_selectedStickerLayerId!);
      if (layer == null || !layer.isVisible) {
        _selectedStickerLayerId = null;
      }
    }
    if (_selectedDrawLayerId != null) {
      final layer = _findDrawLayer(_selectedDrawLayerId!);
      if (layer == null || !layer.isVisible) {
        _selectedDrawLayerId = null;
      }
    }
    if (_selectedShapeLayerId != null) {
      final layer = _findShapeLayer(_selectedShapeLayerId!);
      if (layer == null || !layer.isVisible) {
        _selectedShapeLayerId = null;
      }
    }
    if (_isMainSurfaceSelected && _mainSurfacePhoto == null) {
      _isMainSurfaceSelected = false;
    }

    final selectionCount =
        (_selectedExtraPhotoLayerId != null ? 1 : 0) +
        (_selectedTextLayerId != null ? 1 : 0) +
        (_selectedElementLayerId != null ? 1 : 0) +
        (_selectedStickerLayerId != null ? 1 : 0) +
        (_selectedDrawLayerId != null ? 1 : 0) +
        (_selectedShapeLayerId != null ? 1 : 0) +
        (_isMainSurfaceSelected ? 1 : 0);

    if (selectionCount <= 1) {
      if (selectionCount == 0) {
        _selectedLayerQuickActionTool = null;
      }
      return;
    }

    if (_selectedShapeLayerId != null) {
      _selectedDrawLayerId = null;
      _selectedStickerLayerId = null;
      _selectedElementLayerId = null;
      _selectedTextLayerId = null;
      _selectedExtraPhotoLayerId = null;
      _isMainSurfaceSelected = false;
      return;
    }
    if (_selectedDrawLayerId != null) {
      _selectedStickerLayerId = null;
      _selectedElementLayerId = null;
      _selectedTextLayerId = null;
      _selectedExtraPhotoLayerId = null;
      _isMainSurfaceSelected = false;
      return;
    }
    if (_selectedStickerLayerId != null) {
      _selectedElementLayerId = null;
      _selectedTextLayerId = null;
      _selectedExtraPhotoLayerId = null;
      _isMainSurfaceSelected = false;
      return;
    }
    if (_selectedElementLayerId != null) {
      _selectedTextLayerId = null;
      _selectedExtraPhotoLayerId = null;
      _isMainSurfaceSelected = false;
      return;
    }
    if (_selectedTextLayerId != null) {
      _selectedExtraPhotoLayerId = null;
      _isMainSurfaceSelected = false;
      return;
    }
    if (_selectedExtraPhotoLayerId != null) {
      _isMainSurfaceSelected = false;
    }
  }

  void unselectTextLayer() {
    clearOverlaySelection();
  }

  void selectMainSurfaceLayer() {
    if (_mainSurfacePhoto == null) {
      return;
    }
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = true;
    _activeTool = _toolById(EditorToolId.photo);
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void selectExtraPhotoLayer(String layerId) {
    final layer = _findExtraPhotoLayer(layerId);
    if (layer == null || !layer.isVisible) {
      return;
    }
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = layerId;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.photo);
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void selectTextLayer(String layerId) {
    final layer = _findTextLayer(layerId);
    if (layer == null || !layer.isVisible) {
      return;
    }
    _selectedTextLayerId = layerId;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.text);
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void selectElementLayer(String layerId) {
    final layer = _findElementLayer(layerId);
    if (layer == null || !layer.isVisible) {
      return;
    }
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = layerId;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.elements);
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void selectStickerLayer(String layerId) {
    final layer = _findStickerLayer(layerId);
    if (layer == null || !layer.isVisible) {
      return;
    }
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = layerId;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.stickers);
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void selectDrawLayer(String layerId) {
    final layer = _findDrawLayer(layerId);
    if (layer == null || !layer.isVisible) {
      return;
    }
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = layerId;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.draw);
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void selectShapeLayer(String layerId) {
    final layer = _findShapeLayer(layerId);
    if (layer == null || !layer.isVisible) {
      return;
    }
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = layerId;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.shapes);
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void openSelectedLayerQuickAction(EditorToolId toolId) {
    if (!hasSelectedEditableLayer) {
      return;
    }
    _selectedLayerQuickActionTool = toolId;
    notifyListeners();
  }

  void closeSelectedLayerQuickAction() {
    if (_selectedLayerQuickActionTool == null) {
      return;
    }
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void setDrawMode(DrawToolMode mode) {
    if (_drawMode == mode) {
      return;
    }
    _drawMode = mode;
    if (mode == DrawToolMode.pen) {
      _drawBrushStyle = DrawBrushStyle.smoothPen;
    } else if (mode == DrawToolMode.brush &&
        _drawBrushStyle == DrawBrushStyle.neonHighlighter) {
      _drawBrushStyle = DrawBrushStyle.softBrush;
    } else if (mode == DrawToolMode.highlighter) {
      _drawBrushStyle = DrawBrushStyle.neonHighlighter;
    }
    notifyListeners();
  }

  void setDrawBrushStyle(DrawBrushStyle style) {
    _drawBrushStyle = style;
    notifyListeners();
  }

  void setDrawColor(Color color) {
    _drawColor = color;
    notifyListeners();
  }

  void setDrawSize(double value) {
    _drawSize = value.clamp(0.004, 0.06);
    notifyListeners();
  }

  void setDrawOpacity(double value) {
    _drawOpacity = value.clamp(0.08, 1.0);
    notifyListeners();
  }

  void beginDrawStroke(Offset point) {
    if (!_drawSessionActive ||
        (_drawEditingLayerId != null &&
            (_findDrawLayer(_drawEditingLayerId!)?.isLocked ?? false))) {
      return;
    }
    _drawRedoStack.clear();
    _drawStrokeSeq += 1;
    _drawDraftStrokes.add(
      DrawStroke(
        id: 'stroke_$_drawStrokeSeq',
        mode: _drawMode,
        style: _drawBrushStyle,
        points: <Offset>[_clampNormalizedPoint(point)],
        color: _drawColor,
        size: _drawSize,
        opacity: _drawOpacity,
      ),
    );
    _activeDraftStrokeIndex = _drawDraftStrokes.length - 1;
    notifyListeners();
  }

  void appendDrawStrokePoint(Offset point) {
    if (!_drawSessionActive || _activeDraftStrokeIndex == null) {
      return;
    }
    final index = _activeDraftStrokeIndex!;
    if (index < 0 || index >= _drawDraftStrokes.length) {
      return;
    }
    final current = _drawDraftStrokes[index];
    final points = List<Offset>.from(current.points)
      ..add(_clampNormalizedPoint(point));
    _drawDraftStrokes[index] = current.copyWith(points: points);
    notifyListeners();
  }

  void endDrawStroke() {
    _activeDraftStrokeIndex = null;
    notifyListeners();
  }

  void undoDrawStroke() {
    if (_drawDraftStrokes.isEmpty) {
      return;
    }
    _drawRedoStack.add(_drawDraftStrokes.removeLast());
    notifyListeners();
  }

  void redoDrawStroke() {
    if (_drawRedoStack.isEmpty) {
      return;
    }
    _drawDraftStrokes.add(_drawRedoStack.removeLast());
    notifyListeners();
  }

  void clearDrawSession() {
    if (_drawDraftStrokes.isEmpty && _drawRedoStack.isEmpty) {
      return;
    }
    _drawDraftStrokes = <DrawStroke>[];
    _drawRedoStack.clear();
    _activeDraftStrokeIndex = null;
    notifyListeners();
  }

  void applyDrawSession() {
    if (!_drawSessionActive) {
      return;
    }
    final targetId = _drawEditingLayerId;
    if (targetId != null) {
      _updateDrawLayer(
        targetId,
        (current) =>
            current.copyWith(strokes: List<DrawStroke>.from(_drawDraftStrokes)),
      );
      _selectedDrawLayerId = targetId;
    } else if (_drawDraftStrokes.isNotEmpty) {
      _drawSeq += 1;
      final id = 'draw_$_drawSeq';
      _drawLayers.add(
        StageDrawLayer(
          id: id,
          name: 'Draw $_drawSeq',
          strokes: List<DrawStroke>.from(_drawDraftStrokes),
          zIndex: _nextOverlayZIndex,
        ),
      );
      _selectedDrawLayerId = id;
    }
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _isMainSurfaceSelected = false;
    _resetDrawSessionState();
    markEdit();
  }

  void cancelDrawSession() {
    _resetDrawSessionState();
    _activeTool = null;
    notifyListeners();
  }

  void setStageExportMode({
    required bool enabled,
    bool transparentBackground = false,
  }) {
    if (_isStageExportMode == enabled &&
        _exportTransparentBackground == transparentBackground) {
      return;
    }
    _isStageExportMode = enabled;
    _exportTransparentBackground = enabled && transparentBackground;
    notifyListeners();
  }

  void updateSelectedLayerOpacity(double value) {
    if (!hasSelectedEditableLayer || isSelectedLayerLocked) {
      return;
    }
    final normalized = value.clamp(0.0, 1.0);
    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _mainSurfacePhoto = _mainSurfacePhoto!.copyWith(
        visuals: _mainSurfacePhoto!.visuals.copyWith(opacity: normalized),
      );
    } else if (selectedExtraPhotoLayer != null) {
      final id = selectedExtraPhotoLayer!.id;
      _updateExtraPhotoLayer(
        id,
        (current) => current.copyWith(
          visuals: current.visuals.copyWith(opacity: normalized),
        ),
      );
    } else if (selectedTextLayer != null) {
      updateSelectedTextStyle(
        selectedTextLayer!.style.copyWith(opacity: normalized),
      );
      return;
    } else if (selectedElementLayer != null) {
      final id = selectedElementLayer!.id;
      _updateElementLayer(
        id,
        (current) => current.copyWith(
          visuals: current.visuals.copyWith(opacity: normalized),
        ),
      );
    } else if (selectedStickerLayer != null) {
      final id = selectedStickerLayer!.id;
      _updateStickerLayer(
        id,
        (current) => current.copyWith(
          visuals: current.visuals.copyWith(opacity: normalized),
        ),
      );
    } else if (selectedDrawLayer != null) {
      final id = selectedDrawLayer!.id;
      _updateDrawLayer(
        id,
        (current) => current.copyWith(
          visuals: current.visuals.copyWith(opacity: normalized),
        ),
      );
    } else if (selectedShapeLayer != null) {
      final id = selectedShapeLayer!.id;
      _updateShapeLayer(
        id,
        (current) => current.copyWith(
          visuals: current.visuals.copyWith(opacity: normalized),
        ),
      );
    }
    markEdit();
  }

  void updateSelectedLayerShadow({
    Color? color,
    double? blur,
    double? distance,
    double? opacity,
  }) {
    if (!hasSelectedEditableLayer || isSelectedLayerLocked) {
      return;
    }
    final current = selectedLayerShadow;
    final next = current.copyWith(
      color: color ?? current.color,
      blur: blur?.clamp(0.0, 1.0),
      distance: distance?.clamp(0.0, 1.0),
      opacity: opacity?.clamp(0.0, 1.0),
    );
    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _mainSurfacePhoto = _mainSurfacePhoto!.copyWith(
        visuals: _mainSurfacePhoto!.visuals.copyWith(shadow: next),
      );
    } else if (selectedExtraPhotoLayer != null) {
      final id = selectedExtraPhotoLayer!.id;
      _updateExtraPhotoLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(shadow: next)),
      );
    } else if (selectedTextLayer != null) {
      updateSelectedTextStyle(
        selectedTextLayer!.style.copyWith(
          shadow: Shadow(
            color: next.color.withValues(alpha: next.opacity),
            blurRadius: next.blur * 24,
            offset: Offset(0, next.distance * 18),
          ),
        ),
      );
      return;
    } else if (selectedElementLayer != null) {
      final id = selectedElementLayer!.id;
      _updateElementLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(shadow: next)),
      );
    } else if (selectedStickerLayer != null) {
      final id = selectedStickerLayer!.id;
      _updateStickerLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(shadow: next)),
      );
    } else if (selectedDrawLayer != null) {
      final id = selectedDrawLayer!.id;
      _updateDrawLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(shadow: next)),
      );
    } else if (selectedShapeLayer != null) {
      final id = selectedShapeLayer!.id;
      _updateShapeLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(shadow: next)),
      );
    }
    markEdit();
  }

  void updateSelectedLayerBlendMode(LayerBlendModeOption mode) {
    if (!hasSelectedEditableLayer || isSelectedLayerLocked) {
      return;
    }
    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _mainSurfacePhoto = _mainSurfacePhoto!.copyWith(
        visuals: _mainSurfacePhoto!.visuals.copyWith(blendMode: mode),
      );
    } else if (selectedExtraPhotoLayer != null) {
      final id = selectedExtraPhotoLayer!.id;
      _updateExtraPhotoLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(blendMode: mode)),
      );
    } else if (selectedTextLayer != null) {
      _updateTextLayer(
        selectedTextLayer!.id,
        (layer) => layer.copyWith(blendMode: mode),
      );
    } else if (selectedElementLayer != null) {
      final id = selectedElementLayer!.id;
      _updateElementLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(blendMode: mode)),
      );
    } else if (selectedStickerLayer != null) {
      final id = selectedStickerLayer!.id;
      _updateStickerLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(blendMode: mode)),
      );
    } else if (selectedDrawLayer != null) {
      final id = selectedDrawLayer!.id;
      _updateDrawLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(blendMode: mode)),
      );
    } else if (selectedShapeLayer != null) {
      final id = selectedShapeLayer!.id;
      _updateShapeLayer(
        id,
        (layer) =>
            layer.copyWith(visuals: layer.visuals.copyWith(blendMode: mode)),
      );
    }
    markEdit();
  }

  void flipSelectedLayerHorizontal() {
    if (!hasSelectedEditableLayer || isSelectedLayerLocked) {
      return;
    }
    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _mainSurfacePhoto = _mainSurfacePhoto!.copyWith(
        visuals: _mainSurfacePhoto!.visuals.copyWith(
          flipX: !_mainSurfacePhoto!.visuals.flipX,
        ),
      );
    } else if (selectedExtraPhotoLayer != null) {
      final id = selectedExtraPhotoLayer!.id;
      _updateExtraPhotoLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipX: !layer.visuals.flipX),
        ),
      );
    } else if (selectedTextLayer != null) {
      _updateTextLayer(
        selectedTextLayer!.id,
        (layer) => layer.copyWith(isFlipped: !layer.isFlipped),
      );
    } else if (selectedElementLayer != null) {
      final id = selectedElementLayer!.id;
      _updateElementLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipX: !layer.visuals.flipX),
        ),
      );
    } else if (selectedStickerLayer != null) {
      final id = selectedStickerLayer!.id;
      _updateStickerLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipX: !layer.visuals.flipX),
        ),
      );
    } else if (selectedDrawLayer != null) {
      final id = selectedDrawLayer!.id;
      _updateDrawLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipX: !layer.visuals.flipX),
        ),
      );
    } else if (selectedShapeLayer != null) {
      final id = selectedShapeLayer!.id;
      _updateShapeLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipX: !layer.visuals.flipX),
        ),
      );
    }
    markEdit();
  }

  void flipSelectedLayerVertical() {
    if (!hasSelectedEditableLayer || isSelectedLayerLocked) {
      return;
    }
    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _mainSurfacePhoto = _mainSurfacePhoto!.copyWith(
        visuals: _mainSurfacePhoto!.visuals.copyWith(
          flipY: !_mainSurfacePhoto!.visuals.flipY,
        ),
      );
    } else if (selectedExtraPhotoLayer != null) {
      final id = selectedExtraPhotoLayer!.id;
      _updateExtraPhotoLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipY: !layer.visuals.flipY),
        ),
      );
    } else if (selectedTextLayer != null) {
      _updateTextLayer(
        selectedTextLayer!.id,
        (layer) => layer.copyWith(isFlippedVertical: !layer.isFlippedVertical),
      );
    } else if (selectedElementLayer != null) {
      final id = selectedElementLayer!.id;
      _updateElementLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipY: !layer.visuals.flipY),
        ),
      );
    } else if (selectedStickerLayer != null) {
      final id = selectedStickerLayer!.id;
      _updateStickerLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipY: !layer.visuals.flipY),
        ),
      );
    } else if (selectedDrawLayer != null) {
      final id = selectedDrawLayer!.id;
      _updateDrawLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipY: !layer.visuals.flipY),
        ),
      );
    } else if (selectedShapeLayer != null) {
      final id = selectedShapeLayer!.id;
      _updateShapeLayer(
        id,
        (layer) => layer.copyWith(
          visuals: layer.visuals.copyWith(flipY: !layer.visuals.flipY),
        ),
      );
    }
    markEdit();
  }

  void rotateSelectedLayerByQuarterTurn() {
    if (!hasSelectedEditableLayer || isSelectedLayerLocked) {
      return;
    }
    updateSelectedLayerRotation(selectedLayerRotation + (math.pi / 2));
  }

  void updateSelectedLayerRotation(double angle) {
    if (!hasSelectedEditableLayer || isSelectedLayerLocked) {
      return;
    }
    final normalized = _hardSnapRotation(angle);
    if (_isMainSurfaceSelected) {
      _mainSurfaceRotation = normalized;
      _mainSurfaceOffset = _clampOffset(_mainSurfaceOffset, _mainSurfaceScale);
    } else if (selectedExtraPhotoLayer != null) {
      _updateExtraPhotoLayer(
        selectedExtraPhotoLayer!.id,
        (layer) => layer.copyWith(rotation: normalized),
      );
    } else if (selectedTextLayer != null) {
      _updateTextLayer(
        selectedTextLayer!.id,
        (layer) => layer.copyWith(rotation: normalized),
      );
    } else if (selectedElementLayer != null) {
      _updateElementLayer(
        selectedElementLayer!.id,
        (layer) => layer.copyWith(rotation: normalized),
      );
    } else if (selectedStickerLayer != null) {
      _updateStickerLayer(
        selectedStickerLayer!.id,
        (layer) => layer.copyWith(rotation: normalized),
      );
    } else if (selectedDrawLayer != null) {
      // Draw layer has no free rotation in this foundation build.
      return;
    } else if (selectedShapeLayer != null) {
      _updateShapeLayer(
        selectedShapeLayer!.id,
        (layer) => layer.copyWith(rotation: normalized),
      );
    }
    markEdit();
  }

  void duplicateSelectedLayerInPlace() {
    if (!hasSelectedEditableLayer) {
      return;
    }
    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _photoSeq += 1;
      final duplicate = StagePhotoLayer(
        id: 'photo_$_photoSeq',
        imageUrl: _mainSurfacePhoto!.imageUrl,
        name: 'Photo $_photoSeq',
        size: mainSurfaceFitSize == Size.zero
            ? const Size(280, 360)
            : mainSurfaceFitSize,
        offset: _mainSurfaceOffset,
        scale: _mainSurfaceScale,
        rotation: _mainSurfaceRotation,
        adjustments: _mainSurfacePhoto!.adjustments,
        filter: _mainSurfacePhoto!.filter,
        removeBgState: _mainSurfacePhoto!.removeBgState,
        decoration: _mainSurfacePhoto!.decoration,
        visuals: _mainSurfacePhoto!.visuals,
        zIndex: _nextOverlayZIndex,
      );
      _extraPhotoLayers.add(duplicate);
      _selectedExtraPhotoLayerId = duplicate.id;
      _selectedTextLayerId = null;
      _selectedElementLayerId = null;
      _selectedStickerLayerId = null;
      _isMainSurfaceSelected = false;
      markEdit();
      return;
    }
    if (selectedExtraPhotoLayer != null) {
      final layer = selectedExtraPhotoLayer!;
      _photoSeq += 1;
      final duplicate = layer.copyWith(
        id: 'photo_$_photoSeq',
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
      );
      _extraPhotoLayers.add(duplicate);
      _selectedExtraPhotoLayerId = duplicate.id;
      _selectedTextLayerId = null;
      _selectedElementLayerId = null;
      _selectedStickerLayerId = null;
      _selectedDrawLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      _selectedLayerQuickActionTool = null;
      markEdit();
      return;
    }
    if (selectedTextLayer != null) {
      final layer = selectedTextLayer!;
      _textSeq += 1;
      final duplicate = layer.copyWith(
        id: 'text_$_textSeq',
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
      );
      _textLayers.add(duplicate);
      _selectedTextLayerId = duplicate.id;
      _selectedExtraPhotoLayerId = null;
      _selectedElementLayerId = null;
      _selectedStickerLayerId = null;
      _selectedDrawLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      _selectedLayerQuickActionTool = null;
      markEdit();
      return;
    }
    if (selectedElementLayer != null) {
      final layer = selectedElementLayer!;
      _elementSeq += 1;
      final duplicate = layer.copyWith(
        id: 'element_$_elementSeq',
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
      );
      _elementLayers.add(duplicate);
      _selectedElementLayerId = duplicate.id;
      _selectedExtraPhotoLayerId = null;
      _selectedTextLayerId = null;
      _selectedStickerLayerId = null;
      _selectedDrawLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      _selectedLayerQuickActionTool = null;
      markEdit();
      return;
    }
    if (selectedStickerLayer != null) {
      final layer = selectedStickerLayer!;
      _stickerSeq += 1;
      final duplicate = layer.copyWith(
        id: 'sticker_$_stickerSeq',
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
      );
      _stickerLayers.add(duplicate);
      _selectedStickerLayerId = duplicate.id;
      _selectedExtraPhotoLayerId = null;
      _selectedTextLayerId = null;
      _selectedElementLayerId = null;
      _selectedDrawLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      _selectedLayerQuickActionTool = null;
      markEdit();
      return;
    }
    if (selectedDrawLayer != null) {
      final layer = selectedDrawLayer!;
      _drawSeq += 1;
      final duplicate = layer.copyWith(
        id: 'draw_$_drawSeq',
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
      );
      _drawLayers.add(duplicate);
      _selectedDrawLayerId = duplicate.id;
      _selectedExtraPhotoLayerId = null;
      _selectedTextLayerId = null;
      _selectedElementLayerId = null;
      _selectedStickerLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      _selectedLayerQuickActionTool = null;
      markEdit();
      return;
    }
    if (selectedShapeLayer != null) {
      final layer = selectedShapeLayer!;
      _shapeSeq += 1;
      final duplicate = layer.copyWith(
        id: 'shape_$_shapeSeq',
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
      );
      _shapeLayers.add(duplicate);
      _selectedShapeLayerId = duplicate.id;
      _selectedExtraPhotoLayerId = null;
      _selectedTextLayerId = null;
      _selectedElementLayerId = null;
      _selectedStickerLayerId = null;
      _selectedDrawLayerId = null;
      _isMainSurfaceSelected = false;
      _selectedLayerQuickActionTool = null;
      markEdit();
    }
  }

  void toggleSelectedLayerLock() {
    if (!hasSelectedEditableLayer) {
      return;
    }
    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _mainSurfacePhoto = _mainSurfacePhoto!.copyWith(
        isLocked: !_mainSurfacePhoto!.isLocked,
      );
      markEdit();
      return;
    }
    if (selectedExtraPhotoLayer != null) {
      toggleLockForLayerEntry('photo:${selectedExtraPhotoLayer!.id}');
      return;
    }
    if (selectedTextLayer != null) {
      toggleLockForLayerEntry('text:${selectedTextLayer!.id}');
      return;
    }
    if (selectedElementLayer != null) {
      toggleLockForLayerEntry('element:${selectedElementLayer!.id}');
      return;
    }
    if (selectedStickerLayer != null) {
      toggleLockForLayerEntry('sticker:${selectedStickerLayer!.id}');
      return;
    }
    if (selectedDrawLayer != null) {
      toggleLockForLayerEntry('draw:${selectedDrawLayer!.id}');
      return;
    }
    if (selectedShapeLayer != null) {
      toggleLockForLayerEntry('shape:${selectedShapeLayer!.id}');
    }
  }

  void exitTextToolToMainTools() {
    _activeTool = null;
    _selectedTextLayerId = null;
    _pendingFullScreenTextEditorLayerId = null;
    notifyListeners();
  }

  void cancelCropSession() {
    if (!_cropSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }

    if (_cropTargetType == _CropTargetType.extraPhoto &&
        _cropTargetLayerId != null) {
      final layerId = _cropTargetLayerId!;
      final target = _findExtraPhotoLayer(layerId);
      if (target != null) {
        _updateExtraPhotoLayer(
          layerId,
          (current) => current.copyWith(
            cropRatio: _ratioFromKey(_cropInitialRatioKey),
            clearCropRatio: _ratioFromKey(_cropInitialRatioKey) == null,
            cropTurns: _cropInitialTurns,
            size: _cropInitialSize ?? current.size,
            rotation: _cropInitialRotation,
          ),
        );
      }
    } else if (_cropTargetType == _CropTargetType.mainSurface) {
      _mainSurfaceCropRatio = _ratioFromKey(_cropInitialRatioKey);
      _mainSurfaceCropTurns = _cropInitialTurns;
    }

    _resetCropSessionState();
    _activeTool = null;
    notifyListeners();
  }

  void applyCropSession() {
    if (!_cropSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }
    _resetCropSessionState();
    _activeTool = null;
    markEdit();
  }

  void resetCropSession() {
    if (!_cropSessionActive) {
      return;
    }
    _cropDraftRatioKey = _cropInitialRatioKey;
    _cropDraftTurns = _cropInitialTurns;
    _applyCropDraftPreview();
    notifyListeners();
  }

  void updateCropRatio(String ratioKey) {
    if (!_cropSessionActive || !_cropRatioOptions.containsKey(ratioKey)) {
      return;
    }
    _cropDraftRatioKey = ratioKey;
    _applyCropDraftPreview();
    notifyListeners();
  }

  void rotateCropQuarter() {
    if (!_cropSessionActive) {
      return;
    }
    _cropDraftTurns = (_cropDraftTurns + 1) % 4;
    _applyCropDraftPreview();
    notifyListeners();
  }

  void cancelAdjustSession() {
    if (!_adjustSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }

    if (_adjustTargetType == _AdjustTargetType.mainSurface) {
      final surface = _mainSurfacePhoto;
      if (surface != null) {
        _mainSurfacePhoto = surface.copyWith(adjustments: _adjustInitial);
      }
    } else if (_adjustTargetType == _AdjustTargetType.extraPhoto &&
        _adjustTargetLayerId != null) {
      final id = _adjustTargetLayerId!;
      _updateExtraPhotoLayer(
        id,
        (current) => current.copyWith(adjustments: _adjustInitial),
      );
    }

    _resetAdjustSessionState();
    _activeTool = null;
    notifyListeners();
  }

  void applyAdjustSession() {
    if (!_adjustSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }
    _resetAdjustSessionState();
    _activeTool = null;
    markEdit();
  }

  void resetAdjustSession() {
    if (!_adjustSessionActive) {
      return;
    }
    _adjustDraft = PhotoAdjustments.neutral;
    _applyAdjustDraftPreview();
    notifyListeners();
  }

  void _updateAdjustValue({
    required _AdjustControl control,
    required double value,
  }) {
    if (!_adjustSessionActive) {
      return;
    }
    final normalized = value.clamp(-1.0, 1.0);
    switch (control) {
      case _AdjustControl.brightness:
        _adjustDraft = _adjustDraft.copyWith(brightness: normalized);
        break;
      case _AdjustControl.contrast:
        _adjustDraft = _adjustDraft.copyWith(contrast: normalized);
        break;
      case _AdjustControl.saturation:
        _adjustDraft = _adjustDraft.copyWith(saturation: normalized);
        break;
      case _AdjustControl.warmth:
        _adjustDraft = _adjustDraft.copyWith(warmth: normalized);
        break;
      case _AdjustControl.tint:
        _adjustDraft = _adjustDraft.copyWith(tint: normalized);
        break;
      case _AdjustControl.highlights:
        _adjustDraft = _adjustDraft.copyWith(highlights: normalized);
        break;
      case _AdjustControl.shadows:
        _adjustDraft = _adjustDraft.copyWith(shadows: normalized);
        break;
      case _AdjustControl.sharpness:
        _adjustDraft = _adjustDraft.copyWith(sharpness: normalized);
        break;
    }
    _applyAdjustDraftPreview();
    notifyListeners();
  }

  void updateAdjustBrightness(double value) {
    _updateAdjustValue(control: _AdjustControl.brightness, value: value);
  }

  void updateAdjustContrast(double value) {
    _updateAdjustValue(control: _AdjustControl.contrast, value: value);
  }

  void updateAdjustSaturation(double value) {
    _updateAdjustValue(control: _AdjustControl.saturation, value: value);
  }

  void updateAdjustWarmth(double value) {
    _updateAdjustValue(control: _AdjustControl.warmth, value: value);
  }

  void updateAdjustTint(double value) {
    _updateAdjustValue(control: _AdjustControl.tint, value: value);
  }

  void updateAdjustHighlights(double value) {
    _updateAdjustValue(control: _AdjustControl.highlights, value: value);
  }

  void updateAdjustShadows(double value) {
    _updateAdjustValue(control: _AdjustControl.shadows, value: value);
  }

  void updateAdjustSharpness(double value) {
    _updateAdjustValue(control: _AdjustControl.sharpness, value: value);
  }

  void cancelFilterSession() {
    if (!_filterSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }
    _applyFilterState(_filterInitial);
    _resetFilterSessionState();
    _activeTool = null;
    notifyListeners();
  }

  void applyFilterSession() {
    if (!_filterSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }
    _resetFilterSessionState();
    _activeTool = null;
    markEdit();
  }

  void resetFilterSession() {
    if (!_filterSessionActive) {
      return;
    }
    _filterDraft = PhotoFilterConfig.none;
    _applyFilterDraftPreview();
    notifyListeners();
  }

  void selectFilterPreset(PhotoFilterPreset preset) {
    if (!_filterSessionActive) {
      return;
    }
    final intensity = preset == PhotoFilterPreset.none
        ? 0.0
        : (_filterDraft.intensity <= 0 ? 1.0 : _filterDraft.intensity);
    _filterDraft = _filterDraft.copyWith(preset: preset, intensity: intensity);
    _applyFilterDraftPreview();
    notifyListeners();
  }

  void updateFilterIntensity(double value) {
    if (!_filterSessionActive) {
      return;
    }
    final normalized = value.clamp(0.0, 1.0);
    final preset = normalized <= 0
        ? PhotoFilterPreset.none
        : _filterDraft.preset;
    _filterDraft = _filterDraft.copyWith(preset: preset, intensity: normalized);
    _applyFilterDraftPreview();
    notifyListeners();
  }

  void cancelBorderFrameSession() {
    if (!_borderFrameSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }
    _applyBorderFrameState(_borderFrameInitial, target: _borderFrameTarget);
    _resetBorderFrameSessionState();
    _activeTool = null;
    notifyListeners();
  }

  void applyBorderFrameSession() {
    if (!_borderFrameSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }
    _resetBorderFrameSessionState();
    _activeTool = null;
    markEdit();
  }

  void resetBorderFrameSession() {
    if (!_borderFrameSessionActive) {
      return;
    }
    _borderFrameDraft = DecorationStyleConfig.none;
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void setBorderFrameSection(BorderFrameSection section) {
    if (_borderFrameSection == section) {
      return;
    }
    _borderFrameSection = section;
    notifyListeners();
  }

  void setBorderFrameTarget(BorderFrameTarget target) {
    if (_borderFrameTarget == target) {
      return;
    }
    _applyBorderFrameState(_borderFrameInitial, target: _borderFrameTarget);
    _borderFrameTarget = target;
    _loadBorderFrameStateForTarget(target);
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void updateBorderStyle(BorderStylePreset style) {
    if (!_borderFrameSessionActive) {
      return;
    }
    _borderFrameSection = BorderFrameSection.border;
    _borderFrameDraft = _borderFrameDraft.copyWith(
      border: _borderFrameDraft.border.copyWith(style: style),
    );
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void updateBorderThickness(double value) {
    if (!_borderFrameSessionActive) {
      return;
    }
    _borderFrameDraft = _borderFrameDraft.copyWith(
      border: _borderFrameDraft.border.copyWith(
        thickness: value.clamp(0.0, 0.18),
      ),
    );
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void updateBorderCornerRadius(double value) {
    if (!_borderFrameSessionActive) {
      return;
    }
    _borderFrameDraft = _borderFrameDraft.copyWith(
      border: _borderFrameDraft.border.copyWith(
        cornerRadius: value.clamp(0.0, 0.30),
      ),
    );
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void updateBorderOpacity(double value) {
    if (!_borderFrameSessionActive) {
      return;
    }
    _borderFrameDraft = _borderFrameDraft.copyWith(
      border: _borderFrameDraft.border.copyWith(opacity: value.clamp(0.0, 1.0)),
    );
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void updateBorderShadow(double value) {
    if (!_borderFrameSessionActive) {
      return;
    }
    _borderFrameDraft = _borderFrameDraft.copyWith(
      border: _borderFrameDraft.border.copyWith(shadow: value.clamp(0.0, 1.0)),
    );
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void selectFramePreset(String presetId) {
    if (!_borderFrameSessionActive) {
      return;
    }
    final preset = _framePresetById(presetId);
    if (preset == null) {
      return;
    }
    _borderFrameSection = BorderFrameSection.frame;
    final nextFrame = _borderFrameDraft.frame.copyWith(
      presetId: presetId,
      opacity: _borderFrameDraft.frame.opacity <= 0
          ? preset.opacity
          : _borderFrameDraft.frame.opacity,
      size: preset.size,
    );
    _borderFrameDraft = _borderFrameDraft.copyWith(frame: nextFrame);
    _addRecentFramePreset(presetId);
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void toggleFavoriteFramePreset(String presetId) {
    if (_favoriteFramePresetIds.contains(presetId)) {
      _favoriteFramePresetIds.remove(presetId);
    } else {
      _favoriteFramePresetIds.add(presetId);
    }
    notifyListeners();
  }

  void updateFrameOpacity(double value) {
    if (!_borderFrameSessionActive) {
      return;
    }
    _borderFrameDraft = _borderFrameDraft.copyWith(
      frame: _borderFrameDraft.frame.copyWith(opacity: value.clamp(0.0, 1.0)),
    );
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  void updateFrameSize(double value) {
    if (!_borderFrameSessionActive) {
      return;
    }
    _borderFrameDraft = _borderFrameDraft.copyWith(
      frame: _borderFrameDraft.frame.copyWith(size: value.clamp(0.05, 0.24)),
    );
    _applyBorderFrameDraftPreview();
    notifyListeners();
  }

  Future<void> runAutoRemoveBackground() async {
    if (!_removeBgSessionActive || _removeBgIsProcessing) {
      return;
    }

    final imageUrl = _currentRemoveBgImageUrl;
    if (imageUrl == null) {
      return;
    }

    _removeBgIsProcessing = true;
    notifyListeners();

    try {
      final result = await _backgroundRemovalService.autoRemove(
        BackgroundRemovalRequest(
          imageUrl: imageUrl,
          imageSize: _currentRemoveBgImageSize,
          pipeline: BackgroundRemovalPipeline.offlineFast,
        ),
      );
      _removeBgDraft = _removeBgDraft.copyWith(
        autoMask: result.maskTemplate,
        lastAppliedMode: result.engineLabel,
      );
      _applyRemoveBgDraftPreview();
    } finally {
      _removeBgIsProcessing = false;
      notifyListeners();
    }
  }

  void cancelRemoveBgSession() {
    if (!_removeBgSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }
    _applyRemoveBgState(_removeBgInitial);
    _resetRemoveBgSessionState();
    _activeTool = null;
    notifyListeners();
  }

  void applyRemoveBgSession() {
    if (!_removeBgSessionActive) {
      _activeTool = null;
      notifyListeners();
      return;
    }
    _resetRemoveBgSessionState();
    _activeTool = null;
    markEdit();
  }

  void resetRemoveBgSession() {
    if (!_removeBgSessionActive) {
      return;
    }
    _removeBgDraft = RemoveBgState.none;
    _removeBgRefineMode = RemoveBgRefineMode.erase;
    _removeBgBrushSize = 0.11;
    _removeBgSoftness = 0.45;
    _applyRemoveBgDraftPreview();
    notifyListeners();
  }

  void setRemoveBgRefineMode(RemoveBgRefineMode mode) {
    if (_removeBgRefineMode == mode) {
      return;
    }
    _removeBgRefineMode = mode;
    notifyListeners();
  }

  void updateRemoveBgBrushSize(double value) {
    _removeBgBrushSize = value.clamp(0.04, 0.28);
    notifyListeners();
  }

  void updateRemoveBgSoftness(double value) {
    _removeBgSoftness = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void startRemoveBgRefineStroke(Offset normalizedPoint) {
    if (!_removeBgSessionActive) {
      return;
    }
    final point = _clampNormalizedPoint(normalizedPoint);
    final strokes = List<RemoveBgStroke>.from(_removeBgDraft.strokes)
      ..add(
        RemoveBgStroke(
          mode: _removeBgRefineMode,
          points: <Offset>[point],
          brushSize: _removeBgBrushSize,
          softness: _removeBgSoftness,
        ),
      );
    _activeRemoveBgStrokeIndex = strokes.length - 1;
    _removeBgDraft = _removeBgDraft.copyWith(strokes: strokes);
    _applyRemoveBgDraftPreview();
    notifyListeners();
  }

  void appendRemoveBgRefineStroke(Offset normalizedPoint) {
    if (!_removeBgSessionActive || _activeRemoveBgStrokeIndex < 0) {
      return;
    }
    final strokes = List<RemoveBgStroke>.from(_removeBgDraft.strokes);
    if (_activeRemoveBgStrokeIndex >= strokes.length) {
      return;
    }
    final current = strokes[_activeRemoveBgStrokeIndex];
    strokes[_activeRemoveBgStrokeIndex] = current.copyWith(
      points: <Offset>[
        ...current.points,
        _clampNormalizedPoint(normalizedPoint),
      ],
    );
    _removeBgDraft = _removeBgDraft.copyWith(strokes: strokes);
    _applyRemoveBgDraftPreview();
    notifyListeners();
  }

  void endRemoveBgRefineStroke() {
    if (_activeRemoveBgStrokeIndex < 0) {
      return;
    }
    _activeRemoveBgStrokeIndex = -1;
    notifyListeners();
  }

  List<EditorElementAsset> filterElementAssets({
    required String category,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final source = category == 'Recent'
        ? _recentElementAssetIds
              .map(_elementAssetById)
              .whereType<EditorElementAsset>()
              .toList(growable: false)
        : _elementAssetCatalog;
    return source
        .where((asset) {
          final categoryMatch = category == 'Recent'
              ? true
              : asset.category == category;
          final queryMatch =
              normalizedQuery.isEmpty ||
              asset.name.toLowerCase().contains(normalizedQuery) ||
              asset.tags.any(
                (tag) => tag.toLowerCase().contains(normalizedQuery),
              );
          return categoryMatch && queryMatch;
        })
        .toList(growable: false);
  }

  List<EditorStickerAsset> filterStickerAssets({
    required String category,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final source = category == 'Recent'
        ? _recentStickerAssetIds
              .map(_stickerAssetById)
              .whereType<EditorStickerAsset>()
              .toList(growable: false)
        : _stickerAssetCatalog;
    return source
        .where((asset) {
          final categoryMatch = category == 'Recent'
              ? true
              : asset.category == category;
          final queryMatch =
              normalizedQuery.isEmpty ||
              asset.name.toLowerCase().contains(normalizedQuery) ||
              asset.tags.any(
                (tag) => tag.toLowerCase().contains(normalizedQuery),
              );
          return categoryMatch && queryMatch;
        })
        .toList(growable: false);
  }

  Map<String, Object?> buildDraftPayload() {
    final currentEntry = _captureHistoryEntry();
    final lastEntry = _lastCommittedState ?? currentEntry;
    return <String, Object?>{
      'savedAt': DateTime.now().toIso8601String(),
      'schemaVersion': 2,
      'stageBackground': _serializeStageBackground(_stageBackground),
      'recentBackgroundColors': _recentBackgroundColors
          .map((color) => color.toARGB32())
          .toList(growable: false),
      'backgroundSampleSeq': _backgroundSampleSeq,
      'mainSurface': _mainSurfacePhoto == null
          ? null
          : <String, Object?>{
              'imageUrl': _mainSurfacePhoto!.imageUrl,
              'scale': _mainSurfaceScale,
              'rotation': _mainSurfaceRotation,
              'offset': _serializeOffset(_mainSurfaceOffset),
              'cropRatio': _mainSurfaceCropRatio,
              'cropTurns': _mainSurfaceCropTurns,
              'adjustments': _serializeAdjustments(
                _mainSurfacePhoto!.adjustments,
              ),
              'filter': _serializeFilter(_mainSurfacePhoto!.filter),
              'removeBg': _serializeRemoveBg(_mainSurfacePhoto!.removeBgState),
              'decoration': _serializeDecoration(_mainSurfacePhoto!.decoration),
              'visuals': _serializeVisuals(_mainSurfacePhoto!.visuals),
              'isLocked': _mainSurfacePhoto!.isLocked,
            },
      'mainSurfaceImageSize': _mainSurfaceImageSize == null
          ? null
          : _serializeSize(_mainSurfaceImageSize!),
      'extraPhotos': _extraPhotoLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'imageUrl': layer.imageUrl,
              'name': layer.name,
              'size': _serializeSize(layer.size),
              'offset': _serializeOffset(layer.offset),
              'scale': layer.scale,
              'rotation': layer.rotation,
              'cropRatio': layer.cropRatio,
              'cropTurns': layer.cropTurns,
              'adjustments': _serializeAdjustments(layer.adjustments),
              'filter': _serializeFilter(layer.filter),
              'removeBg': _serializeRemoveBg(layer.removeBgState),
              'decoration': _serializeDecoration(layer.decoration),
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'texts': _textLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'name': layer.name,
              'text': layer.text,
              'offset': _serializeOffset(layer.offset),
              'rotation': layer.rotation,
              'scale': layer.scale,
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
              'isFlipped': layer.isFlipped,
              'isFlippedVertical': layer.isFlippedVertical,
              'blendMode': layer.blendMode.name,
              'style': _serializeTextStyle(layer.style),
            },
          )
          .toList(growable: false),
      'elements': _elementLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'assetId': layer.assetId,
              'assetUrl': layer.assetUrl,
              'name': layer.name,
              'category': layer.category,
              'size': _serializeSize(layer.size),
              'offset': _serializeOffset(layer.offset),
              'scale': layer.scale,
              'rotation': layer.rotation,
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'stickers': _stickerLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'stickerId': layer.stickerId,
              'stickerUrl': layer.stickerUrl,
              'name': layer.name,
              'category': layer.category,
              'size': _serializeSize(layer.size),
              'offset': _serializeOffset(layer.offset),
              'scale': layer.scale,
              'rotation': layer.rotation,
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'drawLayers': _drawLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'name': layer.name,
              'strokes': layer.strokes
                  .map((stroke) => _serializeDrawStroke(stroke))
                  .toList(growable: false),
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'shapeLayers': _shapeLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'kind': layer.kind.name,
              'name': layer.name,
              'size': _serializeSize(layer.size),
              'offset': _serializeOffset(layer.offset),
              'scale': layer.scale,
              'rotation': layer.rotation,
              'fillColor': layer.fillColor.toARGB32(),
              'useGradientFill': layer.useGradientFill,
              'gradientColors': layer.gradientColors
                  .map((color) => color.toARGB32())
                  .toList(growable: false),
              'strokeColor': layer.strokeColor.toARGB32(),
              'strokeWidth': layer.strokeWidth,
              'opacity': layer.opacity,
              'cornerRadius': layer.cornerRadius,
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'selection': <String, Object?>{
        'isMainSurfaceSelected': _isMainSurfaceSelected,
        'selectedExtraPhotoLayerId': _selectedExtraPhotoLayerId,
        'selectedTextLayerId': _selectedTextLayerId,
        'selectedElementLayerId': _selectedElementLayerId,
        'selectedStickerLayerId': _selectedStickerLayerId,
        'selectedDrawLayerId': _selectedDrawLayerId,
        'selectedShapeLayerId': _selectedShapeLayerId,
      },
      'activeToolId': _activeTool?.id.name,
      'seq': <String, int>{
        'photo': _photoSeq,
        'element': _elementSeq,
        'sticker': _stickerSeq,
        'draw': _drawSeq,
        'shape': _shapeSeq,
        'drawStroke': _drawStrokeSeq,
        'text': _textSeq,
      },
      'history': <String, Object?>{
        'undo': _undoHistory
            .map((entry) => _serializeHistorySnapshot(entry.snapshot))
            .toList(growable: false),
        'redo': _redoHistory
            .map((entry) => _serializeHistorySnapshot(entry.snapshot))
            .toList(growable: false),
        'last': _serializeHistorySnapshot(lastEntry.snapshot),
      },
    };
  }

  void applyDraftPayload(Map<String, Object?> payload) {
    final currentSnapshot = _historySnapshotFromDraftPayload(payload);
    final currentSignature = jsonEncode(
      _serializeHistorySnapshot(currentSnapshot),
    );
    final currentEntry = _EditorHistoryEntry(
      snapshot: currentSnapshot,
      signature: currentSignature,
    );

    _restoreFromHistory(currentEntry);

    final historyMap = _asMap(payload['history']);
    final undoEntries = <_EditorHistoryEntry>[];
    final redoEntries = <_EditorHistoryEntry>[];

    if (historyMap != null) {
      final undoList = _asList(historyMap['undo']);
      if (undoList != null) {
        for (final item in undoList) {
          final entry = _historyEntryFromSerializedMap(_asMap(item));
          if (entry != null) {
            undoEntries.add(entry);
          }
        }
      }

      final redoList = _asList(historyMap['redo']);
      if (redoList != null) {
        for (final item in redoList) {
          final entry = _historyEntryFromSerializedMap(_asMap(item));
          if (entry != null) {
            redoEntries.add(entry);
          }
        }
      }
    }

    if (undoEntries.length > _historyLimit) {
      undoEntries.removeRange(0, undoEntries.length - _historyLimit);
    }
    if (redoEntries.length > _historyLimit) {
      redoEntries.removeRange(0, redoEntries.length - _historyLimit);
    }

    _undoHistory
      ..clear()
      ..addAll(undoEntries);
    _redoHistory
      ..clear()
      ..addAll(redoEntries);
    _lastCommittedState = currentEntry;
    final activeToolName = _asString(payload['activeToolId']);
    if (activeToolName == null) {
      _activeTool = null;
    } else {
      _activeTool = null;
      for (final tool in kEditorTools) {
        if (tool.id.name == activeToolName) {
          _activeTool = tool;
          break;
        }
      }
    }
    _normalizeSelectionState();
    _selectedLayerQuickActionTool = null;
    notifyListeners();
  }

  void addElementToStage(EditorElementAsset asset) {
    _addRecentElementAsset(asset.id);
    _elementSeq += 1;
    final layerId = 'element_$_elementSeq';
    _elementLayers.add(
      StageElementLayer(
        id: layerId,
        assetId: asset.id,
        assetUrl: asset.url,
        name: 'Element $_elementSeq',
        category: asset.category,
        size: _buildElementInitialSize(),
        offset: Offset.zero,
        scale: 1,
        rotation: 0,
        zIndex: _nextOverlayZIndex,
      ),
    );
    _selectedElementLayerId = layerId;
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.elements);
    markEdit();
  }

  void addStickerToStage(EditorStickerAsset asset) {
    _addRecentStickerAsset(asset.id);
    _stickerSeq += 1;
    final layerId = 'sticker_$_stickerSeq';
    _stickerLayers.add(
      StageStickerLayer(
        id: layerId,
        stickerId: asset.id,
        stickerUrl: asset.url,
        name: 'Sticker $_stickerSeq',
        category: asset.category,
        size: _buildStickerInitialSize(),
        offset: Offset.zero,
        scale: 1,
        rotation: 0,
        zIndex: _nextOverlayZIndex,
      ),
    );
    _selectedStickerLayerId = layerId;
    _selectedElementLayerId = null;
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.stickers);
    markEdit();
  }

  void addShapeToStage(ShapeKind kind) {
    _shapeSeq += 1;
    final layerId = 'shape_$_shapeSeq';
    _shapeLayers.add(
      StageShapeLayer(
        id: layerId,
        kind: kind,
        name: 'Shape $_shapeSeq',
        size: _buildShapeInitialSize(kind),
        offset: Offset.zero,
        scale: 1,
        rotation: 0,
        zIndex: _nextOverlayZIndex,
      ),
    );
    _selectedShapeLayerId = layerId;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = null;
    _selectedDrawLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.shapes);
    markEdit();
  }

  void updateSelectedShapeFillColor(Color color) {
    final layer = selectedShapeLayer;
    if (layer == null || layer.isLocked) {
      return;
    }
    _updateShapeLayer(
      layer.id,
      (current) => current.copyWith(fillColor: color),
    );
    markEdit();
  }

  void updateSelectedShapeStrokeColor(Color color) {
    final layer = selectedShapeLayer;
    if (layer == null || layer.isLocked) {
      return;
    }
    _updateShapeLayer(
      layer.id,
      (current) => current.copyWith(
        strokeColor: color,
        strokeWidth: current.strokeWidth <= 0 ? 0.02 : current.strokeWidth,
      ),
    );
    markEdit();
  }

  void updateSelectedShapeStrokeWidth(double value) {
    final layer = selectedShapeLayer;
    if (layer == null || layer.isLocked) {
      return;
    }
    _updateShapeLayer(
      layer.id,
      (current) => current.copyWith(strokeWidth: value.clamp(0.0, 0.22)),
    );
    markEdit();
  }

  void updateSelectedShapeOpacity(double value) {
    final layer = selectedShapeLayer;
    if (layer == null || layer.isLocked) {
      return;
    }
    _updateShapeLayer(
      layer.id,
      (current) => current.copyWith(opacity: value.clamp(0.0, 1.0)),
    );
    markEdit();
  }

  void updateSelectedShapeCornerRadius(double value) {
    final layer = selectedShapeLayer;
    if (layer == null || layer.isLocked) {
      return;
    }
    _updateShapeLayer(
      layer.id,
      (current) => current.copyWith(cornerRadius: value.clamp(0.0, 0.5)),
    );
    markEdit();
  }

  void updateSelectedShapeGradient({
    required bool enabled,
    List<Color>? colors,
  }) {
    final layer = selectedShapeLayer;
    if (layer == null || layer.isLocked) {
      return;
    }
    _updateShapeLayer(
      layer.id,
      (current) => current.copyWith(
        useGradientFill: enabled,
        gradientColors: colors ?? current.gradientColors,
      ),
    );
    markEdit();
  }

  void markEdit() {
    final currentState = _captureHistoryEntry();
    final lastState = _lastCommittedState;
    if (lastState == null) {
      _lastCommittedState = currentState;
      notifyListeners();
      return;
    }

    if (currentState.signature == lastState.signature) {
      notifyListeners();
      return;
    }

    _undoHistory.add(lastState);
    if (_undoHistory.length > _historyLimit) {
      _undoHistory.removeAt(0);
    }
    _redoHistory.clear();
    _lastCommittedState = currentState;
    notifyListeners();
  }

  void undo() {
    if (_drawSessionActive && _drawDraftStrokes.isNotEmpty) {
      undoDrawStroke();
      return;
    }
    if (_undoHistory.isEmpty) {
      return;
    }
    final currentState = _captureHistoryEntry();
    final previousState = _undoHistory.removeLast();
    _redoHistory.add(currentState);
    if (_redoHistory.length > _historyLimit) {
      _redoHistory.removeAt(0);
    }
    _restoreFromHistory(previousState);
    _lastCommittedState = previousState;
    notifyListeners();
  }

  void redo() {
    if (_drawSessionActive && _drawRedoStack.isNotEmpty) {
      redoDrawStroke();
      return;
    }
    if (_redoHistory.isEmpty) {
      return;
    }
    final currentState = _captureHistoryEntry();
    final nextState = _redoHistory.removeLast();
    _undoHistory.add(currentState);
    if (_undoHistory.length > _historyLimit) {
      _undoHistory.removeAt(0);
    }
    _restoreFromHistory(nextState);
    _lastCommittedState = nextState;
    notifyListeners();
  }

  void setStageSolidBackground(Color color) {
    _stageBackground = StageBackgroundConfig.solid(color);
    _addRecentBackgroundColor(color);
    markEdit();
  }

  void setStageGradientBackground(List<Color> colors, {double angle = 270}) {
    _stageBackground = StageBackgroundConfig.gradient(colors, angle: angle);
    if (colors.isNotEmpty) {
      _addRecentBackgroundColor(colors.first);
    }
    markEdit();
  }

  void setStageImageBackground(String imageUrl) {
    _stageBackground = StageBackgroundConfig.image(
      imageUrl,
      fit: _stageBackground.imageFit,
      blur: _stageBackground.imageBlur,
      opacity: _stageBackground.imageOpacity,
    );
    markEdit();
  }

  void setBackgroundImageFit(StageBackgroundImageFit fit) {
    _stageBackground = _stageBackground.copyWith(
      type: StageBackgroundType.image,
      imageFit: fit,
    );
    markEdit();
  }

  void setBackgroundImageBlur(double blur) {
    _stageBackground = _stageBackground.copyWith(
      type: StageBackgroundType.image,
      imageBlur: blur.clamp(0, 20),
    );
    markEdit();
  }

  void setBackgroundImageOpacity(double opacity) {
    _stageBackground = _stageBackground.copyWith(
      type: StageBackgroundType.image,
      imageOpacity: opacity.clamp(0.1, 1),
    );
    markEdit();
  }

  Future<void> addPhotoToStage(String imageUrl) async {
    if (_mainSurfacePhoto == null) {
      _mainSurfacePhoto = StageSurfacePhoto(imageUrl: imageUrl);
      _mainSurfaceScale = _mainSurfaceMinScale;
      _mainSurfaceRotation = 0;
      _mainSurfaceOffset = Offset.zero;
      _showHorizontalGuide = false;
      _showVerticalGuide = false;
      notifyListeners();

      final loadedSize = await _loadImageSize(imageUrl);
      if (loadedSize != null && _mainSurfacePhoto?.imageUrl == imageUrl) {
        _mainSurfaceImageSize = loadedSize;
        _mainSurfaceOffset = _clampOffset(
          _mainSurfaceOffset,
          _mainSurfaceScale,
        );
        notifyListeners();
      }
      markEdit();
      return;
    }

    final loadedSize = await _loadImageSize(imageUrl);

    _photoSeq += 1;
    final layerId = 'photo_$_photoSeq';
    final layer = StagePhotoLayer(
      id: layerId,
      imageUrl: imageUrl,
      name: 'Photo ${_photoSeq + 1}',
      size: _buildExtraLayerInitialSize(loadedSize),
      offset: Offset.zero,
      scale: 1,
      rotation: 0,
      zIndex: _nextOverlayZIndex,
    );

    _extraPhotoLayers.add(layer);
    _selectedTextLayerId = null;
    _selectedExtraPhotoLayerId = layerId;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _selectedShapeLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.photo);
    markEdit();
  }

  Size _buildExtraLayerInitialSize(Size? sourceSize) {
    final stageWidth = _stageSize.width > 0 ? _stageSize.width : 360;
    final stageHeight = _stageSize.height > 0 ? _stageSize.height : 640;

    final maxWidth = stageWidth * 0.72;
    final maxHeight = stageHeight * 0.58;
    const minSide = 120.0;

    if (sourceSize == null || sourceSize.width <= 0 || sourceSize.height <= 0) {
      final side = math.max(minSide, math.min(maxWidth, 220));
      return Size(side.toDouble(), side.toDouble());
    }

    final widthRatio = maxWidth / sourceSize.width;
    final heightRatio = maxHeight / sourceSize.height;
    final ratio = math.min(widthRatio, heightRatio);

    final fittedWidth = sourceSize.width * ratio;
    final fittedHeight = sourceSize.height * ratio;

    return Size(
      fittedWidth.clamp(minSide, maxWidth),
      fittedHeight.clamp(minSide, maxHeight),
    );
  }

  Size _buildElementInitialSize() {
    final stageWidth = _stageSize.width > 0 ? _stageSize.width : 360;
    final side = (stageWidth * 0.28).clamp(90.0, 180.0);
    return Size.square(side);
  }

  Size _buildStickerInitialSize() {
    final stageWidth = _stageSize.width > 0 ? _stageSize.width : 360;
    final side = (stageWidth * 0.24).clamp(84.0, 152.0);
    return Size.square(side);
  }

  Size _buildShapeInitialSize(ShapeKind kind) {
    final stageWidth = _stageSize.width > 0 ? _stageSize.width : 360;
    final stageHeight = _stageSize.height > 0 ? _stageSize.height : 640;
    final base = (stageWidth * 0.3).clamp(90.0, 210.0);
    switch (kind) {
      case ShapeKind.line:
        return Size(base * 1.25, (base * 0.12).clamp(8.0, 22.0));
      case ShapeKind.arrow:
        return Size(base * 1.15, base * 0.65);
      case ShapeKind.oval:
        return Size(base * 1.1, base * 0.72);
      case ShapeKind.triangle:
      case ShapeKind.polygon:
      case ShapeKind.star:
      case ShapeKind.heart:
      case ShapeKind.circle:
      case ShapeKind.rectangle:
      case ShapeKind.roundedRectangle:
        final side = math.min(base, stageHeight * 0.32);
        return Size.square(side);
    }
  }

  Future<Size?> _loadImageSize(String imageUrl) async {
    try {
      final completer = Completer<Size?>();
      final image = editorImageProvider(imageUrl);
      final stream = image.resolve(const ImageConfiguration());
      ImageStreamListener? listener;
      listener = ImageStreamListener(
        (info, _) {
          final size = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          if (!completer.isCompleted) {
            completer.complete(size);
          }
          if (listener != null) {
            stream.removeListener(listener);
          }
        },
        onError: (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          if (listener != null) {
            stream.removeListener(listener);
          }
        },
      );
      stream.addListener(listener);
      return completer.future;
    } catch (_) {
      return null;
    }
  }

  void onToolOptionTap(EditorToolDefinition tool, String option) {
    if (tool.id == EditorToolId.text) {
      addTextLayer();
      return;
    }

    if (tool.id == EditorToolId.photo) {
      requestPhotoPicker();
      return;
    }

    if (tool.id == EditorToolId.elements) {
      if (_elementAssetCatalog.isNotEmpty) {
        addElementToStage(_elementAssetCatalog.first);
      }
      return;
    }

    if (tool.id == EditorToolId.stickers) {
      if (_stickerAssetCatalog.isNotEmpty) {
        addStickerToStage(_stickerAssetCatalog.first);
      }
      return;
    }

    if (tool.id == EditorToolId.background) {
      if (option.contains('కలర్')) {
        setStageSolidBackground(Colors.white);
      } else if (option.contains('గ్రేడియంట్')) {
        setStageGradientBackground(const <Color>[
          Color(0xFFF8FAFF),
          Color(0xFFEAF1FF),
        ]);
      } else if (option.contains('ఫోటో')) {
        requestBackgroundImagePicker();
      } else {
        markEdit();
      }
      return;
    }

    if (tool.id == EditorToolId.removeBg) {
      if (option.toLowerCase().contains('auto')) {
        runAutoRemoveBackground();
        return;
      }
      markEdit();
      return;
    }

    markEdit();
  }

  void onExtraPhotoScaleStart(String layerId, ScaleStartDetails details) {
    final layer = _findExtraPhotoLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }

    _activeExtraPhotoGestureLayerId = layerId;
    _extraPhotoGestureStartScale = layer.scale;
    _extraPhotoGestureStartRotation = layer.rotation;
    _extraPhotoGestureStartOffset = layer.offset;
    _extraPhotoGestureStartFocal = details.focalPoint;
    _isExtraPhotoLayerInteracting = true;
  }

  void onExtraPhotoScaleUpdate(String layerId, ScaleUpdateDetails details) {
    if (_activeExtraPhotoGestureLayerId != layerId) {
      return;
    }
    final layer = _findExtraPhotoLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }

    final rawScale = (_extraPhotoGestureStartScale * details.scale).clamp(
      _overlayMinScale,
      _overlayMaxScale,
    );
    final rawRotation = _extraPhotoGestureStartRotation + details.rotation;
    final snappedRotation = _softSnapRotation(rawRotation);

    final dragDelta = details.focalPoint - _extraPhotoGestureStartFocal;
    final rawOffset = _extraPhotoGestureStartOffset + dragDelta;
    final clampedOffset = _clampExtraLayerOffset(
      layer: layer,
      offset: rawOffset,
      scale: rawScale,
    );

    _updateExtraPhotoLayer(
      layerId,
      (current) => current.copyWith(
        scale: rawScale,
        rotation: snappedRotation,
        offset: clampedOffset,
      ),
    );
    _showVerticalGuide = clampedOffset.dx.abs() <= _guideCenterThreshold;
    _showHorizontalGuide = clampedOffset.dy.abs() <= _guideCenterThreshold;
    if (_nearlyEqual(layer.scale, rawScale) &&
        _nearlyEqual(layer.rotation, snappedRotation) &&
        _offsetNearlyEqual(layer.offset, clampedOffset)) {
      return;
    }
    notifyListeners();
  }

  void onExtraPhotoScaleEnd(String layerId, ScaleEndDetails details) {
    if (_activeExtraPhotoGestureLayerId != layerId) {
      return;
    }

    final layer = _findExtraPhotoLayer(layerId);
    if (layer != null) {
      final finalRotation = _hardSnapRotation(layer.rotation);
      final finalOffset = _snapOffsetToGuides(
        _clampExtraLayerOffset(
          layer: layer,
          offset: layer.offset,
          scale: layer.scale,
        ),
      );
      _updateExtraPhotoLayer(
        layerId,
        (current) =>
            current.copyWith(rotation: finalRotation, offset: finalOffset),
      );
      final hasChanged = _hasTransformChanged(
        startScale: _extraPhotoGestureStartScale,
        endScale: layer.scale,
        startRotation: _extraPhotoGestureStartRotation,
        endRotation: finalRotation,
        startOffset: _extraPhotoGestureStartOffset,
        endOffset: finalOffset,
      );
      _activeExtraPhotoGestureLayerId = null;
      _isExtraPhotoLayerInteracting = false;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      if (hasChanged) {
        markEdit();
      } else {
        notifyListeners();
      }
      return;
    }

    _activeExtraPhotoGestureLayerId = null;
    _isExtraPhotoLayerInteracting = false;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
    notifyListeners();
  }

  void onElementScaleStart(String layerId, ScaleStartDetails details) {
    final layer = _findElementLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }
    _activeElementGestureLayerId = layerId;
    _elementGestureStartScale = layer.scale;
    _elementGestureStartRotation = layer.rotation;
    _elementGestureStartOffset = layer.offset;
    _elementGestureStartFocal = details.focalPoint;
    _isElementLayerInteracting = true;
  }

  void onElementScaleUpdate(String layerId, ScaleUpdateDetails details) {
    if (_activeElementGestureLayerId != layerId) {
      return;
    }
    final layer = _findElementLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }

    final rawScale = (_elementGestureStartScale * details.scale).clamp(
      _overlayMinScale,
      _overlayMaxScale,
    );
    final rawRotation = _elementGestureStartRotation + details.rotation;
    final snappedRotation = _softSnapRotation(rawRotation);
    final dragDelta = details.focalPoint - _elementGestureStartFocal;
    final rawOffset = _elementGestureStartOffset + dragDelta;
    final clampedOffset = _clampElementOffset(
      layer: layer,
      offset: rawOffset,
      scale: rawScale,
    );

    _updateElementLayer(
      layerId,
      (current) => current.copyWith(
        scale: rawScale,
        rotation: snappedRotation,
        offset: clampedOffset,
      ),
    );
    _showVerticalGuide = clampedOffset.dx.abs() <= _guideCenterThreshold;
    _showHorizontalGuide = clampedOffset.dy.abs() <= _guideCenterThreshold;
    if (_nearlyEqual(layer.scale, rawScale) &&
        _nearlyEqual(layer.rotation, snappedRotation) &&
        _offsetNearlyEqual(layer.offset, clampedOffset)) {
      return;
    }
    notifyListeners();
  }

  void onElementScaleEnd(String layerId, ScaleEndDetails details) {
    if (_activeElementGestureLayerId != layerId) {
      return;
    }

    final layer = _findElementLayer(layerId);
    if (layer != null) {
      final finalRotation = _hardSnapRotation(layer.rotation);
      final finalOffset = _snapOffsetToGuides(
        _clampElementOffset(
          layer: layer,
          offset: layer.offset,
          scale: layer.scale,
        ),
      );
      _updateElementLayer(
        layerId,
        (current) =>
            current.copyWith(rotation: finalRotation, offset: finalOffset),
      );
      final hasChanged = _hasTransformChanged(
        startScale: _elementGestureStartScale,
        endScale: layer.scale,
        startRotation: _elementGestureStartRotation,
        endRotation: finalRotation,
        startOffset: _elementGestureStartOffset,
        endOffset: finalOffset,
      );
      _activeElementGestureLayerId = null;
      _isElementLayerInteracting = false;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      if (hasChanged) {
        markEdit();
      } else {
        notifyListeners();
      }
      return;
    }

    _activeElementGestureLayerId = null;
    _isElementLayerInteracting = false;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
    notifyListeners();
  }

  void onStickerScaleStart(String layerId, ScaleStartDetails details) {
    final layer = _findStickerLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }
    _activeStickerGestureLayerId = layerId;
    _stickerGestureStartScale = layer.scale;
    _stickerGestureStartRotation = layer.rotation;
    _stickerGestureStartOffset = layer.offset;
    _stickerGestureStartFocal = details.focalPoint;
    _isStickerLayerInteracting = true;
  }

  void onStickerScaleUpdate(String layerId, ScaleUpdateDetails details) {
    if (_activeStickerGestureLayerId != layerId) {
      return;
    }
    final layer = _findStickerLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }

    final rawScale = (_stickerGestureStartScale * details.scale).clamp(
      _overlayMinScale,
      _overlayMaxScale,
    );
    final rawRotation = _stickerGestureStartRotation + details.rotation;
    final snappedRotation = _softSnapRotation(rawRotation);
    final dragDelta = details.focalPoint - _stickerGestureStartFocal;
    final rawOffset = _stickerGestureStartOffset + dragDelta;
    final clampedOffset = _clampStickerOffset(
      layer: layer,
      offset: rawOffset,
      scale: rawScale,
    );

    _updateStickerLayer(
      layerId,
      (current) => current.copyWith(
        scale: rawScale,
        rotation: snappedRotation,
        offset: clampedOffset,
      ),
    );
    _showVerticalGuide = clampedOffset.dx.abs() <= _guideCenterThreshold;
    _showHorizontalGuide = clampedOffset.dy.abs() <= _guideCenterThreshold;
    if (_nearlyEqual(layer.scale, rawScale) &&
        _nearlyEqual(layer.rotation, snappedRotation) &&
        _offsetNearlyEqual(layer.offset, clampedOffset)) {
      return;
    }
    notifyListeners();
  }

  void onStickerScaleEnd(String layerId, ScaleEndDetails details) {
    if (_activeStickerGestureLayerId != layerId) {
      return;
    }

    final layer = _findStickerLayer(layerId);
    if (layer != null) {
      final finalRotation = _hardSnapRotation(layer.rotation);
      final finalOffset = _snapOffsetToGuides(
        _clampStickerOffset(
          layer: layer,
          offset: layer.offset,
          scale: layer.scale,
        ),
      );
      _updateStickerLayer(
        layerId,
        (current) =>
            current.copyWith(rotation: finalRotation, offset: finalOffset),
      );
      final hasChanged = _hasTransformChanged(
        startScale: _stickerGestureStartScale,
        endScale: layer.scale,
        startRotation: _stickerGestureStartRotation,
        endRotation: finalRotation,
        startOffset: _stickerGestureStartOffset,
        endOffset: finalOffset,
      );
      _activeStickerGestureLayerId = null;
      _isStickerLayerInteracting = false;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      if (hasChanged) {
        markEdit();
      } else {
        notifyListeners();
      }
      return;
    }

    _activeStickerGestureLayerId = null;
    _isStickerLayerInteracting = false;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
    notifyListeners();
  }

  void onShapeScaleStart(String layerId, ScaleStartDetails details) {
    final layer = _findShapeLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }
    _activeShapeGestureLayerId = layerId;
    _shapeGestureStartScale = layer.scale;
    _shapeGestureStartRotation = layer.rotation;
    _shapeGestureStartOffset = layer.offset;
    _shapeGestureStartFocal = details.focalPoint;
    _isShapeLayerInteracting = true;
  }

  void onShapeScaleUpdate(String layerId, ScaleUpdateDetails details) {
    if (_activeShapeGestureLayerId != layerId) {
      return;
    }
    final layer = _findShapeLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }
    final rawScale = (_shapeGestureStartScale * details.scale).clamp(
      _overlayMinScale,
      _overlayMaxScale,
    );
    final rawRotation = _shapeGestureStartRotation + details.rotation;
    final snappedRotation = _softSnapRotation(rawRotation);
    final dragDelta = details.focalPoint - _shapeGestureStartFocal;
    final rawOffset = _shapeGestureStartOffset + dragDelta;
    final clampedOffset = _clampShapeOffset(
      layer: layer,
      offset: rawOffset,
      scale: rawScale,
    );
    _updateShapeLayer(
      layerId,
      (current) => current.copyWith(
        scale: rawScale,
        rotation: snappedRotation,
        offset: clampedOffset,
      ),
    );
    _showVerticalGuide = clampedOffset.dx.abs() <= _guideCenterThreshold;
    _showHorizontalGuide = clampedOffset.dy.abs() <= _guideCenterThreshold;
    if (_nearlyEqual(layer.scale, rawScale) &&
        _nearlyEqual(layer.rotation, snappedRotation) &&
        _offsetNearlyEqual(layer.offset, clampedOffset)) {
      return;
    }
    notifyListeners();
  }

  void onShapeScaleEnd(String layerId, ScaleEndDetails details) {
    if (_activeShapeGestureLayerId != layerId) {
      return;
    }
    final layer = _findShapeLayer(layerId);
    if (layer != null) {
      final finalRotation = _hardSnapRotation(layer.rotation);
      final finalOffset = _snapOffsetToGuides(
        _clampShapeOffset(
          layer: layer,
          offset: layer.offset,
          scale: layer.scale,
        ),
      );
      _updateShapeLayer(
        layerId,
        (current) =>
            current.copyWith(rotation: finalRotation, offset: finalOffset),
      );
      final hasChanged = _hasTransformChanged(
        startScale: _shapeGestureStartScale,
        endScale: layer.scale,
        startRotation: _shapeGestureStartRotation,
        endRotation: finalRotation,
        startOffset: _shapeGestureStartOffset,
        endOffset: finalOffset,
      );
      _activeShapeGestureLayerId = null;
      _isShapeLayerInteracting = false;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      if (hasChanged) {
        markEdit();
      } else {
        notifyListeners();
      }
      return;
    }
    _activeShapeGestureLayerId = null;
    _isShapeLayerInteracting = false;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
    notifyListeners();
  }

  void reorderSelectedExtraPhotoForward() {
    final layer = selectedExtraPhotoLayer;
    if (layer == null) {
      return;
    }
    bringLayerToFrontFromEntry('photo:${layer.id}');
  }

  void reorderSelectedExtraPhotoBackward() {
    final layer = selectedExtraPhotoLayer;
    if (layer == null) {
      return;
    }
    sendLayerToBackFromEntry('photo:${layer.id}');
  }

  void bringSelectedExtraPhotoToFront() {
    final layer = selectedExtraPhotoLayer;
    if (layer == null) {
      return;
    }
    bringLayerToFrontFromEntry('photo:${layer.id}');
  }

  void toggleSelectedExtraPhotoLock() {
    final layer = selectedExtraPhotoLayer;
    if (layer == null) {
      return;
    }
    toggleLockForLayerEntry('photo:${layer.id}');
  }

  void toggleSelectedExtraPhotoVisibility() {
    final layer = selectedExtraPhotoLayer;
    if (layer == null) {
      return;
    }
    toggleVisibilityForLayerEntry('photo:${layer.id}');
  }

  void duplicateSelectedExtraPhotoLayer() {
    final layer = selectedExtraPhotoLayer;
    if (layer == null) {
      return;
    }
    duplicateLayerFromEntry('photo:${layer.id}');
  }

  void deleteSelectedExtraPhotoLayer() {
    final layer = selectedExtraPhotoLayer;
    if (layer == null) {
      return;
    }
    deleteLayerFromEntry('photo:${layer.id}');
  }

  void deleteSelectedLayer() {
    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _mainSurfacePhoto = null;
      _mainSurfaceImageSize = null;
      _mainSurfaceScale = _mainSurfaceMinScale;
      _mainSurfaceRotation = 0;
      _mainSurfaceOffset = Offset.zero;
      _mainSurfaceCropRatio = null;
      _mainSurfaceCropTurns = 0;
      _isMainSurfaceSelected = false;
      markEdit();
      return;
    }
    if (_selectedExtraPhotoLayerId != null) {
      deleteLayerFromEntry('photo:${_selectedExtraPhotoLayerId!}');
      return;
    }
    if (_selectedTextLayerId != null) {
      deleteLayerFromEntry('text:${_selectedTextLayerId!}');
      return;
    }
    if (_selectedElementLayerId != null) {
      deleteLayerFromEntry('element:${_selectedElementLayerId!}');
      return;
    }
    if (_selectedStickerLayerId != null) {
      deleteLayerFromEntry('sticker:${_selectedStickerLayerId!}');
      return;
    }
    if (_selectedDrawLayerId != null) {
      deleteLayerFromEntry('draw:${_selectedDrawLayerId!}');
      return;
    }
    if (_selectedShapeLayerId != null) {
      deleteLayerFromEntry('shape:${_selectedShapeLayerId!}');
    }
  }

  void selectLayerFromEntry(String entryId) {
    if (entryId == 'background') {
      clearOverlaySelection();
      return;
    }
    if (entryId == 'surface_photo') {
      selectMainSurfaceLayer();
      return;
    }
    if (entryId.startsWith('photo:')) {
      selectExtraPhotoLayer(entryId.replaceFirst('photo:', ''));
      return;
    }
    if (entryId.startsWith('text:')) {
      selectTextLayer(entryId.replaceFirst('text:', ''));
      return;
    }
    if (entryId.startsWith('element:')) {
      selectElementLayer(entryId.replaceFirst('element:', ''));
      return;
    }
    if (entryId.startsWith('sticker:')) {
      selectStickerLayer(entryId.replaceFirst('sticker:', ''));
      return;
    }
    if (entryId.startsWith('draw:')) {
      selectDrawLayer(entryId.replaceFirst('draw:', ''));
      return;
    }
    if (entryId.startsWith('shape:')) {
      selectShapeLayer(entryId.replaceFirst('shape:', ''));
    }
  }

  void toggleVisibilityForLayerEntry(String entryId) {
    if (entryId == 'surface_photo') {
      return;
    }
    if (entryId.startsWith('photo:')) {
      final id = entryId.replaceFirst('photo:', '');
      final layer = _findExtraPhotoLayer(id);
      if (layer == null) {
        return;
      }
      final nextVisible = !layer.isVisible;
      _updateExtraPhotoLayer(
        id,
        (current) => current.copyWith(isVisible: nextVisible),
      );
      if (!nextVisible && _selectedExtraPhotoLayerId == id) {
        _selectedExtraPhotoLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('text:')) {
      final id = entryId.replaceFirst('text:', '');
      final layer = _findTextLayer(id);
      if (layer == null) {
        return;
      }
      final nextVisible = !layer.isVisible;
      _updateTextLayer(
        id,
        (current) => current.copyWith(isVisible: nextVisible),
      );
      if (!nextVisible && _selectedTextLayerId == id) {
        _selectedTextLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('element:')) {
      final id = entryId.replaceFirst('element:', '');
      final layer = _findElementLayer(id);
      if (layer == null) {
        return;
      }
      final nextVisible = !layer.isVisible;
      _updateElementLayer(
        id,
        (current) => current.copyWith(isVisible: nextVisible),
      );
      if (!nextVisible && _selectedElementLayerId == id) {
        _selectedElementLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('sticker:')) {
      final id = entryId.replaceFirst('sticker:', '');
      final layer = _findStickerLayer(id);
      if (layer == null) {
        return;
      }
      final nextVisible = !layer.isVisible;
      _updateStickerLayer(
        id,
        (current) => current.copyWith(isVisible: nextVisible),
      );
      if (!nextVisible && _selectedStickerLayerId == id) {
        _selectedStickerLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('draw:')) {
      final id = entryId.replaceFirst('draw:', '');
      final layer = _findDrawLayer(id);
      if (layer == null) {
        return;
      }
      final nextVisible = !layer.isVisible;
      _updateDrawLayer(
        id,
        (current) => current.copyWith(isVisible: nextVisible),
      );
      if (!nextVisible && _selectedDrawLayerId == id) {
        _selectedDrawLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('shape:')) {
      final id = entryId.replaceFirst('shape:', '');
      final layer = _findShapeLayer(id);
      if (layer == null) {
        return;
      }
      final nextVisible = !layer.isVisible;
      _updateShapeLayer(
        id,
        (current) => current.copyWith(isVisible: nextVisible),
      );
      if (!nextVisible && _selectedShapeLayerId == id) {
        _selectedShapeLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
    }
  }

  void toggleLockForLayerEntry(String entryId) {
    if (entryId == 'surface_photo') {
      if (_mainSurfacePhoto == null) {
        return;
      }
      _mainSurfacePhoto = _mainSurfacePhoto!.copyWith(
        isLocked: !_mainSurfacePhoto!.isLocked,
      );
      markEdit();
      return;
    }
    if (entryId.startsWith('photo:')) {
      final id = entryId.replaceFirst('photo:', '');
      final layer = _findExtraPhotoLayer(id);
      if (layer == null) {
        return;
      }
      _updateExtraPhotoLayer(
        id,
        (current) => current.copyWith(isLocked: !current.isLocked),
      );
      markEdit();
      return;
    }

    if (entryId.startsWith('text:')) {
      final id = entryId.replaceFirst('text:', '');
      final layer = _findTextLayer(id);
      if (layer == null) {
        return;
      }
      _updateTextLayer(
        id,
        (current) => current.copyWith(isLocked: !current.isLocked),
      );
      markEdit();
      return;
    }

    if (entryId.startsWith('element:')) {
      final id = entryId.replaceFirst('element:', '');
      final layer = _findElementLayer(id);
      if (layer == null) {
        return;
      }
      _updateElementLayer(
        id,
        (current) => current.copyWith(isLocked: !current.isLocked),
      );
      markEdit();
      return;
    }

    if (entryId.startsWith('sticker:')) {
      final id = entryId.replaceFirst('sticker:', '');
      final layer = _findStickerLayer(id);
      if (layer == null) {
        return;
      }
      _updateStickerLayer(
        id,
        (current) => current.copyWith(isLocked: !current.isLocked),
      );
      markEdit();
      return;
    }

    if (entryId.startsWith('draw:')) {
      final id = entryId.replaceFirst('draw:', '');
      final layer = _findDrawLayer(id);
      if (layer == null) {
        return;
      }
      _updateDrawLayer(
        id,
        (current) => current.copyWith(isLocked: !current.isLocked),
      );
      markEdit();
      return;
    }

    if (entryId.startsWith('shape:')) {
      final id = entryId.replaceFirst('shape:', '');
      final layer = _findShapeLayer(id);
      if (layer == null) {
        return;
      }
      _updateShapeLayer(
        id,
        (current) => current.copyWith(isLocked: !current.isLocked),
      );
      markEdit();
    }
  }

  void duplicateLayerFromEntry(String entryId) {
    if (entryId == 'surface_photo' && _mainSurfacePhoto != null) {
      _photoSeq += 1;
      final copyId = 'photo_$_photoSeq';
      final duplicate = StagePhotoLayer(
        id: copyId,
        imageUrl: _mainSurfacePhoto!.imageUrl,
        name: 'Photo $_photoSeq',
        size: mainSurfaceFitSize == Size.zero
            ? const Size(280, 360)
            : mainSurfaceFitSize,
        offset: _mainSurfaceOffset,
        scale: _mainSurfaceScale,
        rotation: _mainSurfaceRotation,
        adjustments: _mainSurfacePhoto!.adjustments,
        filter: _mainSurfacePhoto!.filter,
        removeBgState: _mainSurfacePhoto!.removeBgState,
        decoration: _mainSurfacePhoto!.decoration,
        visuals: _mainSurfacePhoto!.visuals,
        zIndex: _nextOverlayZIndex,
      );
      _extraPhotoLayers.add(duplicate);
      _selectedExtraPhotoLayerId = copyId;
      _selectedTextLayerId = null;
      _selectedElementLayerId = null;
      _selectedStickerLayerId = null;
      _selectedDrawLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      _selectedLayerQuickActionTool = null;
      markEdit();
      return;
    }
    if (entryId.startsWith('photo:')) {
      final id = entryId.replaceFirst('photo:', '');
      final layer = _findExtraPhotoLayer(id);
      if (layer == null) {
        return;
      }
      _photoSeq += 1;
      final copyId = 'photo_$_photoSeq';
      final duplicate = layer.copyWith(
        id: copyId,
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
        isVisible: true,
      );
      _extraPhotoLayers.add(duplicate);
      _selectedExtraPhotoLayerId = copyId;
      _selectedTextLayerId = null;
      _selectedElementLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      markEdit();
      return;
    }

    if (entryId.startsWith('text:')) {
      final id = entryId.replaceFirst('text:', '');
      final layer = _findTextLayer(id);
      if (layer == null) {
        return;
      }
      _textSeq += 1;
      final copyId = 'text_$_textSeq';
      final duplicate = layer.copyWith(
        id: copyId,
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
        isVisible: true,
      );
      _textLayers.add(duplicate);
      _selectedTextLayerId = copyId;
      _selectedExtraPhotoLayerId = null;
      _selectedElementLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      markEdit();
      return;
    }

    if (entryId.startsWith('element:')) {
      final id = entryId.replaceFirst('element:', '');
      final layer = _findElementLayer(id);
      if (layer == null) {
        return;
      }
      _elementSeq += 1;
      final copyId = 'element_$_elementSeq';
      final duplicate = layer.copyWith(
        id: copyId,
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
        isVisible: true,
      );
      _elementLayers.add(duplicate);
      _selectedElementLayerId = copyId;
      _selectedTextLayerId = null;
      _selectedExtraPhotoLayerId = null;
      _selectedStickerLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      markEdit();
      return;
    }

    if (entryId.startsWith('sticker:')) {
      final id = entryId.replaceFirst('sticker:', '');
      final layer = _findStickerLayer(id);
      if (layer == null) {
        return;
      }
      _stickerSeq += 1;
      final copyId = 'sticker_$_stickerSeq';
      final duplicate = layer.copyWith(
        id: copyId,
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
        isVisible: true,
      );
      _stickerLayers.add(duplicate);
      _selectedStickerLayerId = copyId;
      _selectedElementLayerId = null;
      _selectedTextLayerId = null;
      _selectedExtraPhotoLayerId = null;
      _selectedDrawLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      markEdit();
      return;
    }

    if (entryId.startsWith('draw:')) {
      final id = entryId.replaceFirst('draw:', '');
      final layer = _findDrawLayer(id);
      if (layer == null) {
        return;
      }
      _drawSeq += 1;
      final copyId = 'draw_$_drawSeq';
      final duplicate = layer.copyWith(
        id: copyId,
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
        isVisible: true,
      );
      _drawLayers.add(duplicate);
      _selectedDrawLayerId = copyId;
      _selectedStickerLayerId = null;
      _selectedElementLayerId = null;
      _selectedTextLayerId = null;
      _selectedExtraPhotoLayerId = null;
      _selectedShapeLayerId = null;
      _isMainSurfaceSelected = false;
      markEdit();
      return;
    }

    if (entryId.startsWith('shape:')) {
      final id = entryId.replaceFirst('shape:', '');
      final layer = _findShapeLayer(id);
      if (layer == null) {
        return;
      }
      _shapeSeq += 1;
      final copyId = 'shape_$_shapeSeq';
      final duplicate = layer.copyWith(
        id: copyId,
        name: '${layer.name} Copy',
        zIndex: _nextOverlayZIndex,
        isLocked: false,
        isVisible: true,
      );
      _shapeLayers.add(duplicate);
      _selectedShapeLayerId = copyId;
      _selectedDrawLayerId = null;
      _selectedStickerLayerId = null;
      _selectedElementLayerId = null;
      _selectedTextLayerId = null;
      _selectedExtraPhotoLayerId = null;
      _isMainSurfaceSelected = false;
      markEdit();
    }
  }

  void deleteLayerFromEntry(String entryId) {
    if (entryId == 'surface_photo') {
      _mainSurfacePhoto = null;
      _mainSurfaceImageSize = null;
      _mainSurfaceScale = _mainSurfaceMinScale;
      _mainSurfaceRotation = 0;
      _mainSurfaceOffset = Offset.zero;
      _mainSurfaceCropRatio = null;
      _mainSurfaceCropTurns = 0;
      _isMainSurfaceSelected = false;
      _normalizeSelectionState();
      markEdit();
      return;
    }
    if (entryId.startsWith('photo:')) {
      final id = entryId.replaceFirst('photo:', '');
      _extraPhotoLayers.removeWhere((layer) => layer.id == id);
      if (_selectedExtraPhotoLayerId == id) {
        _selectedExtraPhotoLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('text:')) {
      final id = entryId.replaceFirst('text:', '');
      _textLayers.removeWhere((layer) => layer.id == id);
      if (_selectedTextLayerId == id) {
        _selectedTextLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('element:')) {
      final id = entryId.replaceFirst('element:', '');
      _elementLayers.removeWhere((layer) => layer.id == id);
      if (_selectedElementLayerId == id) {
        _selectedElementLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('sticker:')) {
      final id = entryId.replaceFirst('sticker:', '');
      _stickerLayers.removeWhere((layer) => layer.id == id);
      if (_selectedStickerLayerId == id) {
        _selectedStickerLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('draw:')) {
      final id = entryId.replaceFirst('draw:', '');
      _drawLayers.removeWhere((layer) => layer.id == id);
      if (_selectedDrawLayerId == id) {
        _selectedDrawLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
      return;
    }

    if (entryId.startsWith('shape:')) {
      final id = entryId.replaceFirst('shape:', '');
      _shapeLayers.removeWhere((layer) => layer.id == id);
      if (_selectedShapeLayerId == id) {
        _selectedShapeLayerId = null;
      }
      _normalizeSelectionState();
      markEdit();
    }
  }

  void renameLayerFromEntry(String entryId, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (entryId.startsWith('photo:')) {
      final id = entryId.replaceFirst('photo:', '');
      _updateExtraPhotoLayer(id, (current) => current.copyWith(name: trimmed));
      markEdit();
      return;
    }

    if (entryId.startsWith('text:')) {
      final id = entryId.replaceFirst('text:', '');
      _updateTextLayer(id, (current) => current.copyWith(name: trimmed));
      markEdit();
      return;
    }

    if (entryId.startsWith('element:')) {
      final id = entryId.replaceFirst('element:', '');
      _updateElementLayer(id, (current) => current.copyWith(name: trimmed));
      markEdit();
      return;
    }

    if (entryId.startsWith('sticker:')) {
      final id = entryId.replaceFirst('sticker:', '');
      _updateStickerLayer(id, (current) => current.copyWith(name: trimmed));
      markEdit();
      return;
    }

    if (entryId.startsWith('draw:')) {
      final id = entryId.replaceFirst('draw:', '');
      _updateDrawLayer(id, (current) => current.copyWith(name: trimmed));
      markEdit();
      return;
    }

    if (entryId.startsWith('shape:')) {
      final id = entryId.replaceFirst('shape:', '');
      _updateShapeLayer(id, (current) => current.copyWith(name: trimmed));
      markEdit();
    }
  }

  void bringLayerToFrontFromEntry(String entryId) {
    final frontZ = _nextOverlayZIndex;
    if (entryId.startsWith('photo:')) {
      final id = entryId.replaceFirst('photo:', '');
      _updateExtraPhotoLayer(id, (current) => current.copyWith(zIndex: frontZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('text:')) {
      final id = entryId.replaceFirst('text:', '');
      _updateTextLayer(id, (current) => current.copyWith(zIndex: frontZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('element:')) {
      final id = entryId.replaceFirst('element:', '');
      _updateElementLayer(id, (current) => current.copyWith(zIndex: frontZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('sticker:')) {
      final id = entryId.replaceFirst('sticker:', '');
      _updateStickerLayer(id, (current) => current.copyWith(zIndex: frontZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('draw:')) {
      final id = entryId.replaceFirst('draw:', '');
      _updateDrawLayer(id, (current) => current.copyWith(zIndex: frontZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('shape:')) {
      final id = entryId.replaceFirst('shape:', '');
      _updateShapeLayer(id, (current) => current.copyWith(zIndex: frontZ));
      markEdit();
    }
  }

  void sendLayerToBackFromEntry(String entryId) {
    final backZ = _overlayMinZIndex - 1;
    if (entryId.startsWith('photo:')) {
      final id = entryId.replaceFirst('photo:', '');
      _updateExtraPhotoLayer(id, (current) => current.copyWith(zIndex: backZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('text:')) {
      final id = entryId.replaceFirst('text:', '');
      _updateTextLayer(id, (current) => current.copyWith(zIndex: backZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('element:')) {
      final id = entryId.replaceFirst('element:', '');
      _updateElementLayer(id, (current) => current.copyWith(zIndex: backZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('sticker:')) {
      final id = entryId.replaceFirst('sticker:', '');
      _updateStickerLayer(id, (current) => current.copyWith(zIndex: backZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('draw:')) {
      final id = entryId.replaceFirst('draw:', '');
      _updateDrawLayer(id, (current) => current.copyWith(zIndex: backZ));
      markEdit();
      return;
    }
    if (entryId.startsWith('shape:')) {
      final id = entryId.replaceFirst('shape:', '');
      _updateShapeLayer(id, (current) => current.copyWith(zIndex: backZ));
      markEdit();
    }
  }

  void reorderOverlayLayersByPanelOrder(
    List<String> orderedEntryIdsTopToBottom,
  ) {
    var z = orderedEntryIdsTopToBottom.length;
    for (final entryId in orderedEntryIdsTopToBottom) {
      if (entryId.startsWith('photo:')) {
        final id = entryId.replaceFirst('photo:', '');
        _updateExtraPhotoLayer(id, (current) => current.copyWith(zIndex: z));
      } else if (entryId.startsWith('text:')) {
        final id = entryId.replaceFirst('text:', '');
        _updateTextLayer(id, (current) => current.copyWith(zIndex: z));
      } else if (entryId.startsWith('element:')) {
        final id = entryId.replaceFirst('element:', '');
        _updateElementLayer(id, (current) => current.copyWith(zIndex: z));
      } else if (entryId.startsWith('sticker:')) {
        final id = entryId.replaceFirst('sticker:', '');
        _updateStickerLayer(id, (current) => current.copyWith(zIndex: z));
      } else if (entryId.startsWith('draw:')) {
        final id = entryId.replaceFirst('draw:', '');
        _updateDrawLayer(id, (current) => current.copyWith(zIndex: z));
      } else if (entryId.startsWith('shape:')) {
        final id = entryId.replaceFirst('shape:', '');
        _updateShapeLayer(id, (current) => current.copyWith(zIndex: z));
      }
      z -= 1;
    }
    markEdit();
  }

  int get _nextOverlayZIndex {
    final photoMax = _extraPhotoLayers.isEmpty
        ? -1
        : _extraPhotoLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.max(a, b));
    final textMax = _textLayers.isEmpty
        ? -1
        : _textLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.max(a, b));
    final elementMax = _elementLayers.isEmpty
        ? -1
        : _elementLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.max(a, b));
    final stickerMax = _stickerLayers.isEmpty
        ? -1
        : _stickerLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.max(a, b));
    final drawMax = _drawLayers.isEmpty
        ? -1
        : _drawLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.max(a, b));
    final shapeMax = _shapeLayers.isEmpty
        ? -1
        : _shapeLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.max(a, b));
    return math.max(
          math.max(
            math.max(photoMax, textMax),
            math.max(elementMax, stickerMax),
          ),
          math.max(drawMax, shapeMax),
        ) +
        1;
  }

  int get _overlayMinZIndex {
    final photoMin = _extraPhotoLayers.isEmpty
        ? 0
        : _extraPhotoLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.min(a, b));
    final textMin = _textLayers.isEmpty
        ? 0
        : _textLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.min(a, b));
    final elementMin = _elementLayers.isEmpty
        ? 0
        : _elementLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.min(a, b));
    final stickerMin = _stickerLayers.isEmpty
        ? 0
        : _stickerLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.min(a, b));
    final drawMin = _drawLayers.isEmpty
        ? 0
        : _drawLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.min(a, b));
    final shapeMin = _shapeLayers.isEmpty
        ? 0
        : _shapeLayers
              .map((item) => item.zIndex)
              .reduce((a, b) => math.min(a, b));
    return math.min(
      math.min(
        math.min(math.min(photoMin, textMin), math.min(elementMin, stickerMin)),
        drawMin,
      ),
      shapeMin,
    );
  }

  Offset _clampExtraLayerOffset({
    required StagePhotoLayer layer,
    required Offset offset,
    required double scale,
  }) {
    if (_stageSize == Size.zero) {
      return offset;
    }

    final width = layer.size.width * scale;
    final height = layer.size.height * scale;

    final maxX = ((_stageSize.width + width) / 2) - 44;
    final maxY = ((_stageSize.height + height) / 2) - 44;

    return Offset(offset.dx.clamp(-maxX, maxX), offset.dy.clamp(-maxY, maxY));
  }

  Offset _clampElementOffset({
    required StageElementLayer layer,
    required Offset offset,
    required double scale,
  }) {
    if (_stageSize == Size.zero) {
      return offset;
    }

    final width = layer.size.width * scale;
    final height = layer.size.height * scale;
    final maxX = ((_stageSize.width + width) / 2) - 36;
    final maxY = ((_stageSize.height + height) / 2) - 36;
    return Offset(offset.dx.clamp(-maxX, maxX), offset.dy.clamp(-maxY, maxY));
  }

  Offset _clampStickerOffset({
    required StageStickerLayer layer,
    required Offset offset,
    required double scale,
  }) {
    if (_stageSize == Size.zero) {
      return offset;
    }

    final width = layer.size.width * scale;
    final height = layer.size.height * scale;
    final maxX = ((_stageSize.width + width) / 2) - 32;
    final maxY = ((_stageSize.height + height) / 2) - 32;
    return Offset(offset.dx.clamp(-maxX, maxX), offset.dy.clamp(-maxY, maxY));
  }

  Offset _clampShapeOffset({
    required StageShapeLayer layer,
    required Offset offset,
    required double scale,
  }) {
    if (_stageSize == Size.zero) {
      return offset;
    }
    final width = layer.size.width * scale;
    final height = layer.size.height * scale;
    final maxX = ((_stageSize.width + width) / 2) - 36;
    final maxY = ((_stageSize.height + height) / 2) - 36;
    return Offset(offset.dx.clamp(-maxX, maxX), offset.dy.clamp(-maxY, maxY));
  }

  void setTextLayerInteracting(bool value) {
    if (_isTextLayerInteracting == value) {
      return;
    }
    _isTextLayerInteracting = value;
  }

  void beginTextLayerMove(String layerId) {
    final layer = _findTextLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }
    _activeTextMoveLayerId = layerId;
    _textMoveStartOffset = layer.offset;
    _isTextLayerInteracting = true;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
  }

  void onTextScaleStart(String layerId, ScaleStartDetails details) {
    final layer = _findTextLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }
    selectTextLayer(layerId);
    _activeTextMoveLayerId = layerId;
    _textMoveStartOffset = layer.offset;
    _textGestureStartScale = layer.scale;
    _textGestureStartRotation = layer.rotation;
    _textGestureStartFocal = details.focalPoint;
    _isTextLayerInteracting = true;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
  }

  void addTextLayer() {
    _textSeq += 1;
    final layer = EditorTextLayer(
      id: 'text_$_textSeq',
      name: 'Text $_textSeq',
      text: 'కొత్త టెక్స్ట్',
      offset: Offset.zero,
      rotation: 0,
      scale: 1,
      zIndex: _nextOverlayZIndex,
      style: kDefaultEditorTextStyle,
    );
    _textLayers.add(layer);
    _selectedTextLayerId = layer.id;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _selectedDrawLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.text);
    markEdit();
  }

  void requestFullScreenTextEditor(String layerId) {
    final layer = _findTextLayer(layerId);
    if (layer == null) {
      return;
    }
    _selectedTextLayerId = layerId;
    _selectedExtraPhotoLayerId = null;
    _selectedElementLayerId = null;
    _selectedStickerLayerId = null;
    _isMainSurfaceSelected = false;
    _activeTool = _toolById(EditorToolId.text);
    _pendingFullScreenTextEditorLayerId = layerId;
    notifyListeners();
  }

  String? consumePendingFullScreenTextEditorLayerId() {
    final layerId = _pendingFullScreenTextEditorLayerId;
    _pendingFullScreenTextEditorLayerId = null;
    return layerId;
  }

  void updateTextLayerContent(String layerId, String content) {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return;
    }
    _updateTextLayer(layerId, (layer) => layer.copyWith(text: normalized));
    markEdit();
  }

  void updateSelectedTextStyle(EditorTextStyleConfig style) {
    final layer = selectedTextLayer;
    if (layer == null) {
      return;
    }
    _updateTextLayer(layer.id, (current) => current.copyWith(style: style));
    markEdit();
  }

  void moveTextLayerBy(String layerId, Offset delta) {
    final layer = _findTextLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }
    if (_activeTextMoveLayerId != null && _activeTextMoveLayerId != layerId) {
      return;
    }
    final base = layer.offset;
    final next = Offset(base.dx + delta.dx, base.dy + delta.dy);
    final bounded = _clampTextOffset(next);
    if (_offsetNearlyEqual(base, bounded)) {
      return;
    }
    _updateTextLayer(layerId, (current) => current.copyWith(offset: bounded));
    _showVerticalGuide = bounded.dx.abs() <= _guideCenterThreshold;
    _showHorizontalGuide = bounded.dy.abs() <= _guideCenterThreshold;
    notifyListeners();
  }

  void onTextScaleUpdate(String layerId, ScaleUpdateDetails details) {
    if (_activeTextMoveLayerId != layerId) {
      return;
    }
    final layer = _findTextLayer(layerId);
    if (layer == null || layer.isLocked || !layer.isVisible) {
      return;
    }

    final rawScale = (_textGestureStartScale * details.scale).clamp(
      _overlayMinScale,
      _overlayMaxScale,
    );
    final rawRotation = _textGestureStartRotation + details.rotation;
    final snappedRotation = _softSnapRotation(rawRotation);
    final dragDelta = details.focalPoint - _textGestureStartFocal;
    final rawOffset = _textMoveStartOffset + dragDelta;
    final clampedOffset = _clampTextOffset(rawOffset);

    _updateTextLayer(
      layerId,
      (current) => current.copyWith(
        scale: rawScale,
        rotation: snappedRotation,
        offset: clampedOffset,
      ),
    );
    _showVerticalGuide = clampedOffset.dx.abs() <= _guideCenterThreshold;
    _showHorizontalGuide = clampedOffset.dy.abs() <= _guideCenterThreshold;

    if (_nearlyEqual(layer.scale, rawScale) &&
        _nearlyEqual(layer.rotation, snappedRotation) &&
        _offsetNearlyEqual(layer.offset, clampedOffset)) {
      return;
    }
    notifyListeners();
  }

  void completeTextLayerMove([String? layerId]) {
    final targetId = layerId ?? _activeTextMoveLayerId ?? _selectedTextLayerId;
    if (targetId == null) {
      _isTextLayerInteracting = false;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      return;
    }
    final layer = _findTextLayer(targetId);
    if (layer == null) {
      _activeTextMoveLayerId = null;
      _isTextLayerInteracting = false;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      notifyListeners();
      return;
    }
    final finalOffset = _snapOffsetToGuides(_clampTextOffset(layer.offset));
    final hasChanged = !_offsetNearlyEqual(_textMoveStartOffset, finalOffset);
    if (!_offsetNearlyEqual(layer.offset, finalOffset)) {
      _updateTextLayer(
        targetId,
        (current) => current.copyWith(offset: finalOffset),
      );
    }
    _activeTextMoveLayerId = null;
    _isTextLayerInteracting = false;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
    if (hasChanged) {
      markEdit();
    } else {
      notifyListeners();
    }
  }

  void completeTextLayerTransform([String? layerId]) {
    final targetId = layerId ?? _activeTextMoveLayerId ?? _selectedTextLayerId;
    if (targetId == null) {
      _activeTextMoveLayerId = null;
      _isTextLayerInteracting = false;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      return;
    }

    final layer = _findTextLayer(targetId);
    if (layer == null) {
      _activeTextMoveLayerId = null;
      _isTextLayerInteracting = false;
      _showVerticalGuide = false;
      _showHorizontalGuide = false;
      notifyListeners();
      return;
    }

    final finalRotation = _hardSnapRotation(layer.rotation);
    final finalOffset = _snapOffsetToGuides(_clampTextOffset(layer.offset));
    final hasChanged = _hasTransformChanged(
      startScale: _textGestureStartScale,
      endScale: layer.scale,
      startRotation: _textGestureStartRotation,
      endRotation: finalRotation,
      startOffset: _textMoveStartOffset,
      endOffset: finalOffset,
    );

    if (!_nearlyEqual(layer.rotation, finalRotation, epsilon: 0.002) ||
        !_offsetNearlyEqual(layer.offset, finalOffset)) {
      _updateTextLayer(
        targetId,
        (current) =>
            current.copyWith(rotation: finalRotation, offset: finalOffset),
      );
    }

    _activeTextMoveLayerId = null;
    _isTextLayerInteracting = false;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;

    if (hasChanged) {
      markEdit();
    } else {
      notifyListeners();
    }
  }

  void cancelTextLayerMove([String? layerId]) {
    final targetId = layerId ?? _activeTextMoveLayerId;
    if (targetId != null) {
      final layer = _findTextLayer(targetId);
      if (layer != null &&
          !_offsetNearlyEqual(layer.offset, _textMoveStartOffset)) {
        _updateTextLayer(
          targetId,
          (current) => current.copyWith(offset: _textMoveStartOffset),
        );
      }
    }
    _activeTextMoveLayerId = null;
    _isTextLayerInteracting = false;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
    notifyListeners();
  }

  void duplicateSelectedTextLayer() {
    final layer = selectedTextLayer;
    if (layer == null) {
      return;
    }
    duplicateLayerFromEntry('text:${layer.id}');
  }

  void toggleSelectedTextLock() {
    final layer = selectedTextLayer;
    if (layer == null) {
      return;
    }
    toggleLockForLayerEntry('text:${layer.id}');
  }

  void flipSelectedText() {
    final layer = selectedTextLayer;
    if (layer == null || layer.isLocked) {
      return;
    }
    _updateTextLayer(
      layer.id,
      (current) => current.copyWith(isFlipped: !current.isFlipped),
    );
    markEdit();
  }

  void rotateSelectedTextByQuarterTurn() {
    final layer = selectedTextLayer;
    if (layer == null || layer.isLocked) {
      return;
    }
    _updateTextLayer(
      layer.id,
      (current) => current.copyWith(rotation: current.rotation + (math.pi / 2)),
    );
    markEdit();
  }

  void bringSelectedTextToFront() {
    final layer = selectedTextLayer;
    if (layer == null) {
      return;
    }
    bringLayerToFrontFromEntry('text:${layer.id}');
  }

  void sendSelectedTextToBack() {
    final layer = selectedTextLayer;
    if (layer == null) {
      return;
    }
    sendLayerToBackFromEntry('text:${layer.id}');
  }

  void onScaleStart(ScaleStartDetails details) {
    if (_mainSurfacePhoto == null ||
        (_mainSurfacePhoto?.isLocked ?? false) ||
        _isTextLayerInteracting ||
        _isExtraPhotoLayerInteracting ||
        _isElementLayerInteracting ||
        _drawSessionActive ||
        _removeBgSessionActive ||
        _isStickerLayerInteracting ||
        _isShapeLayerInteracting) {
      return;
    }
    _gestureStartScale = _mainSurfaceScale;
    _gestureStartRotation = _mainSurfaceRotation;
    _gestureStartFocal = details.focalPoint;
    _gestureStartOffset = _mainSurfaceOffset;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_mainSurfacePhoto == null ||
        (_mainSurfacePhoto?.isLocked ?? false) ||
        _isTextLayerInteracting ||
        _isExtraPhotoLayerInteracting ||
        _isElementLayerInteracting ||
        _removeBgSessionActive ||
        _isStickerLayerInteracting ||
        _isShapeLayerInteracting) {
      return;
    }

    final rawScale = (_gestureStartScale * details.scale).clamp(
      _mainSurfaceMinScale,
      _mainSurfaceMaxScale,
    );
    final rawRotation = _gestureStartRotation + details.rotation;
    final snappedRotation = _softSnapRotation(rawRotation);

    final dragDelta = details.focalPoint - _gestureStartFocal;
    final rawOffset = _gestureStartOffset + dragDelta;
    final clampedOffset = _clampOffset(rawOffset, rawScale);

    _mainSurfaceScale = rawScale;
    _mainSurfaceRotation = snappedRotation;
    _mainSurfaceOffset = clampedOffset;

    _showVerticalGuide = _mainSurfaceOffset.dx.abs() <= _guideCenterThreshold;
    _showHorizontalGuide = _mainSurfaceOffset.dy.abs() <= _guideCenterThreshold;

    if (_nearlyEqual(_gestureStartScale, rawScale) &&
        _nearlyEqual(_gestureStartRotation, snappedRotation) &&
        _offsetNearlyEqual(_gestureStartOffset, clampedOffset)) {
      return;
    }
    notifyListeners();
  }

  void onScaleEnd(ScaleEndDetails details) {
    if (_mainSurfacePhoto == null ||
        _isTextLayerInteracting ||
        _isExtraPhotoLayerInteracting ||
        _isElementLayerInteracting ||
        _removeBgSessionActive ||
        _isStickerLayerInteracting ||
        _isShapeLayerInteracting) {
      return;
    }

    final finalScale = _mainSurfaceScale.clamp(
      _mainSurfaceMinScale,
      _mainSurfaceMaxScale,
    );
    final finalRotation = _hardSnapRotation(_mainSurfaceRotation);
    final finalOffset = _snapOffsetToGuides(
      _clampOffset(_mainSurfaceOffset, finalScale),
    );

    _mainSurfaceScale = finalScale;
    _mainSurfaceRotation = finalRotation;
    _mainSurfaceOffset = finalOffset;
    _showVerticalGuide = false;
    _showHorizontalGuide = false;

    final hasChanged = _hasTransformChanged(
      startScale: _gestureStartScale,
      endScale: finalScale,
      startRotation: _gestureStartRotation,
      endRotation: finalRotation,
      startOffset: _gestureStartOffset,
      endOffset: finalOffset,
    );
    if (hasChanged) {
      markEdit();
    } else {
      notifyListeners();
    }
  }

  void resetMainSurfaceTransform() {
    if (_mainSurfacePhoto == null) {
      return;
    }
    _mainSurfaceScale = _mainSurfaceMinScale;
    _mainSurfaceRotation = 0;
    _mainSurfaceOffset = Offset.zero;
    _showHorizontalGuide = false;
    _showVerticalGuide = false;
    notifyListeners();
  }

  double _softSnapRotation(double angle) {
    for (final target in _snapTargets) {
      final delta = _angleDistance(angle, target);
      if (delta < _rotationSnapThresholdRad) {
        return angle + (target - angle) * 0.28;
      }
    }
    return angle;
  }

  double _hardSnapRotation(double angle) {
    for (final target in _snapTargets) {
      final delta = _angleDistance(angle, target);
      if (delta < _rotationHardSnapThresholdRad) {
        return target;
      }
    }
    return angle;
  }

  Offset _clampOffset(Offset offset, double scale) {
    final fitSize = mainSurfaceFitSize;
    if (fitSize == Size.zero || _stageSize == Size.zero) {
      return offset;
    }

    final displayedWidth = fitSize.width * scale;
    final displayedHeight = fitSize.height * scale;

    final maxX = math.max(
      0.0,
      ((_stageSize.width + displayedWidth) / 2) - _minVisiblePx,
    );
    final maxY = math.max(
      0.0,
      ((_stageSize.height + displayedHeight) / 2) - _minVisiblePx,
    );

    return Offset(offset.dx.clamp(-maxX, maxX), offset.dy.clamp(-maxY, maxY));
  }

  Offset _clampTextOffset(Offset offset) {
    if (_stageSize == Size.zero) {
      return offset;
    }
    final maxX = (_stageSize.width / 2) - 40;
    final maxY = (_stageSize.height / 2) - 24;
    return Offset(offset.dx.clamp(-maxX, maxX), offset.dy.clamp(-maxY, maxY));
  }

  EditorToolDefinition _toolById(EditorToolId id) {
    return kEditorTools.firstWhere((tool) => tool.id == id);
  }

  StagePhotoLayer? _findExtraPhotoLayer(String layerId) {
    for (final layer in _extraPhotoLayers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  void _updateExtraPhotoLayer(
    String layerId,
    StagePhotoLayer Function(StagePhotoLayer current) updater,
  ) {
    final index = _extraPhotoLayers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) {
      return;
    }
    _extraPhotoLayers[index] = updater(_extraPhotoLayers[index]);
  }

  StageElementLayer? _findElementLayer(String layerId) {
    for (final layer in _elementLayers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  void _updateElementLayer(
    String layerId,
    StageElementLayer Function(StageElementLayer current) updater,
  ) {
    final index = _elementLayers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) {
      return;
    }
    _elementLayers[index] = updater(_elementLayers[index]);
  }

  StageStickerLayer? _findStickerLayer(String layerId) {
    for (final layer in _stickerLayers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  void _updateStickerLayer(
    String layerId,
    StageStickerLayer Function(StageStickerLayer current) updater,
  ) {
    final index = _stickerLayers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) {
      return;
    }
    _stickerLayers[index] = updater(_stickerLayers[index]);
  }

  StageDrawLayer? _findDrawLayer(String layerId) {
    for (final layer in _drawLayers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  void _updateDrawLayer(
    String layerId,
    StageDrawLayer Function(StageDrawLayer current) updater,
  ) {
    final index = _drawLayers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) {
      return;
    }
    _drawLayers[index] = updater(_drawLayers[index]);
  }

  StageShapeLayer? _findShapeLayer(String layerId) {
    for (final layer in _shapeLayers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  void _updateShapeLayer(
    String layerId,
    StageShapeLayer Function(StageShapeLayer current) updater,
  ) {
    final index = _shapeLayers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) {
      return;
    }
    _shapeLayers[index] = updater(_shapeLayers[index]);
  }

  EditorTextLayer? _findTextLayer(String layerId) {
    for (final layer in _textLayers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  void _updateTextLayer(
    String layerId,
    EditorTextLayer Function(EditorTextLayer current) updater,
  ) {
    final index = _textLayers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) {
      return;
    }
    _textLayers[index] = updater(_textLayers[index]);
  }

  _EditorHistoryEntry _captureHistoryEntry() {
    final snapshot = _EditorHistorySnapshot(
      stageBackground: _cloneStageBackground(_stageBackground),
      recentBackgroundColors: List<Color>.from(_recentBackgroundColors),
      backgroundSampleSeq: _backgroundSampleSeq,
      mainSurfacePhoto: _mainSurfacePhoto == null
          ? null
          : _cloneSurfacePhoto(_mainSurfacePhoto!),
      mainSurfaceImageSize: _mainSurfaceImageSize == null
          ? null
          : Size(_mainSurfaceImageSize!.width, _mainSurfaceImageSize!.height),
      mainSurfaceScale: _mainSurfaceScale,
      mainSurfaceRotation: _mainSurfaceRotation,
      mainSurfaceOffset: Offset(_mainSurfaceOffset.dx, _mainSurfaceOffset.dy),
      mainSurfaceCropRatio: _mainSurfaceCropRatio,
      mainSurfaceCropTurns: _mainSurfaceCropTurns,
      extraPhotoLayers: _extraPhotoLayers
          .map(_clonePhotoLayer)
          .toList(growable: false),
      elementLayers: _elementLayers
          .map(_cloneElementLayer)
          .toList(growable: false),
      stickerLayers: _stickerLayers
          .map(_cloneStickerLayer)
          .toList(growable: false),
      drawLayers: _drawLayers.map(_cloneDrawLayer).toList(growable: false),
      shapeLayers: _shapeLayers.map(_cloneShapeLayer).toList(growable: false),
      textLayers: _textLayers.map(_cloneTextLayer).toList(growable: false),
      photoSeq: _photoSeq,
      elementSeq: _elementSeq,
      stickerSeq: _stickerSeq,
      drawSeq: _drawSeq,
      shapeSeq: _shapeSeq,
      drawStrokeSeq: _drawStrokeSeq,
      textSeq: _textSeq,
      selectedExtraPhotoLayerId: _selectedExtraPhotoLayerId,
      selectedTextLayerId: _selectedTextLayerId,
      selectedElementLayerId: _selectedElementLayerId,
      selectedStickerLayerId: _selectedStickerLayerId,
      selectedDrawLayerId: _selectedDrawLayerId,
      selectedShapeLayerId: _selectedShapeLayerId,
      isMainSurfaceSelected: _isMainSurfaceSelected,
      showVerticalGuide: _showVerticalGuide,
      showHorizontalGuide: _showHorizontalGuide,
    );

    final signature = jsonEncode(_serializeHistorySnapshot(snapshot));
    return _EditorHistoryEntry(snapshot: snapshot, signature: signature);
  }

  void _restoreFromHistory(_EditorHistoryEntry entry) {
    final snapshot = entry.snapshot;
    _stageBackground = _cloneStageBackground(snapshot.stageBackground);
    _recentBackgroundColors
      ..clear()
      ..addAll(snapshot.recentBackgroundColors);
    _backgroundSampleSeq = snapshot.backgroundSampleSeq;
    _mainSurfacePhoto = snapshot.mainSurfacePhoto == null
        ? null
        : _cloneSurfacePhoto(snapshot.mainSurfacePhoto!);
    _mainSurfaceImageSize = snapshot.mainSurfaceImageSize == null
        ? null
        : Size(
            snapshot.mainSurfaceImageSize!.width,
            snapshot.mainSurfaceImageSize!.height,
          );
    _mainSurfaceScale = snapshot.mainSurfaceScale;
    _mainSurfaceRotation = snapshot.mainSurfaceRotation;
    _mainSurfaceOffset = Offset(
      snapshot.mainSurfaceOffset.dx,
      snapshot.mainSurfaceOffset.dy,
    );
    _mainSurfaceCropRatio = snapshot.mainSurfaceCropRatio;
    _mainSurfaceCropTurns = snapshot.mainSurfaceCropTurns;

    _extraPhotoLayers
      ..clear()
      ..addAll(snapshot.extraPhotoLayers.map(_clonePhotoLayer));
    _elementLayers
      ..clear()
      ..addAll(snapshot.elementLayers.map(_cloneElementLayer));
    _stickerLayers
      ..clear()
      ..addAll(snapshot.stickerLayers.map(_cloneStickerLayer));
    _drawLayers
      ..clear()
      ..addAll(snapshot.drawLayers.map(_cloneDrawLayer));
    _shapeLayers
      ..clear()
      ..addAll(snapshot.shapeLayers.map(_cloneShapeLayer));
    _textLayers
      ..clear()
      ..addAll(snapshot.textLayers.map(_cloneTextLayer));

    _photoSeq = snapshot.photoSeq;
    _elementSeq = snapshot.elementSeq;
    _stickerSeq = snapshot.stickerSeq;
    _drawSeq = snapshot.drawSeq;
    _shapeSeq = snapshot.shapeSeq;
    _drawStrokeSeq = snapshot.drawStrokeSeq;
    _textSeq = snapshot.textSeq;

    _selectedExtraPhotoLayerId = snapshot.selectedExtraPhotoLayerId;
    _selectedTextLayerId = snapshot.selectedTextLayerId;
    _selectedElementLayerId = snapshot.selectedElementLayerId;
    _selectedStickerLayerId = snapshot.selectedStickerLayerId;
    _selectedDrawLayerId = snapshot.selectedDrawLayerId;
    _selectedShapeLayerId = snapshot.selectedShapeLayerId;
    _isMainSurfaceSelected = snapshot.isMainSurfaceSelected;
    _showVerticalGuide = snapshot.showVerticalGuide;
    _showHorizontalGuide = snapshot.showHorizontalGuide;

    _activeExtraPhotoGestureLayerId = null;
    _activeElementGestureLayerId = null;
    _activeStickerGestureLayerId = null;
    _activeShapeGestureLayerId = null;
    _selectedLayerQuickActionTool = null;

    _normalizeSelectionState();
    _resetCropSessionState();
    _resetAdjustSessionState();
    _resetFilterSessionState();
    _resetBorderFrameSessionState();
    _resetRemoveBgSessionState();
    _resetDrawSessionState();
  }

  Map<String, Object?> _serializeHistorySnapshot(_EditorHistorySnapshot s) {
    return <String, Object?>{
      'stageBackground': _serializeStageBackground(s.stageBackground),
      'recentBackgroundColors': s.recentBackgroundColors
          .map((color) => color.toARGB32())
          .toList(growable: false),
      'backgroundSampleSeq': s.backgroundSampleSeq,
      'mainSurfacePhoto': s.mainSurfacePhoto == null
          ? null
          : <String, Object?>{
              'imageUrl': s.mainSurfacePhoto!.imageUrl,
              'adjustments': _serializeAdjustments(
                s.mainSurfacePhoto!.adjustments,
              ),
              'filter': _serializeFilter(s.mainSurfacePhoto!.filter),
              'removeBgState': _serializeRemoveBg(
                s.mainSurfacePhoto!.removeBgState,
              ),
              'decoration': _serializeDecoration(
                s.mainSurfacePhoto!.decoration,
              ),
              'visuals': _serializeVisuals(s.mainSurfacePhoto!.visuals),
              'isLocked': s.mainSurfacePhoto!.isLocked,
            },
      'mainSurfaceImageSize': s.mainSurfaceImageSize == null
          ? null
          : _serializeSize(s.mainSurfaceImageSize!),
      'mainSurfaceScale': s.mainSurfaceScale,
      'mainSurfaceRotation': s.mainSurfaceRotation,
      'mainSurfaceOffset': _serializeOffset(s.mainSurfaceOffset),
      'mainSurfaceCropRatio': s.mainSurfaceCropRatio,
      'mainSurfaceCropTurns': s.mainSurfaceCropTurns,
      'extraPhotoLayers': s.extraPhotoLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'imageUrl': layer.imageUrl,
              'name': layer.name,
              'size': _serializeSize(layer.size),
              'offset': _serializeOffset(layer.offset),
              'scale': layer.scale,
              'rotation': layer.rotation,
              'cropRatio': layer.cropRatio,
              'cropTurns': layer.cropTurns,
              'adjustments': _serializeAdjustments(layer.adjustments),
              'filter': _serializeFilter(layer.filter),
              'removeBgState': _serializeRemoveBg(layer.removeBgState),
              'decoration': _serializeDecoration(layer.decoration),
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'elementLayers': s.elementLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'assetId': layer.assetId,
              'assetUrl': layer.assetUrl,
              'name': layer.name,
              'category': layer.category,
              'size': _serializeSize(layer.size),
              'offset': _serializeOffset(layer.offset),
              'scale': layer.scale,
              'rotation': layer.rotation,
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'stickerLayers': s.stickerLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'stickerId': layer.stickerId,
              'stickerUrl': layer.stickerUrl,
              'name': layer.name,
              'category': layer.category,
              'size': _serializeSize(layer.size),
              'offset': _serializeOffset(layer.offset),
              'scale': layer.scale,
              'rotation': layer.rotation,
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'drawLayers': s.drawLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'name': layer.name,
              'strokes': layer.strokes
                  .map((stroke) => _serializeDrawStroke(stroke))
                  .toList(growable: false),
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'shapeLayers': s.shapeLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'kind': layer.kind.name,
              'name': layer.name,
              'size': _serializeSize(layer.size),
              'offset': _serializeOffset(layer.offset),
              'scale': layer.scale,
              'rotation': layer.rotation,
              'fillColor': layer.fillColor.toARGB32(),
              'useGradientFill': layer.useGradientFill,
              'gradientColors': layer.gradientColors
                  .map((color) => color.toARGB32())
                  .toList(growable: false),
              'strokeColor': layer.strokeColor.toARGB32(),
              'strokeWidth': layer.strokeWidth,
              'opacity': layer.opacity,
              'cornerRadius': layer.cornerRadius,
              'visuals': _serializeVisuals(layer.visuals),
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isVisible': layer.isVisible,
            },
          )
          .toList(growable: false),
      'textLayers': s.textLayers
          .map(
            (layer) => <String, Object?>{
              'id': layer.id,
              'name': layer.name,
              'text': layer.text,
              'offset': _serializeOffset(layer.offset),
              'rotation': layer.rotation,
              'scale': layer.scale,
              'zIndex': layer.zIndex,
              'isLocked': layer.isLocked,
              'isFlipped': layer.isFlipped,
              'isFlippedVertical': layer.isFlippedVertical,
              'blendMode': layer.blendMode.name,
              'isVisible': layer.isVisible,
              'style': _serializeTextStyle(layer.style),
            },
          )
          .toList(growable: false),
      'seq': <String, int>{
        'photo': s.photoSeq,
        'element': s.elementSeq,
        'sticker': s.stickerSeq,
        'draw': s.drawSeq,
        'shape': s.shapeSeq,
        'drawStroke': s.drawStrokeSeq,
        'text': s.textSeq,
      },
      'selection': <String, Object?>{
        'main': s.isMainSurfaceSelected,
        'photo': s.selectedExtraPhotoLayerId,
        'text': s.selectedTextLayerId,
        'element': s.selectedElementLayerId,
        'sticker': s.selectedStickerLayerId,
        'draw': s.selectedDrawLayerId,
        'shape': s.selectedShapeLayerId,
      },
      'guides': <String, bool>{
        'vertical': s.showVerticalGuide,
        'horizontal': s.showHorizontalGuide,
      },
    };
  }

  StageBackgroundConfig _cloneStageBackground(StageBackgroundConfig config) {
    return config.copyWith(
      gradientColors: config.gradientColors == null
          ? null
          : List<Color>.from(config.gradientColors!),
      posterDecoration: _cloneDecoration(config.posterDecoration),
    );
  }

  StageSurfacePhoto _cloneSurfacePhoto(StageSurfacePhoto surface) {
    return surface.copyWith(
      adjustments: _cloneAdjustments(surface.adjustments),
      filter: _cloneFilter(surface.filter),
      removeBgState: _cloneRemoveBgState(surface.removeBgState),
      decoration: _cloneDecoration(surface.decoration),
      visuals: _cloneVisuals(surface.visuals),
    );
  }

  StagePhotoLayer _clonePhotoLayer(StagePhotoLayer layer) {
    return layer.copyWith(
      size: Size(layer.size.width, layer.size.height),
      offset: Offset(layer.offset.dx, layer.offset.dy),
      adjustments: _cloneAdjustments(layer.adjustments),
      filter: _cloneFilter(layer.filter),
      removeBgState: _cloneRemoveBgState(layer.removeBgState),
      decoration: _cloneDecoration(layer.decoration),
      visuals: _cloneVisuals(layer.visuals),
    );
  }

  StageElementLayer _cloneElementLayer(StageElementLayer layer) {
    return layer.copyWith(
      size: Size(layer.size.width, layer.size.height),
      offset: Offset(layer.offset.dx, layer.offset.dy),
      visuals: _cloneVisuals(layer.visuals),
    );
  }

  StageStickerLayer _cloneStickerLayer(StageStickerLayer layer) {
    return layer.copyWith(
      size: Size(layer.size.width, layer.size.height),
      offset: Offset(layer.offset.dx, layer.offset.dy),
      visuals: _cloneVisuals(layer.visuals),
    );
  }

  StageDrawLayer _cloneDrawLayer(StageDrawLayer layer) {
    return layer.copyWith(
      strokes: layer.strokes.map(_cloneDrawStroke).toList(growable: false),
      visuals: _cloneVisuals(layer.visuals),
    );
  }

  StageShapeLayer _cloneShapeLayer(StageShapeLayer layer) {
    return layer.copyWith(
      size: Size(layer.size.width, layer.size.height),
      offset: Offset(layer.offset.dx, layer.offset.dy),
      gradientColors: List<Color>.from(layer.gradientColors),
      visuals: _cloneVisuals(layer.visuals),
    );
  }

  EditorTextLayer _cloneTextLayer(EditorTextLayer layer) {
    return layer.copyWith(
      offset: Offset(layer.offset.dx, layer.offset.dy),
      style: _cloneTextStyle(layer.style),
    );
  }

  EditorTextStyleConfig _cloneTextStyle(EditorTextStyleConfig style) {
    return style.copyWith(
      gradientColors: style.gradientColors == null
          ? null
          : List<Color>.from(style.gradientColors!),
      backgroundHighlightColor: style.backgroundHighlightColor,
      strokeColor: style.strokeColor,
      shadow: Shadow(
        color: style.shadow.color,
        offset: style.shadow.offset,
        blurRadius: style.shadow.blurRadius,
      ),
    );
  }

  DrawStroke _cloneDrawStroke(DrawStroke stroke) {
    return stroke.copyWith(
      points: stroke.points
          .map((point) => Offset(point.dx, point.dy))
          .toList(growable: false),
    );
  }

  PhotoAdjustments _cloneAdjustments(PhotoAdjustments adjustments) {
    return adjustments.copyWith();
  }

  PhotoFilterConfig _cloneFilter(PhotoFilterConfig filter) {
    return filter.copyWith();
  }

  RemoveBgState _cloneRemoveBgState(RemoveBgState state) {
    return state.copyWith(
      autoMask: state.autoMask.copyWith(
        center: Offset(state.autoMask.center.dx, state.autoMask.center.dy),
      ),
      strokes: state.strokes
          .map(
            (stroke) => stroke.copyWith(
              points: stroke.points
                  .map((point) => Offset(point.dx, point.dy))
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }

  DecorationStyleConfig _cloneDecoration(DecorationStyleConfig config) {
    return config.copyWith(
      border: config.border.copyWith(
        gradientColors: List<Color>.from(config.border.gradientColors),
      ),
      frame: config.frame.copyWith(),
    );
  }

  LayerVisualConfig _cloneVisuals(LayerVisualConfig visuals) {
    return visuals.copyWith(
      shadow: visuals.shadow.copyWith(color: visuals.shadow.color),
    );
  }

  Map<String, Object?> _serializeStageBackground(StageBackgroundConfig config) {
    return <String, Object?>{
      'type': config.type.name,
      'solidColor': config.solidColor?.toARGB32(),
      'gradientColors': config.gradientColors
          ?.map((color) => color.toARGB32())
          .toList(growable: false),
      'gradientAngle': config.gradientAngle,
      'imageUrl': config.imageUrl,
      'imageFit': config.imageFit.name,
      'imageBlur': config.imageBlur,
      'imageOpacity': config.imageOpacity,
      'posterDecoration': _serializeDecoration(config.posterDecoration),
    };
  }

  Map<String, Object?> _serializeDecoration(DecorationStyleConfig decoration) {
    return <String, Object?>{
      'border': <String, Object?>{
        'style': decoration.border.style.name,
        'solidColor': decoration.border.solidColor.toARGB32(),
        'gradientColors': decoration.border.gradientColors
            .map((color) => color.toARGB32())
            .toList(growable: false),
        'thickness': decoration.border.thickness,
        'cornerRadius': decoration.border.cornerRadius,
        'opacity': decoration.border.opacity,
        'shadow': decoration.border.shadow,
      },
      'frame': <String, Object?>{
        'presetId': decoration.frame.presetId,
        'opacity': decoration.frame.opacity,
        'size': decoration.frame.size,
      },
    };
  }

  Map<String, Object?> _serializeVisuals(LayerVisualConfig visuals) {
    return <String, Object?>{
      'opacity': visuals.opacity,
      'blendMode': visuals.blendMode.name,
      'flipX': visuals.flipX,
      'flipY': visuals.flipY,
      'shadow': <String, Object?>{
        'color': visuals.shadow.color.toARGB32(),
        'blur': visuals.shadow.blur,
        'distance': visuals.shadow.distance,
        'opacity': visuals.shadow.opacity,
      },
    };
  }

  Map<String, Object?> _serializeTextStyle(EditorTextStyleConfig style) {
    return <String, Object?>{
      'fontFamily': style.fontFamily,
      'fontSize': style.fontSize,
      'color': style.color.toARGB32(),
      'opacity': style.opacity,
      'gradientColors': style.gradientColors
          ?.map((color) => color.toARGB32())
          .toList(growable: false),
      'backgroundHighlightColor': style.backgroundHighlightColor?.toARGB32(),
      'strokeColor': style.strokeColor?.toARGB32(),
      'strokeWidth': style.strokeWidth,
      'shadow': <String, Object?>{
        'color': style.shadow.color.toARGB32(),
        'blurRadius': style.shadow.blurRadius,
        'offset': _serializeOffset(style.shadow.offset),
      },
      'isBold': style.isBold,
      'isItalic': style.isItalic,
      'alignment': style.alignment.name,
      'letterSpacing': style.letterSpacing,
      'lineHeight': style.lineHeight,
      'curve': style.curve,
    };
  }

  Map<String, Object?> _serializeAdjustments(PhotoAdjustments adjustments) {
    return <String, Object?>{
      'brightness': adjustments.brightness,
      'contrast': adjustments.contrast,
      'saturation': adjustments.saturation,
      'warmth': adjustments.warmth,
      'tint': adjustments.tint,
      'highlights': adjustments.highlights,
      'shadows': adjustments.shadows,
      'sharpness': adjustments.sharpness,
    };
  }

  Map<String, Object?> _serializeFilter(PhotoFilterConfig filter) {
    return <String, Object?>{
      'preset': filter.preset.name,
      'intensity': filter.intensity,
    };
  }

  Map<String, Object?> _serializeRemoveBg(RemoveBgState state) {
    return <String, Object?>{
      'mask': <String, Object?>{
        'isActive': state.autoMask.isActive,
        'kind': state.autoMask.kind.name,
        'center': _serializeOffset(state.autoMask.center),
        'radiusX': state.autoMask.radiusX,
        'radiusY': state.autoMask.radiusY,
        'feather': state.autoMask.feather,
        'source': state.autoMask.source,
        'modelSlot': state.autoMask.modelSlot,
      },
      'strokes': state.strokes
          .map(
            (stroke) => <String, Object?>{
              'mode': stroke.mode.name,
              'brushSize': stroke.brushSize,
              'softness': stroke.softness,
              'points': stroke.points
                  .map((point) => _serializeOffset(point))
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    };
  }

  Map<String, Object?> _serializeDrawStroke(DrawStroke stroke) {
    return <String, Object?>{
      'id': stroke.id,
      'mode': stroke.mode.name,
      'style': stroke.style.name,
      'points': stroke.points
          .map((point) => _serializeOffset(point))
          .toList(growable: false),
      'color': stroke.color.toARGB32(),
      'size': stroke.size,
      'opacity': stroke.opacity,
    };
  }

  Map<String, double> _serializeOffset(Offset offset) => <String, double>{
    'dx': offset.dx,
    'dy': offset.dy,
  };

  Map<String, double> _serializeSize(Size size) => <String, double>{
    'width': size.width,
    'height': size.height,
  };

  _EditorHistoryEntry? _historyEntryFromSerializedMap(
    Map<String, Object?>? map,
  ) {
    if (map == null) {
      return null;
    }
    final snapshot = _historySnapshotFromSerializedMap(map);
    final signature = jsonEncode(_serializeHistorySnapshot(snapshot));
    return _EditorHistoryEntry(snapshot: snapshot, signature: signature);
  }

  _EditorHistorySnapshot _historySnapshotFromSerializedMap(
    Map<String, Object?> map,
  ) {
    final stageBackground =
        _parseStageBackground(_asMap(map['stageBackground'])) ??
        const StageBackgroundConfig.solid(Colors.white);
    final mainSurface = _parseSurfacePhoto(_asMap(map['mainSurfacePhoto']));
    final mainSurfaceImageSize = _parseSize(
      _asMap(map['mainSurfaceImageSize']),
    );
    final mainSurfaceScale = _asDouble(map['mainSurfaceScale']) ?? 1;
    final mainSurfaceRotation = _asDouble(map['mainSurfaceRotation']) ?? 0;
    final mainSurfaceOffset =
        _parseOffset(_asMap(map['mainSurfaceOffset'])) ?? Offset.zero;
    final mainSurfaceCropRatio = _asDouble(map['mainSurfaceCropRatio']);
    final mainSurfaceCropTurns = _asInt(map['mainSurfaceCropTurns']) ?? 0;
    final extraPhotos = _parsePhotoLayers(_asList(map['extraPhotoLayers']));
    final textLayers = _parseTextLayers(_asList(map['textLayers']));
    final elementLayers = _parseElementLayers(_asList(map['elementLayers']));
    final stickerLayers = _parseStickerLayers(_asList(map['stickerLayers']));
    final drawLayers = _parseDrawLayers(_asList(map['drawLayers']));
    final shapeLayers = _parseShapeLayers(_asList(map['shapeLayers']));
    final seq = _asMap(map['seq']);
    final selection = _asMap(map['selection']);
    final guides = _asMap(map['guides']);

    return _EditorHistorySnapshot(
      stageBackground: stageBackground,
      recentBackgroundColors: _parseColorList(map['recentBackgroundColors']),
      backgroundSampleSeq: _asInt(map['backgroundSampleSeq']) ?? 0,
      mainSurfacePhoto: mainSurface,
      mainSurfaceImageSize: mainSurfaceImageSize,
      mainSurfaceScale: mainSurfaceScale,
      mainSurfaceRotation: mainSurfaceRotation,
      mainSurfaceOffset: mainSurfaceOffset,
      mainSurfaceCropRatio: mainSurfaceCropRatio,
      mainSurfaceCropTurns: mainSurfaceCropTurns,
      extraPhotoLayers: extraPhotos,
      elementLayers: elementLayers,
      stickerLayers: stickerLayers,
      drawLayers: drawLayers,
      shapeLayers: shapeLayers,
      textLayers: textLayers,
      photoSeq:
          _asInt(seq?['photo']) ??
          _deriveSeq(extraPhotos.map((e) => e.id), 'photo_'),
      elementSeq:
          _asInt(seq?['element']) ??
          _deriveSeq(elementLayers.map((e) => e.id), 'element_'),
      stickerSeq:
          _asInt(seq?['sticker']) ??
          _deriveSeq(stickerLayers.map((e) => e.id), 'sticker_'),
      drawSeq:
          _asInt(seq?['draw']) ??
          _deriveSeq(drawLayers.map((e) => e.id), 'draw_'),
      shapeSeq:
          _asInt(seq?['shape']) ??
          _deriveSeq(shapeLayers.map((e) => e.id), 'shape_'),
      drawStrokeSeq: _asInt(seq?['drawStroke']) ?? 0,
      textSeq:
          _asInt(seq?['text']) ??
          _deriveSeq(textLayers.map((e) => e.id), 'text_'),
      selectedExtraPhotoLayerId: _asString(selection?['photo']),
      selectedTextLayerId: _asString(selection?['text']),
      selectedElementLayerId: _asString(selection?['element']),
      selectedStickerLayerId: _asString(selection?['sticker']),
      selectedDrawLayerId: _asString(selection?['draw']),
      selectedShapeLayerId: _asString(selection?['shape']),
      isMainSurfaceSelected: _asBool(selection?['main']) ?? false,
      showVerticalGuide: _asBool(guides?['vertical']) ?? false,
      showHorizontalGuide: _asBool(guides?['horizontal']) ?? false,
    );
  }

  _EditorHistorySnapshot _historySnapshotFromDraftPayload(
    Map<String, Object?> payload,
  ) {
    final stageBackground =
        _parseStageBackground(_asMap(payload['stageBackground'])) ??
        const StageBackgroundConfig.solid(Colors.white);
    final mainSurfaceData = _asMap(payload['mainSurface']);
    final mainSurfaceImageUrl = _asString(mainSurfaceData?['imageUrl']);
    final mainSurfacePhoto = mainSurfaceImageUrl == null
        ? null
        : StageSurfacePhoto(
            imageUrl: mainSurfaceImageUrl,
            adjustments: _parseAdjustments(
              _asMap(mainSurfaceData?['adjustments']),
            ),
            filter: _parseFilter(_asMap(mainSurfaceData?['filter'])),
            removeBgState: _parseRemoveBg(
              _asMap(mainSurfaceData?['removeBg']) ??
                  _asMap(mainSurfaceData?['removeBgState']),
            ),
            decoration: _parseDecoration(
              _asMap(mainSurfaceData?['decoration']),
            ),
            visuals: _parseVisuals(_asMap(mainSurfaceData?['visuals'])),
            isLocked: _asBool(mainSurfaceData?['isLocked']) ?? false,
          );

    final extraPhotos = _parsePhotoLayers(_asList(payload['extraPhotos']));
    final textLayers = _parseTextLayers(_asList(payload['texts']));
    final elementLayers = _parseElementLayers(_asList(payload['elements']));
    final stickerLayers = _parseStickerLayers(_asList(payload['stickers']));
    final drawLayers = _parseDrawLayers(_asList(payload['drawLayers']));
    final shapeLayers = _parseShapeLayers(_asList(payload['shapeLayers']));
    final seq = _asMap(payload['seq']);
    final selection = _asMap(payload['selection']);

    return _EditorHistorySnapshot(
      stageBackground: stageBackground,
      recentBackgroundColors: _parseColorList(
        payload['recentBackgroundColors'],
      ),
      backgroundSampleSeq: _asInt(payload['backgroundSampleSeq']) ?? 0,
      mainSurfacePhoto: mainSurfacePhoto,
      mainSurfaceImageSize: _parseSize(_asMap(payload['mainSurfaceImageSize'])),
      mainSurfaceScale: _asDouble(mainSurfaceData?['scale']) ?? 1,
      mainSurfaceRotation: _asDouble(mainSurfaceData?['rotation']) ?? 0,
      mainSurfaceOffset:
          _parseOffset(_asMap(mainSurfaceData?['offset'])) ?? Offset.zero,
      mainSurfaceCropRatio: _asDouble(mainSurfaceData?['cropRatio']),
      mainSurfaceCropTurns: _asInt(mainSurfaceData?['cropTurns']) ?? 0,
      extraPhotoLayers: extraPhotos,
      elementLayers: elementLayers,
      stickerLayers: stickerLayers,
      drawLayers: drawLayers,
      shapeLayers: shapeLayers,
      textLayers: textLayers,
      photoSeq:
          _asInt(seq?['photo']) ??
          _deriveSeq(extraPhotos.map((e) => e.id), 'photo_'),
      elementSeq:
          _asInt(seq?['element']) ??
          _deriveSeq(elementLayers.map((e) => e.id), 'element_'),
      stickerSeq:
          _asInt(seq?['sticker']) ??
          _deriveSeq(stickerLayers.map((e) => e.id), 'sticker_'),
      drawSeq:
          _asInt(seq?['draw']) ??
          _deriveSeq(drawLayers.map((e) => e.id), 'draw_'),
      shapeSeq:
          _asInt(seq?['shape']) ??
          _deriveSeq(shapeLayers.map((e) => e.id), 'shape_'),
      drawStrokeSeq: _asInt(seq?['drawStroke']) ?? 0,
      textSeq:
          _asInt(seq?['text']) ??
          _deriveSeq(textLayers.map((e) => e.id), 'text_'),
      selectedExtraPhotoLayerId: _asString(
        selection?['selectedExtraPhotoLayerId'],
      ),
      selectedTextLayerId: _asString(selection?['selectedTextLayerId']),
      selectedElementLayerId: _asString(selection?['selectedElementLayerId']),
      selectedStickerLayerId: _asString(selection?['selectedStickerLayerId']),
      selectedDrawLayerId: _asString(selection?['selectedDrawLayerId']),
      selectedShapeLayerId: _asString(selection?['selectedShapeLayerId']),
      isMainSurfaceSelected:
          _asBool(selection?['isMainSurfaceSelected']) ?? false,
      showVerticalGuide: false,
      showHorizontalGuide: false,
    );
  }

  StageBackgroundConfig? _parseStageBackground(Map<String, Object?>? map) {
    if (map == null) {
      return null;
    }
    final typeName = _asString(map['type']) ?? StageBackgroundType.solid.name;
    final type = StageBackgroundType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => StageBackgroundType.solid,
    );
    final posterDecoration = _parseDecoration(_asMap(map['posterDecoration']));
    switch (type) {
      case StageBackgroundType.solid:
        return StageBackgroundConfig.solid(
          _parseColor(map['solidColor']) ?? Colors.white,
        ).copyWith(posterDecoration: posterDecoration);
      case StageBackgroundType.gradient:
        return StageBackgroundConfig.gradient(
          _parseColorList(map['gradientColors']).isEmpty
              ? const <Color>[Color(0xFFF8FAFF), Color(0xFFE2E8F0)]
              : _parseColorList(map['gradientColors']),
          angle: _asDouble(map['gradientAngle']) ?? 270,
        ).copyWith(posterDecoration: posterDecoration);
      case StageBackgroundType.image:
        final url = _asString(map['imageUrl']);
        if (url == null || url.isEmpty) {
          return const StageBackgroundConfig.solid(Colors.white);
        }
        final fitName =
            _asString(map['imageFit']) ?? StageBackgroundImageFit.fill.name;
        final fit = StageBackgroundImageFit.values.firstWhere(
          (item) => item.name == fitName,
          orElse: () => StageBackgroundImageFit.fill,
        );
        return StageBackgroundConfig.image(
          url,
          fit: fit,
          blur: _asDouble(map['imageBlur']) ?? 0,
          opacity: _asDouble(map['imageOpacity']) ?? 1,
        ).copyWith(posterDecoration: posterDecoration);
    }
  }

  DecorationStyleConfig _parseDecoration(Map<String, Object?>? map) {
    if (map == null) {
      return DecorationStyleConfig.none;
    }
    final borderMap = _asMap(map['border']);
    final frameMap = _asMap(map['frame']);
    final borderStyleName =
        _asString(borderMap?['style']) ?? BorderStylePreset.solid.name;
    final borderStyle = BorderStylePreset.values.firstWhere(
      (item) => item.name == borderStyleName,
      orElse: () => BorderStylePreset.solid,
    );
    return DecorationStyleConfig(
      border: BorderDecorationConfig(
        style: borderStyle,
        solidColor:
            _parseColor(borderMap?['solidColor']) ?? const Color(0xFFFFFFFF),
        gradientColors: _parseColorList(borderMap?['gradientColors']).isEmpty
            ? const <Color>[Color(0xFFFFE082), Color(0xFFF59E0B)]
            : _parseColorList(borderMap?['gradientColors']),
        thickness: _asDouble(borderMap?['thickness']) ?? 0,
        cornerRadius: _asDouble(borderMap?['cornerRadius']) ?? 0.08,
        opacity: _asDouble(borderMap?['opacity']) ?? 1,
        shadow: _asDouble(borderMap?['shadow']) ?? 0,
      ),
      frame: FrameDecorationConfig(
        presetId: _asString(frameMap?['presetId']),
        opacity: _asDouble(frameMap?['opacity']) ?? 0,
        size: _asDouble(frameMap?['size']) ?? 0.12,
      ),
    );
  }

  LayerVisualConfig _parseVisuals(Map<String, Object?>? map) {
    if (map == null) {
      return LayerVisualConfig.standard;
    }
    final shadowMap = _asMap(map['shadow']);
    final blendName =
        _asString(map['blendMode']) ?? LayerBlendModeOption.normal.name;
    return LayerVisualConfig(
      opacity: (_asDouble(map['opacity']) ?? 1).clamp(0.0, 1.0),
      blendMode: LayerBlendModeOption.values.firstWhere(
        (item) => item.name == blendName,
        orElse: () => LayerBlendModeOption.normal,
      ),
      flipX: _asBool(map['flipX']) ?? false,
      flipY: _asBool(map['flipY']) ?? false,
      shadow: LayerShadowConfig(
        color: _parseColor(shadowMap?['color']) ?? const Color(0xFF000000),
        blur: _asDouble(shadowMap?['blur']) ?? 0,
        distance: _asDouble(shadowMap?['distance']) ?? 0,
        opacity: _asDouble(shadowMap?['opacity']) ?? 0,
      ),
    );
  }

  EditorTextStyleConfig _parseTextStyle(Map<String, Object?>? map) {
    if (map == null) {
      return kDefaultEditorTextStyle;
    }
    final shadowMap = _asMap(map['shadow']);
    final offset = _parseOffset(_asMap(shadowMap?['offset'])) ?? Offset.zero;
    final alignName = _asString(map['alignment']) ?? TextAlign.center.name;
    final alignment = TextAlign.values.firstWhere(
      (item) => item.name == alignName,
      orElse: () => TextAlign.center,
    );
    return EditorTextStyleConfig(
      fontFamily:
          _asString(map['fontFamily']) ?? kDefaultEditorTextStyle.fontFamily,
      fontSize: _asDouble(map['fontSize']) ?? kDefaultEditorTextStyle.fontSize,
      color: _parseColor(map['color']) ?? kDefaultEditorTextStyle.color,
      opacity: (_asDouble(map['opacity']) ?? 1).clamp(0.0, 1.0),
      gradientColors: _parseColorList(map['gradientColors']).isEmpty
          ? null
          : _parseColorList(map['gradientColors']),
      backgroundHighlightColor: _parseColor(map['backgroundHighlightColor']),
      strokeColor: _parseColor(map['strokeColor']),
      strokeWidth: _asDouble(map['strokeWidth']) ?? 0,
      shadow: Shadow(
        color: _parseColor(shadowMap?['color']) ?? Colors.transparent,
        blurRadius: _asDouble(shadowMap?['blurRadius']) ?? 0,
        offset: offset,
      ),
      isBold: _asBool(map['isBold']) ?? false,
      isItalic: _asBool(map['isItalic']) ?? false,
      alignment: alignment,
      letterSpacing: _asDouble(map['letterSpacing']) ?? 0,
      lineHeight: _asDouble(map['lineHeight']) ?? 1.2,
      curve: _asDouble(map['curve']) ?? 0,
    );
  }

  PhotoAdjustments _parseAdjustments(Map<String, Object?>? map) {
    if (map == null) {
      return PhotoAdjustments.neutral;
    }
    return PhotoAdjustments(
      brightness: _asDouble(map['brightness']) ?? 0,
      contrast: _asDouble(map['contrast']) ?? 0,
      saturation: _asDouble(map['saturation']) ?? 0,
      warmth: _asDouble(map['warmth']) ?? 0,
      tint: _asDouble(map['tint']) ?? 0,
      highlights: _asDouble(map['highlights']) ?? 0,
      shadows: _asDouble(map['shadows']) ?? 0,
      sharpness: _asDouble(map['sharpness']) ?? 0,
    );
  }

  PhotoFilterConfig _parseFilter(Map<String, Object?>? map) {
    if (map == null) {
      return PhotoFilterConfig.none;
    }
    final presetName = _asString(map['preset']) ?? PhotoFilterPreset.none.name;
    final preset = PhotoFilterPreset.values.firstWhere(
      (item) => item.name == presetName,
      orElse: () => PhotoFilterPreset.none,
    );
    return PhotoFilterConfig(
      preset: preset,
      intensity: (_asDouble(map['intensity']) ?? 0).clamp(0.0, 1.0),
    );
  }

  RemoveBgState _parseRemoveBg(Map<String, Object?>? map) {
    if (map == null) {
      return RemoveBgState.none;
    }
    final maskMap = _asMap(map['mask']);
    final autoMask = maskMap == null
        ? AutoMaskTemplate.none
        : AutoMaskTemplate(
            kind: AutoMaskTemplateKind.values.firstWhere(
              (item) =>
                  item.name ==
                  (_asString(maskMap['kind']) ??
                      AutoMaskTemplateKind.none.name),
              orElse: () => AutoMaskTemplateKind.none,
            ),
            center:
                _parseOffset(_asMap(maskMap['center'])) ??
                const Offset(0.5, 0.5),
            radiusX: _asDouble(maskMap['radiusX']) ?? 0.34,
            radiusY: _asDouble(maskMap['radiusY']) ?? 0.44,
            feather: _asDouble(maskMap['feather']) ?? 0.14,
            source: _asString(maskMap['source']) ?? 'none',
            modelSlot: _asString(maskMap['modelSlot']) ?? 'none',
          );
    final strokeList = _asList(map['strokes']);
    final strokes = <RemoveBgStroke>[];
    if (strokeList != null) {
      for (final item in strokeList) {
        final strokeMap = _asMap(item);
        if (strokeMap == null) {
          continue;
        }
        final modeName =
            _asString(strokeMap['mode']) ?? RemoveBgRefineMode.erase.name;
        final mode = RemoveBgRefineMode.values.firstWhere(
          (value) => value.name == modeName,
          orElse: () => RemoveBgRefineMode.erase,
        );
        final points = _parseOffsetList(strokeMap['points']);
        if (points.isEmpty) {
          continue;
        }
        strokes.add(
          RemoveBgStroke(
            mode: mode,
            points: points,
            brushSize: _asDouble(strokeMap['brushSize']) ?? 0.11,
            softness: _asDouble(strokeMap['softness']) ?? 0.45,
          ),
        );
      }
    }
    return RemoveBgState(
      autoMask: autoMask,
      strokes: strokes,
      lastAppliedMode: _asString(map['lastAppliedMode']) ?? 'none',
    );
  }

  StageSurfacePhoto? _parseSurfacePhoto(Map<String, Object?>? map) {
    if (map == null) {
      return null;
    }
    final imageUrl = _asString(map['imageUrl']);
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    return StageSurfacePhoto(
      imageUrl: imageUrl,
      adjustments: _parseAdjustments(_asMap(map['adjustments'])),
      filter: _parseFilter(_asMap(map['filter'])),
      removeBgState: _parseRemoveBg(
        _asMap(map['removeBg']) ?? _asMap(map['removeBgState']),
      ),
      decoration: _parseDecoration(_asMap(map['decoration'])),
      visuals: _parseVisuals(_asMap(map['visuals'])),
      isLocked: _asBool(map['isLocked']) ?? false,
    );
  }

  List<StagePhotoLayer> _parsePhotoLayers(List<Object?>? list) {
    if (list == null) {
      return <StagePhotoLayer>[];
    }
    final parsed = <StagePhotoLayer>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) {
        continue;
      }
      final id = _asString(map['id']);
      final imageUrl = _asString(map['imageUrl']);
      if (id == null || imageUrl == null || imageUrl.isEmpty) {
        continue;
      }
      parsed.add(
        StagePhotoLayer(
          id: id,
          imageUrl: imageUrl,
          name: _asString(map['name']) ?? id,
          size: _parseSize(_asMap(map['size'])) ?? const Size(180, 180),
          offset: _parseOffset(_asMap(map['offset'])) ?? Offset.zero,
          scale: (_asDouble(map['scale']) ?? 1).clamp(0.1, 10),
          rotation: _asDouble(map['rotation']) ?? 0,
          cropRatio: _asDouble(map['cropRatio']),
          cropTurns: _asInt(map['cropTurns']) ?? 0,
          adjustments: _parseAdjustments(_asMap(map['adjustments'])),
          filter: _parseFilter(_asMap(map['filter'])),
          removeBgState: _parseRemoveBg(
            _asMap(map['removeBg']) ?? _asMap(map['removeBgState']),
          ),
          decoration: _parseDecoration(_asMap(map['decoration'])),
          visuals: _parseVisuals(_asMap(map['visuals'])),
          zIndex: _asInt(map['zIndex']) ?? 0,
          isLocked: _asBool(map['isLocked']) ?? false,
          isVisible: _asBool(map['isVisible']) ?? true,
        ),
      );
    }
    parsed.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return parsed;
  }

  List<EditorTextLayer> _parseTextLayers(List<Object?>? list) {
    if (list == null) {
      return <EditorTextLayer>[];
    }
    final parsed = <EditorTextLayer>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) {
        continue;
      }
      final id = _asString(map['id']);
      if (id == null) {
        continue;
      }
      final blendName =
          _asString(map['blendMode']) ?? LayerBlendModeOption.normal.name;
      final blendMode = LayerBlendModeOption.values.firstWhere(
        (value) => value.name == blendName,
        orElse: () => LayerBlendModeOption.normal,
      );
      parsed.add(
        EditorTextLayer(
          id: id,
          name: _asString(map['name']) ?? id,
          text: _asString(map['text']) ?? '',
          offset: _parseOffset(_asMap(map['offset'])) ?? Offset.zero,
          rotation: _asDouble(map['rotation']) ?? 0,
          scale: (_asDouble(map['scale']) ?? 1).clamp(0.1, 10),
          zIndex: _asInt(map['zIndex']) ?? 0,
          style: _parseTextStyle(_asMap(map['style'])),
          isLocked: _asBool(map['isLocked']) ?? false,
          isFlipped: _asBool(map['isFlipped']) ?? false,
          isFlippedVertical: _asBool(map['isFlippedVertical']) ?? false,
          blendMode: blendMode,
          isVisible: _asBool(map['isVisible']) ?? true,
        ),
      );
    }
    parsed.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return parsed;
  }

  List<StageElementLayer> _parseElementLayers(List<Object?>? list) {
    if (list == null) {
      return <StageElementLayer>[];
    }
    final parsed = <StageElementLayer>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) {
        continue;
      }
      final id = _asString(map['id']);
      final assetId = _asString(map['assetId']);
      final assetUrl = _asString(map['assetUrl']);
      if (id == null || assetId == null || assetUrl == null) {
        continue;
      }
      parsed.add(
        StageElementLayer(
          id: id,
          assetId: assetId,
          assetUrl: assetUrl,
          name: _asString(map['name']) ?? id,
          category: _asString(map['category']) ?? 'Others',
          size: _parseSize(_asMap(map['size'])) ?? const Size(120, 120),
          offset: _parseOffset(_asMap(map['offset'])) ?? Offset.zero,
          scale: (_asDouble(map['scale']) ?? 1).clamp(0.1, 10),
          rotation: _asDouble(map['rotation']) ?? 0,
          visuals: _parseVisuals(_asMap(map['visuals'])),
          zIndex: _asInt(map['zIndex']) ?? 0,
          isLocked: _asBool(map['isLocked']) ?? false,
          isVisible: _asBool(map['isVisible']) ?? true,
        ),
      );
    }
    parsed.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return parsed;
  }

  List<StageStickerLayer> _parseStickerLayers(List<Object?>? list) {
    if (list == null) {
      return <StageStickerLayer>[];
    }
    final parsed = <StageStickerLayer>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) {
        continue;
      }
      final id = _asString(map['id']);
      final stickerId = _asString(map['stickerId']);
      final stickerUrl = _asString(map['stickerUrl']);
      if (id == null || stickerId == null || stickerUrl == null) {
        continue;
      }
      parsed.add(
        StageStickerLayer(
          id: id,
          stickerId: stickerId,
          stickerUrl: stickerUrl,
          name: _asString(map['name']) ?? id,
          category: _asString(map['category']) ?? 'Others',
          size: _parseSize(_asMap(map['size'])) ?? const Size(120, 120),
          offset: _parseOffset(_asMap(map['offset'])) ?? Offset.zero,
          scale: (_asDouble(map['scale']) ?? 1).clamp(0.1, 10),
          rotation: _asDouble(map['rotation']) ?? 0,
          visuals: _parseVisuals(_asMap(map['visuals'])),
          zIndex: _asInt(map['zIndex']) ?? 0,
          isLocked: _asBool(map['isLocked']) ?? false,
          isVisible: _asBool(map['isVisible']) ?? true,
        ),
      );
    }
    parsed.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return parsed;
  }

  List<StageDrawLayer> _parseDrawLayers(List<Object?>? list) {
    if (list == null) {
      return <StageDrawLayer>[];
    }
    final parsed = <StageDrawLayer>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) {
        continue;
      }
      final id = _asString(map['id']);
      if (id == null) {
        continue;
      }
      final strokes = <DrawStroke>[];
      final strokeList = _asList(map['strokes']);
      if (strokeList != null) {
        for (final strokeData in strokeList) {
          final strokeMap = _asMap(strokeData);
          if (strokeMap == null) {
            continue;
          }
          final modeName =
              _asString(strokeMap['mode']) ?? DrawToolMode.pen.name;
          final styleName =
              _asString(strokeMap['style']) ?? DrawBrushStyle.smoothPen.name;
          final mode = DrawToolMode.values.firstWhere(
            (value) => value.name == modeName,
            orElse: () => DrawToolMode.pen,
          );
          final style = DrawBrushStyle.values.firstWhere(
            (value) => value.name == styleName,
            orElse: () => DrawBrushStyle.smoothPen,
          );
          final points = _parseOffsetList(strokeMap['points']);
          if (points.isEmpty) {
            continue;
          }
          strokes.add(
            DrawStroke(
              id: _asString(strokeMap['id']) ?? 'stroke_${strokes.length + 1}',
              mode: mode,
              style: style,
              points: points,
              color: _parseColor(strokeMap['color']) ?? const Color(0xFF111827),
              size: _asDouble(strokeMap['size']) ?? 0.014,
              opacity: (_asDouble(strokeMap['opacity']) ?? 1).clamp(0.0, 1.0),
            ),
          );
        }
      }
      parsed.add(
        StageDrawLayer(
          id: id,
          name: _asString(map['name']) ?? id,
          strokes: strokes,
          visuals: _parseVisuals(_asMap(map['visuals'])),
          zIndex: _asInt(map['zIndex']) ?? 0,
          isLocked: _asBool(map['isLocked']) ?? false,
          isVisible: _asBool(map['isVisible']) ?? true,
        ),
      );
    }
    parsed.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return parsed;
  }

  List<StageShapeLayer> _parseShapeLayers(List<Object?>? list) {
    if (list == null) {
      return <StageShapeLayer>[];
    }
    final parsed = <StageShapeLayer>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) {
        continue;
      }
      final id = _asString(map['id']);
      if (id == null) {
        continue;
      }
      final kindName = _asString(map['kind']) ?? ShapeKind.rectangle.name;
      final kind = ShapeKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => ShapeKind.rectangle,
      );
      parsed.add(
        StageShapeLayer(
          id: id,
          kind: kind,
          name: _asString(map['name']) ?? id,
          size: _parseSize(_asMap(map['size'])) ?? const Size(140, 140),
          offset: _parseOffset(_asMap(map['offset'])) ?? Offset.zero,
          scale: (_asDouble(map['scale']) ?? 1).clamp(0.1, 10),
          rotation: _asDouble(map['rotation']) ?? 0,
          fillColor: _parseColor(map['fillColor']) ?? const Color(0xFF2563EB),
          useGradientFill: _asBool(map['useGradientFill']) ?? false,
          gradientColors: _parseColorList(map['gradientColors']).isEmpty
              ? const <Color>[Color(0xFF6366F1), Color(0xFF06B6D4)]
              : _parseColorList(map['gradientColors']),
          strokeColor:
              _parseColor(map['strokeColor']) ?? const Color(0xFFFFFFFF),
          strokeWidth: _asDouble(map['strokeWidth']) ?? 0,
          opacity: (_asDouble(map['opacity']) ?? 1).clamp(0.0, 1.0),
          cornerRadius: (_asDouble(map['cornerRadius']) ?? 0.18).clamp(
            0.0,
            0.5,
          ),
          visuals: _parseVisuals(_asMap(map['visuals'])),
          zIndex: _asInt(map['zIndex']) ?? 0,
          isLocked: _asBool(map['isLocked']) ?? false,
          isVisible: _asBool(map['isVisible']) ?? true,
        ),
      );
    }
    parsed.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return parsed;
  }

  Offset? _parseOffset(Map<String, Object?>? map) {
    if (map == null) {
      return null;
    }
    final dx = _asDouble(map['dx']);
    final dy = _asDouble(map['dy']);
    if (dx == null || dy == null) {
      return null;
    }
    return Offset(dx, dy);
  }

  List<Offset> _parseOffsetList(Object? raw) {
    final list = _asList(raw);
    if (list == null) {
      return <Offset>[];
    }
    return list
        .map((item) => _parseOffset(_asMap(item)))
        .whereType<Offset>()
        .toList(growable: false);
  }

  Size? _parseSize(Map<String, Object?>? map) {
    if (map == null) {
      return null;
    }
    final width = _asDouble(map['width']);
    final height = _asDouble(map['height']);
    if (width == null || height == null) {
      return null;
    }
    return Size(width, height);
  }

  Color? _parseColor(Object? raw) {
    final value = _asInt(raw);
    if (value == null) {
      return null;
    }
    return Color(value);
  }

  List<Color> _parseColorList(Object? raw) {
    final list = _asList(raw);
    if (list == null) {
      return <Color>[];
    }
    return list.map(_parseColor).whereType<Color>().toList(growable: false);
  }

  Map<String, Object?>? _asMap(Object? raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  List<Object?>? _asList(Object? raw) {
    if (raw is List) {
      return raw.cast<Object?>();
    }
    return null;
  }

  String? _asString(Object? raw) {
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? null : value;
    }
    return null;
  }

  int? _asInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is double) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  double? _asDouble(Object? raw) {
    if (raw is double) {
      return raw;
    }
    if (raw is int) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw);
    }
    return null;
  }

  bool? _asBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      if (raw.toLowerCase() == 'true') {
        return true;
      }
      if (raw.toLowerCase() == 'false') {
        return false;
      }
    }
    return null;
  }

  int _deriveSeq(Iterable<String> ids, String prefix) {
    var max = 0;
    for (final id in ids) {
      if (!id.startsWith(prefix)) {
        continue;
      }
      final value = int.tryParse(id.substring(prefix.length));
      if (value != null && value > max) {
        max = value;
      }
    }
    return max;
  }

  void _beginCropSession() {
    if (selectedExtraPhotoLayer != null) {
      final layer = selectedExtraPhotoLayer!;
      _cropSessionActive = true;
      _cropTargetType = _CropTargetType.extraPhoto;
      _cropTargetLayerId = layer.id;
      _cropInitialRatioKey = _ratioKeyFromValue(layer.cropRatio);
      _cropInitialTurns = layer.cropTurns;
      _cropInitialSize = layer.size;
      _cropInitialRotation = layer.rotation;
      _cropDraftRatioKey = _cropInitialRatioKey;
      _cropDraftTurns = _cropInitialTurns;
      return;
    }

    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _cropSessionActive = true;
      _cropTargetType = _CropTargetType.mainSurface;
      _cropTargetLayerId = null;
      _cropInitialRatioKey = _ratioKeyFromValue(_mainSurfaceCropRatio);
      _cropInitialTurns = _mainSurfaceCropTurns;
      _cropInitialSize = null;
      _cropInitialRotation = 0;
      _cropDraftRatioKey = _cropInitialRatioKey;
      _cropDraftTurns = _cropInitialTurns;
    }
  }

  void _beginAdjustSession() {
    if (selectedExtraPhotoLayer != null) {
      final layer = selectedExtraPhotoLayer!;
      _adjustSessionActive = true;
      _adjustTargetType = _AdjustTargetType.extraPhoto;
      _adjustTargetLayerId = layer.id;
      _adjustInitial = layer.adjustments;
      _adjustDraft = layer.adjustments;
      return;
    }

    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _adjustSessionActive = true;
      _adjustTargetType = _AdjustTargetType.mainSurface;
      _adjustTargetLayerId = null;
      _adjustInitial = _mainSurfacePhoto!.adjustments;
      _adjustDraft = _mainSurfacePhoto!.adjustments;
      return;
    }

    _adjustSessionActive = false;
    _adjustTargetType = null;
    _adjustTargetLayerId = null;
    _adjustInitial = PhotoAdjustments.neutral;
    _adjustDraft = PhotoAdjustments.neutral;
  }

  void _beginFilterSession() {
    if (selectedExtraPhotoLayer != null) {
      final layer = selectedExtraPhotoLayer!;
      _filterSessionActive = true;
      _filterTargetType = _FilterTargetType.extraPhoto;
      _filterTargetLayerId = layer.id;
      _filterInitial = layer.filter;
      _filterDraft = layer.filter;
      return;
    }

    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _filterSessionActive = true;
      _filterTargetType = _FilterTargetType.mainSurface;
      _filterTargetLayerId = null;
      _filterInitial = _mainSurfacePhoto!.filter;
      _filterDraft = _mainSurfacePhoto!.filter;
      return;
    }

    _resetFilterSessionState();
  }

  void _beginBorderFrameSession() {
    _borderFrameSessionActive = true;
    _borderFrameSection = BorderFrameSection.border;
    final preferredTarget =
        selectedExtraPhotoLayer != null || _isMainSurfaceSelected
        ? BorderFrameTarget.selectedPhoto
        : BorderFrameTarget.fullPoster;
    _borderFrameTarget = preferredTarget;
    _loadBorderFrameStateForTarget(preferredTarget);
  }

  void _loadBorderFrameStateForTarget(BorderFrameTarget target) {
    if (target == BorderFrameTarget.fullPoster) {
      final current = _stageBackground.posterDecoration;
      _borderFrameInitial = current;
      _borderFrameDraft = current;
      return;
    }

    if (selectedExtraPhotoLayer != null) {
      final current = selectedExtraPhotoLayer!.decoration;
      _borderFrameInitial = current;
      _borderFrameDraft = current;
      return;
    }

    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      final current = _mainSurfacePhoto!.decoration;
      _borderFrameInitial = current;
      _borderFrameDraft = current;
      return;
    }

    _borderFrameTarget = BorderFrameTarget.fullPoster;
    final current = _stageBackground.posterDecoration;
    _borderFrameInitial = current;
    _borderFrameDraft = current;
  }

  void _beginRemoveBgSession() {
    if (selectedExtraPhotoLayer != null) {
      final layer = selectedExtraPhotoLayer!;
      _removeBgSessionActive = true;
      _removeBgTargetType = _RemoveBgTargetType.extraPhoto;
      _removeBgTargetLayerId = layer.id;
      _removeBgInitial = layer.removeBgState;
      _removeBgDraft = layer.removeBgState;
      _removeBgRefineMode = RemoveBgRefineMode.erase;
      _activeRemoveBgStrokeIndex = -1;
      return;
    }

    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _removeBgSessionActive = true;
      _removeBgTargetType = _RemoveBgTargetType.mainSurface;
      _removeBgTargetLayerId = null;
      _removeBgInitial = _mainSurfacePhoto!.removeBgState;
      _removeBgDraft = _mainSurfacePhoto!.removeBgState;
      _removeBgRefineMode = RemoveBgRefineMode.erase;
      _activeRemoveBgStrokeIndex = -1;
      return;
    }

    _resetRemoveBgSessionState();
  }

  void _beginDrawSession() {
    _drawSessionActive = true;
    _drawEditingLayerId = _selectedDrawLayerId;
    if (_selectedDrawLayerId != null) {
      final layer = _findDrawLayer(_selectedDrawLayerId!);
      _drawInitialStrokes = layer == null
          ? <DrawStroke>[]
          : List<DrawStroke>.from(layer.strokes);
      _drawDraftStrokes = List<DrawStroke>.from(_drawInitialStrokes);
    } else {
      _drawInitialStrokes = <DrawStroke>[];
      _drawDraftStrokes = <DrawStroke>[];
    }
    _drawRedoStack.clear();
    _activeDraftStrokeIndex = null;
  }

  void _resetCropSessionState() {
    _cropSessionActive = false;
    _cropTargetType = null;
    _cropTargetLayerId = null;
    _cropDraftRatioKey = 'free';
    _cropDraftTurns = 0;
    _cropInitialRatioKey = 'free';
    _cropInitialTurns = 0;
    _cropInitialSize = null;
    _cropInitialRotation = 0;
  }

  void _resetAdjustSessionState() {
    _adjustSessionActive = false;
    _adjustTargetType = null;
    _adjustTargetLayerId = null;
    _adjustInitial = PhotoAdjustments.neutral;
    _adjustDraft = PhotoAdjustments.neutral;
  }

  void _resetFilterSessionState() {
    _filterSessionActive = false;
    _filterTargetType = null;
    _filterTargetLayerId = null;
    _filterInitial = PhotoFilterConfig.none;
    _filterDraft = PhotoFilterConfig.none;
  }

  void _resetBorderFrameSessionState() {
    _borderFrameSessionActive = false;
    _borderFrameSection = BorderFrameSection.border;
    _borderFrameTarget = BorderFrameTarget.selectedPhoto;
    _borderFrameInitial = DecorationStyleConfig.none;
    _borderFrameDraft = DecorationStyleConfig.none;
  }

  void _resetRemoveBgSessionState() {
    _removeBgSessionActive = false;
    _removeBgTargetType = null;
    _removeBgTargetLayerId = null;
    _removeBgInitial = RemoveBgState.none;
    _removeBgDraft = RemoveBgState.none;
    _removeBgRefineMode = RemoveBgRefineMode.erase;
    _removeBgBrushSize = 0.11;
    _removeBgSoftness = 0.45;
    _removeBgIsProcessing = false;
    _activeRemoveBgStrokeIndex = -1;
  }

  void _resetDrawSessionState() {
    _drawSessionActive = false;
    _drawEditingLayerId = null;
    _drawInitialStrokes = <DrawStroke>[];
    _drawDraftStrokes = <DrawStroke>[];
    _drawRedoStack.clear();
    _activeDraftStrokeIndex = null;
  }

  void _applyCropDraftPreview() {
    if (!_cropSessionActive) {
      return;
    }
    if (_cropTargetType == _CropTargetType.mainSurface) {
      _mainSurfaceCropRatio = _ratioFromKey(_cropDraftRatioKey);
      _mainSurfaceCropTurns = _cropDraftTurns;
      return;
    }

    if (_cropTargetType == _CropTargetType.extraPhoto &&
        _cropTargetLayerId != null) {
      final layerId = _cropTargetLayerId!;
      final layer = _findExtraPhotoLayer(layerId);
      if (layer == null) {
        return;
      }
      final baseSize = _cropInitialSize ?? layer.size;
      final nextSize = _sizeFromRatio(
        baseSize: baseSize,
        ratio: _ratioFromKey(_cropDraftRatioKey),
      );
      final baseRotation = _cropInitialRotation;
      _updateExtraPhotoLayer(
        layerId,
        (current) => current.copyWith(
          cropRatio: _ratioFromKey(_cropDraftRatioKey),
          clearCropRatio: _ratioFromKey(_cropDraftRatioKey) == null,
          cropTurns: _cropDraftTurns,
          size: nextSize,
          rotation: baseRotation + (_cropDraftTurns * (math.pi / 2)),
        ),
      );
    }
  }

  void _applyAdjustDraftPreview() {
    if (!_adjustSessionActive) {
      return;
    }
    if (_adjustTargetType == _AdjustTargetType.mainSurface) {
      final surface = _mainSurfacePhoto;
      if (surface == null) {
        return;
      }
      _mainSurfacePhoto = surface.copyWith(adjustments: _adjustDraft);
      return;
    }

    if (_adjustTargetType == _AdjustTargetType.extraPhoto &&
        _adjustTargetLayerId != null) {
      final id = _adjustTargetLayerId!;
      _updateExtraPhotoLayer(
        id,
        (current) => current.copyWith(adjustments: _adjustDraft),
      );
    }
  }

  void _applyFilterDraftPreview() {
    if (!_filterSessionActive) {
      return;
    }
    _applyFilterState(_filterDraft);
  }

  void _applyFilterState(PhotoFilterConfig state) {
    if (_filterTargetType == _FilterTargetType.mainSurface) {
      final surface = _mainSurfacePhoto;
      if (surface != null) {
        _mainSurfacePhoto = surface.copyWith(filter: state);
      }
      return;
    }

    if (_filterTargetType == _FilterTargetType.extraPhoto &&
        _filterTargetLayerId != null) {
      final id = _filterTargetLayerId!;
      _updateExtraPhotoLayer(id, (current) => current.copyWith(filter: state));
    }
  }

  void _applyBorderFrameDraftPreview() {
    if (!_borderFrameSessionActive) {
      return;
    }
    _applyBorderFrameState(_borderFrameDraft, target: _borderFrameTarget);
  }

  void _applyBorderFrameState(
    DecorationStyleConfig state, {
    required BorderFrameTarget target,
  }) {
    if (target == BorderFrameTarget.fullPoster) {
      _stageBackground = _stageBackground.copyWith(posterDecoration: state);
      return;
    }

    if (selectedExtraPhotoLayer != null) {
      final id = selectedExtraPhotoLayer!.id;
      _updateExtraPhotoLayer(
        id,
        (current) => current.copyWith(decoration: state),
      );
      return;
    }

    if (_isMainSurfaceSelected && _mainSurfacePhoto != null) {
      _mainSurfacePhoto = _mainSurfacePhoto!.copyWith(decoration: state);
    }
  }

  FramePresetConfig? _framePresetById(String presetId) {
    for (final preset in _framePresetCatalog) {
      if (preset.id == presetId) {
        return preset;
      }
    }
    return null;
  }

  void _addRecentFramePreset(String presetId) {
    _recentFramePresetIds.remove(presetId);
    _recentFramePresetIds.insert(0, presetId);
    if (_recentFramePresetIds.length > 8) {
      _recentFramePresetIds.removeRange(8, _recentFramePresetIds.length);
    }
  }

  EditorElementAsset? _elementAssetById(String assetId) {
    for (final asset in _elementAssetCatalog) {
      if (asset.id == assetId) {
        return asset;
      }
    }
    return null;
  }

  EditorStickerAsset? _stickerAssetById(String assetId) {
    for (final asset in _stickerAssetCatalog) {
      if (asset.id == assetId) {
        return asset;
      }
    }
    return null;
  }

  void _addRecentElementAsset(String assetId) {
    _recentElementAssetIds.remove(assetId);
    _recentElementAssetIds.insert(0, assetId);
    if (_recentElementAssetIds.length > 12) {
      _recentElementAssetIds.removeRange(12, _recentElementAssetIds.length);
    }
  }

  void _addRecentStickerAsset(String assetId) {
    _recentStickerAssetIds.remove(assetId);
    _recentStickerAssetIds.insert(0, assetId);
    if (_recentStickerAssetIds.length > 12) {
      _recentStickerAssetIds.removeRange(12, _recentStickerAssetIds.length);
    }
  }

  void _applyRemoveBgDraftPreview() {
    if (!_removeBgSessionActive) {
      return;
    }
    _applyRemoveBgState(_removeBgDraft);
  }

  void _applyRemoveBgState(RemoveBgState state) {
    if (_removeBgTargetType == _RemoveBgTargetType.mainSurface) {
      final surface = _mainSurfacePhoto;
      if (surface != null) {
        _mainSurfacePhoto = surface.copyWith(removeBgState: state);
      }
      return;
    }

    if (_removeBgTargetType == _RemoveBgTargetType.extraPhoto &&
        _removeBgTargetLayerId != null) {
      final id = _removeBgTargetLayerId!;
      _updateExtraPhotoLayer(
        id,
        (current) => current.copyWith(removeBgState: state),
      );
    }
  }

  String? get _currentRemoveBgImageUrl {
    if (_removeBgTargetType == _RemoveBgTargetType.mainSurface) {
      return _mainSurfacePhoto?.imageUrl;
    }
    if (_removeBgTargetType == _RemoveBgTargetType.extraPhoto &&
        _removeBgTargetLayerId != null) {
      return _findExtraPhotoLayer(_removeBgTargetLayerId!)?.imageUrl;
    }
    return null;
  }

  Size get _currentRemoveBgImageSize {
    if (_removeBgTargetType == _RemoveBgTargetType.mainSurface) {
      return _mainSurfaceImageSize ??
          (_stageSize == Size.zero ? const Size(1080, 1350) : _stageSize);
    }
    if (_removeBgTargetType == _RemoveBgTargetType.extraPhoto &&
        _removeBgTargetLayerId != null) {
      return _findExtraPhotoLayer(_removeBgTargetLayerId!)?.size ??
          const Size(720, 720);
    }
    return const Size(720, 720);
  }

  Offset _clampNormalizedPoint(Offset point) {
    return Offset(point.dx.clamp(0.0, 1.0), point.dy.clamp(0.0, 1.0));
  }

  Size _sizeFromRatio({required Size baseSize, required double? ratio}) {
    if (ratio == null || ratio <= 0) {
      return baseSize;
    }
    final area = math.max(1.0, baseSize.width * baseSize.height);
    final width = math.sqrt(area * ratio);
    final height = width / ratio;
    return Size(width, height);
  }

  double? _ratioFromKey(String key) => _cropRatioOptions[key];

  String _ratioKeyFromValue(double? ratio) {
    if (ratio == null) {
      return 'free';
    }
    for (final entry in _cropRatioOptions.entries) {
      final value = entry.value;
      if (value != null && (value - ratio).abs() < 0.0001) {
        return entry.key;
      }
    }
    return 'free';
  }

  static const List<double> _snapTargets = <double>[
    0,
    math.pi / 2,
    math.pi,
    3 * math.pi / 2,
    2 * math.pi,
  ];

  double _angleDistance(double a, double b) {
    final diff = (a - b).abs() % (2 * math.pi);
    return diff > math.pi ? (2 * math.pi - diff) : diff;
  }

  Offset _snapOffsetToGuides(Offset offset) {
    final snappedDx = offset.dx.abs() <= _guideCenterThreshold
        ? 0.0
        : offset.dx;
    final snappedDy = offset.dy.abs() <= _guideCenterThreshold
        ? 0.0
        : offset.dy;
    return Offset(snappedDx, snappedDy);
  }

  bool _hasTransformChanged({
    required double startScale,
    required double endScale,
    required double startRotation,
    required double endRotation,
    required Offset startOffset,
    required Offset endOffset,
  }) {
    return !_nearlyEqual(startScale, endScale) ||
        !_nearlyEqual(startRotation, endRotation, epsilon: 0.002) ||
        !_offsetNearlyEqual(startOffset, endOffset);
  }

  bool _nearlyEqual(double a, double b, {double epsilon = 0.0005}) {
    return (a - b).abs() <= epsilon;
  }

  bool _offsetNearlyEqual(Offset a, Offset b, {double epsilon = 0.5}) {
    return (a - b).distance <= epsilon;
  }

  void _addRecentBackgroundColor(Color color) {
    _recentBackgroundColors.removeWhere(
      (item) => item.toARGB32() == color.toARGB32(),
    );
    _recentBackgroundColors.insert(0, color);
    if (_recentBackgroundColors.length > 10) {
      _recentBackgroundColors.removeRange(10, _recentBackgroundColors.length);
    }
  }

  static const List<List<Color>> _backgroundGradientOptions = <List<Color>>[
    <Color>[Color(0xFFF8FAFF), Color(0xFFE2E8F0)],
    <Color>[Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
    <Color>[Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
    <Color>[Color(0xFFECFEFF), Color(0xFFCFFAFE)],
    <Color>[Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFDDEAFE)],
    <Color>[Color(0xFFFDF2F8), Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
  ];

  static const List<String> _backgroundImageUrls = <String>[
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1400',
    'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?w=1400',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1400',
    'https://images.unsplash.com/photo-1511300636408-a63a89df3482?w=1400',
  ];

  static const List<String> _elementCategories = <String>[
    'Trending',
    'Recent',
    'Shapes',
    'Frames',
    'Flowers',
    'Devotional',
    'Love',
    'Birthday',
    'Wedding',
    'Symbols',
    'Political',
    'Nature',
    'Others',
  ];

  static const List<EditorElementAsset> _elementAssetCatalog =
      <EditorElementAsset>[
        EditorElementAsset(
          id: 'elm_trend_star',
          name: 'Star Burst',
          category: 'Trending',
          url: 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png',
          tags: <String>['star', 'burst', 'highlight'],
        ),
        EditorElementAsset(
          id: 'elm_shape_circle',
          name: 'Circle Ring',
          category: 'Shapes',
          url: 'https://cdn-icons-png.flaticon.com/512/32/32339.png',
          tags: <String>['shape', 'circle'],
        ),
        EditorElementAsset(
          id: 'elm_frame_gold',
          name: 'Gold Frame',
          category: 'Frames',
          url: 'https://cdn-icons-png.flaticon.com/512/1040/1040216.png',
          tags: <String>['frame', 'border'],
        ),
        EditorElementAsset(
          id: 'elm_flower_rose',
          name: 'Rose',
          category: 'Flowers',
          url: 'https://cdn-icons-png.flaticon.com/512/3159/3159310.png',
          tags: <String>['flower', 'rose'],
        ),
        EditorElementAsset(
          id: 'elm_devotional_lamp',
          name: 'Diya',
          category: 'Devotional',
          url: 'https://cdn-icons-png.flaticon.com/512/3565/3565418.png',
          tags: <String>['devotional', 'festival', 'diya'],
        ),
        EditorElementAsset(
          id: 'elm_love_heart',
          name: 'Heart',
          category: 'Love',
          url: 'https://cdn-icons-png.flaticon.com/512/833/833472.png',
          tags: <String>['love', 'heart'],
        ),
        EditorElementAsset(
          id: 'elm_birthday_cake',
          name: 'Cake',
          category: 'Birthday',
          url: 'https://cdn-icons-png.flaticon.com/512/3176/3176368.png',
          tags: <String>['birthday', 'cake'],
        ),
        EditorElementAsset(
          id: 'elm_wedding_ring',
          name: 'Wedding Ring',
          category: 'Wedding',
          url: 'https://cdn-icons-png.flaticon.com/512/992/992700.png',
          tags: <String>['wedding', 'ring'],
        ),
        EditorElementAsset(
          id: 'elm_symbol_flag',
          name: 'Flag Symbol',
          category: 'Symbols',
          url: 'https://cdn-icons-png.flaticon.com/512/197/197374.png',
          tags: <String>['symbol', 'flag'],
        ),
        EditorElementAsset(
          id: 'elm_political_mic',
          name: 'Mic',
          category: 'Political',
          url: 'https://cdn-icons-png.flaticon.com/512/727/727245.png',
          tags: <String>['political', 'speech', 'mic'],
        ),
        EditorElementAsset(
          id: 'elm_nature_leaf',
          name: 'Leaf',
          category: 'Nature',
          url: 'https://cdn-icons-png.flaticon.com/512/2909/2909768.png',
          tags: <String>['nature', 'leaf'],
        ),
        EditorElementAsset(
          id: 'elm_other_confetti',
          name: 'Confetti',
          category: 'Others',
          url: 'https://cdn-icons-png.flaticon.com/512/4363/4363350.png',
          tags: <String>['party', 'confetti'],
        ),
      ];

  static const List<String> _stickerCategories = <String>[
    'Trending',
    'Recent',
    'Emoji',
    'Love',
    'Birthday',
    'Festival',
    'Devotional',
    'Funny',
    'Symbols',
    'Shapes',
  ];

  static const List<EditorStickerAsset> _stickerAssetCatalog =
      <EditorStickerAsset>[
        EditorStickerAsset(
          id: 'stk_trending_fire',
          name: 'Fire',
          category: 'Trending',
          url: 'https://cdn-icons-png.flaticon.com/512/785/785116.png',
          tags: <String>['trending', 'hot', 'fire'],
        ),
        EditorStickerAsset(
          id: 'stk_recent_pin',
          name: 'Pin',
          category: 'Recent',
          url: 'https://cdn-icons-png.flaticon.com/512/684/684908.png',
          tags: <String>['recent', 'pin'],
        ),
        EditorStickerAsset(
          id: 'stk_emoji_smile',
          name: 'Smile',
          category: 'Emoji',
          url: 'https://cdn-icons-png.flaticon.com/512/742/742751.png',
          tags: <String>['emoji', 'smile', 'happy'],
        ),
        EditorStickerAsset(
          id: 'stk_love_heart',
          name: 'Love Heart',
          category: 'Love',
          url: 'https://cdn-icons-png.flaticon.com/512/2589/2589175.png',
          tags: <String>['love', 'heart'],
        ),
        EditorStickerAsset(
          id: 'stk_birthday_balloon',
          name: 'Balloon',
          category: 'Birthday',
          url: 'https://cdn-icons-png.flaticon.com/512/3468/3468377.png',
          tags: <String>['birthday', 'balloon', 'party'],
        ),
        EditorStickerAsset(
          id: 'stk_festival_diya',
          name: 'Festival Diya',
          category: 'Festival',
          url: 'https://cdn-icons-png.flaticon.com/512/1683/1683814.png',
          tags: <String>['festival', 'diya', 'lights'],
        ),
        EditorStickerAsset(
          id: 'stk_devotional_om',
          name: 'Om',
          category: 'Devotional',
          url: 'https://cdn-icons-png.flaticon.com/512/1656/1656073.png',
          tags: <String>['devotional', 'om', 'spiritual'],
        ),
        EditorStickerAsset(
          id: 'stk_funny_lol',
          name: 'LOL',
          category: 'Funny',
          url: 'https://cdn-icons-png.flaticon.com/512/1246/1246332.png',
          tags: <String>['funny', 'lol', 'meme'],
        ),
        EditorStickerAsset(
          id: 'stk_symbol_star',
          name: 'Star',
          category: 'Symbols',
          url: 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png',
          tags: <String>['symbols', 'star', 'highlight'],
        ),
        EditorStickerAsset(
          id: 'stk_shape_circle',
          name: 'Circle',
          category: 'Shapes',
          url: 'https://cdn-icons-png.flaticon.com/512/753/753345.png',
          tags: <String>['shape', 'circle'],
        ),
      ];

  static const List<FramePresetConfig> _framePresetCatalog =
      <FramePresetConfig>[
        FramePresetConfig(
          id: 'frame_devotional_gold',
          name: 'Temple Gold',
          category: FramePresetCategory.devotional,
          primaryColor: Color(0xFFF59E0B),
          secondaryColor: Color(0xFF7C2D12),
          accentColor: Color(0xFFFFFBEB),
          opacity: 0.92,
          size: 0.14,
        ),
        FramePresetConfig(
          id: 'frame_floral_rose',
          name: 'Rose Floral',
          category: FramePresetCategory.floral,
          primaryColor: Color(0xFFE11D48),
          secondaryColor: Color(0xFFF9A8D4),
          accentColor: Color(0xFFFECDD3),
          opacity: 0.88,
          size: 0.13,
        ),
        FramePresetConfig(
          id: 'frame_birthday_confetti',
          name: 'Confetti Party',
          category: FramePresetCategory.birthday,
          primaryColor: Color(0xFF2563EB),
          secondaryColor: Color(0xFFF59E0B),
          accentColor: Color(0xFFEC4899),
          opacity: 0.86,
          size: 0.12,
        ),
        FramePresetConfig(
          id: 'frame_wedding_royal',
          name: 'Royal Wedding',
          category: FramePresetCategory.wedding,
          primaryColor: Color(0xFFB45309),
          secondaryColor: Color(0xFFFDE68A),
          accentColor: Color(0xFFFFFFFF),
          opacity: 0.9,
          size: 0.15,
        ),
        FramePresetConfig(
          id: 'frame_festive_lights',
          name: 'Festive Lights',
          category: FramePresetCategory.festive,
          primaryColor: Color(0xFF7C3AED),
          secondaryColor: Color(0xFFF97316),
          accentColor: Color(0xFFFEF3C7),
          opacity: 0.9,
          size: 0.14,
        ),
      ];

  static const Map<String, double?> _cropRatioOptions = <String, double?>{
    'free': null,
    '1:1': 1,
    '4:5': 4 / 5,
    '16:9': 16 / 9,
    '9:16': 9 / 16,
    '3:4': 3 / 4,
    '4:3': 4 / 3,
  };

  static const Map<String, String> _cropRatioLabels = <String, String>{
    'free': 'Free',
    '1:1': '1:1',
    '4:5': '4:5',
    '16:9': '16:9',
    '9:16': '9:16',
    '3:4': '3:4',
    '4:3': '4:3',
  };
}

enum _CropTargetType { mainSurface, extraPhoto }

enum _AdjustTargetType { mainSurface, extraPhoto }

enum _FilterTargetType { mainSurface, extraPhoto }

enum _RemoveBgTargetType { mainSurface, extraPhoto }

enum _AdjustControl {
  brightness,
  contrast,
  saturation,
  warmth,
  tint,
  highlights,
  shadows,
  sharpness,
}

class _EditorHistoryEntry {
  const _EditorHistoryEntry({required this.snapshot, required this.signature});

  final _EditorHistorySnapshot snapshot;
  final String signature;
}

class _EditorHistorySnapshot {
  const _EditorHistorySnapshot({
    required this.stageBackground,
    required this.recentBackgroundColors,
    required this.backgroundSampleSeq,
    required this.mainSurfacePhoto,
    required this.mainSurfaceImageSize,
    required this.mainSurfaceScale,
    required this.mainSurfaceRotation,
    required this.mainSurfaceOffset,
    required this.mainSurfaceCropRatio,
    required this.mainSurfaceCropTurns,
    required this.extraPhotoLayers,
    required this.elementLayers,
    required this.stickerLayers,
    required this.drawLayers,
    required this.shapeLayers,
    required this.textLayers,
    required this.photoSeq,
    required this.elementSeq,
    required this.stickerSeq,
    required this.drawSeq,
    required this.shapeSeq,
    required this.drawStrokeSeq,
    required this.textSeq,
    required this.selectedExtraPhotoLayerId,
    required this.selectedTextLayerId,
    required this.selectedElementLayerId,
    required this.selectedStickerLayerId,
    required this.selectedDrawLayerId,
    required this.selectedShapeLayerId,
    required this.isMainSurfaceSelected,
    required this.showVerticalGuide,
    required this.showHorizontalGuide,
  });

  final StageBackgroundConfig stageBackground;
  final List<Color> recentBackgroundColors;
  final int backgroundSampleSeq;
  final StageSurfacePhoto? mainSurfacePhoto;
  final Size? mainSurfaceImageSize;
  final double mainSurfaceScale;
  final double mainSurfaceRotation;
  final Offset mainSurfaceOffset;
  final double? mainSurfaceCropRatio;
  final int mainSurfaceCropTurns;
  final List<StagePhotoLayer> extraPhotoLayers;
  final List<StageElementLayer> elementLayers;
  final List<StageStickerLayer> stickerLayers;
  final List<StageDrawLayer> drawLayers;
  final List<StageShapeLayer> shapeLayers;
  final List<EditorTextLayer> textLayers;
  final int photoSeq;
  final int elementSeq;
  final int stickerSeq;
  final int drawSeq;
  final int shapeSeq;
  final int drawStrokeSeq;
  final int textSeq;
  final String? selectedExtraPhotoLayerId;
  final String? selectedTextLayerId;
  final String? selectedElementLayerId;
  final String? selectedStickerLayerId;
  final String? selectedDrawLayerId;
  final String? selectedShapeLayerId;
  final bool isMainSurfaceSelected;
  final bool showVerticalGuide;
  final bool showHorizontalGuide;
}
