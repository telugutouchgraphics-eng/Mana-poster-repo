part of 'image_editor_screen.dart';

extension _EditorAdjustState on _ImageEditorScreenState {
  void _openAdjustPanel() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isPhoto || layer.isLocked) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
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
      _activeMainToolLabel = 'Effects';
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.none;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _isAdjustMode = true;
      _adjustSessionLayerId = layer.id;
      _adjustSessionBrightness = layer.photoBrightness;
      _adjustSessionContrast = layer.photoContrast;
      _adjustSessionSaturation = layer.photoSaturation;
      _adjustSessionBlur = layer.photoBlur;
      _adjustSessionSharpen = layer.photoSharpen;
      _adjustSessionGrain = layer.photoGrain;
      _adjustSessionVignette = layer.photoVignette;
      _adjustSessionMotion = layer.photoMotion;
      _adjustSessionTiltShift = layer.photoTiltShift;
      _adjustSessionShadows = layer.photoShadows;
      _adjustSessionHighlights = layer.photoHighlights;
      _adjustSessionTemperature = layer.photoTemperature;
      _adjustSessionTint = layer.photoTint;
      _adjustInitialBrightness = layer.photoBrightness;
      _adjustInitialContrast = layer.photoContrast;
      _adjustInitialSaturation = layer.photoSaturation;
      _adjustInitialBlur = layer.photoBlur;
      _adjustInitialSharpen = layer.photoSharpen;
      _adjustInitialGrain = layer.photoGrain;
      _adjustInitialVignette = layer.photoVignette;
      _adjustInitialMotion = layer.photoMotion;
      _adjustInitialTiltShift = layer.photoTiltShift;
      _adjustInitialShadows = layer.photoShadows;
      _adjustInitialHighlights = layer.photoHighlights;
      _adjustInitialTemperature = layer.photoTemperature;
      _adjustInitialTint = layer.photoTint;
      _showTextControls = false;
    });
    _adjustSessionNotifier.value = _AdjustSessionState(
      brightness: layer.photoBrightness,
      contrast: layer.photoContrast,
      saturation: layer.photoSaturation,
      blur: layer.photoBlur,
      sharpen: layer.photoSharpen,
      grain: layer.photoGrain,
      vignette: layer.photoVignette,
      motion: layer.photoMotion,
      tiltShift: layer.photoTiltShift,
      shadows: layer.photoShadows,
      highlights: layer.photoHighlights,
      temperature: layer.photoTemperature,
      tint: layer.photoTint,
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
      _adjustSessionSharpen = 0;
      _adjustSessionGrain = 0;
      _adjustSessionVignette = 0;
      _adjustSessionMotion = 0;
      _adjustSessionTiltShift = 0;
      _adjustSessionShadows = 0;
      _adjustSessionHighlights = 0;
      _adjustSessionTemperature = 0;
      _adjustSessionTint = 0;
      _adjustInitialBrightness = 0;
      _adjustInitialContrast = 1;
      _adjustInitialSaturation = 1;
      _adjustInitialBlur = 0;
      _adjustInitialSharpen = 0;
      _adjustInitialGrain = 0;
      _adjustInitialVignette = 0;
      _adjustInitialMotion = 0;
      _adjustInitialTiltShift = 0;
      _adjustInitialShadows = 0;
      _adjustInitialHighlights = 0;
      _adjustInitialTemperature = 0;
      _adjustInitialTint = 0;
      _restoreSelectedLayerToolContextFields();
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
      _adjustSessionSharpen = _adjustInitialSharpen;
      _adjustSessionGrain = _adjustInitialGrain;
      _adjustSessionVignette = _adjustInitialVignette;
      _adjustSessionMotion = _adjustInitialMotion;
      _adjustSessionTiltShift = _adjustInitialTiltShift;
      _adjustSessionShadows = _adjustInitialShadows;
      _adjustSessionHighlights = _adjustInitialHighlights;
      _adjustSessionTemperature = _adjustInitialTemperature;
      _adjustSessionTint = _adjustInitialTint;
    });
    _adjustSessionNotifier.value = _AdjustSessionState(
      brightness: _adjustInitialBrightness,
      contrast: _adjustInitialContrast,
      saturation: _adjustInitialSaturation,
      blur: _adjustInitialBlur,
      sharpen: _adjustInitialSharpen,
      grain: _adjustInitialGrain,
      vignette: _adjustInitialVignette,
      motion: _adjustInitialMotion,
      tiltShift: _adjustInitialTiltShift,
      shadows: _adjustInitialShadows,
      highlights: _adjustInitialHighlights,
      temperature: _adjustInitialTemperature,
      tint: _adjustInitialTint,
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
    _adjustSessionSharpen = nextState.sharpen;
    _adjustSessionGrain = nextState.grain;
    _adjustSessionVignette = nextState.vignette;
    _adjustSessionMotion = nextState.motion;
    _adjustSessionTiltShift = nextState.tiltShift;
    _adjustSessionShadows = nextState.shadows;
    _adjustSessionHighlights = nextState.highlights;
    _adjustSessionTemperature = nextState.temperature;
    _adjustSessionTint = nextState.tint;
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
        (beforeLayer.photoBlur - _adjustSessionBlur).abs() > 0.0001 ||
        (beforeLayer.photoSharpen - _adjustSessionSharpen).abs() > 0.0001 ||
        (beforeLayer.photoGrain - _adjustSessionGrain).abs() > 0.0001 ||
        (beforeLayer.photoVignette - _adjustSessionVignette).abs() > 0.0001 ||
        (beforeLayer.photoMotion - _adjustSessionMotion).abs() > 0.0001 ||
        (beforeLayer.photoTiltShift - _adjustSessionTiltShift).abs() > 0.0001 ||
        (beforeLayer.photoShadows - _adjustSessionShadows).abs() > 0.0001 ||
        (beforeLayer.photoHighlights - _adjustSessionHighlights).abs() >
            0.0001 ||
        (beforeLayer.photoTemperature - _adjustSessionTemperature).abs() >
            0.0001 ||
        (beforeLayer.photoTint - _adjustSessionTint).abs() > 0.0001;
    final afterLayer = beforeLayer.copyWith(
      photoBrightness: _adjustSessionBrightness,
      photoContrast: _adjustSessionContrast,
      photoSaturation: _adjustSessionSaturation,
      photoBlur: _adjustSessionBlur,
      photoSharpen: _adjustSessionSharpen,
      photoGrain: _adjustSessionGrain,
      photoVignette: _adjustSessionVignette,
      photoMotion: _adjustSessionMotion,
      photoTiltShift: _adjustSessionTiltShift,
      photoShadows: _adjustSessionShadows,
      photoHighlights: _adjustSessionHighlights,
      photoTemperature: _adjustSessionTemperature,
      photoTint: _adjustSessionTint,
    );
    if (hasChanges) {
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    }
    setState(() {
      _layers[index] = afterLayer;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _restoreSelectedLayerToolContextFields();
    });
    _adjustSessionNotifier.value = null;
  }
}
