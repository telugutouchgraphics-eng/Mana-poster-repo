// ignore_for_file: use_build_context_synchronously, unused_element, unused_field

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
import 'package:image_cropper/image_cropper.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/app/localization/app_language.dart';

import '../models/background_presets.dart';
import '../models/elements_catalog.dart';
import '../models/editor_template_document.dart';
import '../models/editor_page_config.dart';
import '../models/editor_stage_background.dart';
import '../services/background_removal_service.dart';
import '../services/editor_draft_storage_service.dart';

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

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({
    super.key,
    this.pageConfig,
    this.initialStageBackground,
    this.templateDocumentSource,
  });

  final EditorPageConfig? pageConfig;
  final EditorStageBackground? initialStageBackground;
  final String? templateDocumentSource;

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

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

  final List<_CanvasLayer> _layers = <_CanvasLayer>[];
  final List<_EditorHistoryEntry> _undoStack = <_EditorHistoryEntry>[];
  final List<_EditorHistoryEntry> _redoStack = <_EditorHistoryEntry>[];
  String? _selectedLayerId;
  Color _canvasBackgroundColor = const Color(0xFF000000);
  int _canvasBackgroundGradientIndex = -1;
  int _layerSeed = 0;
  static const int _maxHistory = 40;
  _CanvasLayer? _fontSizeEditBeforeLayer;
  _CanvasLayer? _textStyleEditBeforeLayer;
  _CanvasLayer? _textContentEditBeforeLayer;
  String? _textContentEditingLayerId;
  bool _isSyncingSelectedTextField = false;
  bool _isExporting = false;
  bool _isSharing = false;
  bool _isRemovingBackground = false;
  bool _isCapturingStage = false;
  bool _isTransparentExportCapture = false;
  bool _isCropMode = false;
  bool _isCropApplying = false;
  bool _suppressCanvasTapDown = false;
  bool _canvasTapResolvedLayer = false;
  int _suppressCanvasTapToken = 0;
  bool _showTextControls = false;
  _BottomPrimaryTool _activeBottomPrimaryTool = _BottomPrimaryTool.none;
  _BottomInlineMode _activeInlineMode = _BottomInlineMode.none;
  String _activeStickerCategory = 'Emojis';
  _BorderStyle _borderStyle = _BorderStyle.none;
  String? _borderTargetLayerId;
  double _backgroundBlurAmount = 0;
  bool _isAdjustMode = false;
  bool _isLayerInteracting = false;
  bool _isCreatingTextLayer = false;
  int _removeBackgroundTaskId = 0;
  String? _activeCommitJobKey;
  Future<void> _commitJobTail = Future<void>.value();
  double? _pageAspectRatio;
  bool _pageAspectRatioAutoFromImage = false;
  bool _didShowSetupReadyHint = false;
  bool _isOpeningTextFullScreenEditor = false;
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
  DateTime? _lastSelectedTextTapAt;
  String? _lastSelectedTextTapLayerId;
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
  final ValueNotifier<_SnapGuideState> _snapGuideNotifier =
      ValueNotifier<_SnapGuideState>(const _SnapGuideState.none());
  final ValueNotifier<_SelectedPhotoRenderState?> _selectedPhotoRenderNotifier =
      ValueNotifier<_SelectedPhotoRenderState?>(null);
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
        telugu: 'Photo టూల్: Gallery లేదా Camera నుంచి ఫోటో జోడించండి.',
        english: 'Photo tool: add from Gallery or Camera.',
      ),
      _BottomPrimaryTool.text => strings.localized(
        telugu: 'Text టూల్: Add Text నొక్కి వెంటనే style మార్చండి.',
        english: 'Text tool: tap Add Text, then style it.',
      ),
      _BottomPrimaryTool.background => strings.localized(
        telugu: 'Background టూల్: White, Color, Gradient లేదా Image ఎంచుకోండి.',
        english: 'Background tool: choose White, Color, Gradient, or Image.',
      ),
      _BottomPrimaryTool.tools => strings.localized(
        telugu:
            'Tools టూల్: Crop, Erase, Layers, Stickers మరియు Border ఇక్కడ ఉన్నాయి.',
        english: 'Tools: Crop, Erase, Layers, Stickers, and Border.',
      ),
      _BottomPrimaryTool.none => '',
    };
    if (message.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
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
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.none;
      _showTextControls = false;
    });
  }

  void _openInlineMode(_BottomInlineMode mode) {
    setState(() {
      _activeInlineMode = mode;
      if (mode != _BottomInlineMode.stickerItems) {
        _activeStickerCategory = 'Emojis';
      }
    });
  }

  void _closeInlineMode() {
    setState(() {
      _activeInlineMode = _BottomInlineMode.none;
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

  Future<T?> _pushPremiumOverlay<T>(Widget child) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.34),
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
                  filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Material(
                          color: const Color(0xF8F8FAFC),
                          child: child,
                        ),
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
    final selected = await _pushPremiumOverlay<String>(
      TextFontFullscreenOverlay(
        selectedFontFamily: layer.fontFamily,
        teluguFonts: _textFontFamilies,
        englishFonts: _englishTextFontFamilies,
        previewText: (layer.text ?? '').trim().isEmpty
            ? 'తెలుగు Poster Title'
            : layer.text!,
      ),
    );
    if (!mounted || selected == null || selected.isEmpty) {
      return;
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

  Future<void> _openStickerBrowserOverlay() async {
    final selected = await _pushPremiumOverlay<String>(
      StickerBrowserFullscreenOverlay(
        categories: _stickerCategories,
        catalog: _stickerCatalog,
      ),
    );
    if (!mounted || selected == null || selected.isEmpty) {
      return;
    }
    _handleAddSticker(selected);
  }

  Future<void> _openLayersAdvancedOverlay() async {
    await _pushPremiumOverlay<void>(
      _AdvancedLayersFullscreenOverlay(
        layers: _layers,
        selectedLayerId: _selectedLayerId,
        onSelectLayer: _handleLayerSelected,
        onDeleteLayer: _deleteLayerById,
        onToggleLayerLock: _toggleLayerLockById,
        onToggleLayerVisibility: _toggleLayerVisibilityById,
        onReorderLayers: _reorderLayersFromAdvancedView,
        onMoveToFront: _moveLayerToFrontById,
        onMoveToBack: _moveLayerToBackById,
      ),
    );
  }

  void _moveLayerToFrontById(String layerId) {
    if (_selectedLayerId != layerId) {
      _handleLayerSelected(layerId);
    }
    _moveSelectedLayerToFront();
  }

  void _moveLayerToBackById(String layerId) {
    if (_selectedLayerId != layerId) {
      _handleLayerSelected(layerId);
    }
    _moveSelectedLayerToBack();
  }

  void _handleToolsLayersTap() {
    if (_activeInlineMode == _BottomInlineMode.layers) {
      unawaited(_openLayersAdvancedOverlay());
      return;
    }
    _openInlineMode(_BottomInlineMode.layers);
  }

  void _toggleLayerLockById(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) {
      return;
    }
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(isLocked: !beforeLayer.isLocked);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
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
    final boundedNew = newIndex.clamp(0, _layers.length).toInt();
    var insertIndex = boundedNew;
    if (oldIndex < boundedNew) {
      insertIndex -= 1;
    }
    if (insertIndex == oldIndex ||
        insertIndex < 0 ||
        insertIndex >= _layers.length) {
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
    if (selectedId == null) {
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
    if (selectedId == null) {
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
    final currentIndex = _textFontFamilies.indexOf(layer.fontFamily);
    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + 1) % _textFontFamilies.length;
    unawaited(_setSelectedTextFontFamily(_textFontFamilies[nextIndex]));
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
    if (!_hasSelectedTextLayer) {
      return;
    }
    _lastSelectedTextTapAt = null;
    _lastSelectedTextTapLayerId = null;
    _cancelSelectedTextLongPress();
    unawaited(_openSelectedTextFullScreenEditor());
  }

  Future<void> _openSelectedTextFullScreenEditor() async {
    if (_isOpeningTextFullScreenEditor) {
      return;
    }
    final selected = _selectedLayer;
    if (selected == null || !selected.isText || !mounted) {
      return;
    }
    _isOpeningTextFullScreenEditor = true;
    _commitSelectedTextContentEdit();
    final String initialText = selected.text ?? '';
    _TextEditResult? result;
    try {
      result = await Navigator.of(context).push<_TextEditResult>(
        PageRouteBuilder<_TextEditResult>(
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return TextEditorFullscreenOverlay(
                  initialText: initialText,
                  fontFamily: selected.fontFamily,
                  textColor: selected.textColor,
                  textGradientIndex: selected.textGradientIndex,
                  textOpacity: selected.textOpacity,
                  fontSize: selected.fontSize,
                  textLineHeight: selected.textLineHeight,
                  textLetterSpacing: selected.textLetterSpacing,
                  textAlign: selected.textAlign,
                  textShadowOpacity: selected.textShadowOpacity,
                  textShadowBlur: selected.textShadowBlur,
                  textShadowOffsetY: selected.textShadowOffsetY,
                  isTextBold: selected.isTextBold,
                  isTextItalic: selected.isTextItalic,
                  isTextUnderline: selected.isTextUnderline,
                  textStrokeColor: selected.textStrokeColor,
                  textStrokeWidth: selected.textStrokeWidth,
                  textStrokeGradientIndex: selected.textStrokeGradientIndex,
                  textBackgroundColor: selected.textBackgroundColor,
                  textBackgroundOpacity: selected.textBackgroundOpacity,
                  textBackgroundRadius: selected.textBackgroundRadius,
                  colors: _textColors,
                  gradients: _textGradients,
                  fontFamilies: _textFontFamilies,
                );
              },
          transitionsBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                  child: child,
                );
              },
        ),
      );
    } finally {
      _isOpeningTextFullScreenEditor = false;
      if (mounted &&
          (_showTextControls ||
              _activeBottomPrimaryTool != _BottomPrimaryTool.none)) {
        setState(() {
          _showTextControls = false;
          _activeBottomPrimaryTool = _BottomPrimaryTool.none;
        });
      }
    }
    if (!mounted || result == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selected.id);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final currentLayer = _layers[index];
    final normalizedText = result.text;
    final unchanged =
        (currentLayer.text ?? '') == normalizedText &&
        currentLayer.textColor.toARGB32() == result.textColor.toARGB32() &&
        currentLayer.textGradientIndex == result.textGradientIndex &&
        (currentLayer.textOpacity - result.textOpacity).abs() < 0.0001 &&
        (currentLayer.fontSize - result.fontSize).abs() < 0.0001 &&
        (currentLayer.textLineHeight - result.textLineHeight).abs() < 0.0001 &&
        (currentLayer.textLetterSpacing - result.textLetterSpacing).abs() <
            0.0001 &&
        currentLayer.textAlign == result.textAlign &&
        (currentLayer.textShadowOpacity - result.textShadowOpacity).abs() <
            0.0001 &&
        (currentLayer.textShadowBlur - result.textShadowBlur).abs() < 0.0001 &&
        (currentLayer.textShadowOffsetY - result.textShadowOffsetY).abs() <
            0.0001 &&
        currentLayer.isTextBold == result.isTextBold &&
        currentLayer.isTextItalic == result.isTextItalic &&
        currentLayer.isTextUnderline == result.isTextUnderline &&
        currentLayer.textStrokeColor.toARGB32() ==
            result.textStrokeColor.toARGB32() &&
        (currentLayer.textStrokeWidth - result.textStrokeWidth).abs() <
            0.0001 &&
        currentLayer.textStrokeGradientIndex ==
            result.textStrokeGradientIndex &&
        currentLayer.fontFamily == result.fontFamily;
    if (unchanged) {
      return;
    }
    final converted = await _resolveLegacyRenderTextFor(
      text: normalizedText,
      fontFamily: result.fontFamily,
    );
    if (!mounted) {
      return;
    }
    final refreshedIndex = _layers.indexWhere((item) => item.id == selected.id);
    if (refreshedIndex == -1 || !_layers[refreshedIndex].isText) {
      return;
    }
    final latestLayer = _layers[refreshedIndex];
    final afterLayer = latestLayer.copyWith(
      text: normalizedText,
      textColor: result.textColor,
      textGradientIndex: result.textGradientIndex,
      textOpacity: result.textOpacity,
      fontSize: result.fontSize,
      textLineHeight: result.textLineHeight,
      textLetterSpacing: result.textLetterSpacing,
      textAlign: result.textAlign,
      textShadowOpacity: result.textShadowOpacity,
      textShadowBlur: result.textShadowBlur,
      textShadowOffsetY: result.textShadowOffsetY,
      isTextBold: result.isTextBold,
      isTextItalic: result.isTextItalic,
      isTextUnderline: result.isTextUnderline,
      textStrokeColor: result.textStrokeColor,
      textStrokeWidth: result.textStrokeWidth,
      textStrokeGradientIndex: result.textStrokeGradientIndex,
      fontFamily: result.fontFamily,
      legacyRenderText: converted,
    );
    _replaceLayerWithHistory(index: refreshedIndex, afterLayer: afterLayer);
    _syncSelectedTextEditor();
  }

  void _handleSelectedTextTap() {
    if (!_hasSelectedTextLayer) {
      return;
    }
    final selectedId = _selectedLayerId;
    final now = DateTime.now();
    if (selectedId != null &&
        _lastSelectedTextTapLayerId == selectedId &&
        _lastSelectedTextTapAt != null &&
        now.difference(_lastSelectedTextTapAt!) <=
            const Duration(milliseconds: 320)) {
      _lastSelectedTextTapAt = null;
      _lastSelectedTextTapLayerId = null;
      _handleSelectedTextDoubleTap();
      return;
    }
    _lastSelectedTextTapAt = now;
    _lastSelectedTextTapLayerId = selectedId;
    _cancelSelectedTextLongPress();
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
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: _TextStyleBar(
                  visible: true,
                  selectedLayer: _selectedLayer,
                  textController: _selectedTextController,
                  textFocusNode: _selectedTextFocusNode,
                  colors: _textColors,
                  backgroundColors: editorBackgroundColors,
                  gradients: _textGradients,
                  onEditTap: () => _syncSelectedTextEditor(requestFocus: true),
                  onTextChanged: _handleSelectedTextChanged,
                  onFontsTap: () => unawaited(_openFontPickerOverlay()),
                  onColorSelected: _setSelectedTextColor,
                  onBackgroundColorSelected: _setSelectedTextBackgroundColor,
                  onAlignSelected: _setSelectedTextAlignment,
                  onGradientSelected: _setSelectedTextGradient,
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
                  onBoldToggle: _toggleSelectedTextBold,
                  onItalicToggle: _toggleSelectedTextItalic,
                  onUnderlineToggle: _toggleSelectedTextUnderline,
                  onStrokeColorSelected: _setSelectedTextStrokeColor,
                  onStrokeWidthChanged: _setSelectedTextStrokeWidth,
                  onStrokeWidthChangeStart: _beginSelectedTextStyleEdit,
                  onStrokeWidthChangeEnd: _endSelectedTextStyleEdit,
                ),
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
    _selectedTextLongPressTimer = Timer(const Duration(seconds: 2), () {
      _selectedTextLongPressTimer = null;
      _selectedTextPressPosition = null;
      if (!mounted || !_hasSelectedTextLayer) {
        return;
      }
      unawaited(_openSelectedTextFullScreenEditor());
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

  void _showSetupReadyHintIfNeeded() {
    if (_didShowSetupReadyHint ||
        widget.pageConfig == null ||
        widget.templateDocumentSource != null ||
        !mounted) {
      return;
    }
    _didShowSetupReadyHint = true;
    final strings = context.strings;
    final config = widget.pageConfig!;
    final backgroundLabel = switch (widget.initialStageBackground?.type) {
      EditorStageBackgroundType.transparent => strings.localized(
        telugu: 'Transparent',
        english: 'Transparent',
      ),
      EditorStageBackgroundType.color => strings.localized(
        telugu: 'Color',
        english: 'Color',
      ),
      EditorStageBackgroundType.gradient => strings.localized(
        telugu: 'Gradient',
        english: 'Gradient',
      ),
      _ => strings.localized(telugu: 'వైట్', english: 'White'),
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.localized(
            telugu:
                'Canvas ready: ${config.widthPx}x${config.heightPx} • $backgroundLabel',
            english:
                'Canvas ready: ${config.widthPx}x${config.heightPx} • $backgroundLabel',
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
    _selectedTextFocusNode.addListener(_handleSelectedTextFocusChange);
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
    _backgroundRemoverInitialization = BackgroundRemover.instance
        .initializeOrt();
    _enterEditorImmersiveMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_enterEditorImmersiveMode());
      _showSetupReadyHintIfNeeded();
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
    _adjustSessionNotifier.dispose();
    _commitStateNotifier.dispose();
    _selectedTextController.dispose();
    _selectedTextFocusNode.dispose();
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
        _canvasBackgroundColor = const Color(0xFF000000);
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
                : _isAdjustMode
                ? _adjustBarHeight
                : _bottomBarHeight;
            const reservedTopInset = _canvasChromeInset;
            const reservedBottomInset = _canvasChromeInset;
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
                    child: ColoredBox(color: Color(0xFF000000)),
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
                      backgroundBlurAmount: _backgroundBlurAmount,
                      borderStyle: _borderStyle,
                      borderTargetLayerId: _borderTargetLayerId,
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
                      onSelectedTextTap: _handleSelectedTextTap,
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
                      onCanvasTap: _isCropMode
                          ? () {}
                          : _handleCanvasTap,
                      showCanvasBackground: !_isTransparentExportCapture,
                      photoBrightnessForLayer: _effectivePhotoBrightness,
                      photoContrastForLayer: _effectivePhotoContrast,
                      photoSaturationForLayer: _effectivePhotoSaturation,
                      photoBlurForLayer: _effectivePhotoBlur,
                      showSelectionDecorations:
                          !_isCropMode &&
                          !_isExporting &&
                          !_isCapturingStage,
                      showPageFramePreview: !_isExporting && !_isCapturingStage,
                      snapGuideListenable: _snapGuideNotifier,
                      snapGuidesEnabled: !_isCropMode && !_isCapturingStage,
                      selectedPhotoRenderListenable:
                          _selectedPhotoRenderNotifier,
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
                if (_isCropMode) const SizedBox.shrink(),
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
                              key: const ValueKey<String>('crop-inline-strip'),
                              child: _CropInlineStrip(
                                height: bottomToolsHeight,
                                isApplying: _isCropApplying,
                                selectedAspectRatio: _cropSessionAspectRatio,
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
                                onMoveBackward: _moveSelectedLayerBackwardOne,
                                onDeleteSelected: _handleDeleteSelectedLayer,
                              ),
                            )
                          : _activeInlineMode == _BottomInlineMode.border
                          ? KeyedSubtree(
                              key: const ValueKey<String>(
                                'border-inline-strip',
                              ),
                              child: _BorderInlineStrip(
                                height: bottomToolsHeight,
                                selectedStyle: _borderStyle,
                                onBack: _closeInlineMode,
                                onStyleTap: _applyBorderStyle,
                              ),
                            )
                          : _activeInlineMode ==
                                _BottomInlineMode.backgroundBlur
                          ? KeyedSubtree(
                              key: const ValueKey<String>('blur-inline-strip'),
                              child: _BackgroundBlurInlineStrip(
                                height: bottomToolsHeight,
                                value: _backgroundBlurAmount,
                                enabled: _stageBackgroundImageBytes != null,
                                onBack: _closeInlineMode,
                                onValueTap: _setBackgroundBlur,
                              ),
                            )
                          : _showTextControls
                          ? KeyedSubtree(
                              key: const ValueKey<String>('text-style-overlay'),
                              child: _buildTextStyleOverlay(
                                _textStyleBarHeight,
                              ),
                            )
                          : _activeBottomPrimaryTool == _BottomPrimaryTool.none
                          ? KeyedSubtree(
                              key: const ValueKey<String>('main-strip'),
                              child: _EditorMainToolsStrip(
                                height: bottomToolsHeight,
                                activeToolLabel: _activeMainToolLabel,
                                onPhotoTap: () => _openBottomPrimaryTool(
                                  _BottomPrimaryTool.photo,
                                  'Photo',
                                ),
                                onTextTap: _handleMainTextToolTap,
                                onBackgroundTap: () => _openBottomPrimaryTool(
                                  _BottomPrimaryTool.background,
                                  'Background',
                                ),
                                onToolsTap: () => _openBottomPrimaryTool(
                                  _BottomPrimaryTool.tools,
                                  'Tools',
                                ),
                              ),
                            )
                          : KeyedSubtree(
                              key: ValueKey<String>(
                                'sub-strip_${_activeBottomPrimaryTool.name}',
                              ),
                              child: _EditorSubToolsStrip(
                                height: bottomToolsHeight,
                                tool: _activeBottomPrimaryTool,
                                onBack: _closeBottomPrimaryTool,
                                onPhotoGalleryTap: _handleAddPhoto,
                                onPhotoCameraTap: _handleAddPhotoFromCamera,
                                onPhotoRemoveBgTap: _handleRemoveBackgroundTap,
                                onPhotoCropTap: _handleCropPhotoTap,
                                onPhotoAdjustTap: _openAdjustPanel,
                                onTextAddTap: _handleTextAddQuickTap,
                                onTextEditTap: _handleTextEditQuickTap,
                                onTextStyleTap: _handleTextStyleQuickTap,
                                onTextColorTap: _handleTextColorQuickTap,
                                onTextFontTap: _handleTextFontQuickTap,
                                onBackgroundWhiteTap: () =>
                                    _setCanvasBackgroundColor(
                                      const Color(0xFFFFFFFF),
                                    ),
                                onBackgroundTransparentTap: () =>
                                    _setCanvasBackgroundColor(
                                      Colors.transparent,
                                    ),
                                onBackgroundColorTap: () =>
                                    unawaited(_openBackgroundPickerOverlay()),
                                onBackgroundGradientTap: () =>
                                    unawaited(_openBackgroundPickerOverlay()),
                                onBackgroundImageTap: () async {
                                  await _setCanvasBackgroundImage();
                                },
                                onBackgroundBlurTap: () => _openInlineMode(
                                  _BottomInlineMode.backgroundBlur,
                                ),
                                onToolsCropTap: _handleCropPhotoTap,
                                onToolsLayersTap: _handleToolsLayersTap,
                                onToolsStickersTap: () =>
                                    unawaited(_openStickerBrowserOverlay()),
                                onToolsBorderTap: () =>
                                    _openInlineMode(_BottomInlineMode.border),
                                onToolsFiltersTap: _openAdjustPanel,
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
